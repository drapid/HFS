unit HFS.Tray;
{$I NoRTTI.inc}

interface

uses
  Windows, System.SysUtils, System.Classes, Graphics, System.ImageList, Vcl.ImgList,
  Vcl.BaseImageCollection, Vcl.ImageCollection, Controls, CommCtrl,
//  Vcl.Imaging.gifimg,
  Vcl.Imaging.pngImage,
  Vcl.VirtualImageList
  ;

  procedure drawTrayIconNumber(cnv: TCanvas; const s: String; size: Integer = 16); OverLoad;
  procedure drawTrayIconNumber(cnv: TCanvas; const n: Integer; size: Integer = 16); OverLoad
  function  getBaseTrayIcon(perc: real=0; size: Integer = 16): TBitmap;

implementation

uses
   AnsiClasses, ansiStrings, WinApi.ShellAPI,
   utilLib, iconsLib,
   srvVars, srvUtils;

var
  numbers: TBitmap;

function getBaseTrayIcon(perc: real=0; size: Integer = 16): TBitmap;
var
  x: integer;
  h, h2: Integer;
begin
  Result:= IconsDM.imgCollection.GetBitmap( if_(assigned(srv) and srv.active,24,30), size, size);
if perc > 0 then
  begin
    h := Result.Height;
  x:=round((h-2)*perc);
    h2 := h div 2 + 1;
  result.canvas.Brush.color:=clYellow;
  result.Canvas.FillRect(rect(1, h2, x+1, h-1));
  result.canvas.Brush.color:=clGreen;
  result.Canvas.FillRect(rect(x+1,h2,h-1, h-1));
  end;
end; // getBaseTrayIcon


procedure drawTrayIconNumber(cnv: TCanvas; const n: Integer; size: Integer = 16);
begin
  drawTrayIconNumber(cnv, intToStr(n), size);
end;

procedure drawTrayIconNumber(cnv: TCanvas; const s: String; size: Integer = 16);

var
  w, h, idx: integer;
  dx, dy, dw, dh: Integer;
begin
  if length(s) > 0 then
   begin
    dx := 10;
    dy := 8;
    w := numbers.Width div 11;
    h := numbers.Height;
    dx := MulDiv(dx, size, 16);
    dy := MulDiv(dy, size, 16);
    dw := MulDiv(4, size, 16);
    dh := MulDiv(6, size, 16);
    for var i:=length(s) downto 1 do
      begin
      if s[i] = '%' then idx:=10
      else idx:=ord(s[i])-ord('0');
      TransparentBlt(cnv.Handle, dx, dy, dw, dh, numbers.Canvas.Handle, idx*w, 0, w, h, $FF00FF);
      dec(dx, dw);
      end;
   end;
end; // drawTrayIconString

INITIALIZATION
var
  snum: RawByteString;
begin
  snum := getRes('NUMBERS', 'IMAGE');
  numbers := stringPNG2BMP(snum);
end;

end.
