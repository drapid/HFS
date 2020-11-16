unit IconsLib;
{$I NoRTTI.inc}

interface

uses
  Windows, System.SysUtils, System.Classes, Graphics, System.ImageList, Vcl.ImgList,
  Vcl.BaseImageCollection, Vcl.ImageCollection, Controls, CommCtrl,
//  Vcl.Imaging.gifimg,
  Vcl.Imaging.pngImage,
  Vcl.VirtualImageList
  ;

type
  TIconsDM = class(TDataModule)
    ImgCollection: TImageCollection;
    images: TVirtualImageList;
    constructor Create(AOwner: TComponent); override;
  private
    { Private declarations }
  public
    { Public declarations }
    systemimages: Timagelist;    // system icons
  end;

  function idx_img2ico(i:integer):integer;
  function idx_ico2img(i:integer):integer;

  {$IFDEF HFS_GIF_IMAGES}
  function stringToGif(s: RawByteString; gif:TgifImage=NIL):TgifImage;
  function gif2str(gif:TgifImage): RawByteString;
  {$ELSE ~HFS_GIF_IMAGES}
  function stringToPNG(const s: RawByteString; png: TpngImage=NIL):TpngImage;
  function png2str(png:TPngImage): RawByteString;
  {$ENDIF HFS_GIF_IMAGES}
  function bmp2str(bmp:Tbitmap): RawByteString;
  function pic2str(idx:integer; imgSize: Integer): RawByteString;
  function str2pic(const s: RawByteString; imgSize: Integer):integer;
  function getImageIndexForFile(fn:string):integer;

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
   AnsiClasses, ansiStrings, WinApi.ShellAPI,
   RnQCrypt,
   srvVars;

var
  imagescache: array of RawByteString;
  sysidx2index: array of record sysidx, idx:integer; end; // maps system imagelist icons to internal imagelist

function Shell_GetImageLists(var hl,hs:Thandle):boolean; stdcall; external 'shell32.dll' index 71;

function getSystemimages():TImageList;
var
  hl, hs: Thandle;
begin
  result := NIL;
  if not Shell_GetImageLists(hl,hs) then exit;
  result := Timagelist.Create(NIL);
    Result.ColorDepth := cd32Bit;
  result.ShareImages := TRUE;
  result.handle := hs;
end; // loadSystemimages


constructor TIconsDM.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  systemimages := getSystemimages();
  images.Masked := false;
  images.ColorDepth := cd32bit;
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
    gif:=TGIFImage.Create();
  gif.loadFromStream(ss);
  result:=gif;
finally ss.free end;
end; // stringToGif

function gif2str(gif:TgifImage): RawByteString;
var
  stream: Tbytesstream;
begin
stream:=Tbytesstream.create();
gif.SaveToStream(stream);
setLength(result, stream.size);
move(stream.bytes[0], result[1], stream.size);
stream.free;
end; // gif2str

function bmp2str(bmp:Tbitmap): RawByteString;
var
	gif: TGIFImage;
begin
gif:=TGIFImage.Create();
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

function str2pic(s: RawByteString):integer;
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
function stringToPNG(const s: RawByteString; png: TpngImage=NIL):TpngImage;
var
  ss: TAnsiStringStream;
begin
  ss := TAnsiStringStream.create(s);
try
  if png = NIL then
    png:=TPNGImage.Create();
  png.loadFromStream(ss);
  result:=png;
finally ss.free end;
end; // stringToGif

function png2str(png:TpngImage): RawByteString;
var
  stream: Tbytesstream;
begin
stream:=Tbytesstream.create();
png.SaveToStream(stream);
setLength(result, stream.size);
move(stream.bytes[0], result[1], stream.size);
stream.free;
end; // gif2str

function bmp2str(bmp:Tbitmap): RawByteString;
const
  PixelsQuad = MaxInt div SizeOf(TRGBQuad) - 1;
type
  TRGBAArray = Array [0..PixelsQuad - 1] of TRGBQuad;
  PRGBAArray = ^TRGBAArray;
var
	png: TPNGImage;
  RowInOut: PRGBAArray;
  RowAlpha: PByteArray;
begin
png:=TPNGImage.Create();
try
//  png.ColorReduction:=rmQuantize;
  png.Assign(bmp);
  if bmp.PixelFormat = pf32bit then
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
  result:=png2str(png);
finally png.free;
  end;
end; // bmp2str

function pic2str(idx:integer; imgSize: Integer): RawByteString;
var
  bmp: TBitmap;
begin
  result := '';
  if idx < 0 then
    exit;
  idx := idx_ico2img(idx);
  if length(imagescache) <= idx then
    setlength(imagescache, idx+1);
  result := imagescache[idx];
  if result > '' then
    exit;

  try
    bmp := IconsDM.ImgCollection.GetBitmap(idx, imgSize, imgSize);

    if Assigned(bmp) then
     begin
       result := bmp2str(bmp);
       imagescache[idx]:=result;
     end;
  finally
    if Assigned(bmp) then
      bmp.Free;
  end;
end; // pic2str

function str2pic(const s: RawByteString; imgSize: Integer):integer;
var
	png: TPNGImage;
  str: TAnsiStringStream;
  i: Integer;
begin
  for result:=0 to IconsDM.images.count-1 do
    if pic2str(result, imgSize) = s then
      exit;
