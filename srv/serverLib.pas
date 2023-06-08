unit serverLib;

interface

uses
  // delphi libs
  Windows, Messages,
  mormot.core.base,
 {$IFDEF FMX}
  FMX.Forms,
  FMX.Controls,
  FMX.Graphics, System.UITypes,
  FMX.TreeView,
 {$ELSE ~FMX}
  Graphics,
  Forms,
  ComCtrls,
 {$ENDIF FMX}
  math, Types, SysUtils,
  iniFiles,
  srvConst,
  HSLib, srvClassesLib, fileLib;

type

  TShowPrefs = set of (spUseSysIcons, spHttpsUrls, spFoldersBefore, spLinksBefore,
                       spNoPortInUrl, spEncodeNonascii, spEncodeSpaces, spCompressed, spNoWaitSysIcons);


  TLogPrefs = set of (logBanned, logIcons, logBrowsing, logProgress,
                      logServerstart, logServerstop, logconnections,
                      logDisconnections, logUploads);

  TfileListing = class
    actualCount: integer;
   public
    dir: array of Tfile;
    timeout: TDateTime;
    ignoreConnFilter: boolean;
    constructor create();
    destructor Destroy; override;
    function fromFolder(loadPrefs: TLoadPrefs; folder: Tfile; cd:TconnDataMain; recursive: boolean=FALSE;
      limit:integer=-1; toSkip: Integer=-1; doClear: Boolean=TRUE): Integer;
    procedure sort(foldersBefore, linksBefore: Boolean; cd:TconnDataMain; const def: String='');
  end;

  TOnGetSP = function: TShowPrefs of object;
  TOnGetLP = function: TLoadPrefs of object;

//  TmacroCB = function(fs: TFileServer; const fullMacro: string; pars: TPars; cbData: pointer): string;
  TmacroData = record
    cd: TconnDataMain;
    tpl: Ttpl;
    folder, f: Tfile;
    afterTheList, archiveAvailable, hideExt, breaking: boolean;
    aliases, tempVars: THashedStringList;
    table: TStringDynArray;
    logTS: boolean;
   end;

  TFileServer = class;

  TMacroApplyFunc = function(fs: TFileServer; var txt: String; var md: TmacroData; removeQuotings: boolean=true): boolean;
  TLoadVFSProg = procedure(Sender: TObject; PRC: Real; var Cancel: Boolean);

  {$IFDEF FMX}
  TTreeNode = TTreeViewItem;
  {$ENDIF FMX}

  TFileServer = class
    userPwdHashCache2: Tstr2str;
    rootFile: Tfile;
