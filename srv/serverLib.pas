unit serverLib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  // delphi libs
  Windows,
  mormot.core.base,
  Classes,
  //Messages,
  Graphics,
  Forms,
  ComCtrls,
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Generics.Collections,
  {$ELSE USE_MORMOT_COLLECTIONS}
  mormot.core.collections,
  {$ENDIF USE_MORMOT_COLLECTIONS}
  math, Types, SysUtils,
  RnQPrefsLib,
  iniFiles,
  srvConst,
  HSLib, srvClassesLib, fileLib;

type

  TShowPrefs = set of (spUseSysIcons, spHttpsUrls, spFoldersBefore, spLinksBefore,
                       spNoPortInUrl, spEncodeNonascii, spEncodeSpaces, spCompressed,
                       spNoWaitSysIcons, spSendHFSIdentifier, spFreeLogin,
                       spStopSpiders, spPreventLeeching,
                       spDisableMacros, spNonLocalIPDisableMacros,
                       spPwdInPages, spEnableNoDefault, spDMbrowserTpl,
                       spRecursiveListing, spOemTar, spNoContentDisposition, spPreventStandby
                       );


  TLogPrefs = set of (logBanned, logIcons, logBrowsing, logProgress,
                      logServerstart, logServerstop,
                      logConnections, logDisconnections,
                      logUploads, logFullDownloads, LogDeletions,
                      logBytesReceived, logBytesSent, logOnlyServed,
                      logRequests, logReplies, logOtherEvents,
                      dumpRequests, dumpTraffic,
                      logMacros);

  TUpdateTrayWhat = set of (utIcon, utTIP);

  TFileServer = class;

  TfileListing = class
    tr: IServerTree;
    actualCount: integer;
   public
    dir: array of Tfile;
    timeout: TDateTime;
    ignoreConnFilter: boolean;
    constructor create(pTree: IServerTree);
    destructor Destroy; override;
    function fromFolder(lp: TLoadPrefs; folder: Tfile; cd: TconnDataMain; recursive: boolean=FALSE;
      limit: integer=-1; toSkip: Integer=-1; doClear: Boolean=TRUE): Integer;
    procedure sort(foldersBefore, linksBefore: Boolean; cd: TconnDataMain; const def: String='');
  end;

  TOnGetSP = function: TShowPrefs of Object;
  TOnGetLP = function: TLoadPrefs of Object;
