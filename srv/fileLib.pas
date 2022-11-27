unit fileLib;
{$I NoRTTI.inc}

interface

uses
  // delphi libs
  Windows, Messages,
 {$IFDEF FMX}
  FMX.Graphics, System.UITypes,
  FMX.TreeView,
 {$ELSE ~FMX}
  Graphics,
  Forms,
  ComCtrls,
 {$ENDIF FMX}
  math, Types, SysUtils, JSON,
  HSLib, srvClassesLib;

type

  TfileAttribute = (
    FA_FOLDER,       // folder kind
    FA_VIRTUAL,      // does not exist on disc
    FA_ROOT,         // only the root item has this attribute
    FA_BROWSABLE,    // permit listing of this folder (not recursive, only dir)
    FA_HIDDEN,       // hidden items won't be shown to browsers (not recursive)
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

 {$IFDEF FMX}
  TFileTree = TTreeView;
  TFileNode = TTreeViewItem;
 {$ELSE ~FMX}
  TFileTree = TTreeView;
  TFileNode = TTreeNode;
 {$ENDIF FMX}

  Tfile = class;
//  TconnData = class;

  TfileCallbackReturn = set of (FCB_NO_DEEPER, FCB_DELETE, FCB_RECALL_AFTER_CHILDREN); // use FCB_* flags

  // returning FALSE stops recursion
  TfileCallback = function(f: Tfile; childrenDone: boolean; par, par2: IntPtr): TfileCallbackReturn;

  TfileAction = (FA_ACCESS, FA_DELETE, FA_UPLOAD);

  TLoadPrefs = set of (lpION, lpHideProt, lpSysAttr, lpHdnAttr, lpSnglCmnt, lpFingerPrints, lpRecurListing, lpOEMForION);

  TFindFileNode = function(f: TFile): TFileNode;

  TIconsIdxArray = array of integer;


  Tfile = class (Tobject)
  private
//    fFilesTree: TFilesTree;
    fMainTreeView: TFileTree;
    fLocked: boolean;
    FDLcount: integer;
    tempParent: TFile;
//    fGetFileNode: TFindFileNode;
//    fNode: TFileNode;
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
    constructor create(pTree: TFileTree; const fullpath: String);
    constructor createTemp(pTree: TFileTree; const fullpath: String; pParentFile: TFile = NIL);
    constructor createVirtualFolder(pTree: TFileTree; const name:string);
    constructor createLink(pTree: TFileTree; const name: String);
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
    function  isDLforbidden(): Boolean;
    function  relativeURL(fullEncode: Boolean=FALSE): String;
    procedure setupImage(sysIcons: Boolean; newIcon: integer); overload;
    procedure setupImage(sysIcons: Boolean; pNode: TFileNode = NIL); overload;
    function  getSystemIcon(): integer;
    function  gotSystemIcon(): boolean;
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
    procedure setResource(res: String);
    function  getDynamicComment(loadPrefs: TLoadPrefs; skipParent: Boolean=FALSE): String;
    procedure setDynamicComment(loadPrefs: TLoadPrefs; cmt: String);
    function  getRecursiveDiffTplAsStr(outInherited: Pboolean=NIL; outFromDisk: Pboolean=NIL): String;
    function  getVFS(): RawByteString;
    function  getVFSZ(): RawByteString;
    function  getVFSJZ(var p_icons: TIconsIdxArray): TJSONObject;
     // locking prevents modification of all its ancestors and descendants
    procedure lock();
    procedure unlock();
    procedure SyncNode(pNode: TFileNode);
    function  findNode: TFileNode;
    function  getNode: TFileNode;
    procedure DeleteChildren;
    function  isLocked():boolean;
    function  getFirstChild: TFile;
    function  getNextSibling: TFile;
    function  getMainFile: TFile;
    function  setBrowsable(childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;
    property  parent: Tfile read getParent;
    property  DLcount: Integer read getDLcount write setDLcount;
    property  node: TFileNode read getNode;
    property  locked: Boolean read fLocked;
//    property  mainTree: TFilesTree read fFilesTree;
    property  mainTree: TFileTree read fMainTreeView;
//    property  onGetFileNode: TFindFileNode read fGetFileNode write fGetFileNode;
   end; // Tfile

function nodeToFile(n: TFileNode): Tfile;
function nodeIsLocked(n: TFileNode): Boolean;
function isCommentFile(const lp: TLoadPrefs; const fn: string): Boolean;
function isFingerprintFile(const lp: TLoadPrefs; const fn: string): Boolean;
function hasRightAttributes(const lp: TLoadPrefs; const fn: string): Boolean; overload;
function hasRightAttributes(const lp: TLoadPrefs; attr: Integer): Boolean; overload;
function findNameInDescriptionFile(const txt, name: String): Integer;
function freeIfTemp(var f: Tfile): Boolean; inline;
function accountAllowed(action: TfileAction; cd: TconnDataMain; f: Tfile): Boolean;
function str_(fa: TfileAttributes): RawByteString; overload;

function loadMD5for(const fn: String): String;
function loadFingerprint(const fn: String): String;
function setBrowsable(f: Tfile; childrenDone: Boolean; par, par2: IntPtr): TfileCallbackReturn;

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
{$IFDEF HFS_GIF_IMAGES}
  FK_ICON_GIF = 15;
{$ELSE ~HFS_GIF_IMAGES}
  FK_ICON_GIF = 15;
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
  strutils, iniFiles, Classes,
  RegExpr,
  RDUtils, RDFileUtil,
  RDSysUtils,
  RnQZip, RnQCrypt,
  serverLib,
  srvConst, srvUtils, srvVars, IconsLib,
  parserLib
  ;

function loadDescriptionFile(const lp: TLoadPrefs; const fn: string): string;
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

function hasRightAttributes(const lp: TLoadPrefs; attr: Integer): Boolean; overload;
begin
result:=((lpHdnAttr in lp)or (attr and faHidden = 0))
  and ((lpSysAttr in lp) or (attr and faSysFile = 0));
end; // hasRightAttributes

function hasRightAttributes(const lp: TLoadPrefs; const fn: String): Boolean; overload;
begin result:=hasRightAttributes(lp, GetFileAttributes(pChar(fn))) end;

function getFiles(const mask: String): TStringDynArray;
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
constructor Tfile.create(pTree: TFileTree; const fullpath: String);
var
  fp: String;
begin
  fp := ExcludeTrailingPathDelimiter(fullpath);
  icon := -1;
  size := -1;
  atime := now();
  mtime := atime;
  flags := [];
  fMainTreeView := pTree;
  setResource(fp);
  if (resource > '') and sysutils.directoryExists(resource) then
    flags := flags+[FA_FOLDER, FA_BROWSABLE];
end; // create

constructor Tfile.createTemp(pTree: TFileTree; const fullpath: String; pParentFile: TFile = NIL);
begin
  create(pTree, fullpath);
  include(flags, FA_TEMP);
  if Assigned(pParentFile) then
    tempParent := pParentFile.getMainFile
   else
    tempParent := NIL;
end; // createTemp

constructor Tfile.createVirtualFolder(pTree: TFileTree; const name: string);
begin
  fMainTreeView := pTree;
  icon := -1;
  setResource('');
  flags := [FA_FOLDER, FA_VIRTUAL, FA_BROWSABLE];
  self.name := name;
  atime := now();
  mtime := atime;
end; // createVirtualFolder

constructor Tfile.createLink(pTree: TFileTree; const name: String);
begin
  fMainTreeView := pTree;
  icon := -1;
  setName(name);
  atime := now();
  mtime := atime;
  flags := [FA_LINK, FA_VIRTUAL];
end; // createLink

procedure Tfile.setResource(res: String);

  function sameDrive(const f1, f2: string): boolean;
  begin
    result := (length(f1) >= 2) and (length(f2) >= 2) and (f1[2] = ':')
      and (f2[2] = ':') and (upcase(f1[1]) = upcase(f2[1]));
  end; // sameDrive

var
  s: String;
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
var
  n: TFileNode;
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

function TFile.getVFS(): RawByteString;
  function getAutoupdatedFiles():RawByteString;
  var
    i: integer;
    fn: string;
  begin
  result:='';
  i:=0;
  while i < autoupdatedFiles.Count do
    begin
    fn:=autoupdatedFiles[i];
    result:=result+TLV(FK_NODE, TLV(FK_NAME, StrToUTF8(fn))
      + TLV(FK_DLCOUNT, str_(autoupdatedFiles.getInt(fn))) );
    inc(i);
    end;
  end; // getAutoupdatedFiles

var
  i: integer;
  commonFields, s: RawByteString;
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
    result := result+TLV(FK_ROOT, commonFields );
  for i:=0 to node.Count-1 do
    begin
    var
  {$IFDEF FMX}
      ff: TFile := nodetofile(node.items[i]);
  {$ELSE ~FMX}
      ff: TFile := nodetofile(node.item[i]);
  {$ENDIF FMX}
      if Assigned(ff) then
         result := result+ ff.getVFS(); // recursion
    end;
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
  ResJ: TJSONObject;
  ResZ: TZipFile;
  icons: TIconsIdxArray;
  stream: Tbytesstream;
begin
  ResJ := getVFSJZ(icons);
  ResZ := TZipFile.create;

  ResZ.AddFile('VFS.json', 0, '', StrToUTF8(ResJ.ToString));
  if Length(icons) > 0 then
    for var i := Low(icons) to High(icons) do
      begin
        var img: RawByteString;
        img := pic2str(icons[i], 16);
        if img > '' then
          ResZ.AddFile(intToStr(icons[i]) + '.png', 0, '', img);

        img := pic2str(icons[i], 32);
        if img > '' then
          ResZ.AddFile(intToStr(icons[i]) + '_BIG.png', 0, '', img);
      end;
  stream := TBytesStream.create();
  ResZ.SaveToStream(stream);
  setLength(result, stream.size);
  if stream.Size > 0 then
    move(stream.bytes[0], result[1], stream.size);
  stream.free;
  ResZ.Free;
  ResJ.Free;
end;

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
        fj.AddPair(IntToStr(FK_NAME), fn);
        fj.AddPair(IntToStr(FK_DLCOUNT), autoupdatedFiles.getInt(fn));
        Result.AddElement(fj);
        inc(i);
      end;
  end; // getAutoupdatedFiles
  //
  procedure addval(var o: TJSONObject; const key: Integer; const val: TJSONValue); OverLoad;
  begin
    if val <> NIL then
      begin
        o.AddPair(IntToStr(key), val);
      end;
  end;
  //
  procedure addval(var o: TJSONObject; const key: Integer; const val: TStringDynArray); OverLoad;
  var
    va: TJSONArray;
  begin
    if (val <> NIL) and (Length(val) > 0) then
      begin
        va := TJSONArray.Create;
        for var i := 0 to Length(val)-1 do
          va.Add(val[i]);
        o.AddPair(IntToStr(key), va);
      end;
  end;
  //
  procedure addval(var o: TJSONObject; const key: Integer; const val: Integer); OverLoad;
  begin
    if val >= 0 then
      begin
        o.AddPair(IntToStr(key), val);
      end;
  end;
  //
  procedure addval(var o: TJSONObject; const key: Integer; const val: RawByteString); OverLoad;
  begin
    if val > '' then
      begin
        o.AddPair(IntToStr(key), str2hexU(val));
      end;
  end;
  //
  procedure addval(var o: TJSONObject; const key: Integer; const val: String); OverLoad;
  begin
    if val > '' then
      begin
        o.AddPair(IntToStr(key), val);
      end;
  end;
  procedure addIcon(ic: Integer);
  begin
    if ic <= 0 then
     Exit;
    for var I := Low(p_icons) to High(p_icons) do
      if p_icons[i] = ic then
        Exit;
    SetLength(p_icons, Length(p_icons) + 1);
    p_icons[Length(p_icons)-1] := ic;
  end;
  //
  function getCommonFields(): TJSONObject;
  begin
    Result := TJSONObject.Create;
    addval(Result, FK_FLAGS, integer(self.flags));
    addval(Result, FK_RESOURCE, self.resource);
    addval(Result, FK_COMMENT, self.comment);
    if self.user>'' then
      begin
        addval(Result, FK_USERPWD, b64utf8W(self.user+':'+self.pwd));
      end;
    addval(Result, FK_ACCOUNTS, self.accounts[FA_ACCESS]);
    addval(Result, FK_UPLOADACCOUNTS, self.accounts[FA_UPLOAD]);
    addval(Result, FK_DELETEACCOUNTS, self.accounts[FA_DELETE]);
    addval(Result, FK_FILESFILTER, self.filesfilter);
    addval(Result, FK_FOLDERSFILTER, self.foldersfilter);
    addval(Result, FK_REALM, self.realm);
    addval(Result, FK_DEFAULTMASK, self.defaultFileMask);
    addval(Result, FK_UPLOADFILTER, self.uploadFilterMask);
    addval(Result, FK_DONTCOUNTASDOWNLOADMASK, self.dontCountAsDownloadMask);
    addval(Result, FK_DIFF_TPL, self.diffTpl);
  end;
var
  i: integer;
  commonFields: TJSONObject;
  subFiles: TJSONArray;
begin
//  nn := node;
//  commonFields := TJSONObject.Create;

  commonFields := getCommonFields;

  subFiles := NIL;
  if node.Count > 0 then
    begin
      subFiles := TJSONArray.Create;
      for i:=0 to node.Count-1 do
        begin
        var
 {$IFDEF FMX}
          ff: TFile := nodetofile(node.items[i]);
 {$ELSE ~FMX}
          ff: TFile := nodetofile(node.item[i]);
 {$ENDIF FMX}
          if Assigned(ff) then
            subFiles.Add(ff.getVFSJZ(p_icons)); // recursion
        end;
    end;

  Result := TJSONObject.Create;

  if self.isRoot() then
    begin
      if subFiles <> NIL then
        commonFields.AddPair('nodes', subFiles);
      addval(commonFields, FK_AUTOUPDATED_FILES, getAutoupdatedFilesJSON());
      Result.AddPair('root', commonFields);
    end
   else
    begin
      addVal(commonFields, FK_NAME, self.name);
      commonFields.AddPair(IntToStr(FK_ADDEDTIME), self.atime);
//      addVal(Result, FK_ADDEDTIME, self.atime);
      if self.icon >= 0 then
        begin
          addVal(commonFields, FK_ICON_IDX, self.icon);
          addIcon(self.icon);
        end;
      if self.isFile() then
        addVal(commonFields, FK_DLCOUNT, self.DLcount);
      if subFiles <> NIL then
        commonFields.AddPair('nodes', subFiles);
      addVal(Result, FK_NODE, commonFields);
    end;
end;

procedure TFile.SyncNode(pNode: TFileNode);
begin
//  fNode := pNode;
//  if Assigned(pNode) then
//    if pNode.Text <> name then
//      pNode.Text := name;
end;

function TFile.findNode: TFileNode;
var
  n: TFileNode;
begin
//  if Assigned(fGetFileNode) then
//    Result := fGetFileNode(self)
//   else
//    Result := NIL;
 {$IFDEF FMX}
  for var i := 0 to mainTree.Count-1 do
   begin
    n := mainTree.Items[i];
    if n.Data.AsObject = Self then
      Exit(n);
   end;
 {$ELSE ~FMX}
  for n in mainTree.Items do
    if n.Data = Self then
      Exit(n);
 {$ENDIF FMX}
  Result := NIL;
end;

function TFile.getNode: TFileNode;
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

procedure Tfile.DeleteChildren;
var
  n: TFileNode;
begin
  n := getNode;
  if Assigned(n) then
    n.DeleteChildren;
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

function Tfile.isEmptyFolder(loadPrefs: TLoadPrefs; cd: TconnDataMain=NIL): Boolean;
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
  s:=loadDescriptionFile(loadPrefs, path);
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
  p: TFileNode;
begin
  if node = NIL then
    result := NIL
   else
    if isTemp() then
      result := getMainFile
     else
      try
 {$IFDEF FMX}
        p := node.ParentItem;
        if p = NIL then
          result := NIL
         else
          result := Tfile(p.data.AsObject);
 {$ELSE ~FMX}
        p := node.parent;
        if p = NIL then
          result := NIL
         else
          result := p.data
 {$ENDIF FMX}
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
      n := node;
      if Assigned(n) then
 {$IFDEF FMX}
        begin
          if n.Count > 0 then
            Result := nodeToFile(n.Items[0])
        end
 {$ELSE ~FMX}
        Result := nodeToFile(n.getFirstChild)
 {$ENDIF FMX}
       else
        Result := NIL
        ;
    end;
end;

function Tfile.getNextSibling: TFile;
var
  n: TFileNode;
begin
  n := node;
   if Assigned(n) then
        Result := nodeToFile(n.getNextSibling)
    else
      Result := NIL;
end;

function Tfile.getDLcount():integer;
begin
  if isFolder() then
    result := getDLcountRecursive()
   else if isTemp() then
    result := autoupdatedFiles.getInt(resource)
   else
    result := FDLcount;
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

procedure Tfile.setupImage(sysIcons: Boolean; newIcon: Integer);
begin
  icon := newIcon;
  setupImage(sysIcons);
end; // setupImage

procedure Tfile.setupImage(sysIcons: Boolean; pNode: TFileNode);
begin
  if pNode = NIL then
    pNode := node;
  if pNode = NIL then
    Exit;
  if icon >= 0 then
    pNode.Imageindex := icon
   else
    pNode.ImageIndex := getIconForTreeview(sysIcons);
  pNode.SelectedIndex := pNode.imageindex;
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

function Tfile.relativeURL(fullEncode:boolean=FALSE): String;
begin
  if isLink() then
    result := xtpl(resource, ['%ip%', defaultIP])
   else if isRoot() then
     result := ''
    else
     result := encodeURL(name, fullEncode)+if_(isFolder(),'/')
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
result:=FA_DL_FORBIDDEN in flags;
if result or not isTemp() then exit;
f:=nodeToFile(node);
result:=assigned(f) and (FA_DL_FORBIDDEN in f.flags);
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
    result := Tfile.createTemp(self.mainTree, resource+'\'+sr.name, self); // temporary nodes are bound to the parent's node
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

procedure Tfile.recursiveApply(callback:TfileCallback; par: IntPtr=0; par2: IntPtr=0);
var
  f, fNext: TFile;
  r: TfileCallbackReturn;
begin
  r := callback(self, FALSE, par, par2);
  if FCB_DELETE in r then
    begin
      if Assigned(node) then
        node.delete();
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
        if Assigned(node) then
          node.delete();
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

function nodeIsLocked(n: TFileNode): boolean;
begin
  result := FALSE;
  if (n = NIL) or (n.data = NIL) then
    exit;
  result := nodeToFile(n).isLocked();
end; // nodeIsLocked



function loadMD5for(const fn: String): String;
begin
  if getMtimeUTC(fn+'.md5') < getMtimeUTC(fn) then
    result := ''
   else
    result := trim(getTill(' ', UnUTF(loadfile(fn+'.md5'))))
end; // loadMD5for

function loadFingerprint(const fn:string):string;
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

end.
