unit srvUtils;
{$I DEFS.inc}
{$I NoRTTI.inc}

interface
uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF MSWINDOWS}
 {$IFDEF FMX}
  FMX.Graphics, System.UITypes, FMX.Types,
 {$ELSE ~FMX}
  Graphics,
 {$ENDIF FMX}
  Classes, Types,
  HSLib, srvConst;

  function xtpl(src: String; const table: array of string): String; OverLoad;
  function xtpl(src: RawByteString; table: array of RawByteString): RawByteString; OverLoad;
  function escapeNL(s: String): String;
  function unescapeNL(s: String): String;
  function htmlEncode(const s:string):string;
  function substr(const s: RawByteString; start: Integer; upTo: Integer=0): RawByteString; inline; OverLoad;
  function substr(const s: String; start: Integer; upTo: Integer=0): String; inline; overload;
  function substr(const s: String; const after: String): String; overload;
  function replace(var s: String; const ss: String; start, upTo: Integer): Integer;
  function strAt(const s, ss:string; at:integer):boolean; inline;
  procedure enforceNUL(var s: string); OverLoad;
  procedure enforceNUL(var s: RawbyteString); OverLoad;
  function dequote(const s:string; quoteChars:TcharSetW=['"']):string;
  function removeStartingStr(const ss, s: String): String;
  procedure excludeTrailingString(var s: string; const ss:string);
  function smartsize(size: int64): String;
  function elapsedToStr(t: TDateTime): String;
 {$IFDEF FMX}
  function stringToColorEx(s:string; default:Tcolor= TColorRec.Null): Tcolor;
 {$ELSE FMX}
  function stringToColorEx(s:string; default:Tcolor=clNone):Tcolor;
 {$ENDIF FMX}
