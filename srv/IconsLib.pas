unit IconsLib;
{$I NoRTTI.inc}

interface

uses
  Windows,
  mormot.core.base,
  System.SysUtils, System.Types, SyncObjs,
 {$IFDEF FMX}
  FMX.Types,
  FMX.Forms,
  FMX.Controls,
  FMX.Graphics, System.UITypes,
  FMX.TreeView,
  FMX.MultiResBitmap,
  FMX.ImgList,
 {$ELSE ~FMX}
  Graphics,
  Forms,
  CommCtrl,
  Controls,
  {$IFDEF HFS_GIF_IMAGES}
  Vcl.Imaging.gifimg,
  {$ELSE ~HFS_GIF_IMAGES}
  Vcl.Imaging.gifimg,
  Vcl.Imaging.pngImage,
  {$ENDIF HFS_GIF_IMAGES}
  Vcl.VirtualImageList, Vcl.BaseImageCollection,
  Vcl.ImageCollection, Vcl.ImgList,
 {$ENDIF FMX}
 System.Classes, System.ImageList
  ;

type
  TIconsDM = class(TDataModule)
    ImgCollection: TImageCollection;
    images: TVirtualImageList;
    BtnImgCollection: TImageCollection;
    constructor Create(AOwner: TComponent); override;
  private
    { Private declarations }
    imgCS: TCriticalSection;

  public
    { Public declarations }
 {$IFDEF FMX}
    systemimages: TImageList;
 {$ELSE ~FMX}
    systemimages: Timagelist;    // system icons
 {$ENDIF FMX}
    function GetBitmap(idx: Integer; Size: Integer): TBitmap;
    function getImageIndexForFile(fn: string): integer;
  end;

  function idx_img2ico(i: integer): integer;
  function idx_ico2img(i: integer): integer;
  function idx_label(i: integer): String;

 {$IFDEF FMX}
  function stringToPNG(const s: RawByteString; png: TBitmap=NIL): TBitmap;
  function png2str(png: TBitmap): RawByteString;
 {$ELSE ~FMX}
  {$IFDEF HFS_GIF_IMAGES}
  function stringToGif(s: RawByteString; gif: TgifImage=NIL): TgifImage;
  function gif2str(gif: TgifImage): RawByteString;
  {$ELSE ~HFS_GIF_IMAGES}
  function stringToPNG(const s: RawByteString; png: TpngImage=NIL): TpngImage;
  function png2str(png: TPngImage): RawByteString;
  {$ENDIF HFS_GIF_IMAGES}
 {$ENDIF FMX}
  function bmp2str(bmp: Tbitmap): RawByteString;
  function pic2str(idx: integer; imgSize: Integer): RawByteString;
  function str2pic(const s: RawByteString; imgSize: Integer): integer;
  function strGif2pic(const gs: RawByteString; imgSize: Integer): integer;
  function ico2str(hndl: THandle; icoNdx: Integer; imgSize: Integer): RawByteString;
  function ico2bmp(hndl: THandle; icoNdx: Integer; imgSize: Integer): TBitmap;

  function  stringPNG2BMP(const s: RawByteString): TBitmap;

const
  ICONMENU_NEW = 1;

  ICON_UNIT = 31;
  ICON_ROOT = 1;
  ICON_LINK = 4;
  ICON_FILE = 37;
  ICON_FOLDER = 6;
  ICON_REAL_FOLDER = 19;
  ICON_LOCK = 12;
  ICON_EASY = 29;
  ICON_EXPERT = 35;

  USER_ICON_MASKS_OFS = 10000;

var
  IconsDM: TIconsDM;
  startingImagesCount: integer;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}
uses
//  AnsiClasses,
  ansiStrings,
  WinApi.ShellAPI,
  RnQCrypt,
  srvVars;

const
  ImageSizeSmall = 16;
  ImageSizeBig = 32;
var
  imagescacheSm: array of RawByteString;
  imagescacheBg: array of RawByteString;
  sysidx2index: array of record sysidx, idx:integer; end; // maps system imagelist icons to internal imagelist



function Shell_GetImageLists(var hl, hs: Thandle): boolean; stdcall; external 'shell32.dll' index 71;

function getSystemimages(): TImageList;
var
  hl, hs: Thandle;
begin
  result := NIL;
  if not Shell_GetImageLists(hl, hs) then
    exit;
 {$IFDEF FMX}
  result := TImageList.Create(NIL);
 {$ELSE ~FMX}
  result := Timagelist.Create(NIL);
  result.ShareImages := TRUE;
  {$IFNDEF FPC}
  Result.ColorDepth := cd32Bit;
  result.handle := hs;
  {$ENDIF FPC}
 {$ENDIF FMX}
