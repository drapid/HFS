unit fileLib;

interface

uses
  // delphi libs
  Windows, Messages, Graphics, Forms, ComCtrls, math, Types, SysUtils,
  HSLib, classesLib;

type

  TfileAttribute = (
    FA_FOLDER,       // folder kind
    FA_VIRTUAL,      // does not exist on disc
    FA_ROOT,         // only the root item has this attribute
    FA_BROWSABLE,    // permit listing of this folder (not recursive, only dir)
    FA_HIDDEN,       // hidden iterms won't be shown to browsers (not recursive)
    { no more used attributes have to stay for backward compatibility with
    { VFS files }
    FA_NO_MORE_USED1,
  	FA_NO_MORE_USED2,
    FA_TEMP,            // this is a temporary item and is not part of the VFS
    FA_HIDDENTREE,      // recursive hidden
    FA_LINK,            // redirection
    FA_UNIT,            // logical unit (drive)
    FA_VIS_ONLY_ANON,   // visible only to anonymous users [no more used]
    FA_DL_FORBIDDEN,    // forbid download (not recursive)
    FA_HIDE_EMPTY_FOLDERS,  // (recursive)
    FA_DONT_COUNT_AS_DL,    // (not recursive)
    FA_SOLVED_LNK,
    FA_HIDE_EXT,       // (recursive)
    FA_DONT_LOG,       // (recursive)
    FA_ARCHIVABLE      // (recursive)
  );
  TfileAttributes = set of TfileAttribute;

  Tfile = class;
//  TconnData = class;

  TfileCallbackReturn = set of (FCB_NO_DEEPER, FCB_DELETE, FCB_RECALL_AFTER_CHILDREN); // use FCB_* flags

  // returning FALSE stops recursion
  TfileCallback = function(f:Tfile; childrenDone:boolean; par, par2: IntPtr): TfileCallbackReturn;

  TfileAction = (FA_ACCESS, FA_DELETE, FA_UPLOAD);

  TLoadPrefs = set of (lpION, lpHideProt, lpSysAttr, lpHdnAttr, lpSnglCmnt, lpFingerPrints);

  Tfile = class (Tobject)
  private
    fLocked: boolean;
    FDLcount: integer;
    tempParent: TFile;
//    fNode: Ttreenode;
    function  getParent():Tfile;
    function  getDLcount():integer;
    procedure setDLcount(i:integer);
    function  getDLcountRecursive():integer;
  public
    name, comment, user, pwd, lnk: string;
    resource: string;  // link to physical file/folder; URL for links
    flags: TfileAttributes;
    size: int64; // -1 is NULL
    atime,            // when was this file added to the VFS ?
    mtime: Tdatetime; // modified time, read from disk
    icon: integer;
    accounts: array [TfileAction] of TStringDynArray;
    filesFilter, foldersFilter, realm, diffTpl,
    defaultFileMask, dontCountAsDownloadMask, uploadFilterMask: string;
    constructor create(fullpath: String);
    constructor createTemp(const fullpath: String; pParentFile: TFile = NIL);
    constructor createVirtualFolder(const name:string);
    constructor createLink(const name: String);
    function  toggle(att:TfileAttribute):boolean;
    function  isFolder():boolean; inline;
    function  isFile():boolean; inline;
    function  isFileOrFolder():boolean; inline;
    function  isRealFolder():boolean; inline;
    function  isVirtualFolder():boolean; inline;
    function  isEmptyFolder(loadPrefs: TLoadPrefs; cd:TconnDataMain=NIL):boolean;
    function  isRoot():boolean; inline;
    function  isLink():boolean; inline;
    function  isTemp():boolean; inline;
    function  isNew():boolean;
    function  isDLforbidden():boolean;
    function  relativeURL(fullEncode:boolean=FALSE):string;
    procedure setupImage(sysIcons: Boolean; newIcon: integer); overload;
    procedure setupImage(sysIcons: Boolean; pNode: TTreeNode = NIL); overload;
    function  getAccountsFor(action:TfileAction; specialUsernames:boolean=FALSE; outInherited:Pboolean=NIL):TstringDynArray;
    function  accessFor(username, password:string):boolean; overload;
    function  accessFor(cd:TconnDataMain):boolean; overload;
    function  hasRecursive(attributes: TfileAttributes; orInsteadOfAnd:boolean=FALSE; outInherited:Pboolean=NIL):boolean; overload;
    function  hasRecursive(attribute: TfileAttribute; outInherited:Pboolean=NIL):boolean; overload;
    function  getIconForTreeview(sysIcons: Boolean):integer;
    function  getFolder():string;
    function  getRecursiveFileMask():string;
    function  shouldCountAsDownload():boolean;
    function  getDefaultFile():Tfile;
    procedure recursiveApply(callback: TfileCallback; par: NativeInt=0; par2: NativeInt=0);
    procedure getFiltersRecursively(var files,folders:string);
    function  diskfree():int64;
    function  same(f:Tfile):boolean;
    procedure setName(const name: String);
    procedure setResource(res: string);
    function  getDynamicComment(loadPrefs: TLoadPrefs; skipParent:boolean=FALSE):string;
    procedure setDynamicComment(loadPrefs: TLoadPrefs; cmt:string);
    function  getRecursiveDiffTplAsStr(outInherited:Pboolean=NIL; outFromDisk:Pboolean=NIL):string;
    // locking prevents modification of all its ancestors and descendants
    procedure lock();
    procedure unlock();
    procedure SyncNode(pNode: Ttreenode);
    function  findNode: TTreeNode;
    function  getNode: TTreeNode;
    function  isLocked():boolean;
    function  getFirstChild: TFile;
    function  getNextSibling: TFile;
    function  getMainFile: TFile;
    property  parent:Tfile read getParent;
    property  DLcount:integer read getDLcount write setDLcount;
    property  node: Ttreenode read getNode;
    property  locked: Boolean read fLocked;
   end; // Tfile

  TfileListing = class
   public
    dir: array of Tfile;
    ignoreConnFilter: boolean;
    constructor create();
    destructor Destroy; override;
    function fromFolder(loadPrefs: TLoadPrefs; folder:Tfile; cd:TconnDataMain; recursive:boolean=FALSE;
      limit:integer=-1; toSkip:integer=-1; doClear:boolean=TRUE):integer;
    procedure sort(foldersBefore, linksBefore: Boolean; cd:TconnDataMain; def:string='');
  end;

function nodeToFile(n:TtreeNode):Tfile;
function isCommentFile(lp: TLoadPrefs; fn: string): boolean;
function isFingerprintFile(lp: TLoadPrefs; const fn: string): boolean;
function hasRightAttributes(lp: TLoadPrefs; const fn: string): boolean; overload;
function hasRightAttributes(lp: TLoadPrefs; attr:integer): boolean; overload;
function findNameInDescriptionFile(const txt, name:string):integer;

const
  FILEACTION2STR: array [TfileAction] of string = ('Access', 'Delete', 'Upload');

var
  defSorting: string;          // default sorting, browsing

implementation

uses
  strutils, iniFiles, Classes,
  RegExpr,
  main, utilLib, RDUtils, RDFileUtil, hfsGlobal, scriptLib, hfsVars;

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
  application.ProcessMessages();
  if cd.conn.state = HCS_DISCONNECTED then exit;

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

function loadDescriptionFile(fn:string):string;
var
  sa: RawByteString;
begin
  result := '';
  sa := loadFile(fn);
  if sa = '' then
    sa := loadFile(fn+'\descript.ion');
  if (sa > '') and mainfrm.oemForIonChk.checked then
    Result := sa
   else
    Result := UnUTF(sa);
end; // loadDescriptionFile

function escapeIon(s:string):string;
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

procedure loadIon(path:string; comments:TstringList);
var
  s, l, fn: string;
begin
//if not mainfrm.supportDescriptionChk.checked then exit;
s:=loadDescriptionFile(path);
while s > '' do
  begin
  l:=chopLine(s);
  if l = '' then continue;
  fn:=chop(nonQuotedPos(' ', l), l);
  comments.add(dequote(fn)+'='+trim(unescapeIon(l)));
  end;
end; // loadIon

function isCommentFile(lp: TLoadPrefs; fn:string):boolean;
begin
result:=(fn=COMMENTS_FILE)
  or (lpSnglCmnt in lp) and isExtension(fn, COMMENT_FILE_EXT)
  or (lpION in lp) and sameText('descript.ion',fn)
end; // isCommentFile

function isFingerprintFile(lp: TLoadPrefs; const fn:string):boolean;
begin
  result := (lpFingerPrints in lp)and isExtension(fn, '.md5')
end; // isFingerprintFile

function hasRightAttributes(lp: TLoadPrefs; attr:integer):boolean; overload;
begin
result:=((lpHdnAttr in lp)or (attr and faHidden = 0))
  and ((lpSysAttr in lp) or (attr and faSysFile = 0));
end; // hasRightAttributes

function hasRightAttributes(lp: TLoadPrefs; const fn: string):boolean; overload;
begin result:=hasRightAttributes(lp, GetFileAttributes(pChar(fn))) end;

function getFiles(mask:string):TStringDynArray;
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
  actualCount: integer;
  seeProtected, noEmptyFolders, forArchive: boolean;
  filesFilter, foldersFilter, urlFilesFilter, urlFoldersFilter: string;

  procedure recurOn(f:Tfile);
  begin
  if not f.isFolder() then exit;
  setLength(dir, actualCount);
  toSkip:=fromFolder(loadPrefs, f, cd, TRUE, limit, toSkip, FALSE);
  actualCount:=length(dir);
  end; // recurOn

  procedure addToListing(f:Tfile);
  begin
    if noEmptyFolders and f.isEmptyFolder(loadPrefs, cd)
       and not accountAllowed(FA_UPLOAD, cd, f) then
      exit; // upload folders should be listed anyway
  application.ProcessMessages();
  if cd.conn.state = HCS_DISCONNECTED then exit;

  if toSkip > 0 then dec(toSkip)
  else
    begin
    if actualCount >= length(dir) then
      setLength(dir, actualCount+100);
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
    try comments.loadFromFile(folder.resource+'\'+COMMENTS_FILE, TEncoding.UTF8);
    except end;
    if lpion in loadPrefs then
      loadIon(folder.resource, comments);
    i:=if_((filesFilter='\') or (urlFilesFilter='\'), faDirectory, faAnyFile);
    setBit(i, faSysFile, lpSysAttr in loadPrefs);
    setBit(i, faHidden, lpHdnAttr in loadPrefs);
    if findfirst(folder.resource+'\*', i, sr) <> 0 then exit;

    try
      extractCommentsWithWildcards();
        repeat
        application.ProcessMessages();
        cd.lastActivityTime:=now();
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

        f:=Tfile.createTemp( folder.resource+'\'+sr.name, folder); // temporary nodes are bound to the parent's node
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
if doClear then dir:=NIL;

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

actualCount:=length(dir);
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
finally setLength(dir, actualCount) end;
result:=toSkip;
end; // fromFolder



constructor Tfile.create(fullpath: string);
begin
fullpath:=ExcludeTrailingPathDelimiter(fullpath);
icon:=-1;
size:=-1;
atime:=now();
mtime:=atime;
flags:=[];
setResource(fullpath);
if (resource > '') and sysutils.directoryExists(resource) then
  flags:=flags+[FA_FOLDER, FA_BROWSABLE];
end; // create

constructor Tfile.createTemp(const fullpath: String; pParentFile: TFile = NIL);
begin
create(fullpath);
include(flags, FA_TEMP);
  if Assigned(pParentFile) then
    tempParent := pParentFile.getMainFile
   else
    tempParent := NIL;
end; // createTemp

constructor Tfile.createVirtualFolder(const name:string);
begin
icon:=-1;
setResource('');
flags:=[FA_FOLDER, FA_VIRTUAL, FA_BROWSABLE];
self.name:=name;
atime:=now();
mtime:=atime;
end; // createVirtualFolder

constructor Tfile.createLink(const name: String);
begin
icon:=-1;
setName(name);
atime:=now();
mtime:=atime;
flags:=[FA_LINK, FA_VIRTUAL];
end; // createLink

procedure Tfile.setResource(res:string);

  function sameDrive(f1,f2:string):boolean;
  begin
  result:=(length(f1) >= 2) and (length(f2) >= 2) and (f1[2] = ':')
    and (f2[2] = ':') and (upcase(f1[1]) = upcase(f2[1]));
  end; // sameDrive

var
  s: string;
begin
if isExtension(res, '.lnk') or fileExists(res+'\target.lnk') then
  begin
  s:=extractFileName(res);
  if isExtension(s, '.lnk') then
    setLength(s, length(s)-4);
  setName(s);
  lnk:=res;
  res:=resolveLnk(res);
  include(flags, FA_SOLVED_LNK);
  end
else
  exclude(flags, FA_SOLVED_LNK);
res:=ExcludeTrailingPathDelimiter(res);

// in this case, drive letter may change. useful with pendrives.
if runningOnRemovable and sameDrive(exePath, res) then
  delete(res, 1,2);

resource:=res;
if (length(res) = 2) and (res[2] = ':') then // logical unit
  begin
  include(flags, FA_UNIT);
  if not isRoot() and not (FA_SOLVED_LNK in flags) then
    setName(res);
  end
else
  begin
  exclude(flags, FA_UNIT);
  if not isRoot() and not (FA_SOLVED_LNK in flags) then
    setName(extractFileName(res));
  end;
size:=-1;
end; // setResource

procedure Tfile.setName(const name: String);
var
  n: TTreeNode;
begin
  if self.name <> name then
   begin
    self.name := name;
    if getMainFile <> Self then
      exit;
    n := findNode;
    if n <> NIL then
      n.Text := name;
   end;
end; // setName

procedure TFile.SyncNode(pNode: Ttreenode);
begin
//  fNode := pNode;
//  if Assigned(pNode) then
//    if pNode.Text <> name then
//      pNode.Text := name;
end;

function TFile.findNode: TTreeNode;
var
  n: TTreeNode;
begin
  for n in MainFrm.filesBox.Items do
    if n.Data = Self then
      Exit(n);
  Result := NIL;
end;

function TFile.getNode: TTreeNode;
begin
  if isTemp then
    begin
      if Assigned(tempParent) then
        Result := tempParent.node
       else
        Result := NIL
    end
   else
    Result := findNode;
end;

function Tfile.same(f:Tfile):boolean;
begin result:=(self = f) or (resource = f.resource) end;

function Tfile.toggle(att:TfileAttribute):boolean;
begin
if att in flags then exclude(flags, att)
else include(flags, att);
result:=att in flags
end;

function Tfile.isRoot():boolean;
begin result:=FA_ROOT in flags end;

function Tfile.isFolder():boolean;
begin result:=FA_FOLDER in flags end;

function Tfile.isLink():boolean;
begin result:=FA_LINK in flags end;

function Tfile.isTemp():boolean;
begin result:=FA_TEMP in flags end;

function Tfile.isFile():boolean;
begin result:=not ((FA_FOLDER in flags) or (FA_LINK in flags)) end;

function Tfile.isFileOrFolder():boolean;
begin result:=not (FA_LINK in flags) end;

function Tfile.isRealFolder():boolean;
begin result:=(FA_FOLDER in flags) and not (FA_VIRTUAL in flags) end;

function Tfile.isVirtualFolder():boolean;
begin result:=(FA_FOLDER in flags) and (FA_VIRTUAL in flags) end;

function Tfile.isEmptyFolder(loadPrefs: TLoadPrefs; cd:TconnDataMain=NIL):boolean;
var
  listing: TfileListing;
begin
result:=FALSE;
if not isFolder() then exit;
listing:=TfileListing.create();
//** i fear it is not ok to use fromFolder() to know if the folder is empty, because it gives empty also for unallowed folders.
listing.fromFolder(loadPrefs, self, cd, FALSE, 1 );
result:= length(listing.dir) = 0;
listing.free;
end; // isEmptyFolder

// uses comments file
function Tfile.getDynamicComment(loadPrefs: TLoadPrefs; skipParent:boolean=FALSE):string;
var
  comments: THashedStringList;
begin
try
  result:=comment;
  if result > '' then exit;
  if lpSnglCmnt in loadPrefs then
    result:= UnUTF(loadFile(resource+COMMENT_FILE_EXT));
  if (result > '') or skipParent then exit;
  comments:=THashedStringList.create();
  try
    try
      if fileExists(resource+'\..\'+COMMENTS_FILE) then
       begin
        comments.CaseSensitive:=FALSE;
        comments.LoadFromFile(resource+'\..\'+COMMENTS_FILE, TEncoding.UTF8);
        result:=comments.values[name];
       end;
    except end
  finally
    if result = '' then
      begin
      loadIon(resource+'\..', comments);
      result:=comments.values[name];
      end;
    if result > '' then
      result:=unescapeNL(result);
    comments.free
  end;
finally result:=macroQuote(result) end;
end; // getDynamicComment

function findNameInDescriptionFile(const txt, name:string):integer;
begin result:=reMatch(txt, '^'+quoteRegExprMetaChars(quoteIfAnyChar(' ',name)), 'mi') end;

procedure Tfile.setDynamicComment(loadPrefs: TLoadPrefs; cmt:string);
var
  s, path, name: string;
  i: integer;
begin
if not isTemp() then
  begin
  comment:=cmt; // quite easy
  exit;
  end;
path:=resource+COMMENT_FILE_EXT;
if fileExists(path) then
  begin
  if cmt='' then
    deleteFile(path)
  else
    saveTextFile(path, cmt);
  exit;
  end;
name:=extractFileName(resource);

// we prefer descript.ion, but if its support was disabled,
// or it doesn't exist while hfs.comments.txt does, then we'll use the latter
path:=extractFilePath(resource)+COMMENTS_FILE;
if not (lpION in loadPrefs)
or fileExists(path) and not fileExists(extractFilePath(resource)+'descript.ion') then
  saveTextFile(path, setKeyInString(UnUTF(loadFile(path)), name, escapeNL(cmt)));

if not (lpION in loadPrefs) then exit;

path:=extractFilePath(resource)+'descript.ion';
try
  s:=loadDescriptionFile(path);
  cmt:=escapeIon(cmt); // that's how multilines are handled in this file
  i:=findNameInDescriptionFile(s, name);
  if i = 0 then // not found
    if cmt='' then // no comment, we are good
      exit
    else
      s:=s+quoteIfAnyChar(' ', name)+' '+cmt+CRLF // append
  else // found, then replace
    if cmt='' then
      replace(s, '', i, findEOL(s, i)) // remove the whole line
    else
      begin
      i:=nonQuotedPos(' ', s, i); // replace just the comment
      replace(s, cmt, i+1, findEOL(s, i, FALSE));
      end;
  if s='' then
    deleteFile(path)
  else
    saveTextFile(path, s);
except end;
end; // setDynamicComment

function Tfile.getParent():Tfile;
var
  p: TTreeNode;
begin
  if node = NIL then
    result := NIL
   else
    if isTemp() then
      result := getMainFile
     else
      try
        p := node.parent;
        if p = NIL then
          result := NIL
         else
          result := p.data
       except
         Result := NIL;
      end;
end; // getParent

function Tfile.getMainFile: TFile;
begin
  if isTemp then
    begin
      if Assigned(tempParent) then
        Result := tempParent.getMainFile
       else
        Result := NIL;
    end
   else
    Result := Self;
end;

function Tfile.getFirstChild: TFile;
var
  n: TTreeNode;
begin
  if isTemp or not isFolder then
    Result := NIL
   else
    begin
      n := node;
      if Assigned(n) then
        Result := nodeToFile(n.getFirstChild)
       else
        Result := NIL
        ;
    end;
end;

function Tfile.getNextSibling: TFile;
var
  n: TTreeNode;
begin
  n := node;
   if Assigned(n) then
        Result := nodeToFile(n.getNextSibling)
    else
      Result := NIL;
end;

function Tfile.getDLcount():integer;
begin
if isFolder() then result:=getDLcountRecursive()
else if isTemp() then result:=autoupdatedFiles.getInt(resource)
else result:=FDLcount;
end; // getDLcount

procedure Tfile.setDLcount(i:integer);
begin
if isTemp() then autoupdatedFiles.setInt(resource, i)
else FDLcount:=i;
end; // setDLcount

function Tfile.getDLcountRecursive():integer;
var
  i: integer;
  f: Tfile;
begin
if not isFolder() then
  begin
  result:=DLcount;
  exit;
  end;
result:=0;
if node = NIL then exit;
f := getFirstChild();
if not isTemp() then
  while assigned(f) do
    begin
      if f.isFolder() then
        inc(result, f.getDLcountRecursive())
       else
        inc(result, f.FDLcount);
    f := f.getNextSibling();
    end;
if isRealFolder() then
  for i:=0 to autoupdatedFiles.count-1 do
    if ansiStartsText(resource, autoupdatedFiles[i]) then
      inc(result, autoupdatedFiles.getIntByIdx(i));
end; // getDLcountRecursive

function Tfile.diskfree():int64;
begin
if FA_VIRTUAL in flags then result:=0
else result:=diskSpaceAt(resource);
end; // diskfree

procedure Tfile.setupImage(sysIcons: Boolean; newIcon:integer);
begin
icon:=newIcon;
setupImage(sysIcons);
end; // setupImage

procedure Tfile.setupImage(sysIcons: Boolean; pNode: TTreeNode);
begin
  if pNode = NIL then
    pNode := node;
  if icon >= 0 then
    pNode.Imageindex := icon
   else
    pNode.ImageIndex := getIconForTreeview(sysIcons);
  pNode.SelectedIndex := pNode.imageindex;
end; // setupImage

function Tfile.getIconForTreeview(sysIcons: Boolean):integer;
begin
if FA_UNIT in flags then result:=ICON_UNIT
else if FA_ROOT in flags then result:=ICON_ROOT
else if FA_LINK in flags then result:=ICON_LINK
else
  if FA_FOLDER in flags then
    if FA_VIRTUAL in flags then result:=ICON_FOLDER
    else result:=ICON_REAL_FOLDER
  else
    if sysIcons and (resource > '') then
      result:=getImageIndexForFile(resource) // skip iconsCache
    else
      result:=ICON_FILE;
end; // getIconForTreeview

function Tfile.relativeURL(fullEncode:boolean=FALSE):string;
begin
if isLink() then result:=xtpl(resource, ['%ip%', defaultIP])
else if isRoot() then result:=''
else result:=encodeURL(name, fullEncode)+if_(isFolder(),'/')
end;

function Tfile.getFolder():string;
var
  f: Tfile;
  s: string;
begin
result:='/';
f:=parent;
while assigned(f) and assigned(f.parent) do
  begin
  result:='/'+f.name+result;
  f:=f.parent;
  end;
if not isTemp() then exit;
f:=parent; // f now points to the non-temporary ancestor item
s:=extractFilePath(resource);
s:=copy( s, length(f.resource)+2, length(s) );
result:=result+xtpl(s, ['\','/']);
end; // getFolder

function Tfile.isDLforbidden():boolean;
var
  f: Tfile;
begin
// the flag can be in this node
result:=FA_DL_FORBIDDEN in flags;
if result or not isTemp() then exit;
f:=nodeToFile(node);
result:=assigned(f) and (FA_DL_FORBIDDEN in f.flags);
end; // isDLforbidden

function Tfile.isNew():boolean;
var
  t: Tdatetime;
begin
if FA_TEMP in flags then t:=mtime
else t:=atime;
result:=(filesStayFlaggedForMinutes > 0)
  and (trunc(abs(now()-t)*24*60) <= filesStayFlaggedForMinutes)
end; // isNew

function Tfile.getRecursiveDiffTplAsStr(outInherited:Pboolean=NIL; outFromDisk:Pboolean=NIL):string;
var
  basePath, runPath, s, fn, diff: string;
  f: Tfile;
  first: boolean;

  function add2diff(const s:string):boolean;
  begin
  result:=FALSE;
  if s = '' then exit;
  diff:=s
    + ifThen((diff > '') and not ansiEndsStr(CRLF,s), CRLF)
    + ifThen((diff > '') and not isSectionAt(@diff[1]), '[]'+CRLF)
    + diff;
  result:=TRUE;
  end; // add2diff

begin
result:='';
diff:='';
runPath:='';
f:=self;
if assigned(outInherited) then outInherited^:=FALSE;
if assigned(outFromDisk) then outFromDisk^:=FALSE;
first:=TRUE;
while assigned(f) do
  begin
  if f.isRealFolder() then
    if f.isTemp() then
      begin
      basePath:=excludeTrailingPathDelimiter( extractFilePath(f.parent.resource) );
      runPath:=copy(f.resource, length(basePath)+2, length(f.resource));
      f:=f.parent;
      end
    else
      begin
      basePath:=excludeTrailingPathDelimiter(extractFilePath(f.resource));
      runPath:=extractFileName(f.resource);
      end;
  // temp realFolder will cycle more than once, while non-temp only once
  while runPath > '' do
    begin
    if add2diff(UnUTF(loadFile(basePath+'\'+runPath+'\'+DIFF_TPL_FILE))) and assigned(outFromDisk) then
      outFromDisk^:=TRUE;
    runPath:=excludeTrailingPathDelimiter(ExtractFilePath(runPath));
    end;
  // consider the diffTpl in node
  s:=f.diffTpl;
  if (s > '') and singleLine(s) then
    begin
    // maybe it refers to a file
    fn:=trim(s);
    if fileExists(fn) then doNothing()
    else if fileExists(exePath+fn) then fn:=exePath+fn
    else if fileExists(f.resource+'\'+fn) then fn:=f.resource+'\'+fn;
    if fileExists(fn) then
      s := UnUTF(loadFile(fn));
    end;
  if add2diff(s) and not first and assigned(outInherited) then
    outInherited^:=TRUE;
  f:=f.parent;
  first:=FALSE;
  end;
for s in sortArrayF(getFiles(exePath+'*.diff.tpl')) do
  add2diff(UnUTF(loadFileA(s)));
result:=diff;
end; // getRecursiveDiffTplAsStr

function Tfile.getDefaultFile():Tfile;
var
  f: Tfile;
  mask, s: string;
  sr: TsearchRec;
begin
result:=NIL;
mask:=getRecursiveFileMask();
if mask = '' then exit;

  f := getFirstChild();
{ if this folder has been dinamically generated, the treenode is not actually
{ its own, and we won't care about subitems }
if not isTemp() then
  while assigned(f) do
    begin
      if (FA_LINK in f.flags) or f.isFolder()
        or not fileMatch(mask, f.name) or not fileExists(f.resource) then
        f := f.getNextSibling()
       else
        begin
          result:=f;
          exit;
        end;
    end;

if not isRealFolder() or not sysutils.directoryExists(resource) then exit;

while mask > '' do
  begin
  s:=chop(';', mask);
  if findFirst(resource+'\'+s, faAnyFile-faDirectory, sr) <> 0 then continue;
  try
    // encapsulate for returning
    result := Tfile.createTemp(resource+'\'+sr.name, self); // temporary nodes are bound to the parent's node
  finally findClose(sr) end;
  exit;
  end;
end; // getDefaultFile

function Tfile.shouldCountAsDownload():boolean;
var
  f: Tfile;
  mask: string;
begin
result:=not (FA_DONT_COUNT_AS_DL in flags);
if not result then exit;
f:=self;
  repeat
  mask:=f.dontCountAsDownloadMask;
  f:=f.parent;
  until (f = NIL) or (mask > '');
if mask > '' then result:=not fileMatch(mask, name)
end; // shouldCountAsDownload

procedure Tfile.lock();
begin fLocked:=TRUE end;

procedure Tfile.unlock();
begin fLocked:=FALSE end;

function Tfile.isLocked():boolean;
var
  f: Tfile;
begin
// check ancestors (first, because it is always fast)
f:=self;
  repeat
  result:=f.locked;
  f:=f.parent;
  until (f = NIL) or result;
// check descendants
  f := getFirstChild();
  while assigned(f) and not result do
  begin
    result := f.isLocked();
    if Result then
      Exit
     else
      f := f.getNextSibling();
  end;
end; // isLocked

procedure Tfile.recursiveApply(callback:TfileCallback; par:NativeInt=0; par2:NativeInt=0);
var
  f, fNext: TFile;
  r: TfileCallbackReturn;
begin
r:=callback(self, FALSE, par, par2);
if FCB_DELETE in r then
  begin
    if Assigned(node) then
      node.delete();
    exit;
  end;
if FCB_NO_DEEPER in r then exit;
f := getFirstChild();
while assigned(f) do
  begin
  fNext:=f.getNextSibling(); // "next" must be saved this point because the callback may delete the current node
  f.recursiveApply(callback, par, par2);
  f := fNext;
  end;
if FCB_RECALL_AFTER_CHILDREN in r then
  begin
  r:=callback(self, TRUE, par, par2);
  if FCB_DELETE in r then
    if Assigned(node) then
      node.delete();
  end;
end; // recursiveApply

function Tfile.hasRecursive(attributes: TfileAttributes; orInsteadOfAnd:boolean=FALSE; outInherited:Pboolean=NIL):boolean;
var
  f: Tfile;
begin
result:=FALSE;
f:=self;
if assigned(outInherited) then outInherited^:=FALSE;
while assigned(f) do
  begin
  result:=orInsteadOfAnd and (attributes*f.flags <> [])
    or (attributes*f.flags = attributes);
  if result or f.isRoot then exit;
  f:=f.parent;
  if assigned(outInherited) then outInherited^:=TRUE;
  end;
if assigned(outInherited) then outInherited^:=FALSE; // grant it is set only if result=TRUE
end; // hasRecursive

function Tfile.hasRecursive(attribute: TfileAttribute; outInherited:Pboolean=NIL):boolean;
begin result:=hasRecursive([attribute], FALSE, outInherited) end;

function Tfile.accessFor(cd:TconnDataMain):boolean;
begin
if cd = NIL then result:=accessFor('', '')
else result:=accessFor(cd.usr, cd.pwd)
end; // accessFor

function Tfile.accessFor(username, password:string):boolean;
var
  a: Paccount;
  f: Tfile;
  list: TStringDynArray;
begin
result:=FALSE;
if isFile() and isDLforbidden() then exit;
result:=FALSE;
f:=self;
while assigned(f) do
  begin
  list:=f.accounts[FA_ACCESS]; // shortcut

  if (username = '') and stringExists(USER_ANONYMOUS, list, TRUE) then break;
  // first check in user/pass
  if (f.user > '') and sameText(f.user, username) and (f.pwd = password) then break;
  // then in accounts
  if assigned(list) then
    begin
    a:=getAccount(username);

    if stringExists(USER_ANYONE, list, TRUE) then break;
    // we didn't match the user/pass, but this file is restricted, so we must have an account at least to access it
    if assigned(a) and (a.pwd = password) and
      (stringExists(USER_ANY_ACCOUNT, list, TRUE) or (findEnabledLinkedAccount(a, list, TRUE) <> NIL))
    then break;

    exit;
    end;
  // there's a user/pass restriction, but the password didn't match (if we got this far). We didn't exit before to give accounts a chance.
  if f.user > '' then exit;

  f:=f.parent;
  end;
result:=TRUE;

// in case the file is not protected, we must not accept authentication credentials belonging to disabled accounts
if (username > '') and (f = NIL) then
  begin
  a:=getAccount(username);
  if a = NIL then exit;
  result:=a.enabled;
  end;
end; // accessFor

function Tfile.getRecursiveFileMask():string;
var
  f: Tfile;
begin
f:=self;
  repeat
  result:=f.defaultFileMask;
  if result > '' then exit;
  f:=f.parent;
  until f = NIL;
end; // getRecursiveFileMask

function Tfile.getAccountsFor(action:TfileAction; specialUsernames:boolean=FALSE; outInherited:Pboolean=NIL):TstringDynArray;
var
  f: Tfile;
begin
result:=NIL;
f:=self;
if assigned(outInherited) then outInherited^:=FALSE;
while assigned(f) do
  begin
  for var s in f.accounts[action] do
  	begin
    if (s = '')
    or (action = FA_UPLOAD) and not f.isRealFolder() then // we must ignore this setting
      continue;

    if specialUsernames and (s[1] = '@')
    or accountExists(s, specialUsernames) then // we admit groups only if specialUsernames are admitted too
      addString(s, result);
    end;
  if (action = FA_ACCESS) and (f.user > '') then
    addString(f.user, result);
  if assigned(result) then
    exit;
  if assigned(outInherited) then
    outInherited^:=TRUE;
  f:=f.parent;
  end;
end; // getAccountsFor

procedure Tfile.getFiltersRecursively(var files,folders:string);
var
  f: Tfile;
begin
files:='';
folders:='';
f:=self;
while assigned(f) do
  begin
  if (files = '') and (f.filesfilter > '') then files:=f.filesFilter;
  if (folders = '') and (f.foldersfilter > '') then folders:=f.foldersFilter;
  if (files > '') and (folders > '') then break;
  f:=f.parent;
  end;
end; // getFiltersRecursively


function nodeToFile(n:TtreeNode):Tfile; inline;
begin if n = NIL then result:=NIL else result:=Tfile(n.data) end;


end.