//  TOnGetLogP = function: TLogPrefs of Object;

  PMacroData = ^TmacroData;
  TmacroData = record
    cd: TconnDataMain;
    tpl: Ttpl;
    folder, f: Tfile;
    afterTheList, archiveAvailable, hideExt, breaking: boolean;
    aliases, tempVars: THashedStringList;
    table: TMacroTableVal;
    logTS: boolean;
   end;

  TmacroCB = function(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;

  TMacroFunc = record
    minParams: Byte;
    func: TmacroCB;
  end;

  {$IFNDEF USE_MORMOT_COLLECTIONS}
  TMacroFuncArr = TDictionary<String, TMacroFunc>;
  {$ELSE USE_MORMOT_COLLECTIONS}
  TMacroFuncArr = IKeyValue<String, TMacroFunc>;
  {$ENDIF USE_MORMOT_COLLECTIONS}


  TconnData = class;

  TMacroApplyFunc = function(fs: TFileServer; var txt: UnicodeString; var md: TmacroData; removeQuotings: boolean=true): boolean;
  TLoadVFSProg = procedure(Sender: TObject; PRC: Real; var Cancel: Boolean);
//  TConnDataEvent = procedure(data: TconnDataMain);
  TConnDataEvent = procedure(data: TconnData);
  TConnDataEventO = procedure(data: TconnData) of Object;
  TFindFileNode = function(f: TFile): TFileNode;
  TFileAddedEvent = procedure(f: Tfile; parent, node: TFileNode; skipComment: Boolean; addingStoped: Boolean) of Object;
  TSetStatusBarText = procedure(const s: String; lastFor: Integer) of Object;


  TFileServer = class(TInterfacedPersistent, IServerTree)
   private class var
      defaultTpl: Ttpl;
      supportZStd: Boolean;
   private
    fHTTPSrv: ThttpSrv;
    userPwdHashCache2: Tstr2str;
    fMainTree: TFileTree;
    fRootFile: Tfile;
    fSP: TShowPrefs;
    fLP: TLoadPrefs;
    fLogP: TLogPrefs;
    fOnGetSP: TOnGetSP;
    fOnGetLP: TOnGetLP;
//    fOnGetLogP: TOnGetLogP;
    fOnAddingItems: TProcedureOfObject;
    fAllPrefs: TRnQPref;
    fMacroFuncs: TMacroFuncArr;
   private
    fOnAdd2Log: TAdd2LogEvent;
    fOnIPsEverChanged: TProcedureOfObject;
    fOnFlash: TProc<String>;
    fOnSetupDownloadIcon: TConnDataEvent;
    fOnStatusChanged: TProc<Boolean>;
    fOnRefreshConn: TConnDataEventO;
    fOnInitConnData: TConnDataEvent;
    fOnRemoveConnData: TConnDataEvent;
    fOnUpdateTray: TProc<TUpdateTrayWhat>;
    fOnBeforeAddFile: TNotifyEvent;
    fOnAfterAddFile: TFileAddedEvent;
    fSetStatusBarText: TSetStatusBarText;
//    fGetFileNode: TFindFileNode;
    class constructor CreateServer;
    class destructor  DestroyServer;
    constructor Create; OverLoad;
    function  shouldRecur(data: TconnDataMain): boolean;
    procedure doOnIPsEverChanged;
    procedure doFlash(event: String);
    procedure doSetupDownloadIcon(data: TconnData);
    procedure doStatusChanged(Open: Boolean);
    procedure doRefreshConn(data: TconnData);
    procedure doInitConnData(data: TconnData);
    procedure doRemoveConnData(data: TconnData);
    procedure doUpdateTray(what: TUpdateTrayWhat);
    procedure initPrefs;
   public
    tpl: Ttpl; // template for generated pages
    tryApplyMacrosAndSymbols: TMacroApplyFunc;
    stopAddingItems: Boolean;
    constructor Create(pTree: TFileTree; pTryApplyMacrosAndSymbols: TMacroApplyFunc;
                       pOnGetSP: TOnGetSP; pOnGetLP: TOnGetLP;
                       pOnAddingItems: TProcedureOfObject;
                       pSetStatusBarText: TSetStatusBarText); OverLoad;
    destructor Destroy; OverRide;
    procedure setAdd2LogFunc(doAdd2LogFunc: TAdd2LogEvent);
    procedure registerMacroFunc(const name: String; const func: TMacroFunc); OverLoad;
    procedure registerMacroFunc(const name: String; minParams: Byte; const func: TmacroCB); OverLoad;
    procedure unRegisterMacroFunc(const name: String);
    procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = True);
    function  initRoot: TFile;
    function  initRootWithNode: TFile;
    procedure clearNodes;
    function  encodeURLA(const s: string; fullEncode: Boolean=FALSE): RawByteString;
    function  encodeURLW(const s: string; fullEncode: Boolean=FALSE): String;
    function  pathTill(fl: Tfile; root: Tfile=NIL; delim: char='\'): String;
    function  url(f: Tfile; fullEncode: boolean=FALSE): String;
    function  parentURL(f: Tfile): String;
    function  fullURL(f: Tfile; const ip, user, pwd: String): String; OverLoad;
    function  fullURL(f: Tfile; ip: String=''): String; OverLoad;
    function  tplFromFile(f: Tfile): Ttpl;
    function  getAFolderPage(folder: Tfile; cd: TconnDataMain; otpl: TTpl): UnicodeString;
    function  findFilebyURL(url: UnicodeString; parent: Tfile=NIL; allowTemp: boolean=TRUE): Tfile;
    function  fileExistsByURL(const url: UnicodeString): Boolean;
    function  uri2disk(url: string; parent: Tfile=NIL; resolveLnk: boolean=TRUE): string;
    function  uri2diskMaybe(const path: String; parent: Tfile=NIL; resolveLnk: Boolean=TRUE): String;
    function  protoColon(sp: TShowPrefs): String;
    function  addFileRecur(f: TFile; parent: TFile=NIL): TFile; OverLoad;
    function  addFileRecur(f: Tfile; parent: TFileNode=NIL): Tfile; OverLoad;
    function  addFileRecur(f: Tfile; parent: TFileNode; var newNode: TFileNode): Tfile; OverLoad;
    function  addFileInt(f: Tfile; parent: TFile): Tfile;
    function  addFileGUI(f: Tfile; parent: TFileNode; skipComment: boolean): Tfile;
    procedure setVFS(const vfs: RawByteString; pf: TFile; onProgress: TLoadVFSProg);
    procedure setVFSJZ(const vfs: RawByteString; node: TFileNode=NIL; onProgress: TLoadVFSProg = NIL);
    function  removeFile(f: Tfile): Boolean; OverLoad;
    function  removeFile(node: TFileNode): Boolean; OverLoad;
    procedure fileDeletion(f: TFile);
    function  existsNodeWithName(const name: string; parent: TFileNode): boolean;
    function  getUniqueNodeName(const start: string; parent: TFileNode): string;
    function  getRootNode: TFileNode;
    procedure getPage(const sectionName: RawByteString; data: TconnDataMain; f: Tfile=NIL; tpl2use: Ttpl=NIL);
    procedure compressReply(cd: TconnDataMain);
    function  conn2data(i: integer): TconnData; inline;
    procedure kickByIP(const ip: String);
    procedure kickAllIdle(const Msg: String);
    procedure httpEventNG(event: ThttpEvent; conn: ThttpConn);
    procedure purgeVFSaccounts();
    function  getSP0: TShowPrefs;
    function  getLP0: TLoadPrefs;
    function  getLogP0: TLogPrefs;
    function  getMainTree: TFileTree;
    procedure setStatusBarText(const s: String; lastFor: Integer);
    procedure DoImageChanged(Sender: TObject; n: TFileNode = NIL);
    procedure ChangedName(Sender: TObject; Name: String);
    function  findNode(f: TObject): TFileNode;
    function  getParentNode(f: TObject): TFileNode;
    function  getFirstChild(f: TObject): TFileNode;
    function  getNextSibling(f: TObject): TFileNode;
    procedure DeleteChildren(f: TObject);
    procedure DeleteNode(f: TObject);
    procedure ForAllSubNodes(Sender: TObject; proc: TProc<TObject>);
    function  nodeToFile(n: TFileNode): TObject; inline;
    function  nodeText(n: TFileNode): String; inline;
    function  nodeIsLocked(n: TFileNode): Boolean;
    function  httpServIsActive: Boolean;
    function  countDownloads(const ip: String=''; const user: String=''; f:Tfile=NIL): Integer;
    function  uptimeStr(): string;
    function  getConnectionsCount: Integer;
    function  countIPs(onlyDownloading: boolean=FALSE; usersInsteadOfIps: boolean=FALSE): integer;
    procedure syncSP;
    procedure syncLP;
    procedure syncLogP;
    function  startServer: boolean;
    function  changeListenAddr(const addr: String): boolean;
    function  restartServer: boolean;
    function  changePort(const newVal: String): Boolean;
    function  getListenPorts(const onlyPref: Boolean = false): String;
    procedure resetTotals;
    property  SP: TShowPrefs read fSP; // write fOnGetSP;
    property  LP: TLoadPrefs read fLP; // write fOnGetLP;
    property  LogP: TLogPrefs read fLogP; // write fOnGetLogP;
    property  onGetSP: TOnGetSP read fOnGetSP; // write fOnGetSP;
    property  onGetLP: TOnGetLP read fOnGetLP; // write fOnGetLP;
//    property  onGetLogP: TOnGetLogP read fOnGetLogP; // write fOnGetLogP;
    property  onAddingItems: TProcedureOfObject read fOnAddingItems write fOnAddingItems;
    property  onIPsEverChanged: TProcedureOfObject read fOnIPsEverChanged write fOnIPsEverChanged;
    property  OnSetupDownloadIcon: TConnDataEvent read fOnSetupDownloadIcon write fOnSetupDownloadIcon;
    property  OnFlash: TProc<String> read fOnFlash write fOnFlash;
    property  OnUpdateTray: TProc<TUpdateTrayWhat> read fOnUpdateTray write fOnUpdateTray;
    property  OnStatusChanged: TProc<Boolean> read fOnStatusChanged write fOnStatusChanged;
    property  OnRefreshConn: TConnDataEventO read fOnRefreshConn write fOnRefreshConn;
    property  OnInitConnData: TConnDataEvent read fOnInitConnData write fOnInitConnData;
    property  OnRemoveConnData: TConnDataEvent read fOnRemoveConnData write fOnRemoveConnData;
//    property  onGetFileNode: TFindFileNode read fGetFileNode write fGetFileNode;
    property  OnBeforeAddFile: TNotifyEvent read fOnBeforeAddFile write fOnBeforeAddFile;
    property  OnAfterAddFile: TFileAddedEvent read fOnAfterAddFile write fOnAfterAddFile;
    property  MainTree: TFileTree read fMainTree;
    property  rootFile: Tfile read fRootFile;
    property  prefs: TRnQPref read fAllPrefs;
    property  htSrv: ThttpSrv read fHttpSrv;
    property  add2LogFunc: TAdd2LogEvent read fOnAdd2Log;
    property  macroFuncs: TMacroFuncArr read fMacroFuncs;
    class property  defTPL: TTpl read defaultTpl;
   end;

  TconnData = class(TconnDataMain)  // data associated to a client connection
  private
    fLastFile: Tfile;
    procedure setLastFile(f: Tfile);
  public
    guiData: TObject;
    ConnBoxAdded: Boolean;
//    countAsDownload: boolean; // cache the value for the Tfile method
    // cache User-Agent because often retrieved by connBox.
    // this value is filled after the http request is complete (HE_REQUESTED),
    // or before, during the request as we get a file (HE_POST_FILE). }
    deleting: boolean;      // don't use, this item is about to be discarded
    nextDloadScreenUpdate: Tdatetime; // avoid too fast updating during download
    preReply: TpreReply;
    lastBytesSent, lastBytesGot: int64; // used for print to log only the recent amount of bytes
    bytesGotGrouping, bytesSentGrouping: record
      bytes: integer;
      since: Tdatetime;
     end;
    // here we put just a pointer because the file type would triplicate
    // the size of this record, while it is NIL for most connections }
    f: ^file; // uploading file handle

    property lastFile: Tfile read fLastFile write setLastFile;
    constructor create(conn: ThttpConn; pGuiData: TObject);
    destructor Destroy; override;
    function accessFor(f: TFile): Boolean;
    function getHTTPStateString: String;
    function getSpeed: Real;
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

  function  getAcceptOptions(): TstringDynArray;
  procedure stopServer(srv: ThttpSrv);
  function noLimitsFor(account: Paccount): Boolean;
  function connO2data(p: Tobject): TconnData; inline; overload;
  function isBanned(const address: String; out comment: String): Boolean; overload;
  function isBanned(cd: TconnDataMain): Boolean; overload;
  procedure removeFilesFromComments(files: TStringDynArray; lp: TLoadPrefs);
  function protoColon(fs: TFileServer): String;
  function getLibs: String;

implementation

uses
  strutils, DateUtils, Contnrs,
  mormot.core.unicode,
  OverbyteIcsWSocket,
 {$IFDEF FPC}
  mormot.core.datetime,
  fpJSON,
 {$ELSE ~FPC}
  //Winapi.WinSock,
  JSON,
 {$IFDEF USE_SSL}
  OverbyteIcsSSLEAY,
 {$ENDIF USE_SSL}
  OverbyteIcsTypes,
 {$ENDIF FPC}
  mormot.core.json,
  netUtils,
  RDUtils, RDFileUtil, RDGlobal, //AnsiClasses,
  RnQNet.Uploads.Lib, RnQNet.Uploads.Tar, //RnQNet.Uploads.Zip,
  //RnQCrypt,
 {$IFDEF ZIP_ZSTD}
   ZSTDLib,
 {$ENDIF ZIP_ZSTD}
  RnQzip, RnQLangs, RnQDialogs, RnQJSON,
  IconsLib,
  HSUtils,
  srvUtils, parserLib, srvVars;

constructor TfileListing.create(pTree: IServerTree);
begin
  dir := NIL;
  tr := pTree;
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

    if cd.conn.httpState = HCS_DISCONNECTED then
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
  fn: string;
  s, l: UnicodeString;
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

function getFiles(const mask: UnicodeString): TUnicodeStringDynArray;
var
  sr: TUnicodeSearchRec;
begin
  result := NIL;
  if findFirst(mask, faAnyFile, sr) = 0 then
  try
    repeat addString(sr.name, result)
    until findNext(sr) <> 0;
  finally findClose(sr) end;
end; // getFiles

function getDynLogFilename(cd: TconnDataMain): String; overload;
var
  d, m, y, w: word;
  u: string;
begin
  decodeDateFully(now(), y,m,d,w);
  if cd = NIL then
    u := ''
   else
    u := nonEmptyConcat('(', cd.usr, ')');
  result := xtpl(logFile.filename, [
    '%d%', int0(d,2),
    '%m%', int0(m,2),
    '%y%', int0(y,4),
    '%dow%', int0(w-1,2),
    '%w%', int0(weekOf(now()),2),
    '%user%', u
  ]);
end; // getDynLogFilename


// returns number of skipped files
function TfileListing.fromFolder(lp: TLoadPrefs; folder: Tfile; cd: TconnDataMain;
  recursive:boolean=FALSE; limit:integer=-1; toSkip:integer=-1; doClear:boolean=TRUE):integer;
var
  seeProtected, noEmptyFolders, forArchive: boolean;
  filesFilter, foldersFilter, urlFilesFilter, urlFoldersFilter: string;

  procedure recurOn(f: Tfile);
  begin
    if not f.isFolder() then
      exit;
    toSkip:=fromFolder(lp, f, cd, TRUE, limit, toSkip, FALSE);
  end; // recurOn

  procedure addToListing(f: Tfile);
  begin
    if noEmptyFolders and f.isEmptyFolder(LP, cd)
       and not accountAllowed(FA_UPLOAD, cd, f) then
      exit; // upload folders should be listed anyway
//  application.ProcessMessages();
  if cd.conn.httpState = HCS_DISCONNECTED then
    exit;

  if toSkip > 0 then dec(toSkip)
  else
    begin
    if actualCount >= length(dir) then
      begin
      setLength(dir, actualCount+1000);
      if actualCount > 0 then
        begin
          tr.setStatusBarText(format('Listing files: %s',[dotted(actualCount)]));
        end;
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
    function getCommentByMaskFor(const fn: String): String;
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
    if lpion in LP then
      loadIon(LP, folder.resource, comments);
    i:=if_((filesFilter='\') or (urlFilesFilter='\'), faDirectory, faAnyFile);
    setBit(i, faSysFile, lpSysAttr in LP);
    setBit(i, faHidden, lpHdnAttr in LP);
    if findfirst(folder.resource+'\*', i, sr) <> 0 then
      exit;

    try
      extractCommentsWithWildcards();
      repeat
        application.ProcessMessages();
        cd.lastActivityTime:=now();
        if (timeout > 0) and (cd.lastActivityTime > timeout) then
          break;
        // we don't list these entries
        if (sr.name = '.') or (sr.name = '..')
        or isCommentFile(LP, sr.name) or isFingerprintFile(LP, sr.name) or sameText(sr.name, DIFF_TPL_FILE)
        or not hasRightAttributes(LP, sr.attr)
        or stringExists(sr.name, namesInVFS)
        then continue;

        filteredOut:=not fileMatch( if_(sr.Attr and faDirectory > 0, foldersFilter, filesFilter), sr.name)
          or not fileMatch( if_(sr.Attr and faDirectory > 0, urlFoldersFilter, urlFilesFilter), sr.name);
        // if it's a folder, though it was filtered, we need to recur
        if filteredOut and (not recursive or (sr.Attr and faDirectory = 0)) then continue;

        f := Tfile.createTemp(tr, folder.resource+'\'+sr.name, folder); // temporary nodes are bound to the parent's node
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
      until (findNext(sr) <> 0) or (cd.conn.httpState = HCS_DISCONNECTED) or (limit >= 0) and (actualCount >= limit);
    finally findClose(sr) end;
  finally comments.free  end
  end; // includeFilesFromDisk

  procedure includeItemsFromVFS();
  var
    f: Tfile;
    sr: TSearchRec;
  begin
  // this folder has been dinamically generated, thus the node is not actually
  // its own... skip }
    if folder.isTemp() then
      exit;

  // include (valid) items from the VFS branch
  f := folder.getFirstChild;
  while assigned(f) and (cd.conn.httpState <> HCS_DISCONNECTED)
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
        if not hasRightAttributes(LP, sr.attr) then continue;
        end
      else // why findFirst() failed? is it a shared folder?
        if not sysutils.directoryExists(f.resource) then continue;
      addToListing(f);
     finally
       f := f.getNextSibling();
    end;
  end; // includeItemsFromVFS

  function beginsOrEndsBy(const ss: String; const s: String): Boolean;
  begin result:=ansiStartsText(ss,s) or ansiEndsText(ss,s) end;

  function par(const k: String):string;
  begin
    if cd = NIL then
      result:=''
     else
      result:=cd.urlvars.values[k]
  end;

begin
  result := toSkip;
  if doClear then
    actualCount:=0;

  if not folder.isFolder()
    or not folder.accessFor(cd)
    or folder.hasRecursive(FA_HIDDENTREE)
    or not (FA_BROWSABLE in folder.flags)
   then
    exit;

  if assigned(cd) then
  begin
    if limit < 0 then
      limit := StrToIntDef(par('limit'), -1);
    if toSkip < 0 then
      toSkip := StrToIntDef(par('offset'), -1);
    if toSkip < 0 then
      toSkip := max(0, pred(strToIntDef(par('page'), 1))*limit);
  end;

  folder.getFiltersRecursively(filesFilter, foldersFilter);
  if assigned(cd) and not ignoreConnFilter then
   begin
    urlFilesFilter := par('files-filter');
    if urlFilesFilter = '' then
      urlFilesFilter := par('filter');
    urlFoldersFilter := par('folders-filter');
    if urlFoldersFilter = '' then
      urlFoldersFilter := par('filter');
    if (urlFilesFilter+urlFoldersFilter = '') and (par('search') > '') then
     begin
      urlFilesFilter:=reduceSpaces(par('search'), '*');
      if not beginsOrEndsBy('*', urlFilesFilter) then
        urlFilesFilter := '*'+urlFilesFilter+'*';
      urlFoldersFilter := urlFilesFilter;
    end;
   end;
// cache user options
  forArchive := assigned(cd) and (cd.downloadingWhat = DW_ARCHIVE);
  seeProtected := not (lpHideProt in LP) and not forArchive;
  noEmptyFolders := (urlFilesFilter = '') and folder.hasRecursive(FA_HIDE_EMPTY_FOLDERS);
  try
    if folder.isRealFolder() and not (FA_HIDDENTREE in folder.flags) and allowedTo(folder) then
      includeFilesFromDisk();
    includeItemsFromVFS();
   finally
    if doClear then
      setLength(dir, actualCount)
  end;
  result := toSkip;
end; // fromFolder

class constructor TFileServer.CreateServer;
begin
  {$IFDEF ZIP_ZSTD}
   try
     supportZStd := ZSTD_versionNumber(False) <> 0;
    except
     supportZStd := false;
   end;
  {$ELSE ~ZIP_ZSTD}
   supportZStd := false;
  {$ENDIF ZIP_ZSTD}
  defaultTpl := Ttpl.create(getResText('defaultTpl'));
  WebPTryLoad;
end;

class destructor TFileServer.DestroyServer;
begin
  defaultTpl.Free;
end;

constructor TFileServer.Create;
begin
  Self.fRootFile := NIL;
  userPwdHashCache2 := NIL;
  fAllPrefs := TRnQPref.Create;
end;

constructor TFileServer.Create(pTree: TFileTree; pTryApplyMacrosAndSymbols: TMacroApplyFunc;
                       pOnGetSP: TOnGetSP; pOnGetLP: TOnGetLP;
                       pOnAddingItems: TProcedureOfObject;
                       pSetStatusBarText: TSetStatusBarText);
begin
  fMainTree := pTree;
  tryApplyMacrosAndSymbols := pTryApplyMacrosAndSymbols;
  fAllPrefs := TRnQPref.Create;
  fOnGetSP := pOnGetSP;
  fOnGetLP := pOnGetLP;
//  fOnGetLogP := pOnGetLogP;
  initPrefs;
  onAddingItems := pOnAddingItems;
  fSetStatusBarText := pSetStatusBarText;
  Self.fRootFile := NIL;
  userPwdHashCache2 := NIL;
  tpl := Ttpl.create(RawByteString(''), defaultTpl);
  fHTTPSrv := ThttpSrv.create();
  fHTTPSrv.autoFreeDisconnectedClients := FALSE;
  fHTTPSrv.limiters.add(globalLimiter);
  fHTTPSrv.onEvent := Self.httpEventNG;
  sessions := Tsessions.create(fHTTPSrv);
//  fMacroFuncs := NIL;
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    fMacroFuncs := TMacroFuncArr.Create();
  {$ELSE USE_MORMOT_COLLECTIONS}
//    fMacroFuncs := Collections.NewKeyValue<String, TMacroFunc>;
    fMacroFuncs := Collections.NewPlainKeyValue<String, TMacroFunc>;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

destructor TFileServer.Destroy;
begin
  fHTTPSrv.onEvent := NIL;
  fHTTPSrv.Free;
  fHTTPSrv := NIL;
  tpl.free;
  tpl := NIL;
  fMacroFuncs := NIL;
end;

procedure TFileServer.setAdd2LogFunc(doAdd2LogFunc: TAdd2LogEvent);
begin
  fOnAdd2Log := doAdd2LogFunc;
end;

procedure TFileServer.registerMacroFunc(const name: String; const func: TMacroFunc);
begin
  fMacroFuncs.Add(name, func);
end;

procedure TFileServer.registerMacroFunc(const name: String; minParams: Byte; const func: TmacroCB);
var
  f: TMacroFunc;
begin
  f.minParams := minParams;
  f.func := func;
  fMacroFuncs.Add(name, f);
end;

procedure TFileServer.unRegisterMacroFunc(const name: String);
begin
  fMacroFuncs.Remove(name);
end;

procedure TFileServer.setStatusBarText(const s: String; lastFor: Integer);
begin
  if Assigned(fSetStatusBarText) then
    fSetStatusBarText(s, lastFor);
end;

function TFileServer.initRoot: TFile;
begin
  fRootFile := Tfile.createVirtualFolder(Self, '/');
  rootFile.flags := rootFile.flags+[FA_ROOT, FA_ARCHIVABLE];
  rootFile.dontCountAsDownloadMask := '*.htm;*.html;*.css';
  rootFile.defaultFileMask := 'index.html;index.htm;default.html;default.htm';
  Result := rootFile;
end;

function TFileServer.initRootWithNode: TFile;
begin
  result := initRoot;
  addFileInt(result, NIL);
end;

procedure TFileServer.clearNodes;
var
  n: TFileNode;
begin
  n := getRootNode;
  if assigned(n) then
   begin
     n.Delete();
   end;
end;

function TFileServer.encodeURLA(const s: String; fullEncode:boolean=FALSE): RawByteString;
var
  r: RawByteString;
begin
  if fullEncode or (spEncodeNonAscii in SP) then
    begin
//      r := ansiToUTF8(s);
      r := StringToUtf8(s);
      result := HSUtils.encodeURL(r, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
    end
   else
    result := HSUtils.encodeURL(s, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
end; // encodeURL

function TFileServer.encodeURLW(const s: String; fullEncode:boolean=FALSE): String;
var
  r: RawByteString;
begin
  if fullEncode or (spEncodeNonAscii in SP) then
    begin
//      r := ansiToUTF8(s);
      r := StringToUtf8(s);
      result := HSUtils.encodeURL(r, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
    end
   else
    result := HSUtils.encodeURL(s, (spEncodeNonAscii in SP),
        fullEncode or (spEncodeSpaces in SP))
end; // encodeURL

function TFileServer.findFilebyURL(url: UnicodeString; parent: Tfile=NIL; allowTemp: Boolean=TRUE): Tfile;

  procedure workTheRestByReal(const rest: UnicodeString; f: Tfile);
  var
    s: UnicodeString;
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
    result := Tfile.createTemp(Self, s, f); // temp nodes are bound to parent's node
    // the temp file inherits flags from the real folder
    if FA_DONT_LOG in f.flags then
      include(result.flags, FA_DONT_LOG);
    if not (FA_BROWSABLE in f.flags) then
      exclude(result.flags, FA_BROWSABLE);
  end; // workTheRestByReal

var
  parts: Types.TStringDynArray;
  s: string;
  cur, n: TFileNode;
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

  cur := parent.node;   // we'll move using tree's nodes
  for var i: integer :=0 to length(parts)-1 do
   begin
    s := parts[i];
    if s = '' then
      exit; // no support for null filenames
    found := FALSE;
    // search inside the VFS
    n := cur.getFirstChild();
    while assigned(n) do
    begin
      found := sameText(nodetext(n), s);
    if found then
      break;
    n := n.getNextSibling();
    end;
    if not found then // this piece was not found the virtual way
     begin
      f := TFile(nodeToFile(cur));
      if f.isRealFolder() then // but real folders have not all the stuff loaded and ready. we have another way to walk.
        begin
          if length(parts) > i+1 then
            for var j: integer :=i+1 to length(parts)-1 do
              s:=s+'\'+parts[j];
          workTheRestByReal(s, f);
        end;
      exit;
     end;
    cur := n;
    if cur = NIL then
      exit;
   end;
  result := TFile(nodeToFile(cur));
end; // findFileByURL

function TFileServer.fileExistsByURL(const url: UnicodeString): boolean;
var
  f: Tfile;
begin
  f := self.findFilebyURL(url);
  result := assigned(f);
  freeIfTemp(f);
end; // fileExistsByURL

function TFileServer.protoColon(sp: TShowPrefs): String;
const
  LUT: array [boolean] of string = ('http://','https://');
begin
  result := LUT[spHttpsUrls in sp];
end; // protoColon

function TFileServer.uri2disk(url: string; parent: Tfile=NIL; resolveLnk: boolean=TRUE): string;
var
  fi: Tfile;
  i: integer;
  append: string;
begin
  // don't consider wildcard-part when resolving
  i := reMatch(url, '[?*]', '!');
  if i = 0 then
    append:=''
   else
    begin
      i := lastDelimiter('/', url);
      append := substr(url,i);
      if i>0 then
        append[1]:='\';
      delete(url, i, MaxInt);
    end;
  try
    fi := Self.findFilebyURL(url, parent);
    if fi <> NIL then
      try
        result := ifThen(resolveLnk or (fi.lnk=''), fi.resource, fi.lnk) +append;
       finally
        freeIfTemp(fi)
      end
     else
      Result := '';
  except result:='' end;
end; // uri2disk

function TFileServer.uri2diskMaybe(const path: String; parent: Tfile=NIL; resolveLnk: Boolean=TRUE): String;
begin
  if ansiContainsStr(path, '/') then
    result := Self.uri2disk(path, parent, resolveLnk)
   else
    result := path;
end; // uri2diskmaybe


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
     +if_(f.isFolder() and not f.isRoot(), String('/'));
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
begin
  result := url(f);
  if f.isLink() then
    exit;
  if assigned(htSrv) and htSrv.active
     and (htSrv.port <> '80') and (pos(':',ip) = 0)
     and not (spNoPortInUrl in sp) then
    result := ':'+htSrv.port+result;
  if ip = '' then
    ip:=defaultIP;
  if Pos(':',ip, Pos(':',ip)+1) > 0 then // ipv6
    begin
      if Pos('%', ip) > 0  then
//        ip:='['+getTill('%',ip)+']';
        ip := getTill('%',ip)+']'
    end;
  result := protoColon(sp)+ip+result;
end; // fullURL

function TFileServer.tplFromFile(f: Tfile): Ttpl;
begin
  result := Ttpl.create(f.getRecursiveDiffTplAsStr(), tpl)
end;


function TFileServer.getAFolderPage(folder: Tfile; cd: TconnDataMain; otpl: TTpl): UnicodeString;
var
  baseurl: string;
  list: UnicodeString;
  fileTpl, folderTpl, linkTpl: UnicodeString;
  //lTable: Types.TStringDynArray;
  lTable: TMacroTableVal;
  ofsRelItemUrl, ofsRelUrl, numberFiles, numberFolders, numberLinks: integer;
  img_file: boolean;
  totalBytes: int64;
  fast: TFastUStringAppend;
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
    idxS: UnicodeString;
  begin
    idx:=0;
    p:=1;
    repeat
      p:=ipos(PATTERN, result, p);
      if p = 0 then
        exit;
      inc(idx);
      idxS:=intToStr(idx);
      delete(result, p, length(PATTERN)-length(idxS));
     {$IFDEF FPC}
      MoveChar0(idxS[1], result[p], length(idxS));
     {$ELSE ~FPC}
      moveChars(idxS[1], result[p], length(idxS));
     {$ENDIF FPC}
    until false;
  end; // applySequential

  procedure handleItem(f: Tfile);
  var
    type_, url, fingerprint, itemFolder: string;
    s: String;
    sU: UnicodeString;
    nonPerc: Types.TStringDynArray;
  begin
    if not f.isLink and ansiContainsStr(f.resource, '?') then
      exit; // unicode filename?   //mod by mars

//    if f.size > 0 then
//      inc(totalBytes, f.size);

  // build up the symbols table
    md.table := lTable;
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
      s := diffTpl['protected']
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
      if (spPwdInPages in sp) and (cd.usr > '') then
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
      sU:=linkTpl;
      inc(numberLinks);
      type_:='link';
      end
    else if f.isFolder() then
      begin
      sU := folderTpl;
      inc(numberFolders);
      type_:='folder';
      end
    else
      begin
      sU := diffTpl.getTxtByExt(ExtractFileExt(f.name));
      if sU = '' then
        sU := fileTpl;
      inc(numberFiles);
      type_:='file';
      end;

    addArray(md.table, [
      '%item-type%', type_
    ]);

    sU := xtpl(sU, nonPerc);
    md.f := f;
    tryApplyMacrosAndSymbols(self, sU, md, FALSE);
    fast.append(sU);
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
  sU: UnicodeString;
begin
  result := '';
  if (folder = NIL) or not folder.isFolder() then
    exit;

  diffTpl := Ttpl.create();
  folder.lock();
  antiDos := NIL;
try
  buildTime := now();
  cd.conn.setHeaderIfNone('Cache-Control', RawByteString('no-cache, no-store, must-revalidate, max-age=-1'));
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
  mainSection := diffTpl.getSection('');
  if mainSection = NIL then
    exit;
  useList := not mainSection.noList;

  antiDos := TantiDos.create();
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
  md.hideExt := folder.hasRecursive(FA_HIDE_EXT);

  result := diffTpl['special:begin'];
  sU := result;
  tryApplyMacrosAndSymbols(self, sU, md, FALSE);
  Result := sU;

  if useList then
    begin
      // cache these values
      fileTpl := xtpl(diffTpl['file'], lTable);
      folderTpl := xtpl(diffTpl['folder'], lTable);
      linkTpl := xtpl(diffTpl['link'], lTable);
      // this may be heavy to calculate, only do it upon request
      img_file := pos('~img_file', fileTpl) > 0;

      // build %list% based on dir[]
      numberFolders:=0; numberFiles:=0; numberLinks:=0;
      totalBytes:=0;
      oneAccessible:=FALSE;
      fast := TfastUStringAppend.Create();
      listing := TfileListing.create(Self);
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
        lTable := toMSA([
          '%upload-link%', if_(accountAllowed(FA_UPLOAD, cd, folder), diffTpl['upload-link']),
          '%files%', diffTpl[if_(n>0, String('files'),'nofiles')],
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
          if cd.conn.httpState = HCS_DISCONNECTED then
            exit;
          cd.lastActivityTime:=now();
          handleItem(listing.dir[i])
          end;
        list := fast.reset();
       finally
        listing.free;
        fast.free;
        hasher.free;
      end;

      if cd.conn.httpState = HCS_DISCONNECTED then
        exit;

      // build final page
      if not oneAccessible then
        md.archiveAvailable:=FALSE;
    end
   else
    list := '';

  md.table := lTable;
  addArray(md.table, [
    '%list%', list
  ]);
  Result := mainSection.txt;
  md.f := NIL;
  md.afterTheList := TRUE;
  try
    sU := Result;
    tryApplyMacrosAndSymbols(self, sU, md);
   finally
    Result := sU;
    md.afterTheList:=FALSE
  end;
  applySequential();
  // ensure this is the last symbol to be translated
  result := xtpl(result, [
    '%build-time%', floatToStrF((now()-buildTime)*SECONDS, ffFixed, 7,3)
  ]);
finally
  freeAndNIL(antiDos);
  folder.unlock();
  diffTpl.free;
  end;
end; // getAFolderPage

function TFileServer.existsNodeWithName(const name: String; parent: TFileNode): boolean;
var
  n: TFileNode;
begin
  result := FALSE;
  if parent = NIL then
    begin
      if Assigned(rootFile) then
        parent := rootFile.node;
    end;
  if parent = NIL then
    exit;
  while assigned(parent.data) and not TFile(nodeToFile(parent)).isFolder() do
    parent := parent.parent;
  n := parent.getFirstChild();
  while assigned(n) do
  begin
    result := sameText(nodetext(n), name);
    if result then
      exit;
    n := n.getNextSibling();
  end;
end; // existsNodeWithName

function TFileServer.getUniqueNodeName(const start: string; parent: TFileNode): string;
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

function TFileServer.getRootNode: TFileNode;
begin
  if Assigned(rootFile) then
    Result := rootFile.node
   else
    Result := NIL;
end;

function  TFileServer.getMainTree: TFileTree;
begin
  Result := MainTree;
end;

procedure TFileServer.DoImageChanged(Sender: TObject; n: TFileNode = NIL);
begin
  if n = NIL then
    n := TFile(Sender).node;
  if Assigned(n) then
  n.Imageindex := TFile(Sender).NodeImageindex;
  n.SelectedIndex := TFile(Sender).NodeImageindex;
end;

procedure TFileServer.ChangedName(Sender: TObject; Name: String);
var
  n: TFileNode;
begin
  n := TFile(Sender).node;
  if Assigned(n) then
    begin
  {$IFDEF USE_VTV}
      MainTree.InvalidateNode(n);
  {$ELSE ~USE_VTV}
      n.Text := name;
  {$ENDIF ~USE_VTV}
    end;
end;

function TFileServer.findNode(f: TObject): TFileNode;
var
  n: TFileNode;
begin
  if mainTree.Items.Count > 0 then
    for n in mainTree.Items do
      if n.Data = f then
        Exit(n);
  Result := NIL;
end;

function TFileServer.getParentNode(f: TObject): TFileNode;
var
  n: TFileNode;
begin
  n := findNode(f);
  Result := n.parent;
end;

function TFileServer.getFirstChild(f: TObject): TFileNode;
var
  n: TFileNode;
begin
  n := findNode(f);
  if Assigned(n) then
    Result := n.getFirstChild
   else
    Result := NIL
   ;
end;

function TFileServer.getNextSibling(f: TObject): TFileNode;
var
  n: TFileNode;
begin
  n := findNode(f);
  if Assigned(n) then
    begin
      Result := n.getNextSibling;
    end
    else
      Result := NIL;
end;

procedure TFileServer.DeleteChildren(f: TObject);
var
  n: TFileNode;
begin
  n := findNode(f);
  if Assigned(n) then
   {$IFDEF USE_VTV}
    MainTree.DeleteChildren(n);
   {$ELSE ~USE_VTV}
    n.DeleteChildren;
   {$ENDIF ~USE_VTV}
end;

procedure TFileServer.DeleteNode(f: TObject);
var
  n: TFileNode;
begin
  n := findNode(f);
  if Assigned(n) then
    begin
      n.delete();
    end;
end;

procedure TFileServer.ForAllSubNodes(Sender: TObject; proc: TProc<TObject>);
var
  n: TFileNode;
  i: Integer;
  ff: Tfile;
begin
  n := TFile(Sender).node;
  if n.Count > 0 then
  for i:=0 to n.Count-1 do
    begin
    {$IFDEF FPC}
      ff := TFile(nodetofile(n.items[i]));
    {$ELSE ~FPC}
      ff := TFile(nodetofile(n.item[i]));
    {$ENDIF FPC}
      if Assigned(ff) then
        proc(ff);
    end;
end;

function TFileServer.nodeToFile(n: TFileNode): TObject;
begin
  if n = NIL then
    result := NIL
   else
    result := n.data
end;
function TFileServer.nodeText(n: TFileNode): String;
begin
  if n = NIL then
   result := ''
  else
   result := n.Text
end;

function TFileServer.nodeIsLocked(n: TFileNode): boolean;
var
  f: TFile;
begin
  result := FALSE;
  f := TFile(nodeToFile(n));
  if f = NIL then
    exit
   else
   result := f.isLocked();
end; // nodeIsLocked

function TFileServer.httpServIsActive: Boolean;
begin
  Result := assigned(htSrv) and htSrv.active;
end;

function TFileServer.getConnectionsCount: Integer;
begin
  Result := htSrv.conns.Count;
end;

function TFileServer.countIPs(onlyDownloading: boolean=FALSE; usersInsteadOfIps: boolean=FALSE): integer;
begin
  Result := srvClassesLib.countIPs(htSrv, onlyDownloading, usersInsteadOfIps);
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
        setVFS(data2, Self.addFileRecur(Tfile.create(Self, ''), pf), onProgress);
        end;
      FK_COMPRESSED_ZLIB:
        // Explanation for the #0 workaround.
        // I found an uncompressable vfs file, with ZDecompressStr2() raising an exception.
        // In the end i found it was missing a trailing #0, maybe do to an incorrect handling of strings
        // containing a trailing #0. Using a zlib wrapper there is some underlying C code.
        // I was unable to reproduce the bug, but i found that correct data doesn't complain if i add an extra #0. }
        try
  //        data := ZDecompressStr2(data+#0, 31);
          data2 := ZDecompressStr3(data2+#0, TZStreamType.zsGZip);
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
        and (MessageDlg(MSG_NEWER_INCOMP+MSG_BETTERSTOP, TMsgDlgType.mtError, [mbYes, mbNo], 0, mbNo, 90) = IDYES) then
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

  pf.ExpandNode;
end;

procedure TFileServer.setVFSJZ(const vfs: RawByteString; node: TFileNode=NIL; onProgress: TLoadVFSProg = NIL);
resourcestring
  MSG_MISS_J = 'Missing "VFS.json" file in archive';
  MSG_CORRUPTED_J = '"VFS.json" is not a JSON file';
  //
  function parseAcccounts(pArray: TJSONArray): TStringDynArray;
  var
    i: Integer;
  begin
    SetLength(Result, pArray.Count);
    if pArray.Count > 0 then
      for I := 0 to pArray.Count-1 do
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
                {$IFDEF FPC}
                 v := (fj as TJSONObject).Elements[IntToStr(FK_NAME)];
                 if v <> NIL then
                   begin
                     v2 := (fj as TJSONObject).Elements[IntToStr(FK_DLCOUNT)];
                     if v2 <> NIL then
                       begin
                         autoupdatedFiles.setInt(v.Value, v2.AsInteger);
                       end;
                   end;
                {$ELSE ~FPC}
                 v := (fj as TJSONObject).FindValue(IntToStr(FK_NAME));
                 if v <> NIL then
                   begin
                     v2 := (fj as TJSONObject).FindValue(IntToStr(FK_DLCOUNT));
                     if v2 <> NIL then
                       begin
                         autoupdatedFiles.setInt(v.Value, v2.GetValue<Integer>);
                       end;
                   end;
                 {$ENDIF FPC}
               end;
             inc(i);
           end;;
      end;
  end;
  //
var
  z: TZipFile;
  function parseProperty(const v: String; var pf: Tfile; value: TJSONValue): Boolean;
  begin
    Result := True;
    if v = '1' then // FK_RESOURCE
      begin
        pf.resource := value.Value;
      end
    else if v = '2' then // FK_NAME
      begin
        pf.SetName(value.Value);
      end
    else if v = '3' then // FK_FLAGS
      begin
        var d: String := value.Value;
        var i: Integer := value.AsType<Integer>;
        move(i, pf.flags, min(SizeOf(i), SizeOf(pf.flags)));
      end
    else if v = '7' then // FK_COMMENT
      begin
        pf.comment := value.Value;
      end
    else if v = '8' then // FK_USERPWD
      begin
        var data2: RawByteString := decodeB64(value.Value);
        pf.user := UnUTF(chop(':', data2));
        pf.pwd := UnUTF(data2);
        usersInVFS.track(pf.user, pf.pwd);
      end
    else if v = '9' then // FK_ADDEDTIME
      begin
        try
          pf.atime := value.AsType<TDateTime>;
         except
          pf.atime := value.AsType<Double>;
        end;
      end
    else if v='10' then // FK_DLCOUNT
      begin
        pf.DLcount := value.AsType<Integer>;
      end
    else if v='12' then // FK_ACCOUNTS
      begin
        pf.accounts[FA_ACCESS] := parseAcccounts(value as TJSONArray);
      end
    else if v='17' then // FK_UPLOADACCOUNTS
      begin
        pf.accounts[FA_UPLOAD] := parseAcccounts(value as TJSONArray);
      end
    else if v='27' then // FK_DELETEACCOUNTS
      begin
        pf.accounts[FA_DELETE] := parseAcccounts(value as TJSONArray);
      end
    else if v='13' then // FK_FILESFILTER
      begin
        pf.filesfilter := value.Value;
      end
    else if v='14' then // FK_FOLDERSFILTER
      begin
        pf.foldersfilter := value.Value;
      end
    else if v='26' then // FK_UPLOADFILTER
      begin
        pf.uploadFilterMask := value.Value;
      end
    else if v='16' then // FK_REALM
      begin
        pf.realm := value.Value;
      end
    else if v='18' then // FK_DEFAULTMASK
      begin
        pf.defaultFileMask := value.Value;
      end
    else if v='25' then // FK_DIFF_TPL
      begin
        pf.diffTpl := value.Value;
      end
    else if v='19' then // FK_DONTCOUNTASDOWNLOADMASK
      begin
        pf.dontCountAsDownloadMask := value.Value;
      end
    else if v='20' then // FK_AUTOUPDATED_FILES
      begin
        parseAutoupdatedFilesJ(value);
      end
    else if v='23' then // FK_HFS_BUILD
      begin
        loadingVFS.build := value.Value;
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
        var idx: Integer := value.AsType<Integer>;
        var zi: Integer := z.IndexOf('icons\'+ IntToStr(idx) + '.png');
        if zi < 0 then
          zi := z.IndexOf(IntToStr(idx) + '.png');
        if zi >= 0 then
          begin
            pf.setupImage(spUseSysIcons in sp, str2pic(z.Data[zi], 16));
          end;
        zi := z.IndexOf('icons\' +IntToStr(idx) + '_BIG.png');
        if zi < 0 then
          zi := z.IndexOf(IntToStr(idx) + '_BIG.png');
        if zi >= 0 then
          begin
            pf.setupImage(spUseSysIcons in sp, str2pic(z.Data[zi], 32));
          end;
      end
    else
     Result := False;
  end;

  procedure parseNodeArrInfo(pn: TFileNode; data: TJSONArray; prgFrom, prgTo: Real); forward;

  procedure parseNodeInfo(pn: TFileNode; data: TJSONObject; prgFrom, prgTo: Real);
//  procedure parseNodeInfo(pn: TFileNode; data: TJSONValue);
  var
//    jp: TJSONPair;
    v: String;
    pf: Tfile;
//    en: TJSONObject.TEnumerator;
    prc: Real;
    step: Real;
    doCancel: Boolean;
  begin
    pf := TFile(nodeToFile(pn));
    doCancel := False;
//    en := data.GetEnumerator;
    prc := prgFrom;
    if data.Count > 0 then
    begin
     step := (prgTo-prgFrom) / data.Count;
     for var i2: Integer := 0 to data.Count-1 do
      begin
        try
          var dj := data.Pairs[i2];
          v := dj.JsonString.Value;
          if v='4' then // FK_NODE
            begin
              if Assigned(onProgress) then
                onProgress(Self, prgFrom + step * i2, doCancel);
              if doCancel then
                exit;
               ;
              if dj.JsonValue is TJSONObject then
                parseNodeInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, dj.JsonValue as TJSONObject, prc, prc+step)
               else if dj.JsonValue is TJSONArray then
                 begin
//                  var jv := (dj.JsonValue as TJSONArray)[0];
//                  if Assigned(jv) and (jv is TJSONObject) then
//                    parseNodeInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, jv as TJSONObject, prc, prc+step)
                    parseNodeArrInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, dj.JsonValue as TJSONArray, prc, prc+step)
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
  //                 parseNodeInfo(Self.addFileRecur(Tfile.create(pn.TreeView as TFileTree, ''), pn).node, ro);
                   parseNodeInfo(pn, ro, prc, prc+step);
                 end;
               end;
            end
          else
           if not parseProperty(v, pf, dj.JsonValue) then
             loadingVFS.unkFK := TRUE;
         except
           on e:exception do
            add2Log('Bad data in VFS. v='+v +'; '+ e.Message );
        end;
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

        pf.ExpandNode;
      end;
  end;

  procedure parseNodeArrInfo(pn: TFileNode; data: TJSONArray; prgFrom, prgTo: Real);
//  procedure parseNodeInfo(pn: TFileNode; data: TJSONValue);
  var
    jv: TJSONValue;
//    jp: TJSONPair;
    v: String;
    pf: Tfile;
    en: TJSONArray.TEnumerator;
    prc: Real;
    step: Real;
    doCancel: Boolean;
    dj: TJSONPair;
  begin
    pf := TFile(nodeToFile(pn));
    doCancel := False;
    en := data.GetEnumerator;
    prc := prgFrom;
    if data.Count > 0 then
    begin
     step := (prgTo-prgFrom) / data.Count;
     for var i2: Integer := 0 to data.Count-1 do
//     for var dj in data do
      begin
        try
          dj := NIL;
          jv := data[i2];
          if jv is TJSONObject then
            begin
              if (jv AS TJSONObject).Count > 0 then
                begin
                  dj := (jv AS TJSONObject).Pairs[0]
                end;

//              v := dj.ToJSON;
//              v := (dj AS TJSONObject).Value;
            end;
//           else
//            v := dj.GetValue<String>;
          if Assigned(dj) then
            v := dj.JsonString.Value
           else
            v := '';
          if v='4' then // FK_NODE
            begin
              if Assigned(onProgress) then
                onProgress(Self, prgFrom + step * i2, doCancel);
              if doCancel then
                exit;
               ;
//              parseNodeInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, dj.JsonValue as TJSONObject, prc, prc+step);
              if dj.JsonValue is TJSONObject then
                parseNodeInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, dj.JsonValue as TJSONObject, prc, prc+step)
               else if dj.JsonValue is TJSONArray then
                parseNodeArrInfo(Self.addFileRecur(Tfile.create(Self, ''), pn).node, dj.JsonValue as TJSONArray, prc, prc+step)
            end
          else if v = 'nodes' then
            begin
              var rr := dj.JsonValue as TJSONArray;
             if Assigned(rr) then
               begin
                 for var jv1 in rr do
                 begin
                   var ro := jv1 as TJSONObject;
                   parseNodeInfo(pn, ro, prc, prc+step);
                 end;
               end;
            end
          else
           if not parseProperty(v, pf, dj.JsonValue) then
             loadingVFS.unkFK := TRUE;
         except
           on e:exception do
            add2Log('Bad data in VFS. v='+v +'; '+ e.Message );
        end;
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

        pf.ExpandNode;
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
   {$IFDEF FPC}
    if not ParseJSON(UTF8String(js), j) then
   {$ELSE ~FPC}
    if not ParseJSON(js, j) then
   {$ENDIF FPC}
//    if not IsValidJson(vfs) then
      begin
//        msgDlg(MSG_MISS_J, MB_ICONERROR);
        MessageDlg(MSG_CORRUPTED_J, mtError, []);
        exit;
      end;
   {$IFDEF FPC}
    rr := j.Find('root');
   {$ELSE ~FPC}
    if j.Count > 0  then
     begin
       if j.Pairs[0].JsonString.Value = 'root' then
         rr := j.Pairs[0].JsonValue
        else
         rr := j.FindValue('root');
     end;
   {$ENDIF FPC}
     if Assigned(rr) then
       begin
         ro := NIL;
         if (rr is TJSONObject) then
          ro := rr as TJSONObject
         else if rr is TJSONArray then
           begin
             parseNodeArrInfo(getRootNode, rr as TJSONArray, 0, 1);
           end
         else
   {$IFDEF FPC}
           ParseJSON(rr.FormatJSON(), ro);
   {$ELSE ~FPC}
           ParseJSON(rr.ToJSON, ro);
   {$ENDIF FPC}
//          ro := rr.AsType<TJSONObject>;
//         ro := TJSONObject.Create;
//         ro.ParseJSONValue(rr.ToJSON);
         if Assigned(ro) then
           parseNodeInfo(getRootNode, ro, 0, 1);
       end;

   finally
     z.Free;
     str.Free;
  end;

end; // setVFSJZ

function TFileServer.addFileRecur(f: TFile; parent: TFile=NIL): TFile;
var
  pn, n: TFileNode;
begin
  if Assigned(parent) then
    pn := parent.node
   else
    pn := NIL;
  Result := addFileRecur(f, pn, n);
end;

function TFileServer.addFileRecur(f:Tfile; parent: TFileNode=NIL): Tfile;
var
  n: TFileNode;
begin
  Result := addFileRecur(f, parent, n);
end;

function TFileServer.addFileRecur(f: Tfile; parent: TFileNode; var newNode: TFileNode): Tfile;
var
  sr: TsearchRec;
  newF: Tfile;
//  s: string;
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
  while assigned(parent) and assigned(parent.data)
    and not TFile(nodeToFile(parent)).isFolder() do
    parent := parent.parent;
  // test for duplicate. it often happens when you have a shortcut to a file.
  if existsNodeWithName(f.name, parent) then
    begin
    result:=NIL;
    exit;
    end;

  if stopAddingItems then
    exit;

  newNode := mainTree.Items.AddChildObject(parent, f.name, f);
  // stateIndex assignments are a workaround to a delphi bug
  newNode.stateIndex := 0;
  newNode.stateIndex := -1;
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
    newF := Tfile.create(Self, f.resource+'\'+sr.name);
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

function TFileServer.addFileGUI(f: Tfile; parent: TFileNode; skipComment: boolean): Tfile;
var
  newNode: TFileNode;
begin
  Self.stopAddingItems := false;
  if Assigned(fOnBeforeAddFile) then
    fOnBeforeAddFile(f);
  try
    if not Self.stopAddingItems then
      result := Self.addFileRecur(f, parent, newNode);
   finally
    if Assigned(fOnAfterAddFile) then
      fOnAfterAddFile(Result, parent, newNode, skipComment, stopAddingItems);
  end;
end;

function TFileServer.removeFile(f: Tfile): Boolean;
begin
  Result := False;
  if f = NIL then
    Result := removeFile(TFileNode(NIL))
   else
    if f.node <> NIL then
      Result := removeFile(f.node);
end;

function TFileServer.removeFile(node: TFileNode): Boolean;
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
    node.Delete();
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
    Self.fRootFile := NIL;
  VFSmodified := TRUE
end;

procedure TFileServer.getPage(const sectionName: RawByteString; data: TconnDataMain; f:Tfile=NIL; tpl2use: Ttpl=NIL);
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
      if i >= htSrv.conns.count then
        break;
      d := conn2data(i);
      if d.address <> data.address then
        continue;
      fn := '';
      // fill fields
      if d.isReceivingFile then
        begin
        t := tpl2use['progress-upload-file'];
        fn := d.uploadSrc; // already encoded by the browser
        bytes := d.conn.bytesPosted;
        total := d.conn.post.length;
        end;
      if d.isSendingFile then
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
    i: Integer;
  begin
    if sectionName <> 'upload' then
      exit;
    files := '';
    for i :=1 to 10 do
      files := files+ xtpl(tpl2use['upload-file'], ['%idx%',intToStr(i)]);
    addArray(md.table, ['%upload-files%', files]);
  end; // addUploadSymbols

  procedure addUploadResultsSymbols();
  var
    files: string;
    i: Integer;
  begin
    if sectionName <> 'upload-results' then
      exit;
    files := '';
    if length(data.uploadResults) > 0 then
     for i :=0 to length(data.uploadResults)-1 do
      with data.uploadResults[i] do
        files := files+xtpl(tpl2use[ if_(reason='', RawByteString('upload-success'),'upload-failed') ],[
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
  sU: UnicodeString;
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
    sU := s;
    tryApplyMacrosAndSymbols(Self, sU, md, FALSE);
    s := sU;

    if data.conn.reply.mode = HRM_REPLY then
      s := section.txt
     else
      begin
        s := xtpl(tpl2use['error-page'], ['%content%', section.txt]);
        if s = '' then
          s := section.txt;
      end;
    sU := s;
    tryApplyMacrosAndSymbols(Self, sU, md);
    s := sU;

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
  lToZstd: Boolean; // ZStandart
begin
  lToGZip := spCompressed in sp;
  lToBr   := spCompressed in sp;
  lToZstd := supportZStd and (spCompressed in sp);
//  if not compressedbrowsingChk.checked then
//    exit;
  lToBr := lToBr and cd.conn.isAcceptEncoding('Br');

  lToZstd := lToZstd and (cd.conn.reply.body <> '')
              and cd.conn.isAcceptEncoding('zstd');

  lToGZip := lToGZip and (cd.conn.reply.body <> '');
  lToGZip := lToGZip and cd.conn.isAcceptEncoding('gzip');
  if (not lToGZip) and (not lToZstd) and not cd.conn.reply.IsCompressed then
    begin
      cd.conn.reply.comprType := '';
      Exit;
    end;
  s := cd.conn.reply.body;
  if s = '' then
    exit;

 {$IFDEF ZIP_ZSTD}
  if lToZstd and not cd.conn.reply.IsCompressed then
    s := ZSTDCompressStr(s)
   else
 {$ENDIF ~ZIP_ZSTD}
    begin
    // workaround for IE6 pre-SP2 bug
      if (cd.workaroundForIEutf8  = wi_toDetect) and (cd.agent > '') then
        if reMatch(cd.agent, '^MSIE [4-6]\.', '!') > 0 then // version 6 and before
          cd.workaroundForIEutf8 := wi_yes
         else
          cd.workaroundForIEutf8 := wi_no;
    //s:=ZcompressStr2(s, zcFastest, 31,8,zsDefault);
      if lToGZip and not cd.conn.reply.IsCompressed then
        s := ZcompressStr(s, TCompressionLevel.clDefault, TZStreamType.zsGZip);

      if (cd.workaroundForIEutf8  = wi_yes) and (length(s) < BAD_IE_THRESHOLD) then
        lToGZip := false;
    end;
  if cd.conn.reply.IsCompressed and (cd.conn.reply.comprType <> '')
     and (((cd.conn.reply.comprType = 'gzip') and lToGZip)
         or ((cd.conn.reply.comprType = 'zstd') and lToZstd)
         or ((cd.conn.reply.comprType = 'Br') and lToBr)
         )
      then
    begin
      cd.conn.addHeader('Content-Encoding', RawByteString(cd.conn.reply.comprType));
      cd.conn.reply.body := s;
    end
   else
  if lToZstd then
    begin
      cd.conn.reply.comprType := 'zstd';
      cd.conn.addHeader('Content-Encoding', RawByteString('zstd'));
      cd.conn.reply.body := s;
    end
  else if lToGZip then
    begin
      cd.conn.reply.comprType := 'gzip';
      cd.conn.addHeader('Content-Encoding', RawByteString('gzip'));
      cd.conn.reply.body := s;
    end
   else
    begin
      if cd.conn.reply.IsCompressed then
        begin
          if cd.conn.reply.comprType = 'gzip' then
            cd.conn.reply.body := ZDecompressStr3(cd.conn.reply.body)
 {$IFDEF ZIP_ZSTD}
           else if cd.conn.reply.comprType = 'zstd' then
            cd.conn.reply.body := ZSTDDecompressStr(cd.conn.reply.body)
 {$ENDIF ~ZIP_ZSTD}
          ;
          cd.conn.reply.IsCompressed := False;
        end;

    end;
end; // compressReply

function connO2data(p: Tobject): TconnData; inline; overload;
begin
  if p = NIL then
    result := NIL
   else
    result := TconnData((p as ThttpConn).data)
end; // connO2data

function TFileServer.conn2data(i: integer): TconnData;
var
  cnt: Integer;
begin
  cnt := htSrv.conns.count;
  try
    if i < cnt then
      result := connO2data(htSrv.conns[i])
    else
      result := connO2data(htSrv.offlines[i-cnt])
   except
    result := NIL
  end
end; // conn2data

function TFileServer.countDownloads(const ip: String=''; const user: String=''; f: Tfile=NIL): Integer;
var
  i: integer;
  d: TconnData;
begin
  result := 0;
  i := 0;
  while i < htSrv.conns.count do
  begin
  d := conn2data(i);
  if d.isDownloading
  and ((f = NIL) or (assigned(d.lastFile) and d.lastFile.same(f)))
  and ((ip = '') or addressMatch(ip, d.address))
  and ((user = '') or sameText(user, d.usr))
  then
    inc(result);
  inc(i);
  end;
end;

function TFileServer.getSP0: TShowPrefs;
begin
  if Assigned(fOnGetSP) then
    Result := fOnGetSP()
   else
    Result := [];
end;

function TFileServer.getLP0: TLoadPrefs;
begin
  if Assigned(fOnGetLP) then
    Result := fOnGetLP()
   else
    Result := [];
end;

function TFileServer.getLogP0: TLogPrefs;
begin
  Result := [];
  if prefs.getDPrefBool('log-banned') then
    Include(Result, logBanned);
  if prefs.getDPrefBool('log-icons') then
    Include(Result, logIcons);
  if prefs.getDPrefBool('log-browsing') then
    Include(Result, logBrowsing);
  if prefs.getDPrefBool('log-progress') then
    Include(Result, logProgress);
  if prefs.getDPrefBool('log-server-start') then
    Include(Result, logServerstart);
  if prefs.getDPrefBool('log-server-stop') then
    Include(Result, logServerstop);
  if prefs.getDPrefBool('log-connections') then
    Include(Result, logconnections);
  if prefs.getDPrefBool('log-disconnections') then
    Include(Result, logDisconnections);
  if prefs.getDPrefBool('log-uploads') then
    Include(Result, logUploads);
  if prefs.getDPrefBool('log-full-downloads') then
    Include(Result, logFullDownloads);
  if prefs.getDPrefBool('log-deletions') then
    Include(Result, LogDeletions);
  if prefs.getDPrefBool('log-others') then
    Include(Result, logOtherEvents);
  if prefs.getDPrefBool('log-bytes-received') then
    Include(Result, logBytesReceived);
  if prefs.getDPrefBool('log-bytes-sent') then
    Include(Result, logBytesSent);
  if prefs.getDPrefBool('log-only-served') then
    Include(Result, logOnlyServed);
  if prefs.getDPrefBool('log-requests') then
    Include(Result, logRequests);
  if prefs.getDPrefBool('log-replies') then
    Include(Result, logReplies);
  if prefs.getDPrefBool('log-dump-request') then
    Include(Result, dumpRequests);
  if prefs.getDPrefBool('log-dump-traffic') then
    Include(Result, dumpTraffic);
  if prefs.getDPrefBool('log-macros') then
    Include(Result, logMacros);
end;

procedure TFileServer.initPrefs;
begin
  prefs.addPrefBool('log-uploads', True);
  prefs.addPrefBool('log-full-downloads', True);
  prefs.addPrefBool('log-deletions', True);
end;

procedure TFileServer.syncSP;
begin
  fSP := getSP0;
end;

procedure TFileServer.syncLP;
begin
  fLP := getLP0;
end;

procedure TFileServer.syncLogP;
begin
  fLogP := getLogP0;
end;

function TFileServer.shouldRecur(data: TconnDataMain): boolean;
begin
  result := (spRecursiveListing in SP)
        and data.allowRecur
end; // shouldRecur

procedure TFileServer.add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = True);
begin
  if Assigned(fOnAdd2Log) then
    fOnAdd2Log(lines, cd, clr, doSync);
end;

procedure TFileServer.doOnIPsEverChanged;
begin
  if Assigned(fOnIPsEverChanged) then
    fOnIPsEverChanged;
end;

procedure TFileServer.doFlash(event: String);
begin
  if Assigned(fOnFlash) then
    fOnFlash(event);
end;

procedure TFileServer.doSetupDownloadIcon(data: TconnData);
begin
  if Assigned(fOnSetupDownloadIcon) then
    fOnSetupDownloadIcon(data);
end;

procedure TFileServer.doStatusChanged(Open: Boolean);
begin
  if Assigned(fOnStatusChanged) then
    fOnStatusChanged(Open);
end;

procedure TFileServer.doRefreshConn(data: TconnData);
begin
  if Assigned(fOnRefreshConn) then
    fOnRefreshConn(data);
end;

procedure TFileServer.doInitConnData(data: TconnData);
begin
  if Assigned(fOnInitConnData) then
    fOnInitConnData(data);
end;

procedure TFileServer.doRemoveConnData(data: TconnData);
begin
  if Assigned(fOnRemoveConnData) then
    fOnRemoveConnData(data);
end;

procedure TFileServer.doUpdateTray(what: TUpdateTrayWhat);
begin
  if Assigned(fOnUpdateTray) then
    fOnUpdateTray(what);
end;

function sendPic(cd: TconnDataMain; idx: integer=-1): boolean;
var
  imgurl, s, url: string;
  special: (no, graph);
begin
  url := decodeURL(cd.conn.httpRequest.url);
  result := FALSE;
  special := no;
  if idx < 0 then
    begin
      s := url;
      if not ansiStartsText('/~img', s) then
        exit;
      imgurl := s;
      delete(s,1,5);
      // converts special symbols
      if ansiStartsText('_graph', s) then
        special:=graph else
      if ansiStartsText('_link', s) then
        idx:=ICON_LINK else
      if ansiStartsText('_file', s) then
        idx := ICON_FILE else
      if ansiStartsText('_folder', s) then
        idx := ICON_FOLDER else
      if ansiStartsText('_lock', s) then
        idx := ICON_LOCK
       else
        try
          idx := strToInt(s)
         except
          exit
        end;
    end;

  if (special = no) and ((idx < 0) or (idx >= IconsDM.images.count)) then
    exit;

  case special of
    no: begin
          var pic := pic2str(idx, 16);
          if (imgurl > '') and notModified(cd.conn, imgurl + ':' + pic2hash(pic), '') then
            exit(True);
          cd.conn.reply.body := pic;
        end;
    graph: cd.conn.reply.body := getGraphPic(cd, sendGraphWidth, sendGraphHeight);
  end;

  result := TRUE;
  {**
  // browser caching support
  if idx < startingImagesCount then
    s:=intToStr(idx)+':'+etags.values['exe']
  else
    s:=etags.values['icon.'+intToStr(idx)];
  if notModified(cd.conn, s, '') then
    exit;
  }
  cd.conn.reply.mode := HRM_REPLY;
  {$IFDEF HFS_GIF_IMAGES}
  cd.conn.reply.contentType := 'image/gif';
  {$ELSE ~HFS_GIF_IMAGES}
  cd.conn.reply.contentType := 'image/png';
  {$ENDIF HFS_GIF_IMAGES}
  cd.conn.reply.bodyMode := RBM_RAW;
  cd.downloadingWhat := DW_ICON;
  cd.lastFN := copy(url,2,1000);
end; // sendPic

function notModified(conn: ThttpConn; f: Tfile): boolean; overload;
begin
  result := notModified(conn, f.resource)
end;

procedure TFileServer.httpEventNG(event: ThttpEvent; conn: ThttpConn);
resourcestring
  MSG_LOG_SERVER_START = 'Server start';
  MSG_LOG_SERVER_STOP = 'Server stop';
  MSG_LOG_CONNECTED = 'Connected';
  MSG_LOG_DISC_SRV = 'Disconnected by server';
  MSG_LOG_DISC = 'Disconnected';
  MSG_LOG_GOT = 'Got %d bytes';
  MSG_LOG_BYTES_SENT = '%s bytes sent';
  MSG_LOG_SERVED = 'Served %s';
  MSG_LOG_HEAD = 'Served head';
  MSG_LOG_NOT_MOD = 'Not modified, use cache';
  MSG_LOG_REDIR = 'Redirected to %s';
  MSG_LOG_NOT_SERVED = 'Not served: %d - %s';
  MSG_LOG_UPL = 'Uploading %s';
  MSG_LOG_UPLOADED = 'Fully uploaded %s - %s @ %sB/s';
  MSG_LOG_UPL_FAIL = 'Upload failed %s';
  MSG_LOG_DL = 'Fully downloaded - %s @ %sB/s - %s';
var
  data: TconnData;
  f: Tfile;
  url: UnicodeString;

  Freq, StartCount, StopCount: Int64;
  TimingSeconds: real;

  procedure switchToDefaultFile();
  var
    default: Tfile;
  begin
    if (f = NIL) or not f.isFolder() then
      exit;
    default := f.getDefaultFile();
    if default = NIL then
      exit;
    freeIfTemp(f);
    f := default;
  end; // switchToDefaultFile

  function calcAverageSpeed(bytes: int64): integer;
  begin
    result := round(safeDiv(bytes, (now()-data.fileXferStart)*SECONDS))
  end;

  function runEventScript(const event: String; table: array of UnicodeString): String; overload;
  var
    md: TmacroData;
    pleaseFree: boolean;
    sU: UnicodeString;
  begin
    result := trim(eventScripts[event]);
    if result = '' then
      exit;
    ZeroMemory(@md, sizeOf(md));
    md.cd := data;
    md.table := toMSA(table);
    md.tpl := eventScripts;
    addArray(md.table, ['%event%', event]);
    pleaseFree := FALSE;
  try
    if data.isReceivingFile then
      begin
      // we must encapsulate it in a Tfile to expose file properties to the script. we don't need to cache the object because we need it only once.

      md.folder := data.lastFile;
      if assigned(md.folder) then
        md.f := Tfile.createTemp(Self, data.uploadDest, md.folder)
       else
        md.f := Tfile.createTemp(Self, data.uploadDest)
        ;
      md.f.size := sizeOfFile(data.uploadDest);
      pleaseFree:=TRUE;

      end
    else if assigned(f) then
      md.f := f
    else if assigned(data) then
      md.f := data.lastFile;

    if assigned(md.f) and (md.folder = NIL) then
      md.folder := md.f.parent;
    sU := Result;
    tryApplyMacrosAndSymbols(Self, sU, md);
    Result := sU;

  finally
    if pleaseFree then
      freeIfTemp(md.f);
    end;
  end; // runEventScript

  function runEventScript(const event: String): String; overload;
  begin
    result := runEventScript(event, [])
  end;

  procedure doLog();
  var
    i: integer;
    s: string;
     function decodedUrl(): String;
      begin
      if conn = NIL then
        exit('');
      result := decodeURL(conn.httpRequest.url);
     end;
  begin
    if assigned(data) and data.dontLog and (event <> HE_DISCONNECTED) then
      exit; // we exit expect for HE_DISCONNECTED because dontLog is always set AFTER connections, so HE_CONNECTED is always logged. The coupled HE_DISCONNECTED should be then logged too.

    if assigned(data) and (data.preReply = PR_BAN)
    and not (logBanned in logP) then exit;

    if not (event in [HE_OPEN, HE_CLOSE, HE_CONNECTED, HE_DISCONNECTED, HE_GOT, HE_DESTROID]) then
      if not ((logIcons in logP) and Assigned(data) and (data.downloadingWhat = DW_ICON))
      and not ((logBrowsing in logP) and Assigned(data) and (data.downloadingWhat = DW_FOLDERPAGE))
      and not ((logProgress in logP) and (decodedUrl() = '/~progress')) then
        exit;

    if not (event in [HE_OPEN, HE_CLOSE, HE_DESTROID])
    and addressMatch(dontLogAddressMask, data.address) then
      exit;

    case event of
      HE_OPEN: if (logServerstart in logP) then
                 add2log(MSG_LOG_SERVER_START);
      HE_CLOSE: if (logServerStop in logP) then
                  add2log(MSG_LOG_SERVER_STOP);
      HE_CONNECTED: if (logconnections in logP) then
                      add2log(MSG_LOG_CONNECTED, data);
      HE_DISCONNECTED: if (logDisconnections in logP) then
        add2log(if_(conn.disconnectedByServer, MSG_LOG_DISC_SRV,MSG_LOG_DISC)
          +nonEmptyConcat(': ', data.disconnectReason)
          +if_(conn.bytesSent>0, ' - '+format(MSG_LOG_BYTES_SENT, [dotted(conn.bytesSent)])),
        data);
      HE_GOT:
        begin
        i := conn.bytesGot-data.lastBytesGot;
        if i <= 0 then
          exit;
        if logBytesReceived in logP then
          if now()-data.bytesGotGrouping.since <= BYTES_GROUPING_THRESHOLD then
            inc(data.bytesGotGrouping.bytes, i)
          else
            begin
            add2log(format(MSG_LOG_GOT,[i+data.bytesGotGrouping.bytes]), data);
            data.bytesGotGrouping.since := now();
            data.bytesGotGrouping.bytes := 0;
            end;
        inc(data.lastBytesGot, i);
        end;
      HE_SENT:
        begin
        i:=conn.bytesSent-data.lastBytesSent;
        if i <= 0 then exit;
        if logBytesSent in logP then
          if now()-data.bytesSentGrouping.since <= BYTES_GROUPING_THRESHOLD then
            inc(data.bytesSentGrouping.bytes, i)
          else
            begin
            add2log(format(MSG_LOG_BYTES_SENT,[dotted(i+data.bytesSentGrouping.bytes)]), data);
            data.bytesSentGrouping.since:=now();
            data.bytesSentGrouping.bytes:=0;
            end;
        inc(data.lastBytesSent, i);
        end;
      HE_REQUESTED:
        if not (logOnlyServed in logP)
        or (conn.reply.mode in [HRM_REPLY, HRM_REPLY_HEADER, HRM_REDIRECT]) then
          begin
          data.logLaterInApache := TRUE;
          if logRequests in logP then
            begin
            s := subStr(conn.getHeader('Range'), 7);
            if s > '' then
              s:=TAB+'['+s+']';
            add2log(format('Requested %s %s%s', [ METHOD2STR[conn.httpRequest.method], decodedUrl(), s ]), data);
            end;
          if dumpRequests in logP then
            add2log(RawByteString('Request dump')+CRLF+conn.httpRequest.full, data);
          end;
      HE_REPLIED:
        if logReplies in logP then
         case conn.reply.mode of
            HRM_REPLY: if not data.fullDLlogged then add2log(format(MSG_LOG_SERVED, [smartSize(conn.bytesSentLastItem)]) + ' ' + conn.reply.comprType, data);
            HRM_REPLY_HEADER: add2log(MSG_LOG_HEAD, data);
            HRM_NOT_MODIFIED: add2log(MSG_LOG_NOT_MOD, data);
            HRM_REDIRECT: add2log(format(MSG_LOG_REDIR, [conn.reply.url]), data);
            else if not (logOnlyServed in logP) then
              add2log(format(MSG_LOG_NOT_SERVED, [HRM2CODE[conn.reply.mode], HRM2STR[conn.reply.mode] ])
                +nonEmptyConcat(': ', data.error), data);
            end;
      HE_POST_FILE:
        if (logUploads in logP) and (data.uploadFailed = '') then
          add2log(format(MSG_LOG_UPL, [data.uploadSrc]), data);
      HE_POST_END_FILE:
        if (logUploads in logP) then
          if data.uploadFailed = '' then
            add2log(format(MSG_LOG_UPLOADED, [
              data.uploadSrc,
              smartSize(conn.bytesPostedLastItem),
              smartSize(calcAverageSpeed(conn.bytesPostedLastItem)) ]), data)
          else
            add2log(format(MSG_LOG_UPL_FAIL, [data.uploadSrc]), data);
      HE_LAST_BYTE_DONE:
        if (logFullDownloads in logP)
        and data.countAsDownload
        and (data.downloadingWhat in [DW_FILE, DW_ARCHIVE]) then
          begin
          data.fullDLlogged := TRUE;
          add2log(format(MSG_LOG_DL, [
            smartSize(conn.bytesSentLastItem),
            smartSize(calcAverageSpeed(conn.bytesSentLastItem)),
            decodedUrl()]), data);
          end;
      end;

    { apache format log is only related to http events, that's why it resides
    { inside httpEvent(). moreover, it needs to access to some variables. }
    if (logFile.filename = '') or (logFile.apacheFormat = '')
    or (data = NIL) or not data.logLaterInApache
    or not (event in [HE_LAST_BYTE_DONE, HE_DISCONNECTED]) then exit;

    data.logLaterInApache := FALSE;
    s:=xtpl(logfile.apacheFormat, [
      '\t', TAB,
      '\r', #13,
      '\n', #10,
      '\"', '"',
      '\\', '\'
    ]);
    s := reCB('%(!?[0-9,]+)?(\{([^}]+)\})?>?([a-z])', s, apacheLogCb, data);
    appendFileU(getDynLogFilename(data), s+CRLF);
  end; // doLog

  function limitsExceededOnConnection():boolean;
  begin
  if noLimitsFor(data.account) then result:=FALSE
  else
    result:=(maxConnections>0) and (htSrv.conns.count > maxConnections)
      or (maxConnectionsIP>0)
        and (countConnectionsByIP(htSrv, data.address) > maxConnectionsIP)
      or (maxIPs>0) and (countIPs() > maxIPs)
  end; // limitsExceededOnConnection

  function limitsExceededOnDownload(): boolean;
  var
    was: string;
  begin
    result := FALSE;
    data.disconnectReason := '';

    if data.conn.ignoreSpeedLimit then
      exit;

    if (maxContempDLs > 0) and (countDownloads() > maxContempDLs)
    or (maxContempDLsIP > 0) and (countDownloads(data.address) > maxContempDLsIP) then
      data.disconnectReason := MSG_MAX_SIM_DL
    else if (maxIPsDLing > 0) and (countIPs(TRUE) > maxIPsDLing) then
      data.disconnectReason := MSG_MAX_SIM_ADDR_DL
    else if (spPreventLeeching in sp) and (countDownloads(data.address, '', f) > 1) then
      data.disconnectReason := 'Leeching';

    was := data.disconnectReason;
    runEventScript('download');

    result := data.disconnectReason > '';
    if not result then
      exit;
    data.countAsDownload:=FALSE;
    self.getPage(if_(was=data.disconnectReason, RawByteString('max contemp downloads'), 'deny'), data);
  end; // limitsExceededOnDownload

  procedure extractParams();
  const
    MAX = 1000;
  var
    s: string;
    i: integer;
  begin
    s:=url;
    url:=chop('?',s);
    data.urlvars.clear();
    if s > '' then
      begin
        extractStrings(['&'], [], @s[1], data.urlvars);
        for i:=0 to data.urlvars.count-1 do
          data.urlvars[i]:=decodeURL(data.urlvars[i]);
      end;
  end; // extractParams

  procedure closeUploadingFile();
  begin
  if data.f = NIL then exit;
  closeFile(data.f^);
  dispose(data.f);
  data.f:=NIL;
  end; // closeUploadingFile

  // close and eventually delete/rename
  procedure closeUploadingFile_partial(lp: TLoadPrefs);
  begin
    if (data = NIL) or (data.f = NIL) then
      exit;
    closeUploadingFile();
    if lpDeletePartialUploads in lp then
      deleteFile(data.uploadDest)
     else if renamePartialUploads = '' then
      exit;
    if ipos('%name%', renamePartialUploads) = 0 then
      renameFile(data.uploadDest, data.uploadDest+renamePartialUploads)
    else
      renameFile(data.uploadDest,
        extractFilePath(data.uploadDest) + xtpl(renamePartialUploads,['%name%',extractFileName(data.uploadDest)]) );
  end; // closeUploadingFile_partial

  function isDownloadManagerBrowser():boolean;
  begin
    result := (pos('GetRight', data.agent)>0)
      or (pos('FDM',data.agent)>0)
      or (pos('FlashGet',data.agent)>0)
  end; // isDownloadManagerBrowser

  procedure logUploadFailed();
  begin
    if not (logUploads in logP) then
      exit;
    add2log(format(MSG_LOG_UPL_FAIL, [data.uploadSrc])+' : '+data.uploadFailed, data);
  end; // logUploadFile

  function eventToFilename(const event: String; table: array of UnicodeString): String;
  var
    i: integer;
  begin
  result:=trim(stripChars(runEventScript(event, table), [TAB,#10,#13]));
  // turn illegal chars into underscores
  for i:=1 to length(result) do
    if result[i] in ILLEGAL_FILE_CHARS-[':','\'] then
      result[i]:='_';
  end; // eventToFilename

  procedure getUploadDestinationFileName();
  var
    i: integer;
    fn, ext, s: string;
  begin
  new(data.f);
  fn:=data.uploadSrc;

  data.uploadDest:=f.resource+'\'+fn;
  assignFile(data.f^, data.uploadDest );

  // see if an event script wants to change the name
  s:=eventToFilename('upload name', []);

  if validFilepath(s) then // is it valid anyway?
    begin
    if pos('\', s) = 0 then  // it's just the file name, no path specified: must include the path of the current folder
      s:=f.resource+'\'+s;
    // ok, we'll use this new name
    data.uploadDest:=s;
    fn:=extractFileName(s);
    end;

  if lpNumberFilesOnUpload in lp then
    begin
    ext:=extractFileExt(fn);
    setLength(fn, length(fn)-length(ext));
    i:=0;
    while fileExists(data.uploadDest) do
      begin
      inc(i);
      data.uploadDest:=format('%s\%s (%d)%s', [f.resource, fn, i, ext]);
      end;
    end;
  assignFile(data.f^, data.uploadDest);
  end; // getUploadDestinationFileName

  procedure addContentDisposition(const fn: String; attach:boolean=TRUE);
  var
    r: RawByteString;
  begin
//  conn.addHeader( 'Content-Disposition: '+if_(attach, 'attachment; ')+'filename*=UTF-8''"'+UTF8encode(data.lastFN)+'";');
//  conn.addHeader('Content-Disposition', RawByteString('attachment; filename="')+encodeURL(data.lastFN)+'";');
//  conn.addHeader('Content-Disposition', if_(attach, RawByteString('attachment; ')) + RawByteString('filename*=UTF-8''"')+encodeURL(UTF8encode(fn))+'";');
    r := RawByteString('filename="')+ encodeURLA(fn)+ RawByteString('";');
    if attach then
      r := RawByteString('attachment; ') + r;
    conn.setHeaderIfNone(RawByteString('Content-Disposition'), r);
  end;

  function sessionRedirect():boolean;
  var
    s: TSession;
  begin
    if (data.sessionID = '') or (sessions.noSession(data.sessionID)) then
      exit(FALSE);
    s := sessions[data.sessionid];
    if s.redirect = '' then
      exit(FALSE);
    conn.reply.mode := HRM_REDIRECT;
    conn.reply.url := s.redirect;
    s.redirect := ''; // only once
    result := TRUE;
  end; // sessionRedirect

  function sessionSetup():boolean;
  var
//    idx: Integer;
    sid: TSessionId;
    s: Tsession;
  begin
    result:=TRUE;
    if data = NIL then
      Exit;
    data.usr:='';
    data.pwd:='';
//    if sessions.noSession(data.sessionID) then
     begin
      sid := conn.getCookie(SESSION_COOKIE);
      if (sid = '') then
        sid:=data.urlvars.Values[SESSION_COOKIE];
      if (sid = Tsession.sanitizeSID(sid))  and (sid.length >= 10) then
        data.sessionID := sid
       else
        data.sessionID := ''
        ;
      if sessions.noSession(data.sessionID) then
      begin
      data.sessionID:= sessions.initNewSession(conn.address, data.sessionID);
      if sid <> data.sessionID then
        conn.setCookie(SESSION_COOKIE, data.sessionID, ['path','/'], 'HttpOnly'); // the session is site-wide, even if this request was related to a folder
      end;
     end;
    s := sessions[data.sessionID];
    if Assigned(s) then
     begin
        if s.ip <> conn.address then
          begin
          conn.delCookie(SESSION_COOKIE); // legitimate clients that changed address must clear their cookie, or they will be stuck with this invalid session
          conn.reply.mode:=HRM_DENY;
          result:=FALSE;
          exit;
          end;
      s.keepAlive();
     end;
    if (conn.httpRequest.user > '') then
      begin
      data.usr:=conn.httpRequest.user;
      data.pwd:=conn.httpRequest.pwd;
      data.account:=getAccount(data.usr);
      exit;
      end;
    if Assigned(s) then
     begin
      data.account:=getAccount(s.user);
     end;
    if data.account <> NIL then
      begin
       data.usr:=data.account.user;
       data.pwd:=data.account.pwd;
      end;
  end; // sessionSetup

  procedure serveTar();
  var
    tar: TtarStream;
    nofolders, selection, itsAsearch: boolean;

    procedure addFolder(f:Tfile; ignoreConnFilters:boolean=FALSE);
    var
      i, ofs: integer;
      listing: TfileListing;
      fi: Tfile;
      fIsTemp: boolean;
      s: string;
    begin
      if not f.accessFor(data) then
        exit;
      listing := TfileListing.create(Self);
      try
        listing.ignoreConnFilter := ignoreConnFilters;
        listing.timeout := now()+1/MINUTES;
        listing.fromFolder(lp, f, data, shouldRecur(data));
        fIsTemp:=f.isTemp();
        ofs:=length(f.resource)-length(f.name)+1;
        for i:=0 to length(listing.dir)-1 do
          begin
          if conn.httpState = HCS_DISCONNECTED then
            break;

          fi:=listing.dir[i];
          // we archive only files, folders are just part of the path
          if not fi.isFile() then continue;
          if not fi.accessFor(data) then continue;

          // build the full path of this file as it will be in the archive
          if noFolders then
            s:=fi.name
          else if fIsTemp and not (FA_SOLVED_LNK in fi.flags)then
            s:=copy(fi.resource, ofs, MAXINT) // pathTill won't work this case, because f.parent is an ancestor but not necessarily the parent
          else
            s:= self.pathTill(fi, f.parent); // we want the path to include also f, so stop at f.parent

          tar.addFile(fi.resource, s);
          end
       finally
        listing.free
      end;
    end; // addFolder

    procedure addSelection();
    var
      t: string;
      ft: Tfile;
      s: String;
    begin
    selection:=FALSE;
    for s in data.getFilesSelection() do
        begin
        selection:=TRUE;
        if dirCrossing(s) then
          continue;
        ft := Self.findFilebyURL(s, f);
        if ft = NIL then
          continue;
        try
          if not ft.accessFor(data) then
            continue;
          // case folder
          if ft.isFolder() then
            begin
            addFolder(ft, TRUE);
            continue;
            end;
          // case file
          if not fileExists(ft.resource) then
            continue;
          if noFolders then
            t:=substr(s, lastDelimiter('\/', s)+1)
          else
            t:=s;
          tar.addFile(ft.resource, t);
        finally freeIfTemp(ft) end;
        end;
    end; // addSelection

  begin
    if not f.hasRecursive(FA_ARCHIVABLE) then
      begin
      Self.getPage('deny', data);
      exit;
      end;
    data.downloadingWhat := DW_ARCHIVE;
    data.countAsDownload := TRUE;
    if limitsExceededOnDownload() then
      exit;

    // this will let you get all files as flatly arranged in the root of the archive, without folders
    noFolders := not stringExists(data.postVars.values['nofolders'], ['','0','false']);
    itsAsearch := data.urlvars.values['search'] > '';

    tar := TtarStream.create(); // this is freed by ThttpSrv
    try
      tar.fileNamesOEM := spOemTar in sp;
      addSelection();
      if not selection then
        addFolder(f);

      if tar.count = 0 then
       begin
        tar.free;
        data.disconnectReason := 'There is no file you are allowed to download';
        Self.getPage('deny', data, f);
        exit;
       end;
      data.fileXferStart := now();
      conn.reply.mode:=HRM_REPLY;
      conn.reply.contentType := DEFAULT_MIME;
      conn.reply.bodyMode := RBM_STREAM;
      conn.reply.bodyStream := tar;

      if f.name = '' then
        exit; // can this really happen?
      data.lastFN := if_(f.name='/', 'home', f.name)
        +'.'+if_(selection, 'selection', if_(itsAsearch, 'search', 'folder'))
        +'.tar';
      data.lastFN := first(eventToFilename('archive name', [
        '%archive-name%', data.lastFN,
        '%mode%', if_(selection, 'selection','folder'),
        '%archive-size%', intToStr(tar.size)
       ]), data.lastFN);
      if not (spNoContentDisposition in sp) then
        addContentDisposition(data.lastFN);
     except
      tar.free
    end;
  end; // serveTar

  procedure checkCurrentAddress();
  begin
    if selftesting then
      exit;
    if limitsExceededOnConnection() then
      data.preReply := PR_OVERLOAD;
    if isBanned(data)  then
     begin
      data.disconnectReason := 'banned';
      data.preReply := PR_BAN;
      if noReplyBan then
        conn.reply.mode := HRM_CLOSE;
     end;
  end; // checkCurrentAddress

  procedure handleRequest();
  var
    dlForbiddenForWholeFolder, specialGrant: boolean;
    mode, urlCmd: string;
    acc: Paccount;

    function accessGranted(forceFile:Tfile=NIL):boolean;
    resourcestring
      MSG_LOGIN_FAILED = 'Login failed';
    begin
    result:=FALSE;
    if assigned(forceFile) then
      f:=forceFile;
    if f = NIL then
      exit;
    if f.isFile() and (dlForbiddenForWholeFolder or f.isDLforbidden()) then
      begin
      Self.getPage('deny', data);
      exit;
      end;
    result:=f.accessFor(data);
    // sections are accessible. You can implement protection in place, if needed.
    if not result  and (f = Self.rootFile)
    and ((mode='section') or startsStr('~', urlCmd) and Self.tpl.sectionExist(copy(urlCmd,2,MAXINT))) then
      begin
      result:=TRUE;
      specialGrant:=TRUE;
      end;
    if result then
      exit;
    if f.isFolder() and sessionRedirect() then // forbidden folder, but we were asked to go elsewhere
      exit;
    conn.reply.realm := f.getShownRealm(LP);
    runEventScript('unauthorized');
    Self.getPage('login', data, f);
    // log anyone trying to guess the password
    if (forceFile = NIL) and stringExists(data.usr, getAccountList(TRUE, FALSE))
    and (logOtherEvents in logP) then
      add2log(MSG_LOGIN_FAILED, data);
    end; // accessGranted

    function isAllowedReferer():boolean;
    var
      r: string;
    begin
      result := TRUE;
      if allowedReferer = '' then
        exit;
      r := hostFromURL(conn.getHeader('Referer'));
      if (r = '') or (r = data.getSafeHost(data)) then
        exit;
      result := fileMatch(allowedReferer, r);
    end; // isAllowedReferer

    procedure replyWithString(s: UnicodeString);
    var
      a: String;
     {$IFDEF FPC}
//      sR: RawByteString;
     {$ENDIF FPC}
    begin
      if (data.disconnectReason > '') and not data.disconnectAfterReply then
      begin
        self.getPage('deny', data);
        exit;
      end;

      if conn.reply.contentType = '' then
        conn.reply.contentType:=if_(trim(getTill('<', s))='', RawByteString('text/html'), RawByteString('text/plain'));
      a := conn.getHeader('Accept-Charset');
      if (a <> '') and ( (ipos('utf-8', a) = 0) and (pos('*', a) = 0)) then
        begin
         {$IFDEF FPC}
//          sR := s;
//          SetCodePage(sR, 28591);  // ISO 8859-1 Latin 1; Western European (ISO)
//          conn.reply.body := sR
         {$ELSE ~FPC}
//          conn.reply.body := UnicodeToAnsi(s, 28591) // ISO 8859-1 Latin 1; Western European (ISO)
         {$ENDIF FPC}
         conn.reply.body := TSynAnsiConvert.Create(CP_LATIN1).UnicodeStringToAnsi(s);
        end
       else
        conn.reply.bodyU := s;

      conn.reply.mode := HRM_REPLY;
      conn.reply.bodyMode := RBM_TEXT;
      Self.compressReply(data);
    end; // replyWithString

    procedure replyWithStringB(const s: RawByteString);
    begin
      if (data.disconnectReason > '') and not data.disconnectAfterReply then
       begin
        Self.getPage('deny', data);
        exit;
       end;

      if conn.reply.contentType = '' then
        conn.reply.contentType := if_(trim(getTill(RawByteString('<'), s))='', RawByteString('text/html'), RawByteString('text/plain'));
      conn.reply.mode:=HRM_REPLY;
      conn.reply.bodyMode := RBM_RAW;
      conn.reply.body := s;
      Self.compressReply(data);
    end; // replyWithStringB

    procedure replyWithRes(const res: String; const contType: RawByteString);
    var
      s: RawByteString;
      isGZ: Boolean;
    begin
      if (data.disconnectReason > '') and not data.disconnectAfterReply then
        begin
        Self.getPage('deny', data);
        exit;
        end;

        s := getRes(pchar(res), 'ZTEXT');
        isGZ := s <> '';
        if not isGZ then
          s := getRes(pchar(res));
      if contType <> '' then
        conn.reply.contentType := contType;
      if conn.reply.contentType = '' then
        conn.reply.contentType := if_(trim(getTill(RawByteString('<'), s))='', RawByteString('text/html'), RawByteString('text/plain'));
      conn.reply.mode := HRM_REPLY;
      conn.reply.bodyMode := RBM_RAW;
      conn.reply.body := s;
      conn.reply.IsCompressed := isGZ;
      if conn.reply.IsCompressed then
        conn.reply.comprType := 'gzip';
      Self.compressReply(data);
    end; // replyWithRes

    procedure deletion();
    var
      asUrl, s: string;
      doneRes, done, errors: TStringDynArray;
    begin
    if (conn.httpRequest.method <> HM_POST)
    or (data.postVars.values['action'] <> 'delete')
    or not accountAllowed(FA_DELETE, data, f) then exit;

    doneRes:=NIL;
    errors:=NIL;
    done:=NIL;
    for asUrl in data.getFilesSelection() do
      begin
        s := uri2disk(asUrl, f);
        if (s = '') or not fileOrDirExists(s) then  // ignore
          continue;
        runEventScript('file deleting', ['%item-deleting%', s]);
        moveToBin(toSA([s, s+'.md5', s+COMMENT_FILE_EXT]) , TRUE);
        if fileOrDirExists(s) then
          begin
          addString(asUrl, errors);
          continue; // this was not deleted. permissions problem?
          end;

        addString(s, doneRes);
        addString(asUrl, done);
        runEventScript('file deleted', ['%item-deleted%', s]);
      end;

    removeFilesFromComments(doneRes, lp);

    if (LogDeletions in logP) and assigned(done) then
      add2log('Deleted files in '+url+CRLF+join(CRLF, done), data);
    if (LogDeletions in logP) and assigned(errors) then
      add2log('Failed deletion in '+url+CRLF+join(CRLF, errors), data);
    end; // deletion

    function getAccountRedirect(acc:Paccount=NIL):string;
    begin
    result:='';
    if acc = NIL then
      acc:=data.account;
    acc:=accountRecursion(acc, ARSC_REDIR);
    if acc = NIL then exit;
    result:=acc.redir;
    if (result = '') or ansiContainsStr(result, '://') then exit;
    // if it's not a complete url, it may require some fixing
    if not ansiStartsStr('/', result) then result:='/'+result;
    result:=xtpl(result,['\','/']);
    end; // getAccountRedirect

    function addNewAddress():boolean;
    begin
    result:=ipsEverConnected.indexOf(data.address) < 0;
    if not result then exit;
    ipsEverConnected.add(data.address);
    end; // addNewAddress

    // parameters: u(username), e(?expiration_UTC), s2(sha256(rest+pwd))
    function urlAuth():string;
    var
      s, sign: string;
      ss: Tsession;
    begin
      result:='';
      if mode <> 'auth' then
        exit;
      acc := getAccount(data.urlVars.values['u']);
      if acc = NIL then
        exit('username not found');
      sign := conn.httpRequest.url;
      chop('?', sign);
      s := chop('&s2=',sign);
      if strSHA256(s+acc.pwd)<>sign then
        exit('bad sign');
      ss := sessions[data.sessionID];
      if Assigned(ss) then
        begin
          try
           {$IFDEF FPC}
            ss.setTTL(UniversalTimeToLocal(StrToFloat(data.urlvars.Values['e']))- now());
           {$ELSE ~FPC}
            ss.setTTL(TTimeZone.Local.ToLocalTime(StrToFloat(data.urlvars.Values['e'])) - now() )
           {$ENDIF FPC}
           except
          end;

          if ss.ttl < 0 then
            exit('expired');
          ss.user := acc.user;
          ss.redirect := '.';
        end;
      data.account := acc;
      data.usr := acc.user;
      data.pwd := acc.pwd;
      runEventScript('login')
    end; //urlAuth

    function thumb(): Boolean;
    var
//      b: rawbytestring;
//      s, e: integer;
      ct: String;
      str: TStream;
      szs: String;
      sz: Integer;
      AcceptWebP: Boolean;
    begin
      if mode <> 'thumb' then
        exit(FALSE);
      result := TRUE;
      str := nil;
      szs := data.urlVars.values['size'];
      sz := StrToIntDef(szs, -1);
      AcceptWebP := ipos('image/webp', data.conn.getHeader('Accept')) >= 0;
      if f.getThumb(str, ct, sz, AcceptWebP) then
        begin
          conn.reply.contentType := ct;
          conn.reply.mode := HRM_REPLY;
//          conn.reply.bodyMode := RBM_RAW;
//          conn.reply.Body := Copy(b, s, e-s+2);
          conn.reply.bodyMode := RBM_STREAM;
          conn.reply.bodyStream := str;
        end
       else
        begin
          data.conn.reply.mode := HRM_BAD_REQUEST;
          exit;
        end;
    end;

    function sendIcon():Boolean;
    var
      i: Integer;
    begin
      if mode <> 'icon' then
        exit(FALSE);
      result := TRUE;
      i := -1;
      if ((spUseSysIcons in SP) or (f.icon >= 0)) then
        i := f.getSystemIcon;
      if i >= 0 then
        begin
//          conn.reply.mode := HRM_MOVED;
          conn.reply.mode := HRM_REDIRECT;
          conn.reply.url := '/~img' + IntToStr(i);
          data.dontLog := True;
        end
       else
        begin
          data.conn.reply.mode := HRM_NOT_FOUND;
          exit;
        end;
    end;

  var
    b: boolean;
    s: string;
//    i: integer;
    section: PtplSection;
  begin
    // eventually override the address
    if addressmatch(forwardedMask, conn.address) then
      begin
      data.address := getTill(':', getTill(',', conn.getHeader('x-forwarded-for')));
      if (data.address = '') or (not checkAddressSyntax(data.address, false)) then
        data.address := conn.address;
      end;

    data.isLocalAddress := isLocalIP(data.address);


    checkCurrentAddress();

    // update list
    if (data.preReply = PR_NONE)
    and addNewAddress() then
      doOnIPsEverChanged;

    data.requestTime := now();
    data.downloadingWhat := DW_UNK;
    data.fullDLlogged := FALSE;
    data.countAsDownload := FALSE;
    conn.reply.contentType := '';
    specialGrant := FALSE;

    data.lastFile := NIL; // auto-freeing

    with objByIp(htSrv, data.address) do
      begin
        if speedLimitIP < 0 then
          limiter.maxSpeed:=MAXINT
         else
          limiter.maxSpeed:=round(speedLimitIP*1000);
        if conn.limiters.indexOf(limiter) < 0 then
          conn.limiters.add(limiter);
      end;

    conn.addHeader(RawByteString('Accept-Ranges'), RawByteString('bytes'));
    if spSendHFSIdentifier in sp then
      conn.addHeader('Server', 'HFS '+ srvConst.VERSION);

    case data.preReply of
      PR_OVERLOAD:
        begin
        data.disconnectReason := 'limits exceeded';
        Self.getPage('overload', data);
        end;
      PR_BAN:
        begin
        Self.getPage('ban', data);
        conn.reply.reason := RawByteString('Banned: ')+ StrToUTF8(data.banReason);
        end;
      end;

    runEventScript('pre-filter-request');
    if conn.disconnectedByServer then
      exit;
    if data.disconnectReason > '' then
      begin
        Self.getPage('deny', data);
        exit;
      end;

    if (length(conn.httpRequest.user) > 100) or anycharIn('/\:?*<>|', conn.httpRequest.user) then
      begin
      conn.reply.mode := HRM_BAD_REQUEST;
      exit;
      end;

    if not (conn.httpRequest.method in [HM_GET,HM_HEAD,HM_POST]) then
      begin
      conn.reply.mode := HRM_METHOD_NOT_ALLOWED;
      exit;
      end;
    inc(hitsLogged);

    if data.preReply <> PR_NONE then
      exit;

    url := conn.httpRequest.url;
    extractParams();
    url := decodeURL(url, True);
    mode := data.urlvars.values['mode'];

    data.lastFN := extractFileName( xtpl(url,['/','\']) );
    data.agent := getAgentID(conn);

    if selfTesting and (url = 'test') then
      begin
      replyWithString('HFS OK');
      exit;
      end;

    if not sessionSetup() then
      exit;
    if mode = 'logout' then
      begin
      data.logout();
      replyWithString('ok');
      exit;
      end;
    if mode = 'login' then
      begin
      acc := getAccount(data.postVars.values['user']);
      if acc = NIL then
        s := 'bad password' // Should be the same error message as if bad password
      else
        if data.passwordValidation(acc.pwd) then
          begin
          s := 'ok';
          sessions[data.sessionID].user:=acc.user;
          sessions[data.sessionID].redirect:=getAccountRedirect(acc);
          end
        else
          begin
          s := 'bad password'; //TODO shouldn't this change http code?
          end;

      if s='ok' then
        runEventScript('login')
      else
        runEventScript('unauthorized');
      replyWithString(s);
      exit;
      end;
    s := urlAuth();
    if s > '' then
      begin
      runEventScript('unauthorized');
      conn.reply.mode := HRM_DENY;
      replyWithString(s);
      exit;
      end;

    conn.ignoreSpeedLimit := noLimitsFor(data.account);

    // all URIs must begin with /
    if (url = '') or (url[1] <> '/') then
      begin
      conn.reply.mode := HRM_BAD_REQUEST;
      exit;
      end;

    runEventScript('request');
    if data.disconnectReason > '' then
      begin
        Self.getPage('deny', data);
        exit;
      end;
    if conn.reply.mode = HRM_REDIRECT then
      exit;

    lastActivityTime:=now();
    if conn.httpRequest.method = HM_HEAD then
      conn.reply.mode := HRM_REPLY_HEADER
    else
      conn.reply.mode := HRM_REPLY;

    if ansiStartsStr('/~img', url) then
      begin
        if not sendPic(data) then
          Self.getPage('not found', data);
        exit;
      end;
    if mode = 'jquery' then
      begin
        if notModified(conn,'jquery'+FloatToStr(uptime), '') then
          exit;
        replyWithRes('jquery', 'text/javascript');
        exit;
      end;

    // forbid using invalid credentials
    if not (spFreeLogin in sp) and not specialGrant then
      if (data.usr>'')
      and ((data.account=NIL) or (data.account.pwd <> data.pwd))
      and not usersInVFS.match(data.usr, data.pwd) then
        begin
        data.acceptedCredentials := FALSE;
        runEventScript('unauthorized');
        Self.getPage('unauth', data);
        conn.reply.realm := 'Invalid login';
        exit;
        end
      else
        data.acceptedCredentials := TRUE;

    f := Self.findFileByURL(url);
    urlCmd := ''; // urlcmd is only if the file doesn't exist
    if f = NIL then
      begin
      // maybe the file doesn't exist because the URL has a final command in it
      // move last url part from 'url' into 'urlCmd'
      urlCmd := url;
      url := chop(lastDelimiter('/', urlCmd)+1, 0, urlCmd);
      // we know an urlCmd must begin with ~
      // favicon is handled as an urlCmd: we provide HFS icon.
      // a non-existent ~file will be detected a hundred lines below.
      if ansiStartsStr('~', urlCmd) or (urlCmd = 'favicon.ico') then
        f := Self.findFileByURL(url);
      end;
    if f = NIL then
      begin
        if sameText(url, '/robots.txt') and (spStopSpiders in sp) then
          replyWithStringB('User-agent: *'+CRLF+'Disallow: /')
         else
          Self.getPage('not found', data);
        exit;
      end;
    if f.isFolder() and not ansiEndsStr('/',url) then
      begin
      conn.reply.mode := HRM_MOVED;
      conn.reply.url := Self.url(f); // we use f.url() instead of just appending a "/" to url because of problems with non-ansi chars http://www.rejetto.com/forum/?topic=7837
      exit;
      end;
    if f.isFolder() and (urlCmd = '') and (mode='') then
      switchToDefaultFile();
    if (spEnableNoDefault in sp) and (urlCmd = '~nodefault') then
      urlCmd:='';

    if f.isRealFolder() and not sysutils.directoryExists(f.resource)
    or f.isFile() and not fileExists(f.resource) then
      begin
      Self.getPage('not found', data);
      exit;
      end;
    dlForbiddenForWholeFolder := f.isDLforbidden();

    if not accessGranted() then
      exit;

    if urlCmd = 'favicon.ico' then
      begin
      sendPic(data, 23);
      exit;
      end;

    b := urlCmd = '~upload+progress';
    if (b or (urlCmd = '~upload') or (urlCmd = '~upload-no-progress')) then
      begin
      if not f.isRealFolder() then
        Self.getPage('deny', data)
      else if accountAllowed(FA_UPLOAD, data, f) then
        Self.getPage( if_(b, RawByteString('upload+progress'),'upload'), data, f)
      else
        begin
        Self.getPage('unauth', data);
        runEventScript('unauthorized');
        end;
      if b then  // fix for IE6
        begin
        data.disconnectAfterReply:=TRUE;
        data.disconnectReason := 'IE6 workaround';
        end;
      exit;
      end;

    if (conn.httpRequest.method = HM_POST) and assigned(data.uploadResults) then
      begin
      Self.getPage('upload-results', data, f);
      exit;
      end;

    // provide access to any [section] in the tpl, included [progress]
    if mode = 'section' then
      s:=first(data.urlvars.values['id'], 'no-id') // no way, you must specify the id
    else if (f = Self.rootFile) and (urlCmd > '') then
      s:=substr(urlCmd,2)
    else
      s:='';
    if (s > '') and f.isFolder() and not ansiStartsText('special:', s) then
      with Self.tplFromFile(f) do // temporarily builds from diff tpls
        try
          section:=getsection(s);
          if assigned(section) and section.public then // it has to exist and be accessible
            begin
            if not section.cache
            or not notModified(conn, s+floatToStr(section.ts), '') then
              Self.getPage(s, data, f, me());
            exit;
            end;
        finally free
          end;

    if f.isFolder() and not (FA_BROWSABLE in f.flags)
    and stringExists(urlCmd,['','~folder.tar','~files.lst']) then
      begin
      Self.getPage('deny', data);
      exit;
      end;

    if not isAllowedReferer()
    or f.isFile() and f.isDLforbidden() then
      begin
      Self.getPage('deny', data);
      exit;
      end;

    if (urlCmd = '~folder.tar')
    or (mode = 'archive') then
      begin
      serveTar();
      exit;
      end;

    // please note: we accept also ~files.lst.m3u
    if ansiStartsStr('~files.lst', urlCmd)
    or f.isFolder() and (data.urlvars.values['tpl'] = 'list') then
      begin
        if conn.reply.mode=HRM_REPLY_HEADER then
          exit;
        // load from external file
        s := cfgPath+FILELIST_TPL_FILE;
        if newMtime(s, lastFilelistTpl) then
          filelistTpl.fullText := loadfile(s);
        // if no file is given, load from internal resource
        if not fileExists(s) and (lastFilelistTpl > 0) then
          begin
          lastFilelistTpl := 0;
          filelistTpl.fullText := getRes('filelistTpl');
          end;

        data.downloadingWhat := DW_FOLDERPAGE;
        data.disconnectAfterReply := TRUE; // needed for IE6... ugh...
        data.disconnectReason := 'IE6 workaround';
        replyWithString(trim(getAFolderPage(f, data, filelistTpl)));
        exit;
      end;

    // from here on, we manage only services with no urlCmd.
    // a non empty urlCmd means the url resource was not found.
    if urlCmd > '' then
      begin
      Self.getPage('not found', data);
      exit;
      end;

    data.lastFile := f; // auto-freeing

    if f.isFolder() then
      begin
      if conn.reply.mode=HRM_REPLY_HEADER then
        exit;
      deletion();
      if sessionRedirect() then
        exit;
      data.downloadingWhat := DW_FOLDERPAGE;
  QueryPerformanceFrequency(Freq);
  QueryPerformanceCounter(StartCount);
      if (spDMbrowserTpl in sp) and isDownloadManagerBrowser() then
        s := getAFolderPage(f, data, dmBrowserTpl)
      else if (spDisableMacros in sp) and (not Assigned(Self.tpl) or (Self.tpl.fullText = '') or Self.tpl.anyMacroMarkerIn)and Assigned(noMacrosTpl) and (noMacrosTpl.fullText>'') then
        s := getAFolderPage(f, data, noMacrosTpl)
      else if (spNonLocalIPDisableMacros in sp) and not data.isLocalAddress and Assigned(noMacrosTpl) and (noMacrosTpl.fullText>'') then
        s := getAFolderPage(f, data, noMacrosTpl)
      else
        s := getAFolderPage(f, data, Self.tpl);
      if conn.reply.mode <> HRM_REDIRECT then
        replyWithString(s);
  QueryPerformanceCounter(StopCount);
  TimingSeconds := (StopCount - StartCount) / Freq;
  OutputDebugString(PChar('Prepared reply for folder by ' + floattostr(TimingSeconds)));
      exit;
      end;

    if notModified(conn, f) then // calling notModified before limitsExceededOnDownload makes possible for [download] to manipualate headers set here
      exit;
    if thumb() then
      Exit;
    if mode = 'icon' then
      begin
        sendIcon;
        Exit;
      end;

    data.countAsDownload := f.shouldCountAsDownload();
    if data.countAsDownload and limitsExceededOnDownload() then
      exit;

    doSetupDownloadIcon(data);
    data.eta.idx := 0;
    conn.reply.contentType := name2mimetype(f.name, DEFAULT_MIME);
    conn.reply.bodyMode := RBM_FILE;
    conn.reply.bodyU := f.resource;
    data.downloadingWhat := DW_FILE;
    { I guess this would not help in any way for files since we are already handling the 'if-modified-since' field
    try
      conn.addHeader('ETag: '+getEtag(f.resource));
    except end;
    }

    data.fileXferStart := now();
    if data.countAsDownload and (flashOn = 'download') then
      doFlash('download');

    b := (openInBrowser <> '') and fileMatch(openInBrowser, f.name)
      or inBrowserIfMIME and (conn.reply.contentType <> DEFAULT_MIME);

    s := first(eventToFilename('download name', []), f.name); // a script can eventually decide the name
    // N-th workaround for IE. The 'accept' check should let us know if the save-dialog is displayed. More information at www.rejetto.com/forum/?topic=6275
    if (data.agent = 'MSIE') and (conn.getHeader('Accept') = '*/*') then
      s:=xtpl(s, [' ','%20']);
    if not (spNoContentdisposition in sp) or not b then
      addContentDisposition(s, not b);
  end; // handleRequest

  procedure lastByte();

    procedure incDLcount(f: Tfile; const res: String);
    begin
      if (f = NIL) or f.isTemp() then
        autoupdatedFiles.incInt(res)
       else
        f.DLcount := 1+f.DLcount
    end;

  var
    archive: TarchiveStream;
    i: integer;
  begin
    if data.countAsDownload then
      inc(downloadsLogged);
    // workaround for a bug that was fixed in Wget/1.10
    if stringExists(data.agent, ['Wget/1.7', 'Wget/1.8.2', 'Wget/1.9', 'Wget/1.9.1']) then
      data.disconnect('wget bug workaround (consider updating wget)');
    VFScounterMod := TRUE;
    case data.downloadingWhat of
      DW_FILE:
        if assigned(data) then
          incDLcount(data.lastFile, data.lastFile.resource);
      DW_ARCHIVE:
        begin
        archive := conn.reply.bodyStream as TarchiveStream;
        for i:=0 to length(archive.flist)-1 do
          incDLcount(Tfile(archive.flist[i].data), archive.flist[i].src);
        end;
      end;
    if data.countAsDownload then
      runEventScript('download completed');
  end; // lastByte

  function canWriteFile(): Boolean;
   resourcestring
    MSG_MIN_DISK_REACHED = 'Minimum disk space reached.';
  begin
    result := FALSE;
    if data.f = NIL then
      exit;
    result := minDiskSpace <= diskSpaceAt(data.uploadDest) div MEGA;
    if result then
      exit;
    closeUploadingFile_partial(lp);
    data.uploadFailed := MSG_MIN_DISK_REACHED;
  end; // canWriteFile

  function complyUploadFilter(): Boolean;

    function getMask(): String;
    begin
      if f.isTemp() then
        result := f.parent.uploadFilterMask
       else
        result := f.uploadFilterMask;
      if result = '' then
        result := '\'+PROTECTED_FILES_MASK; // the user can disable this default filter by inputing * as mask
    end;

   resourcestring
    MSG_UPL_NAME_FORB = 'File name or extension forbidden.';
  begin
    result := validFilename(data.uploadSrc)
      and not sameText(data.uploadSrc, DIFF_TPL_FILE) // never allow this
      and not isExtension(data.uploadSrc, '.lnk')  // security matters (by mars)
      and fileMatch(getMask(), data.uploadSrc);
    if not result then
      data.uploadFailed := MSG_UPL_NAME_FORB;
  end; // complyUploadFilter

  function canCreateFile():boolean;
   resourcestring
    MSG_UPL_CANT_CREATE = 'Error creating file.';
  begin
    IOresult;
    rewrite(data.f^, 1);
    result := IOresult=0;
    if result then
      exit;
    data.uploadFailed := MSG_UPL_CANT_CREATE;
  end; // canCreateFile

var
  ur: TuploadResult;
  i: integer;
begin
  if assigned(conn) and (conn.getLockCount <> 1) then
    add2log('please report on the forum about this message');

  f := NIL;
  data := NIL;
  if assigned(conn) then
    data := conn.data;
  if assigned(data) then
    data.lastActivityTime := now();

  if (dumpTraffic in logP) and (event in [HE_GOT, HE_SENT]) then
    appendFileA(exePath+'hfs-dump.bin', TLV(if_(event=HE_GOT,1,2),
      TLV(10, str_(now()))+TLVS(11, data.address)+TLVS(12, conn.port)+TLV(13, conn.eventData)
    ));

  if (spPreventStandby in sp) and assigned(setThreadExecutionState) then
    setThreadExecutionState(1);

  // this situation can happen when there is a call to processMessage() before this function ends
  if (data = NIL) and (event in [HE_REQUESTED, HE_GOT]) then
    exit;

  case event of
    HE_CANT_OPEN_FILE: data.error := 'Can''t open file';
    HE_OPEN:
      begin
        doStatusChanged(True);
        runEventScript('server start');
      end;
    HE_CLOSE:
      begin
        doStatusChanged(False);
        runEventScript('server stop');
      end;
    HE_REQUESTING:
      begin
      // do some clearing, due for persistent connections
      data.vars.clear();
      data.urlvars.clear();
      data.postVars.clear();
      data.tplCounters.clear();
      doRefreshConn(data);
      end;
    HE_GOT_HEADER: runEventScript('got header');
    HE_REQUESTED:
      begin
      data.dontLog := FALSE;
  //QueryPerformanceFrequency(Freq);
  //QueryPerformanceCounter(StartCount);
      handleRequest();
  //QueryPerformanceCounter(StopCount);
  //TimingSeconds := (StopCount - StartCount) / Freq;
  //OutputDebugString(PChar('Prepared request answer by ' + floattostr(TimingSeconds)));
      // we save the value because we need it also in HE_REPLY, and temp files are not avaliable there
      data.dontLog := data.dontLog or assigned(f) and f.hasRecursive(FA_DONT_LOG);
      if f <> data.lastFile then
        freeIfTemp(f);
      doRefreshConn(data);
      end;
    HE_STREAM_READY:
      begin
      i := length(data.disconnectReason);
      runEventScript('stream ready');
      if (i=0) and (data.disconnectReason > '') then // only if it was not already disconnecting
        begin
        conn.reply.ClearAdditionalHeaders; // content-disposition would prevent the browser
        Self.getPage('deny', data);
        conn.initInputStream();
        end;
      end;
    HE_REPLIED:
      begin
      doSetupDownloadIcon(data); // remove the icon
      data.lastBytesGot:=0;
      if data.disconnectAfterReply then
        data.disconnect('replied');
      if updateASAP > '' then
        data.disconnect('updating');
      doRefreshConn(data);
      end;
    HE_LAST_BYTE_DONE:
      begin
      if (conn.reply.mode = HRM_REPLY) and (data.downloadingWhat in [DW_FILE, DW_ARCHIVE]) then
        lastByte();
      runEventScript('request completed');
      end;
    HE_CONNECTED:
      begin
        //** lets see if this helps with speed
        conn.socketSetNoDelay;

        data := TconnData.create(conn, NIL);
        conn.limiters.add(globalLimiter); // every connection is bound to the globalLimiter
        conn.sndBuf := STARTING_SNDBUF;
        data.address := conn.address;
        data.isLocalAddress := isLocalIP(conn.address) and not addressmatch(forwardedMask, conn.address); // More strictly, because we need to check if it's a reverse proxy!
        checkCurrentAddress();
        doInitConnData(data);
        if (flashOn = 'connection') and (conn.reply.mode <> HRM_CLOSE) then
          doFlash('connection');
        runEventScript('connected');
      end;
    HE_DISCONNECTED:
      begin
        closeUploadingFile_partial(lp);
        data.deleting := TRUE;
        toDelete.add(data);
        doRemoveConnData(data);
        runEventScript('disconnected');
    {$IFNDEF USE_VTV}
//    connBox.invalidate();
    {$ENDIF ~USE_VTV}
      end;
    HE_DESTROID:
      begin
       // Socket destroid
        if Assigned(data) then
          begin
            toDelete.Remove(data);
            doRemoveConnData(data);
            data.Free;
            conn.data := NIL;
          end;
      end;
    HE_GOT: lastActivityTime := now();
    HE_SENT:
      begin
        lastActivityTime := now();
        if data.nextDloadScreenUpdate <= lastActivityTime then
          begin
          data.nextDloadScreenUpdate := lastActivityTime + DOWNLOAD_MIN_REFRESH_TIME;
    //      refreshConn(data, false);
          doRefreshConn(data);
          doSetupDownloadIcon(data);
          end;
        if (lastActivityTime - lastEverySec) > OneSecond then
          Application.ProcessMessages;
      end;
    HE_POST_FILE:
      begin
        sessionSetup();
        data.downloadingWhat := DW_UNK;
        data.agent := getAgentID(conn);
        data.fileXferStart := now();
        f := Self.findFileByURL(decodeURL(getTill('?',conn.httpRequest.url)));
        data.lastFile := f; // auto-freeing
        data.uploadSrc := conn.post.filename;
        data.uploadFailed := '';
        if (f = NIL) or not accountAllowed(FA_UPLOAD, data, f) or not f.accessFor(data) then
          data.uploadFailed := if_(f=NIL, String('Folder not found.'), 'Not allowed.')
         else
          begin
            closeUploadingFile();
            getUploadDestinationFileName();

            if complyUploadFilter() and canWriteFile() and canCreateFile() then
              saveFileA(data.f^, conn.post.data);
            doUpdateTray([utIcon]);
//            repaintTray();
          end;
        if data.uploadFailed > '' then
          logUploadFailed();
      end;
    HE_POST_MORE_FILE:
      if canWriteFile() then
        saveFileA(data.f^, conn.post.data);
    HE_POST_END_FILE:
      begin
        // fill the record
        ur.fn := first(extractFilename(data.uploadDest), data.uploadSrc);
        if data.f = NIL then
          ur.size := -1
         else
          ur.size := filesize(data.f^);
        ur.speed := calcAverageSpeed(conn.bytesPostedLastItem);
        // custom scripts
        if assigned(data.f) then
          inc(uploadsLogged);
        closeUploadingFile();
        if data.uploadFailed = '' then
          data.uploadFailed:=trim(runEventScript('upload completed'))
         else
          runEventScript('upload failed');
        ur.reason := data.uploadFailed;
        if data.uploadFailed > '' then
          deleteFile(data.uploadDest);
        // queue the record
        i := length(data.uploadResults);
        setLength(data.uploadResults, i+1);
        data.uploadResults[i]:=ur;

        doRefreshConn(data);
      end;
    HE_POST_VAR: data.postVars.add(conn.post.varname+'='+UnUTF(conn.post.data));
    HE_POST_VARS:
      if conn.post.mode = PM_URLENCODED then
        urlToStrings(conn.post.data, data.postVars);
    // default case
   else
    doRefreshConn(data);
  end;//case
  if Assigned(data) then
    sessions.keepAlive(data.sessionID);
  if event in [HE_CONNECTED, HE_DISCONNECTED, HE_OPEN, HE_CLOSE, HE_REQUESTED, HE_POST_END, HE_LAST_BYTE_DONE] then
   begin
    doUpdateTray([utIcon, utTIP])
   end;
  doLog();
end; // httpEventNG
//*)

// ensure f.accounts does not store non-existent users
function cbPurgeVFSaccounts(f: Tfile; callingAfterChildren: Boolean; par, par2: IntPtr): TfileCallbackReturn;
var
  usernames, renamings: THashedStringList;
  i: integer;
  act: TfileAction;
  u, n: string;
begin
result:=[];
usernames:=THashedStringList(par);
renamings:=THashedStringList(par2);
for act:=low(act) to high(act) do
  for i:=length(f.accounts[act])-1 downto 0 do
    begin
    u:=f.accounts[act][i];
    n:=renamings.values[u];
    if n > '' then
      begin
      f.accounts[act][i]:=n;
      VFSmodified:=TRUE;
      continue;
      end;
    if (u = '')
    or not (u[1] in ['@','*']) and (usernames.indexOf(u) < 0) then
      begin
      removeString(f.accounts[act], i);
      VFSmodified:=TRUE;
      end;
    end;
end; // cbPurgeVFSaccounts

procedure TFileServer.purgeVFSaccounts();
var
  usernames, renamings: THashedStringList;
  i: integer;
  a: Paccount;
begin
  usernames := THashedStringList.create;
  renamings := THashedStringList.create;
  try
    for i:=0 to length(accounts)-1 do
      begin
      a:=@accounts[i];
      usernames.add(a.user);
      if (a.wasUser > '') and (a.user <> a.wasUser) then
        renamings.Values[a.wasUser]:=a.user;
      end;
    rootFile.recursiveApply(cbPurgeVFSaccounts, NativeInt(usernames), NativeInt(renamings));
   finally
    usernames.free;
    renamings.free;
  end;
end; // purgeVFSaccounts

function TFileServer.uptimeStr(): string;
var
  t: Tdatetime;
begin
  result := 'server down';
  if not htSrv.active then
    exit;
  t := now()-uptime;
  if t > 1 then
    result := format('(%d days) ', [trunc(t)])
   else
    result := '';

  result := result + formatDateTime('hh:nn:ss', t)
end; // uptimeStr

procedure TFileServer.kickByIP(const ip: String);
var
  i: integer;
  d: TconnDataMain;
begin
  i := 0;
  while i < htSrv.conns.count do
   begin
    d := conn2data(i);
    if assigned(d) and (d.address = ip) or (ip = '*') then
      d.disconnect(first(d.disconnectReason, 'kicked'));
    inc(i);
   end;
end; // kickByIP

procedure TFileServer.kickAllIdle(const Msg: String);
var
  i: integer;
begin
  i := 0;
  while i < getConnectionsCount do
  begin
    with conn2data(i) do
      if conn.httpState = HCS_IDLE then
        disconnect(Msg);
    inc(i);
  end;
end;

function TFileServer.startServer(): boolean;
var
  listenAddr: String;
  listenPort: String;

  procedure tryPorts(list: array of string);
  var
    i: Integer;
  begin
    for i :=0 to length(list)-1 do
     begin
      htSrv.port := trim(list[i]);
      if htSrv.start(listenAddr) then
        exit;
     end;
  end; // tryPorts

begin
  result := FALSE;
  if htSrv.active then
    exit; // fail if already active
  listenAddr := prefs.getDPrefStr('listen-on');
  if (listenAddr> '') and not stringExists(listenPort, getAcceptOptions()) then
    prefs.addPrefStr('listen-on', '');

  listenPort := prefs.getDPrefStr('port');
  if listenPort > '' then
    tryPorts([listenPort])
   else
    tryPorts(['80','8080','280','10080','0']);
  if not htSrv.active then
    exit; // failed
  upTime := now();
  result := TRUE;
end; // startServer

function TFileServer.restartServer: boolean;
var
  listenAddr: String;
  port: String;
begin
  result := FALSE;
  if not htSrv.active then
    exit;
  port := htSrv.port;
  htSrv.stop();
  htSrv.port := port;
  listenAddr := prefs.getDPrefStr('listen-on');
  result := htSrv.start(listenAddr);
end; // restartServer

function TFileServer.changeListenAddr(const addr: String): boolean;
begin
  prefs.addPrefStr('listen-on', addr);
  Result := restartServer;
end;

// change port and test it working. Restore if not working.
function TFileServer.changePort(const newVal: String): Boolean;
var
  act: boolean;
  was: string;
begin
  result := TRUE;
  act := htSrv.active;
//  was := port;
  was := prefs.getDPrefStr('port');
//  port := newVal;
  prefs.addPrefStr('port', newVal);
  if act and (newVal = htSrv.port) then
    exit;
  stopServer(htSrv);
  if startServer then
    begin
      if not act then
        stopServer(htSrv); // restore
      exit;
    end;
  result := FALSE;
//  port := was;
  prefs.addPrefStr('port', was);
  if act then
    startServer();
end; // changePort

function TFileServer.getListenPorts(const onlyPref: Boolean = false): String;
begin
  if httpServIsActive then
    Result :=  htSrv.port
   else
    Result := prefs.getDPrefStr('port');
end;

procedure TFileServer.resetTotals;
begin
  hitsLogged := 0;
  downloadsLogged := 0;
  uploadsLogged := 0;
  outTotalOfs := -htSrv.bytesSent;
  inTotalOfs := -htSrv.bytesReceived;
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
  ConnBoxAdded := False;
end; // constructor

destructor TconnData.destroy;
var
  i: Integer;
begin
  if Assigned(vars) and (vars.Count > 0) then
    for i :=0 to vars.Count-1 do
    if assigned(vars.Objects[i]) and (vars.Objects[i] <> currentCFGhashed) then
      begin
        vars.Objects[i].free;
        vars.Objects[i] := NIL;
      end;
  if Assigned(vars) then
    freeAndNIL(vars);
  freeAndNIL(postVars);
  freeAndNIL(urlvars);
  freeAndNIL(tplCounters);
  if guiData <> NIL then
    FreeAndNil(guiData);

//  freeAndNIL(limiter);
  if assigned(limiter) then
    begin
      if Assigned(conn) then
        conn.hsrv.limiters.remove(Self.limiter);
      freeAndNIL(limiter);
    end;
  Self.conn := NIL;
//  freeAndNIL(Self.conn);

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

function TconnData.getHTTPStateString: String;
resourcestring
  MSG_CON_STATE_IDLE  = 'idle';
  MSG_CON_STATE_REQ   = 'requesting';
  MSG_CON_STATE_RCV   = 'receiving';
  MSG_CON_STATE_THINK = 'thinking';
  MSG_CON_STATE_REP   = 'replying';
  MSG_CON_STATE_SEND  = 'sending';
  MSG_CON_STATE_DISC  = 'disconnected';
const
  HCS2STR: array [ThttpConnState] of String = (MSG_CON_STATE_IDLE, MSG_CON_STATE_REQ, MSG_CON_STATE_RCV,
    MSG_CON_STATE_THINK, MSG_CON_STATE_REP, MSG_CON_STATE_SEND, MSG_CON_STATE_DISC);
begin
  Result := HCS2STR[conn.httpState];
  if conn.httpState = HCS_IDLE then
    Result := Result + ' '+intToStr(conn.requestCount);
end;

function TconnData.getSpeed: Real;
begin
  case conn.httpState of
      HCS_REPLYING_BODY: Result := conn.speedOut;
      HCS_POSTING: Result := conn.speedIn;
   else
     Result := averageSpeed;
  end;
end;

function getAcceptOptions(): Types.TstringDynArray;
begin
 {$IFDEF USE_IPv6}
  result := getLocalIPs();
//  result := listToArray(localIPlist(sfAny));
  addUniqueString('127.0.0.1', result);
  addUniqueString('::1', result);
 {$ELSE ~USE_IPv6}
  result := listToArray(localIPlist);
  addUniqueString('127.0.0.1', result);
 {$ENDIF USE_IPv6}
end; // getAcceptOptions

procedure stopServer(srv: ThttpSrv);
begin
  if assigned(srv) then
    srv.stop()
end;

function noLimitsFor(account: Paccount): boolean;
begin
  account := accountRecursion(account, ARSC_NOLIMITS);
  result := assigned(account) and account.noLimits;
end; // noLimitsFor

function isBanned(const address: String; out comment: String): Boolean; overload;
var
  i: Integer;
begin
  result := TRUE;
  for i :=0 to length(banlist)-1 do
    if addressMatch(banlist[i].ip, address) then
      begin
        comment:=banlist[i].comment;
        exit;
      end;
  result := FALSE;
end; // isBanned

function isBanned(cd: TconnDataMain): Boolean; overload;
begin
  result := assigned(cd) and isBanned(cd.address, cd.banReason)
end;

procedure removeFilesFromComments(files: TStringDynArray; lp: TLoadPrefs);
var
  fn, lastPath, path: string;
  trancheStart, trancheEnd: integer; // the tranche is a window within 'selection' of items sharing the same path
  ss: TstringList;

  procedure doTheTranche();
  var
    b, i: integer;
    fn, s: string;
    sa: RawByteString;
    anyChange: boolean;
  begin
    // leave only the files' name
    for i :=trancheStart to trancheEnd do
      files[i]:=copy(files[i],length(lastPath)+1,MAXINT);
    // comments file
    try
      fn:=lastPath+COMMENTS_FILE;
      ss.loadFromFile(fn, TEncoding.UTF8);
      anyChange:=FALSE;
      for i :=trancheStart to trancheEnd do
        begin
        b:=ss.indexOfName(files[i]);
        if b < 0 then continue;
        ss.delete(b);
        anyChange:=TRUE;
        end;
      if anyChange then
        if ss.count = 0 then
          deleteFile(fn)
        else
          ss.saveToFile(fn, TEncoding.UTF8);
     except
    end;
    // descript.ion
    if not (lpION in lp ) then
      exit;
    try
      fn := path+DESCRIPT_ION;
      sa := loadFile(fn);
      if sa = '' then
        exit;
      if lpOEMForION in lp then
        begin
          SetLength(s, Length(sa));
          OEMToCharBuff(@sa[1], @s[1], length(s));
        end
       else
        s := UnUTF(sa);
      anyChange:=FALSE;
      for i :=trancheStart to trancheEnd do
        begin
          b:=findNameInDescriptionFile(s, files[i]);
          if b = 0 then
            continue;
          delete(s, b, findEOL(s,b)-b+1);
          anyChange:=TRUE;
        end;
      if anyChange then
        if s='' then
          deleteFile(fn)
         else
          saveTextfile(fn, s);
     except
    end;
  end; // doTheTranche

begin
  // collect files with same path in tranche, then process it
  sortArray(files);
  trancheStart:=0;
  ss := TstringList.create(); // we'll use this in doTheTranche(), but create the object once, as an optimization
  try
    ss.caseSensitive:=FALSE;
    for trancheEnd:=0 to length(files)-1 do
      begin
      fn:=files[trancheEnd];
      path:=getTill(lastDelimiter('\/', fn), fn);
      if trancheEnd = 0 then
        lastPath:=path;
      if path <> lastPath then
        begin
        doTheTranche();
        // init the new tranche
        trancheStart:=trancheEnd+1;
        lastPath:=path;
        end;
      end;
    trancheEnd:=length(files)-1; // after the for-loop, the variable seems to not be reliable
    doTheTranche();
   finally
    ss.free
  end;
end; // removeFilesFromComments

function protoColon(fs: TFileServer): String;
const
  LUT: array [boolean] of string = ('http://','https://');
begin
  result := LUT[spHttpsUrls in fs.SP];
end; // protoColon

function getLibs: String;
begin
  Result := SYNOPSE_FRAMEWORK_NAME + ': ' + SYNOPSE_FRAMEWORK_FULLVERSION;
  Result := Result + CrLf + OverbyteIcsWSocket.CopyRight;
  Result := Result + CrLf + 'SSL: ' + GSSLEAY_DLL_FileVersion;
  Result := Result + CrLf + RnQzip.ZLibVersion;
  Result := Result + CrLf + RnQzip.ZStdVersion;
  Result := Result + CrLf + 'WebP Encoder: ' + WebPLibVersion;
end;

end.