end; // loadSystemimages

{
function InitIcons: Boolean;
var
  z: TZipFile;
  I: Integer;
  ii: Integer;
  s: String;
  item: TImageCollectionItem;
  str: TMemoryStream;
begin
  ICOImgCollection := TImageCollection.Create(Application.MainForm);
  ICOImages := TVirtualImageList.Create(Application.MainForm);
  ICOsystemimages := TImageList.Create(Application.MainForm);
  ICOsystemimages := getSystemimages();
  ICOimages.Masked := false;
  ICOimages.ColorDepth := cd32bit;
  if FileExists('HFS.Icons.zip') then
    begin
      z := TZipFile.create;
      z.LoadFromFile('HFS.Icons.zip');
      // We have 40 icons to load
      for ii := 0 to 40-1 do
        begin
          s := IntToStr(ii) + '.';
          for I := 0 to z.Count - 1 do
            if z.Name[i].StartsWith(s) then
              begin
                str := TMemoryStream.Create;
                try
                  if z.ExtractToStream(i, str) then
                    begin
                      var itemIdx := ICOImgCollection.GetIndexByName(IntToStr(ii));
                      if itemIdx <0 then
                        begin
                          item := ICOImgCollection.Images.Add;
                          item.Name := IntToStr(ii);
                        end
                       else
                        item := ICOImgCollection.Images.Items[itemIdx];
                      item.SourceImages.Add.Image.LoadFromStream(str);
                    end;
                finally
                  str.Free;
                end;
              end;
        end;

    end;
  ICOImages.ImageCollection := ICOImgCollection;
end;
}

constructor TIconsDM.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  systemimages := getSystemimages();
 {$IFNDEF FMX}
  images.Masked := false;
  images.ColorDepth := cd32bit;
 {$ENDIF FMX}
  imgCS := TCriticalSection.Create;
end;

function idx_img2ico(i: integer): integer;
begin
  if (i < startingImagesCount) or (i >= USER_ICON_MASKS_OFS) then
    result := i
   else
    result := i-startingImagesCount+USER_ICON_MASKS_OFS
end;

function idx_ico2img(i: integer): integer;
begin
  if i < USER_ICON_MASKS_OFS then
    result := i
   else
    result := i-USER_ICON_MASKS_OFS+startingImagesCount
end;


{$IFDEF HFS_GIF_IMAGES}
function stringToGif(s: RawByteString; gif: TgifImage=NIL):TgifImage;
var
  ss: TAnsiStringStream;
begin
  ss := TAnsiStringStream.create(s);
try
  if gif = NIL then
    gif := TGIFImage.Create();
  gif.loadFromStream(ss);
  result := gif;
finally ss.free end;
end; // stringToGif

function gif2str(gif: TgifImage): RawByteString;
var
//  stream: Tbytesstream;
  stream: TRawByteStringStream;
begin
  stream := TRawByteStringStream.create();
  gif.SaveToStream(stream);
//  setLength(result, stream.size);
//  move(stream.bytes[0], result[1], stream.size);
  Result := stream.dataString;
  stream.free;
end; // gif2str

function bmp2str(bmp: Tbitmap): RawByteString;
var
	gif: TGIFImage;
begin
  gif := TGIFImage.Create();
try
  gif.ColorReduction:=rmQuantize;
  gif.Assign(bmp);
  result:=gif2str(gif);
finally gif.free;
  end;
end; // bmp2str

function pic2str(idx:integer): RawByteString;
var
  ico: Ticon;
  gif: TgifImage;
begin
result:='';
if idx < 0 then exit;
idx:=idx_ico2img(idx);
if length(imagescache) <= idx then
  setlength(imagescache, idx+1);
result:=imagescache[idx];
if result > '' then exit;

ico:=Ticon.Create;
gif:=TGifImage.Create;
try
  IconsDM.images.getIcon(idx, ico);
  gif.Assign(ico);
  result:=gif2str(gif);
  imagescache[idx]:=result;
finally
  gif.Free;
  ico.free;
  end;
end; // pic2str

function str2pic(s: RawByteString): integer;
var
	gif: TGIFImage;
begin
  for result:=0 to IconsDM.images.count-1 do
    if pic2str(result) = s then
      exit;
