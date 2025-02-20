unit srvUtils;
{$I DEFS.inc}
{$I NoRTTI.inc}

interface
uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF MSWINDOWS}
  Graphics,
  ShellAPI,
  Classes, Types,
   //RegularExpressions,
  regexpr,
  srvClassesLib,
  HSLib, srvConst;

type
  TreCB = procedure(re: TregExpr; var res: String; data: Pointer);

  function xtpl(src: UnicodeString; const table: array of UnicodeString): UnicodeString; OverLoad;
  function xtpl(src: RawByteString; table: array of RawByteString): RawByteString; OverLoad;
  function xtpl(src: UnicodeString; table: TMacroTableVal): UnicodeString; OverLoad;
  function escapeNL(s: String): String;
  function unescapeNL(s: String): String;
  function htmlEncode(const s: UnicodeString): UnicodeString;
  function substr(const s: RawByteString; start: Integer; upTo: Integer=0): RawByteString; inline; OverLoad;
  function substr(const s: UnicodeString; start: Integer; upTo: Integer=0): UnicodeString; inline; overload;
  function substr(const s: String; const after: String): String; overload;
 {$IFNDEF UNICODE}
  function replace(var s: String; const ss: String; start, upTo: Integer): Integer; OverLoad;
 {$ENDIF UNICODE}
  function replace(var s: UnicodeString; const ss: UnicodeString; start, upTo: Integer): Integer; OverLoad;
  function strAt(const s, ss: AnsiString; at: integer): Boolean; inline; OverLoad;
  function strAt(const s, ss: UnicodeString; at: integer): Boolean; inline; OverLoad;
  procedure enforceNUL(var s: UnicodeString); OverLoad;
  procedure enforceNUL(var s: RawbyteString); OverLoad;
  function  nonEmptyConcat(const pre, s: String; const post: String=''): String;
  function  dequote(const s:string; quoteChars:TcharSetW=['"']):string;
  function  removeStartingStr(const ss, s: String): String;
  procedure excludeTrailingString(var s: String; const ss: String); OverLoad;
 {$IFNDEF UNICODE}
  procedure excludeTrailingString(var s: UnicodeString; const ss: UnicodeString); OverLoad;
 {$ENDIF ~UNICODE}
  function  countSubstr(const ss: String; const s: String): Integer;
  function  smartsize(size: int64): String;
  function  elapsedToStr(t: TDateTime): String;
  function  dotted(i: Int64): String;
  function stringToColorEx(s: String; default: Tcolor=clNone):Tcolor;
  function reMatch(const s, exp: UnicodeString; mods: String='m'; ofs: Integer=1; subexp: PstringDynArray=NIL): Integer;
  function reReplace(const subj, exp, repl: String; const mods: String='m'): String;
  function reGet(const s, exp: String; subexpIdx:integer=1; const mods: String='!mi'; ofs:integer=1): String;
  function reCB(const expr, subj: UnicodeString; cb: TreCB; data: Pointer=NIL): UnicodeString;
  procedure apacheLogCb(re: TregExpr; var res: String; data: pointer);

 {$IFDEF UNICODE}
  function if_(v:boolean; const v1:string; const v2:string=''):string; overload; inline;
 {$ENDIF UNICODE}
  function if_(v: Boolean; const v1: RawByteString; const v2: RawByteString = ''): RawByteString; overload; inline;
  function if_(v:boolean; v1:int64; v2:int64=0):int64; overload; inline;
  function if_(v:boolean; v1:integer; v2:integer=0):integer; overload; inline;
  function if_(v:boolean; v1:Tobject; v2:Tobject=NIL):Tobject; overload; inline;
  function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean; overload; inline;
  function isExtension(const filename, ext: UnicodeString): Boolean;

  function swapMem(var src, dest; count: dword; cond: Boolean=TRUE): Boolean;

// strings array
  function  stringExists(const s: String; const a: array of String; isSorted: Boolean=FALSE): Boolean;
  function  removeString(var a: TStringDynArray; idx: integer; l: Integer=1): Boolean; overload;
  function  removeString(const s: String; var a: TStringDynArray; onlyOnce: Boolean=TRUE; ci: Boolean=TRUE; keepOrder: Boolean=TRUE): Boolean; overload;
  procedure removeStrings(const find: String; var a: TStringDynArray);
  procedure toggleString(const s: String; var ss: TStringDynArray);
  function  onlyString(const s: String; ss: TStringDynArray): boolean;
  function  addArray(var dst: TstringDynArray; src: array of string; where: Integer=-1; srcOfs: Integer=0; srcLn: Integer=-1): Integer; OverLoad;
  function  addArray(var dst: TMacroTableVal; src: array of String): Integer; OverLoad;
  function  removeArray(var src: TstringDynArray; toRemove:array of string):integer;
  function  split(const separator, s: String; nonQuoted: Boolean=FALSE): TStringDynArray;
  function  splitU(const s, separator: RawByteString; nonQuoted: Boolean=FALSE): TStringDynArray;
  function  join(const separator: String; ss: TStringDynArray): String;
  function  listToArray(l: Tstrings): TstringDynArray;
  function  arrayToList(a: TStringDynArray; list: TstringList=NIL): TstringList;
  procedure urlToStrings(const s: String; sl: Tstrings); OverLoad;
  procedure urlToStrings(const s: RawByteString; sl:Tstrings); OverLoad;

  function  toSA(a: array of UnicodeString): TstringDynArray; // this is just to have a way to typecast
  function  toMSA(a: array of UnicodeString): TMacroTableVal; // this is just to have a way to typecast
  function  addUniqueString(const s: String; var ss: TStringDynArray): Boolean;
  function  addString(const s: String; var ss: TStringDynArray): integer;
  function  replaceString(var ss: TStringDynArray; const old, new: String): Integer;
  function  popString(var ss: TstringDynArray): String;
  procedure insertString(const s: String; idx: Integer; var ss: TStringDynArray);
  function  addUniqueArray(var a:TstringDynArray; b:array of string): Integer;
  procedure uniqueStrings(var a:TstringDynArray; ci:Boolean=TRUE);
  procedure sortArray(var a:TStringDynArray);
  function  sortArrayF(const a:TStringDynArray):TStringDynArray;
  function  idxOf(const s: String; a:array of string; isSorted:boolean=FALSE): Integer;

  function match(mask, txt: pchar; fullMatch:boolean=TRUE; charsNotWildcard: TcharsetW=[]): Integer;
  function filematch(mask: String; const fn: String): Boolean;
  function validFilepath(const fn: UnicodeString; acceptUnits: Boolean=TRUE): Boolean;
  function validFilename(const s: String): Boolean;
  function isAbsolutePath(const path: String): Boolean;
  function newMtime(const fn: String; var previous: Tdatetime): Boolean;
  function checkAddressSyntax(address: String; mask: Boolean=TRUE): Boolean;
  function hostFromURL(const s: String): String;
  function poss(chars: TcharSetW; s: String; ofs: Integer=1): Integer;
  function strToCharset(const s: string): TcharsetW;
  function anycharIn(const chars, s:string):boolean; overload;
  function anycharIn(chars: TcharsetW; const s: String): Boolean; overload;
  function stripChars(s: String; cs: TcharsetW; invert: boolean=FALSE): String;
  function singleLine(const s: string): boolean;
  function findEOL(const s:string; ofs:integer=1; included:boolean=TRUE):integer;
  function quoteIfAnyChar(const badChars: String; s:string; const quote:string='"'; const unquote:string='"'):string;
  function getKeyFromString(const s: UnicodeString; key: UnicodeString; const def: UnicodeString=''): UnicodeString;
  function setKeyInString(s: UnicodeString; key: UnicodeString; val: UnicodeString=''): UnicodeString;
  function getMtimeUTC(const filename: UnicodeString): Tdatetime;
  function getMtime(const filename: String): Tdatetime;
  function getStr(from, to_: pAnsichar): RawByteString; OverLoad;
  function getStr(from, to_: pchar): String; OverLoad;
 {$IFDEF UNICODE}
  function getTill(const ss, s: String; included: Boolean=FALSE): String; overload;
  function getTill(i: Integer; const s: String): String; overload;
 {$ENDIF UNICODE}
  function getTill(const ss, s: RawByteString; included:boolean=FALSE): RawByteString; OverLoad;
  function getTill(i:integer; const s: RawByteString): RawByteString; OverLoad;
  function getSectionAt(p: pchar; out name: String): Boolean;
  function isSectionAt(p: pChar): boolean;

  function name2mimetype(const fn: String; const default: RawByteString): RawByteString;

  function strSHA256(const s: String): String;
  function strMD5(const s: String): String;
  function getCRC(const data: RawByteString): Integer;


  function ipToInt(const ip:string):dword;
  function addressmatch(mask: String; const address: string):boolean;

  function b64utf8(const s:string): RawByteString;
  function b64utf8S(const s:string): String;
  function b64utf8W(const s:string): UnicodeString;
  function decodeB64utf8(const s: RawByteString):string; OverLoad;
  function decodeB64utf8(const s: String):string; OverLoad;
  function decodeB64(const s: String): RawByteString; OverLoad;
  function decodeB64(const s: RawByteString): RawByteString; OverLoad;
  function b64U(const b: RawByteString): UnicodeString;
  function b64R(const b: RawByteString): RawByteString;
  function jsEncode(s: String; const chars: String): String;

  function TLV(t: Integer; const data: RawByteString): RawByteString;
  function TLVS(t: Integer; const data: String): RawByteString;
  function TLVI(t: Integer; data: Integer): RawByteString;
  function TLV_NOT_EMPTY(t: Integer; const data: RawByteString): RawByteString;
  function TLVS_NOT_EMPTY(t: Integer; const data: String): RawByteString;

  function dt_(const s: RawByteString): TDatetime;
  function int_(const s: RawByteString): Integer;
  function str_(i: integer): RawByteString; overload;
  function str_(t: Tdatetime): RawByteString; overload;
  function str_(b: boolean): RawByteString; overload;
  function int0(i, digits: integer): String;

  function compare_(i1, i2: double): integer; overload;
  function compare_(i1, i2: int64): integer; overload;
  function compare_(i1, i2: integer): integer; overload;
  function minmax(min, max, v: Integer): Integer; inline;

  function first(a, b: integer): Integer; overload;
  function first(a, b: double): Double; overload;
  function first(a, b: pointer): Pointer; overload;
  function first(const a, b: String): String; overload;
  function first(a: array of string): String; overload;
  function first(a: array of RawByteString): RawByteString; overload;

  function diskSpaceAt(path: String): Int64;
  function getRes(name: PChar; const typ: string='TEXT'): RawByteString;
  function getResText(name: PChar): RawByteString;

  function accountExists(const user: String; evenGroups: Boolean=FALSE): Boolean;
  function getAccount(const user: String; evenGroups: Boolean=FALSE): Paccount;
  function accountRecursion(account: Paccount; stopCase: TaccountRecursionStopCase; data: pointer=NIL; data2: pointer=NIL): Paccount;
  function findEnabledLinkedAccount(account: Paccount; over: TStringDynArray; isSorted: Boolean=FALSE): Paccount;
  function onlyExistentAccounts(a: TstringDynArray): TstringDynArray;
{$IFDEF MSWINDOWS}
  function filetimeToDatetime(ft: TFileTime): Tdatetime;
{$ENDIF}
{$IFDEF POSIX}
  function filetimeToDatetime(ft: time_t): Tdatetime;
{$ENDIF}
  function dateToHTTP(gmtTime: Tdatetime): String; overload;
  function dateToHTTP(const filename: String): String; overload;
  function dateToHTTPr(const filename: String): RawByteString; overload;
  function dateToHTTPr(gmtTime: Tdatetime): RawByteString; overload;
  function maybeUnixTime(t: TDateTime): TDateTime;
  function localToGMT(d: TDateTime):TDateTime;

  function reduceSpaces(s: UnicodeString; const replacement: UnicodeString=' '; spaces:TcharSetW=[]): UnicodeString;

  function dirCrossing(const s: UnicodeString): boolean;
  function fileOrDirExists(const fn: UnicodeString): boolean;
  function getEtag(const filename: UnicodeString): String;
  function hasJunction(const fn: UnicodeString): UnicodeString;
  function deltree(path: UnicodeString): Boolean;
  function forceDirectory(path: UnicodeString): Boolean;
  function moveToBin(const fn: UnicodeString; force: Boolean=FALSE): Boolean; overload;
  function moveToBin(files: TUnicodeStringDynArray; force: Boolean=FALSE): Boolean; overload;
  function saveFileA(fn: String; const data: RawByteString; append:boolean=FALSE): boolean; overload;   // Use RDFileUtil instead!
  function saveFileA(var f: File; const data: RawByteString): boolean; overload;
  function saveFileU(fn: String; const data: UnicodeString; append: Boolean=FALSE): Boolean; overload;   // Use RDFileUtil instead!
  function appendFileU(const fn: String; const data: UnicodeString): Boolean;
  function appendFileA(const fn: String; const data: RawByteString): Boolean;
  function moveFile(const src, dst: String; op: UINT=FO_MOVE): Boolean;
  function copyFile(const src, dst: String): Boolean;

  function captureExec(const DosApp: string; out output: String; out exitcode: Cardinal; timeout: Real=0): Boolean;

  function localDNSget(const ip: String): String;

  function safeDiv(a, b: real; default: real=0): Real; overload;
  function safeDiv(a, b: int64; default: int64=0): Int64; overload;
  function safeMod(a, b: int64; default: int64=0): Int64;
  function getFirstChar(const s: String): Char;

  function getAccountList(users: boolean=TRUE; groups: boolean=TRUE): TstringDynArray;

  function notModified(conn: ThttpConn; const etag, ts: String): Boolean; overload;
  function notModified(conn: ThttpConn; const f: String): Boolean; overload;

  function  getAgentID(conn: ThttpConn): String; overload;
  procedure drawGraphOn(cnv: Tcanvas; colors: TIntegerDynArray=NIL);
  function  recalculateGraph(s: ThttpSrv): Boolean;
  procedure resetGraph(s: ThttpSrv);

  function dllIsPresent(const name: String): Boolean;

  function evalFormula(s: String): Real;

