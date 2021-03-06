{
Copyright (C) 2002-2020  Massimo Melina (www.rejetto.com)

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
unit srvClassesLib;
{$I NoRTTI.inc}

interface

uses
  iniFiles, types, strUtils, sysUtils, classes,
  system.Generics.Collections,
  OverbyteIcsWSocket, OverbyteIcshttpProt,
  hslib, srvConst;

type
  Tip2av = Tdictionary<string,Tdatetime>;
  TantiDos = class
    const MAX_CONCURRENTS = 3;
  class var
    folderConcurrents: integer;
    ip2availability: Tip2av;
    class constructor Create;
  protected
    accepted: boolean;
    Paddress: string;
  public
    constructor create;
    destructor Destroy; override;
    function accept(conn:ThttpConn; address:string=''):boolean;
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
    function idxOf(const data: string):integer;
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

  Tint2int = Tdictionary<integer,integer>;
  Tstr2str = Tdictionary<string,string>;
  Tstr2pointer = Tdictionary<string,pointer>;

  TstringToIntHash = class(ThashedStringList)
    constructor create;
    function getInt(const s:string):integer;
    function getIntByIdx(idx:integer):integer;
    function incInt(const s:string):integer;
    procedure setInt(const s:string; int:integer);
    end;

  PtplSection = ^TtplSection;
  TtplSection = record
    name, txt: string;
    nolog, public, noList, cache: boolean;
    ts: Tdatetime;
    end;

  Tstr2section = Tdictionary<string,PtplSection>;

  Ttpl = class
  protected
//    src: RawByteString;
    srcU: String;
//    lastExt,   // cache for getTxtByExt()
//    last: record section:string; idx:integer; end; // cache for getIdx()
    fileExts: TStringDynArray;
    strTable: THashedStringList;
//    fUTF8: boolean;
    fOver: Ttpl;
    sections: Tstr2section;
    function  getTxt(section:string):string;
    function  newSection(section:string):PtplSection;
    procedure fromString(const txt: String);
    function  toS: String;
    procedure fromRaw(const txt: RawByteString);
    function  toRaw: RawByteString;
    procedure setOver(v:Ttpl);
    procedure clear();
  public
    onChange: TNotifyEvent;
    constructor create(const txt: RawByteString=''; over:Ttpl=NIL); OverLoad;
    constructor create(const txt: String; over:Ttpl=NIL); OverLoad;
    destructor Destroy; override;
    property txt[section:string]:string read getTxt; default;
    property fullText: RawByteString read toRaw write fromRaw;
    property fullTextS: String read toS write fromString;
//    property utf8:boolean read fUTF8;
    property over:Ttpl read fOver write setOver;
    function sectionExist(section:string):boolean;
    function getTxtByExt(fileExt:string):string;
    function getSection(section:string; inherit:boolean=TRUE):PtplSection;
    function getSections():TStringDynArray;
    procedure appendString(txt: String);
    function getStrByID(const id:string):string;
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

  Ttlv = class
  protected
    cur, bound: integer;
    whole: RawByteString;
    lastValue: RawByteString;
    stack: array of integer;
    stackTop: integer;
  public
    procedure parse(const data: RawByteString);
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

  TSessionId = String;
  Tsession = class
    vars: THashedStringList;
    ttl: Double;
    created, expires: Tdatetime;
    user, ip, redirect: String;
    procedure setVar(k, v:string);
    function getVar(k: String):string;
    class function sanitizeSID(s:TSessionId):TSessionId;
    class function getNewSID(): TSessionId;
  public
    id: TSessionId;
    constructor create(const sid: TSessionId='');
    destructor Destroy; override;
    procedure init;
    procedure keepAlive();
    procedure setTTL(t:Tdatetime);
    property v[k: TSessionId]: String read getVar write setVar; default;
   end;

  Tsessions = class
   fS: TDictionary<TSessionId,Tsession>;
  public
    constructor create;
    destructor Destroy; override;
    procedure clearSession(sId: TSessionId);
    procedure destroySession(sId: TSessionId);
    function  createSession(sId: TSessionId = ''): Tsession;
    function  initNewSession(peerIp: String = ''; sid: TSessionId = ''): TSessionId;
    function  getSession(sId: TSessionId): Tsession; OverLoad;
    function  noSession(sId: TSessionId): Boolean;
    procedure keepAlive(sId: TSessionId);
    procedure checkExpired;
    property  ss[sId: TSessionId]: Tsession read getSession; default;
  end;


  ThashFunc = function(s:string):string;

  TconnDataMain = class   // data associated to a client connection
  public
    class function getSafeHost(cd:TconnDataMain):string;
  public
    address: string;   // this is address shown in the log, and it is not necessarily the same as the socket address
    time: Tdatetime;  // connection start time
    requestTime: Tdatetime; // last request start time
    { cache User-Agent because often retrieved by connBox.
    { this value is filled after the http request is complete (HE_REQUESTED),
    { or before, during the request as we get a file (HE_POST_FILE). }
    agent: string;
    conn: ThttpConn;
    limiter: TspeedLimiter;
    acceptedCredentials: boolean;
    usr, pwd: string;
    account: Paccount;
    sessionID: TsessionId;
    vars, // defined by {.set.}
    urlvars,  // as $_GET in php
    postVars  // as $_POST in php
      : THashedStringList;
    tpl: Ttpl;
    tplCounters: TstringToIntHash;
    downloadingWhat: TdownloadingWhat;
    disconnectReason: string;
    uploadFailed: string; // reason (empty on success)
    lastActivityTime: Tdatetime;
    function goodPassword(const pwd: String; s:string; func:ThashFunc):boolean;
    function passwordValidation(const pwd: String):boolean;
    procedure setSessionVar(k, v: String);
    procedure logout();
    function allowRecur: Boolean;
    function getFilesSelection(): TStringDynArray;

  end;

implementation

uses
  windows, dateUtils, forms, ansiStrings,
  RDFileUtil, RDUtils,
//  utilLib, hfsGlobal, hfsVars,
  srvUtils, srvVars;


class constructor TantiDos.Create;
begin
  ip2availability := NIL;
  folderConcurrents := 0;
end;

constructor TantiDos.create();
begin
accepted:=FALSE;
end;

function TantiDos.accept(conn:ThttpConn; address:string=''):boolean;

  procedure reject();
  resourcestring
    MSG_ANTIDOS_REPLY = 'Please wait, server busy';
  begin
  conn.reply.mode:=HRM_OVERLOAD;
  conn.addHeader(ansistring('Refresh: '+intToStr(1+random(2)))); // random for less collisions
  conn.reply.body:=UTF8Encode(MSG_ANTIDOS_REPLY);
  end;

begin
if address= '' then
  address:=conn.address;
if ip2availability = NIL then
  ip2availability:=Tip2av.create();
try
  if ip2availability.ContainsKey(address) then
   if ip2availability[address] > now() then // this specific address has to wait?
    begin
    reject();
    exit(FALSE);
    end;
except
  end;
if folderConcurrents >= MAX_CONCURRENTS then   // max number of concurrent folder loading, others are postponed
  begin
  reject();
  exit(FALSE);
  end;
inc(folderConcurrents);
Paddress:=address;
ip2availability.AddOrSetValue(address, now()+1/HOURS);
accepted:=TRUE;
Result:=TRUE;
end;

destructor TantiDos.Destroy;
var
  pair: Tpair<string,Tdatetime>;
  t: Tdatetime;
begin
if not accepted then
  exit;
t:=now();
if folderConcurrents = MAX_CONCURRENTS then // serving multiple addresses at max capacity, let's give a grace period for others
  ip2availability[Paddress]:=t + 1/SECONDS
else
  ip2availability.Remove(Paddress);
dec(folderConcurrents);
// purge leftovers
 for pair in ip2availability do
  if pair.Value < t then
    ip2availability.Remove(pair.Key);
end;

//////////// TcachedTpls

destructor TcachedTpls.Destroy;
var
  i: integer;
begin
for i:=0 to count-1 do
  objects[i].free;
end;

function TcachedTpls.getTplFor(fn: String): Ttpl;
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

function TiconsCache.idxOf(const data: string):integer;
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

function TiconsCache.get(data: String): PcachedIcon;
var
  i: integer;
begin
result:=NIL;
i:=idxOf(data);
if (i >= 0) and (i < n) and (icons[i].data = data) then
  result:=@icons[i];
end; // get

procedure TiconsCache.put(data: String; idx: Integer; time: Tdatetime);
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
      add(path+lowercase(f)+'='+UnUTF(h));
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

function TstringToIntHash.getInt(const s:string):integer;
begin result:=getIntByIdx(indexOf(s)) end;

procedure TstringToIntHash.setInt(const s:string; int:integer);
begin
beginUpdate();
objects[add(s)]:=Tobject(int);
endUpdate();
end; // setInt

function TstringToIntHash.incInt(const s:string):integer;
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

constructor Ttpl.create(const txt: RawByteString=''; over:Ttpl=NIL);
begin
sections:=Tstr2section.Create();
fullText:=txt;
self.over:=over;
end;

constructor Ttpl.create(const txt: String; over:Ttpl=NIL);
begin
sections:=Tstr2section.Create();
fullTextS:=txt;
self.over:=over;
end;

destructor Ttpl.destroy;
begin
fullText:=''; // this will cause the disposing
inherited;
end; // destroy

function Ttpl.getStrByID(const id:string):string;
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

function Ttpl.newSection(section:string):PtplSection;
begin
new(result);
sections.Add(section, result);
result.name:=section;
end; // newSection

function Ttpl.sectionExist(section:string):boolean;
begin
result:=assigned(getSection(section));
if not result and assigned(over) then
  result:=over.sectionExist(section);
end;

function Ttpl.getSection(section:string; inherit:boolean=TRUE):PtplSection;
begin
  result:=NIL;
  if sections.containsKey(section) then
   if not sections.TryGetValue(section, result) then
     result:=NIL;
if inherit and assigned(over) and (result = NIL) then
  result:=over.getSection(section);
end; // getSection

function Ttpl.getTxt(section:string):string;
var
  p: PTplSection;
begin
  p := getSection(section);
if p <> NIL then
  result:=p.txt
else
  result:=''
end; // getTxt

function Ttpl.getTxtByExt(fileExt:string):string;
begin result:=getTxt('file'+fileExt) end;

procedure Ttpl.clear();
begin
  srcU := '';
  for var p in sections.values do
    dispose(p);
  sections.clear();
  freeAndNIL(strTable);  // mod by mars
end;

procedure Ttpl.fromRaw(const txt: RawByteString);
var
  s: String;
begin
  clear;
  s := unUTF(txt);
  appendString(s);
end; // fromString

procedure Ttpl.fromString(const txt: String);
begin
  clear;

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
    base: TtplSection;

    function parseFlagsAndAcceptSection(flags:TStringDynArray):boolean;
    var
      f, k, v, s: string;
      i: integer;
    begin
    for f in flags do
      begin
      i:=pos('=',f);
      if i = 0 then
        begin
        if f='no log' then
          base.nolog:=TRUE
        else if f='public' then
          base.public:=TRUE
        else if f='no list' then
          base.noList:=TRUE
        else if f='cache' then
          base.cache:=TRUE;
        Continue;
        end;
      k:=copy(f,1,i-1);
      v:=copy(f,i+1,MAXINT);
      if k = 'build' then
        begin
        s:=chop('-',v);
        if (v > '') and (VERSION_BUILD > v) // max
        or (s > '') and (VERSION_BUILD < s) then // min
          exit(FALSE);
        end
      else if k = 'ver' then
        if fileMatch(v, VERSION) then continue
        else exit(FALSE)
      else if k = 'template' then
        if fileMatch(v, getTill(#13,getTxt('template id'))) then continue
        else exit(FALSE)
      end;
    result:=TRUE;
    end;

  var
    ss: TStringDynArray;
    s: string;
    till: pchar;
    append, prepend, add: boolean;
    sect, from: PtplSection;
  begin
  till:=pred(bos);
  if till = NIL then
    till:=pred(strEnd(ptxt));
  if till^ = #10 then dec(till);
  if till^ = #13 then dec(till);

  base:=default(TtplSection);
  base.txt:=getStr(ptxt, till);
  base.ts:=now();
  ss:=split('|',cur_section);
  cur_section:=popString(ss);
  if not parseFlagsAndAcceptSection(ss) then
    exit;

  prepend:=startsStr('^', cur_section);
  append:=ansiStartsStr('+', cur_section);
  add:=prepend or append;
  if add then
    delete(cur_section,1,1);

  // there may be several section names separated by =
  ss:=split('=', cur_section);
  // handle the main section specific case
  if ss = NIL then
    addString('', ss);
  // assign to every name the same txt
  for var si in ss do
    begin
    s:=trim(si);
    sect:=getSection(s, FALSE);
    from:=NIL;
    if sect = NIL then // not found
      begin
      if add then
        from:=getSection(s);
      sect:=newSection(s);
      end
    else
      if add then
        from:=sect;
    if from<>NIL then
      begin // inherit from it
      if append then
        sect.txt:=from.txt+base.txt
      else
        sect.txt:=base.txt+CRLF+from.txt;
      sect.nolog:=from.nolog or base.nolog;
      sect.public:=from.public or base.public;
      sect.noList:=from.noList or base.noList;
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
if assigned(onChange) then
  onChange(self);
end; // appendString

procedure Ttpl.setOver(v: Ttpl);
begin
fOver:=v;
end; // setOver

function Ttpl.getSections():TStringDynArray;
begin result:=sections.Keys.ToArray() end;

function Ttpl.me():Ttpl;
begin result:=self end;



procedure Ttlv.parse(const data: RawByteString);
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
  exit(FALSE);
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

function TconnDataMain.goodPassword(const pwd: String; s:string; func:ThashFunc):boolean;
var
  a: String;
begin
  s := postVars.values[s];
  Result := s > '';
  if Result then
   begin
    a := func(func(pwd)+ sessionId);
    result:= s = a
   end;
end;

function TconnDataMain.passwordValidation(const pwd: String):boolean;
begin
  Result := (postVars.values['password'] = pwd)
         or goodPassword(pwd, 'passwordSHA256', strSHA256)
         or goodPassword(pwd, 'passwordMD5', strMD5)
end;

function TconnDataMain.allowRecur: Boolean;
begin
  Result := (urlvars.indexOf('recursive') >= 0) or (urlvars.values['search'] > '');
end;

procedure TconnDataMain.setSessionVar(k, v: String);
var
  s: TSession;
begin
  s := sessions.getSession(sessionId);
  s.v[k] := v;
end;

function TconnDataMain.getFilesSelection(): TStringDynArray;
begin
  result:=NIL;
  for var i: integer :=0 to postvars.count-1 do
    if sameText('selection', postvars.names[i]) then
      addString(getTill('#', postvars.valueFromIndex[i]), result) // omit #anchors
end; // getFilesSelection

procedure TconnDataMain.logout();
begin
  sessions.destroySession(sessionID);
  usr:='';
  pwd:='';
  account := NIL;
  conn.delCookie(SESSION_COOKIE);
end; // logout

class function TconnDataMain.getSafeHost(cd:TconnDataMain):string;
begin
result:='';
if cd = NIL then exit;
if addressmatch(forwardedMask, cd.conn.address) then
  result:=cd.conn.getHeader('x-forwarded-host');
if result = '' then
  result:=cd.conn.getHeader('host');
result:=stripChars(result, ['0'..'9','a'..'z','A'..'Z',':','.','-','_'], TRUE);
end; // getSafeHost

class function Tsession.getNewSID():TSessionId;
begin result:=sanitizeSID(b64U(str_(now())+str_(random()))) end;

class function Tsession.sanitizeSID(s:TSessionId):TSessionId;
//begin result:=reReplace(s, '[\D\W]', '', '!') end;
begin result:=reReplace(s, '[^0-9a-zA-Z]', '', '!') end;

constructor Tsession.create(const sid:string='');
begin
id:=sid;
if Length(id) < 10 then
  id:=getNewSID();
//sessions.Add(id, self);
init;
end;

procedure Tsession.init;
begin
created:=now();
ttl:=1; // days
user := '';
ip := '';
redirect := '';
keepAlive();
end;

destructor Tsession.Destroy;
var
  cd: TconnDataMain;
begin
for var o in srv.conns do
  begin
  cd:=ThttpConn(o).data;
  if cd.sessionID = self.id then
    cd.sessionID := '';
  end;
//sessions.remove(id);
freeAndNIL(vars);
end;

procedure Tsession.keepAlive();
begin expires:=now() + ttl end;

function Tsession.getVar(k:string):string;
begin
  Result := '';
  if vars = NIL then
    Exit
   else
     if vars.IndexOfName(k) >= 0 then
try result:=vars.values[k];
except result:=''
  end;
end; // sessionGet

procedure Tsession.setVar(k, v:string);
begin
if vars= NIL then
  vars:=THashedStringList.create;
vars.addPair(k,v);
end;

procedure Tsession.setTTL(t:Tdatetime);
begin
ttl:=t;
keepAlive();
end;

constructor Tsessions.create;
begin
  fS := Tdictionary<TSessionId,Tsession>.Create();
end;

destructor Tsessions.Destroy;
begin
  FreeAndNil(fS);
end;

function Tsessions.getSession(sId: TSessionId): Tsession;
begin
  if not fS.TryGetValue(sId, Result) then
    Result := NIL;
end;

function Tsessions.createSession(sId: TSessionId = ''): Tsession;
begin
  result := Tsession.create(sid);
  fS.Add(result.id, result);
end;

function Tsessions.initNewSession(peerIp: String = ''; sid: TSessionId = ''): TSessionId;
var
  s: Tsession;
begin
  s := getSession(sid);
  if s = NIL then
    s := createSession(sid);
  s.init;
  Result := s.id;
  s.ip := peerIp;
end;

procedure Tsessions.clearSession(sId: TSessionId);
begin
  fS.Remove(sId);
end;

procedure Tsessions.destroySession(sId: TSessionId);
var
  s: Tsession;
begin
  s := getSession(sId);
  if Assigned(s) then
    begin
      fS.Remove(sId);
      s.free;
    end;
end;

function Tsessions.noSession(sId: TSessionId): Boolean;
var
  s: TSession;
begin
  Result := (sID = '') or not fS.ContainsKey(sId);
  if not Result then
   // Check if session was expired
    begin
      s := fS.Items[sId];
      Result := s.expires < now;
    end;
end;

procedure Tsessions.keepAlive(sId: TSessionId);
var
  s: Tsession;
begin
  s := ss[sId];
  if Assigned(s) then
    s.keepAlive;
end;

procedure Tsessions.checkExpired;
var
  now_: TDateTime;
  sId: TSessionId;
begin
  now_ := now();
  for var sess in self.fS.Values do
   if now_ > sess.expires then
   begin
    sId := sess.id;
    sess.free;
    self.fS.Items[sId] := NIL;
    self.fS.Remove(sId);
   end;
end;



end.
