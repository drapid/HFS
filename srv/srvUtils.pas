unit srvUtils;
{$I NoRTTI.inc}

interface
uses
  graphics, Types, SysUtils,
  srvConst;

  function xtpl(src:string; table:array of string):string; OverLoad;
  function xtpl(src: RawByteString; table:array of RawByteString): RawByteString; OverLoad;
  function escapeNL(s:string):string;
  function unescapeNL(s:string):string;
  function htmlEncode(const s:string):string;
  function substr(const s: RawByteString; start:integer; upTo:integer=0): RawByteString; inline; OverLoad;
  function substr(const s:string; start:integer; upTo:integer=0):string; inline; overload;
  function substr(const s:string; const after:string):string; overload;
  function replace(var s:string; const ss:string; start,upTo:integer):integer;
  function strAt(const s, ss:string; at:integer):boolean; inline;
  procedure enforceNUL(var s: string); OverLoad;
  procedure enforceNUL(var s: RawbyteString); OverLoad;
  function dequote(const s:string; quoteChars:TcharSetW=['"']):string;
//  function reCache(exp:string; mods:string='m'):TregExpr;
  function reMatch(const s, exp:string; mods:string='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
  function reReplace(subj, exp, repl:string; mods:string='m'):string;
  function if_(v:boolean; const v1:string; const v2:string=''):string; overload; inline;
  function if_(v: Boolean; const v1: RawByteString; const v2: RawByteString = ''): RawByteString;overload; inline;
  function if_(v:boolean; v1:int64; v2:int64=0):int64; overload; inline;
  function if_(v:boolean; v1:integer; v2:integer=0):integer; overload; inline;
  function if_(v:boolean; v1:Tobject; v2:Tobject=NIL):Tobject; overload; inline;
  function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean; overload; inline;
  function isExtension(const filename, ext: String): Boolean;
  function stringExists(s:string; a:array of string; isSorted:boolean=FALSE):boolean;
  function removeString(var a:TStringDynArray; idx:integer; l:integer=1):boolean; overload;
  function removeString(s:string; var a:TStringDynArray; onlyOnce:boolean=TRUE; ci:boolean=TRUE; keepOrder:boolean=TRUE):boolean; overload;
  procedure removeStrings(find:string; var a:TStringDynArray);
  procedure toggleString(s:string; var ss:TStringDynArray);
  function onlyString(const s: String; ss: TStringDynArray): boolean;
  function addArray(var dst:TstringDynArray; src:array of string; where:integer=-1; srcOfs:integer=0; srcLn:integer=-1):integer;
  function removeArray(var src:TstringDynArray; toRemove:array of string):integer;

  function toSA(a:array of string):TstringDynArray; // this is just to have a way to typecast
  function addUniqueString(const s: String; var ss: TStringDynArray): boolean;
  function addString(const s: String; var ss: TStringDynArray): integer;
  function replaceString(var ss:TStringDynArray; old, new:string):integer;
  function popString(var ss:TstringDynArray):string;
  procedure insertString(const s: String; idx: integer; var ss: TStringDynArray);
  function addUniqueArray(var a:TstringDynArray; b:array of string):integer;
  procedure uniqueStrings(var a:TstringDynArray; ci:Boolean=TRUE);
  function idxOf(s:string; a:array of string; isSorted:boolean=FALSE):integer;

  function poss(chars:TcharSetW; s:string; ofs:integer=1):integer;
  function strToCharset(const s:string): TcharsetW;
  function anycharIn(const chars, s:string):boolean; overload;
  function anycharIn(chars:TcharsetW; const s:string):boolean; overload;
  function findEOL(const s:string; ofs:integer=1; included:boolean=TRUE):integer;
  function quoteIfAnyChar(const badChars: String; s:string; const quote:string='"'; const unquote:string='"'):string;

type
  TfastStringAppend = class
  protected
    buff: string;
    n: integer;
  public
    function length():integer;
    function reset():string;
    function get():string;
    function append(s:string):integer;
    end;


implementation
uses
  math, strutils, RegExpr, iniFiles,
  ansistrings;

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

function TfastStringAppend.append(s:string):integer;
var
  ls, lb: integer;
begin
  ls := system.length(s);
  lb := system.length(buff);
  if n+ls > lb then
    setlength(buff, lb+ls+20000);
  MoveChars(s[1], buff[n+1], ls);
  inc(n, ls);
  result:=n;
end; // append


function xtpl(src:string; table:array of string):string;
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

function escapeNL(s:string):string;
begin
  s:=replaceStr(s, '\','\\');
  case newlineType(s) of
    NL_D: s:=replaceStr(s, #13,'\n');
    NL_A: s:=replaceStr(s, #10,'\n');
    NL_DA: s:=replaceStr(s, #13#10,'\n');
    NL_MIXED: s:=replaceStr(replaceStr(replaceStr(s, #13#10,'\n'), #13,'\n'), #10,'\n'); // bad case, we do our best
    end;
  result:=s;
end; // escapeNL

function unescapeNL(s:string):string;
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

function replace(var s:string; const ss:string; start,upTo:integer):integer;
var
  common, oldL, surplus: integer;
begin
  oldL := upTo-start+1;
  common := min(length(ss), oldL);
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

function reReplace(subj, exp, repl:string; mods:string='m'):string;
var
  re: TRegExpr;
begin
re:=reCache(exp,mods);
result:=re.replace(subj, repl, TRUE);
end; // reReplace


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

function isExtension(const filename, ext: String):boolean;
begin
  result := 0=ansiCompareText(ext, extractFileExt(filename))
end;

function idxOf(s:string; a:array of string; isSorted:boolean=FALSE):integer;
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

function stringExists(s:string; a:array of string; isSorted:boolean=FALSE):boolean;
begin result:= idxOf(s,a, isSorted) >= 0 end;

procedure toggleString(s:string; var ss:TStringDynArray);
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

procedure uniqueStrings(var a:TstringDynArray; ci:Boolean=TRUE);
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
procedure removeStrings(find:string; var a:TStringDynArray);
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
result:=length(ss);
addArray(ss, [s], result)
end; // addString

function replaceString(var ss:TStringDynArray; old, new:string):integer;
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

function removeString(s:string; var a:TStringDynArray; onlyOnce:boolean=TRUE; ci:boolean=TRUE; keepOrder:boolean=TRUE):boolean; overload;
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

function toSA(a:array of string):TstringDynArray; // this is just to have a way to typecast
begin
result:=NIL;
addArray(result, a);
end; // toSA


end.