type
  TfastRStringAppend = class
    const incStep: Integer = 20000;
   protected
    buff: RawByteString;
    n: integer;
   public
    function length():integer;
    function reset(): RawByteString;
    function get(): RawByteString;
    function append(const s: RawByteString): Integer;
  end;

  TFastUStringAppend = class
    const incStep: Integer = 20000;
   protected
    buff: UnicodeString;
    n: integer;
   public
    function length():integer;
    function reset(): UnicodeString;
    function get(): UnicodeString;
    function append(const s: UnicodeString): Integer;
  end;

const
  {$IFDEF FPC}
  PTR1: Pointer = ptr(1, 0);
  {$ELSE ~FPC}
  PTR1: Tobject = ptr(1);
  {$ENDIF FPC}


implementation
uses
  math, SysUtils, strutils, iniFiles, DateUtils,
  OverbyteIcsWSocket,
 {$IFNDEF FPC}
  UIConsts,
  OverbyteIcsTypes,
  OverbyteIcsUtils,
 {$ENDIF ~FPC}
 {$IFNDEF USE_MORMOT_COLLECTIONS}
  Generics.Collections,
 {$ELSE USE_MORMOT_COLLECTIONS}
  mormot.core.collections,
 {$ENDIF USE_MORMOT_COLLECTIONS}
  Base64,
  RDUtils, RnQCrypt, RnQZip,
  {$IFDEF UNICODE}
  ansistrings,
  {$ENDIF UNICODE}
  HSUtils,
  serverLib,
  srvVars;

resourcestring
  LIMIT = 'Limit';
  TOP_SPEED = 'Top speed';

var
  ipToInt_cache: ThashedStringList;


//////////// TfastRStringAppend

function TfastRStringAppend.length():integer;
begin result:=n end;

function TfastRStringAppend.get(): RawByteString;
begin
setlength(buff, n);
result:=buff;
end; // get

function TfastRStringAppend.reset(): RawByteString;
begin
result:=get();
buff:='';
n:=0;
end; // reset

function TfastRStringAppend.append(const s: RawByteString): Integer;
var
  ls, lb: integer;
begin
  ls := system.length(s);
  if ls > 0 then
    begin
      lb := system.length(buff);
      if n+ls > lb then
        setlength(buff, lb+ls + incStep);
      Move(s[1], buff[n+1], ls);
      inc(n, ls);
    end;
  result:=n;
end; // append

//////////// TFastUStringAppend

function TFastUStringAppend.length():integer;
begin result:=n end;

function TFastUStringAppend.get(): UnicodeString;
begin
  setlength(buff, n);
  result:=buff;
end; // get

function TFastUStringAppend.reset(): UnicodeString;
begin
  result:=get();
  buff:='';
  n:=0;
end; // reset

function TFastUStringAppend.append(const s: UnicodeString): integer;
var
  ls, lb: integer;
begin
  ls := system.length(s);
  if ls > 0 then
    begin
      lb := system.length(buff);
      if n+ls > lb then
        setlength(buff, lb+ls + incStep);
     {$IFDEF FPC}
      Move(s[1], buff[n+1], ls * sizeOf(UnicodeChar));
     {$ELSE FPC}
      MoveChars(s[1], buff[n+1], ls);
     {$ENDIF FPC}
      inc(n, ls);
    end;
  result:=n;
end; // append


function xtpl(src: UnicodeString; const table: array of UnicodeString): UnicodeString;
var
  i: integer;
begin
  i := 0;
  while i < length(table) do
   begin
    src := SysUtils.StringReplace(src,table[i],table[i+1],[rfReplaceAll,rfIgnoreCase]);
    inc(i, 2);
   end;
  result := src;
end; // xtpl

function xtpl(src: RawByteString; table:array of RawByteString): RawByteString;
var
  i: integer;
begin
i:=0;
while i < length(table) do
  begin
  src:=stringReplace(src,table[i],table[i+1],[rfReplaceAll,rfIgnoreCase]);
  inc(i, 2);
  end;
result:=src;
end; // xtpl

function xtpl(src: UnicodeString; table: TMacroTableVal): UnicodeString; OverLoad;
var
 {$IFNDEF USE_MORMOT_COLLECTIONS}
  p: TMacroTableValPair;
 {$ELSE USE_MORMOT_COLLECTIONS}
  i: Integer;
  k, v: UnicodeString;
 {$ENDIF USE_MORMOT_COLLECTIONS}
begin
  if Assigned(table) and (table.Count > 0) then
   {$IFNDEF USE_MORMOT_COLLECTIONS}
    for p in table do
      begin
        src := StringReplace(src, p.Key, p.Value, [rfReplaceAll,rfIgnoreCase]);
      end;
  {$ELSE USE_MORMOT_COLLECTIONS}
   begin
    i := 0;
    while i < table.Count do
     begin
      k := table.Key[i];
      v := table.Value[i];
      src := StringReplace(src, k, v, [rfReplaceAll,rfIgnoreCase]);
      inc(i);
     end;
   end;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  result := src;
end; // xtpl

type
  Tnewline = (NL_UNK, NL_D, NL_A, NL_DA, NL_MIXED);

function newlineType(const s: String): TNewLine;
var
  d, a, l: integer;
