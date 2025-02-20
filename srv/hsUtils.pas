{
Copyright (C) 2002-2020 Massimo Melina (www.rejetto.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


HTTP Server Utils

}
{$I- }

unit HSUtils;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  classes, messages,
  contnrs, strUtils,
  types
  ;


// decode/decode url
function decodeURL(const url: String; utf8: Boolean=TRUE): UnicodeString; OverLoad;
function decodeURL(const url: RawByteString): UnicodeString; OverLoad;
function encodeURL(const url: String; nonascii: Boolean=TRUE; spaces: Boolean=TRUE;
  htmlEncoding: Boolean=FALSE):string; OverLoad;
function encodeURL(const url: RawByteString; nonascii: Boolean=TRUE; spaces: Boolean=TRUE;
  unicode: boolean=FALSE): RawByteString; OverLoad;
// returns true if address is not suitable for the internet
function isLocalIP(const ip: String): Boolean;
// ensure a string ends with a specific string
procedure includeTrailingString(var s: UnicodeString; const ss: UnicodeString); OverLoad;
procedure includeTrailingString(var s: RawByteString; const ss: RawByteString); OverLoad;
// gets unicode code for specified character
function charToUnicode(c: WideChar): dword; OverLoad;
function charToUnicode(c: AnsiChar): dword; OverLoad;
// this version of pos() is able to skip the pattern if inside quotes
{$IFDEF UNICODE}
function nonQuotedPos(const ss, s: String; ofs: Integer=1; const quote: String='"'; const unquote: String='"'): Integer; OverLoad;
{$ENDIF UNICODE}
function nonQuotedPos(const ss, s: RawByteString; ofs: integer=1; const quote: RawByteString='"'; const unquote: RawByteString='"'): Integer; OverLoad;
// case insensitive version
//function ipos(ss, s:string; ofs:integer=1):integer; overload;
function getNameOf(const s: String): String; OverLoad; // colon included
function getNameOf(const s: RawByteString): RawByteString; OverLoad; // colon included
function namePos(const name: string; const headers:string; from:integer=1):integer; OverLoad;
function namePos(const name: RawByteString; const headers: RawByteString; from: integer=1):integer; OverLoad;

implementation

uses
  Windows, sysutils,
{$IFDEF UNICODE}
  AnsiStrings,
//  AnsiClasses,
{$ENDIF UNICODE}
  OverbyteIcsWSocket,
  RDUtils,
  srvConst;

const
  HEADER_LIMITER: RawByteString = CRLFA+CRLFA;
  MAX_REQUEST_LENGTH = 64*1024;
  MAX_INPUT_BUFFER_LENGTH = 256*1024;
  HexCharsW: set of Char = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
                            'A', 'B', 'C', 'D', 'E', 'F']; //
procedure includeTrailingString(var s: UnicodeString; const ss: UnicodeString);
begin if copy(s, length(s)-length(ss)+1, length(ss)) <> ss then s:=s+ss end;

procedure includeTrailingString(var s: RawByteString; const ss: RawByteString);
begin
  if copy(s, length(s)-length(ss)+1, length(ss)) <> ss then
    s:=s+ss
end;

function charToUnicode(c: WideChar):dword;
begin stringToWideChar(c,@result,4) end;

function charToUnicode(c: AnsiChar):dword;
begin stringToWideChar(c,@result,4) end;

function isLocalIP(const ip:string):boolean;
var
  r: record d,c,b,a:byte end;
begin
  if ip = '::1' then
    exit(TRUE);
  if ip = '' then
    exit(False);
 {$IFDEF FPC}
  dword(r) := WSocket_ntohl(WSocket_inet_addr(@ip[1]));
 {$ELSE FPC}
  dword(r) := dword(WSocket_ntohl(WSocket_inet_addr(ansiString(ip))));
 {$ENDIF FPC}
result:=(r.a in [0,10,23,127])
  or (r.a = 192) and ((r.b = 168) or (r.b = 0) and (r.c = 2))
  or (r.a = 169) and (r.b = 254)
  or (r.a = 172) and (r.b in [16..31])
