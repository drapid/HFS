unit fileLib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  // delphi libs
  Windows, Messages,
  mormot.core.base,
  Classes,
  math, Types, SysUtils,
 {$IFNDEF USE_MORMOT}
   {$IFDEF FPC}
    fpjson,
   {$ELSE ~FPC}
    JSON,
   {$ENDIF FPC}
 {$ENDIF USE_MORMOT}
  srvClassesLib;

type

  TfileAttribute = (
    FA_FOLDER,       // folder kind
    FA_VIRTUAL,      // does not exist on disc
    FA_ROOT,         // only the root item has this attribute
    FA_BROWSABLE,    // permit listing of this folder (not recursive, only dir)
    FA_HIDDEN,       // hidden items won't be shown to browsers (not recursive)
     //no more used attributes have to stay for backward compatibility with
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
  TfileCallback = function(f: Tfile; childrenDone: boolean; par, par2: IntPtr): TfileCallbackReturn;

  TfileAction = (FA_ACCESS, FA_DELETE, FA_UPLOAD);

  TLoadPrefs = set of (lpION, lpHideProt, lpSysAttr, lpHdnAttr, lpSnglCmnt, lpFingerPrints, lpRecurListing, lpOEMForION,
                       lpDeletePartialUploads, lpNumberFilesOnUpload, lpUseCommentAsRealm);

  TIconsIdxArray = array of integer;

  PFile = ^TFile;
  Tfile = class (Tobject)
  private
    fFilesTree: IServerTree;
    fLocked: boolean;
    FDLcount: integer;
    fName: String;
    tempParent: TFile;
    fOnImageChanged: TNotifyEvent;
    fNodeImageindex: Integer;
    fHasThumb: Boolean;
    function  getParent(): Tfile;
    function  getDLcount(): Integer;
    procedure setDLcount(i: Integer);
    function  getDLcountRecursive(): Integer;
  public
    comment, user, pwd, lnk: string;
    resource: UnicodeString;  // link to physical file/folder; URL for links
    flags: TfileAttributes;
    size: int64; // -1 is NULL
    atime,            // when was this file added to the VFS ?
    mtime: Tdatetime; // modified time, read from disk
    icon: integer;
    accounts: array [TfileAction] of TStringDynArray;
    filesFilter, foldersFilter, realm, diffTpl,
    defaultFileMask, dontCountAsDownloadMask, uploadFilterMask: UnicodeString;
    constructor create(pSrv: IServerTree; const fullpath: UnicodeString);
    constructor createTemp(pSrv: IServerTree; const fullpath: UnicodeString; pParentFile: TFile = NIL);
    constructor createVirtualFolder(pSrv: IServerTree; const name: String);
    constructor createLink(pSrv: IServerTree; const name: String);
    function  toggle(att: TfileAttribute): Boolean;
    function  isFolder(): Boolean; inline;
    function  isFile(): Boolean; inline;
    function  isFileOrFolder():boolean; inline;
    function  isRealFolder():boolean; inline;
    function  isVirtualFolder():boolean; inline;
    function  isEmptyFolder(loadPrefs: TLoadPrefs; cd:TconnDataMain=NIL):boolean;
    function  isRoot():boolean; inline;
    function  isLink():boolean; inline;
    function  isTemp():boolean; inline;
    function  isNew():boolean;
    function  isDLforbidden(): Boolean;
    function  relativeURL(fullEncode: Boolean=FALSE): String;
    procedure setupImage(sysIcons: Boolean; newIcon: integer); overload;
    procedure setupImage(sysIcons: Boolean; pNode: TFileNode = NIL); overload;
    function  getSystemIcon(): integer;
    function  gotSystemIcon(): boolean;
    function  getHasThumb: Boolean;
    function  getThumb(var str: TStream; var format: String; size: Integer; AcceptWebP: Boolean = false): Boolean;
    function  getAccountsFor(action: TfileAction; specialUsernames: Boolean=FALSE; outInherited: Pboolean=NIL): TstringDynArray;
    function  accessFor(const username, password: String): Boolean; overload;
    function  accessFor(cd: TconnDataMain): Boolean; overload;
    function  hasRecursive(attributes: TfileAttributes; orInsteadOfAnd: Boolean=FALSE; outInherited: Pboolean=NIL): Boolean; overload;
    function  hasRecursive(attribute: TfileAttribute; outInherited: Pboolean=NIL): Boolean; overload;
    function  getIconForTreeview(sysIcons: Boolean): Integer;
    function  getFolder(): String;
    function  getRecursiveFileMask(): String;
    function  shouldCountAsDownload(): Boolean;
    function  getDefaultFile(): Tfile;
    procedure recursiveApply(callback: TfileCallback; par: IntPtr=0; par2: IntPtr=0);
    procedure getFiltersRecursively(var files, folders: String);
    function  diskfree(): int64;
    function  same(f:Tfile): boolean;
    procedure setName(const name: String);
    procedure setResource(res: UnicodeString);
    function  getDynamicComment(loadPrefs: TLoadPrefs; skipParent: Boolean=FALSE): String;
    procedure setDynamicComment(loadPrefs: TLoadPrefs; cmt: String);
    function  getRecursiveDiffTplAsStr(outInherited: Pboolean=NIL; outFromDisk: Pboolean=NIL): String;
    function  getVFS(): RawByteString;
    function  getVFSZ(): RawByteString;
 {$IFDEF USE_MORMOT}
    function  getVFSJZ2(var p_icons: TIconsIdxArray; pHumanReadable: Boolean = False): RawByteString;
 {$ELSE USE_MORMOT}
    function  getVFSJZ(var p_icons: TIconsIdxArray): TJSONObject;
 {$ENDIF USE_MORMOT}
     // locking prevents modification of all its ancestors and descendants
    procedure lock();
    procedure unlock();
    function  getNode: TFileNode;
    procedure DeleteNode;
    procedure DeleteChildren;
    procedure ExpandNode;
    function  isLocked():boolean;
    function  getFirstChild: TFile;
    function  getNextSibling: TFile;
    function  getMainFile: TFile;
    function  setBrowsable(childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;
    function  getShownRealm(LP: TLoadPrefs): String;
    property  parent: Tfile read getParent;
    property  DLcount: Integer read getDLcount write setDLcount;
    property  node: TFileNode read getNode;
    property  locked: Boolean read fLocked;
    property  name: String read fName write SetName;
    property  NodeImageindex: Integer read fNodeImageindex;
    property  hasThumb: Boolean read getHasThumb;
   end; // Tfile

function nodeToFile(n: TFileNode): Tfile;
function nodeText(n: TFileNode): String;
function isCommentFile(const lp: TLoadPrefs; const fn: string): Boolean;
function isFingerprintFile(const lp: TLoadPrefs; const fn: string): Boolean;
function hasRightAttributes(const lp: TLoadPrefs; const fn: UnicodeString): Boolean; overload;
function hasRightAttributes(const lp: TLoadPrefs; attr: DWORD): Boolean; overload;
function findNameInDescriptionFile(const txt, name: String): Integer;
function freeIfTemp(var f: Tfile): Boolean; inline;
function accountAllowed(action: TfileAction; cd: TconnDataMain; f: Tfile): Boolean;
function str_(fa: TfileAttributes): RawByteString; overload;

function setNilChildrenFrom(nodes: TFileNodeDynArray; father: integer): integer;

function loadMD5for(const fn: String): String;
function loadFingerprint(const fn: String): String;
function setBrowsable(f: Tfile; childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;

function addVFSheader(const vfsdata: RawByteString): RawByteString;

const
  FILEACTION2STR: array [TfileAction] of string = ('Access', 'Delete', 'Upload');

const
  // IDs used for file chunks
  FK_HEAD = 0;
  FK_RESOURCE = 1;
  FK_NAME = 2;
  FK_FLAGS = 3;
  FK_NODE = 4;
  FK_FORMAT_VER = 5;
  FK_CRC = 6;
  FK_COMMENT = 7;
  FK_USERPWD = 8;
  FK_USERPWD_UTF8 = 108;
  FK_ADDEDTIME = 9;
  FK_DLCOUNT = 10;
  FK_ROOT = 11;
  FK_ACCOUNTS = 12;
  FK_FILESFILTER = 13;
  FK_FOLDERSFILTER = 14;
  FK_ICON_GIF = 15;
{$IFDEF HFS_GIF_IMAGES}
{$ELSE ~HFS_GIF_IMAGES}
  FK_ICON_PNG = 115;
  FK_ICON32_PNG = 116;
  FK_ICON_IDX = 117;
{$ENDIF HFS_GIF_IMAGES}
  FK_REALM = 16;
  FK_UPLOADACCOUNTS = 17;
  FK_DEFAULTMASK = 18;
  FK_DONTCOUNTASDOWNLOADMASK = 19;
  FK_AUTOUPDATED_FILES = 20;
  FK_DONTCOUNTASDOWNLOAD = 21;
  FK_HFS_VER = 22;
  FK_HFS_BUILD = 23;
  FK_COMPRESSED_ZLIB = 24;
  FK_DIFF_TPL = 25;
  FK_UPLOADFILTER = 26;
  FK_DELETEACCOUNTS = 27;

type
  TstringIntPairs = array of record
    str: string;
    int: integer;
   end;


var
  defSorting: string;          // default sorting, browsing
  iconMasks: TstringIntPairs;

implementation

uses
  strutils, iniFiles, Graphics,
  RegExpr,
  RDUtils, RDFileUtil,
  RDSysUtils,
  RnQZip,
//  RnQJSON,
 {$IFDEF USE_MORMOT}
   mormot.core.json,
   mormot.core.text,
  {$ELSE}
   mormot.core.datetime,
 {$ENDIF USE_MORMOT}
  serverLib,
  HSUtils,
  srvConst, srvUtils, srvVars,
  IconsLib,
  parserLib
  ;

function loadDescriptionFile(const lp: TLoadPrefs; const fn: string): UnicodeString;
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
result:=escapeNL(s);
if result <> s then
  result:=result+#4#$C2;
end; // escapeIon

function unescapeIon(s: String): String;
begin
if ansiEndsStr(#4#$C2, s) then
  begin
  setLength(s, length(s)-2);
  s:=unescapeNL(s);
  end;
result:=s;
end; // unescapeIon

procedure loadIon(const lp: TLoadPrefs; const path: String; comments: TStringList);
var
  s, l: UnicodeString;
  fn: string;
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

function isCommentFile(const lp: TLoadPrefs; const fn: String): Boolean;
begin
result:=(fn=COMMENTS_FILE)
  or (lpSnglCmnt in lp) and isExtension(fn, COMMENT_FILE_EXT)
  or (lpION in lp) and sameText('descript.ion',fn)
end; // isCommentFile

function isFingerprintFile(const lp: TLoadPrefs; const fn: String): Boolean;
begin
  result := (lpFingerPrints in lp)and isExtension(fn, '.md5')
end; // isFingerprintFile

function hasRightAttributes(const lp: TLoadPrefs; attr: DWORD): Boolean; overload;
begin
  result := ((lpHdnAttr in lp)or (attr and faHidden = 0))
     and ((lpSysAttr in lp) or (attr and faSysFile = 0));
end; // hasRightAttributes

function hasRightAttributes(const lp: TLoadPrefs; const fn: UnicodeString): Boolean; overload;
var
  a: DWORD;
begin
  a := GetFileAttributesW(PWideChar(fn));
  result := hasRightAttributes(lp, a);
end;

function getFiles(const mask: String): TStringDynArray;
var
  sr: TSearchRec;
begin
  result:=NIL;
  if findFirst(mask, faAnyFile, sr) = 0 then
  try
    repeat
      addString(sr.name, result)
    until findNext(sr) <> 0;
   finally
    findClose(sr)
  end;
end; // getFiles

function freeIfTemp(var f:Tfile):boolean; inline;
begin
try
  result:=assigned(f) and f.isTemp();
  if result then freeAndNIL(f);
except result:=FALSE end;
end; // freeIfTemp

function accountAllowed(action: TfileAction; cd: TconnDataMain; f: Tfile): Boolean;
var
  a: TStringDynArray;
begin
  result := FALSE;
  if f = NIL then
    exit;
  if action = FA_ACCESS then
    begin
      result := f.accessFor(cd);
      exit;
    end;
  if f.isTemp() then
    f := f.parent;
  if (action = FA_UPLOAD) and not f.isRealFolder() then
    exit;

  repeat
    a := f.accounts[action];
    if assigned(a)
    and not ((action = FA_UPLOAD) and not f.isRealFolder()) then
      break;
    f := f.parent;
    if f = NIL then
      exit;
  until false;

  result := TRUE;
  if stringExists(USER_ANYONE, a, TRUE) then
    exit;
  result := (cd.usr = '') and stringExists(USER_ANONYMOUS, a, TRUE)
    or assigned(cd.account) and stringExists(USER_ANY_ACCOUNT, a, TRUE)
    or (NIL <> findEnabledLinkedAccount(cd.account, a, TRUE));
end; // accountAllowed

// converts from TfileAttributes to string[4]
function str_(fa: TfileAttributes): RawByteString; overload;
begin
  result := str_(integer(fa))
end;

////////////---------------------------------------------///////////////
constructor Tfile.create(pSrv: IServerTree; const fullpath: UnicodeString);
var
  fp: UnicodeString;
begin
  fp := ExcludeTrailingPathDelimiter(fullpath);
  icon := -1;
  size := -1;
  atime := now();
  mtime := atime;
  flags := [];
  fFilesTree := pSrv;
  setResource(fp);
  if (resource > '') and sysutils.directoryExists(resource) then
    flags := flags+[FA_FOLDER, FA_BROWSABLE];
end; // create

constructor Tfile.createTemp(pSrv: IServerTree; const fullpath: UnicodeString; pParentFile: TFile = NIL);
begin
  create(pSrv, fullpath);
  include(flags, FA_TEMP);
  if Assigned(pParentFile) then
    tempParent := pParentFile.getMainFile
   else
    tempParent := NIL;
end; // createTemp

constructor Tfile.createVirtualFolder(pSrv: IServerTree; const name: string);
begin
  fFilesTree := pSrv;
  icon := -1;
  setResource('');
  flags := [FA_FOLDER, FA_VIRTUAL, FA_BROWSABLE];
  self.fName := name;
  atime := now();
  mtime := atime;
end; // createVirtualFolder

constructor Tfile.createLink(pSrv: IServerTree; const name: String);
begin
  fFilesTree := pSrv;
  icon := -1;
  setName(name);
  atime := now();
  mtime := atime;
  flags := [FA_LINK, FA_VIRTUAL];
end; // createLink

procedure Tfile.setResource(res: UnicodeString);

  function sameDrive(const f1, f2: string): boolean;
  begin
    result := (length(f1) >= 2) and (length(f2) >= 2) and (f1[2] = ':')
      and (f2[2] = ':') and (upcase(f1[1]) = upcase(f2[1]));
  end; // sameDrive

var
  s: UnicodeString;
begin
  if isExtension(res, '.lnk') or fileExists(res+'\target.lnk') then
    begin
      s := extractFileName(res);
      if isExtension(s, '.lnk') then
        setLength(s, length(s)-4);
      setName(s);
      lnk := res;
      res := resolveLnk(res);
      include(flags, FA_SOLVED_LNK);
    end
   else
    exclude(flags, FA_SOLVED_LNK);
  res := ExcludeTrailingPathDelimiter(res);

  // in this case, drive letter may change. useful with pendrives.
  if runningOnRemovable and sameDrive(exePath, res) then
    delete(res, 1,2);

  resource := res;
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
  size := -1;
end; // setResource

procedure Tfile.setName(const name: String);
begin
  if self.name <> name then
   begin
    self.fName := name;
    if getMainFile <> Self then
      exit;
    fFilesTree.ChangedName(Self, name);

   end;
end; // setName

function TFile.getVFS(): RawByteString;
  function getAutoupdatedFiles(): RawByteString;
  var
    i: integer;
    fn: String;
  begin
    result := '';
    i := 0;
    while i < autoupdatedFiles.Count do
      begin
        fn := autoupdatedFiles[i];
        result := result+TLV(FK_NODE, TLVS(FK_NAME, fn)
          + TLVI(FK_DLCOUNT, autoupdatedFiles.getIntByIdx(i)) );
        inc(i);
      end;
  end; // getAutoupdatedFiles

var
  commonFields, s: RawByteString;
  s2: RawByteString;
 {$IFDEF FPC}
  n: TFileNode;
  i: Integer;
  ff: TFile;
 {$ENDIF FPC}
begin
//  nn := node;
  commonFields := TLV(FK_FLAGS, str_(self.flags))
    +TLVS_NOT_EMPTY(FK_RESOURCE, self.resource)
    +TLVS_NOT_EMPTY(FK_COMMENT, self.comment)
    +if_(self.user>'', TLV(FK_USERPWD, b64R(AnsiString(self.user+':'+self.pwd))))
    +if_(self.user>'', TLV(FK_USERPWD_UTF8, b64utf8(self.user+':'+self.pwd)))
    +TLVS_NOT_EMPTY(FK_ACCOUNTS, join(';', self.accounts[FA_ACCESS]) )
    +TLVS_NOT_EMPTY(FK_UPLOADACCOUNTS, join(';', self.accounts[FA_UPLOAD]))
    +TLVS_NOT_EMPTY(FK_DELETEACCOUNTS, join(';', self.accounts[FA_DELETE]))
    +TLVS_NOT_EMPTY(FK_FILESFILTER, self.filesfilter)
    +TLVS_NOT_EMPTY(FK_FOLDERSFILTER, self.foldersfilter)
    +TLVS_NOT_EMPTY(FK_REALM, self.realm)
    +TLVS_NOT_EMPTY(FK_DEFAULTMASK, self.defaultFileMask)
    +TLVS_NOT_EMPTY(FK_UPLOADFILTER, self.uploadFilterMask)
    +TLVS_NOT_EMPTY(FK_DONTCOUNTASDOWNLOADMASK, self.dontCountAsDownloadMask)
    +TLVS_NOT_EMPTY(FK_DIFF_TPL, self.diffTpl);

  result:='';
  if self.isRoot() then
    result := result+TLV(FK_ROOT, commonFields);
  s2 := '';
 {$IFDEF FPC}
  n := Self.node;
  for i:=0 to n.Count-1 do
    begin
      ff := TFile(nodetofile(n.items[i]));
      if Assigned(ff) then
        s2 := s2 + ff.getVFS(); // recursion
    end;
 {$ELSE ~FPC}
  fFilesTree.ForAllSubNodes(Self, procedure (f: TObject)
      var
        ff: TFile;
      begin
        ff := f as TFile;
        if Assigned(ff) then
          s2 := s2 + ff.getVFS(); // recursion
      end);
 {$ENDIF FPC}
//  s2 := fFilesTree.ForAllSubNodesR(Self, addVFS);
  result := result + s2;
  if self.isRoot() then
    begin
    result := result+TLV_NOT_EMPTY(FK_AUTOUPDATED_FILES, getAutoupdatedFiles() );
    exit;
    end;
  if not self.isFile() then
    s := ''
   else
    s := TLV(FK_DLCOUNT, str_(self.DLcount)); // called on a folder would be recursive

// for non-root nodes, subnodes must be calculated first, so to be encapsulated
  result := TLV(FK_NODE, commonFields
                +TLVS_NOT_EMPTY(FK_NAME, self.name)
                +TLV(FK_ADDEDTIME, str_(self.atime))
              {$IFDEF HFS_GIF_IMAGES}
                +TLV_NOT_EMPTY(FK_ICON_GIF, pic2str(self.icon))
              {$ELSE ~HFS_GIF_IMAGES}
                +TLV_NOT_EMPTY(FK_ICON_PNG, pic2str(self.icon, 16))
                +TLV_NOT_EMPTY(FK_ICON32_PNG, pic2str(self.icon, 32))
              {$ENDIF HFS_GIF_IMAGES}
                +s
                +result // subnodes
          );
end;

function TFile.getVFSZ(): RawByteString;
var
 {$IFDEF USE_MORMOT}
  ResJS: RawByteString;
 {$ELSE ~USE_MORMOT}
  ResJ: TJSONObject;
 {$ENDIF USE_MORMOT}
  ResZ: TZipFile;
  icons: TIconsIdxArray;
  stream: TbytesStream;
 {$IFDEF FPC}
  i: Integer;
  img: RawByteString;
 {$ENDIF FPC}
begin
  ResZ := TZipFile.create;

 {$IFDEF USE_MORMOT}
  ResJS := getVFSJZ2(icons);
  ResZ.AddFile('VFS.json', 0, '', ResJS);
 {$ELSE ~USE_MORMOT}
  ResJ := getVFSJZ(icons);
  {$IFDEF FPC}
    ResZ.AddFile('VFS.json', 0, '', StrToUTF8(ResJ.FormatJSON()));
  {$ELSE ~FPC}
    ResZ.AddFile('VFS.json', 0, '', StrToUTF8(ResJ.ToString));
  {$ENDIF FPC}
  ResJ.Free;
 {$ENDIF USE_MORMOT}
  if Length(icons) > 0 then
 {$IFDEF FPC}
    for i := Low(icons) to High(icons) do
      begin
 {$ELSE FPC}
    for var i := Low(icons) to High(icons) do
      begin
        var img: RawByteString;
 {$ENDIF FPC}
        img := pic2str(icons[i], 16);
        if img > '' then
          ResZ.AddFile('icons\' + intToStr(icons[i]) + '.png', 0, '', img);

        img := pic2str(icons[i], 32);
        if img > '' then
          ResZ.AddFile('icons\' + intToStr(icons[i]) + '_BIG.png', 0, '', img);
      end;
  stream := TBytesStream.create();
  ResZ.SaveToStream(stream);
  setLength(result, stream.size);
  if stream.Size > 0 then
    move(stream.bytes[0], result[1], stream.size);
  stream.free;
  ResZ.Free;
end;

 {$IFNDEF USE_MORMOT}
function TFile.getVFSJZ(var p_icons: TIconsIdxArray): TJSONObject;

  function getAutoupdatedFilesJSON(): TJSONArray;
  var
    i: Integer;
    fn: String;
    fj: TJSONObject;
  begin
    result := NIL;
    if autoupdatedFiles.Count = 0 then
      Exit;
    i := 0;
    Result := TJSONArray.Create;// TJSONObject.Create;
    while i < autoupdatedFiles.Count do
      begin
        fn := autoupdatedFiles[i];
        fj := TJSONObject.Create;
       {$IFDEF FPC}
        fj.Add(IntToStr(FK_NAME), fn);
        fj.Add(IntToStr(FK_DLCOUNT), autoupdatedFiles.getIntByIdx(i));
        Result.Add(fj);
       {$ELSE ~FPC}
        fj.AddPair(IntToStr(FK_NAME), fn);
        fj.AddPair(IntToStr(FK_DLCOUNT), autoupdatedFiles.getIntByIdx(i));
        Result.AddElement(fj);
       {$ENDIF FPC}
        inc(i);
      end;
  end; // getAutoupdatedFiles
  //
  {$IFDEF FPC}
  procedure addval(var o: TJSONObject; const key: Integer; const val: TJSONData); OverLoad;
  begin
    if val <> NIL then
      begin
      {$IFDEF FPC}
        o.Add(IntToStr(key), val);
      {$ELSE FPC}
        o.AddPair(IntToStr(key), val);
      {$ENDIF FPC}
      end;
  end;
  {$ELSE ~FPC}
  procedure addval(var o: TJSONObject; const key: Integer; const val: TJSONValue); OverLoad;
  begin
    if val <> NIL then
      begin
      {$IFDEF FPC}
        o.Add(IntToStr(key), val);
      {$ELSE FPC}
        o.AddPair(IntToStr(key), val);
      {$ENDIF FPC}
      end;
  end;
  {$ENDIF FPC}
  //
  function addval(var o: TJSONObject; const key: Integer; const val: TStringDynArray): Boolean; OverLoad;
  var
    va: TJSONArray;
    i: Integer;
  begin
    Result := False;
    if (val <> NIL) and (Length(val) > 0) then
      begin
        va := TJSONArray.Create;
        for i := 0 to Length(val)-1 do
          va.Add(val[i]);
       {$IFDEF FPC}
        o.Add(IntToStr(key), va);
       {$ELSE FPC}
        o.AddPair(IntToStr(key), va);
       {$ENDIF FPC}
        Result := True;
      end;
  end;
  //
  function addval(var o: TJSONObject; const key: Integer; const val: Integer): Boolean; OverLoad;
  begin
    Result := False;
    if val >= 0 then
      begin
       {$IFDEF FPC}
        o.Add(IntToStr(key), val);
       {$ELSE FPC}
        o.AddPair(IntToStr(key), val);
       {$ENDIF FPC}
       Result := True;
      end;
  end;
  //
  function addval(var o: TJSONObject; const key: Integer; const val: RawByteString): Boolean; OverLoad;
  begin
    Result := False;
    if val > '' then
      begin
       {$IFDEF FPC}
        o.Add(IntToStr(key), str2hexU(val));
       {$ELSE FPC}
        o.AddPair(IntToStr(key), str2hexU(val));
       {$ENDIF FPC}
       Result := True;
      end;
  end;
  //
  function addval(var o: TJSONObject; const key: Integer; const val: String): Boolean; OverLoad;
  begin
    Result := False;
    if val > '' then
      begin
       {$IFDEF FPC}
        o.Add(IntToStr(key), val);
       {$ELSE FPC}
        o.AddPair(IntToStr(key), val);
       {$ENDIF FPC}
       Result := True;
      end;
  end;
 {$IFNDEF UNICODE}
  function addval(var o: TJSONObject; const key: Integer; const val: UnicodeString): Boolean; OverLoad;
  begin
    Result := False;
    if val > '' then
      begin
       {$IFDEF FPC}
        o.Add(IntToStr(key), val);
       {$ELSE FPC}
        o.AddPair(IntToStr(key), val);
       {$ENDIF FPC}
       Result := True;
      end;
  end;
 {$ENDIF UNICODE}

  procedure addIcon(ic: Integer);
  var
    i: Integer;
  begin
    if ic <= 0 then
     Exit;
    for I := Low(p_icons) to High(p_icons) do
      if p_icons[i] = ic then
        Exit;
    SetLength(p_icons, Length(p_icons) + 1);
    p_icons[Length(p_icons)-1] := ic;
  end;
  //
  function getCommonFields(): TJSONObject;
  var
    rs: TJSONObject;
  begin
    rs := TJSONObject.Create;
    addval(rs, FK_FLAGS, integer(self.flags));
    addval(rs, FK_RESOURCE, self.resource);
    addval(rs, FK_COMMENT, self.comment);
    if self.user>'' then
      begin
        addval(rs, FK_USERPWD, String( b64utf8W(self.user+':'+self.pwd)));
      end;
    addval(rs, FK_ACCOUNTS, self.accounts[FA_ACCESS]);
    addval(rs, FK_UPLOADACCOUNTS, self.accounts[FA_UPLOAD]);
    addval(rs, FK_DELETEACCOUNTS, self.accounts[FA_DELETE]);
    addval(rs, FK_FILESFILTER, self.filesfilter);
    addval(rs, FK_FOLDERSFILTER, self.foldersfilter);
    addval(rs, FK_REALM, self.realm);
    addval(rs, FK_DEFAULTMASK, self.defaultFileMask);
    addval(rs, FK_UPLOADFILTER, self.uploadFilterMask);
    addval(rs, FK_DONTCOUNTASDOWNLOADMASK, self.dontCountAsDownloadMask);
    addval(rs, FK_DIFF_TPL, self.diffTpl);
    getCommonFields := rs;
  end;
var
  commonFields: TJSONObject;
  subFiles: TJSONArray;
  ii: TIconsIdxArray;
  n: TFileNode;
 {$IFDEF FPC}
  i: integer;
  ff: TFile;
  rs: RawByteString;
 {$ENDIF FPC}
begin
//  nn := node;
//  commonFields := TJSONObject.Create;

  commonFields := getCommonFields;

  subFiles := NIL;
  n := node;
  {$IFDEF USE_VTV}
  if n.ChildCount > 0 then
  {$ELSE ~USE_VTV}
  if n.Count > 0 then
  {$ENDIF ~USE_VTV}
    begin
      subFiles := TJSONArray.Create;
      ii := p_icons;
     {$IFDEF FPC}
      for i:=0 to n.Count-1 do
        begin
          ff := TFile(nodetofile(n.items[i]));
          if Assigned(ff) then
            subFiles.Add(ff.getVFSJZ(ii)); // recursion
        end;
     {$ELSE FPC}
      fFilesTree.ForAllSubNodes(Self, procedure (f: TObject)
          var
            ff: TFile;
          begin
            ff := f as TFile;
            if Assigned(ff) then
              subFiles.Add(ff.getVFSJZ(ii)); // recursion
          end);
     {$ENDIF FPC}
      p_icons := ii;
    end;

  Result := TJSONObject.Create;

  if self.isRoot() then
    begin
      if subFiles <> NIL then
       {$IFDEF FPC}
        commonFields.Add('nodes', subFiles);
       {$ELSE FPC}
        commonFields.AddPair('nodes', subFiles);
       {$ENDIF FPC}
      addval(commonFields, FK_AUTOUPDATED_FILES, getAutoupdatedFilesJSON());
     {$IFDEF FPC}
      Result.Add('root', commonFields);
     {$ELSE FPC}
      Result.AddPair('root', commonFields);
     {$ENDIF FPC}
    end
   else
    begin
      addVal(commonFields, FK_NAME, self.name);
     {$IFDEF FPC}
     //commonFields.Add(IntToStr(FK_ADDEDTIME), self.atime);
      rs := DateTimeToIso8601(self.atime, True);
      commonFields.Add(IntToStr(FK_ADDEDTIME), rs);
     {$ELSE FPC}
      commonFields.AddPair(IntToStr(FK_ADDEDTIME), self.atime);
     {$ENDIF FPC}
//      addVal(Result, FK_ADDEDTIME, self.atime);
      if self.icon >= 0 then
        begin
          addVal(commonFields, FK_ICON_IDX, self.icon);
          addIcon(self.icon);
        end;
      if self.isFile() then
        addVal(commonFields, FK_DLCOUNT, self.DLcount);
      if subFiles <> NIL then
       {$IFDEF FPC}
        commonFields.Add('nodes', subFiles);
       {$ELSE FPC}
        commonFields.AddPair('nodes', subFiles);
       {$ENDIF FPC}
      addVal(Result, FK_NODE, commonFields);
    end;
end;
 {$ELSE USE_MORMOT}
function TFile.getVFSJZ2(var p_icons: TIconsIdxArray; pHumanReadable: Boolean = False): RawByteString;
var
  pr: TTextWriterWriteObjectOptions;

  function getAutoupdatedFilesJSON(): RawByteString;
  var
    i: Integer;
    fn: String;
    j: TJsonWriter;
  begin
    result := '';
    if autoupdatedFiles.Count = 0 then
      Exit;
    i := 0;
    j := TJsonWriter.CreateOwnedStream();
    j.BlockBegin('[', pr);
    while i < autoupdatedFiles.Count do
      begin
        fn := autoupdatedFiles[i];
        j.AddJsonEscape([IntToStr(FK_NAME), fn,
             IntToStr(FK_DLCOUNT), autoupdatedFiles.getIntByIdx(i)]
             );
        inc(i);
        if i < autoupdatedFiles.Count then
          j.BlockAfterItem(pr);
      end;
    j.BlockEnd(']', pr);
    Result := j.Text;
    j.Free;
  end; // getAutoupdatedFiles
  //

  procedure addJval(var o: TJsonWriter; const key: Integer; const val: RawByteString); OverLoad;
  begin
    if val <> '' then
      begin
       o.Add('{"', TTextWriterKind.twNone);
       o.AddJsonEscapeString(IntToStr(key));
       o.Add('"');
       o.Add(':');
       o.AddRawJson(val);
       o.Add('}', TTextWriterKind.twNone);
      end;
  end;
  //
  function addval(var o: TJsonWriter; const key: Integer; const val: TStringDynArray): Boolean; OverLoad;
  var
    i: Integer;
//    k: UTF8String;
  begin
    Result := False;
    if (val <> NIL) and (Length(val) > 0) then
      begin
        o.Add(['{"'+ IntToStr(key) + '":'], TTextWriterKind.twNone);

        o.BlockBegin('[', pr);
//        k := IntToStr(key);
        for i := 0 to Length(val)-1 do
         begin
           o.AddJsonString(val[i]);
           if i < Length(val)-1 then
             o.BlockAfterItem(pr);
         end;
        o.BlockEnd(']', pr);
        o.Add('}', TTextWriterKind.twNone);
        Result := True;
      end;
  end;
  //
  function addval(var o: TJsonWriter; const key: Integer; const val: Integer): Boolean; OverLoad;
  begin
    Result := False;
    if val >= 0 then
      begin
       o.AddJsonEscape([IntToStr(key), val]);
       Result := True;
      end;
  end;
  //
  function addval(var o: TJsonWriter; const key: Integer; const val: RawByteString): Boolean; OverLoad;
  var
    u: RawByteString;
  begin
    Result := False;
    if val > '' then
      begin
       o.Add('{', TTextWriterKind.twNone);
       o.AddJsonEscapeString(IntToStr(key));
       o.Add(':');
       u := str2hex(val);
       o.Add('"');
       o.AddNoJsonEscapeUtf8(u);
       o.Add('"}', TTextWriterKind.twNone);
       Result := True;
      end;
  end;
  //
  function addval(var o: TJsonWriter; const key: Integer; const val: String): Boolean; OverLoad;
  begin
    Result := False;
    if val > '' then
      begin
       o.AddJsonEscape([IntToStr(key), val]);
       Result := True;
      end;
  end;

  procedure addIcon(ic: Integer);
  var
    i: Integer;
  begin
    if ic <= 0 then
     Exit;
    for I := Low(p_icons) to High(p_icons) do
      if p_icons[i] = ic then
        Exit;
    SetLength(p_icons, Length(p_icons) + 1);
    p_icons[Length(p_icons)-1] := ic;
  end;
  //
  function getCommonFields(jw: TJsonWriter): RawByteString;
  begin
    Result := '';
    if addval(jw, FK_FLAGS, integer(self.flags)) then
      jw.AddComma;
    if addval(jw, FK_RESOURCE, self.resource) then
      jw.AddComma;
    if addval(jw, FK_COMMENT, self.comment) then
      jw.AddComma;
    if self.user>'' then
      begin
        if addval(jw, FK_USERPWD, String( b64utf8W(self.user+':'+self.pwd))) then
          jw.AddComma;
      end;
    if addval(jw, FK_ACCOUNTS, self.accounts[FA_ACCESS]) then
      jw.AddComma;
    if addval(jw, FK_UPLOADACCOUNTS, self.accounts[FA_UPLOAD]) then
      jw.AddComma;
    if addval(jw, FK_DELETEACCOUNTS, self.accounts[FA_DELETE]) then
      jw.AddComma;
    if addval(jw, FK_FILESFILTER, self.filesfilter) then
      jw.AddComma;
    if addval(jw, FK_FOLDERSFILTER, self.foldersfilter) then
      jw.AddComma;
    if addval(jw, FK_REALM, self.realm) then
      jw.AddComma;
    if addval(jw, FK_DEFAULTMASK, self.defaultFileMask) then
      jw.AddComma;
    if addval(jw, FK_UPLOADFILTER, self.uploadFilterMask) then
      jw.AddComma;
    if addval(jw, FK_DONTCOUNTASDOWNLOADMASK, self.dontCountAsDownloadMask) then
      jw.AddComma;
    if addval(jw, FK_DIFF_TPL, self.diffTpl) then
      jw.AddComma;
  end;
var
  commonFields: TJsonWriter;
  subFiles: RawByteString;
  ii: TIconsIdxArray;
  n: TFileNode;
 {$IFDEF FPC}
  i: integer;
  ff: TFile;
 {$ENDIF FPC}
begin
//  nn := node;
//  commonFields := TJSONObject.Create;
  if pHumanReadable then
    pr := [woHumanReadable]
   else
    pr := [];

  commonFields := TJsonWriter.CreateOwnedStream();
  getCommonFields(commonFields);

  subFiles := '';
  n := node;
  {$IFDEF USE_VTV}
  if n.ChildCount > 0 then
  {$ELSE ~USE_VTV}
  if n.Count > 0 then
  {$ENDIF ~USE_VTV}
    begin
      var subFilesJ := TJsonWriter.CreateOwnedStream();
//      subFilesJ.Add('{', TTextWriterKind.twNone);
      subFilesJ.BlockBegin('[', pr);
      ii := p_icons;
     {$IFDEF FPC}
      for i:=0 to n.Count-1 do
        begin
          ff := TFile(nodetofile(n.items[i]));
          if Assigned(ff) then
            subFiles.Add(ff.getVFSJZ(ii)); // recursion
        end;
     {$ELSE FPC}
      fFilesTree.ForAllSubNodes(Self, procedure (f: TObject)
          var
            ff: TFile;
          begin
            ff := f as TFile;
            if Assigned(ff) then
              begin
                subFilesJ.AddNoJsonEscapeUtf8(ff.getVFSJZ2(ii)); // recursion
                subFilesJ.AddComma;
              end;
          end);
     {$ENDIF FPC}
      subFilesJ.CancelLastComma;
      subFilesJ.BlockEnd(']', pr);
//      subFilesJ.Add(['}'], TTextWriterKind.twNone);
      subFiles := subFilesJ.Text;
      subFilesJ.Free;
      p_icons := ii;
    end;

  Result := ''; //TJSONObject.Create;

  if self.isRoot() then
    begin
      var auf: RawByteString := getAutoupdatedFilesJSON();
      if subFiles <> '' then
       begin
        commonFields.Add(['{"nodes":'], TTextWriterKind.twNone);
        commonFields.AddNoJsonEscapeUtf8(subFiles);
        commonFields.Add(['}'], TTextWriterKind.twNone);
        commonFields.AddComma;
       end;
      if auf > '' then
        begin
          addJval(commonFields, FK_AUTOUPDATED_FILES, auf);
          commonFields.AddComma;
        end;
      commonFields.CancelLastComma;
      Result := RawByteString('{"root":[')+ commonFields.Text + ']}';
    end
   else
    begin
      //commonFields.AddComma;
      if addVal(commonFields, FK_NAME, self.name) then
        commonFields.AddComma;
      commonFields.Add(['{"'+ IntToStr(FK_ADDEDTIME) + '":"'], TTextWriterKind.twNone);
      commonFields.AddDateTime(self.atime);
      commonFields.Add(['"}'], TTextWriterKind.twNone);
      if self.icon >= 0 then
        begin
          commonFields.AddComma;
          addVal(commonFields, FK_ICON_IDX, self.icon);
          addIcon(self.icon);
        end;
      if self.isFile() then
       begin
        commonFields.AddComma;
        addVal(commonFields, FK_DLCOUNT, self.DLcount);
       end;
      if subFiles <> '' then
       begin
        commonFields.AddComma;
        commonFields.Add(['{"nodes":'], TTextWriterKind.twNone);
        commonFields.AddNoJsonEscapeUtf8(subFiles);
        commonFields.Add(['}'], TTextWriterKind.twNone);
       end;
      Result := RawByteString('{"')+ RawByteString(IntToStr(FK_NODE)) + RawByteString('":[')+ commonFields.Text + ']}';
    end;
  commonFields.Free;
end;
 {$ENDIF USE_MORMOT}

function TFile.getNode: TFileNode;
begin
  if Assigned(Self) and isTemp then
    begin
      if Assigned(tempParent) then
        Result := tempParent.node
       else
        Result := NIL
    end
   else
    Result := fFilesTree.findNode(Self);
end;

procedure Tfile.DeleteChildren;
begin
  fFilesTree.DeleteChildren(Self);
end;

procedure Tfile.DeleteNode;
begin
  fFilesTree.DeleteNode(Self);
end;

procedure Tfile.ExpandNode;
var
  n: TFileNode;
begin
  n := Self.node;
  if Assigned(n) then
     n.expanded := TRUE;
end;

function Tfile.same(f: Tfile): boolean;
begin result:=(self = f) or (resource = f.resource) end;

function Tfile.toggle(att: TfileAttribute): boolean;
begin
  if att in flags then
    exclude(flags, att)
   else
    include(flags, att);
  result := att in flags
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

function Tfile.isEmptyFolder(loadPrefs: TLoadPrefs; cd: TconnDataMain=NIL): Boolean;
var
  listing: TfileListing;
begin
  result := FALSE;
  if not isFolder() then
    exit;
  listing := TfileListing.create(fFilesTree);
//** i fear it is not ok to use fromFolder() to know if the folder is empty, because it gives empty also for unallowed folders.
  listing.fromFolder(loadPrefs, self, cd, FALSE, 1 );
  result := length(listing.dir) = 0;
  listing.free;
end; // isEmptyFolder

// uses comments file
function Tfile.getDynamicComment(loadPrefs: TLoadPrefs; skipParent: boolean=FALSE): String;
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
      loadIon(loadPrefs, resource+'\..', comments);
      result:=comments.values[name];
      end;
    if result > '' then
      result:=unescapeNL(result);
    comments.free
  end;
finally result:=macroQuote(result) end;
end; // getDynamicComment

function findNameInDescriptionFile(const txt, name: String): Integer;
begin result:=reMatch(txt, '^'+quoteRegExprMetaChars(quoteIfAnyChar(' ',name)), 'mi') end;

procedure Tfile.setDynamicComment(loadPrefs: TLoadPrefs; cmt: String);
var
  s: UnicodeString;
  path, name: string;
  i: integer;
begin
  if not isTemp() then
  begin
    comment:=cmt; // quite easy
    exit;
  end;
  path := resource+COMMENT_FILE_EXT;
  if fileExists(path) then
  begin
    if cmt='' then
      deleteFile(path)
     else
      saveTextFile(path, cmt);
    exit;
  end;
  name := extractFileName(resource);

// we prefer descript.ion, but if its support was disabled,
// or it doesn't exist while hfs.comments.txt does, then we'll use the latter
  path := extractFilePath(resource)+COMMENTS_FILE;
  if not (lpION in loadPrefs)
    or fileExists(path) and not fileExists(extractFilePath(resource)+'descript.ion') then
   saveTextFile(path, setKeyInString(UnUTF(loadFile(path)), name, escapeNL(cmt)));

  if not (lpION in loadPrefs) then
    exit;

  path := extractFilePath(resource)+'descript.ion';
  try
    s := loadDescriptionFile(loadPrefs, path);
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
   except
  end;
end; // setDynamicComment

function Tfile.getParent():Tfile;
var
  p: TFileNode;
begin
  if isTemp() then
    result := getMainFile
   else if isRoot then
    result := NIL
   else if node = NIL then
    result := NIL
   else
      try
        p := fFilesTree.getParentNode(Self);
        if p = NIL then
          result := NIL
         else
          result := TFile(fFilesTree.nodeToFile(p));
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
  n: TFileNode;
begin
  if isTemp or not isFolder then
    Result := NIL
   else
    begin
      n := fFilesTree.getFirstChild(Self);
      if Assigned(n) then
        Result := TFile(fFilesTree.nodeToFile(n))
       else
        Result := NIL
        ;
    end;
end;

function Tfile.getNextSibling: TFile;
var
  n: TFileNode;
begin
  n := fFilesTree.getNextSibling(Self);
  if Assigned(n) then
    begin
      Result := TFile(fFilesTree.nodeToFile(n));
    end
    else
      Result := NIL;
end;

function TFile.getShownRealm(LP: TLoadPrefs): String;
var
  f: Tfile;
begin
  f := self;
  repeat
    result := f.realm;
    if result > '' then
      exit;
    f := f.parent;
  until f = NIL;
  if lpUseCommentAsRealm in lp then
    result := getDynamicComment(LP);
end; // getShownRealm

function Tfile.getDLcount():integer;
begin
  if isFolder() then
    result := getDLcountRecursive()
   else if isTemp() then
    result := autoupdatedFiles.getInt(resource)
   else
    result := FDLcount;
end; // getDLcount

procedure Tfile.setDLcount(i: Integer);
begin
  if isTemp() then
    autoupdatedFiles.setInt(resource, i)
   else
    FDLcount:=i;
end; // setDLcount

function Tfile.getDLcountRecursive(): Integer;
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
  if node = NIL then
    exit;
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
  if FA_VIRTUAL in flags then
    result:=0
   else
    result:=diskSpaceAt(resource);
end; // diskfree

procedure Tfile.setupImage(sysIcons: Boolean; newIcon: Integer);
begin
  icon := newIcon;
  setupImage(sysIcons);
end; // setupImage

procedure Tfile.setupImage(sysIcons: Boolean; pNode: TFileNode = NIL);
var
  lIcon: Integer;
begin
  if icon >= 0 then
    lIcon := icon
   else
    lIcon := getIconForTreeview(sysIcons);
  fNodeImageindex := lIcon;
  fFilesTree.DoImageChanged(Self, pNode);

end; // setupImage

function Tfile.getSystemIcon(): integer;
var
  ic: PcachedIcon;
  i: integer;
begin
  result := icon;
  if result >= 0 then
    exit;
  if isFile() then
    for i:=0 to length(iconMasks)-1 do
      if fileMatch(iconMasks[i].str, name) then
        begin
          result := iconMasks[i].int;
          exit;
        end;
  ic := iconsCache.get(resource);
  if ic = NIL then
    begin
      result := IconsDM.getImageIndexForFile(resource);
      iconsCache.put(resource, result, mtime);
      exit;
    end;
  if mtime <= ic.time then
    result := ic.idx
   else
    begin
      result := IconsDM.getImageIndexForFile(resource);
      ic.time := mtime;
      ic.idx := result;
    end;
end; // getSystemIcon

function Tfile.gotSystemIcon(): boolean;
var
  ic: PcachedIcon;
  i: integer;
begin
  result := icon >= 0;
  if result then
    exit;
  if isFile() then
    for i:=0 to length(iconMasks)-1 do
      if fileMatch(iconMasks[i].str, name) then
        begin
          result := True;
          exit;
        end;
  ic := iconsCache.get(resource);
  if ic = NIL then
    begin
      result := False;
      exit;
    end;
  if mtime <= ic.time then
    result := True
   else
    begin
      result := False
    end;
end;

function Tfile.getIconForTreeview(sysIcons: Boolean): Integer;
begin
  if FA_UNIT in flags then
    result := ICON_UNIT
   else if FA_ROOT in flags then
    result := ICON_ROOT
   else if FA_LINK in flags then
    result := ICON_LINK
   else if FA_FOLDER in flags then
    if FA_VIRTUAL in flags then
      result := ICON_FOLDER
     else
      result := ICON_REAL_FOLDER
   else
    if sysIcons and (resource > '') then
      result := IconsDM.getImageIndexForFile(resource) // skip iconsCache
     else
      result := ICON_FILE;
end; // getIconForTreeview

function Tfile.getHasThumb: Boolean;
var
  e: String;
begin
  if not isFile then
    Result := false;
  e := ExtractFileExt(resource);
  if idxOf(e, thumbsShowToExt, True) >= 0 then
//  if (e = '.jpg') or (e = '.jpeg') or (e = '.png') or
//     (e = '.gif') or (e = '.webp') or (e = '.bmp') or (e = '.ico') then
    Result := True;
  fHasThumb := Result;
end;

function Tfile.getThumb(var str: TStream; var format: String; size: Integer; AcceptWebP: Boolean = false): Boolean;
var
  b: RawByteString;
  e, s: Integer;
  ext: String;
  bmp: TBitmap;
begin
  Result := False;
  if getHasThumb then
    begin
      ext := ExtractFileExt(resource);
      if (ext = '.jpg') or (ext = '.jpeg') then
        begin
          b := RDFileUtil.loadFile(Self.resource, 0, 96*KILO);
          s := pos(rawbytestring(#$FF#$D8#$FF), b, 2);
          if s > 0 then
            e := pos(rawbytestring(#$FF#$D9), b, s)
           else
            e := 0;
          if (s>0) and (e>0) then
            begin
              str := TRawByteStringStream.create(Copy(b, s, e-s+2));
              str.Position := 0;
              format := 'image/jpeg';
              Result := True;
            end
           else
             begin
               format := 'image/jpeg';
               Result := false;
             end;
        end;
      if not Result then
        begin
          bmp := TBitmap.Create;
          if size <= 0 then
           size := 120;
          e := GetThumbFromCache(resource, bmp, size);
          if Succeeded(e) then
            begin
              if AcceptWebP and bmp2strWebPAllowed then
                begin
                 b := bmp2strWebP(bmp);
                 format := 'image/webp';
                end
               else
                begin
                 b := bmp2str(bmp);
                 format := 'image/png';
                end;
              str := TRawByteStringStream.Create(b);
              str.Position := 0;
              Result := str.Size > 0;
            end
           else
            Result := False;
          bmp.Free;
       end;
    end;
end;

function Tfile.relativeURL(fullEncode:boolean=FALSE): String;
begin
  if isLink() then
    result := xtpl(resource, ['%ip%', defaultIP])
   else if isRoot() then
     result := ''
    else
     result := encodeURL(name, fullEncode)+if_(isFolder(), String('/'))
end;

function Tfile.getFolder(): String;
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

function Tfile.isDLforbidden(): Boolean;
var
  f: Tfile;
begin
// the flag can be in this node
  result := FA_DL_FORBIDDEN in flags;
  if result or not isTemp() then
    exit;
  f := TFile(fFilesTree.nodeToFile(node));
  result := assigned(f) and (FA_DL_FORBIDDEN in f.flags);
end; // isDLforbidden

function Tfile.isNew(): Boolean;
var
  t: Tdatetime;
begin
  if FA_TEMP in flags then
    t := mtime
   else
    t := atime;
  result := (filesStayFlaggedForMinutes > 0)
    and (trunc(abs(now()-t)*24*60) <= filesStayFlaggedForMinutes)
end; // isNew

function Tfile.getRecursiveDiffTplAsStr(outInherited: Pboolean=NIL; outFromDisk: Pboolean=NIL): String;
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
    if fileExists(fn) then
      begin
//        doNothing()
      end
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

function Tfile.getDefaultFile(): Tfile;
var
  f: Tfile;
  mask, s: string;
  sr: TsearchRec;
begin
  result := NIL;
  mask := getRecursiveFileMask();
  if mask = '' then
    exit;

  f := getFirstChild();
// if this folder has been dinamically generated, the treenode is not actually
// its own, and we won't care about subitems }
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
    result := Tfile.createTemp(fFilesTree, resource+'\'+sr.name, self); // temporary nodes are bound to the parent's node
  finally findClose(sr) end;
  exit;
  end;
end; // getDefaultFile

function Tfile.shouldCountAsDownload(): Boolean;
var
  f: Tfile;
  mask: string;
begin
  result := not (FA_DONT_COUNT_AS_DL in flags);
  if not result then
    exit;
  f := self;
  repeat
    mask := f.dontCountAsDownloadMask;
    f := f.parent;
  until (f = NIL) or (mask > '');
  if mask > '' then
    result := not fileMatch(mask, name)
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

procedure Tfile.recursiveApply(callback: TfileCallback; par: IntPtr=0; par2: IntPtr=0);
var
  f, fNext: TFile;
  r: TfileCallbackReturn;
begin
  r := callback(self, FALSE, par, par2);
  if FCB_DELETE in r then
    begin
      Self.DeleteNode;
      exit;
    end;
  if FCB_NO_DEEPER in r then
    exit;
  f := getFirstChild();
  while assigned(f) do
    begin
      fNext := f.getNextSibling(); // "next" must be saved this point because the callback may delete the current node
      f.recursiveApply(callback, par, par2);
      f := fNext;
    end;
  if FCB_RECALL_AFTER_CHILDREN in r then
    begin
      r := callback(self, TRUE, par, par2);
      if FCB_DELETE in r then
        Self.DeleteNode;
    end;
end; // recursiveApply

function Tfile.hasRecursive(attributes: TfileAttributes; orInsteadOfAnd: Boolean=FALSE; outInherited: Pboolean=NIL): Boolean;
var
  f: Tfile;
begin
  result := FALSE;
  f := self;
  if assigned(outInherited) then
    outInherited^ := FALSE;
  while assigned(f) do
    begin
      result := orInsteadOfAnd and (attributes*f.flags <> [])
        or (attributes*f.flags = attributes);
      if result or f.isRoot then
        exit;
      f := f.parent;
      if assigned(outInherited) then
        outInherited^:=TRUE;
    end;
  if assigned(outInherited) then
    outInherited^:=FALSE; // grant it is set only if result=TRUE
end; // hasRecursive

function Tfile.hasRecursive(attribute: TfileAttribute; outInherited: Pboolean=NIL): Boolean;
begin result:=hasRecursive([attribute], FALSE, outInherited) end;

function Tfile.accessFor(cd: TconnDataMain): Boolean;
begin
  if cd = NIL then
    result := accessFor('', '')
   else
    result := accessFor(cd.usr, cd.pwd)
end; // accessFor

function Tfile.accessFor(const username, password: String): Boolean;
var
  a: Paccount;
  f: Tfile;
  list: TStringDynArray;
begin
  result := FALSE;
  if isFile() and isDLforbidden() then
    exit;
  result := FALSE;
  f := self;
while assigned(f) do
  begin
    list := f.accounts[FA_ACCESS]; // shortcut

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
    if f.user > '' then
      exit;

    f := f.parent;
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

function Tfile.getRecursiveFileMask(): String;
var
  f: Tfile;
begin
  f := self;
  repeat
    result := f.defaultFileMask;
    if result > '' then
      exit;
    f := f.parent;
  until f = NIL;
end; // getRecursiveFileMask

function Tfile.getAccountsFor(action: TfileAction; specialUsernames: boolean=FALSE; outInherited: Pboolean=NIL): TstringDynArray;
var
  f: Tfile;
  s: String;
begin
result:=NIL;
f:=self;
if assigned(outInherited) then outInherited^:=FALSE;
while assigned(f) do
  begin
  for s in f.accounts[action] do
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

procedure Tfile.getFiltersRecursively(var files, folders: String);
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

function Tfile.setBrowsable(childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;
begin
  if not Self.isFolder() then
    exit;
  if (FA_BROWSABLE in Self.flags) = boolean(par) then
    VFSmodified := TRUE
   else
    exit;
  if boolean(par) then
    exclude(Self.flags, FA_BROWSABLE)
   else
    include(Self.flags, FA_BROWSABLE);
end; // setBrowsable

function setBrowsable(f: Tfile; childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;
begin
  Result := f.setBrowsable(childrenDone, par, par2);
end;

function nodeToFile(n: TFileNode): Tfile; inline;
begin
  if n = NIL then
   result := NIL
  else
   result := Tfile(n.data)
end;

function nodeText(n: TFileNode): String; inline;
begin
  if n = NIL then
   result := ''
  else
   result := n.Text
end;

function setNilChildrenFrom(nodes: TFileNodeDynArray; father: integer): integer;
var
  i: integer;
begin
result:=0;
for i:=father+1 to length(nodes)-1 do
  if nodes[i].Parent = nodes[father] then
    begin
    nodes[i]:=NIL;
    inc(result);
    end;
end; // setNilChildrenFrom


function loadMD5for(const fn: String): String;
begin
  if getMtimeUTC(fn+'.md5') < getMtimeUTC(fn) then
    result := ''
   else
    result := trim(getTill(' ', UnUTF(loadfile(fn+'.md5'))))
end; // loadMD5for

function loadFingerprint(const fn: String): String;
var
  hasher: Thasher;
begin
  result := loadMD5for(fn);
  if result > '' then
    exit;

  hasher := Thasher.create();
  hasher.loadFrom(ExtractFilePath(fn));
  result := hasher.getHashFor(fn);
  hasher.Free;
end; // loadFingerprint

function addVFSheader(const vfsdata: RawByteString): RawByteString;
var
  data: RawByteString;
begin
  if length(vfsdata) > COMPRESSION_THRESHOLD then
    data := TLV(FK_COMPRESSED_ZLIB,
//    ZcompressStr2(vfsdata, zcFastest, 31,8, zsDefault) );
      ZcompressStr(vfsdata, TCompressionLevel.clDefault, TZStreamType.zsGZip) )
   else
    data := vfsdata;
  result := TLV(FK_HEAD, VFS_FILE_IDENTIFIER)
    +TLV(FK_FORMAT_VER, str_(CURRENT_VFS_FORMAT))
    +TLV(FK_HFS_VER, srvConst.VERSION)
    +TLV(FK_HFS_BUILD, VERSION_BUILD)
    +TLV(FK_CRC, str_(getCRC(data)));  // CRC must always be right before data
  result := result + data
end; // addVFSheader

end.