begin
  d:=pos(#13,s);
  a:=pos(#10,s);
  if d = 0 then
    if a = 0 then
      result:=NL_UNK
     else
      result:=NL_A
   else
    if a = 0 then
      result:=NL_D
     else
      if a = 1 then
        result:=NL_MIXED
       else
        begin
          result:=NL_MIXED;
          // search for an unpaired #10
          while (a > 0) and (s[a-1] = #13) do
            a:=posEx(#10, s, a+1);
          if a > 0 then
            exit;
          // search for an unpaired #13
          l:=length(s);
          while (d < l) and (s[d+1] = #10) do
            d:=posEx(#13, s, d+1);
          if d > 0 then
            exit;
          // ok, all is paired
          result:=NL_DA;
        end;
end; // newlineType

function escapeNL(s: String): String;
begin
  s := replaceStr(s, '\','\\');
  case newlineType(s) of
    NL_D: s := replaceStr(s, #13,'\n');
    NL_A: s := replaceStr(s, #10,'\n');
    NL_DA: s := replaceStr(s, #13#10,'\n');
    NL_MIXED: s := replaceStr(replaceStr(replaceStr(s, #13#10,'\n'), #13,'\n'), #10,'\n'); // bad case, we do our best
    end;
  result := s;
end; // escapeNL

function unescapeNL(s: String): String;
var
  o, n: integer;
begin
o:=1;
while o <= length(s) do
  begin
  o:=posEx('\n', s, o);
  if o = 0 then break;
  n:=1;
  while (o-n > 0) and (s[o-n] = '\') do inc(n);
  if odd(n) then
    begin
    s[o]:=#13;
    s[o+1]:=#10;
    end;
  inc(o,2);
  end;
result:=xtpl(s, ['\\','\']);
end; // unescapeNL

function htmlEncode(const s: UnicodeString): UnicodeString;
var
  i: integer;
  p: UnicodeString;
  fs: TfastUStringAppend;
begin
  fs := TfastUStringAppend.create;
  try
    for i:=1 to length(s) do
      begin
      case s[i] of
        '&': p:='&amp;';
        '<': p:='&lt;';
        '>': p:='&gt;';
        '"': p:='&quot;';
        '''': p:='&#039;';
        else p:=s[i];
        end;
      fs.append(p);
      end;
    result:=fs.get();
   finally
    fs.free
  end;
end; // htmlEncode


function substr(const s: UnicodeString; start:integer; upTo:integer=0): UnicodeString; inline;
var
  l: integer;
begin
  l := length(s);
  if start = 0 then
    inc(start)
   else if start < 0 then
    start:=l+start+1;
  if upTo <= 0 then
    upTo:=l+upTo;
  result := copy(s, start, upTo-start+1)
end; // substr

function substr(const s: RawByteString; start:integer; upTo:integer=0): RawByteString; inline;
var
  l: integer;
begin
  l := length(s);
  if start = 0 then
    inc(start)
   else
    if start < 0 then
      start := l+start+1;
  if upTo <= 0 then
    upTo := l+upTo;
  result := copy(s, start, upTo-start+1)
end; // substr

function substr(const s:string; const after:string):string;
var
  i: integer;
begin
  i := pos(after,s);
  if i = 0 then
    result:=''
   else
    result:=copy(s, i+length(after), MAXINT)
end; // substr

 {$IFNDEF UNICODE}
function replace(var s: String; const ss: String; start,upTo: Integer): Integer;
var
  common, oldL, surplus: Integer;
begin
  oldL := upTo-start+1;
  common := min(length(ss), oldL);
  if common > 0 then
   {$IFDEF FPC}
    Move(ss[1], s[start], common);
   {$ELSE ~FPC}
    MoveChars(ss[1], s[start], common);
   {$ENDIF FPC}
  surplus := oldL-length(ss);
  if surplus > 0 then
    delete(s, start+length(ss), surplus)
   else
    insert(copy(ss, common+1, -surplus), s, start+common);
  result := -surplus;
end; // replace
 {$ENDIF UNICODE}

function replace(var s: UnicodeString; const ss: UnicodeString; start,upTo: Integer): Integer;
var
  common, oldL, surplus: Integer;
  s2: UnicodeString;
begin
  oldL := upTo-start+1;
  common := min(length(ss), oldL);
  if common > 0 then
   begin
    UniqueString(s);
   {$IFDEF FPC}
    //MoveChar0(ss[1], s[start], common * sizeOf( unicodeChar));
    Move(ss[1], s[start], common * sizeOf( unicodeChar));
   {$ELSE ~FPC}
    MoveChars(ss[1], s[start], common);
   {$ENDIF FPC}
   end;
  surplus := oldL-length(ss);
  if surplus > 0 then
    delete(s, start+length(ss), surplus)
   else
    begin
      s2 := copy(ss, common+1, -surplus);
      insert(s2, s, start+common);
    end;
  result := -surplus;
end; // replace

// tells if a substring is found at specific position
function strAt(const s, ss: AnsiString; at:integer):boolean; inline;
begin
  if (ss = '') or (length(s) < at+length(ss)-1) then
    result:=FALSE
  else if length(ss) = 1 then
    result:=s[at] = ss[1]
  else if length(ss) = 2 then
    result:=(s[at] = ss[1]) and (s[at+1] = ss[2])
  else
    result:=copy(s,at,length(ss)) = ss;
end; // strAt

// tells if a substring is found at specific position
{$IFDEF FPC}
function strAt(const s, ss: UnicodeString; at:integer): Boolean; inline;
var
  ch: UnicodeChar;
begin
  if (ss = '') or (length(s) < at+length(ss)-1) then
    result := FALSE
  else
   begin
     ch := s[at];
     result := ch = ss[1];
     if Result and (length(ss) > 1) then
        begin
          if length(ss) = 2 then
            begin
              ch := s[at+1];
              result := (ch = ss[2])
            end
           else
           result := copy(s,at,length(ss)) = ss;
        end;
   end;
end; // strAt
{$ELSE FPC}
function strAt(const s, ss: UnicodeString; at:integer): Boolean; inline;
begin
  if (ss = '') or (length(s) < at+length(ss)-1) then
    result:=FALSE
  else if length(ss) = 1 then
    result:=s[at] = ss[1]
  else if length(ss) = 2 then
    result:=(s[at] = ss[1]) and (s[at+1] = ss[2])
  else
    result:=copy(s,at,length(ss)) = ss;
end; // strAt
{$ENDIF FPC}

procedure enforceNUL(var s: UnicodeString);
begin
  if s>'' then
    setLength(s, strLen(PWideChar(@s[1])))
end; // enforceNUL

procedure enforceNUL(var s: RawByteString);
begin
  if s>'' then
    setLength(s, {$IFDEF UNICODE}ansistrings.{$ENDIF UNICODE}strLen(PAnsiChar(@s[1])))
end; // enforceNUL

// concat pre+s+post only if s is non empty
function nonEmptyConcat(const pre, s: String; const post: String=''): String;
begin
  if s = '' then
    result := ''
   else
    result := pre+s+post
end;

var
  reTempCache, reFixedCache: THashedStringList;

function reCache(const exp: RegExprString; mods: String='m'): TregExpr;
const
  CACHE_MAX = 100;
var
  i: integer;
  cache: THashedStringList;
  temporary: boolean;
  key: string;

begin

// this is a temporary cache: older things get deleted. order: first is older, last is newer.
  if reTempCache = NIL then
    reTempCache:=THashedStringList.create();
// this is a permanent cache: things are never deleted (while the process is alive)
  if reFixedCache = NIL then
    reFixedCache:=THashedStringList.create();

// is it temporary or not?
  i := pos('!', mods);
  temporary := i=0;
  Tobject(cache):=if_(temporary, reTempCache, reFixedCache);
  delete(mods, i, 1);

// access the cache
  key := mods+#255+exp;
  i := cache.indexOf(key);
  if i >= 0 then
    begin
      result:=cache.objects[i] as TregExpr;
      if temporary then
        cache.move(i, cache.count-1); // just requested, refresh position
    end
   else
    begin
      // cache fault, create new object
      result:=TRegExpr.Create;
      cache.addObject(key, result);

      if temporary and (cache.count > CACHE_MAX) then
        // delete older ones
        for i:=1 to CACHE_MAX div 10 do
          try
            cache.objects[0].free;
            cache.delete(0);
          except end;

      result.modifierS:=FALSE;
      result.modifierStr:=mods;
      result.expression:=exp;
      result.compile();
    end;

end;//reCache

function reMatch(const s, exp: UnicodeString; mods: String='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
var
  i: integer;
  re: TRegExpr;
begin
  result := 0;
  re := reCache(exp, mods);
  if assigned(subexp) then
    subexp^:=NIL;
  // do the job
  try
    re.inputString:=s;
    if not re.execPos(ofs) then
      exit;
    result := re.matchPos[0];
    if subexp = NIL then
      exit;
    i := re.subExprMatchCount;
    setLength(subexp^, i+1); // it does include also the whole match, with index zero
    for i:=0 to i do
      subexp^[i]:=re.match[i]
   except
  end;
end; // reMatch

function reReplace(const subj, exp, repl: String; const mods: String='m'): String;
var
  re: TRegExpr;
begin
  re := reCache(exp, mods);
  result := re.replace(subj, repl, TRUE);
end; // reReplace

function reGet(const s, exp:string; subexpIdx:integer=1; const mods:string='!mi'; ofs:integer=1):string;
var
  se: TstringDynArray;
begin
  if reMatch(s, exp, mods, ofs, @se) > 0 then
    result := se[subexpIdx]
   else
    result := '';
end; // reGet

// method TregExpr.ReplaceEx does the same thing, but doesn't allow the extra data field (sometimes necessary).
// Moreover, here i use the TfastStringAppend that will give us good performance with many replacements.
function reCB(const expr, subj: UnicodeString; cb:TreCB; data:pointer=NIL): UnicodeString;
var
  r: string;
  last: integer;
  re: TRegExpr;
  s: TfastUStringAppend;
begin
  re := TRegExpr.create;
  s := TfastUStringAppend.create;
  try
    re.modifierI:=TRUE;
    re.ModifierS:=FALSE;
    re.expression:=expr;
    re.compile();
    last:=1;
    if re.exec(subj) then
      repeat
      r:=re.match[0];
      cb(re, r, data);
      if re.MatchPos[0] > 1 then
        s.append(substr(subj, last, re.matchPos[0]-1)); // we must IF because 0 is the end of string for substr()
      s.append(r);
      last:=re.matchPos[0]+re.matchLen[0];
      until not re.execNext();
    s.append(substr(subj, last));
    result:=s.get();
   finally
    re.free;
    s.free;
  end
end; // reCB

procedure apacheLogCb(re: TregExpr; var res: String; data: pointer);
const
  APACHE_TIMESTAMP_FORMAT = 'dd"/!!!/"yyyy":"hh":"nn":"ss';
var
  code, codes, par: string;
  cmd: char;
  cd: TconnData;

  procedure extra();
  var
    i: Integer;
  begin
    // apache log standard for "nothing" is "-", but "-" is a valid filename
    res := '';
    if cd.uploadResults = NIL then
      exit;
    for i := 0 to length(cd.uploadResults)-1 do
      with cd.uploadResults[i] do
        if reason = '' then
          res := res+fn+'|';
    setLength(res, length(res)-1);
  end; // extra

begin
  cd := data;
  if cd = NIL then
    exit; // something's wrong
  code := intToStr(HRM2CODE[cd.conn.reply.mode]);
  // first parameter specifies http code to match as CSV, with leading '!' to invert logic
  codes := re.match[1];
  if (codes > '') and ((pos(code, codes) > 0) = (codes[1] = '!')) then
    begin
     res := '-';
     exit;
    end;
  par := re.match[3];
  cmd := re.match[4][1]; // it's case sensitive
  try
    case cmd of
      'a', 'h': res := cd.address;
      'l': res := '-';
      'u': res := first(cd.usr, '-');
      't': res := '['
        +xtpl(formatDatetime(APACHE_TIMESTAMP_FORMAT, now()),
           ['!!!',MONTH2STR[monthOf(now())]])
        +' '+logfile.apacheZoneString+']';
      'r': res:= UnUTF(getTill(CRLFA, cd.conn.httpRequest.full));
      's': res := code;
      'B': res := intToStr(cd.conn.bytesSentLastItem);
      'b': if cd.conn.bytesSentLastItem = 0 then res:='-' else res:=intToStr(cd.conn.bytesSentLastItem);
      'i': res := cd.conn.getHeader(par);
      'm': res := METHOD2STR[cd.conn.httpRequest.method];
      'c': if (cd.conn.bytesToSend > 0) and (cd.conn.httpState = HCS_DISCONNECTED) then res:='X'
            else if cd.disconnectAfterReply then res:='-'
            else res:='+';
      'e': res := getEnvironmentVariable(par);
      'f': res := cd.lastFile.name;
      'H': res := 'HTTP'; // no way
      'p': res := cd.conn.hsrv.port;
      'z': extra(); // extra information specific for hfs
      else
        res := 'UNSUPPORTED';
      end;
   except
    res := 'ERROR'
  end;
end; // apacheLogCb

function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean;
begin if v then result:=v1 else result:=v2 end;

{$IFDEF UNICODE}
function if_(v:boolean; const v1, v2:string):string;
begin if v then result:=v1 else result:=v2 end;
{$ENDIF UNICODE}

function if_(v: Boolean; const v1, v2: RawByteString): RawByteString;
begin
  if v then
    result := v1
   else
    result := v2
end;

function if_(v:boolean; v1,v2:int64):int64;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1, v2:integer):integer;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1, v2:Tobject):Tobject;
begin if v then result:=v1 else result:=v2 end;

function dequote(const s:string; quoteChars:TcharSetW=['"']):string;
begin
if (s > '') and (s[1] = s[length(s)]) and (s[1] in quoteChars) then
  result:=copy(s, 2, length(s)-2)
else
  result:=s;
end; // dequote

function removeStartingStr(const ss, s: String): String;
begin
if ansiStartsStr(ss, s) then
  result:=substr(s, 1+length(ss))
else
  result:=s
end; // removeStartingStr

procedure excludeTrailingString(var s: UnicodeString; const ss: UnicodeString);
var
  i: integer;
begin
  i := length(s)-length(ss);
  if i >= 0 then
    if copy(s, i+1, length(ss)) = ss then
      setLength(s, i);
end;

 {$IFNDEF UNICODE}
procedure excludeTrailingString(var s: String; const ss: String);
var
  i: integer;
begin
  i := length(s)-length(ss);
  if i >= 0 then
    if copy(s, i+1, length(ss)) = ss then
      setLength(s, i);
end;
 {$ENDIF ~UNICODE}

function countSubstr(const ss: String; const s: String): Integer;
var
  i, l: integer;
  c: char;
begin
  result := 0;
  l := length(ss);
  if l = 1 then
    begin
      l := length(s);
      c := ss[1];
      for i:=1 to l do
        if s[i] = c then
          inc(result);
      exit;
    end;
  i := 1;
  repeat
    i := posEx(ss, s, i);
    if i = 0 then
      exit;
    inc(result);
    inc(i, l);
  until false;
end; // countSubstr


function smartsize(size: int64): string;
begin
  if size < 0 then result:='N/A'
  else
    if size < 1 shl 10 then result:=intToStr(size)
    else
      if size < 1 shl 20 then result:=format('%.1f K',[size/(1 shl 10)])
      else
        if size < 1 shl 30 then result:=format('%.1f M',[size/(1 shl 20)])
        else result:=format('%.1f G',[size/(1 shl 30)])
end; // smartsize

function elapsedToStr(t: TDateTime): String;
var
  sec: integer;
begin
  sec := trunc(t*SECONDS);
  result := format('%d:%.2d:%.2d', [sec div 3600, sec div 60 mod 60, sec mod 60] );
end; // elapsedToStr

function dotted(i: Int64): String;
begin
  result := IntToStr(i);
  i := length(result)-2;
  while i > 1 do
  begin
    insert(FormatSettings.ThousandSeparator, result, i);
    dec(i,3);
  end;
end; // dotted

function stringToColorEx(s: String; default: Tcolor=clNone): Tcolor;
begin
  try
    if reMatch(s, '#?[0-9a-f]{3,6}','!i') > 0 then
      begin
      s := removeStartingStr('#', s);
      case length(s) of
        3: s:=s[3]+s[3]+s[2]+s[2]+s[1]+s[1];
        6: s:=s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
        end;
      end;
    {$IFDEF FPC}
      try
        result := stringToColor('$'+s)
      except
        try
          result := stringToColor('cl'+s);
         except
          if default = clNone then
            result := stringToColor(s)
          else
            try
              result := stringToColor(s)
             except
              result := default
            end;
        end;
      end;
    {$ELSE ~FPC}
      if not TryStringToColor('$'+s, Result) then
        if not TryStringToColor('cl'+s, Result)  then
          if default = clNone then
            TryStringToColor(s, Result)
           else
            if not TryStringToColor(s, Result) then
              result := default
              ;
    {$ENDIF ~FPC}
   except
    result := default
  end;
end; // stringToColorEx

function isExtension(const filename, ext: UnicodeString): Boolean;
begin
  result := 0=ansiCompareText(ext, extractFileExt(filename))
end;

function swapMem(var src,dest; count:dword; cond:boolean=TRUE):boolean; inline;
var
  temp:pointer;
begin
result:=cond;
if not cond then exit;
getmem(temp, count);
move(src, temp^, count);
move(dest, src, count);
move(temp^, dest, count);
freemem(temp, count);
end; // swapMem

procedure sortArray(var a:TStringDynArray);
var
  i, j, l: integer;
begin
l:=length(a);
for i:=0 to l-2 do
  for j:=i+1 to l-1 do
    swapMem(a[i], a[j], sizeof(a[i]), ansiCompareText(a[i], a[j]) > 0);
end; // sortArray

function sortArrayF(const a:TStringDynArray):TStringDynArray;
var
  i, j, l: integer;
begin
result:=a;
l:=length(result);
for i:=0 to l-2 do
  for j:=i+1 to l-1 do
    swapMem(result[i], result[j], sizeof(result[i]), ansiCompareText(result[i], result[j]) > 0);
end; // sortArray

function idxOf(const s: String; a: array of string; isSorted: Boolean=FALSE): Integer;
var
  r, b, e: integer;
begin
if not isSorted then
  begin
  result:=ansiIndexText(s,a);
  exit;
  end;
// a classic one... :-P
b:=0;
e:=length(a)-1;
while b <= e do
  begin
  result:=(b+e) div 2;
  r:=ansiCompareText(s, a[result]);
  if r = 0 then exit;
  if r < 0 then e:=result-1
  else b:=result+1;
  end;
result:=-1;
end;

function stringExists(const s: String; const a: array of String; isSorted: Boolean=FALSE): Boolean;
begin result:= idxOf(s,a, isSorted) >= 0 end;

procedure toggleString(const s:string; var ss:TStringDynArray);
var
  i: integer;
begin
i:=idxOf(s, ss);
if i < 0 then addString(s, ss)
else removeString(ss, i);
end; // toggleString

function onlyString(const s: String; ss: TStringDynArray): boolean;
// we are case insensitive, just like other functions in this set
begin result:=(length(ss) = 1) and sameText(ss[0], s) end;

function match(mask, txt:pchar; fullMatch:boolean; charsNotWildcard:TcharsetW):integer;
// charsNotWildcard is for chars that are not allowed to be matched by wildcards, like CR/LF
var
  i: integer;
begin
result:=0;
// 1 to 1 match
while not (mask^ in [#0,'*'])
and (txt^ <> #0)
and (
  (ansiUpperCase(mask^) = ansiUpperCase(txt^))
  or (upCase(mask^) = upCase(txt^))
  or (mask^ = '?') and not (txt^ in charsNotWildcard)
) do
  begin
  inc(mask);
  inc(txt);
  inc(result);
  end;
if (mask^ = #0) and (not fullMatch or (txt^ = #0)) then
  exit;
if mask^ <> '*' then
  begin
  result:=0;
  exit;
  end;
while mask^ = '*' do inc(mask);
if mask^ = #0 then // final *, anything matches
  begin
  inc(result, strLen(txt));
  exit;
  end;
  repeat
  if txt^ in charsNotWildcard then break;

  if fullMatch and (strpos(mask,'*') = NIL) then
    begin // we just passed last * so we are trying to match the final part of txt. This block is just an optimization. It happens often because of mime types and masks like *.css
    i:=length(txt)-length(mask);
    if i < 0 then break; // not enough characters left
    // move forward of the minimum part that's required to be covered by the last *
    inc(txt, i);
    inc(result, i);
    i:=match(mask, txt, fullMatch);
    if i = 0 then break; // no more chances
    end
  else
    i:=match(mask, txt, fullMatch);

  if i > 0 then
    begin
    inc(result, i);
    exit;
    end;
  // we're after a *, next part may match at any point, so try it in every way
  inc(txt);
  inc(result);
  until txt^ = #0;
result:=0;
end; // match

function filematch(mask: String; const fn: String): boolean;
var
  invert: integer;
begin
result:=TRUE;
invert:=0;
while (invert < length(mask)) and (mask[invert+1] = '\') do
  inc(invert);
delete(mask,1,invert);
while mask > '' do
  begin
  result:=match( pchar(chop(';',mask)), pchar(fn) ) > 0;
  if result then break;
  end;
result:=result xor odd(invert);
end; // filematch

function validFilepath(const fn: UnicodeString; acceptUnits: Boolean=TRUE): Boolean;
var
  withUnit: boolean;
begin
  withUnit := (length(fn) > 2) and (upcase(fn[1]) in ['A'..'Z']) and (fn[2] = ':');
  result := (fn > '')
    and (posEx(':', fn, if_(withUnit,3,1)) = 0)
    and (poss([#0..#31,'?','*','"','<','>','|'], fn) = 0)
    and (length(fn) <= 255+if_(withUnit, 2));
end;

function validFilename(const s: String): Boolean;
begin
  result := (s>'')
    and not dirCrossing(s)
    and not anycharIn(ILLEGAL_FILE_CHARS,s)
end;

function isAbsolutePath(const path:string):boolean;
begin
  result := (path > '') and (path[1] = '\')
         or (length(path) > 1) and (path[2] = ':')
end;

// this will tell if the file has changed
function newMtime(const fn: String; var previous: Tdatetime): Boolean;
var
  d: TDateTime;
begin
  d := getMtime(fn);
  result := fileExists(fn) and (d <> previous);
  if result then
    previous := d;
end; // newMtime

function checkAddressSyntax(address: String; mask: Boolean=TRUE): Boolean;
var
  a1, a2: string;
 {$IFDEF USE_IPv6}
  sf: TSocketFamily;
 {$ENDIF USE_IPv6}
begin
  result := FALSE;
  if address = '' then
    exit;
  if not mask then
 {$IFDEF USE_IPv6}
    Exit(WSocketIsIPEx(address, sf));
 {$ELSE USE_IPv6}
    Exit(WSocketIsDottedIP(address));
 {$ENDIF USE_IPv6}
  while (address > '') and (address[1] = '\') do
    delete(address,1,1);
  while address > '' do
    begin
      a2 := chop(';', address);
      if sameText(a2, 'lan') then
        continue;
      a1 := chop('-', a2);
      if a2 > '' then
        if not checkAddressSyntax(a1, FALSE)
        or not checkAddressSyntax(a2, FALSE) then
          exit;
      if reMatch(a1, '^[?*a-f0-9\.:]+$', '!') = 0 then
        exit;
    end;
  result := TRUE;
end; // checkAddressSyntax

function hostFromURL(const s: String): String;
begin
  result := reGet(s, '([a-z]+://)?([^/]+@)?([^/]+)', 3)
end;

function addArray(var dst:TstringDynArray; src:array of string; where:integer=-1; srcOfs:integer=0; srcLn:integer=-1):integer;
var
  i, l:integer;
begin
  l:=length(dst);
  if where < 0 then // this means: at the end of it
    where := l;
  if srcLn < 0 then
    srcLn := length(src);
  setLength(dst, l+srcLn); // enlarge your array!

  i := max(l, where+srcLn);
  while i > l do // we are over newly allocated memory, just copy
   begin
    dec(i);
    dst[i]:=src[i-where+srcOfs];
   end;
  while i > where+srcLn do  // we're over the existing data, just shift
   begin
    dec(i);
    dst[i+srcLn]:=dst[i];
   end;
  while i > where do // we'are in middle-earth, both shift and copy
   begin
    dec(i);
    dst[i+srcLn]:=dst[i];
    dst[i]:=src[i-where+srcOfs];
   end;
  result := l+srcLn;
end; // addArray

function addArray(var dst: TMacroTableVal; src: array of UnicodeString): Integer;
var
  i, l: integer;
  k: String;
  v: UnicodeString;
begin
  l := Length(src);
  if l > 0 then
    begin
      i := 0;
      while i < l-1 do
       begin
        k := src[i];
        v := src[i+1];
        if dst = NIL then
          dst := newMacroTableVal;
        if not dst.TryAdd(k, v) then
          dst.Items[k] := v;
        inc(i, 2);
       end;
    end;
  Result := dst.Count;
end; // addArray

function addUniqueArray(var a: TStringDynArray; b: array of string): Integer;
var
  i, l, j, n, lb:integer;
  found: boolean;
  bi: string;
begin
l:=length(a);
n:=l; // real/final length of 'a'
lb:=length(b); // cache this value
setlength(a, l+lb);
for i:=0 to lb-1 do
  begin
  bi:=b[i]; // cache this value
  found:=FALSE;
  for j:=0 to n-1 do
    if sameText(a[j], bi) then
      begin
      found:=TRUE;
      break;
      end;
  if found then continue;
  a[n]:=bi;
  inc(n);
  end;
setLength(a, n);
result:=n-l;
end; // addUniqueArray

procedure uniqueStrings(var a: TstringDynArray; ci: Boolean=TRUE);
var
  i, j: integer;
begin
for i:=length(a)-1 downto 1 do
  for j:=i-1 downto 0 do
    if ci and SameText(a[i], a[j])
    or not ci and (a[i] = a[j]) then
      begin
      removeString(a, i);
      break;
      end;
end; // uniqueStrings

// remove all instances of the specified string
procedure removeStrings(const find: String; var a: TStringDynArray);
var
  i, l: integer;
begin
  repeat
    i := idxOf(find,a);
    if i < 0 then
      break;
    l := 1;
    while (i+l < length(a)) and (ansiCompareText(a[i+l], find) = 0) do
      inc(l);
    removeString(a, i, l);
  until false;
end; // removeStrings

function removeArray(var src:TstringDynArray; toRemove:array of string):integer;
var
  i, l, ofs: integer;
  b: boolean;
begin
l:=length(src);
i:=0;
ofs:=0;
while i+ofs < l do
  begin
  b:=stringExists(src[i+ofs], toRemove);
  if b then inc(ofs);
  if i+ofs > l then break;
  if ofs > 0 then src[i]:=src[i+ofs];
  if not b then inc(i);
  end;
setLength(src, l-ofs);
result:=ofs;
end; // removeArray

function popString(var ss:TstringDynArray):string;
begin
result:='';
if ss = NIL then exit;
result:=ss[0];
removeString(ss, 0);
end; // popString

function addString(const s: String; var ss: TStringDynArray): integer;
begin
  result := length(ss);
  addArray(ss, [s], result)
end; // addString

function replaceString(var ss: TStringDynArray; const old, new: String): Integer;
var
  i: integer;
begin
result:=0;
  repeat
  i:=idxOf(old, ss);
  if i < 0 then exit;
  inc(result);
  ss[i]:=new;
  until false;
end; // replaceString

function addUniqueString(const s: String; var ss: TStringDynArray): boolean;
begin
  result := idxof(s, ss) < 0;
  if result then
    addString(s, ss)
end; // addUniqueString

procedure insertstring(const s: String; idx: Integer; var ss: TStringDynArray);
begin addArray(ss, [s], idx) end;

function removestring(var a:TStringDynArray; idx:integer; l:integer=1):boolean;
begin
result:=FALSE;
if (idx<0) or (idx >= length(a)) then exit;
result:=TRUE;
while idx+l < length(a) do
  begin
  a[idx]:=a[idx+l];
  inc(idx);
  end;
setLength(a, idx);
end; // removestring

function removeString(const s: String; var a: TStringDynArray; onlyOnce: Boolean=TRUE; ci: Boolean=TRUE; keepOrder: Boolean=TRUE): Boolean; overload;
var
  i, lessen:integer;
begin
result:=FALSE;
if a = NIL then
  exit;
lessen:=0;
try
  for i:=length(a)-1 to 0 do
    if ci and sameText(a[i], s)
    or not ci and (a[i]=s) then
      begin
      result:=TRUE;
      if keepOrder then
        removeString(a, i)
      else
        begin
        inc(lessen);
        a[i]:=a[length(a)-lessen];
        end;
      if onlyOnce then
        exit;
      end;
finally
  if lessen > 0 then
    setLength(a, length(a)-lessen);
  end;
end;

function split(const separator, s: String; nonQuoted: Boolean=FALSE): TStringDynArray;
var
  i, j, n, l: integer;
begin
  l := length(s);
  result := NIL;
  if l = 0 then
    exit;
  i:=1;
  n:=0;
  repeat
    if length(result) = n then
      setLength(result, n+50);
    if nonQuoted then
      j := nonQuotedPos(separator, s, i)
    else
      j:=posEx(separator, s, i);
    if j = 0 then
      j:=l+1;
    if i < j then
      result[n]:=substr(s, i, j-1);
    i:=j+length(separator);
    inc(n);
  until j > l;
  setLength(result, n);
end; // split

function splitU(const s, separator: RawByteString; nonQuoted:boolean=FALSE):TStringDynArray;
var
  i, j, n, l: integer;
begin
  l := length(s);
  result := NIL;
  if l = 0 then
    exit;
  i:=1;
  n:=0;
  repeat
    if length(result) = n then
      setLength(result, n+50);
    if nonQuoted then
      j:=nonQuotedPos(separator, s, i)
    else
      j:=posEx(separator, s, i);
    if j = 0 then
      j:=l+1;
    if i < j then
      result[n]:= UnUTF(substr(s, i, j-1));
    i:=j+length(separator);
    inc(n);
  until j > l;
  setLength(result, n);
end; // splitU

function join(const separator: String; ss:TstringDynArray):string;
var
  i:integer;
begin
  result := '';
  if length(ss) = 0 then
    exit;
  result := ss[0];
  if length(ss) > 1 then
   for i:=1 to length(ss)-1 do
    result := result+separator+ss[i];
end; // join

function listToArray(l:Tstrings):TstringDynArray;
var
  i: integer;
begin
try
  setLength(result, l.Count);
  for i:=0 to l.Count-1 do
    result[i]:=l[i];
except
  result:=NIL
  end
end; // listToArray

function arrayToList(a:TStringDynArray; list:TstringList=NIL):TstringList;
var
  i: integer;
begin
if list = NIL then
  list:=ThashedStringList.create;
result:=list;
list.Clear();
for i:=0 to length(a)-1 do
  list.add(a[i]);
end; // arrayToList

procedure urlToStrings(const s: String; sl: Tstrings);
var
  i, l, p: integer;
  t: string;
begin
  i := 1;
  l := length(s);
  while i <= l do
    begin
      p := posEx('&',s,i);
      t := decodeURL(xtpl(substr(s,i,if_(p=0,0,p-1)), ['+',' ']), FALSE);
      sl.add(t);
      if p = 0 then exit;
      i:=p+1;
    end;
end; // urlToStrings

procedure urlToStrings(const s: RawByteString; sl: Tstrings);
var
  i, l, p: integer;
  t: string;
begin
  i:=1;
  l:=length(s);
  while i <= l do
  begin
    p := posEx(RawByteString('&'),s,i);
    t := decodeURL(xtpl(substr(s,i,if_(p=0,0,p-1)), [RawByteString('+'), RawByteString(' ')]));
     // TODO should we instead try to decode utf-8? doing so may affect calls to {.force ansi.} in the template
    sl.add(t);
    if p = 0 then
      exit;
    i := p+1;
  end;
end; // urlToStrings

function singleLine(const s: string): boolean;
var
  i, l: integer;
begin
i:=pos(#13,s);
l:=length(s);
result:=(i = 0) or (i = l) or (i = l-1) and (s[l] = #10)
end; // singleLine

// finds the end of the line
function findEOL(const s:string; ofs:integer=1; included:boolean=TRUE):integer;
begin
ofs:=max(1,ofs);
result:=posEx(#13, s, ofs);
if result > 0 then
  begin
  if not included then
    dec(result)
  else
    if (result < length(s)) and (s[result+1] = #10) then
      inc(result);
  exit;
  end;
result:=posEx(#10, s, ofs);
if result > 0 then
  begin
  if not included then
    dec(result);
  exit;
  end;
result:=length(s);
end; // findEOL

function poss(chars:TcharSetW; s:string; ofs:integer=1):integer;
begin
for result:=ofs to length(s) do
  if s[result] in chars then exit;
result:=0;
end; // poss

function strToCharset(const s:string): TcharsetW;
var
  i: integer;
begin
result:=[];
for i:=1 to length(s) do
  include(result, ansichar(s[i]));
end; // strToCharset

function anycharIn(chars:TcharsetW; const s:string):boolean;
begin result:=poss(chars, s) > 0 end;

function anycharIn(const chars, s:string):boolean;
begin result:=anyCharIn(strToCharset(chars), s) end;

function quoteIfAnyChar(const badChars: String; s:string; const quote:string='"'; const unquote:string='"'):string;
begin
if anycharIn(badChars, s) then
  s:=quote+s+unquote;
result:=s;
end; // quoteIfAnyChar

// this is feasible for spot and low performance needs
function getKeyFromString(const s: UnicodeString; key: UnicodeString; const def: UnicodeString=''): UnicodeString;
var
  i: integer;
begin
  result := def;
  includeTrailingString(key, '=');
  i := 1;
  repeat
  i:= ipos(key, s, i);
  if i = 0 then
    exit; // not found
  until (i = 1) or (s[i-1] in [#13,#10]); // ensure we are at the very beginning of the line
  inc(i, length(key));
  result := substr(s,i, findEOL(s,i,FALSE));
end; // getKeyFromString

// "key=val" in second parameter (with 3rd one empty) is supported
function setKeyInString(s: UnicodeString; key: UnicodeString; val: UnicodeString=''): UnicodeString;
var
  i: integer;
begin
  i := pos('=', key);
  if i = 0 then
    key := key+'='
   else if val = '' then
    begin
     val := copy(key, i+1, MAXINT);
     setLength(key, i);
    end;
// now key has a trailing '='. Let's find where it is.
i:=0;
  repeat i:= ipos(key, s, i+1);
  until (i <= 1) or (s[i-1] in [#13,#10]); // we accept cases 0,1 as they are. Other cases must comply with being at start of line.
if i = 0 then // missing, then add
  begin
  if s > '' then
    includeTrailingString(s, CRLF);
  result:=s+key+val;
  exit;
  end;
// replace
inc(i, length(key));
replace(s, val, i, findEOL(s,i, FALSE));
result:=s;
end; // setKeyInString


function stripChars(s: string; cs: TcharsetW; invert: boolean=FALSE): string;
var
  i, l, ofs: integer;
  b: boolean;
begin
l:=length(s);
i:=1;
ofs:=0;
while i+ofs <= l do
  begin
  b:=(s[i+ofs] in cs) xor invert;
  if b then inc(ofs);
  if i+ofs > l then break;
  if ofs > 0 then s[i]:=s[i+ofs];
  if not b then inc(i);
  end;
setLength(s, l-ofs);
result:=s;
end; // stripChars


function toSA(a: array of UnicodeString): TstringDynArray; // this is just to have a way to typecast
begin
  result := NIL;
  addArray(result, a);
end; // toSA

function  toMSA(a: array of UnicodeString): TMacroTableVal; // this is just to have a way to typecast
begin
  result := NIL;
  if Length(a)> 0 then
    addArray(result, a);
end; // toSA

function getMtimeUTC(const filename: UnicodeString): Tdatetime;
var
  sr: TUnicodeSearchRec;
  st: TSystemTime;
begin
  result:=0;
  if findFirst(filename, faAnyFile, sr) <> 0 then
    exit;
  FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
  result:=SystemTimeToDateTime(st);
  findClose(sr);
end; // getMtimeUTC

function getMtime(const filename: String): Tdatetime;
begin
if not fileAge(filename, result) then
  result:=0;
end; // getMtime

function getStr(from, to_: pAnsichar): RawByteString;
var
  l: integer;
begin
  result:='';
  if (from = NIL) or assigned(to_) and (from > to_) then
    exit;
  if to_ = NIL then
    begin
      to_ := {$IFDEF UNICODE}ansistrings.{$ENDIF UNICODE}strEnd(from);
      dec(to_);
    end;
  l := to_-from+1;
  setLength(result, l);
  if l > 0 then
    {$IFDEF UNICODE}ansistrings.{$ENDIF UNICODE}strLcopy(@result[1], from, l);
end; // getStr

function getStr(from, to_: PChar): String;
var
  l: integer;
begin
result:='';
if (from = NIL) or assigned(to_) and (from > to_) then exit;
if to_ = NIL then
  begin
  to_:=strEnd(from);
  dec(to_);
  end;
l:=to_-from+1;
setLength(result, l);
if l > 0 then strLcopy(@result[1], from, l);
end; // getStr

{$IFDEF UNICODE}
function getTill(const ss, s: String; included: Boolean=FALSE): String;
var
  i: integer;
begin
  i:=pos(ss, s);
  if i = 0 then
    result := s
   else
    result := copy(s,1,i-1+if_(included,length(ss)));
end; // getTill

function getTill(i: Integer; const s: String): String;
begin
  if i < 0 then
    i := length(s)+i;
  result := copy(s, 1, i);
end; // getTill
{$ENDIF UNICODE}

function getTill(const ss, s: RawByteString; included: Boolean=FALSE): RawByteString;
var
  i: integer;
begin
  i := pos(ss, s);
  if i = 0 then
    result := s
   else
    result := copy(s,1,i-1+if_(included,length(ss)));
end; // getTill

function getTill(i:integer; const s: RawByteString): RawByteString;
begin
  if i < 0 then
    i:=length(s)+i;
  result:=copy(s, 1, i);
end; // getTill


// extract at p the section name of a text, if any
function getSectionAt(p: pchar; out name:string): boolean;
var
 eos, eol: pchar;
begin
result:=FALSE;
if (p = NIL) or (p^ <> '[') then exit;
eos:=p;
while eos^ <> ']' do
  if eos^ in [#0, #10, #13] then exit
  else inc(eos);
// ensure the line is termineted correctly
eol:=eos;
inc(eol);
while not (eol^ in [#10,#0]) do
  if not (eol^ in [#9,#32,#13]) then exit
  else inc(eol);
inc(p);
dec(eos);
name:=getStr(p, eos);
result:=TRUE;
end; // getSectionAt

function isSectionAt(p:pchar):boolean;
var
  trash: string;
begin
  result:=getSectionAt(p, trash);
end; // isSectionAt

function name2mimetype(const fn: String; const default: RawByteString): RawByteString;
var
  i: Integer;
begin
  result := default;
  for i := 0 to length(mimeTypes) div 2-1 do
    if fileMatch(mimeTypes[i*2], fn) then
     begin
      result := mimeTypes[i*2+1];
      exit;
     end;
  for i := 0 to length(DEFAULT_MIME_TYPES) div 2-1 do
    if fileMatch(DEFAULT_MIME_TYPES[i*2], fn) then
     begin
      result := DEFAULT_MIME_TYPES[i*2+1];
      exit;
     end;
end; // name2mimetype

function strSHA256(const s: String): String;
//begin result:=THashSHA2.GetHashString(s) end;
begin result:= SHA256PassLS(UTF8Encode(s)) end;

//function strMD5(s:string):string;
//begin result:=THashMD5.GetHashString(s) end;

function strMD5(const s: String): String;
begin Result := LowerCase(MD5PassHS(UTF8Encode(s))); end;

{$IFOPT Q+}{$DEFINE QOn}{$Q-}{$ELSE}{$UNDEF QOn}{$ENDIF}
function getCRC(const data: RawByteString): Integer;
var
  i: UInt32;
  p: Pinteger;
begin
  result:=0;
  if length(data) > 0 then
    begin
      p := @data[1];
      for i:=1 to length(data) div 4 do
        begin
          inc(result, p^);
          inc(p);
        end;
    end;
end; // crc
{$IFDEF QOn}{$Q+}{$ENDIF}

{$IFDEF USE_IPv6}
function ipv6hex(ip:TIcsIPv6Address):string;
begin
setLength(result, 4*8);
binToHex(@ip.words[0], pchar(result), sizeOf(ip))
end;
{$ENDIF USE_IPv6}

function ipToInt(const ip: String): DWord;
var
  i: integer;
begin
  i := ipToInt_cache.Add(ip);
  result := dword(ipToInt_cache.Objects[i]);
  if result <> 0 then
    exit;
  result := dword(WSocket_ntohl(WSocket_inet_addr(PAnsichar(AnsiString(ip)))));
  ipToInt_cache.Objects[i] := Tobject(result);
end; // ipToInt


function addressMatch(mask: String; const address: String): Boolean;
var
  invert: boolean;
  addr4: dword;
  {$IFDEF USE_IPv6}
  addr6: string;
  {$ENDIF USE_IPv6}
  bits: integer;
  a: TStringDynArray;

  {$IFDEF USE_IPv6}
  function ipv6fix(const s: string): string;
  var
    ok: boolean;
    r: TIcsIPv6Address;
  begin
    if length(s) = 39 then
      exit(replaceStr(s,':',''));
    r := wsocketStrToipv6(s, ok);
    if ok then
      exit(ipv6hex(r));
    exit('');
  end;

  function ipv6range(): boolean;
  var
    min, max: string;
  begin
  min:=ipv6fix(a[0]);
  if min = ''then
    exit(FALSE);
  max:=ipv6fix(a[1]);
  if max = '' then
    exit(FALSE);
  result:=(min <= addr6) and (max >= addr6)
  end; // ipv6range
  {$ENDIF USE_IPv6}

begin
  result:=FALSE;
  invert:=FALSE;
  while (mask > '') and (mask[1] = '\') do
  begin
    delete(mask,1,1);
    invert:=not invert;
  end;
  if mask='' then
    Exit;
 {$IFDEF USE_IPv6}
  addr6:=ipv6fix(address);
  addr4:=0;
  if addr6 = '' then
 {$ENDIF USE_IPv6}
    addr4:=ipToInt(address);
  for mask in split(';',mask) do
  begin
    if result then
      break;
    if sameText(mask, 'lan') then
      begin
        result:=isLocalIP(address);
        continue;
      end;

  // range?
    a:=split('-', mask);
    if length(a) = 2 then
      begin
      {$IFDEF USE_IPv6}
        if addr6 > '' then
          result:=ipv6range()
         else
      {$ENDIF USE_IPv6}
          result:=(pos(':',a[0]) = 0) and (addr4 >= ipToInt(a[0])) and (addr4 <= ipToInt(a[1]));
        continue;
      end;

  // bitmask? ipv4 only
    a := split('/', mask);
    if {$IFDEF USE_IPv6}(addr6='') and{$ENDIF USE_IPv6} (length(a) = 2) then
      begin
        try
          bits:=32-strToInt(a[1]);
          result:=addr4 shr bits = ipToInt(a[0]) shr bits;
         except
        end;
        continue;
      end;

  // single
    result := match( pchar(mask), pchar(address) ) > 0;
  end;
result:=result xor invert;
end; // addressMatch

function b64utf8(const s: String): RawByteString;
begin result := Base64EncodeString(UTF8encode(s)); end;

function b64utf8S(const s: String): String;
begin
  result := Base64EncodeString(UTF8encode(s));
end;

function b64utf8W(const s: String): UnicodeString;
begin result:=Base64EncodeString(UTF8encode(s)); end;

function b64U(const b: RawByteString): UnicodeString;
begin result:=Base64EncodeString(b); end;

function b64R(const b: RawByteString): RawByteString;
begin result:=Base64EncodeString(b); end;

function decodeB64utf8(const s: RawByteString):string; OverLoad;
begin result:=UnUTF(Base64DecodeString(s)); end;

function decodeB64utf8(const s: String):string; OverLoad;
begin result:=UnUTF(Base64DecodeString(s)); end;

function decodeB64(const s: String): RawByteString; OverLoad;
begin result:=Base64DecodeString(s); end;

function decodeB64(const s: RawByteString): RawByteString; OverLoad;
begin result:=Base64DecodeString(s); end;

function jsEncode(s: String; const chars: String): String;
var
  i: integer;
begin
  for i:=1 to length(chars) do
    s := ansiReplaceStr(s, chars[i], '\x'+intToHex(ord(chars[i]),2));
  result := s;
end; // jsEncode

function TLV(t: Integer; const data: RawByteString): RawByteString;
begin
  result := str_(t)+str_(length(data))+data
end;

function TLVS(t: Integer; const data: String): RawByteString;
begin
  result := TLV(t, StrToUTF8(data))
end;

function TLVI(t: Integer; data: Integer): RawByteString;
begin
  result := TLV(t, str_(data))
end;

function TLV_NOT_EMPTY(t: integer; const data: RawByteString): RawByteString;
begin if data > '' then result:=TLV(t,data) else result:='' end;

function TLVS_NOT_EMPTY(t: integer; const data: String): RawByteString;
begin if data > '' then result:=TLV(t, StrToUTF8(data)) else result:='' end;

// converts from integer to string[4]
function str_(i: integer): RawByteString; overload;
begin
  setlength(result, 4 div sizeOf(AnsiChar));
  move(i, result[1], 4 div sizeOf(AnsiChar));
end; // str_

// converts from boolean to string[1]
function str_(b: boolean):RawByteString; overload;
begin result:= Ansichar(b) end;

// converts from Tdatetime to string[8]
function str_(t: Tdatetime): RawByteString; overload;
begin
  setlength(result, 8 div sizeOf(AnsiChar));
  move(t, result[1], 8 div sizeOf(AnsiChar));
end; // str_

// converts from string[4] to integer
function int_(const s: RawByteString):integer;
var
  s1: String[4];
begin
  s1 := s;
  result:=Pinteger(@s1[1])^
end;

// converts from string[8] to datetime
function dt_(const s: RawByteString): Tdatetime;
begin
  result := Pdatetime(@s[1])^
end;

function int0(i, digits:integer): String;
begin
  result := intToStr(i);
  result := stringOfChar('0',digits-length(result))+result;
end; // int0


function compare_(i1,i2:int64):integer; overload;
begin
  if i1 < i2 then
    result:=-1
   else
    if i1 > i2 then
      result:=1
     else
      result:=0
end; // compare_

function compare_(i1,i2:integer):integer; overload;
begin
if i1 < i2 then result:=-1 else
if i1 > i2 then result:=1 else
  result:=0
end; // compare_

function compare_(i1,i2:double):integer; overload;
begin
if i1 < i2 then result:=-1 else
if i1 > i2 then result:=1 else
  result:=0
end; // compare_

function minmax(min, max, v: Integer): Integer; inline;
begin
  if v < min then
    result := min
   else if v > max then
    result := max
   else
    result := v
end;

// returns the first non empty string
function first(a:array of string):string;
var
  i: integer;
begin
result:='';
for i:=0 to length(a)-1 do
  begin
  result:=a[i];
  if result > '' then exit;
  end;
end; // first

function first(a:array of RawByteString): RawByteString; overload;
var
  i: integer;
begin
result:='';
for i:=0 to length(a)-1 do
  begin
  result:=a[i];
  if result > '' then exit;
  end;
end; // first

function first(const a,b: String): String;
begin if a = '' then result:=b else result:=a end;

function first(a,b:integer):integer;
begin if a = 0 then result:=b else result:=a end;

function first(a,b:double):double;
begin if a = 0 then result:=b else result:=a end;

function first(a,b:pointer):pointer;
begin if a = NIL then result:=b else result:=a end;

function boolToPtr(b:boolean):pointer;
begin result:=if_(b, PTR1, NIL) end;

function diskSpaceAt(path:string):int64;
var
  tmp: int64;
  was: string;
begin
while not directoryExists(path) do
  begin
  was:=path;
  path:=extractFileDir(path);
  if path = was then break; // we're on the road to nowhere
  end;
if not getDiskFreeSpaceEx(pchar(path), result, tmp, NIL) then
  result:=-1;
end; // diskSpaceAt

function getRes(name: PChar; const typ: String='TEXT'): RawByteString;
var
  h1, h2: Thandle;
  p: pByte;
  l: integer;
  ansi: RawByteString;
begin
  result:='';
  h1 := FindResource(HInstance, name, pchar(typ));
  h2 := LoadResource(HInstance, h1);
  if h2=0 then
    exit;
  l := SizeOfResource(HInstance, h1);
  p := LockResource(h2);
  setLength(ansi, l);
  move(p^, ansi[1], l);
  UnlockResource(h2);
  FreeResource(h2);
  result := ansi;
end; // getRes

function getResText(name: PChar): RawByteString;
const
  typ: String  = 'TEXT';
  ztyp: String = 'ZTEXT';
var
  h1, h2: Thandle;
  p: pByte;
  l: integer;
  ansi: RawByteString;
  needExtract: Boolean;
begin
  result := '';
  h1 := FindResource(HInstance, name, pchar(typ));
  h2 := LoadResource(HInstance, h1);
  if h2=0 then
    begin
      h1 := FindResource(HInstance, name, pchar(ztyp));
      h2 := LoadResource(HInstance, h1);
      if h2=0 then
        exit;
      needExtract := True;
    end
   else
    needExtract := False;
  l := SizeOfResource(HInstance, h1);
  p := LockResource(h2);
  setLength(ansi, l);
  move(p^, ansi[1], l);
  UnlockResource(h2);
  FreeResource(h2);
  if needExtract then
    result := ZDecompressStr3(ansi)
   else
    result := ansi;
end; // getResText

function getAccount(const user:string; evenGroups:boolean=FALSE):Paccount;
var
  i: integer;
begin
result:=NIL;
if user = '' then
  exit;
for i:=0 to length(accounts)-1 do
  if sameText(user, accounts[i].user) then
    begin
    if evenGroups or not accounts[i].group then
      result:= @accounts[i];
    exit;
    end;
end; // getAccount

function accountExists(const user:string; evenGroups:boolean=FALSE):boolean;
begin result:=getAccount(user, evenGroups) <> NIL end;

// this function follows account linking until it finds and returns the account matching the stopCase
function accountRecursion(account:Paccount; stopCase:TaccountRecursionStopCase; data:pointer=NIL; data2:pointer=NIL):Paccount;

  function shouldStop():boolean;
  begin
  case stopCase of
    ARSC_REDIR: result:=account.redir > '';
    ARSC_NOLIMITS: result:=account.noLimits;
    ARSC_IN_SET: result:=stringExists(account.user, TstringDynArray(data), boolean(data2));
    else result:=FALSE;
    end;
  end;

var
  tocheck: TStringDynArray;
  i: integer;
begin
result:=NIL;
if (account = NIL) or not account.enabled then exit;
if shouldStop() then
  begin
  result:=account;
  exit;
  end;
i:=0;
toCheck:=account.link;
while i < length(toCheck) do
  begin
  account:=getAccount(toCheck[i], TRUE);
  inc(i);
  if (account = NIL) or not account.enabled then continue;
  if shouldStop() then
    begin
    result:=account;
    exit;
    end;
  addUniqueArray(toCheck, account.link);
  end;
end; // accountRecursion

function findEnabledLinkedAccount(account:Paccount; over:TStringDynArray; isSorted:boolean=FALSE):Paccount;
begin result:=accountRecursion(account, ARSC_IN_SET, over, boolToPtr(isSorted)) end;

function filetimeToDatetime(ft:TFileTime):Tdatetime;
var
  st: TsystemTime;
begin
  FileTimeToLocalFileTime(ft, ft);
  FileTimeToSystemTime(ft, st);
  TryEncodeDateTime(st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, result);
end; // filetimeToDatetime

function onlyExistentAccounts(a: TstringDynArray): TstringDynArray;
var
  i: integer;
  s: string;
begin
for i:=0 to length(a)-1 do
  begin
  s:=trim(a[i]);
  if (s = '') or (s[1] <> '@') and (getAccount(s) = NIL) then
    removeString(a, i)
  else
    a[i]:=s;
  end;
result:=a;
end; // onlyExistentAccounts

function dateToHTTP(gmtTime:Tdatetime):string; overload;
begin
result:=formatDateTime('"'+DOW2STR[dayOfWeek(gmtTime)]+'," dd "'+MONTH2STR[monthOf(gmtTime)]
  +'" yyyy hh":"nn":"ss "GMT"', gmtTime);
end; // dateToHTTP

function dateToHTTP(const filename: String): String; overload;
begin
  result := dateToHTTP(getMtimeUTC(filename))
end;

function dateToHTTPr(gmtTime: Tdatetime): RawByteString; OverLoad;
begin
  result := RawByteString(formatDateTime('"'+DOW2STR[dayOfWeek(gmtTime)]+'," dd "'+MONTH2STR[monthOf(gmtTime)]
  +'" yyyy hh":"nn":"ss "GMT"', gmtTime));
end; // dateToHTTP

function dateToHTTPr(const filename: string): RawByteString; overload;
begin
  result := dateToHTTPr(getMtimeUTC(filename))
end;

// this is useful when we don't know if the value is expressed as a real Tdatetime or in unix time format
function maybeUnixTime(t: TDateTime): TDateTime;
begin
  if t > 1000000 then
    result := unixToDateTime(round(t))
   else
    result := t
end;

function localToGMT(d: TDateTime):TDateTime;
begin
  result := d-GMToffset*60/SECONDS
end;

function reduceSpaces(s: UnicodeString; const replacement: UnicodeString=' '; spaces: TcharSetW=[]): UnicodeString;
var
  i, c, l: integer;
begin
  if spaces = [] then
    include(spaces, ' ');
  i:=0;
  l:=length(s);
while i < l do
  begin
  inc(i);
  c:=i;
  while (c <= l) and (s[c] in spaces) do
    inc(c);
  if c = i then continue;
  replace(s, replacement, i, c-1);
  end;
result:=s;
end; // reduceSpaces

// recognize strings containing pieces (separated by backslash) made of only dots
function dirCrossing(const s: UnicodeString): Boolean;
begin
  result:=FALSE;

  if onlyDotsRE = NIL then
  begin
    onlyDotsRE:=TRegExpr.Create;
    onlyDotsRE.modifierM:=TRUE;
    onlyDotsRE.expression:='(^|\\)\.\.+($|\\)';
    onlyDotsRE.compile();
  end;

  with onlyDotsRE do
  try
    result := exec(s);
   except
  end;
end; // dirCrossing

function fileOrDirExists(const fn: UnicodeString): Boolean;
begin
  result := fileExists(fn) or directoryExists(fn);
{** first i used this way, because faster, but it proved to not always work: http://www.rejetto.com/forum/index.php/topic,10825.0.html
var
  sr:TsearchRec;
begin
result:= 0=findFirst(ExcludeTrailingPathDelimiter(fn),faAnyFile,sr);
if result then FindClose(sr);
}
end; // fileOrDirExists

function getEtag(const filename: UnicodeString): String;
var
  sr: TUnicodeSearchRec;
  st: TSystemTime;
  stag: UnicodeString;
begin
  result:='';
  if findFirst(filename, faAnyFile, sr) <> 0 then
    exit;
  FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
  stag := intToStr(sr.Size)+':'+floatToStr(SystemTimeToDateTime(st))+':'+expandFileName(filename);
  findClose(sr);
  result := MD5PassHS(StrToUTF8(stag));
end; // getEtag

// this is meant to detect junctions, symbolic links, volume mount points
function isJunction(const path: UnicodeString): Boolean; inline;
var
  attr: DWORD;
begin
  attr := getFileAttributesW(PWideChar(path));
  // don't you dare to convert the <>0 in a boolean typecast! my TurboDelphi (2006) generates the wrong assembly :-(
  result:=(attr <> DWORD(-1)) and (attr and FILE_ATTRIBUTE_REPARSE_POINT <> 0)
end;

// the file may not be a junction itself, but we may have a junction at some point in the path
function hasJunction(const fn: UnicodeString): UnicodeString;
var
  i: integer;
begin
  i := length(fn);
  while i > 0 do
    begin
      result := copy(fn,1,i);
      if isJunction(result) then
        exit;
      while (i > 0) and not (fn[i] in ['\','/']) do
        dec(i);
      dec(i);
    end;
  result := '';
end; // hasJunction

function deltree(path: UnicodeString): Boolean;
var
  sr: TUnicodeSearchRec;
  fn: UnicodeString;
begin
  result := FALSE;
  if fileExists(path) then
    begin
      result := deleteFile(path);
      exit;
    end;
  if not ansiContainsStr(path, '?') and not ansiContainsStr(path, '*') then
    path:=path+'\*';
  if findfirst(path, faAnyFile, sr) <> 0 then
    exit;
  try
    repeat
    if (sr.name = '.') or (sr.name = '..') then
      continue;
    fn := path+'\'+sr.name;
    if boolean(sr.attr and faDirectory) then
      delTree(fn)
     else
      deleteFile(fn);
    until findNext(sr) <> 0;
   finally
    findClose(sr);
    rmDir(path);
  end;
end; // deltree

function forceDirectory(path: UnicodeString): Boolean;
var
  s: UnicodeString;
begin
  result := TRUE;
  path := excludeTrailingPathDelimiter(path);
  if path = '' then
    exit;
  if directoryExists(path) then
    exit;
  s := extractFilePath(path);
  if s = path then
    exit; // we are at the top, going nowhere
  forceDirectory(s);
  result := createDir(path);
end; // forceDirectory


function moveToBin(const fn: UnicodeString; force:boolean=FALSE):boolean; overload;
begin
  result := moveToBin(toSA(fn), force)
end;

function moveToBin(files: TUnicodeStringDynArray; force:boolean=FALSE):boolean; overload;
var
  fo: TSHFileOpStruct;
  i: integer;
  fn, test, list: string;
begin
result:=FALSE;
// the list is null-separated. A double-null will mark the end of the list, but delphi adds an extra hidden null in every string.
list:='';
try
  for i:=0 to length(files)-1 do
    begin
    fn:=expandFileName(files[i]); // if we don't specify a full path, the bin won't be used, and the file will be just deleted
    test:=fn;
    if (reMatch(fn, '[*?]', '!')>0) then
      test:=ExtractFilePath(test);
    // this system call doesn't work on linked files. Moreover, it hangs the process for a while, so we try to detect them, to abort.
    if not fileOrDirExists(test) or (hasJunction(test) > '') then continue;

    list:=list+fn+#0;
    end;

  if list = '' then exit;

  try
    ZeroMemory(@fo, sizeOf(fo));
    fo.wFunc:=FO_DELETE;
    fo.pFrom:=pchar(list);
    fo.fFlags:=FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
    result:=SHFileOperation(fo) = 0;
  except result:=FALSE end;
finally
  if not result and force then
    begin
    // enter the rude
    result:=TRUE;
    for i:=0 to length(files)-1 do
      result:=result and deltree(files[i]);
    end;
  end;
end; // moveToBin

function saveFileA(var f: File; const data: RawByteString): Boolean; overload;
begin
  if length(data) > 0 then
    begin
      blockWrite(f, data[1], length(data));
      result := IOresult=0;
    end
   else
    Result := True
end;

function saveFileA(fn: string; const data: RawByteString; append:boolean=FALSE):boolean; overload;
var
  f: file;
  path, temp: string;
begin
result:=FALSE;
try
  if not validFilepath(fn) then
    exit;
  if not isAbsolutePath(fn) then
    chDir(exePath);
  path := extractFilePath(fn);
  if (path > '') and not forceDirectory(path) then
    exit;
  IOresult();
  if append then
    begin
      assignFile(f, fn);
      reset(f,1);
      if IOresult() <> 0 then
        rewrite(f,1)
       else
        seek(f, fileSize(f));
    end
  else
    begin
    // in this case, we save to a temp file, and overwrite the previous one (if it exists) only after the saving is complete
      temp := format('%s~%d.tmp', [fn, random(MAXINT)]);
      if not validFilepath(temp) then // fn may be too long to append something
        temp := format('hfs~%d.tmp', [fn, random(999)]);
      assignFile(f, temp);
      rewrite(f,1)
    end;

  if IOresult() <> 0 then
    exit;
  if not saveFileA(f, data) then
    exit;
  closeFile(f);
  if not append then
    begin
    deleteFile(fn); // this may fail if the file didn't exist already
    renameFile(temp, fn);
    end;
  result:=TRUE;
except end;
end; // saveFile

function saveFileU(fn:string; const data: UnicodeString; append:boolean=FALSE):boolean;
var
  f: file;
  path, temp: string;
begin
  result := FALSE;
try
  if not validFilepath(fn) then exit;
  if not isAbsolutePath(fn) then chDir(exePath);
  path:=extractFilePath(fn);
  if (path > '') and not forceDirectory(path) then exit;
  IOresult();
  if append then
    begin
    assignFile(f, fn);
    reset(f,1);
    if IOresult() <> 0 then rewrite(f,1)
    else seek(f,fileSize(f));
    end
  else
    begin
    // in this case, we save to a temp file, and overwrite the previous one (if it exists) only after the saving is complete
    temp:=format('%s~%d.tmp', [fn, random(MAXINT)]);
    if not validFilepath(temp) then // fn may be too long to append something
      temp:=format('hfs~%d.tmp', [fn, random(999)]);
    assignFile(f, temp);
    rewrite(f,1)
    end;

  if IOresult() <> 0 then exit;
  if not saveFileA(f, UTF8Encode(data)) then exit;
  closeFile(f);
  if not append then
    begin
    deleteFile(fn); // this may fail if the file didn't exist already
    renameFile(temp, fn);
    end;
  result:=TRUE;
except end;
end; // saveFileU

function appendFileU(const fn: String; const data: UnicodeString): Boolean;
begin
  result := saveFileU(fn, data, TRUE)
end;

function appendFileA(const fn: String; const data: RawByteString): Boolean;
begin
  result := saveFileA(fn, data, TRUE)
end;

function moveFile(const src, dst: String; op: UINT=FO_MOVE): Boolean;
var
  fo: TSHFileOpStruct;
begin
  try
    ZeroMemory(@fo, sizeOf(fo));
    fo.wFunc:=op;
    fo.pFrom:=pchar(src+#0);
    fo.pTo:=pchar(dst+#0);
    fo.fFlags:=FOF_ALLOWUNDO + FOF_NOCONFIRMATION + FOF_NOERRORUI + FOF_SILENT + FOF_NOCONFIRMMKDIR;
    result:=SHFileOperation(fo) = 0;
   except
    result:=FALSE
  end;
end; // movefile

function copyFile(const src, dst: String): Boolean;
begin
  result := movefile(src, dst, FO_COPY)
end;


function localDNSget(const ip: String): String;
var
  i: Integer;
begin
  for i :=0 to length(address2name) div 2-1 do
    if addressmatch(address2name[i*2+1], ip) then
      begin
        result := address2name[i*2];
        exit;
      end;
  result := '';
end; // localDNSget

function safeMod(a, b: int64; default: int64=0): int64;
begin if b=0 then result:=default else result:=a mod b end;

function safeDiv(a, b: int64; default: int64=0): int64; inline;
begin if b=0 then result:=default else result:=a div b end;

function safeDiv(a, b: real; default: real=0): real; inline;
begin if b=0 then result:=default else result:=a/b end;

// useful for casing on the first char
function getFirstChar(const s: String): Char;
begin
  if s = '' then
    result := #0
   else
    result := s[1]
end; // getFirstChar


function getAccountList(users: boolean=TRUE; groups: boolean=TRUE): TstringDynArray;
var
  n, i: integer;
begin
  setLength(result, length(accounts));
  n := 0;
  for i :=0 to length(result)-1 do
    with accounts[i] do
      if group and groups
      or not group and users
      then
        begin
        result[n]:=user;
        inc(n);
        end;
  setlength(result, n);
end; // getAccountList

function notModified(conn: ThttpConn; const etag, ts: String): Boolean; overload;
begin
  result := (etag>'') and (etag = conn.getHeader('If-None-Match'));
  if result then
  begin
    conn.reply.mode := HRM_NOT_MODIFIED;
    exit;
  end;
  conn.setHeaderIfNone('ETag', etag);
  if ts > '' then
    conn.setHeaderIfNone('Last-Modified', ts);
end; // notModified

function notModified(conn: ThttpConn; const f: String): Boolean; overload;
begin
  result := notModified(conn, getEtag(f), dateToHTTP(f))
end;

function getAgentID(s: String): String; overload;
var
  res: string;

  function test(const id: String): Boolean;
  var
    i: integer;
  begin
  result:=FALSE;
  i:=pos(id,s);
  case i of
    0: exit;
    1: res := getTill('/', getTill(' ',s));
    else
      begin
      delete(s,1,i-1);
      res:=getTill(';',s);
      end;
    end;
  result:=TRUE;
  end; // its

begin
  result := stripChars(s,['<','>']);
  if test('Crazy Browser')
  or test('iPhone')
  or test('iPod')
  or test('iPad')
  or test('Chrome')
  or test('WebKit') // generic webkit browser
  or test('Opera')
  or test('MSIE')
  or test('Mozilla') then
    result := res;
end; // getAgentID

function getAgentID(conn: ThttpConn):string; overload;
begin
  result := getAgentID(conn.getHeader('User-Agent'))
end;

procedure drawGraphOn(cnv: Tcanvas; colors: TIntegerDynArray=NIL);
var
  i, h, maxV, sI: integer;
  r: Trect;
  top: double;
  s: string;

  procedure drawSample(sample: int64);
  var
    a: Integer;
  begin
    cnv.moveTo(r.left+i, r.bottom);
    a := (sample*h div maxV);
    cnv.lineTo(r.Left+i, r.Bottom - 1 - a);
  end; // drawSample

  function getColor(idx: integer; def:Tcolor):Tcolor;
  begin
    if (length(colors) <= idx) or (colors[idx] = Graphics.clDefault) then
      result := def
     else
      result := colors[idx]
  end; // getColor

begin
  cnv.Lock;
  try
    r := cnv.cliprect;
    // clear
    cnv.brush.color := getColor(0, clBlack);
    cnv.fillrect(r);
    // draw grid
    cnv.Pen.color := getColor(1, rgb(0,0,120));
    i:=r.left;
    while i < r.right do
      begin
        cnv.moveTo(i, r.top);
        cnv.LineTo(i, r.Bottom);
        inc(i,10);
      end;
    i:=r.bottom;
    while i > r.top do
      begin
        cnv.moveTo(r.left, i);
        cnv.LineTo(r.right, i);
        dec(i,10);
      end;

    maxV := max(graph.maxV, 1);
    h := r.bottom-r.top-1;
    // draw graph
    if r.Right > r.left then
      begin
        sI := Min((r.Right-r.left)-1, Length(graph.samplesOut)-1);

        cnv.Pen.color := getColor(2, clFuchsia);
        for i:=0 to sI do
          drawSample(graph.samplesOut[i]);
        cnv.Pen.color := getColor(3, clYellow);
        for i:=0 to sI do
          drawSample(graph.samplesIn[i]);
      end;
    // text
    cnv.Font.Color := getColor(4, clLtGray);
    cnv.Font.Name := 'Small Fonts';
    cnv.font.size := 7;
    SetBkMode(cnv.handle, TRANSPARENT);
    top := (graph.maxV/1000)*safeDiv(10.0, graph.rate);
    s := format(TOP_SPEED+':'+MSG_SPEED_KBS+'    ---    %d kbps', [top, round(top*8)]);
    cnv.TextOut(r.right-cnv.TextWidth(s)-20, 3, s);
    if assigned(globalLimiter) and (globalLimiter.maxSpeed < MAXINT) then
      cnv.TextOut(r.right-180+25, 15, format(LIMIT+': '+MSG_SPEED_KBS, [globalLimiter.maxSpeed/1000]));
  finally
    cnv.Unlock;
  end;
end; // drawGraphOn

function recalculateGraph(s: ThttpSrv): Boolean;
var
  i: integer;
begin
  Result := False;
  if (s = NIL) then // or quitting then
    exit;
// shift samples
  i := sizeOf(graph.samplesOut)-sizeOf(graph.samplesOut[0]);
  move(graph.samplesOut[0], graph.samplesOut[1], i);
  move(graph.samplesIn[0], graph.samplesIn[1], i);
 // insert new "out" sample
  graph.samplesOut[0] := s.bytesSent-graph.lastOut;
  graph.lastOut := s.bytesSent;
// insert new "in" sample
  graph.samplesIn[0] := s.bytesReceived-graph.lastIn;
  graph.lastIn := s.bytesReceived;
// increase the max value
  i := max(graph.samplesOut[0], graph.samplesIn[0]);
  if i > graph.maxV then
    begin
      graph.maxV := i;
      graph.beforeRecalcMax := 100;
    end;
  Result := graph.maxV <> 0;
  dec(graph.beforeRecalcMax);
  if graph.beforeRecalcMax > 0 then
    exit;
// recalculate max value
  graph.maxV := 0;
  with graph do
    for i:=0 to length(samplesOut)-1 do
      maxV := max(maxV, max(samplesOut[i], samplesIn[i]) );
  graph.beforeRecalcMax:=100;
  Result := True;
end; // recalculateGraph

procedure resetGraph(s: ThttpSrv);
begin
  zeroMemory(@graph.samplesIn, sizeOf(graph.samplesIn));
  zeroMemory(@graph.samplesOut, sizeOf(graph.samplesOut));
  graph.maxV:=0;
  graph.beforeRecalcMax:=1;
  recalculateGraph(s);
end;

function dllIsPresent(const name: String): Boolean;
var
  h: HMODULE;
begin
  h := LoadLibraryEx(@name, 0, LOAD_LIBRARY_AS_DATAFILE);
  result := h<>0;
  FreeLibrary(h);
end;

// taken from http://www.delphi3000.com/articles/article_3361.asp
function captureExec(const DosApp: string; out output:string; out exitcode:cardinal; timeout:real=0):boolean;
const
  ReadBuffer = 1048576;  // 1 MB Buffer
var
  sa            : TSecurityAttributes;
  ReadPipe,WritePipe  : THandle;
  start               : TStartUpInfo;
  ProcessInfo         : TProcessInformation;
  Buffer              : PAnsiChar;
  buf2                : PChar;
  TotalBytesRead,
  BytesRead           : DWORD;
  Apprunning,
  BytesLeftThisMessage,
  TotalBytesAvail : integer;
begin
result:=FALSE;
output:='';
sa.nlength:=SizeOf(sa);
sa.binherithandle:=TRUE;
sa.lpsecuritydescriptor:=NIL;

if not createPipe(ReadPipe, WritePipe, @sa, 0) then exit;
// Redirect In- and Output through STARTUPINFO structure
  Buffer := AllocMem(ReadBuffer + 1);
  ZeroMemory(@start, Sizeof(Start));
  start.cb:= SizeOf(start);
start.hStdOutput:= WritePipe;
start.hStdInput:= ReadPipe;
start.dwFlags:= STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
start.wShowWindow:= SW_HIDE;
TotalBytesRead:=0;
if timeout = 0 then
  timeout := MaxDouble
else
  timeout:=now()+timeout/SECONDS;
// Create a Console Child Process with redirected input and output
try
  if CreateProcess(nil, PChar(DosApp), @sa, @sa, true, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, nil, start, ProcessInfo) then
    repeat
    result:=TRUE;
    // wait for end of child process
    Apprunning := WaitForSingleObject(ProcessInfo.hProcess,100);
//    Application.ProcessMessages();
    // it is important to read from time to time the output information
    // so that the pipe is not blocked by an overflow. New information
    // can be written from the console app to the pipe only if there is
    // enough buffer space.
    if not PeekNamedPipe(ReadPipe, @Buffer[TotalBytesRead], ReadBuffer,
      @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage ) then
      break
    else if BytesRead > 0 then
      ReadFile(ReadPipe, Buffer[TotalBytesRead], BytesRead, BytesRead, nil );
    inc(TotalBytesRead, BytesRead);
    until (Apprunning <> WAIT_TIMEOUT) or (now() >= timeout);

  if IsTextUnicode(Buffer, TotalBytesRead, NIL) then
    begin
    Pchar(@Buffer[TotalBytesRead])^:= #0;
    output:=pchar(Buffer)
    end
  else
    begin
      Buffer[TotalBytesRead]:= #0;
      buf2 := StrAlloc(ReadBuffer + 1);
      OemToChar(PansiChar(Buffer), buf2);
      output := strPas(buf2);
    end;
finally
  GetExitCodeProcess(ProcessInfo.hProcess, exitcode);
  TerminateProcess(ProcessInfo.hProcess, 0);
  FreeMem(Buffer);
  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
  CloseHandle(ReadPipe);
  CloseHandle(WritePipe);
  end;
end; // captureExec

// calculates the value of a constant formula
function evalFormula(s: String): Real;
// this algo is by far not the quickest, because it manipulates the string, but it's the simpler that came to my mind
const
  PAR_VAL = 100;
var
  i, v,
  mImp, // index of the most important operator
  mImpV: integer; // importance of the most important
  ofsImp: integer; // importance offset, due to parenthesis
  ch: char;
  left, right: real;
  leftS, rightS: string;

  function getOperand(dir:integer):string;
  var
    j: integer;
  begin
  i:=mImp+dir;
    repeat
    j:=i+dir;
    if (j > 0) and (j <= length(s))
    and (charInSet(s[j], ['0'..'9','.','E']) or (j>1) and charInSet(s[j],['+','-']) and (s[j-1]='E')) then
      i:=j
    else
      break;
    until false;
  j:=mImp+dir;
  swapMem(i, j, sizeOf(i), dir > 0);
  j:=j-i+1;
  result:=copy(s, i, j);
  end; // getOperand

begin
  repeat
    // search the most urgent operator
    ofsImp:=0;
    mImp:=0;
    mImpV:=0;
    for i:=1 to length(s) do
      begin
        // calculate operator precedence (if any)
        ch:=s[i];
        v:=0;
        case ch of
          '*','/','%','[',']': v:=5+ofsImp;
          '+','-': v:=3+ofsImp;
          '(': inc(ofsImp, PAR_VAL);
          ')': dec(ofsImp, PAR_VAL);
          end;

        if (i = 1) // a starting operator is not an operator
        or (s[i-1]='E') // exponential syntax
        or (v <= mImpV) // left-to-right precedence
        then continue;
        // we got a better one, record it
        mImpV:=v;
        mImp:=i;
      end;//for

    // found or not?
    if mImp = 0 then
      begin
      result:=strToFloat(s);
      exit;
      end;
    // determine operates
    leftS:=getOperand(-1);
    rightS:=getOperand(+1);
    left:=StrToFloatDef(trim(leftS), 0);
    right:=strToFloat(trim(rightS));
    // calculate
    ch:=s[mImp];
    case ch of
      '+': result:=left+right;
      '-': result:=left-right;
      '*': result:=left*right;
      '/':
        if right <> 0 then result:=left/right
        else raise Exception.create('division by zero');
      '%':
        if right <> 0 then result:=trunc(left) mod trunc(right)
        else raise Exception.create('division by zero');
      '[': result:=round(left) shl round(right);
      ']': result:=round(left) shr round(right);
      else raise Exception.create('operator not supported: '+ch);
      end;
    // replace sub-expression with result
    i:=mImp-length(leftS);
    v:=mImp+length(rightS);
    if (i > 1) and (v < length(s)) and (s[i-1] = '(') and (s[v+1] = ')') then
      begin  // remove also parenthesis
      dec(i);
      inc(v);
      end;
    if v-i+1 = length(s) then
      exit; // we already got the result
    replace(s, floatToStr(result), i, v);
  until false;
end; // evalFormula


INITIALIZATION

ipToInt_cache:=THashedStringList.Create;
ipToInt_cache.Sorted:=TRUE;
ipToInt_cache.Duplicates:=dupIgnore;

// calculate GMToffset
var
  TZinfo: TTimeZoneInformation;

GetTimeZoneInformation(TZinfo);
case GetTimeZoneInformation(TZInfo) of
  TIME_ZONE_ID_STANDARD: GMToffset:=TZInfo.StandardBias;
  TIME_ZONE_ID_DAYLIGHT: GMToffset:=TZInfo.DaylightBias;
  else GMToffset:=0;
  end;
GMToffset:=-(TZinfo.bias+GMToffset);


FINALIZATION
freeAndNIL(ipToInt_cache);

end.
