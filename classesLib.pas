{
Copyright (C) 2002-2012  Massimo Melina (www.rejetto.com)

This file is part of HFS ~ HTTP File Server.

    HFS is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HFS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with HFS; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
{$INCLUDE defs.inc }
unit classesLib;

interface

uses
  iniFiles, types, hslib, strUtils, sysUtils, classes, math;

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

  PcachedIcon = ^TcachedIcon;
  TcachedIcon = record
    data: string;
    idx: integer;
    time: Tdatetime;
    end;

  TiconsCache = class
    n: integer;
    icons: array of TcachedIcon;
    function get(data:string):PcachedIcon;
    procedure put(data:string; idx:integer; time:Tdatetime);
    procedure clear();
    procedure purge(olderThan:Tdatetime);
    function idxOf(data:shortstring):integer;
    end;

  TusersInVFS = class
  protected
    users: TstringDynArray;
    pwds: array of TstringDynArray;
  public
    procedure reset();
    procedure track(usr, pwd:string); overload;
    procedure drop(usr, pwd:string); overload;
    function match(usr, pwd:string):boolean; overload;
    function empty():boolean;
    end;

  Thasher = class(TstringList)
    procedure loadFrom(path:string);
    function getHashFor(fn:string):string;
    end;

  TstringToIntHash = class(ThashedStringList)
    constructor create;
    function getInt(s:string):integer;
    function getIntByIdx(idx:integer):integer;
    function incInt(s:string):integer;
    procedure setInt(s:string; int:integer);
    end;

  PtplSection = ^TtplSection;
  TtplSection = record
    name, txt: string;
    nolog, nourl: boolean;
    end;

  Ttpl = class
  protected
//    src: RawByteString;
    srcU: String;
    lastExt,   // cache for getTxtByExt()
    last: record section:string; idx:integer; end; // cache for getIdx()
    fileExts: TStringDynArray;
    strTable: THashedStringList;
    fUTF8: boolean;
    fOver: Ttpl;
    function  getIdx(section:string):integer;
    function  getTxt(section:string):string;
    function  newSection(section:string):PtplSection;
    procedure fromString(txt: String);
    function  toS: String;
    procedure fromRaw(txt: RawByteString);
    function  toRaw: RawByteString;
    procedure setOver(v:Ttpl);
    procedure updateUTF8();
  public
    onChange: TNotifyEvent;
    sections: array of TtplSection;
    constructor create(txt: RawByteString=''; over:Ttpl=NIL);
    destructor Destroy; override;
    property txt[section:string]:string read getTxt; default;
    property fullText: RawByteString read toRaw write fromRaw;
    property fullTextS: String read toS write fromString;
    property utf8:boolean read fUTF8;
    property over:Ttpl read fOver write setOver;
    function sectionExist(section:string):boolean;
    function getTxtByExt(fileExt:string):string;
    function getSection(section:string):PtplSection;
    function getSections():TStringDynArray;
    procedure appendString(txt: String);
    function getStrByID(id:string):string;
    function me():Ttpl;
    end; // Ttpl

  TcachedTplObj = class
    ts: Tdatetime;
    tpl: Ttpl;
    end;

  TcachedTpls = class(THashedStringList)
  public
    function getTplFor(fn:string):Ttpl;
    destructor Destroy; override;
    end; // TcachedTpls

  TperIp = class // for every different address, we have an object of this class. These objects are never freed until hfs is closed.
  public
    limiter: TspeedLimiter;
    customizedLimiter: boolean;
    constructor create();
    destructor Destroy; override;
    end;

  Ttlv = class
  protected
    cur, bound: integer;
    whole: RawByteString;
    lastValue: RawByteString;
    stack: array of integer;
    stackTop: integer;
  public
    procedure parse(data: RawByteString);
//    function pop(var value:string): integer; OverLoad
    function pop(var value: RawByteString): integer;
    function down():boolean;
    function up():boolean;
    function getTotal():integer;
    function getCursor():integer;
    function getPerc():real;
    function isOver():boolean;
    function getTheRest():RawByteString;
    end;

implementation

uses
  RDFileUtil, RDUtils,
  ansiStrings, utilLib, main, windows, dateUtils, forms;

constructor TperIp.create();
begin
limiter:=TspeedLimiter.create();
srv.limiters.add(limiter);
end;

destructor TperIp.Destroy;
begin
srv.limiters.remove(limiter);
limiter.free;
end;

//////////// TcachedTpls

destructor TcachedTpls.Destroy;
var
  i: integer;
begin
for i:=0 to count-1 do
  objects[i].free;
end;

function TcachedTpls.getTplFor(fn: string):Ttpl;
var
  i: integer;
  o: TcachedTplObj;
  s: RawByteString;
begin
  fn := trim(lowercase(fn));
  i := indexOf(fn);
  if i >= 0 then
    o := objects[i] as TcachedTplObj
   else
    begin
      o:=TcachedTplObj.create();
      if addObject(fn, o) > 100 then
        delete(0);
    end;
  result := o.tpl;
  if getMtime(fn) = o.ts then
    exit;
  o.ts := getMtime(fn);
  s := loadFile(fn);
  if o.tpl = NIL then
    begin
    result := Ttpl.create();
    o.tpl := result;
    end;
  o.tpl.fromRaw(s);
end; // getTplFor

//////////// TusersInVFS

function TusersInVFS.empty():boolean;
begin result:= users = NIL end;

procedure TusersInVFS.reset();
begin
users:=NIL;
pwds:=NIL;
end; // reset

procedure TusersInVFS.track(usr, pwd: string);
var
  i: integer;
begin
if usr = '' then exit;
i:=idxOf(usr, users);
if i < 0 then i:=addString(usr, users);
if i >= length(pwds) then setLength(pwds, i+1);
addString(pwd, pwds[i]);
end; // track

procedure TusersInVFS.drop(usr, pwd: string);
var
  i, j: integer;
begin
i:=idxOf(usr, users);
if i < 0 then exit;
j:=AnsiIndexStr(pwd, pwds[i]);
if j < 0 then exit;
removeString(pwds[i], j);
if assigned(pwds[i]) then exit;
// this username does not exist with any password
removeString(users, i);
while i+1 < length(pwds) do
  begin
  pwds[i]:=pwds[i+1];
  inc(i);
  end;
setLength(pwds, i);
end; // drop

function TusersInVFS.match(usr, pwd:string):boolean;
var
  i: integer;
begin
result:=FALSE;
i:=idxOf(usr, users);
if i < 0 then exit;
result:= 0 <= AnsiIndexStr(pwd, pwds[i]);
end; // match

//////////// TiconsCache

function TiconsCache.idxOf(data:shortstring):integer;
var
  b, e, c: integer;
begin
result:=0;
if n = 0 then exit;
// binary search
b:=0;
e:=n-1;
  repeat
  result:=(b+e) div 2;
  c:=compareStr(data, icons[result].data);
  if c = 0 then exit;
  if c < 0 then e:=result-1;
  if c > 0 then b:=result+1;
  until b > e;
result:=b;
end; // idxOf

function TiconsCache.get(data: String):PcachedIcon;
var
  i: integer;
begin
result:=NIL;
i:=idxOf(data);
if (i >= 0) and (i < n) and (icons[i].data = data) then
  result:=@icons[i];
end; // get

procedure TiconsCache.put(data: string; idx:integer; time:Tdatetime);
var
  i, w: integer;
begin
  if length(icons) <= n then
    setlength(icons, n+50);
  w := idxOf(data);
  for i:=n downto w+1 do
    icons[i]:=icons[i-1]; // shift
  icons[w].data:=data;
  icons[w].idx:=idx;
  icons[w].time:=time;
  inc(n);
end; // put

procedure TiconsCache.clear();
begin
icons:=NIL;
n:=0;
end; // clear

procedure TiconsCache.purge(olderThan:Tdatetime);
var
  i, m: integer;
begin
exit;
m:=0;
for i:=0 to n-1 do
  if icons[i].time < olderThan then dec(n) // this does not shorten the loop
  else
    begin
    if m < i then icons[m]:=icons[i];
    inc(m);
    end;
end; // purge

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

//////////// Thasher

procedure Thasher.loadFrom(path:string);
var
  sr: TsearchRec;
  sA, l, h: RawByteString;
  f: String;
begin
  if path='' then
    exit;
  path := includeTrailingPathDelimiter(lowercase(path));
  if findFirst(path+'*.md5', faAnyFile-faDirectory, sr) <> 0 then exit;
  repeat
   sA := loadfile(path+sr.name);
  while sA > '' do
    begin
      l := chopline(sA);
      h:=trim(chop(RawByteString('*'),l));
      if h = '' then break;
      if l = '' then
        // assume it is referring to the filename without the extention
        f := copy(sr.name, 1, length(sr.name)-4)
       else
        f := UnUTF(l);
      add(path+lowercase(f)+'='+h);
    end;
  until findnext(sr) <> 0;
sysutils.findClose(sr);
end; // loadFrom

function Thasher.getHashFor(fn:string):string;
begin
try result:=values[lowercase(fn)]
except result:='' end
end;

//////////// TstringToIntHash

constructor TstringToIntHash.create;
begin
inherited create;
sorted:=TRUE;
duplicates:=dupIgnore;
end; // create

function TstringToIntHash.getIntByIdx(idx:integer):integer;
begin if idx < 0 then result:=0 else result:=integer(objects[idx]) end;

function TstringToIntHash.getInt(s:string):integer;
begin result:=getIntByIdx(indexOf(s)) end;

procedure TstringToIntHash.setInt(s:string; int:integer);
begin
beginUpdate();
objects[add(s)]:=Tobject(int);
endUpdate();
end; // setInt

function TstringToIntHash.incInt(s:string):integer;
var
  i: integer;
begin
beginUpdate();
i:=add(s);
result:=integer(objects[i]);
inc(result);
objects[i]:=Tobject(result);
endUpdate();
end; // autoupdatedFiles_getCounter

//////////// Ttpl

constructor Ttpl.create(txt: RawByteString=''; over:Ttpl=NIL);
begin
fullText:=txt;
self.over:=over;
end;

destructor Ttpl.destroy;
begin
freeAndNIL(strTable);
inherited;
end; // destroy

function Ttpl.getStrByID(id:string):string;
begin
if strTable = NIL then
  begin
  strTable:=THashedStringList.create;
  strTable.text:=txt['special:strings'];
  end;
result:=strTable.values[id];
if (result = '') and assigned(over) then
  result:=over.getStrByID(id)
end; // getStrByID

function Ttpl.getIdx(section:string):integer;
begin
if section <> last.section then
  begin
  last.section:=section;
  for result:=0 to length(sections)-1 do
    if sameText(sections[result].name, section) then
      begin
      last.idx:=result;
      exit;
      end;
  last.idx:=-1;
  end;
result:=last.idx
end; // getIdx

function Ttpl.newSection(section:string):PtplSection;
var
  i: integer;
begin
// add
i:=length(sections);
setLength(sections, i+1);
result:=@sections[i];
result.name:=section;
// getIdx just filled 'last' with not-found, so we must update
last.section:=section;
last.idx:=i;
// manage file.EXT sections
if not ansiStartsText('file.', section) then exit;
i:=length(fileExts);
setLength(fileExts, i+2);
delete(section, 1, 4);
fileExts[i]:=section;
fileExts[i+1]:=str_(last.idx);
lastExt.section:=section;
lastExt.idx:=last.idx;
end; // newSection

function Ttpl.sectionExist(section:string):boolean;
begin
result:=getIdx(section)>=0;
if not result and assigned(over) then
  result:=over.sectionExist(section);
end;

function Ttpl.getSection(section:string):PtplSection;
var
  i: integer;
begin
result:=NIL;
i:=getIdx(section);
if i >= 0 then result:=@sections[i];
if assigned(over) and ((result = NIL) or (trim(result.txt) = '')) then
  result:=over.getSection(section);
end; // getSection

function Ttpl.getTxt(section:string):string;
var
  i: integer;
begin
i:=getIdx(section);
if i >= 0 then
  result:=sections[i].txt
else if assigned(over) then
  result:=over[section]
else
  result:=''
end; // getTxt

function Ttpl.getTxtByExt(fileExt:string):string;
var
  i: integer;
begin
result:='';
if (lastExt.section > '') and (fileExt = lastExt.section) then
  begin
  if lastExt.idx >= 0 then result:=sections[lastExt.idx].txt;
  exit;
  end;
i:=idxOf(fileExt, fileExts);
if (i < 0) and assigned(over) then
  begin
  result:=over.getTxtByExt(fileExt);
  if result > '' then exit;
  end;
lastExt.section:=fileExt;
lastExt.idx:=i;
if i < 0 then exit;
i:=int_(fileExts[i+1]);
lastExt.idx:=i;
result:=sections[i].txt;
end; // getTxtByExt

procedure Ttpl.fromRaw(txt: RawByteString);
var
  s: String;
begin
  srcU := '';
  sections := NIL;
  fileExts := NIL;
  last.section := #255'null'; // '' is a valid (and often used) section name. This is a better null value.
  freeAndNIL(strTable);  // mod by mars

  s := unUTF(txt);
  appendString(s);
end; // fromString

procedure Ttpl.fromString(txt: String);
begin
  srcU := '';
  sections := NIL;
  fileExts := NIL;
  last.section := #255'null'; // '' is a valid (and often used) section name. This is a better null value.
  freeAndNIL(strTable);  // mod by mars

  appendString(txt);
end; // fromString

function Ttpl.toRaw: RawByteString;
begin
  Result := utf8Encode(srcU);
end;

function Ttpl.toS: String;
begin
  Result := srcU;
end;

procedure Ttpl.appendString(txt: String);
var
  ptxt, bos: PChar;
  cur_section, next_section: string;

  function pred(p:pchar):pchar; inline;
  begin
  result:=p;
  if p <> NIL then
    dec(result);
  end;

  function succ(p:pchar):pchar; inline;
  begin
  result:=p;
  if p <> NIL then
    inc(result);
  end;

  procedure findNextSection();
  begin
  // find start
  bos:=ptxt;
    repeat
    if bos^ <> '[' then bos:= ansiStrPos(bos, #10'[');
    if bos = NIL then exit;
    if bos^ = #10 then inc(bos);
    if getSectionAt(bos, next_section) then
      exit;
    inc(bos);
    until false;
  end; // findNextSection

  procedure saveInSection();
  var
    ss: TStringDynArray;
    s: string;
    i, si: integer;
    base: TtplSection;
    till: pchar;
    append: boolean;
    sect, from: PtplSection;
  begin
  till:=pred(bos);
  if till = NIL then
    till:=pred(strEnd(ptxt));
  if till^ = #10 then dec(till);
  if till^ = #13 then dec(till);

  base.txt:=getStr(ptxt, till);
  // there may be flags after |
  s:=cur_section;
  cur_section:=chop('|', s);
  base.nolog:=ansiPos('no log', s) > 0;
  base.nourl:=ansiPos('private', s) > 0;
  // there may be several section names separated by =
  ss:=split('=', cur_section);
  // handle the main section specific case
  if ss = NIL then addString('', ss);
  // assign to every name the same txt
  for i:=0 to length(ss)-1 do
    begin
    s:=trim(ss[i]);
    append:=ansiStartsStr('+', s);
    if append then
      delete(s,1,1);
    si:=getIdx(s);
    from:=NIL;
    if si < 0 then // not found
      begin
      if append then
        from:=getSection(s);
      sect:=newSection(s);
      end
    else
      begin
      sect:=@sections[si];
      if append then
        from:=sect;
      end;
    if from<>NIL then
      begin // inherit from it
      sect.txt:=from.txt+base.txt;
      sect.nolog:=from.nolog or base.nolog;
      sect.nourl:=from.nourl or base.nourl;
      continue;
      end;
    sect^:=base;
    sect.name:=s; // restore this lost attribute
    end;
  end; // saveInSection

//const
//  BOM = RawByteString(#$EF#$BB#$BF);
var
  first: boolean;
begin
// this is used by some unicode files. at the moment we just ignore it.
//  if ansiStartsStr(BOM, txt) then
//    delete(txt, 1, length(BOM));

  if txt = '' then
    exit;
  srcU := srcU + txt;
  cur_section := '';
  ptxt := @txt[1];
first:=TRUE;
  repeat
  findNextSection();
  if not first or (trim(getStr(ptxt, pred(bos))) > '') then
    saveInSection();
  if bos = NIL then break;
  cur_section:=next_section;
  inc(bos, length(cur_section)); // get faster to the end of line
  ptxt:=succ(ansiStrPos(bos, #10)); // get to the end of line (and then beyond)
  first:=FALSE;
  until ptxt = NIL;
updateUTF8();
if assigned(onChange) then
  onChange(self);
end; // appendString

procedure Ttpl.setOver(v: Ttpl);
begin
fOver:=v;
updateUTF8();
end; // setOver

procedure Ttpl.updateUTF8();
begin
  fUTF8 := assigned(over) and over.utf8 or utf8test(fullText)
end;

function Ttpl.getSections():TStringDynArray;
var
  i: integer;
begin
i:=length(sections);
setLength(result, i);
for i:=0 to i-1 do
  result[i]:=sections[i].name;
end;

function Ttpl.me():Ttpl;
begin result:=self end;



procedure Ttlv.parse(data: RawByteString);
begin
  whole:=data;
  cur:=1;
  bound:=length(data);
  stackTop:=0;
end; // parse

function Ttlv.pop(var value: RawByteString):integer;
var
  n: integer;
begin
  result := -1;
  if isOver() then
    exit; // finished
  result:=integer((@whole[cur])^);
  n:=Pinteger(@whole[cur+4])^;
  value :=  copy(whole, cur+8, n);
  lastValue := value;
  inc(cur, 8+n);
end;

function Ttlv.down():boolean;
begin
// do we have anything to recur on?
if (cur = 1) then
  begin
  result:=false;
  exit;
  end;
// push into the stack
if (stackTop = length(stack)) then // space over
  setLength(stack, stackTop+10); // make space
stack[stackTop]:=cur;
inc(stackTop);
stack[stackTop]:=bound;
inc(stackTop);

bound:=cur;
dec(cur, length(lastValue));
result:=true;
end; // down

function Ttlv.up():boolean;
begin
if stackTop = 0 then
  begin
  result:=false;
  exit;
  end;
dec(stackTop);
bound:=stack[stackTop];
dec(stackTop);
cur:=stack[stackTop];
result:=true;
end; // up

function Ttlv.getTotal():integer;
begin result:=length(whole) end;

function Ttlv.getCursor():integer;
begin result:=cur end;

function Ttlv.getPerc():real;
begin
if length(whole) = 0 then result:=0
else result:=cur/length(whole)
end; // getPerc

function Ttlv.isOver():boolean;
begin result:=(cur+8 > bound) end;

function Ttlv.getTheRest(): RawByteString;
begin result:=substr(whole, cur, bound) end;

end.