//  function reCache(exp:string; mods:string='m'):TregExpr;
  function reMatch(const s, exp:string; mods:string='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
  function reReplace(const subj, exp, repl: String; const mods: String='m'): String;
  function reGet(const s, exp:string; subexpIdx:integer=1; mods:string='!mi'; ofs:integer=1):string;
  function if_(v:boolean; const v1:string; const v2:string=''):string; overload; inline;
  function if_(v: Boolean; const v1: RawByteString; const v2: RawByteString = ''): RawByteString;overload; inline;
  function if_(v:boolean; v1:int64; v2:int64=0):int64; overload; inline;
  function if_(v:boolean; v1:integer; v2:integer=0):integer; overload; inline;
  function if_(v:boolean; v1:Tobject; v2:Tobject=NIL):Tobject; overload; inline;
  function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean; overload; inline;
  function isExtension(const filename, ext: String): Boolean;

  function swapMem(var src, dest; count: dword; cond: Boolean=TRUE): Boolean;

// strings array
  function  stringExists(const s: String; const a: array of String; isSorted: Boolean=FALSE): Boolean;
  function  removeString(var a: TStringDynArray; idx: integer; l:integer=1): Boolean; overload;
  function  removeString(const s: String; var a: TStringDynArray; onlyOnce: Boolean=TRUE; ci: Boolean=TRUE; keepOrder: Boolean=TRUE): Boolean; overload;
  procedure removeStrings(const find: String; var a: TStringDynArray);
  procedure toggleString(const s: String; var ss: TStringDynArray);
  function  onlyString(const s: String; ss: TStringDynArray): boolean;
  function  addArray(var dst: TstringDynArray; src: array of string; where: Integer=-1; srcOfs: Integer=0; srcLn: Integer=-1): Integer;
  function  removeArray(var src: TstringDynArray; toRemove:array of string):integer;
  function  split(const separator, s: String; nonQuoted:boolean=FALSE):TStringDynArray;
  function  splitU(const s, separator: RawByteString; nonQuoted:boolean=FALSE):TStringDynArray;
  function  join(const separator: String; ss:TstringDynArray):string;
  function  listToArray(l: Tstrings): TstringDynArray;
  function  arrayToList(a: TStringDynArray; list: TstringList=NIL): TstringList;

  function  toSA(a: array of string): TstringDynArray; // this is just to have a way to typecast
  function  addUniqueString(const s: String; var ss: TStringDynArray): boolean;
  function  addString(const s: String; var ss: TStringDynArray): integer;
  function  replaceString(var ss: TStringDynArray; const old, new: String): Integer;
  function  popString(var ss: TstringDynArray): String;
  procedure insertString(const s: String; idx: integer; var ss: TStringDynArray);
  function  addUniqueArray(var a:TstringDynArray; b:array of string):integer;
  procedure uniqueStrings(var a:TstringDynArray; ci:Boolean=TRUE);
  procedure sortArray(var a:TStringDynArray);
  function  sortArrayF(const a:TStringDynArray):TStringDynArray;
  function  idxOf(const s: String; a:array of string; isSorted:boolean=FALSE):integer;

  function match(mask, txt: pchar; fullMatch:boolean=TRUE; charsNotWildcard: TcharsetW=[]): Integer;
  function filematch(mask: String; const fn: String):boolean;
  function poss(chars: TcharSetW; s: String; ofs: Integer=1): Integer;
  function strToCharset(const s: string): TcharsetW;
  function anycharIn(const chars, s:string):boolean; overload;
  function anycharIn(chars: TcharsetW; const s: String): Boolean; overload;
  function stripChars(s: String; cs: TcharsetW; invert: boolean=FALSE): String;
  function singleLine(const s: string): boolean;
  function findEOL(const s:string; ofs:integer=1; included:boolean=TRUE):integer;
  function quoteIfAnyChar(const badChars: String; s:string; const quote:string='"'; const unquote:string='"'):string;
  function getKeyFromString(const s:string; key:string; const def:string=''):string;
  function setKeyInString(s:string; key:string; val:string=''):string;
  function getMtimeUTC(filename:string):Tdatetime;
  function getMtime(filename:string):Tdatetime;
  function getStr(from, to_: pAnsichar): RawByteString; OverLoad;
  function getStr(from, to_: pchar): String; OverLoad;
  function getTill(const ss, s:string; included:boolean=FALSE):string; overload;
  function getTill(i:integer; const s:string):string; overload;
  function getTill(const ss, s: RawByteString; included:boolean=FALSE): RawByteString; OverLoad;
  function getTill(i:integer; const s: RawByteString): RawByteString; OverLoad;
  function getSectionAt(p: pchar; out name: string): boolean;
  function isSectionAt(p: pChar): boolean;

  function name2mimetype(const fn: String; const default: RawByteString): RawByteString;

  function strSHA256(const s: String): String;
  function strMD5(const s: String): String;
  function getCRC(const data: RawByteString): Integer;


  function ipToInt(const ip:string):dword;
  function addressmatch(mask: String; const address: string):boolean;

  function b64utf8(const s:string): RawByteString;
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
  function TLV_NOT_EMPTY(t: Integer; const data: RawByteString): RawByteString;
  function TLVS_NOT_EMPTY(t: Integer; const data: String): RawByteString;

  function dt_(const s: RawByteString): TDatetime;
  function int_(const s: RawByteString): Integer;
  function str_(i: integer): RawByteString; overload;
  function str_(t: Tdatetime): RawByteString; overload;
  function str_(b: boolean): RawByteString; overload;

  function compare_(i1, i2: double): integer; overload;
  function compare_(i1, i2: int64): integer; overload;
  function compare_(i1, i2: integer): integer; overload;

  function first(a, b: integer): Integer; overload;
  function first(a, b: double): Double; overload;
  function first(a, b: pointer): Pointer; overload;
  function first(const a, b: String): String; overload;
  function first(a: array of string): String; overload;
  function first(a: array of RawByteString): RawByteString; overload;

  function diskSpaceAt(path: String): Int64;
  function getRes(name: PChar; const typ: string='TEXT'): RawByteString;

  function accountExists(const user: String; evenGroups: Boolean=FALSE): Boolean;
  function getAccount(const user: String; evenGroups: Boolean=FALSE): Paccount;
  function accountRecursion(account: Paccount; stopCase: TaccountRecursionStopCase; data: pointer=NIL; data2: pointer=NIL): Paccount;
  function findEnabledLinkedAccount(account: Paccount; over:TStringDynArray; isSorted: Boolean=FALSE): Paccount;
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

  function reduceSpaces(s: String; const replacement:string=' '; spaces:TcharSetW=[]):string;

  function dirCrossing(const s: String): boolean;
  function fileOrDirExists(fn: String): boolean;
  function getEtag(const filename: String): String;

  function localDNSget(const ip: String): String;

  function safeDiv(a, b: real; default: real=0): Real; overload;
  function safeDiv(a, b: int64; default: int64=0): Int64; overload;
  function safeMod(a, b: int64; default: int64=0): Int64;

  function getAccountList(users: boolean=TRUE; groups: boolean=TRUE): TstringDynArray;

  function notModified(conn: ThttpConn; const etag, ts: String): Boolean; overload;
  function notModified(conn: ThttpConn; const f: String): Boolean; overload;

  function getAgentID(conn: ThttpConn): String; overload;
  procedure drawGraphOn(cnv: Tcanvas; colors: TIntegerDynArray=NIL);
  function recalculateGraph(s: ThttpSrv): Boolean;
  procedure resetGraph(s: ThttpSrv);

type
  TfastStringAppend = class
   protected
    buff: string;
    n: integer;
   public
    function length():integer;
    function reset():string;
    function get():string;
    function append(const s:string):integer;
  end;

const
  PTR1: Tobject = ptr(1);


implementation
uses
  math, SysUtils, strutils, RegExpr, iniFiles, DateUtils,
  OverbyteIcsWSocket,
  Base64,
  RDUtils, RnQCrypt,
  srvVars,
  ansistrings;

var
  ipToInt_cache: ThashedStringList;


//////////// TfastStringAppend

function TfastStringAppend.length():integer;
begin result:=n end;

function TfastStringAppend.get():string;
begin
setlength(buff, n);
result:=buff;
end; // get

function TfastStringAppend.reset():string;
begin
result:=get();
buff:='';
n:=0;
end; // reset

function TfastStringAppend.append(const s: string):integer;
var
  ls, lb: integer;
begin
  ls := system.length(s);
  if ls > 0 then
    begin
      lb := system.length(buff);
      if n+ls > lb then
        setlength(buff, lb+ls+20000);
      MoveChars(s[1], buff[n+1], ls);
      inc(n, ls);
    end;
  result:=n;
end; // append


function xtpl(src: String; const table: array of String): String;
var
  i:integer;
begin
i:=0;
while i < length(table) do
  begin
  src := SysUtils.StringReplace(src,table[i],table[i+1],[rfReplaceAll,rfIgnoreCase]);
  inc(i, 2);
  end;
result:=src;
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


type
  Tnewline = (NL_UNK, NL_D, NL_A, NL_DA, NL_MIXED);

function newlineType(s:string):Tnewline;
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
      if a > 0 then exit;
      // search for an unpaired #13
      l:=length(s);
      while (d < l) and (s[d+1] = #10) do
        d:=posEx(#13, s, d+1);
      if d > 0 then exit;
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

function htmlEncode(const s:string):string;
var
  i: integer;
  p: string;
  fs: TfastStringAppend;
begin
fs:=TfastStringAppend.create;
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
finally fs.free end;
end; // htmlEncode


function substr(const s:string; start:integer; upTo:integer=0):string; inline;
var
  l: integer;
begin
l:=length(s);
if start = 0 then inc(start)
else if start < 0 then start:=l+start+1;
if upTo <= 0 then upTo:=l+upTo;
result:=copy(s, start, upTo-start+1)
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
i:=pos(after,s);
if i = 0 then result:=''
else result:=copy(s, i+length(after), MAXINT)
end; // substr

function replace(var s: String; const ss: String; start,upTo: Integer): Integer;
var
  common, oldL, surplus: Integer;
begin
  oldL := upTo-start+1;
  common := min(length(ss), oldL);
  if common > 0 then
    MoveChars(ss[1], s[start], common);
  surplus := oldL-length(ss);
  if surplus > 0 then
    delete(s, start+length(ss), surplus)
   else
    insert(copy(ss, common+1, -surplus), s, start+common);
  result := -surplus;
end; // replace

// tells if a substring is found at specific position
function strAt(const s, ss:string; at:integer):boolean; inline;
begin
if (ss = '') or (length(s) < at+length(ss)-1) then result:=FALSE
else if length(ss) = 1 then result:=s[at] = ss[1]
else if length(ss) = 2 then result:=(s[at] = ss[1]) and (s[at+1] = ss[2])
else result:=copy(s,at,length(ss)) = ss;
end; // strAt

procedure enforceNUL(var s:string);
begin
  if s>'' then
    setLength(s, strLen(PWideChar(@s[1])))
end; // enforceNUL

procedure enforceNUL(var s:RawByteString);
begin
  if s>'' then
    setLength(s, ansistrings.strLen(PAnsiChar(@s[1])))
end; // enforceNUL

var
  reTempCache, reFixedCache: THashedStringList;

function reCache(exp:string; mods:string='m'):TregExpr;
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
i:=pos('!', mods);
temporary:= i=0;
Tobject(cache):=if_(temporary, reTempCache, reFixedCache);
delete(mods, i, 1);

// access the cache
key:=mods+#255+exp;
i:=cache.indexOf(key);
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

function reMatch(const s, exp:string; mods:string='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
var
  i: integer;
  re: TRegExpr;
begin
result:=0;
re:=reCache(exp,mods);
if assigned(subexp) then
  subexp^:=NIL;
// do the job
try
  re.inputString:=s;
  if not re.execPos(ofs) then exit;
  result:=re.matchPos[0];
  if subexp = NIL then exit;
  i:=re.subExprMatchCount;
  setLength(subexp^, i+1); // it does include also the whole match, with index zero
  for i:=0 to i do
    subexp^[i]:=re.match[i]
except end;
end; // reMatch

function reReplace(const subj, exp, repl: String; const mods: String='m'): String;
var
  re: TRegExpr;
begin
  re := reCache(exp, mods);
  result := re.replace(subj, repl, TRUE);
end; // reReplace

function reGet(const s, exp:string; subexpIdx:integer=1; mods:string='!mi'; ofs:integer=1):string;
var
  se: TstringDynArray;
begin
if reMatch(s, exp, mods, ofs, @se) > 0 then
  result:=se[subexpIdx]
else
  result:='';
end; // reGet

function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; const v1, v2:string):string;
begin if v then result:=v1 else result:=v2 end;

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

procedure excludeTrailingString(var s: String; const ss: String);
var
  i: integer;
begin
  i := length(s)-length(ss);
  if i >= 0 then
    if copy(s, i+1, length(ss)) = ss then
      setLength(s, i);
end;

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

function stringToColorEx(s:string; default:Tcolor=clNone):Tcolor;
begin
try
  if reMatch(s, '#?[0-9a-f]{3,6}','!i') > 0 then
    begin
    s:=removeStartingStr('#', s);
    case length(s) of
      3: s:=s[3]+s[3]+s[2]+s[2]+s[1]+s[1];
      6: s:=s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
      end;
    end;
  result:=stringToColor('$'+s)
except
  try result:=stringToColor('cl'+s);
  except
    if default = clNone then
      result:=stringToColor(s)
    else
      try result:=stringToColor(s)
      except result:=default end;
    end;
  end;
end; // stringToColorEx

function isExtension(const filename, ext: String):boolean;
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

function addArray(var dst:TstringDynArray; src:array of string; where:integer=-1; srcOfs:integer=0; srcLn:integer=-1):integer;
var
  i, l:integer;
begin
l:=length(dst);
if where < 0 then // this means: at the end of it
  where:=l;
if srcLn < 0 then
  srcLn:=length(src);
setLength(dst, l+srcLn); // enlarge your array!

i:=max(l, where+srcLn);
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
result:=l+srcLn;
end; // addArray

function addUniqueArray(var a:TstringDynArray; b:array of string):integer;
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
  i:=idxOf(find,a);
  if i < 0 then break;
  l:=1;
  while (i+l < length(a)) and (ansiCompareText(a[i+l], find) = 0) do inc(l);
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
result:=idxof(s, ss) < 0;
if result then addString(s, ss)
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
var i, lessen:integer;
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

function split(const separator, s:string; nonQuoted:boolean=FALSE):TStringDynArray;
var
  i, j, n, l: integer;
begin
l:=length(s);
result:=NIL;
if l = 0 then exit;
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
l:=length(s);
result:=NIL;
if l = 0 then exit;
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
result:='';
if length(ss) = 0 then exit;
result:=ss[0];
for i:=1 to length(ss)-1 do
  result:=result+separator+ss[i];
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
function getKeyFromString(const s:string; key:string; const def:string=''):string;
var
  i: integer;
begin
result:=def;
includeTrailingString(key, '=');
i:=1;
  repeat
  i:= ipos(key, s, i);
  if i = 0 then exit; // not found
  until (i = 1) or (s[i-1] in [#13,#10]); // ensure we are at the very beginning of the line
inc(i, length(key));
result:=substr(s,i, findEOL(s,i,FALSE));
end; // getKeyFromString

// "key=val" in second parameter (with 3rd one empty) is supported
function setKeyInString(s:string; key:string; val:string=''):string;
var
  i: integer;
begin
i:=pos('=', key);
if i = 0 then
  key:=key+'='
else if val = '' then
  begin
  val:=copy(key,i+1,MAXINT);
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


function toSA(a: array of string): TstringDynArray; // this is just to have a way to typecast
begin
  result := NIL;
  addArray(result, a);
end; // toSA

function getMtimeUTC(filename:string):Tdatetime;
var
  sr: TsearchRec;
  st: TSystemTime;
begin
result:=0;
if findFirst(filename, faAnyFile, sr) <> 0 then exit;
FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
result:=SystemTimeToDateTime(st);
findClose(sr);
end; // getMtimeUTC

function getMtime(filename:string):Tdatetime;
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
      to_ := ansistrings.strEnd(from);
      dec(to_);
    end;
  l := to_-from+1;
  setLength(result, l);
  if l > 0 then
    ansistrings.strLcopy(@result[1], from, l);
end; // getStr

function getStr(from, to_:pchar): String;
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

function getTill(const ss, s:string; included:boolean=FALSE):string;
var
  i: integer;
begin
i:=pos(ss, s);
if i = 0 then result:=s
else result:=copy(s,1,i-1+if_(included,length(ss)));
end; // getTill

function getTill(const ss, s: RawByteString; included:boolean=FALSE): RawByteString;
var
  i: integer;
begin
  i := pos(ss, s);
  if i = 0 then
    result := s
   else
    result := copy(s,1,i-1+if_(included,length(ss)));
end; // getTill


function getTill(i:integer; const s:string):string;
begin
if i < 0 then i:=length(s)+i;
result:=copy(s, 1, i);
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
begin
  result := default;
  for var i: Integer := 0 to length(mimeTypes) div 2-1 do
    if fileMatch(mimeTypes[i*2], fn) then
     begin
      result := mimeTypes[i*2+1];
      exit;
     end;
  for var i: Integer := 0 to length(DEFAULT_MIME_TYPES) div 2-1 do
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

function ipv6hex(ip:TIcsIPv6Address):string;
begin
setLength(result, 4*8);
binToHex(@ip.words[0], pchar(result), sizeOf(ip))
end;

function ipToInt(const ip:string):dword;
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


function addressMatch(mask: String; const address: string):boolean;
var
  invert: boolean;
  addr4: dword;
  addr6: string;
  bits: integer;
  a: TStringDynArray;

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

begin
result:=FALSE;
invert:=FALSE;
while (mask > '') and (mask[1] = '\') do
  begin
  delete(mask,1,1);
  invert:=not invert;
  end;
addr6:=ipv6fix(address);
addr4:=0;
if addr6 = '' then
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
    if addr6 > '' then
      result:=ipv6range()
    else
      result:=(pos(':',a[0]) = 0) and (addr4 >= ipToInt(a[0])) and (addr4 <= ipToInt(a[1]));
    continue;
    end;

  // bitmask? ipv4 only
  a:=split('/', mask);
  if (addr6='') and (length(a) = 2) then
    begin
    try
      bits:=32-strToInt(a[1]);
      result:=addr4 shr bits = ipToInt(a[0]) shr bits;
    except
      end;
    continue;
    end;

  // single
  result:=match( pchar(mask), pchar(address) ) > 0;
  end;
result:=result xor invert;
end; // addressMatch

function b64utf8(const s:string): RawByteString;
begin result:=Base64EncodeString(UTF8encode(s)); end;

function b64utf8W(const s:string): UnicodeString;
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

function TLV(t:integer; const data: RawByteString): RawByteString;
begin result:=str_(t)+str_(length(data))+data end;

function TLVS(t:integer; const data: String): RawByteString;
begin result:=TLV(t, StrToUTF8(data)) end;

function TLV_NOT_EMPTY(t:integer; const data: RawByteString): RawByteString;
begin if data > '' then result:=TLV(t,data) else result:='' end;

function TLVS_NOT_EMPTY(t:integer; const data: String): RawByteString;
begin if data > '' then result:=TLV(t, StrToUTF8(data)) else result:='' end;

// converts from integer to string[4]
function str_(i:integer): RawByteString; overload;
begin
  setlength(result, 4 div sizeOf(AnsiChar));
  move(i, result[1], 4 div sizeOf(AnsiChar));
end; // str_

// converts from boolean to string[1]
function str_(b:boolean):RawByteString; overload;
begin result:= Ansichar(b) end;

// converts from Tdatetime to string[8]
function str_(t:Tdatetime): RawByteString; overload;
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
function dt_(const s: RawByteString):Tdatetime;
begin result:=Pdatetime(@s[1])^ end;

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

function first(const a,b:string):string;
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

function getRes(name:pchar; const typ:string='TEXT'): RawByteString;
var
  h1, h2: Thandle;
  p: pByte;
  l: integer;
  ansi: RawByteString;
begin
  result:='';
  h1:=FindResource(HInstance, name, pchar(typ));
  h2:=LoadResource(HInstance, h1);
  if h2=0 then
    exit;
  l:=SizeOfResource(HInstance, h1);
  p := LockResource(h2);
  setLength(ansi, l);
  move(p^, ansi[1], l);
  UnlockResource(h2);
  FreeResource(h2);
  result := ansi;
end; // getRes


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

function reduceSpaces(s: String; const replacement: String=' '; spaces: TcharSetW=[]): String;
var
  i, c, l: integer;
begin
if spaces = [] then include(spaces, ' ');
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
function dirCrossing(const s:string):boolean;
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
  try result:=exec(s);
  except end;
end; // dirCrossing

function fileOrDirExists(fn:string):boolean;
begin
result:=fileExists(fn) or directoryExists(fn);
{** first i used this way, because faster, but it proved to not always work: http://www.rejetto.com/forum/index.php/topic,10825.0.html
var
  sr:TsearchRec;
begin
result:= 0=findFirst(ExcludeTrailingPathDelimiter(fn),faAnyFile,sr);
if result then FindClose(sr);
}
end; // fileOrDirExists

function getEtag(const filename: String): String;
var
  sr: TsearchRec;
  st: TSystemTime;
begin
  result:='';
  if findFirst(filename, faAnyFile, sr) <> 0 then
    exit;
  FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
  result := intToStr(sr.Size)+':'+floatToStr(SystemTimeToDateTime(st))+':'+expandFileName(filename);
  findClose(sr);
  result := MD5PassHS(StrToUTF8(result));
end; // getEtag


function localDNSget(const ip: String): String;
begin
  for var i: integer :=0 to length(address2name) div 2-1 do
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

function getAccountList(users: boolean=TRUE; groups: boolean=TRUE): TstringDynArray;
var
  n: integer;
begin
  setLength(result, length(accounts));
  n := 0;
  for var i: Integer :=0 to length(result)-1 do
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
    conn.reply.mode:=HRM_NOT_MODIFIED;
    exit;
  end;
  conn.setHeaderIfNone('ETag',etag);
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
    1: res:=getTill('/', getTill(' ',s));
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

 resourcestring
  LIMIT = 'Limit';
  TOP_SPEED = 'Top speed';
begin
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

  maxV:=max(graph.maxV, 1);
  h:=r.bottom-r.top-1;
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
  cnv.Font.Color:=getColor(4, clLtGray);
  cnv.Font.Name:='Small Fonts';
  cnv.font.size:=7;
  SetBkMode(cnv.handle, TRANSPARENT);
  top:=(graph.maxV/1000)*safeDiv(10.0, graph.rate);
  s:=format(TOP_SPEED+':'+MSG_SPEED_KBS+'    ---    %d kbps', [top, round(top*8)]);
  cnv.TextOut(r.right-cnv.TextWidth(s)-20, 3, s);
  if assigned(globalLimiter) and (globalLimiter.maxSpeed < MAXINT) then
    cnv.TextOut(r.right-180+25, 15, format(LIMIT+': '+MSG_SPEED_KBS, [globalLimiter.maxSpeed/1000]));
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


INITIALIZATION

ipToInt_cache:=THashedStringList.Create;
ipToInt_cache.Sorted:=TRUE;
ipToInt_cache.Duplicates:=dupIgnore;

FINALIZATION
freeAndNIL(ipToInt_cache);

end.