end; // isLocalIP

function min(a,b:integer):integer;
begin if a < b then result:=a else result:=b end;



{$IFDEF UNICODE}
function nonQuotedPos(const ss, s: String; ofs: Integer=1; const quote: String='"'; const unquote: String='"'): Integer; OverLoad;
var
  qpos: integer;
begin
  repeat
    result := posEx(ss, s, ofs);
    if result = 0 then
      exit;

    repeat
      qpos := posEx(quote, s, ofs);
      if qpos = 0 then
        exit; // there's no quoting, our result will fit
      if qpos > result then
        exit; // the quoting doesn't affect the piece, accept the result
      ofs := posEx(unquote, s, qpos+1);
      if ofs = 0 then
        exit; // it is not closed, we don't consider it quoting
      inc(ofs);
    until ofs > result; // this quoting was short, let's see if we have another
  until false;
end; // nonQuotedPos
{$ENDIF UNICODE}

function nonQuotedPos(const ss, s: RawByteString; ofs: integer=1; const quote: RawByteString='"'; const unquote: RawByteString='"'):integer; OverLoad;
var
  qpos: integer;
begin
  repeat
  result:=posEx(ss, s, ofs);
  if result = 0 then exit;

    repeat
    qpos:=posEx(quote, s, ofs);
    if qpos = 0 then exit; // there's no quoting, our result will fit
    if qpos > result then exit; // the quoting doesn't affect the piece, accept the result
    ofs:=posEx(unquote, s, qpos+1);
    if ofs = 0 then exit; // it is not closed, we don't consider it quoting
    inc(ofs);
    until ofs > result; // this quoting was short, let's see if we have another
  until false;
end; // nonQuotedPos

function decodeURL(const url: string; utf8: boolean=TRUE): UnicodeString;
var
  i, l: integer;
  c: char;
  resA: RawByteString;
  ca: AnsiChar;
  c1, c2: Char;
  hv: Boolean;
begin
  setLength(result, length(url));
  if length(url) = 0 then
    Exit;
  setLength(resA, length(url));
  l := 0;
  i := 1;
  while i<=length(url) do
    begin
      hv := False;
      if (url[i] = '%') and (i+2 <= length(url)) then
        begin
          c1 := url[i+1];
          c2 := url[i+2];
          if (c1 in HexCharsW) and
             (c2 in HexCharsW) then
            try
              if utf8 then
                ca := AnsiChar(strToInt( '$'+c1+c2 ))
               else
                c := char(strToInt( '$'+c1+c2 ));
              inc(i,2); // three chars for one
              hv := True;
             except
              hv := False;
            end;
        end;

     if not hv then
       if utf8 then
         ca := AnsiChar(url[i])
        else
         c := url[i];

     inc(i);
     inc(l);
        if utf8 then
          resA[l] := ca
         else
          result[l] := c;
    end;
  if utf8 then
    begin
     setLength(resA, l);
     Result := UnUTF(resA);
    end
   else
    setLength(result, l);
end; // decodeURL

function decodeURL(const url: RawByteString): UnicodeString;
var
  i, l: integer;
  resA: RawByteString;
  c: AnsiChar;
begin
  setLength(result, length(url));
  setLength(resA, length(url));
  l := 0;
  i := 1;
  while i<=length(url) do
    begin
      if (url[i] = '%') and (i+2 <= length(url)) then
        try
          c := AnsiChar(strToIntA(RawByteString('$')+url[i+1]+url[i+2] ));
          inc(i,2); // three chars for one
        except
          c := url[i];
        end
      else
       c := url[i];

      inc(i);
      inc(l);
      resA[l] := c;
    end;
  setLength(resA, l);
  Result := UnUTF(resA);
end; // decodeURL


function encodeURL(const url:string; nonascii:boolean=TRUE; spaces:boolean=TRUE;
  htmlEncoding:boolean=FALSE):string;
