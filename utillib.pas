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

unit utilLib;
{$I NoRTTI.inc}

interface

uses
  types, Windows,
  Graphics,
  Forms,
  dialogs, menus, stdctrls, controls,
  ComCtrls,
  registry, classes, dateUtils,
 {$IFNDEF FPC}
  psAPI, richedit,
 {$ENDIF ~FPC}
  math, sysutils, strutils,
  longinputDlg,
  hsUtils, srvClassesLib, fileLib, netUtils,
  hfsGlobal, srvConst, serverLib;

type
  TnameExistsFun = function(const user: String): Boolean;
  TnameExistsFunO = function(const user: String): Boolean of object;
type
  TWinVersion = (WV_LOWER, WV_2000, WV_VISTA, WV_SEVEN, WV_HIGHER);
var
  inputQueryLongdlg: TlonginputFrm;
  winVersion: TWinVersion;

procedure doNothing(); inline; // useful for readability
procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = false);
function httpsCanWork(onlyCheck: Boolean = false): Boolean; OverLoad;
function httpsCanWork(): Boolean; OverLoad;
procedure fixFontFor(frm:Tform);
{$IFNDEF FPC}
function allocatedMemory():int64;
{$IFDEF MSWINDOWS}
function currentStackUsage: NativeUInt;
{$ENDIF MSWINDOWS}
{$ENDIF ~FPC}
procedure onlyForExperts(p_easymode: Boolean; controls: array of Tcontrol);
function createAccountOnTheFly():Paccount;
function newMenuSeparator(lbl:string=''):Tmenuitem;
function accountIcon(isEnabled, isGroup:boolean):integer; overload;
function accountIcon(a:Paccount):integer; overload;
function boolOnce(var b:boolean):boolean;
procedure drawCentered(cnv: Tcanvas; r: Trect; const text: String);
function isLocalIP(const ip:string):boolean;
function clearAndReturn(var v:string):string;
function pid2file(pid: cardinal):string;
function port2pid(const port:string):integer;
function holdingKey(key:integer):boolean;
function blend(from,to_:Tcolor; perc:real):Tcolor;
function isNT():boolean;
function setClip(const s: String): Boolean;
function eos(s:Tstream):boolean;
function httpGetFileWithCheck(const url, filename: string; tryTimes: integer=1; notify: TProgressFunc =NIL): Boolean;
function getPossibleAddresses(): TUnicodeStringDynArray;
function whatStatusPanel(statusbar: Tstatusbar; x: Integer): Integer;
function getExternalAddress(var res: String; provider: PString=NIL; doLog: Boolean = false): Boolean;
function inputQueryLong(const caption, msg:string; var value:string; ofs:integer=0):boolean;
function exec(cmd: UnicodeString; pars: UnicodeString=''; showCmd:integer=SW_SHOW):boolean;
function execNew(const cmd:string):boolean;
function openURL(const url: string):boolean;
function msgDlg(msg:string; code:integer=0; title:string=''):integer;
// file
function getDrive(fn:string):string;
function getTempDir():string;
function createShellLink(const linkFN: UnicodeString; const destFN: UnicodeString): Boolean;
function existsShellLink(linkFN: WideString): Boolean;
function readShellLink(linkFN: WideString): String;
function getShellFolder(const id: String): String;
function getTempFilename():string;
function saveTempFile(const data: UnicodeString): String;
function sizeOfFile(fn:string):int64; overload;
function sizeOfFile(fh:Thandle):int64; overload;
//function loadFile(fn:string; from:int64=0; size:int64=-1):ansistring;  // Use RDFileUtil instead!
//function saveFile(var f:file; data:string):boolean; overload;    // Use RDFileUtil instead!
function getFilename(var f: File): String;
function filenameToDriveByte(fn:string):byte;
function selectFile(var fn: UnicodeString; const title: UnicodeString=''; const filter: UnicodeString=''; options:TOpenOptions=[]): Boolean;
function selectFiles(caption: UnicodeString; var files: TUnicodeStringDynArray): Boolean;
function selectFolder(const caption: UnicodeString; var folder: UnicodeString): Boolean;
function selectFileOrFolder(caption: UnicodeString; var fileOrFolder: UnicodeString): Boolean;
// registry
function loadregistry(const key, value: String; root: HKEY=0): string;
function saveregistry(const key, value, data: string; root: HKEY=0): boolean;
function deleteRegistry(const key, value: string; root: HKEY=0): boolean; overload;
function deleteRegistry(key: String; root:HKEY=0): boolean; overload;
// convert
function rectToStr(r:Trect):string;
function strToRect(s:string):Trect;
function strToUInt(s:string): UInt;
// misc string
function getUniqueName(const start:string; exists:TnameExistsFun):string; OverLoad;
function getUniqueName(const start:string; exists:TnameExistsFunO):string; OverLoad;
function popTLV(var s,data: RawByteString): integer;
//function optUTF8(bool:boolean; s:string):string; overload;
//function optUTF8(tpl:Ttpl; s:string):string; overload;
function optAnsi(bool: Boolean; const s: RawByteString): String;
function utf8Test(const s: String): Boolean; OverLoad;
function utf8Test(const s: RawByteString): boolean; OverLoad;
function trim2(const s: String; chars: TcharsetW): String;
implementation