// in case the pic was not found, it automatically adds it to the pool
  png := stringToPNG(s);
  try
    str := TAnsiStringStream.Create(s);
    i := IconsDM.images.count;
    IconsDM.imgCollection.Add(IntToStr(i), str);
    str.free;
    IconsDM.images.Add(IntToStr(i), i);
    Result := i;
    etags.values['icon.'+intToStr(result)] := MD5PassHS(s);
   finally
    png.free
  end;
end; // str2pic
{$ENDIF HFS_GIF_IMAGES}

function stringPNG2BMP(const s: RawByteString): TBitmap;
var
  ss: TAnsiStringStream;
  png: TPNGImage;
begin
  if s = '' then
    Exit(NIL);
  ss := TAnsiStringStream.create(s);
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
end;

procedure ClearAlpha(B: TBitmap);
type
  PRGBA = ^TRGBA;
  TRGBA = packed record
    case Cardinal of
      0: (Color: Cardinal);
      2: (HiWord, LoWord: Word);
      3: (B, G, R, A: Byte);
    end;
  PRGBAArray = ^TRGBAArray;
  TRGBAArray = array[0..0] of TRGBA;
var
  I: Integer;
  p: Pointer;
begin
{
  p := B.Scanline[B.Height - 1];
  if p <> NIL then
    for I := 0 to B.Width * B.Height - 1 do
      PRGBAArray(P)[I].A := 1;
}
  for var j := 0 to b.Height -1 do
    begin
      p := B.Scanline[j];

      if p <> NIL then
       for i := 0 to B.Width - 1 do
         begin
           PRGBAArray(P)[I].A := 5;
           PRGBAArray(P)[I].r := 222;
//           PRGBAArray(P)[I].b := 9;
         end;
    end;
end;

function getImageIndexForFile(fn:string):integer;
var
  i, n: integer;
  shfi: TShFileInfo;
  sR16, sR32: RawByteString;
  bmp: TBitmap;
  str: TAnsiStringStream;
  iconX, iconY: Integer;
begin
  ZeroMemory(@shfi, SizeOf(TShFileInfo));
// documentation reports shGetFileInfo() to be working with relative paths too,
// but it does not actually work without the expandFileName()
shGetFileInfo( pchar(expandFileName(fn)), 0, shfi, SizeOf(shfi), SHGFI_SYSICONINDEX);
if shfi.iIcon = 0 then
  begin
  result:=ICON_FILE;
  exit;
  end;
// as reported by official docs
if shfi.hIcon <> 0 then
  destroyIcon(shfi.hIcon);

  sR16 := '';
  sR32 := '';

// have we already met this sysidx before?
for i:=0 to length(sysidx2index)-1 do
  if sysidx2index[i].sysidx = shfi.iIcon then
  	begin
    result:=sysidx2index[i].idx;
    exit;
    end;
// found not, let's check deeper: byte comparison.
// we first add the ico to the list, so we can use pic2str()

// 16x16
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(16, 16);
    ImageList_DrawEx(IconsDM.systemimages.Handle, shfi.iIcon, bmp.Canvas.Handle, 0, 0, 16, 16, CLR_NONE, CLR_NONE, ILD_SCALE or ILD_PRESERVEALPHA);
    sR16 := bmp2str(bmp);
//     saveFileA(IntToStr(i) + '.png', sR);
//    bmp.saveToStream(str);
   finally
    bmp.Free;
  end;
// 32x32
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(32, 32);
    ImageList_DrawEx(IconsDM.systemimages.Handle, shfi.iIcon, bmp.Canvas.Handle, 0, 0, 32, 32, CLR_NONE, CLR_NONE, ILD_SCALE or ILD_PRESERVEALPHA);
    sR32 := bmp2str(bmp);
//     saveFileA(IntToStr(i) + '.png', sR);
//    bmp.saveToStream(str);
   finally
    bmp.Free;
  end;
  if (sR16 > '') or (sR32 > '') then
  begin
    i:= IconsDM.imgCollection.count;
    if sR16 > '' then
     begin
      str := TAnsiStringStream.Create(sR16);
      IconsDM.imgCollection.add(IntToStr(i), str);
      str.free;
     end;
    if sR32 > '' then
     begin
      str := TAnsiStringStream.Create(sR32);
      IconsDM.imgCollection.add(IntToStr(i), str);
      str.free;
     end;

    IconsDM.images.Add(IntToStr(i), i);
//    sR:=pic2str(i);
    etags.values['icon.'+intToStr(i)] := MD5PassHS(sR16);
  end;
//  i:=mainfrm.images.addIcon(ico);
// now we can search if the icon was already there, by byte comparison
n:=0;
while n < length(sysidx2index) do
  begin
  if pic2str(sysidx2index[n].idx, 16) = sR16 then
    begin // found, delete the duplicate
    IconsDM.imgCollection.delete(i);
    IconsDM.images.Delete(IntToStr(i));
    setlength(imagescache, i);
    i:=sysidx2index[n].idx;
    break;
    end;
  inc(n);
  end;
  if (i >= length(imagescache)) then
    setLength(imagescache, i+1);
  if (i>=0) and (imagescache[i] = '') then
    imagescache[i] := sR16;

n:=length(sysidx2index);
setlength(sysidx2index, n+1);
sysidx2index[n].sysidx:=shfi.iIcon;
sysidx2index[n].idx:=i;
result:=i;
end; // getImageIndexForFile


end.