var
  i: integer;
  encodePerc, encodeHTML: TcharSetW;
  encodePercA: TcharSetA;
  a: RawByteString;
begin
result:='';
if url = '' then
  exit;
encodeHTML:=[];
encodePercA := [];
if nonascii then
  encodePercA:=[#0..#31,'#','%','?','"','''','&','<','>',':'] + [#128..#255];
encodePerc:=[#0..#31,'#','%','?','"','''','&','<','>',':'];
// actually ':' needs encoding only in relative url
if spaces then include(encodePerc,' ');
if not htmlEncoding then
  begin
  encodePerc:=encodePerc+encodeHTML;
  encodeHTML:=[];
  end;
if nonascii then
  begin
  a:=UTF8encode(url); // couldn't find a better way to force url to have the UTF8 encoding
  for i:=1 to length(a) do
    if a[i] in encodePercA then
      result:=result+'%'+intToHex(ord(a[i]),2)
    else if a[i] in encodeHTML then
      result:=result+'&#'+intToStr(charToUnicode(a[i]))+';'
    else
      result:=result+a[i];
  end
 else
for i:=1 to length(url) do
	if url[i] in encodePerc then
    result:=result+'%'+intToHex(ord(url[i]),2)
  else if url[i] in encodeHTML then
    result:=result+'&#'+intToStr(charToUnicode(url[i]))+';'
  else
    result:=result+url[i];
end; // encodeURL

function encodeURL(const url: RawByteString; nonascii:boolean=TRUE; spaces:boolean=TRUE;
  unicode:boolean=FALSE): RawByteString;
var
  i: integer;
  encodePerc, encodeUni: set of AnsiChar;
begin
  result := '';
  encodeUni := [];
  if nonascii then
    encodeUni:=[#128..#255];
  encodePerc := [#0..#31,'#','%','?','"','''','&','<','>',':'];
  // actually ':' needs encoding only in relative url
  if spaces then
    include(encodePerc,' ');
  if not unicode then
   begin
    encodePerc:=encodePerc+encodeUni;
    encodeUni:=[];
   end;
  for i:=1 to length(url) do
	  if url[i] in encodePerc then
      result := result+'%'+IntToHexA(ord(url[i]),2)
     else if url[i] in encodeUni then
      result := result+'&#'+IntToStrA(Byte(url[i]))+';'
  else
    result := result+url[i];
end; // encodeURL

function replyHeader_IntPositive(const name: String; int: Int64): String;
begin
  result := '';
  if int >= 0 then
    result := name+': '+intToStr(int)+CRLF;
end;

{
function replyHeader_Str(const name:string; const str:string):string;
begin
result:='';
if str > '' then result:=name+': '+str+CRLF;
end;
}
function replyHeader_Str(const name:RawByteString; const str:RawByteString): RawByteString; OverLoad;
begin
result:='';
if str > '' then result:=name+': '+str+CRLFA;
end;

function replyHeader_Str(const name:RawByteString; const str:String): RawByteString; OverLoad;
begin
result:='';
if str > '' then result:=name+': '+ StrToUTF8(str)+CRLFA;
end;

function getNameOf(const s:string):string; // colon included
begin result:=copy(s, 1, pos(':', s)) end;

function getNameOf(const s: RawByteString): RawByteString; // colon included
begin result:=copy(s, 1, pos(RawByteString(':'), s)) end;

// return 0 if not found
function namePos(const name:string; const headers:string; from:integer=1):integer;
begin
result:=from;
  repeat
  result:=ipos(name, headers, result);
  until (result<=1) // both not found and found at the start of the string
    or (headers[result-1] = #10) // or start of the line
end; // namePos

function namePos(const name: RawByteString; const headers: RawByteString; from: integer=1):integer; OverLoad;
begin
 result := from;
  repeat
    result := ipos(name, headers, result);
  until (result<=1) // both not found and found at the start of the string
    or (headers[result-1] = #10) // or start of the line
end; // namePos

end.