// in case the pic was not found, it automatically adds it to the pool
  gif := stringToGif(s);
  try
    result := IconsDM.images.addMasked(gif.bitmap, gif.Bitmap.TransparentColor);
    etags.values['icon.'+intToStr(result)] := MD5PassHS(s);
   finally
    gif.free
  end;
end; // str2pic
{$ELSE ~HFS_GIF_IMAGES}
 {$IFDEF FMX}
function stringToPNG(const s: RawByteString; png: TBitmap=NIL): TBitmap;
 {$ELSE ~FMX}
function stringToPNG(const s: RawByteString; png: TpngImage=NIL): TpngImage;
 {$ENDIF FMX}
var
//  ss: TAnsiStringStream;
  ss: TRawByteStringStream;
begin
  ss := TRawByteStringStream.create(s);
try
  if png = NIL then
 {$IFDEF FMX}
    png := TBitmap.Create();
 {$ELSE ~FMX}
    png := TPNGImage.Create();
 {$ENDIF FMX}
  png.loadFromStream(ss);
  result := png;
finally ss.free end;
end; // stringToPNG

function gif2png(const s: RawByteString): RawByteString;
var
 {$IFNDEF FMX}
  gif: TgifImage;
 {$ENDIF ~FMX}
//  ss: TAnsiStringStream;
  ss: TRawByteStringStream;
  bmp: TBitmap;
begin
  Result := '';
  ss := TRawByteStringStream.create(s);
  bmp := TBitmap.Create;
  try
 {$IFDEF FMX}
    bmp.loadFromStream(ss);
 {$ELSE FMX}
    gif := TGIFImage.Create();
    gif.loadFromStream(ss);
    bmp.Assign(gif);
 {$ENDIF ~FMX}
    Result := bmp2str(bmp);
   finally
     ss.free;
     bmp.Free;
 {$IFNDEF FMX}
     gif.Free;
 {$ENDIF ~FMX}
  end;
end; // Gif2PNG

 {$IFDEF FMX}
function png2str(png: TBitmap): RawByteString;
 {$ELSE ~FMX}
function png2str(png: TpngImage): RawByteString;
 {$ENDIF FMX}
var
//  stream: Tbytesstream;
  stream: TRawByteStringStream;
begin
//  stream := Tbytesstream.create();
  stream := TRawByteStringStream.create();
  png.SaveToStream(stream);
  Result := stream.DataString;
//  setLength(result, stream.size);
//  move(stream.bytes[0], result[1], stream.size);
  stream.free;
end; // png2str

function bmp2str(bmp: Tbitmap): RawByteString;
const
  PixelsQuad = MaxInt div SizeOf(TRGBQuad) - 1;
type
  TRGBAArray = Array [0..PixelsQuad - 1] of TRGBQuad;
  PRGBAArray = ^TRGBAArray;
 {$IFNDEF FMX}
var
  png: TPNGImage;
  RowInOut: PRGBAArray;
  RowAlpha: PByteArray;
 {$ENDIF FMX}
begin
 {$IFDEF FMX}
  result := png2str(bmp);
 {$ELSE ~FMX}
  png := TPNGImage.Create();
  try
  //  png.ColorReduction:=rmQuantize;
   {$IFDEF FPC}
    png.LoadFromBitmapHandles(bmp.Handle, bmp.MaskHandle);
   {$ELSE ~FPC}
    png.Assign(bmp);
   {$IFDEF FMX}
    if bmp.PixelFormat in [TPixelFormat.RGBA, TPixelFormat.BGRA, TPixelFormat.RGBA16] then
   {$ELSE ~FMX}
    if bmp.PixelFormat = pf32bit then
   {$ENDIF FMX}
      begin
        PNG.CreateAlpha;
        for var Y:=0 to Bmp.Height - 1 do
        begin
          RowInOut := Bmp.ScanLine[Y];
          RowAlpha := PNG.AlphaScanline[Y];
          for var X:=0 to Bmp.Width - 1 do
            RowAlpha[X] := RowInOut[X].rgbReserved;
        end;
      end;
   {$ENDIF ~FPC}
    result := png2str(png);
  finally png.free;
  end;
 {$ENDIF FMX}
end; // bmp2str

function pic2str(idx: integer; imgSize: Integer): RawByteString;
var
  bmp: TBitmap;