uses
  clipbrd, CommCtrl,
  RnQDialogs,
  main, newuserpassDlg,
  shlobj, shellapi, activex, comobj,
//  AnsiClasses,
 {$IFNDEF FPC}
  ansiStrings,
  CommDlg, //System.Hash,
  hfsJclOthers,
 {$ENDIF ~FPC}
  {$IFDEF HAS_FASTMM}
  fastmm4,
  {$ENDIF HAS_FASTMM}
  RDUtils, RDFileUtil,
  srvUtils, srvVars,
  hfsVars, parserLib, scriptLib;

function NtfsFileHasReparsePoint(const Path: string): Boolean;
var
  Attr: DWORD;
begin
  Result := False;
  Attr := GetFileAttributes(PChar(Path));
  if Attr <> DWORD(-1) then
    Result := (Attr and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
end;

{$IFNDEF FPC}
// this is a fixed version of the one contained in JclNTFS.pas
function NtfsGetJunctionPointDestination(const Source: string; var Destination: widestring): Boolean;
var
  Handle: THandle;
  ReparseData: record
    case Boolean of
      False: (Reparse: TReparseDataBuffer;);
      True: (Buffer: array [0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE] of Char;);
    end;
  BytesReturned: DWORD;
begin
  Result := False;
  if not NtfsFileHasReparsePoint(Source) then
    exit;
  handle := CreateFile(PChar(Source), GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
  if handle = INVALID_HANDLE_VALUE then exit;
  try
    BytesReturned := 0;
    if not DeviceIoControl(Handle, FSCTL_GET_REPARSE_POINT, nil, 0, @ReparseData, MAXIMUM_REPARSE_DATA_BUFFER_SIZE, BytesReturned, nil) then
      exit;
    if BytesReturned < DWORD(ReparseData.Reparse.SymbolicLinkReparseBuffer.SubstituteNameLength + SizeOf(WideChar)) then
      exit;
    SetLength(Destination, (ReparseData.Reparse.SymbolicLinkReparseBuffer.SubstituteNameLength div SizeOf(WideChar)));
    Move(ReparseData.Reparse.SymbolicLinkReparseBuffer.PathBuffer[0], Destination[1], ReparseData.Reparse.SymbolicLinkReparseBuffer.SubstituteNameLength);
    Result := True;
   finally
    CloseHandle(Handle)
  end
end; // NtfsGetJunctionPointDestination
{$ENDIF ~FPC}

function getDrive(fn:string):string;
var
  i: integer;
 {$IFDEF FPC}
  us: UnicodeString;
 {$ELSE FPC}
  ws: widestring;
 {$ENDIF FPC}
begin
  result:=fn;
  repeat
    fn := hasJunction(result);
    if fn = '' then
      break;
 {$IFDEF FPC}
    if not FileGetSymLinkTarget(fn, us) then
       break;
    result := us;
 {$ELSE ~FPC}
    if not NtfsGetJunctionPointDestination(fn, ws) then
      break; // at worst we hope the drive is the same
    result := WideCharToString(@ws[1]);
 {$ENDIF FPC}
    // sometimes we get a unicode result
    i:=length(result);
    if (i > 3) and (result[2] = #0) then
     begin
      break;
      result:=wideCharToString(@result[1]);
      setLength(result, i-1);
     end;
    // remove some trailing null chars
    result:=trim(result);
    // we don't like this form, remove useless chars
    if reMatch(result, '^\\\?\?\\.:', '!') > 0 then
      delete(result, 1,4);
  until false;
result:=extractFileDrive(result);
end; // getDrive

function strToUInt(s: String): UInt;
begin
  s := trim(s);
  if s='' then
    result := 0
   else
    result := SysUtils.StrToUInt(s);
  if result < 0 then
    raise Exception.Create('strToUInt: Signed value not accepted');
end; // strToUInt


function rectToStr(r: TRect): String;
begin result:=format('%d,%d,%d,%d',[r.left,r.top,r.right,r.bottom]) end;

function strToRect(s: String): Trect;
begin
result.Left:=strToInt(chop(',',s));
result.Top:=strToInt(chop(',',s));
result.right:=strToInt(chop(',',s));
result.bottom:=strToInt(chop(',',s));
end; // strToRect

// for heavy jobs you are supposed to use class Ttlv
function popTLV(var s,data: RawByteString): Integer;
begin
result:=-1;
if length(s) < 8 then exit;
result:=integer((@s[1])^);
data:=copy(s,9,Pinteger(@s[5])^);
delete(s,1,8+length(data));
end; // popTLV

function msgDlg(msg:string; code:integer=0; title:string=''):integer;
var
  parent: Thandle;
begin
  result := 0;
  if msg='' then
    exit;
  if code = 0 then
    code := MB_OK+MB_ICONINFORMATION;
  if screen.ActiveCustomForm = NIL then
    parent := 0
   else
    parent := screen.ActiveCustomForm.handle;
  application.restore();
  application.BringToFront();
  title := application.Title+nonEmptyConcat(' -- ', title);
  result := messageBox(parent, pchar(msg), pchar(title), code)
end; // msgDlg

{
function loadFile(fn:string; from:int64=0; size:int64=-1):ansistring;
var
  f:file;
  bak: byte;
begin
result:='';
IOresult;
if not validFilepath(fn) then exit;
if not isAbsolutePath(fn) then chDir(exePath);
assignFile(f, fn);
bak:=fileMode;
fileMode:=0;
try
  reset(f,1);
  if IOresult <> 0 then exit;
  seek(f, from);
  if size < 0 then
    size:=filesize(f)-from;
  setLength(result, size);
  blockRead(f, result[1], size);
  closeFile(f);
finally
  filemode:=bak;
  end;
end; // loadFile
}

function getTempFilename():string;
var
  path: string;
begin
  setLength(path, 1000);
  setLength(path, getTempPath(length(path), @path[1]));
  setLength(result, 1000);
  if Windows.getTempFileName(pchar(path), 'hfs.', 0, @result[1]) = 0 then
    result := ''
   else
    setLength(result, StrLen(PChar(@result[1])));
end; // getTempFilename

function saveTempFile(const data: UnicodeString): String;
begin
  result := getTempFilename();
  if result > '' then
    saveFile2(result, StrToUTF8(data));
end; // saveTempFile

function loadregistry(const key, value: String; root: HKEY=0): string;
begin
result:='';
with Tregistry.create do
  try
    try
      if root > 0 then rootKey:=root;
      if openKey(key, FALSE) then
        begin
        result:=readString(value);
        closeKey();
        end;
    finally free end
  except end
  end; // loadregistry

function saveregistry(const key,value,data:string; root:HKEY=0):boolean;
begin
result:=FALSE;
with Tregistry.create do
  try
    if root > 0 then rootKey:=root;
    try
      createKey(key);
      if openKey(key, FALSE) then
        begin
        WriteString(value,data);
        closeKey;
        result:=TRUE;
        end;
    finally free end
  except end;
end; // saveregistry

function deleteRegistry(const key,value:string; root:HKEY=0):boolean; overload;
var
  reg:Tregistry;
begin
reg:=Tregistry.create;
if root > 0 then reg.RootKey:=root;
result:=reg.OpenKey(key,FALSE) and reg.DeleteValue(value);
reg.free
end; // deleteRegistry

function deleteRegistry(key: String; root: HKEY=0): boolean; overload;
var
  reg:Tregistry;
  ss:TstringList;
  i:integer;
  deleteIt:boolean;
begin
reg:=Tregistry.create;
if root > 0 then reg.RootKey:=root;
result:=reg.DeleteKey(key);
// delete also parent keys, if empty
ss:=Tstringlist.create;
while key>'' do
  begin
  i:=LastDelimiter('\',key);
  if i=0 then break;
  setlength(key, i-1);
  if not reg.OpenKeyReadOnly(key) then break;
  reg.GetValueNames(ss);
  deleteIt:=(ss.count=0) and not reg.HasSubKeys;
  reg.CloseKey;
  if deleteit then reg.deleteKey(key)
  else break;
  end;
ss.free;
reg.free
end; // deleteRegistry

function exec(cmd: UnicodeString; pars: UnicodeString=''; showCmd: Integer=SW_SHOW): Boolean;
const
  MAX_PARS = 9;
var
  pars0: string;
  i, o: integer;
  poss: array [1..MAX_PARS] of TintegerDynArray; // positions where we found the Nth parameter, in the %N form, for later substitution
  a: TintegerDynArray;
  parsA: TStringDynArray; // splitted version of pars
begin
  result:=FALSE;
  cmd:=trim(cmd);
  if (cmd = '') or (dequote(cmd) = '') then exit;

  i := nonQuotedPos(' ', cmd);
  if (cmd > '') and (cmd[1] <> '"') and (extractFileExt(cmd) > '') and (extractFileExt(substr(cmd, 0, i)) = '') then
    pars0:=''
   else
    begin
      // the cmd sometimes contains parameters, because loaded from registry
      pars0:=cmd;
      // split such parameters from the real cmd
      cmd := chop(i, pars0);
      // if pars0 contains %1, it must be replaced with the first parameter contained 'pars'.
      // Sadly we can't just replace, because 'pars' may contain %DIGIT strings (that must not be replaced). So we collect positions first, then make substitutions.
      for i:=1 to MAX_PARS do
        begin
        a:=NIL;
        o:=0;
          repeat
          o:=posEx('%'+intToStr(i), pars0, o+1);
          if o = 0 then break;
          setLength(a, length(a)+1);
          a[length(a)-1]:=o;
          until false;
        poss[i]:=a;
        end;

      parsA:=split(' ', pars, TRUE);
      // now do all the collected replacements
      for i:=1 to MAX_PARS do
        begin
        for o:=0 to length(poss[i])-1 do
          replace(pars0, parsA[i-1], poss[i][o], 1+poss[i][o]);
        if length(poss[i]) > 0 then
          removeString(parsA, i-1);
        end;
      // ok, now we have the final version of parameters
      pars := pars0+nonEmptyConcat(' ', join(' ',parsA));
    end;
  // go
  result := (cmd > '') and (32 < shellexecuteW(0, 'open', PWideChar(cmd), PWideChar(pars), NIL, showCmd))
end;

// exec but does not wait for the process to end
function execNew(const cmd: String): Boolean;
begin
  result:=32 < ShellExecute(0, nil, 'cmd.exe', pchar('/C '+cmd), nil, SW_SHOW);
end; // execNew

function execNew2(const cmd: String): Boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
begin
  ZeroMemory(@si, sizeOf(si));
  ZeroMemory(@pi, sizeOf(pi));
  si.cb:=sizeOf(si);
  result:=createProcess(NIL,pchar(cmd),NIL,NIL,FALSE,0,NIL,NIL,si,pi)
end; // execNew

function sizeOfFile(fh:Thandle):int64; overload;
var
  h, l: dword;
begin
l:=getFileSize(fh, @h);
if (l = $FFFFFFFF) and (getLastError() <> NO_ERROR) then result:=-1
else result:=l+int64(h) shl 32;
end; // sizeOfFile

function sizeOfFile(fn:string):int64; overload;
var
  h: Thandle;
begin
  if ansiStartsText('http://', fn) then
    begin
      result := httpFilesize(fn);
      exit;
    end;
  if ansiContainsStr(fn, '/') then
    fn := mainFrm.fileSrv.uri2disk(fn);
  h := fileopen(fn, fmOpenRead+fmShareDenyNone);
  result := sizeOfFile(h);
  fileClose(h);
end; // sizeOfFile

function min(a,b:integer):integer; inline;
begin if a>b then result:=b else result:=a end;

function inputQueryLong(const caption, msg:string; var value:string; ofs:integer=0):boolean;
begin
  inputQueryLongdlg.Caption := caption;
  inputQueryLongdlg.msgLbl.Caption
     := '  '+xtpl(msg, [#13,#13'  '] );
  inputQueryLongdlg.inputBox.Text:=value;
  inputQueryLongdlg.inputBox.SelStart:=ofs;
  // i want focus on the editor, but setFocus works only on visible windows -_-' any better idea?
  inputQueryLongdlg.show();
  inputQueryLongdlg.inputBox.SetFocus();
  inputQueryLongdlg.hide();
  result:=inputQueryLongdlg.ShowModal() = mrOk;
  if result then
    value := inputQueryLongdlg.inputBox.Text;
end; // inputQueryLong

function httpsCanWork(onlyCheck: Boolean = false): Boolean;
 {$IFDEF USE_SSL}
 resourcestring
   MSG_NO_DLL = 'An HTTPS action is required but some files are missing. Download them?';
   MSG_DNL_OK = 'Download completed';
   MSG_DNL_FAIL = 'Download failed';

var
  missing: TStringDynArray;
 {$ENDIF ~USE_SSL}
begin
 {$IFDEF USE_SSL}
  if checkHTTPSCanWork(missing) then
    exit(TRUE);
  if onlyCheck or (msgDlg(MSG_NO_DLL, MB_OKCANCEL+MB_ICONQUESTION) <> MROK) then
    exit(FALSE);
  for var s in missing do
    if not httpGetFileWithCheck(LIBS_DOWNLOAD_URL + s, s, 2, mainfrm.statusBarHttpProgress) then
      begin
      msgDlg(MSG_DNL_FAIL, MB_ICONERROR);
      exit(FALSE);
      end;
  mainfrm.setStatusBarText(MSG_DNL_OK);
  result := TRUE;
 {$ELSE ~USE_SSL}
  result := FALSE;
 {$ENDIF USE_SSL}
end; // httpsCanWork

function httpsCanWork(): Boolean;
begin
  Result := httpsCanWork(false);
end;

function getExternalAddress(var res: String; provider: PString=NIL; doLog: Boolean = false): Boolean;
begin
  if doLog then
    result := netUtils.getExternalAddress(res, provider, add2Log)
   else
    result := netUtils.getExternalAddress(res, provider);
end; // getExternalAddress

function httpGetFileWithCheck(const url, filename: string; tryTimes: integer=1; notify: netUtils.TProgressFunc =NIL): Boolean;
var
  errMsg: String;
begin
  Result := netUtils.httpGetFileWithCheck(url, filename, errMsg, notify);

  if not Result then
    begin
      if errMsg > '' then
        add2log(errMsg);
      while not Result and (tryTimes > 1) do
       begin
        Result := netUtils.httpGetFileWithCheck(url, filename, errMsg, notify);
        if not Result and (errMsg > '') then
          begin
            if errMsg > '' then
              add2log(errMsg);
            dec(tryTimes);
          end;
       end;
    end;
end;

function whatStatusPanel(statusbar: Tstatusbar; x: integer): integer;
var
  x1: integer;
begin
  result := 0;
  x1 := statusbar.panels[0].width;
  while (x > x1) and (result < statusbar.Panels.Count-1) do
   begin
    inc(result);
    inc(x1, statusbar.panels[result].width);
   end;
end; // whatStatusPanel

function getPossibleAddresses(): TUnicodeStringDynArray;
begin // next best
  result := toSA([defaultIP, dyndns.host]);
  addArray(result, customIPs);
  addString(externalIP, result);
  addArray(result, getIPs());
  removeStrings('', result);
  uniqueStrings(result);
end; // getPossibleAddresses

function getFilename(var f:file):string;
begin result:=pchar(@f)+72 end;

function filenameToDriveByte(fn:string):byte;
begin
  if (length(fn) < 2) or (fn[2] <> ':') then
    fn := exePath; // relative paths are actually based on the same drive of the executable
  fn := getDrive(fn);
  if fn = '' then
    result := 0
  else
    result := ord(upcase(fn[1]))-ord('A')+1;
end; // filenameToDriveByte

function cbSelectFolder(wnd:HWND; uMsg:UINT; lp,lpData:LPARAM):LRESULT; stdcall;
begin
  result:=0;
  if (uMsg <> BFFM_INITIALIZED) or (lpdata = 0) then
    exit;
  SendMessage(wnd, BFFM_SETSELECTION, 1, LPARAM(pchar(lpdata)));
  SendMessage(wnd, BFFM_ENABLEOK, 0, 1);
end; // cbSelectFolder

function selectWrapper(caption: UnicodeString; var from: UnicodeString; flags:dword=0): Boolean;
const
  BIF_NEWDIALOGSTYLE = $40;
  BIF_UAHINT = $100;
  BIF_SHAREABLE = $8000;
var
  bi: TBrowseInfoW;
  res: PItemIDList;
  buff: array [0..MAX_PATH] of WideChar;
  im: iMalloc;
begin
  result:=FALSE;
  if SHGetMalloc(im) <> 0 then exit;
  bi.hwndOwner:=GetActiveWindow();
  bi.pidlRoot:=NIL;
  bi.pszDisplayName:=@buff;
  bi.lpszTitle := PWideChar(caption);
  bi.ulFlags:=BIF_RETURNONLYFSDIRS+BIF_NEWDIALOGSTYLE+BIF_SHAREABLE+BIF_UAHINT+BIF_EDITBOX+flags;
  bi.lpfn:=@cbSelectFolder;
  if from > '' then
    bi.lParam:= INT_PTR(@from[1]);
  bi.iImage:=0;
  res := SHBrowseForFolderW(bi);
  if res = NIL then
    exit;
  if not SHGetPathFromIDListW(res, buff) then
    exit;
  im.Free(res);
  from:=buff;
  result:=TRUE;
end; // selectWrapper

function selectFolder(const caption: UnicodeString; var folder: UnicodeString): Boolean;
begin result:=selectWrapper(caption, folder) end;

// works only on XP
function selectFileOrFolder(caption: UnicodeString; var fileOrFolder: UnicodeString): Boolean;
begin result:=selectWrapper(caption, fileOrFolder, BIF_BROWSEINCLUDEFILES) end;

function selectFile(var fn: UnicodeString; const title, filter: UnicodeString; options: TOpenOptions): boolean;
const
  OpenOptions: array [TOpenOption] of DWORD = (
    OFN_READONLY, OFN_OVERWRITEPROMPT, OFN_HIDEREADONLY,
    OFN_NOCHANGEDIR, OFN_SHOWHELP, OFN_NOVALIDATE, OFN_ALLOWMULTISELECT,
    OFN_EXTENSIONDIFFERENT, OFN_PATHMUSTEXIST, OFN_FILEMUSTEXIST,
    OFN_CREATEPROMPT, OFN_SHAREAWARE, OFN_NOREADONLYRETURN,
    OFN_NOTESTFILECREATE, OFN_NONETWORKBUTTON, OFN_NOLONGNAMES,
    OFN_EXPLORER, OFN_NODEREFERENCELINKS,
   {$IFDEF FPC}
    0,
   {$ENDIF FPC}
    OFN_ENABLEINCLUDENOTIFY,
    OFN_ENABLESIZING, OFN_DONTADDTORECENT, OFN_FORCESHOWHIDDEN
    {$IFDEF FPC}
     , 0, 0
    {$ENDIF FPC}
    );
var
//  dlg: TopenDialog;
  hndl: THandle;
  initDir: String;
  Option: TOpenOption;
  Flags: Cardinal;
begin
  result := FALSE;
//  dlg:=TopenDialog.create(screen.activeForm);
  if Assigned(screen.activeForm) then
    hndl := screen.activeForm.Handle
   else
    hndl := 0;
  initDir := exePath;
  if fn > '' then
  begin
    if isAbsolutePath(fn) then
      initDir := ExtractFilePath(fn)
  end;
  flags := 0;
  for Option := Low(Option) to High(Option) do
    if Option in options then
      Flags := Flags or OpenOptions[Option];
  Result := OpenSaveFileDialog(hndl, '', filter, initDir, title, fn, True, false, flags)
end; // selectFile

function getShellFolder(const id: String): String;
begin
result:=loadregistry(
  'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', id,
  HKEY_CURRENT_USER);
end; // getShellFolder

function createShellLink(const linkFN: UnicodeString; const destFN: UnicodeString): Boolean;
var
  ShellObject: IUnknown;
begin
  shellObject := CreateComObject(CLSID_ShellLink);
  result := ((shellObject as IShellLinkW).setPath(PWideChar(destFN)) = NOERROR)
    and ((shellObject as IPersistFile).Save(PWideChar(linkFN), False) = S_OK)
end; // createShellLink

function existsShellLink(linkFN: WideString): Boolean;
var
  ShellObject: IUnknown;
begin
  shellObject := CreateComObject(CLSID_ShellLink);
  if (shellObject as IPersistFile).Load(PWChar(linkFN), 0) <> S_OK then
    Exit(False);
  Result := True;
end; // existsShellLink

function readShellLink(linkFN: WideString): String;
var
  ShellObject: IUnknown;
  pfd: _WIN32_FIND_DATAW;
 {$IFNDEF UNICODE}
  r: WideString;
 {$ENDIF UNICODE}
begin
  shellObject := CreateComObject(CLSID_ShellLink);
  if (shellObject as IPersistFile).Load(PWChar(linkFN), 0) <> S_OK then
    raise Exception.create('readShellLink: cannot load');
 {$IFNDEF UNICODE}
  setLength(r, MAX_PATH);
  if (shellObject as IShellLinkW).getPath(@r[1], length(result), @pfd, 0) <> NOERROR then
 {$ELSE UNICODE}
  setLength(result, MAX_PATH);
  if (shellObject as IShellLinkW).getPath(@result[1], length(result), pfd, 0) <> NOERROR then
 {$ENDIF UNICODE}
    raise Exception.create('readShellLink: cannot getPath');
 {$IFNDEF UNICODE}
  setLength(r, strLen(PWideChar(@r[1])));
  result := r;
 {$ELSE UNICODE}
  setLength(result, strLen(PChar(@result[1])));
 {$ENDIF UNICODE}
end; // readShellLink

function selectFiles(caption: UnicodeString; var files: TUnicodeStringDynArray): Boolean;
var
  dlg: TopenDialog;
  i: integer;
begin
dlg:=TopenDialog.create(screen.activeForm);
try
  dlg.Options:=dlg.Options+[TOpenOption.ofAllowMultiSelect, TOpenOption.ofFileMustExist, TOpenOption.ofPathMustExist];
  result:=dlg.Execute();
  if result then
    begin
    setLength(files, dlg.Files.count);
    for i:=0 to dlg.files.Count-1 do
      files[i]:=dlg.files[i];
    end;
finally dlg.free end;
end;

function eos(s: TStream): Boolean;
begin
  result := s.position >= s.size
end;

function setClip(const s: String): Boolean;
begin
  result := TRUE;
  try
    clipboard().AsText := s
   except
    result:=FALSE
  end;
end; // setClip

function isNT():boolean;
var
  vi: TOSVERSIONINFO;
begin
  result := TRUE;
  vi.dwOSVersionInfoSize := sizeOf(vi);
  if not windows.getVersionEx(vi) then
    exit;
  result := vi.dwPlatformId = VER_PLATFORM_WIN32_NT;
end; // isNT

function getTempDir():string;
begin
setLength(result, 1000);
setLength(result, getTempPath(length(result), @result[1]));
end; // getTempDir
{
function optUTF8(bool:boolean; s: AnsiString): RawByteString;
begin
 if bool then
   result:=ansiToUtf8(s)
  else
   result:=s
end;

function optUTF8(bool:boolean; s:string): RawByteString;
begin
 if bool then
   result:=ansiToUtf8(s)
  else
   result:=s
end;

function optUTF8(tpl:Ttpl; s:string):string; inline;
begin result:=optUTF8(assigned(tpl) and tpl.utf8, s) end;
}

function optAnsi(bool: Boolean; const s: RawByteString): String;
begin
  if bool then
    result := UTF8toAnsi(s)
   else
    result := s
end;

function blend(from,to_:Tcolor; perc:real):Tcolor;
var
  i: integer;
begin
  result := 0;
  from := ColorToRGB(from);
  to_ := ColorToRGB(to_);
  for i:=0 to 2 do
    inc(result, min($FF, round(((from shr (i*8)) and $FF)*(1-perc)
      +((to_ shr (i*8)) and $FF)*perc)) shl (i*8));
end; // blend

function holdingKey(key:integer):boolean;
begin result:=getAsyncKeyState(key) and $8000 <> 0 end;

function utf8Test(const s: String):boolean;
begin result := ansiContainsText(s, 'charset=UTF-8') end;

function utf8Test(const s: RawByteString): boolean;
begin result := ansiContainsText(s, RawByteString('charset=UTF-8')) end;

function port2pid(const port:string):integer;
var
  s, l, p: string;
  code: cardinal;
begin
result:=-1;
if not captureExec('netstat -naop tcp', s, code) then
  exit;
  
while s > '' do
  begin
  l:=chopline(s);
  if pos('LISTENING', l) = 0 then continue;
  chop(':', l);
  p:=chop(' ',l);
  if p <> port then continue;
  chop('LISTENING', l);
  result:=strToIntDef(trim(l), -1);
  exit;
  end;
end; // port2pid

function pid2file(pid: cardinal):string;
var
  h: Thandle;
begin
  result:='';
  // this is likely to fail on Vista if we are querying a service, because we are running with less privs
  h:=openProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pid);
  if h = 0 then exit;
  try
    setLength(result, MAX_PATH);
   {$IFDEF FPC}
    if GetModuleFileName(h, pchar(Result), MAX_PATH) > 0 then
   {$ELSE ~FPC}
    if getModuleFileNameEx(h, 0, pchar(Result), MAX_PATH) > 0 then
   {$ENDIF FPC}
      setLength(result, strLen(pchar(result)))
     else
      result:=''
   finally
    closeHandle(h)
  end;
end; // pid2file

function openURL(const url:string):boolean;
begin
result:=exec(url);
end; // openURL

function clearAndReturn(var v:string):string;
begin
result:=v;
v:='';
end;

procedure drawCentered(cnv: Tcanvas; r: Trect; const text: String);
begin
  drawText(cnv.Handle, pchar(text), length(text), r, DT_CENTER+DT_NOPREFIX+DT_VCENTER+DT_END_ELLIPSIS)
end;

function isLocalIP(const ip:string):boolean;
begin result:=checkAddressSyntax(ip, FALSE) and hsUtils.isLocalIP(ip) end;

function trim2(const s:string; chars:TcharsetW):string;
var
  b, e: integer;
begin
b:=1;
while (b <= length(s)) and (s[b] in chars) do inc(b);
e:=length(s);
while (e > 0) and (s[e] in chars) do dec(e);
result:=substr(s, b, e);
end; // trim2

function boolOnce(var b:boolean):boolean;
begin result:=b; b:=FALSE end;

procedure doNothing();
begin end;

procedure add2Log(lines: String; cd: TconnDataMain=NIL; clr: Tcolor= Graphics.clDefault; doSync: Boolean = false);
begin
  if not doSync then
    mainFrm.add2log(lines, cd, clr)
   else
    mainFrm.add2log(lines, cd, clr);
end;

function getUniqueName(const start:string; exists:TnameExistsFun): String;
var
  i: integer;
begin
  result := start;
  if not exists(result) then
    exit;
  i:=2;
  repeat
    result := format('%s (%d)', [start,i]);
    inc(i);
  until not exists(result);
end; // getUniqueName

function getUniqueName(const start:string; exists:TnameExistsFunO): String;
var
  i: integer;
begin
  result := start;
  if not exists(result) then
    exit;
  i:=2;
  repeat
    result := format('%s (%d)', [start,i]);
    inc(i);
  until not exists(result);
end; // getUniqueName

function accountIcon(isEnabled, isGroup:boolean):integer; overload;
begin result:=if_(isGroup, if_(isEnabled,29,40), if_(isEnabled,27,28)) end;

function accountIcon(a:Paccount):integer; overload;
begin result:=accountIcon(a.enabled, a.group) end;

function newMenuSeparator(lbl: string=''): Tmenuitem;
begin
  result := newItem('-',0,FALSE,TRUE,NIL,0,'');
  result.hint := lbl;
  result.onDrawItem := mainfrm.menuDraw;
  result.OnMeasureItem := mainfrm.menuMeasure;
end; // newMenuSeparator

function createAccountOnTheFly(): Paccount;
var
  acc: Taccount;
  i: integer;
begin
  result := NIL;
  ZeroMemory(@acc, sizeOf(acc));
  acc.enabled := TRUE;
  repeat
    if not newuserpassFrm.prompt(acc.user, acc.pwd)
      or (acc.user = '') then exit;

    if getAccount(acc.user) = NIL then
      break;
    msgDlg('Username already exists', MB_ICONERROR)
  until false;
  i := length(accounts);
  setLength(accounts, i+1);
  accounts[i] := acc;
  result := @accounts[i];
end; // createAccountOnTheFly

procedure onlyForExperts(p_easymode: Boolean; controls: array of Tcontrol);
var
  i: integer;
begin
  for i:=0 to length(controls)-1 do
    controls[i].visible:=not p_easymode;
end; // onlyForExperts

{$IFNDEF FPC}
{$IFNDEF HAS_FASTMM}
// this is to be used with the standard memory manager, while we are currently using a different one
function allocatedMemory():int64;
var
  mms: TMemoryManagerState;
  i: integer;
begin
  getMemoryManagerState(mms);
  result:=0;
  for i:=0 to high(mms.SmallBlockTypeStates)-1 do
    with mms.SmallBlockTypeStates[i] do
      //inc(result, ReservedAddressSpace);   i guess this is real consumption from a system PoV, but it's actually preallocated, not fully used
      inc(result, internalBlockSize*allocatedBlockCount);
  inc(result, mms.TotalAllocatedLargeBlockSize+mms.TotalAllocatedMediumBlockSize);
end; // allocatedMemory

{$ELSE HAS_FASTMM}

function allocatedMemory():int64;
var
  mm: TMemoryManagerUsageSummary;
begin
  getMemoryManagerUsageSummary(mm);
  result := mm.allocatedBytes;
end; // allocatedMemory
{$ENDIF HAS_FASTMM}

{$IFDEF MSWINDOWS}
function currentStackUsage: NativeUInt;
//NB: Win32 uses FS, Win64 uses GS as base for Thread Information Block.
asm
  {$IFDEF WIN32}
  mov eax, fs:[4]  // TIB: base of the stack
  sub eax, esp     // compute difference in EAX (=Result)
  {$ENDIF}
  {$IFDEF WIN64}
  mov rax, gs:[8]  // TIB: base of the stack
  sub rax, rsp     // compute difference in RAX (=Result)
  {$ENDIF}
{$ENDIF}
end;
{$ENDIF ~FPC}

procedure fixFontFor(frm:Tform);
var
  nonClientMetrics: TNonClientMetrics;
begin
  nonClientMetrics.cbSize := sizeOf(nonClientMetrics);
  systemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, @nonClientMetrics, 0);
  frm.font.handle := createFontIndirect(nonClientMetrics.lfMessageFont);
  if frm.scaled then
    frm.font.height:=nonClientMetrics.lfMessageFont.lfHeight;
end; // fixFontFor

function promptForFileName(var fileName: String): boolean;
var
  d: TOpenDialog;
begin
  d := TOpenDialog.Create(Application.MainForm);
  d.Title := 'Select file';
  d.FileName := fileName;
  Result := d.Execute;
  if Result then
   begin
     fileName := d.FileName;
   end;
  d.Free;
//  Result := True;
end;


function detectWinVersion: TWinVersion;
var
  v: Cardinal;
begin
  Result := WV_LOWER;
  v := getversion();
  case byte(v) of
    1..4: Result := WV_LOWER;
    5: Result := WV_2000;
    6: case hibyte(HiWord(v)) of
        0: Result := WV_VISTA;
        1: Result := WV_SEVEN;
        else Result := WV_HIGHER;
        end;
    7..255: Result := WV_HIGHER;
  end;
end;

INITIALIZATION
//  sysutils.DecimalSeparator:='.'; // standardize
  sysutils.FormatSettings.DecimalSeparator := '.'; // standardize

  inputQueryLongdlg := TlonginputFrm.create(NIL); // mainFrm is NIL at this time

// windows version detect
  winVersion := detectWinVersion;

  trayMsg:='%ip%'
  +trayNL+'Uptime: %uptime%'
  +trayNL+'Downloads: %downloads%';

//fastmm4.SuppressMessageBoxes:=TRUE;

FINALIZATION
  freeAndNIL(inputQueryLongdlg);
  freeAndNIL(onlyDotsRE);

end.