//    fSP: TShowPrefs;
    fOnGetSP: TOnGetSP;
    fOnGetLP: TOnGetLP;
    fOnAddingItems: TProc;
   private
    constructor Create; OverLoad;
   public
    tpl: Ttpl; // template for generated pages
    tryApplyMacrosAndSymbols: TMacroApplyFunc;
    stopAddingItems: Boolean;
    constructor Create(pTryApplyMacrosAndSymbols: TMacroApplyFunc;
                       pOnGetSP: TOnGetSP; pOnGetLP: TOnGetLP;
                       pOnAddingItems: TProc); OverLoad;
    destructor Destroy;
    function  initRoot(pTree: TTreeView): TFile;
    function  initRootWithNode(pTree: TTreeView): TFile;
    procedure clearNodes;
    function  encodeURLA(const s: string; fullEncode: Boolean=FALSE): RawByteString;
    function  encodeURLW(const s: string; fullEncode: Boolean=FALSE): String;
    function  pathTill(fl: Tfile; root: Tfile=NIL; delim: char='\'): String;
    function  url(f: Tfile; fullEncode: boolean=FALSE):string;
    function  parentURL(f: Tfile): string;
    function  fullURL(f: Tfile; const ip, user, pwd: String): String; OverLoad;
    function  fullURL(f: Tfile; ip: String=''): String; OverLoad;
    function  tplFromFile(f: Tfile): Ttpl;
    function  getAFolderPage(folder: Tfile; cd: TconnDataMain; otpl: TTpl;
                 const lp: TLoadPrefs; const sp: TShowPrefs;
                 isPwdInPages, isMacrosLog: Boolean): String;
    function  findFilebyURL(url: string; const lp: TLoadPrefs; parent: Tfile=NIL; allowTemp: boolean=TRUE): Tfile; OverLoad;
    function  findFilebyURL(const url: String; parent: Tfile= NIL; allowTemp: Boolean=TRUE): Tfile; OverLoad;
    function  fileExistsByURL(const url: String; lp: TLoadPrefs): Boolean;
    function  protoColon(sp: TShowPrefs): String;
    function  addFileRecur(f: TFile; parent: TFile=NIL): TFile; OverLoad;
    function  addFileRecur(f: Tfile; parent: TTreeNode=NIL): Tfile; OverLoad;
    function  addFileRecur(f: Tfile; parent: TTreeNode; var newNode: TTreeNode): Tfile; OverLoad;
    function  addFileInt(f: Tfile; parent: TFile): Tfile;
    procedure setVFS(const vfs: RawByteString; pf: TFile; onProgress: TLoadVFSProg);
    procedure setVFSJZ(const vfs: RawByteString; node: Ttreenode=NIL; onProgress: TLoadVFSProg = NIL);
    function  removeFile(f: Tfile): Boolean; OverLoad;
    function  removeFile(node: TTreeNode): Boolean; OverLoad;
    procedure fileDeletion(f: TFile);
    function  existsNodeWithName(const name: string; parent: Ttreenode): boolean;
    function  getUniqueNodeName(const start: string; parent: Ttreenode): string;
    function  getRootNode: TTreeNode;
    procedure getPage(const sectionName: String; data: TconnDataMain; f: Tfile=NIL; tpl2use: Ttpl=NIL);
    procedure compressReply(cd: TconnDataMain);
    function  countDownloads(const ip: String=''; const user: String=''; f:Tfile=NIL): Integer;
//    procedure httpEventNG(event: ThttpEvent; conn: ThttpConn; preventLeeching: Boolean);
    function  getSP: TShowPrefs;
    function  getLP: TLoadPrefs;
    property  onGetSP: TOnGetSP read fOnGetSP; // write fOnGetSP;
    property  onGetLP: TOnGetLP read fOnGetLP; // write fOnGetLP;
    property  onAddingItems: TProc read fOnAddingItems write fOnAddingItems;
   end;

  TconnData = class(TconnDataMain)  // data associated to a client connection
  private
    fLastFile: Tfile;
    procedure setLastFile(f: Tfile);
  public
    guiData: TObject;
//    countAsDownload: boolean; // cache the value for the Tfile method
    { cache User-Agent because often retrieved by connBox.
    { this value is filled after the http request is complete (HE_REQUESTED),
    { or before, during the request as we get a file (HE_POST_FILE). }
    deleting: boolean;      // don't use, this item is about to be discarded
    nextDloadScreenUpdate: Tdatetime; // avoid too fast updating during download
    preReply: TpreReply;
    lastBytesSent, lastBytesGot: int64; // used for print to log only the recent amount of bytes
    bytesGotGrouping, bytesSentGrouping: record
      bytes: integer;
      since: Tdatetime;
     end;
    { here we put just a pointer because the file type would triplicate
    { the size of this record, while it is NIL for most connections }
    f: ^file; // uploading file handle

    property lastFile: Tfile read fLastFile write setLastFile;
    constructor create(conn: ThttpConn; pGuiData: TObject);
    destructor Destroy; override;
    function accessFor(f: TFile): Boolean;
   end; // Tconndata

type
  TstringIntPairs = array of record
    str: string;
    int: integer;
   end;

var
  iconMasks: TstringIntPairs;
  eventScripts: Ttpl;
  currentCFG: string;
  currentCFGhashed: THashedStringList;

  procedure kickByIP(const ip: String);
  function  getAcceptOptions(): TstringDynArray;
  function  uptimestr(): String;
  function  startServer(): Boolean;
  procedure stopServer();
  function  restartServer(): boolean;
  function  changePort(const newVal: String): Boolean;
  function noLimitsFor(account: Paccount): Boolean;
  function conn2data(p: Tobject): TconnData; inline; overload;
  function conn2data(i: integer): TconnData; inline; overload;

implementation

uses
  strutils, Classes, JSON,
  OverbyteIcsWSocket,
  OverbyteIcsZlibHigh,
//  scriptLib,
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Generics.Collections,
  {$ELSE USE_MORMOT_COLLECTIONS}
  mormot.core.collections,
  {$ENDIF USE_MORMOT_COLLECTIONS}
  mormot.core.json,
  RDUtils, RDFileUtil, RDGlobal, //AnsiClasses,
  RnQCrypt, RnQzip, RnQLangs, RnQDialogs, RnQJSON,
  IconsLib,
  srvUtils, parserLib, srvVars;

constructor TfileListing.create();
begin
  dir := NIL;
end; // create

destructor TfileListing.destroy;
var
  i: integer;
begin
  for i:=0 to length(dir)-1 do
    freeIfTemp(dir[i]);
  inherited destroy;
end; // destroy

procedure TfileListing.sort(foldersBefore, linksBefore: Boolean; cd: TconnDataMain; const def: String='');
var
  rev: boolean;
  sortBy: ( SB_NAME, SB_EXT, SB_SIZE, SB_TIME, SB_DL, SB_COMMENT );

  function compareExt(const f1, f2: String): Integer;
  begin result := ansiCompareText(extractFileExt(f1), extractFileExt(f2)) end;

  function compareFiles(item1, item2: Pointer): Integer;
  var
    f1, f2: Tfile;
  begin
    f1 := item1;
    f2 := item2;
    if linksBefore and (f1.isLink() <> f2.isLink()) then
      begin
        if f1.isLink() then
          result := -1
         else
          result := +1;
        exit;
      end;
    if foldersBefore and (f1.isFolder() <> f2.isFolder()) then
      begin
        if f1.isFolder() then
          result := -1
         else
          result := +1;
        exit;
      end;
    result := 0;
    case sortby of
      SB_SIZE: result := compare_(f1.size, f2.size);
      SB_TIME: result := compare_(f1.mtime, f2.mtime);
      SB_DL: result := compare_(f1.DLcount, f2.DLcount);
      SB_EXT:
        if not f1.isFolder() and not f2.isFolder() then
          result := compareExt(f1.name, f2.name);
      SB_COMMENT: result := ansiCompareText(f1.comment, f2.comment);
      end;
    if result = 0 then // this happen both for SB_NAME and when other comparisons result in no difference
      result := ansiCompareText(f1.name,f2.name);
    if rev then
      result := -result;
  end; // compareFiles

  procedure qsort(left, right: Integer);
  var
    split, t: Tfile;
    i, j: integer;
  begin
    if left >= right then
      exit;

    if cd.conn.state = HCS_DISCONNECTED then
      exit;
  //  application.ProcessMessages();
  //  if cd.conn.state = HCS_DISCONNECTED then exit;

    i := left;
    j := right;
    split := dir[(i+j) div 2];
      repeat
        while compareFiles(dir[i], split) < 0 do
          inc(i);
        while compareFiles(split, dir[j]) < 0 do
          dec(j);
        if i <= j then
          begin
            t := dir[i];
            dir[i] := dir[j];
            dir[j] := t;

            inc(i);
            dec(j);
          end
      until i > j;
    if left < j then
      qsort(left, j);
    if i < right then
      qsort(i, right);
  end; // qsort

  procedure check1(var flag: boolean; const val: String);
  begin
    if val > '' then
      flag := val='1'
  end;

var
  v: string;
begin
  // caching
  //foldersBefore:=mainfrm.foldersBeforeChk.checked;
  //linksBefore:=mainfrm.linksBeforeChk.checked;

  v := first([def, defSorting, 'name']);
  rev := FALSE;
  if assigned(cd) then
    with cd.urlvars do
      begin
        v := first(values['sort'], v);
        rev := values['rev'] = '1';

        check1(foldersBefore, values['foldersbefore']);
        check1(linksBefore, values['linksbefore']);
      end;
  if ansiStartsStr('!', v) then
    begin
      delete(v, 1,1);
      rev := not rev;
    end;
  if v = '' then
    exit;
  case v[1] of
    'n': sortBy:=SB_NAME;
    'e': sortBy:=SB_EXT;
    's': sortBy:=SB_SIZE;
    't': sortBy:=SB_TIME;
    'd': sortBy:=SB_DL;
    'c': sortBy:=SB_COMMENT;
   else
    exit; // unsupported value
  end;
  qsort( 0, length(dir)-1 );
end; // sort

function loadDescriptionFile(const lp: TLoadPrefs; const fn: String): String;
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

function escapeIon(const s: String): String;
begin
// this escaping method (and also the 2-bytes marker) was reverse-engineered from Total Commander
  result := escapeNL(s);
  if result <> s then
    result := result+#4#$C2;
end; // escapeIon

function unescapeIon(s: String): String;
begin
  if ansiEndsStr(#4#$C2, s) then
    begin
      setLength(s, length(s)-2);
      s := unescapeNL(s);
    end;
  result := s;
end; // unescapeIon

procedure loadIon(const lp: TLoadPrefs; const path: String; comments: TstringList);
var
  s, l, fn: string;
begin
  //if not mainfrm.supportDescriptionChk.checked then exit;
  s := loadDescriptionFile(lp, path);
  while s > '' do
    begin
      l := chopLine(s);
      if l = '' then
        continue;
      fn := chop(nonQuotedPos(' ', l), l);
      comments.add(dequote(fn)+'='+trim(unescapeIon(l)));
    end;
end; // loadIon

function isCommentFile(const lp: TLoadPrefs; const fn: String): Boolean;
begin
  result := (fn=COMMENTS_FILE)
    or (lpSnglCmnt in lp) and isExtension(fn, COMMENT_FILE_EXT)
    or (lpION in lp) and sameText('descript.ion',fn)
end; // isCommentFile

function getFiles(const mask: String): Types.TStringDynArray;
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
    commentMasks: Types.TStringDynArray;

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
    namesInVFS: Types.TStringDynArray;
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

  comments := THashedStringList.create();
  try
    comments.caseSensitive := FALSE;
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

        f.comment := comments.values[sr.name];
        if f.comment = '' then
          f.comment := getCommentByMaskFor(sr.name);
        f.comment := macroQuote(unescapeNL(f.comment));

        f.size := 0;
        if f.isFile() then
          if FA_SOLVED_LNK in f.flags then
            f.size := sizeOfFile(f.resource)
          else
            f.size := int64(sr.FindData.nFileSizeHigh) shl 32 + sr.FindData.nFileSizeLow;
        f.mtime := filetimeToDatetime(sr.FindData.ftLastWriteTime);
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

constructor TFileServer.Create;
begin
  Self.rootFile := NIL;
  userPwdHashCache2 := NIL;
end;

constructor TFileServer.Create(pTryApplyMacrosAndSymbols: TMacroApplyFunc;
                       pOnGetSP: TOnGetSP; pOnGetLP: TOnGetLP;
                       pOnAddingItems: TProc);
begin
  tryApplyMacrosAndSymbols := pTryApplyMacrosAndSymbols;
  fOnGetSP := pOnGetSP;
  fOnGetLP := pOnGetLP;
  onAddingItems := pOnAddingItems;
  Self.rootFile := NIL;
  userPwdHashCache2 := NIL;
  tpl := Ttpl.create('', defaultTpl);
end;

destructor TFileServer.Destroy;
begin
  tpl.free;
  tpl := NIL;
end;

function TFileServer.initRoot(pTree: TTreeView): TFile;
begin
  rootFile := Tfile.createVirtualFolder(pTree, '/');
  rootFile.flags := rootFile.flags+[FA_ROOT, FA_ARCHIVABLE];
  rootFile.dontCountAsDownloadMask := '*.htm;*.html;*.css';
  rootFile.defaultFileMask := 'index.html;index.htm;default.html;default.htm';
  Result := rootFile;
end;

function TFileServer.initRootWithNode(pTree: TTreeView): TFile;
begin
  result := initRoot(pTree);
  addFileInt(result, NIL);
end;

procedure TFileServer.clearNodes;
var
  n: TTreeNode;
begin
  n := getRootNode;
  if assigned(n) then
 {$IFDEF FMX}
    n.Free;
 {$ELSE ~FMX}
    n.Delete();
 {$ENDIF FMX}
end;

function TFileServer.encodeURLA(const s: String; fullEncode:boolean=FALSE): RawByteString;
var
  r: RawByteString;
  sp: TShowPrefs;
begin
  sp := getSP;
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
  sp := getSP;
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

function TFileServer.findFilebyURL(const url: string; parent:Tfile=NIL; allowTemp:boolean=TRUE): Tfile;
begin
  Result := findFilebyURL(url, getLP, parent, allowTemp);
end;

function TFileServer.findFilebyURL(url:string; const lp: TLoadPrefs; parent:Tfile=NIL; allowTemp:boolean=TRUE):Tfile;

  procedure workTheRestByReal(const rest: String; f: Tfile);
  var
    s: string;
  begin
    if not allowTemp then
      exit;

    s := rest; // just a shortcut
    if dirCrossing(s) then
      exit;

    s := includeTrailingPathDelimiter(f.resource)+s; // we made the ".." test before, so relative paths are allowed in the VFS
    if not fileOrDirExists(s) and fileOrDirExists(s+'.lnk') then
      s := s+'.lnk';
    if not fileOrDirExists(s) or not hasRightAttributes(LP, s) then
      exit;
    // found on disk, we need to build a temporary Tfile to return it
    result := Tfile.createTemp(f.mainTree, s, f); // temp nodes are bound to parent's node
    // the temp file inherits flags from the real folder
    if FA_DONT_LOG in f.flags then
      include(result.flags, FA_DONT_LOG);
    if not (FA_BROWSABLE in f.flags) then
      exclude(result.flags, FA_BROWSABLE);
  end; // workTheRestByReal

var
  parts: Types.TStringDynArray;
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
  if (url = '') or anycharIn(#0, url) then
    exit;
  if parent = NIL then
    parent := rootFile;
  url := xtpl(url, ['//', '/']);
  if url[1] = '/' then
    begin
      delete(url, 1,1);  // remove initial "/"
      parent := rootFile; // it's an absolute path, not relative
    end;
  excludeTrailingString(url, '/');
  parts := split('/', url);
  if not workDots() then
    exit;

  if parent.isTemp() then
    begin
      workTheRestByReal(url, parent);
      exit;
    end;

  cur := parent.node;   // we'll move using treenodes
  for var i: integer :=0 to length(parts)-1 do
   begin
    s := parts[i];
    if s = '' then exit; // no support for null filenames
    found := FALSE;
    // search inside the VFS
   {$IFDEF FMX}
    if cur.Count > 0 then
     for var ii in [0..(cur.count-1)] do
      begin
        n := cur.Items[ii];
  //    found:=stringExists(n.text, s) or sameText(n.text, UTF8toAnsi(s));
  //        found := stringExists(n.text, s) or sameText(n.text, s);
        found := sameText(n.text, s);
        if found then
          break;
      end;
   {$ELSE ~FMX}
    n:=cur.getFirstChild();
    while assigned(n) do
    begin
//    found := stringExists(n.text, s) or sameText(n.text, UTF8toAnsi(s));
//        found := stringExists(n.text, s) or sameText(n.text, s);
      found := sameText(n.text, s);
    if found then
      break;
    n := n.getNextSibling();
    end;
   {$ENDIF FMX}
    if not found then // this piece was not found the virtual way
     begin
      f := nodeToFile(cur);
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
    if cur = NIL then
      exit;
   end;
  result := nodeToFile(cur);
end; // findFileByURL

function TFileServer.fileExistsByURL(const url: string; lp: TLoadPrefs): boolean;
var
  f: Tfile;
begin
  f := self.findFilebyURL(url, lp);
  result := assigned(f);
  freeIfTemp(f);
end; // fileExistsByURL

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
var
  s, k, base: string;
begin
  if userPwdHashCache2 = NIL then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    userPwdHashCache2 := Tstr2str.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
    userPwdHashCache2 := Collections.NewKeyValue<String, String>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  base := fullURL(f, ip)+'?';
  k := user + ':' + pwd;
  if not userPwdHashCache2.TryGetValue(k, s) then
    begin
      s := 'mode=auth&u='+encodeURLW(user);
      s := s + '&s2=' + strSHA256(s+pwd); // sign with password
      userPwdHashCache2.add(k, s);
    end;
  result := base + s;
end; // fullURL

function TFileServer.fullURL(f: Tfile; ip: String=''): String;
var
  sp: TShowPrefs;
begin
  sp := getSP();
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

function TFileServer.tplFromFile(f: Tfile): Ttpl;
begin
  result := Ttpl.create(f.getRecursiveDiffTplAsStr(), tpl)
end;


function TFileServer.getAFolderPage(folder: Tfile; cd: TconnDataMain; otpl: TTpl;
                 const lp: TLoadPrefs; const sp: TShowPrefs;
                 isPwdInPages, isMacrosLog: Boolean): String;
var
  baseurl, list, fileTpl, folderTpl, linkTpl: string;
  table: Types.TStringDynArray;
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

  procedure handleItem(f: Tfile);
  var
    type_, s, url, fingerprint, itemFolder: string;
    nonPerc: Types.TStringDynArray;
  begin
    if not f.isLink and ansiContainsStr(f.resource, '?') then
      exit; // unicode filename?   //mod by mars

//    if f.size > 0 then
//      inc(totalBytes, f.size);

  // build up the symbols table
    md.table := table;
    nonPerc := NIL;
    if f.icon >= 0 then
      begin
        s := '~img'+intToStr(f.icon);
        addArray(nonPerc, ['~img_folder', s, '~img_link', s]);
      end;
    if f.isFile() then
      if img_file and (f.icon >= 0) then
        addArray(nonPerc, ['~img_file', '~img'+intToStr(f.getSystemIcon())])
//       else if img_file and (spUseSysIcons in SP ) and (spNoWaitSysIcons in SP) then
//        addArray(nonPerc, ['~img_file', f.relativeURL() + '?mode=icon'])
       else if img_file and (spUseSysIcons in SP ) then
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
        s := hasher.getHashFor(f.resource);
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

    s := xtpl(s, nonPerc);
    md.f:=f;
    tryApplyMacrosAndSymbols(self, s, md, FALSE);
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
  tryApplyMacrosAndSymbols(self, result, md, FALSE);

  if useList then
    begin
      // cache these values
      fileTpl := xtpl(diffTpl['file'], table);
      folderTpl := xtpl(diffTpl['folder'], table);
      linkTpl := xtpl(diffTpl['link'], table);
      // this may be heavy to calculate, only do it upon request
      img_file := pos('~img_file', fileTpl) > 0;

      // build %list% based on dir[]
      numberFolders:=0; numberFiles:=0; numberLinks:=0;
      totalBytes:=0;
      oneAccessible:=FALSE;
      fast:=TfastStringAppend.Create();
      listing := TfileListing.create();
      hasher := Thasher.create();
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
  try
    tryApplyMacrosAndSymbols(self, result, md)
   finally
    md.afterTheList:=FALSE
  end;
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

function TFileServer.existsNodeWithName(const name: string; parent: Ttreenode): boolean;
var
  n: Ttreenode;
begin
  result := FALSE;
  if parent = NIL then
    begin
      if Assigned(rootFile) then
        parent := rootFile.node;
    end;
  if parent = NIL then
    exit;
 {$IFDEF FMX}
  while parent.data.IsObject and not Tfile(parent.data.AsObject).isFolder() do
    parent := parent.ParentItem;
  if parent.Count > 0 then
   for var ii in [0..(parent.count-1)] do
    begin
      n := parent.Items[ii];
      result := sameText(n.text, name);
      if result then
        exit;
    end;
 {$ELSE ~FMX}
  while assigned(parent.data) and not Tfile(parent.data).isFolder() do
    parent := parent.parent;
  n := parent.getFirstChild();
  while assigned(n) do
  begin
    result := sameText(n.text, name);
    if result then
      exit;
    n := n.getNextSibling();
  end;
 {$ENDIF FMX}
end; // existsNodeWithName

function TFileServer.getUniqueNodeName(const start: string; parent: Ttreenode): string;
var
  i: integer;
begin
  result := start;
  if not Self.existsNodeWithName(result, parent) then
    exit;
  i := 2;
  repeat
    result := format('%s (%d)', [start,i]);
    inc(i);
  until not Self.existsNodeWithName(result, parent);
end; // getUniqueNodeName

function TFileServer.getRootNode: TTreeNode;
begin
  if Assigned(rootFile) then
    Result := rootFile.node
   else
    Result := NIL;
end;

procedure TFileServer.setVFS(const vfs: RawByteString; pf: TFile; onProgress: TLoadVFSProg);
resourcestring
  MSG_BETTERSTOP = #13'Going on may lead to problems.'
    +#13'It is adviced to stop loading.'
    +#13'Stop?';
  MSG_BADCRC = 'This file is corrupted (CRC).';
  MSG_NEWER_INCOMP='This file has been created with a newer and incompatible version.';
  MSG_ZLIB = 'This file is corrupted (ZLIB).';
  MSG_BAKAVAILABLE = 'This file is corrupted but a backup is available.'#13'Continue with backup?';

var
  data2: RawByteString;
//  f: Tfile;
  after: record
    resetLetBrowse: boolean;
   end;
  act: TfileAction;
  tlv: Ttlv;
  doCancel: Boolean;
  sp: TShowPrefs;

//  procedure parseAutoupdatedFiles(data: string);
  procedure parseAutoupdatedFiles();
  var
    fn: string;
    s: RawByteString;
  begin
    autoupdatedFiles.Clear();
    tlv.down();
    while tlv.pop(s) = FK_NODE do
      begin
      tlv.down();
      while not tlv.isOver() do
        case tlv.pop(s) of
          FK_NAME: fn:= UnUTF(s);
          FK_DLCOUNT: autoupdatedFiles.setInt(fn, int_(s));
          end;
      tlv.up();
      end;
    tlv.up();
  end; // parseAutoupdatedFiles

begin
  if vfs = '' then
    exit;
  if pf = NIL then // this is supposed to be always true when loading a vfs, and never recurring
    begin
      pf := Self.rootFile;
      uploadPaths := NIL;
      usersInVFS.reset();
      if isAnyMacroIn(vfs) then
        loadingVFS.macrosFound := TRUE;
    end;
  ZeroMemory(@after, sizeof(after));
  Assert(Assigned(pf));
  pf.DeleteChildren();
  sp := GetSP();
  tlv := Ttlv.create(vfs);
  while not tlv.isOver() do
    case tlv.pop(data2) of
      FK_ROOT:
        begin
        setVFS(data2, rootFile, onProgress);
        if loadingVFS.build < '109' then
          include(pf.flags, FA_ARCHIVABLE);
        end;
      FK_NODE:
        begin
          if Assigned(onProgress) then
            onProgress(Self, tlv.getPerc(), doCancel);
        if doCancel then
          exit;
        ;
        setVFS(data2, Self.addFileRecur(Tfile.create(pf.mainTree, ''), pf), onProgress);
        end;
      FK_COMPRESSED_ZLIB:
        { Explanation for the #0 workaround.
        { I found an uncompressable vfs file, with ZDecompressStr2() raising an exception.
        { In the end i found it was missing a trailing #0, maybe do to an incorrect handling of strings
        { containing a trailing #0. Using a zlib wrapper there is some underlying C code.
        { I was unable to reproduce the bug, but i found that correct data doesn't complain if i add an extra #0. }
        try
  //        data := ZDecompressStr2(data+#0, 31);
          data2 := ZDecompressStr3(data2+#0, zsGZip);
          if isAnyMacroIn(data2) then
            loadingVFS.macrosFound:=TRUE;
          setVFS(data2, pf, onProgress);
         except
          MessageDlg(MSG_ZLIB, mtError, [mbOk])
        end;
      FK_FORMAT_VER:
        begin
        if length(data2) < 4 then // early versions: '1.0', '1.1'
          begin
          loadingVFS.resetLetBrowse:=TRUE;
          after.resetLetBrowse:=TRUE;
          end;
        if (int_(data2) > CURRENT_VFS_FORMAT)
        and (MessageDlg(MSG_NEWER_INCOMP+MSG_BETTERSTOP, mtError, [mbYes, mbNo], 0, mbNo, 90) = IDYES) then
          exit;
        end;
      FK_CRC:
        if str_(getCRC(tlv.getTheRest())) <> data2 then
          begin
          if loadingVFS.bakAvailable then
            if MessageDlg(MSG_BAKAVAILABLE, mtWarning, [mbYes, mbNo]) = IDYES then
              begin
              loadingVFS.useBackup:=TRUE;
              exit;
              end;
          if MessageDlg(MSG_BADCRC+MSG_BETTERSTOP, mtError, [mbYes, mbNo]) = IDYES then
            exit;
          end;
      FK_RESOURCE: pf.resource := UnUTF(data2);
      FK_NAME:
        begin
          pf.SetName(UnUTF(data2));
        end;
      FK_FLAGS: move(data2[1], pf.flags, min(length(data2), SizeOf(pf.flags)));
      FK_ADDEDTIME: pf.atime := dt_(data2);
      FK_COMMENT: pf.comment := UnUTF(data2);
      FK_USERPWD:
        begin
          data2 := decodeB64(data2);
          pf.user := UnUTF(chop(':', data2));
          pf.pwd := UnUTF(data2);
          usersInVFS.track(pf.user, pf.pwd);
        end;
      FK_USERPWD_UTF8:
        begin
          data2 := decodeB64(data2);
          pf.user := UnUTF(chop(':', data2));
          pf.pwd := UnUTF(data2);
          usersInVFS.track(pf.user, pf.pwd);
        end;
      FK_DLCOUNT: pf.DLcount := int_(data2);
      FK_ACCOUNTS: pf.accounts[FA_ACCESS] := splitU(data2, ';');
      FK_UPLOADACCOUNTS: pf.accounts[FA_UPLOAD] := splitU(data2, ';');
      FK_DELETEACCOUNTS: pf.accounts[FA_DELETE] := splitU(data2, ';');
      FK_FILESFILTER: pf.filesfilter := UnUTF(data2);
      FK_FOLDERSFILTER: pf.foldersfilter := UnUTF(data2);
      FK_UPLOADFILTER: pf.uploadFilterMask := UnUTF(data2);
      FK_REALM: pf.realm := UnUTF(data2);
      FK_DEFAULTMASK: pf.defaultFileMask := UnUTF(data2);
      FK_DIFF_TPL: pf.diffTpl := UnUTF(data2);
      FK_DONTCOUNTASDOWNLOADMASK: pf.dontCountAsDownloadMask := UnUTF(data2);
      FK_DONTCOUNTASDOWNLOAD: if boolean(data2[1]) then include(pf.flags, FA_DONT_COUNT_AS_DL);  // legacy, now moved into flags
  {$IFDEF HFS_GIF_IMAGES}
      FK_ICON_GIF: if data2 > '' then pf.setupImage(spUseSysIcons in sp, str2pic(data2));
  {$ELSE ~HFS_GIF_IMAGES}
      FK_ICON_GIF: if data2 > '' then pf.setupImage(spUseSysIcons in sp, strGif2pic(data2, 16));
      FK_ICON_PNG: if data2 > '' then pf.setupImage(spUseSysIcons in sp, str2pic(data2, 16));
      FK_ICON32_PNG: if data2 > '' then pf.setupImage(spUseSysIcons in sp, str2pic(data2, 32));
  {$ENDIF HFS_GIF_IMAGES}
  //    FK_AUTOUPDATED_FILES: parseAutoupdatedFiles(UnUTF(data2));
      FK_AUTOUPDATED_FILES: parseAutoupdatedFiles();
      FK_HFS_BUILD: loadingVFS.build := UnUTF(data2);
      FK_HEAD, FK_HFS_VER: ; // recognize these fields, but do nothing
      else loadingVFS.unkFK := TRUE;
      end;
  freeAndNIL(tlv);
  // legacy: in build #213 special usernames renamed for uniformity, and usernames are now sorted for faster access
  for act:=low(act) to high(act) do
    if loadingVFS.build < '213' then
      begin
      replaceString(pf.accounts[act], '*', USER_ANYONE);
      replaceString(pf.accounts[act], '*+', USER_ANY_ACCOUNT);
      uniqueStrings(pf.accounts[act]);
      sortArray(pf.accounts[act]);
      // for a little time, we tried to replace anyone with any+anon. it was a failed and had to revert.
      if stringExists(loadingVFS.build, ['211','212'])
      and stringExists(USER_ANY_ACCOUNT, pf.accounts[act])
      and stringExists(USER_ANONYMOUS, pf.accounts[act]) then
        begin
        removeString(USER_ANY_ACCOUNT, pf.accounts[act]);
        replaceString(pf.accounts[act], USER_ANONYMOUS, USER_ANYONE);
        end;
      end;

  if FA_VIS_ONLY_ANON in pf.flags then
    loadingVFS.visOnlyAnon := TRUE;
  if pf.isVirtualFolder() or pf.isLink() then
    pf.mtime := pf.atime;
  if assigned(pf.accounts[FA_UPLOAD]) and (pf.resource > '') then
    addString(pf.resource, uploadPaths);
  pf.setupImage(spUseSysIcons in sp);
  if after.resetLetBrowse then
    pf.recursiveApply(setBrowsable, integer(FA_BROWSABLE in pf.flags));

  if Assigned(pf.Node) then
    pf.Node.expanded := TRUE;
end;

procedure TFileServer.setVFSJZ(const vfs: RawByteString; node: Ttreenode=NIL; onProgress: TLoadVFSProg = NIL);
resourcestring
  MSG_MISS_J = 'Missing "VFS.json" file in archive';
  MSG_CORRUPTED_J = '"VFS.json" is not a JSON file';
  //
  function parseAcccounts(pArray: TJSONArray): TStringDynArray;
  begin
    SetLength(Result, pArray.Count);
    if pArray.Count > 0 then
      for var I := 0 to pArray.Count-1 do
        begin
          Result[i] := pArray.Items[i].Value;
        end;
  end;
  //
  procedure parseAutoupdatedFilesJ(data: TJSONValue);
  var
    i: Integer;
    fj: TJSONValue;
    v: TJSONValue;
    v2: TJSONValue;
    dc: Integer;
    cnt: Integer;
  begin
    i := 0;
    if (data is TJSONArray) then
      begin
        cnt := (data as TJSONArray).Count;
        if cnt > 0 then
         while i < cnt do
           begin
      //       fj := (data as TJSONArray).FindValue(intToStr(FK_NODE));
             fj := (data as TJSONArray).Items[i];
             if fj is TJSONObject then
               begin
                 v := (fj as TJSONObject).FindValue(IntToStr(FK_NAME));
                 if v <> NIL then
                   begin
                     v2 := (fj as TJSONObject).FindValue(IntToStr(FK_DLCOUNT));
                     if v2 <> NIL then
                       begin
                         autoupdatedFiles.setInt(v.Value, v2.GetValue<Integer>);
                       end;
                   end;
               end;
             inc(i);
           end;;
      end;
  end;
  //
var
  z: TZipFile;
  sp: TShowPrefs;

  procedure parseNodeInfo(pn: TFileNode; data: TJSONObject; prgFrom, prgTo: Real);
//  procedure parseNodeInfo(pn: TFileNode; data: TJSONValue);
  var
    jp: TJSONPair;
    v: String;
    pf: Tfile;
    en: TJSONObject.TEnumerator;
    prc: Real;
    step: Real;
    doCancel: Boolean;
  begin
    pf := nodeToFile(pn);
    doCancel := False;
    en := data.GetEnumerator;
    prc := prgFrom;
    if data.Count > 0 then
    begin
     step := (prgTo-prgFrom) / data.Count;
     for var i2: Integer := 0 to data.Count-1 do
      begin
        var dj := data.Pairs[i2];
        v := dj.JsonString.Value;
        if v='4' then // FK_NODE
          begin
            if Assigned(onProgress) then
              onProgress(Self, prgFrom + step * i2, doCancel);
            if doCancel then
              exit;
             ;
            parseNodeInfo(Self.addFileRecur(Tfile.create(pn.TreeView as TTreeView, ''), pn).node, dj.JsonValue as TJSONObject, prc, prc+step);
          end
        else if v = '1' then // FK_RESOURCE
          begin
            pf.resource := dj.JsonValue.Value;
          end
        else if v = '2' then // FK_NAME
          begin
            pf.SetName(dj.JsonValue.Value);
          end
        else if v = '3' then // FK_FLAGS
          begin
            var d: String := dj.JsonValue.Value;
            var i: Integer := dj.JsonValue.AsType<Integer>;
            move(i, pf.flags, min(SizeOf(i), SizeOf(pf.flags)));
          end
        else if v = '7' then // FK_COMMENT
          begin
            pf.comment := dj.JsonValue.Value;
          end
        else if v = '8' then // FK_USERPWD
          begin
            var data2: RawByteString := decodeB64(dj.JsonValue.Value);
            pf.user := UnUTF(chop(':', data2));
            pf.pwd := UnUTF(data2);
            usersInVFS.track(pf.user, pf.pwd);
          end
        else if v = '9' then // FK_ADDEDTIME
          begin
            pf.atime := dj.JsonValue.AsType<Double>;
          end
        else if v='10' then // FK_DLCOUNT
          begin
            pf.DLcount := dj.JsonValue.AsType<Integer>;
          end
        else if v='12' then // FK_ACCOUNTS
          begin
            pf.accounts[FA_ACCESS] := parseAcccounts(dj.JsonValue as TJSONArray);
          end
        else if v='17' then // FK_UPLOADACCOUNTS
          begin
            pf.accounts[FA_UPLOAD] := parseAcccounts(dj.JsonValue as TJSONArray);
          end
        else if v='27' then // FK_DELETEACCOUNTS
          begin
            pf.accounts[FA_DELETE] := parseAcccounts(dj.JsonValue as TJSONArray);
          end
        else if v='13' then // FK_FILESFILTER
          begin
            pf.filesfilter := dj.JsonValue.Value;
          end
        else if v='14' then // FK_FOLDERSFILTER
          begin
            pf.foldersfilter := dj.JsonValue.Value;
          end
        else if v='26' then // FK_UPLOADFILTER
          begin
            pf.uploadFilterMask := dj.JsonValue.Value;
          end
        else if v='16' then // FK_REALM
          begin
            pf.realm := dj.JsonValue.Value;
          end
        else if v='18' then // FK_DEFAULTMASK
          begin
            pf.defaultFileMask := dj.JsonValue.Value;
          end
        else if v='25' then // FK_DIFF_TPL
          begin
            pf.diffTpl := dj.JsonValue.Value;
          end
        else if v='19' then // FK_DONTCOUNTASDOWNLOADMASK
          begin
            pf.dontCountAsDownloadMask := dj.JsonValue.Value;
          end
        else if v='20' then // FK_AUTOUPDATED_FILES
          begin
            parseAutoupdatedFilesJ(dj.JsonValue);
          end
        else if v='23' then // FK_HFS_BUILD
          begin
            loadingVFS.build := dj.JsonValue.Value;
          end
        else if v='0' then // FK_HEAD
          begin
            // recognize these fields, but do nothing
          end
        else if v='22' then // FK_HFS_VER
          begin
            // recognize these fields, but do nothing
          end
        else if v='117' then // FK_ICON_IDX
          begin
            var idx: Integer := dj.JsonValue.AsType<Integer>;
            var zi: Integer := z.IndexOf(IntToStr(idx) + '.png');
            if zi >= 0 then
              begin
                pf.setupImage(spUseSysIcons in sp, str2pic(z.Data[zi], 16));
              end;
            zi := z.IndexOf(IntToStr(idx) + '_BIG.png');
            if zi >= 0 then
              begin
                pf.setupImage(spUseSysIcons in sp, str2pic(z.Data[zi], 32));
              end;
          end
        else if v = 'nodes' then
          begin
            var rr := dj.JsonValue as TJSONArray;
           if Assigned(rr) then
             begin
               for var jv in rr do
               begin
                 var ro := jv as TJSONObject;
//                 parseNodeInfo(Self.addFileRecur(Tfile.create(pn.TreeView as TTreeView, ''), pn).node, ro);
                 parseNodeInfo(pn, ro, prc, prc+step);
               end;
             end;
          end
        else
         loadingVFS.unkFK := TRUE;
        prc := prc + step;
      end;
    end;
    if Assigned(pf) then
      begin
        if FA_VIS_ONLY_ANON in pf.flags then
          loadingVFS.visOnlyAnon := TRUE;
        if pf.isVirtualFolder() or pf.isLink() then
          pf.mtime := pf.atime;
        if assigned(pf.accounts[FA_UPLOAD]) and (pf.resource > '') then
          addString(pf.resource, uploadPaths);
        pf.setupImage(spUseSysIcons in sp);

        if Assigned(pf.Node) then
          pf.Node.expanded := TRUE;
      end;
  end;
var
  j: TJSONObject;
//  str: TAnsiStringStream;
  str: TRawByteStringStream;
  js: RawByteString;
  rr: TJSONValue;
  ro: TJSONObject;
  jsi: Integer;
begin
  if vfs = '' then
    exit;
//  str := TAnsiStringStream.Create(vfs);
  sp := GetSP();
  str := TRawByteStringStream.Create(vfs);
  z := TZipFile.Create;
  try
    z.LoadFromStream(str);
    jsi := z.IndexOf('VFS.json');
    if jsi < 0 then
      begin
//        msgDlg(MSG_MISS_J, MB_ICONERROR);
        MessageDlg(MSG_MISS_J, mtError, []);
        exit;
      end;
    js := z.Data[jsi];
    if not ParseJSON(js, j) then
//    if not IsValidJson(vfs) then
      begin
//        msgDlg(MSG_MISS_J, MB_ICONERROR);
        MessageDlg(MSG_CORRUPTED_J, mtError, []);
        exit;
      end;
     rr := j.FindValue('root');
     if Assigned(rr) then
       begin
//          TJSONObject.
         ro := rr as TJSONObject;
//         ro := TJSONObject.Create;
//         ro.ParseJSONValue(rr.ToJSON);
         parseNodeInfo(getRootNode, ro, 0, 1);
       end;

   finally
     z.Free;
     str.Free;
  end;

end; // setVFSJZ

function TFileServer.addFileRecur(f: TFile; parent: TFile=NIL): TFile;
var
  pn, n: TTreeNode;
begin
  if Assigned(parent) then
    pn := parent.node
   else
    pn := NIL;
  Result := addFileRecur(f, pn, n);
end;

function TFileServer.addFileRecur(f:Tfile; parent:TTreeNode=NIL): Tfile;
var
  n: TTreeNode;
begin
  Result := addFileRecur(f, parent, n);
end;

function TFileServer.addFileRecur(f: Tfile; parent: TTreeNode; var newNode: TTreeNode): Tfile;
var
//  n: Ttreenode;
  sr: TsearchRec;
  newF: Tfile;
  s: string;
  sp: TShowPrefs;
  lp: TLoadPrefs;
begin
  newNode := NIL;
  result := f;
  if stopAddingItems then
    exit;

  if parent = NIL then
    if Assigned(rootFile) then
      parent := rootFile.node;

  if Assigned(fOnAddingItems) then
    fOnAddingItems();
  sp := GetSP();
  if Assigned(fOnGetLP) then
    lp := onGetLP();
{
  if addingItemsCounter >= 0 then // counter enabled
    begin
    inc(addingItemsCounter);
    if addingItemsCounter and 15 = 0 then // step 16
      begin
      application.ProcessMessages();
      setStatusBarText(format(MSG_ADDING, [addingItemsCounter]));
      end;
    end;
}
  // ensure the parent is a folder
 {$IFDEF FMX}
  while assigned(parent) and parent.data.IsObject
    and not nodeToFile(parent).isFolder() do
    parent := parent.ParentItem;
 {$ELSE ~FMX}
  while assigned(parent) and assigned(parent.data)
    and not nodeToFile(parent).isFolder() do
    parent := parent.parent;
 {$ENDIF FMX}
  // test for duplicate. it often happens when you have a shortcut to a file.
  if existsNodeWithName(f.name, parent) then
    begin
    result:=NIL;
    exit;
    end;

  if stopAddingItems then
    exit;

 {$IFDEF FMX}
  newNode := TTreeViewItem.Create(rootFile.mainTree);
  newNode.Text := f.name;
  newNode.Data := f;
  newNode.parent := parent;

 {$ELSE ~FMX}
  newNode := rootFile.mainTree.Items.AddChildObject(parent, f.name, f);
  // stateIndex assignments are a workaround to a delphi bug
  newNode.stateIndex := 0;
  newNode.stateIndex := -1;
 {$ENDIF FMX}
  f.setupImage(spUseSysIcons in sp, newNode);
  // autocreate fingerprint
  if f.isFile() and (lpFingerPrints in lp) and (autoFingerprint > 0) and (f.resource > '') then
    try
      f.size := sizeofFile(f.resource);
      if (autoFingerprint >= f.size div 1024)
      and (loadFingerprint(f.resource) = '') then
        begin
          toAddFingerPrint.add(f.resource);
        end;
    except
    end;

  if (f.resource = '') or not f.isVirtualFolder() then exit;
  // virtual folders must be run at addition-time
  if findFirst(f.resource+'\*',faAnyfile, sr) <> 0 then exit;
  try
    repeat
    if stopAddingItems then break;
    if (sr.name[1] = '.')
    or isFingerprintFile(lp, sr.name) or isCommentFile(lp, sr.name) then continue;
    newF := Tfile.create(rootFile.mainTree, f.resource+'\'+sr.name);
    if newF.isFolder() then include(newF.flags, FA_VIRTUAL);
    if addfileRecur(newF, newNode) = NIL then
      freeAndNIL(newF);
    until findnext(sr) <> 0;
  finally FindClose(sr) end;
end; // addFileRecur

function TFileServer.addFileInt(f:Tfile; parent: TFile): Tfile;
resourcestring
  MSG_FILE_ADD_ABORT = 'File addition was aborted.'#13'The list of files is incomplete.';
begin
  stopAddingItems := FALSE;
  result := Self.addFileRecur(f, parent);
  if result = NIL then
    exit;
  if stopAddingItems then
    MessageDlg(MSG_FILE_ADD_ABORT, mtWarning, []);
end;

function TFileServer.removeFile(f: Tfile): Boolean;
begin
  Result := False;
  if f = NIL then
    Result := removeFile(Ttreenode(NIL))
   else
    if f.node <> NIL then
      Result := removeFile(f.node);
end;

function TFileServer.removeFile(node: TTreeNode): Boolean;
begin
  Result := False;
  if assigned(node) then
    begin
    if node.parent = NIL then
      exit;
    if nodeIsLocked(node) then
      begin
//      msgDlg(MSG_ITEM_LOCKED, MB_ICONERROR);
//      MessageDlg(MSG_ITEM_LOCKED, mtError, []);
      exit;
      end;
 {$IFDEF FMX}
    node.Free;
 {$ELSE ~FMX}
    node.Delete();
 {$ENDIF FMX}
    exit;
    end;
end;

procedure TFileServer.fileDeletion(f: TFile);
var
  isRoot: Boolean;
begin
  isRoot := f = Self.rootFile;
// the test on uploadPaths may save some function call
  if assigned(f.accounts[FA_UPLOAD]) and assigned(uploadPaths) then
    removeString(f.resource, uploadPaths);
  try
    f.free
   except
  end;
  if isRoot then
//    rootNode := NIL;
    Self.rootFile := NIL;
  VFSmodified := TRUE
end;

procedure TFileServer.getPage(const sectionName: String; data: TconnDataMain; f:Tfile=NIL; tpl2use: Ttpl=NIL);
var
  md: TmacroData;

 procedure addProgressSymbols();
  var
    t, files, fn: string;
    i: integer;
    d: TconnDataMain;
    perc: real;
    bytes, total: int64;
  begin
    if sectionName <> 'progress' then
      exit;

    bytes := 0; total := 0; // shut up compiler
    files := '';
    i := -1;
    repeat // a while-loop would look better but would lead to heavy indentation
      inc(i);
      if i >= srv.conns.count then
        break;
      d := conn2dataMain(i);
      if d.address <> data.address then
        continue;
      fn := '';
      // fill fields
      if isReceivingFile(d) then
        begin
        t := tpl2use['progress-upload-file'];
        fn := d.uploadSrc; // already encoded by the browser
        bytes := d.conn.bytesPosted;
        total := d.conn.post.length;
        end;
      if isSendingFile(d) then
        begin
        if d.conn.reply.bodymode <> RBM_FILE then continue;
        t := tpl2use['progress-download-file'];
        fn := d.lastFN;
        bytes := d.conn.bytesSentLastItem;
        total := d.conn.bytesPartial;
        end;
      perc := safeDiv(0.0+bytes, total); // 0.0 forces a typecast that will call the right overloaded function
      // no file exchange
      if fn = '' then
        continue;
      fn := macroQuote(fn);
      // apply fields
      files := files+xtpl(t, [
        '%item-user%', macroQuote(d.usr),
        '%perc%',intToStr( trunc(perc*100) ),
        '%filename%', fn,
        '%filename-js%', jsEncode(fn, '''"'),
        '%done-bytes%', intToStr(bytes),
        '%total-bytes%', intToStr(total),
        '%done%', smartsize(bytes),
        '%total%', smartsize(total),
        '%time-left%', getETA(d),
        '%speed-kb%', floatToStrF(d.averageSpeed/1000, ffFixed, 7,1),
        '%item-ip%', d.address,
        '%item-port%', d.conn.port
      ]);
    until false;
    if files = '' then
      files := tpl2use['progress-nofiles'];
    addArray(md.table, ['%progress-files%', files]);
  end; // addProgressSymbols

  procedure addUploadSymbols();
  var
    files: string;
  begin
    if sectionName <> 'upload' then
      exit;
    files := '';
    for var i: Integer :=1 to 10 do
      files := files+ xtpl(tpl2use['upload-file'], ['%idx%',intToStr(i)]);
    addArray(md.table, ['%upload-files%', files]);
  end; // addUploadSymbols

  procedure addUploadResultsSymbols();
  var
    files: string;
  begin
    if sectionName <> 'upload-results' then
      exit;
    files := '';
    if length(data.uploadResults) > 0 then
     for var i: Integer :=0 to length(data.uploadResults)-1 do
      with data.uploadResults[i] do
        files := files+xtpl(tpl2use[ if_(reason='','upload-success','upload-failed') ],[
          '%item-name%', htmlEncode(macroQuote(fn)),
          '%item-url%', macroQuote(encodeURLW(fn)),
          '%item-size%', smartsize(size),
          '%item-resource%', f.resource+'\'+fn,
          '%idx%', intToStr(i+1),
          '%reason%', reason,
          '%speed%', intToStr(speed div 1000), // legacy
          '%smart-speed%', smartsize(speed)
        ]);
    addArray(md.table, ['%uploaded-files%', files]);
    data.uploadResults := NIL; // reset
  end; // addUploadResultsSymbols

var
  s: string;
  section: PtplSection;
  buildTime: Tdatetime;
  externalTpl: boolean;
begin
  buildTime := now();

  externalTpl := assigned(tpl2use);
  if not externalTpl then
    tpl2use := tplFromFile(Tfile(first(f, Self.rootFile)));
  if assigned(data.tpl) then
    begin
      data.tpl.over := tpl2use.over;
      tpl2use.over := data.tpl;
    end;


  try
    data.conn.reply.mode:=HRM_REPLY;
    data.conn.reply.bodyMode := RBM_RAW;
    data.conn.reply.body := '';
  except end;

  if sectionName = 'ban' then
    data.conn.reply.mode:=HRM_DENY
  else if sectionName = 'deny' then
    data.conn.reply.mode:=HRM_DENY
  else if sectionName = 'login' then
    data.conn.reply.mode:=HRM_DENY
  else if sectionName = 'not found' then
    data.conn.reply.mode:=HRM_NOT_FOUND
  else if sectionName = 'unauthorized' then
    data.conn.reply.mode:=HRM_UNAUTHORIZED
  else if sectionName = 'overload' then
    data.conn.reply.mode:=HRM_OVERLOAD
  else if sectionName = 'max contemp downloads' then
    data.conn.reply.mode:=HRM_OVERLOAD;

  section := tpl2use.getSection(sectionName);
  if section = NIL then exit;

  try
    ZeroMemory(@md, sizeOf(md));
    addUploadSymbols();
    addProgressSymbols();
    addUploadResultsSymbols();
    if data = NIL then
      s := ''
     else
      s := first(data.banReason, data.disconnectReason);
    addArray(md.table, ['%reason%', s]);

    data.conn.reply.contentType := name2mimetype(sectionName, 'text/html; charset=utf-8');

    md.cd := data;
    md.tpl := tpl2use;
    md.folder := f;
    md.f := NIL;
    md.archiveAvailable := FALSE;
    s := tpl2use['special:begin'];
    tryApplyMacrosAndSymbols(Self, s, md, FALSE);

    if data.conn.reply.mode = HRM_REPLY then
      s := section.txt
     else
      begin
        s := xtpl(tpl2use['error-page'], ['%content%', section.txt]);
        if s = '' then
          s := section.txt;
      end;

    tryApplyMacrosAndSymbols(Self, s, md);

    data.conn.reply.bodyU := xtpl(s, [
      '%build-time%', floatToStrF((now()-buildTime)*SECONDS, ffFixed, 7,3)
    ]);
    if section.nolog then
      data.dontLog := TRUE;
    compressReply(data);
  finally
    if not externalTpl then
      tpl2use.free
    end
end; // getPage

procedure TFileServer.compressReply(cd: TconnDataMain);
const
  BAD_IE_THRESHOLD = 2000; // under this size (few bytes less, really) old IE versions will go nuts with UTF-8 pages
var
  s: RawByteString;
  lToGZip: Boolean; // GZip
  lToBr: Boolean;   // Brotli
  sp: TShowPrefs;
begin
  sp := getSP;
  lToGZip := spCompressed in sp;
  lToBr   := spCompressed in sp;
//  if not compressedbrowsingChk.checked then
//    exit;
  lToBr := lToBr and (ipos('Br', cd.conn.getHeader('Accept-Encoding')) <> 0);


  lToGZip := lToGZip and (cd.conn.reply.body <> '');
  lToGZip := lToGZip and (ipos('gzip', cd.conn.getHeader('Accept-Encoding')) <> 0);
  if not lToGZip and not cd.conn.reply.IsGZiped then
    Exit;
  s := cd.conn.reply.body;
  if s = '' then
    exit;
//  if ipos('gzip', cd.conn.getHeader('Accept-Encoding')) = 0 then
//    exit;
// workaround for IE6 pre-SP2 bug
if (cd.workaroundForIEutf8  = wi_toDetect) and (cd.agent > '') then
  if reMatch(cd.agent, '^MSIE [4-6]\.', '!') > 0 then // version 6 and before
    cd.workaroundForIEutf8 := wi_yes
  else
    cd.workaroundForIEutf8:=wi_no;
//s:=ZcompressStr2(s, zcFastest, 31,8,zsDefault);
  if lToGZip and not cd.conn.reply.IsGZiped then
    s := ZcompressStr(s, clDefault, zsGZip);

  if (cd.workaroundForIEutf8  = wi_yes) and (length(s) < BAD_IE_THRESHOLD) then
    lToGZip := false;
  if lToGZip then
    begin
      cd.conn.addHeader('Content-Encoding', 'gzip');
      cd.conn.reply.body := s;
    end
   else
    begin
      if cd.conn.reply.IsGZiped then
        begin
          cd.conn.reply.body := ZDecompressStr3(cd.conn.reply.body);
          cd.conn.reply.IsGZiped := False;
        end;

    end;
end; // compressReply

function conn2data(p: Tobject): TconnData; inline; overload;
begin
  if p = NIL then
    result:=NIL
   else
    result:=TconnData((p as ThttpConn).data)
end; // conn2data

function conn2data(i: integer): TconnData; inline; overload;
begin
  try
    if i < srv.conns.count then
      result := conn2data(srv.conns[i])
    else
      result := conn2data(srv.offlines[i-srv.conns.count])
   except
    result := NIL
  end
end; // conn2data

function TFileServer.countDownloads(const ip: String=''; const user: String=''; f:Tfile=NIL): Integer;
var
  i: integer;
  d: TconnData;
begin
  result := 0;
  i := 0;
  while i < srv.conns.count do
  begin
  d := conn2data(i);
  if isDownloading(d)
  and ((f = NIL) or (assigned(d.lastFile) and d.lastFile.same(f)))
  and ((ip = '') or addressMatch(ip, d.address))
  and ((user = '') or sameText(user, d.usr))
  then
    inc(result);
  inc(i);
  end;
end;

function TFileServer.getSP: TShowPrefs;
begin
  if Assigned(fOnGetSP) then
    Result := fOnGetSP()
   else
    Result := [];
end;

function TFileServer.getLP: TLoadPrefs;
begin
  if Assigned(fOnGetLP) then
    Result := fOnGetLP()
   else
    Result := [];
end;

constructor TconnData.create(conn: ThttpConn; pGuiData: TObject);
begin
  conn.data := self;
  self.conn := conn;
  time := now();
  lastActivityTime := time;
  downloadingWhat := DW_UNK;
  urlvars := THashedStringList.create();
  urlvars.lineBreak := '&';
  tplCounters := TstringToIntHash.create();
  vars := THashedStringList.create();
  postVars := THashedStringList.create();
  guiData := pGuiData;
end; // constructor

destructor TconnData.destroy;
begin
  if vars.Count > 0 then
  for var i: integer :=0 to vars.Count-1 do
  if assigned(vars.Objects[i]) and (vars.Objects[i] <> currentCFGhashed) then
    begin
    vars.Objects[i].free;
    vars.Objects[i]:=NIL;
    end;
  freeAndNIL(vars);
  freeAndNIL(postVars);
  freeAndNIL(urlvars);
  freeAndNIL(tplCounters);
  freeAndNIL(limiter);
  if guiData <> NIL then
    FreeAndNil(guiData);

// do NOT free "tpl". It is just a reference to cached tpl. It will be freed only at quit time.
if assigned(f) then
  begin
  closeFile(f^);
//  f.free;
  f := nil;
  end;
inherited destroy;
end; // destructor

// we'll automatically free and previous temporary object
procedure TconnData.setLastFile(f: Tfile);
begin
  freeIfTemp(FlastFile);
  FlastFile := f;
end;

function TconnData.accessFor(f: TFile): Boolean;
begin
  Result := Self <> NIL;
  if Result then
    Result := f.accessFor(usr, pwd);
end;



function uptimestr(): string;
var
  t: Tdatetime;
begin
  result := 'server down';
  if not srv.active then
    exit;
  t := now()-uptime;
  if t > 1 then
    result := format('(%d days) ', [trunc(t)])
   else
    result := '';

  result := result + formatDateTime('hh:nn:ss', t)
end; // uptimeStr

function getAcceptOptions(): Types.TstringDynArray;
begin
  result := listToArray(localIPlist(sfAny));
  addUniqueString('127.0.0.1', result);
  addUniqueString('::1', result);
end; // getAcceptOptions

procedure kickByIP(const ip: String);
var
  i: integer;
  d: TconnDataMain;
begin
  i := 0;
  while i < srv.conns.count do
   begin
    d := conn2dataMain(i);
    if assigned(d) and (d.address = ip) or (ip = '*') then
      d.disconnect(first(d.disconnectReason, 'kicked'));
    inc(i);
   end;
end; // kickByIP

function startServer(): boolean;

  procedure tryPorts(list:array of string);
  begin
  for var i: Integer :=0 to length(list)-1 do
    begin
    srv.port:=trim(list[i]);
    if srv.start(listenOn) then exit;
    end;
  end; // tryPorts

begin
result:=FALSE;
if srv.active then exit; // fail if already active

if not stringExists(listenOn, getAcceptOptions()) then
  listenOn:='';

if port > '' then
  tryPorts([port])
else
  tryPorts(['80','8080','280','10080','0']);
if not srv.active then exit; // failed
upTime:=now();
result:=TRUE;
end; // startServer

procedure stopServer();
begin
  if assigned(srv) then
    srv.stop()
end;

function restartServer(): boolean;
var
  port: string;
begin
  result:=FALSE;
  if not srv.active then
    exit;
  port := srv.port;
  srv.stop();
  srv.port := port;
  result := srv.start(listenOn);
end; // restartServer


// change port and test it working. Restore if not working.
function changePort(const newVal: String): Boolean;
var
  act: boolean;
  was: string;
begin
  result := TRUE;
  act := srv.active;
  was := port;
  port := newVal;
  if act and (newVal = srv.port) then
    exit;
  stopServer();
  if startServer() then
    begin
      if not act then
        stopServer(); // restore
      exit;
    end;
  result := FALSE;
  port := was;
  if act then
    startServer();
end; // changePort

function noLimitsFor(account: Paccount): boolean;
begin
  account := accountRecursion(account, ARSC_NOLIMITS);
  result := assigned(account) and account.noLimits;
end; // noLimitsFor


end.