begin
  Result := '';
  if idx < 0 then
    exit;
  idx := idx_ico2img(idx);
  if length(imagescacheSm) <= idx then
    begin
      setlength(imagescacheSm, idx+1);
      setlength(imagescacheBg, idx+1);
    end;
  if imgSize = ImageSizeSmall then
    Result := imagescacheSm[idx]
   else
  if imgSize = ImageSizeBig then
    Result := imagescacheBg[idx];

  if Result > '' then
    exit;

  bmp := nil;
  try
    bmp := IconsDM.GetBitmap(idx, imgSize);

    if Assigned(bmp) then
     begin
       result := bmp2str(bmp);

      if imgSize = ImageSizeSmall then
        imagescacheSm[idx] := Result
       else
      if imgSize = ImageSizeBig then
        imagescacheBg[idx] := Result;
     end;
  finally
    if Assigned(bmp) then
      bmp.Free;
  end;
end; // pic2str

function ico2str(hndl: THandle; icoNdx: Integer; imgSize: Integer): RawByteString;
var
  bmp: TBitmap;
begin
  Result := '';
    bmp := TBitmap.Create;
    try
      bmp.PixelFormat := pf32bit;
      bmp.SetSize(imgSize, imgSize);
      ImageList_DrawEx(hndl, icoNdx, bmp.Canvas.Handle, 0, 0, imgSize, ImgSize, CLR_NONE, CLR_NONE, ILD_SCALE or ILD_PRESERVEALPHA);
      Result := bmp2str(bmp);
     finally
      bmp.Free;
    end;
end;

function ico2bmp(hndl: THandle; icoNdx: Integer; imgSize: Integer): TBitmap;
 //var
   //bmp: TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf32bit;
    Result.SetSize(imgSize, imgSize);
  {$IFDEF FPC}  Result.BeginUpdate(True); {$ENDIF FPC}
    ImageList_DrawEx(hndl, icoNdx, Result.Canvas.Handle, 0, 0, imgSize, ImgSize, CLR_NONE, CLR_NONE, ILD_SCALE or ILD_PRESERVEALPHA);
  {$IFDEF FPC}  Result.EndUpdate; {$ENDIF FPC}
   finally
    //bmp.Free;
  end;
end;

function str2pic(const s: RawByteString; imgSize: Integer): Integer;
var
   {$IFDEF FMX}
	png: TBitmap;
   {$ELSE FMX}
//	png: TPNGImage;
  str: TRawByteStringStream;
   {$ENDIF FMX}
  i: Integer;
begin
  for result:=0 to IconsDM.images.count-1 do
    if pic2str(result, imgSize) = s then
      exit;
// in case the pic was not found, it automatically adds it to the pool
   {$IFDEF FMX}
  png := stringToPNG(s);
   {$ENDIF FMX}
  try
   {$IFDEF FMX}
    i := IconsDM.images.count;
    IconsDM.images.AddOrSet(IntToStr(i), [], []);//, i);
    var bi: tcustombitmapItem;
    var sz: TSize;
    IconsDM.images.BitmapItemByName(IntToStr(i), bi, sz);
    bi.Bitmap.Assign(png);
   {$ELSE ~FMX}
    str := TRawByteStringStream.Create(s);
    if imgSize = ImageSizeBig then
      i := IconsDM.images.count-1
     else
      i := IconsDM.images.count;

    IconsDM.imgCollection.Add(IntToStr(i), str);
    if IconsDM.images.GetIndexByName(IntToStr(i)) < 0 then
      IconsDM.images.Add(IntToStr(i), IntToStr(i));
    str.free;
   {$ENDIF FMX}
    Result := i;
    etags.values['icon.'+intToStr(result)] := MD5PassHS(s);
   finally
   {$IFDEF FMX}
    png.free
   {$ENDIF FMX}
  end;
end; // str2pic

function strGif2pic(const gs: RawByteString; imgSize: Integer):integer;
var
  ps: RawByteString;
begin
  ps := gif2png(gs);
  Result := str2pic(ps, imgSize);
end; // str2pic
{$ENDIF HFS_GIF_IMAGES}

function stringPNG2BMP(const s: RawByteString): TBitmap;
var
  ss: TRawByteStringStream;
   {$IFNDEF FMX}
  png: TPNGImage;
   {$ENDIF FMX}
begin
  Result := NIL;
  if s = '' then
    Exit(NIL);
  ss := TRawByteStringStream.create(s);
   {$IFDEF FMX}
  result := TBitmap.Create;
  try
    Result.LoadFromStream(ss);
  finally
    ss.free;
  end;
   {$ELSE ~FMX}
  png := TPngImage.Create;
  try
    png.LoadFromStream(ss);
  finally
    ss.free;
  end;
  if png.Height > 0 then
    begin
      result := TBitmap.Create;
      png.AssignTo(Result);
    end;
   {$ENDIF FMX}
end;

