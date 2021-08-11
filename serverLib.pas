unit serverLib;

interface

uses
  // delphi libs
  Windows, Messages, Graphics, Forms, math, Types, SysUtils, ComCtrls,
  HSLib, srvClassesLib, fileLib;

type

  TShowPrefs = set of (spUseSysIcons, spHttpsUrls, spFoldersBefore, spLinksBefore, spNoPortInUrl, spEncodeNonascii, spEncodeSpaces);

  TfileListing = class
    actualCount: integer;
   public
    dir: array of Tfile;
    timeout: TDateTime;
    ignoreConnFilter: boolean;
    constructor create();
    destructor Destroy; override;
    function fromFolder(loadPrefs: TLoadPrefs; folder:Tfile; cd:TconnDataMain; recursive:boolean=FALSE;
      limit:integer=-1; toSkip:integer=-1; doClear:boolean=TRUE):integer;
    procedure sort(foldersBefore, linksBefore: Boolean; cd:TconnDataMain; def:string='');
  end;

  TOnGetSP = function: TShowPrefs of object;

  TFileServer = class
    userPwdHashCache: Tstr2str;
    rootFile: Tfile;
//    fSP: TShowPrefs;
    fOnGetSP: TOnGetSP;
   public
    function  initRoot(pTree: TTreeView): TFile;
    function  encodeURLA(const s: string; fullEncode:boolean=FALSE): RawByteString;
    function  encodeURLW(const s: string; fullEncode:boolean=FALSE): String;
    function  pathTill(fl: Tfile; root: Tfile=NIL; delim: char='\'): String;
    function  url(f: Tfile; fullEncode: boolean=FALSE):string;
    function  parentURL(f: Tfile): string;
    function  fullURL(f: Tfile; const ip, user, pwd: String): String; OverLoad;
    function  fullURL(f: Tfile; ip: String=''): String; OverLoad;
    function  getAFolderPage(folder: Tfile; cd: TconnDataMain; otpl: TTpl;
                 const lp: TLoadPrefs; const sp: TShowPrefs;
                 isPwdInPages, isMacrosLog: Boolean): String;
    function  findFilebyURL(url:string; const lp: TLoadPrefs; parent:Tfile=NIL; allowTemp:boolean=TRUE): Tfile;
    function  protoColon(sp: TShowPrefs): String;
    property  onGetSP: TOnGetSP read fOnGetSP write fOnGetSP;
   end;

type
  TstringIntPairs = array of record
    str:string;
    int:integer;
   end;


var
  iconMasks: TstringIntPairs;

implementation

uses
  strutils, iniFiles, Classes,
  RegExpr,
  utilLib,
  scriptLib,
  RDUtils, RDFileUtil,
  srvConst, srvUtils, parserLib, srvVars;

constructor TfileListing.create();
begin
dir:=NIL;
end; // create

destructor TfileListing.destroy;
var
  i: integer;
begin
for i:=0 to length(dir)-1 do
  freeIfTemp(dir[i]);
inherited destroy;
end; // destroy

procedure TfileListing.sort(foldersBefore, linksBefore: Boolean; cd:TconnDataMain; def:string='');
var
  rev: boolean;
  sortBy: ( SB_NAME, SB_EXT, SB_SIZE, SB_TIME, SB_DL, SB_COMMENT );

  function compareExt(f1,f2:string):integer;
  begin result:=ansiCompareText(extractFileExt(f1), extractFileExt(f2)) end;

  function compareFiles(item1,item2:pointer):integer;
  var
    f1, f2:Tfile;
  begin
  f1:=item1;
  f2:=item2;
  if linksBefore and (f1.isLink() <> f2.isLink()) then
    begin
    if f1.isLink() then result:=-1
    else result:=+1;
    exit;
    end;
  if foldersBefore and (f1.isFolder() <> f2.isFolder()) then
    begin
    if f1.isFolder() then result:=-1
    else result:=+1;
    exit;
    end;
  result:=0;
  case sortby of
    SB_SIZE: result:=compare_(f1.size, f2.size);
    SB_TIME: result:=compare_(f1.mtime, f2.mtime);
    SB_DL: result:=compare_(f1.DLcount, f2.DLcount);
    SB_EXT:
      if not f1.isFolder() and not f2.isFolder() then
        result:=compareExt(f1.name, f2.name);
    SB_COMMENT: result:=ansiCompareText(f1.comment, f2.comment);
    end;
  if result = 0 then // this happen both for SB_NAME and when other comparisons result in no difference
    result:=ansiCompareText(f1.name,f2.name);
  if rev then result:=-result;
  end; // compareFiles

  procedure qsort(left, right:integer);
  var
    split, t: Tfile;
    i, j: integer;
  begin
  if left >= right then exit;

  if cd.conn.state = HCS_DISCONNECTED then exit;
//  application.ProcessMessages();
//  if cd.conn.state = HCS_DISCONNECTED then exit;

  i:=left;
  j:=right;
  split:=dir[(i+j) div 2];
    repeat
    while compareFiles(dir[i], split) < 0 do inc(i);
    while compareFiles(split, dir[j]) < 0 do dec(j);
    if i <= j then
      begin
      t:=dir[i];
      dir[i]:=dir[j];
      dir[j]:=t;

      inc(i);
      dec(j);
      end
    until i > j;
  if left < j then qsort(left, j);
  if i < right then qsort(i, right);
  end; // qsort

  procedure check1(var flag:boolean; val:string);
  begin if val > '' then flag:=val='1' end;

var
  v: string;
begin
// caching
//foldersBefore:=mainfrm.foldersBeforeChk.checked;
//linksBefore:=mainfrm.linksBeforeChk.checked;

v:=first([def, defSorting, 'name']);
rev:=FALSE;
if assigned(cd) then
  with cd.urlvars do
    begin
    v:=first(values['sort'], v);
    rev:=values['rev'] = '1';

    check1(foldersBefore, values['foldersbefore']);
    check1(linksBefore, values['linksbefore']);
    end;
if ansiStartsStr('!', v) then
  begin
  delete(v, 1,1);
  rev:=not rev;
  end;
if v = '' then exit;
case v[1] of
  'n': sortBy:=SB_NAME;
  'e': sortBy:=SB_EXT;
  's': sortBy:=SB_SIZE;
  't': sortBy:=SB_TIME;
  'd': sortBy:=SB_DL;
  'c': sortBy:=SB_COMMENT;
  else exit; // unsupported value
  end;
qsort( 0, length(dir)-1 );
end; // sort

function loadDescriptionFile(const lp: TLoadPrefs; const fn:string):string;
var
  sa: RawByteString;
begin
  result := '';
  sa := loadFile(fn);
  if sa = '' then
    sa := loadFile(fn+'\descript.ion');
  if (sa > '') and (lpOEMForION in lp) then
    Result := sa
   else
    Result := UnUTF(sa);
end; // loadDescriptionFile

function escapeIon(const s:string):string;
begin
// this escaping method (and also the 2-bytes marker) was reverse-engineered from Total Commander
result:=escapeNL(s);
if result <> s then
  result:=result+#4#$C2;
end; // escapeIon

function unescapeIon(s:string):string;
begin
if ansiEndsStr(#4#$C2, s) then
  begin
  setLength(s, length(s)-2);
  s:=unescapeNL(s);
  end;
result:=s;
end; // unescapeIon

procedure loadIon(const lp: TLoadPrefs; const path:string; comments:TstringList);
var
  s, l, fn: string;
begin
//if not mainfrm.supportDescriptionChk.checked then exit;
s:=loadDescriptionFile(lp, path);
while s > '' do
  begin
  l:=chopLine(s);
  if l = '' then continue;
  fn:=chop(nonQuotedPos(' ', l), l);
  comments.add(dequote(fn)+'='+trim(unescapeIon(l)));
  end;
end; // loadIon

function isCommentFile(const lp: TLoadPrefs; const fn:string):boolean;
begin
result:=(fn=COMMENTS_FILE)
  or (lpSnglCmnt in lp) and isExtension(fn, COMMENT_FILE_EXT)
  or (lpION in lp) and sameText('descript.ion',fn)
end; // isCommentFile

function getFiles(const mask:string):TStringDynArray;
var
  sr: TSearchRec;
begin
result:=NIL;
if findFirst(mask, faAnyFile, sr) = 0 then
  try
    repeat addString(sr.name, result)
    until findNext(sr) <> 0;
  finally findClose(sr) end;
end; // getFiles

// returns number of skipped files
function TfileListing.fromFolder(loadPrefs: TLoadPrefs; folder: Tfile; cd: TconnDataMain;
  recursive:boolean=FALSE; limit:integer=-1; toSkip:integer=-1; doClear:boolean=TRUE):integer;
var
  seeProtected, noEmptyFolders, forArchive: boolean;
  filesFilter, foldersFilter, urlFilesFilter, urlFoldersFilter: string;

  procedure recurOn(f:Tfile);
  begin
  if not f.isFolder() then exit;
  toSkip:=fromFolder(loadPrefs, f, cd, TRUE, limit, toSkip, FALSE);
  end; // recurOn

  procedure addToListing(f:Tfile);
  begin
    if noEmptyFolders and f.isEmptyFolder(loadPrefs, cd)
       and not accountAllowed(FA_UPLOAD, cd, f) then
      exit; // upload folders should be listed anyway
//  application.ProcessMessages();
  if cd.conn.state = HCS_DISCONNECTED then exit;

  if toSkip > 0 then dec(toSkip)
  else
    begin
    if actualCount >= length(dir) then
      begin
      setLength(dir, actualCount+1000);
      if actualCount > 0 then
//        mainfrm.setStatusBarText(format('Listing files: %s',[dotted(actualCount)]));
        begin end;
      end;
    dir[actualCount]:=f;
    inc(actualCount);
    end;

  if recursive and f.isFolder() then
    recurOn(f);
  end; // addToListing

  function allowedTo(f:Tfile):boolean;
  begin
  if cd = NIL then result:=FALSE
  else result:=(not (FA_VIS_ONLY_ANON in f.flags) or (cd.usr = ''))
    and (seeProtected or f.accessFor(cd))
    and not (forArchive and f.isDLforbidden())
  end; // allowedTo

  procedure includeFilesFromDisk();
  var
    comments: THashedStringList;
    commentMasks: TStringDynArray;

    // moves to "commentMasks" comments with a filemask as filename
    procedure extractCommentsWithWildcards();
    var
      i: integer;
      s: string;
    begin
    i:=0;
    while i < comments.count do
      begin
      s:=comments.names[i];
      if ansiContainsStr(s, '?')
      or ansiContainsStr(s, '*') then
        begin
        addString(comments[i], commentMasks);
        comments.Delete(i);
        end
      else
        inc(i);
      end;
    end; // extractCommentsWithWildcards

    // extract comment for "fn" from "commentMasks"
    function getCommentByMaskFor(fn:string):string;
    var
      i: integer;
      s, mask: string;
    begin
    for i:=0 to length(commentMasks)-1 do
      begin
      s:=commentMasks[i];
      mask:=chop('=', s);
      if fileMatch(mask, fn) then
        begin
        result:=s;
        exit;
        end;
      end;
    result:='';
    end; // getCommentByMaskFor

    procedure setBit(var i:integer; bits:integer; flag:boolean); inline;
    begin
    if flag then i:=i or bits
    else i:=i and not bits;
    end; // setBit

{**

this would let us have "=" inside the names, but names cannot be assigned

    procedure fixQuotedStringList(sl:Tstrings);
    var
      i: integer;
      s: string;
    begin
    for i:=0 to sl.count-1 do
      begin
      s:=sl.names[i];
      if (s = '') or (s[1] <> '"') then continue;
      s:=s+'='+sl.ValueFromIndex[i]; // reconstruct the line
      sl.names[i]:=chop(nonQuotedPos('=', s), s);
      sl.ValueFromIndex[i]:=s;
      end;
    end;
}
  var
    f: Tfile;
    sr: TSearchRec;
    namesInVFS: TStringDynArray;
    filteredOut: boolean;
    i: integer;
  begin
  if (limit >= 0) and (actualCount >= limit) then exit;

  // collect names in the VFS at this level. supposed to be faster than existsNodeWithName().
  namesInVFS:=NIL;
   f := folder.getFirstChild();
  while assigned(f) do
    begin
      addString(f.name, namesInVFS);
      f := f.getNextSibling();
    end;

  comments:=THashedStringList.create();
  try
    comments.caseSensitive:=FALSE;
    if FileExists(folder.resource+'\'+COMMENTS_FILE) then
     try
       comments.loadFromFile(folder.resource+'\'+COMMENTS_FILE, TEncoding.UTF8);
      except
     end;
    if lpion in loadPrefs then
      loadIon(loadPrefs, folder.resource, comments);
    i:=if_((filesFilter='\') or (urlFilesFilter='\'), faDirectory, faAnyFile);
    setBit(i, faSysFile, lpSysAttr in loadPrefs);
    setBit(i, faHidden, lpHdnAttr in loadPrefs);
    if findfirst(folder.resource+'\*', i, sr) <> 0 then exit;

    try
      extractCommentsWithWildcards();
        repeat
        application.ProcessMessages();
        cd.lastActivityTime:=now();
        if (timeout > 0) and (cd.lastActivityTime > timeout) then
          break;
        // we don't list these entries
        if (sr.name = '.') or (sr.name = '..')
        or isCommentFile(loadPrefs, sr.name) or isFingerprintFile(loadPrefs, sr.name) or sameText(sr.name, DIFF_TPL_FILE)
        or not hasRightAttributes(loadPrefs, sr.attr)
        or stringExists(sr.name, namesInVFS)
        then continue;

        filteredOut:=not fileMatch( if_(sr.Attr and faDirectory > 0, foldersFilter, filesFilter), sr.name)
          or not fileMatch( if_(sr.Attr and faDirectory > 0, urlFoldersFilter, urlFilesFilter), sr.name);
        // if it's a folder, though it was filtered, we need to recur
        if filteredOut and (not recursive or (sr.Attr and faDirectory = 0)) then continue;

        f:=Tfile.createTemp(folder.mainTree, folder.resource+'\'+sr.name, folder); // temporary nodes are bound to the parent's node
        if (FA_SOLVED_LNK in f.flags) and f.isFolder() then
          // sorry, but we currently don't support lnk to folders in real-folders
          begin
          f.free;
          continue;
          end;
        if filteredOut then
          begin
          recurOn(f);
          // possible children added during recursion are linked back through the node field, so we can safely free the Tfile
          f.free;
          continue;
          end;

        f.comment:=comments.values[sr.name];
        if f.comment = '' then
          f.comment:=getCommentByMaskFor(sr.name);
        f.comment:=macroQuote(unescapeNL(f.comment));

        f.size:=0;
        if f.isFile() then
          if FA_SOLVED_LNK in f.flags then
            f.size:=sizeOfFile(f.resource)
          else
            f.size:=int64(sr.FindData.nFileSizeHigh) shl 32 + sr.FindData.nFileSizeLow;
        f.mtime:=filetimeToDatetime(sr.FindData.ftLastWriteTime);
        addToListing(f);
        until (findNext(sr) <> 0) or (cd.conn.state = HCS_DISCONNECTED) or (limit >= 0) and (actualCount >= limit);
    finally findClose(sr) end;
  finally comments.free  end
  end; // includeFilesFromDisk

  procedure includeItemsFromVFS();
  var
    f: Tfile;
    sr: TSearchRec;
  begin
  { this folder has been dinamically generated, thus the node is not actually
  { its own... skip }
  if folder.isTemp() then exit;

  // include (valid) items from the VFS branch
  f := folder.getFirstChild;
  while assigned(f) and (cd.conn.state <> HCS_DISCONNECTED)
  and ((limit < 0) or (actualCount < limit)) do
    try
      cd.lastActivityTime:=now();

      // watching not allowed, to anyone
      if (FA_HIDDEN in f.flags) or (FA_HIDDENTREE in f.flags) then continue;

      // filtered out
      if not fileMatch( if_(f.isFolder(), foldersfilter, filesfilter), f.name)
      or not fileMatch( if_(f.isFolder(), urlFoldersfilter, urlFilesfilter), f.name)
      // in this case we must continue recurring: other virtual items may be contained in this real folder, and this flag doesn't apply to them.
      or (forArchive and f.isRealFolder() and (FA_DL_FORBIDDEN in f.flags)) then
        begin
        if recursive then recurOn(f);
        continue;
        end;

      if not allowedTo(f) then continue;

      if FA_VIRTUAL in f.flags then // links and virtual folders are virtual
        begin
        addToListing(f);
        continue;
        end;
      if FA_UNIT in f.flags then
        begin
        if sysutils.directoryExists(f.resource+'\') then
          addToListing(f);
        continue;
        end;

      // try to get more info about this item
      if findFirst(f.resource, faAnyFile, sr) = 0 then
        begin
        try
          // update size and time
          with sr.FindData do f.size:=nFileSizeLow+int64(nFileSizeHigh) shl 32;
          try f.mtime:=filetimeToDatetime(sr.FindData.ftLastWriteTime);
          except f.mtime:=0 end;
        finally findClose(sr) end;
        if not hasRightAttributes(loadPrefs, sr.attr) then continue;
        end
      else // why findFirst() failed? is it a shared folder?
        if not sysutils.directoryExists(f.resource) then continue;
      addToListing(f);
     finally
       f := f.getNextSibling();
    end;
  end; // includeItemsFromVFS

  function beginsOrEndsBy(ss:string; s:string):boolean;
  begin result:=ansiStartsText(ss,s) or ansiEndsText(ss,s) end;

  function par(k:string):string;
  begin if cd = NIL then result:='' else result:=cd.urlvars.values[k] end;

begin
result:=toSkip;
if doClear then
  actualCount:=0;

if not folder.isFolder()
or not folder.accessFor(cd)
or folder.hasRecursive(FA_HIDDENTREE)
or not (FA_BROWSABLE in folder.flags)
then exit;

if assigned(cd) then
  begin
  if limit < 0 then
    limit:=StrToIntDef(par('limit'), -1);
  if toSkip < 0 then
    toSkip:=StrToIntDef(par('offset'), -1);
  if toSkip < 0 then
    toSkip:=max(0, pred(strToIntDef(par('page'), 1))*limit);
  end;

folder.getFiltersRecursively(filesFilter, foldersFilter);
if assigned(cd) and not ignoreConnFilter then
  begin
  urlFilesFilter:=par('files-filter');
  if urlFilesFilter = '' then urlFilesFilter:=par('filter');
  urlFoldersFilter:=par('folders-filter');
  if urlFoldersFilter = '' then urlFoldersFilter:=par('filter');
  if (urlFilesFilter+urlFoldersFilter = '') and (par('search') > '') then
    begin
    urlFilesFilter:=reduceSpaces(par('search'), '*');
    if not beginsOrEndsBy('*', urlFilesFilter) then
      urlFilesFilter:='*'+urlFilesFilter+'*';
    urlFoldersFilter:=urlFilesFilter;
    end;
  end;
// cache user options
forArchive:=assigned(cd) and (cd.downloadingWhat = DW_ARCHIVE);
seeProtected:=not (lpHideProt in loadPrefs) and not forArchive;
noEmptyFolders:=(urlFilesFilter = '') and folder.hasRecursive(FA_HIDE_EMPTY_FOLDERS);
try
  if folder.isRealFolder() and not (FA_HIDDENTREE in folder.flags) and allowedTo(folder) then
    includeFilesFromDisk();
  includeItemsFromVFS();
finally
  if doClear then
    setLength(dir, actualCount)
  end;
result:=toSkip;
end; // fromFolder

function TFileServer.initRoot(pTree: TTreeView): TFile;
begin
  rootFile := Tfile.createVirtualFolder(pTree, '/');
  rootFile.flags := rootFile.flags+[FA_ROOT, FA_ARCHIVABLE];
  rootFile.dontCountAsDownloadMask:='*.htm;*.html;*.css';
  rootFile.defaultFileMask:='index.html;index.htm;default.html;default.htm';
  Result := rootFile;
end;

function TFileServer.encodeURLA(const s: String; fullEncode:boolean=FALSE): RawByteString;
var
  r: RawByteString;
  sp: TShowPrefs;
begin
  sp := onGetSP();
  if fullEncode or (spEncodeNonAscii in SP) then
    begin
      r := ansiToUTF8(s);
      result := HSlib.encodeURL(r, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
    end
   else
    result:=HSlib.encodeURL(s, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
end; // encodeURL

function TFileServer.encodeURLW(const s: String; fullEncode:boolean=FALSE): String;
var
  r: RawByteString;
  sp: TShowPrefs;
begin
  sp := onGetSP;
  if fullEncode or (spEncodeNonAscii in SP) then
    begin
      r := ansiToUTF8(s);
      result := HSlib.encodeURL(r, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
    end
   else
    result:=HSlib.encodeURL(s, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
end; // encodeURL

function TFileServer.findFilebyURL(url:string; const lp: TLoadPrefs; parent:Tfile=NIL; allowTemp:boolean=TRUE):Tfile;

  procedure workTheRestByReal(rest:string; f:Tfile);
  var
    s: string;
  begin
  if not allowTemp then exit;

  s:=rest; // just a shortcut
  if dirCrossing(s) then exit;

  s:=includeTrailingPathDelimiter(f.resource)+s; // we made the ".." test before, so relative paths are allowed in the VFS
  if not fileOrDirExists(s) and fileOrDirExists(s+'.lnk') then
    s:=s+'.lnk';
  if not fileOrDirExists(s) or not hasRightAttributes(LP, s) then
    exit;
  // found on disk, we need to build a temporary Tfile to return it
  result:=Tfile.createTemp(f.mainTree, s, f); // temp nodes are bound to parent's node
  // the temp file inherits flags from the real folder
  if FA_DONT_LOG in f.flags then
    include(result.flags, FA_DONT_LOG);
  if not (FA_BROWSABLE in f.flags) then
    exclude(result.flags, FA_BROWSABLE);
  end; // workTheRestByReal

var
  parts: TStringDynArray;
  s: string;
  cur, n: Ttreenode;
  found: boolean;
  f: Tfile;

  function workDots():boolean;
  label REMOVE;
  var
    i: integer;
  begin
  result:=FALSE;
  i:=0;
  while i < length(parts) do
    begin
    if parts[i] = '.' then
      goto REMOVE; // 10+ years have passed since the last time i used labels in pascal. It's a thrill.
    if parts[i] <> '..' then
      begin
      inc(i);
      continue;
      end;
    if i > 0 then
      begin
      removeString(parts, i-1, 2);
      dec(i);
      continue;
      end;
    parent:=parent.parent;
    if parent = NIL then exit;
    REMOVE:
    removeString(parts, i, 1);
    end;
  result:=TRUE;
  end; // workDots

begin
  result := NIL;
  if (url = '') or anycharIn(#0, url) then exit;
if parent = NIL then
  parent:=rootFile;
url:=xtpl(url, ['//', '/']);
if url[1] = '/' then
  begin
  delete(url, 1,1);  // remove initial "/"
  parent:=rootFile; // it's an absolute path, not relative
  end;
excludeTrailingString(url, '/');
parts:=split('/', url);
if not workDots() then exit;

if parent.isTemp() then
  begin
  workTheRestByReal(url, parent);
  exit;
  end;

cur:=parent.node;   // we'll move using treenodes
for var i: integer :=0 to length(parts)-1 do
  begin
  s:=parts[i];
  if s = '' then exit; // no support for null filenames
  found:=FALSE;
  // search inside the VFS
  n:=cur.getFirstChild();
  while assigned(n) do
    begin
//    found:=stringExists(n.text, s) or sameText(n.text, UTF8toAnsi(s));
//        found := stringExists(n.text, s) or sameText(n.text, s);
    found:=sameText(n.text, s);
    if found then break;
    n:=n.getNextSibling();
    end;
  if not found then // this piece was not found the virtual way
    begin
    f:=cur.data;
    if f.isRealFolder() then // but real folders have not all the stuff loaded and ready. we have another way to walk.
      begin
        if length(parts) > i+1 then
          for var j: integer :=i+1 to length(parts)-1 do
            s:=s+'\'+parts[j];
        workTheRestByReal(s, f);
      end;
    exit;
    end;
  cur:=n;
  if cur = NIL then exit;
  end;
result:=cur.data;
end; // findFileByURL

function TFileServer.protoColon(sp: TShowPrefs): String;
const
  LUT: array [boolean] of string = ('http://','https://');
begin
  result := LUT[spHttpsUrls in sp];
end; // protoColon


function TFileServer.pathTill(fl: Tfile; root: Tfile=NIL; delim: char='\'): String;
var
  f2: Tfile;
begin
  result:='';
  if fl = root then
    exit;
  result := fl.name;
  f2 := fl.parent;
  if fl.isTemp() then
    begin
    if FA_SOLVED_LNK in fl.flags then
      result := extractFilePath(copy(fl.lnk,length(f2.resource)+2, MAXINT)) + fl.name // the path is the one of the lnk, but we have to replace the file name as the lnk can make it
    else
      result:=copy(fl.resource, length(f2.resource)+2, MAXINT);
    if delim <> '\' then result:=xtpl(result, ['\', delim]);
    end;
  while assigned(f2) and (f2 <> root) and (f2 <> rootFile) do
    begin
    result:=f2.name+delim+result;
    f2 := f2.parent;
    end;
end; // pathTill

function TFileServer.url(f: Tfile; fullEncode: boolean=FALSE): string;
begin
  assert(f.node<>NIL, 'node can''t be NIL');
  if f.isLink() then
    result:= f.relativeURL(fullEncode)
   else
    result:='/'+encodeURLW(pathTill(f, rootFile, '/'), fullEncode)
     +if_(f.isFolder() and not f.isRoot(), '/');
end; // url

function TFileServer.parentURL(f: Tfile): string;
var
  i: integer;
begin
  result:=url(f, TRUE);
  i:=length(result)-1;
  while (i > 1) and (result[i] <> '/') do dec(i);
  setlength(result,i);
end; // parentURL

function TFileServer.fullURL(f: Tfile; const ip, user, pwd: String): String;
var s,k,base: string;
begin
if userPwdHashCache = NIL then
  userPwdHashCache:=Tstr2str.Create();
base:=fullURL(f, ip)+'?';
k:=user+':'+pwd;
try result:=base+userPwdHashCache[k]
except
  s:='mode=auth&u='+encodeURLW(user);
  s:=s+'&s2='+strSHA256(s+pwd); // sign with password
  userPwdHashCache.add(k,s);
  result:=base+s;
  end;
end; // fullURL

function TFileServer.fullURL(f: Tfile; ip: String=''): String;
var
  sp: TShowPrefs;
begin
  sp := onGetSP();
  result := url(f);
  if f.isLink() then
    exit;
  if assigned(srv) and srv.active
     and (srv.port <> '80') and (pos(':',ip) = 0)
     and not (spNoPortInUrl in sp) then
    result := ':'+srv.port+result;
  if ip = '' then
    ip:=defaultIP;
  if Pos(':',ip, Pos(':',ip)+1) > 0 then // ipv6
    ip:='['+getTill('%',ip)+']';
  result := protoColon(sp)+ip+result;
end; // fullURL


function TFileServer.getAFolderPage(folder:Tfile; cd:TconnDataMain; otpl: TTpl;
                 const lp: TLoadPrefs; const sp: TShowPrefs;
                 isPwdInPages, isMacrosLog: Boolean): String;
var
  baseurl, list, fileTpl, folderTpl, linkTpl: string;
  table: TStringDynArray;
  ofsRelItemUrl, ofsRelUrl, numberFiles, numberFolders, numberLinks: integer;
  img_file: boolean;
  totalBytes: int64;
  fast: TfastStringAppend;
  buildTime: Tdatetime;
  listing: TfileListing;
  diffTpl: Ttpl;
  hasher: Thasher;
  fullEncode, recur, oneAccessible: boolean;
  md: TmacroData;

  procedure applySequential();
  const
    PATTERN = '%sequential%';
  var
    idx, p: integer;
    idxS: string;
  begin
  idx:=0;
  p:=1;
    repeat
    p:=ipos(PATTERN, result, p);
    if p = 0 then exit;
    inc(idx);
    idxS:=intToStr(idx);
    delete(result, p, length(PATTERN)-length(idxS));
    moveChars(idxS[1], result[p], length(idxS));
    until false;
  end; // applySequential

  procedure handleItem(f:Tfile);
  var
    type_, s, url, fingerprint, itemFolder: string;
    nonPerc: TStringDynArray;
  begin
    if not f.isLink and ansiContainsStr(f.resource, '?') then
      exit; // unicode filename?   //mod by mars

//    if f.size > 0 then
//      inc(totalBytes, f.size);

  // build up the symbols table
  md.table:=table;
  nonPerc:=NIL;
  if f.icon >= 0 then
    begin
    s:='~img'+intToStr(f.icon);
    addArray(nonPerc, ['~img_folder', s, '~img_link', s]);
    end;
  if f.isFile() then
    if img_file and ((spUseSysIcons in SP) or (f.icon >= 0)) then
      addArray(nonPerc, ['~img_file', '~img'+intToStr(f.getSystemIcon())]);

  if recur or (itemFolder = '') then
    itemFolder:=f.getFolder();
  if recur then
    url:=substr(itemFolder, ofsRelItemUrl)
  else
    url:='';
  addArray(md.table, [
    '%item-folder%', itemFolder,
    '%item-relative-folder%', url
  ]);

  if not f.accessFor(cd) then
    s:=diffTpl['protected']
  else
    begin
    s:='';
    if f.isFileOrFolder() then
      oneAccessible:=TRUE;
    end;
  addArray(md.table, [
    '%protected%', s
  ]);

  // url building
  fingerprint:='';
  if (lpFingerPrints in lp) and f.isFile() then
    begin
    s:=loadMD5for(f.resource);
    if s = '' then
      s:=hasher.getHashFor(f.resource);
    if s > '' then
      fingerprint:='#!md5!'+s;
    end;
  if f.isLink() then
    begin
    url:=f.resource;
    s:=url;
    end
  else
    if isPwdInPages and (cd.usr > '') then
      begin
      s:= fullURL(f, cd.getSafeHost(cd), cd.usr, cd.pwd )+fingerprint;
      url:=s
      end
    else
      begin
      if recur then
        s:=copy(self.url(f, fullEncode), ofsRelUrl, MAXINT)+fingerprint
      else
        s:=f.relativeURL(fullEncode)+fingerprint;
      url:=baseurl+s;
      end;

  if not f.isLink() then
    begin
    s:=macroQuote(s);
    url:=macroQuote(url);
    end;

  addArray(md.table, [
    '%item-url%', s,
    '%item-full-url%', url
  ]);

  // select appropriate template
  if f.isLink() then
    begin
    s:=linkTpl;
    inc(numberLinks);
    type_:='link';
    end
  else if f.isFolder() then
    begin
    s:=folderTpl;
    inc(numberFolders);
    type_:='folder';
    end
  else
    begin
    s := diffTpl.getTxtByExt(ExtractFileExt(f.name));
    if s = '' then s:=fileTpl;
    inc(numberFiles);
    type_:='file';
    end;

  addArray(md.table, [
    '%item-type%', type_
  ]);

  s:=xtpl(s, nonPerc);
  md.f:=f;
  tryApplyMacrosAndSymbols(s, md, FALSE);
  fast.append(s);
  end; // handleItem

  function shouldRecur(cd: TconnDataMain): Boolean;
  begin
    Result := (lpRecurListing in lp) and cd.allowRecur;

  end;
var
  n: integer;
  f: Tfile;
  useList: boolean;
  mainSection: PtplSection;
  antiDos: TantiDos;
begin
  result := '';
  if (folder = NIL) or not folder.isFolder() then
    exit;

  diffTpl:=Ttpl.create();
  folder.lock();
try
  buildTime := now();
  cd.conn.setHeaderIfNone('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=-1');
  recur := shouldRecur(cd);
  baseurl := protoColon(sp)+cd.getSafeHost(cd)+ url(folder, TRUE);

  if cd.tpl = NIL then
    diffTpl.over := otpl
  else
    begin
    diffTpl.over := cd.tpl;
    cd.tpl.over := otpl;
    end;

  if otpl <> filelistTpl then
    diffTpl.fullTextS := folder.getRecursiveDiffTplAsStr();
  mainSection:=diffTpl.getSection('');
  if mainSection = NIL then
    exit;
  useList:=not mainSection.noList;

  antiDos:=TantiDos.create();
  if useList and not antiDos.accept(cd.conn, cd.address) then
    exit(cd.conn.reply.body);

  fullEncode:=FALSE;
  ofsRelUrl:=length(url(folder, fullEncode))+1;
  ofsRelItemUrl:=length(pathTill(folder))+1;
  // pathTill() is '/' for root, and 'just/folder', so we must accordingly consider a starting and trailing '/' for the latter case (bugfix by mars)
  if not folder.isRoot() then
    inc(ofsRelItemUrl, 2);

  ZeroMemory(@md, sizeOf(md));
  md.cd:=cd;
  md.tpl:=diffTpl;
  md.folder:=folder;
  md.archiveAvailable:=folder.hasRecursive(FA_ARCHIVABLE) and not folder.isDLforbidden();
  md.hideExt:=folder.hasRecursive(FA_HIDE_EXT);

  result:=diffTpl['special:begin'];
  tryApplyMacrosAndSymbols(result, md, FALSE);

  if useList then
    begin
      // cache these values
      fileTpl:=xtpl(diffTpl['file'], table);
      folderTpl:=xtpl(diffTpl['folder'], table);
      linkTpl:=xtpl(diffTpl['link'], table);
      // this may be heavy to calculate, only do it upon request
      img_file:=pos('~img_file', fileTpl) > 0;

      // build %list% based on dir[]
      numberFolders:=0; numberFiles:=0; numberLinks:=0;
      totalBytes:=0;
      oneAccessible:=FALSE;
      fast:=TfastStringAppend.Create();
      listing:=TfileListing.create();
      hasher:=Thasher.create();
      if lpFingerPrints in lp then
        hasher.loadFrom(folder.resource);
      try
        listing.fromFolder(lp, folder, cd, recur );
        listing.sort(spFoldersBefore in SP, spLinksBefore in SP, cd, if_(recur or (otpl = filelistTpl), '?', diffTpl['sort by']) ); // '?' is just a way to cause the sort to fail in case the sort key is not defined by the connection

        n:=length(listing.dir);
        for var i: Integer :=0 to n-1 do
          begin
          f:=listing.dir[i];
          if f.size > 0 then
            inc(totalBytes, f.size);
          if f.isLink() then
            inc(numberLinks)
          else if f.isFolder() then
            inc(numberFolders)
          else
            inc(numberFiles);
          end;
        {TODO this symbols will be available when executing macros in handleItem. Having
          them at this stage is useful only in case immediate calculations are required.
          This may happen seldom, but maybe some template is using it since we got this here.
          Each symbols is an extra iteration on the template piece and we may be tempted
          to consider for optimizations. To not risk legacy problems we should consider
          treating table symbols with a regular expression and a Tdictionary instead.
        }
        table:=toSA([
          '%upload-link%', if_(accountAllowed(FA_UPLOAD, cd, folder), diffTpl['upload-link']),
          '%files%', diffTpl[if_(n>0, 'files','nofiles')],
          '%number%', intToStr(n),
          '%number-files%', intToStr(numberFiles),
          '%number-folders%', intToStr(numberFolders),
          '%number-links%', intToStr(numberlinks),
          '%total-bytes%', intToStr(totalBytes),
          '%total-kbytes%', intToStr(totalBytes div KILO),
          '%total-size%', smartsize(totalBytes)
        ]);

        for var i: Integer :=0 to length(listing.dir)-1 do
          begin
            if i mod 42 = 0 then
              application.ProcessMessages();
          if cd.conn.state = HCS_DISCONNECTED then
            exit;
          cd.lastActivityTime:=now();
          handleItem(listing.dir[i])
          end;
        list:=fast.reset();
      finally
        listing.free;
        fast.free;
        hasher.free;
        end;

      if cd.conn.state = HCS_DISCONNECTED then
        exit;

      // build final page
      if not oneAccessible then
        md.archiveAvailable:=FALSE;
    end
   else
    list := '';

  md.table:=table;
  addArray(md.table, [
    '%list%',list
  ]);
  result:=mainSection.txt;
  md.f:=NIL;
  md.afterTheList:=TRUE;
  try tryApplyMacrosAndSymbols(result, md)
  finally md.afterTheList:=FALSE end;
  applySequential();
  // ensure this is the last symbol to be translated
  result:=xtpl(result, [
    '%build-time%', floatToStrF((now()-buildTime)*SECONDS, ffFixed, 7,3)
  ]);
finally
  freeAndNIL(antiDos);
  folder.unlock();
  diffTpl.free;
  end;
end; // getAFolderPage


end.