function TIconsDM.GetBitmap(idx: Integer; Size: Integer): TBitmap;
begin
 {$IFDEF FMX}
  result := Images.Bitmap(TSizeF.Create(Size, Size), idx);
 {$ELSE FMX}
 {$IFDEF FPC}
  Result := NIL;
  if Self.images.Count > idx then
   begin
    Result := TBitmap.Create;
    Result.SetSize(Size, Size);
    Self.images.GetBitmap(idx, Result);
   end;
 {$ELSE ~FPC}
  Result:= imgCollection.GetBitmap(idx, size, size);
 {$ENDIF FPC}
 {$ENDIF FMX}
end;

function TIconsDM.getImageIndexForFile(fn: String): Integer;
var
  newIdx, n: integer;
  shfi: TShFileInfo;
  sR16, sR32: RawByteString;
  bmp: TBitmap;
  str: TRawByteStringStream;
//  iconX, iconY: Integer;
begin
  ZeroMemory(@shfi, SizeOf(TShFileInfo));
 try
  imgCS.Acquire;
// documentation reports shGetFileInfo() to be working with relative paths too,
// but it does not actually work without the expandFileName()
  shGetFileInfo( pchar(expandFileName(fn)), 0, shfi, SizeOf(shfi), SHGFI_SYSICONINDEX);
  if shfi.iIcon = 0 then
   begin
    result := ICON_FILE;
    exit;
   end;
  // as reported by official docs
  if shfi.hIcon <> 0 then
    destroyIcon(shfi.hIcon);

  sR16 := '';
  sR32 := '';
   {$IFNDEF FMX}

  // have we already met this sysidx before?
  if length(sysidx2index) > 0 then
   for var i:=0 to length(sysidx2index)-1 do
    if sysidx2index[i].sysidx = shfi.iIcon then
      begin
        result := sysidx2index[i].idx;
        exit;
      end;
  // found not, let's check deeper: byte comparison.
  // we first add the ico to the list, so we can use pic2str()

  // 16x16
    sR16 := ico2str(IconsDM.systemimages.Handle, shfi.iIcon, ImageSizeSmall);
  // 32x32
    sR32 := ico2str(IconsDM.systemimages.Handle, shfi.iIcon, ImageSizeBig);

    if (sR16 > '') or (sR32 > '') then
    begin
      newIdx := IconsDM.imgCollection.count;
      if sR16 > '' then
       begin
        str := TRawByteStringStream.Create(sR16);
        IconsDM.imgCollection.add(IntToStr(newIdx), str);
        str.free;
       end;
      if sR32 > '' then
       begin
        str := TRawByteStringStream.Create(sR32);
        IconsDM.imgCollection.add(IntToStr(newIdx), str);
        str.free;
       end;

      IconsDM.images.Add(IntToStr(newIdx), newIdx);
  //    sR:=pic2str(i);
      etags.values['icon.'+intToStr(newIdx)] := MD5PassHS(sR16);
    end
    else
     {$ENDIF ~FMX}
     newIdx := -1;
  //  i:=mainfrm.images.addIcon(ico);
  // now we can search if the icon was already there, by byte comparison
  n:=0;
     {$IFNDEF FMX}
    if newIdx >= 0 then
      while n < length(sysidx2index) do
        begin
        if pic2str(sysidx2index[n].idx, ImageSizeSmall) = sR16 then
          begin // found, delete the duplicate
          IconsDM.imgCollection.delete(newIdx);
          IconsDM.images.Delete(IntToStr(newIdx));
          setlength(imagescacheSm, newIdx);
          setlength(imagescacheBg, newIdx);
          newIdx := sysidx2index[n].idx;
          break;
          end;
        inc(n);
        end;
    if (newIdx >= length(imagescacheSm)) then
      begin
        setLength(imagescacheSm, newIdx+1);
        setLength(imagescacheBg, newIdx+1);
      end;
    if (newIdx>=0) and (imagescacheSm[newIdx] = '') then
      imagescacheSm[newIdx] := sR16;
    if (newIdx>=0) and (imagescacheBg[newIdx] = '') then
      imagescacheBg[newIdx] := sR32;
     {$ENDIF ~FMX}

  n := length(sysidx2index);
  setlength(sysidx2index, n+1);
  sysidx2index[n].sysidx:=shfi.iIcon;
  sysidx2index[n].idx:= newIdx;
  result := newIdx;
 finally
  imgCS.Release;
 end;
end; // getImageIndexForFile

function idx_label(i: Integer): String;
begin
  result := intToStr(idx_img2ico(i))
end;


end.
