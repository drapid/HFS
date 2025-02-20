{$INCLUDE defs.inc }
unit netUtils;
{$I NoRTTI.inc}

interface

uses
  Classes, Windows,
  OverbyteIcshttpProt,
 {$IFNDEF FPC}
  OverbyteIcsUtils,
  OverbyteIcsTypes,
 {$ENDIF FPC}
  Types,
  srvClassesLib;

type
  TProgressFunc = function(p: real): Boolean of object;

  function httpGetStr(const url: string; from: int64=0; size: int64=-1): string;
  function httpGet(const url:string; from:int64=0; size:int64=-1): RawByteString;
//  function httpGetFile1(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
//  function httpGetFileWithCheck1(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
  function httpGetFile(const url, filename: string; var errMsg: String; notify: TProgressFunc=NIL): Boolean;
  function httpGetFileWithCheck(const url, filename: string; var errMsg: String; notify: TProgressFunc=NIL): Boolean;

  function httpFileSize(const url: string): int64;
  function getIPs(): TStringDynArray;
  function getLocalIPs({$IFDEF USE_IPv6}const ASocketFamily: TSocketFamily = sfIPv4 {$ENDIF USE_IPv6}): TStringDynArray;
  function findRedirection(var h, p: String; const agent: String): Boolean;
  function checkHTTPSCanWork(var missing: TStringDynArray): Boolean; OverLoad;
  function checkHTTPSCanWork(): Boolean; OverLoad;
  function getExternalAddress(var res: String; provider: PString=NIL; doLogFunc: TAdd2LogEvent = NIL): Boolean;
// an ip address where we are listening
  function getIP(): String;

{$IFDEF USE_IPv6}
const
  sfIPv4 = TSocketFamily.sfIPv4;
  sfIPv6 = TSocketFamily.sfIPv6;
  sfAny  = TSocketFamily.sfAny;
{$ENDIF USE_IPv6}

type
  TBoolFunc = function(): Boolean;

 {$IFDEF USE_IPv6}
  ThttpClient = class(TSslHttpCli)
 {$ELSE not USE_IPv6}
  ThttpClient = class(THttpCli)
 {$ENDIF USE_IPv6}
   private
    fCanHTTPS: TBoolFunc;
    fAgent: String;
    fOnProgress: TProgressFunc;
    constructor Create(AOwner: TComponent); override;
    procedure onHttpGetUpdate(sender: TObject; buffer: Pointer; len: Integer);
   public
    destructor Destroy; OverRide;
    class function createURL(const url: String; canHTTPS: TBoolFunc): ThttpClient;
   end;
var
  autoDownloadLibs: TBoolFunc;

implementation

uses
  sysutils, StrUtils,
  RDUtils, RDFileUtil, RnQCrypt,
  OverbyteIcsWSocket,
 {$IFNDEF FPC}
 {$IFDEF USE_SSL}
  OverbyteIcsSslBase,
  OverbyteIcsSSLEAY,
 {$ENDIF USE_SSL}
 {$ENDIF ~FPC}
  srvConst, srvUtils, srvVars,
  HSUtils;

resourcestring
  unsignesErr = 'Signature is not valid';

function httpGetStr(const url: String; from:int64=0; size:int64=-1): String;
var
  reply: Tstringstream;
begin
  if size = 0 then
    exit('');
  reply := TStringStream.Create('');
  with ThttpClient.createURL(url, autoDownloadLibs) do
  try
    rcvdStream := reply;
    if (from <> 0) or (size > 0) then
      contentRangeBegin := intToStr(from);
    if size > 0 then
      contentRangeEnd := intToStr(from+size-1);
    get();
    result := reply.dataString;
    if sameText('utf-8', reGet(ContentType, '; *charset=(.+) *($|;)')) then
      Result:=UTF8ToString(result);
  finally
    reply.free;
    Free;
    end
end; // httpGetStr

function httpGet(const url: string; from: int64=0; size: int64=-1): RawByteString;
var
  fs: TMemoryStream;
  httpCli: ThttpClient;
begin
  if size = 0 then
  begin
    result:='';
    exit;
  end;

//  Result := LoadFromURLStr(url, from, size);
  fs := nil;
  Result := '';
  httpCli := ThttpClient.createURL(url, autoDownloadLibs);
  if Assigned(httpCli) then
    with httpCli do
      try
        fs := TMemoryStream.Create;
        rcvdStream := fs;
        if (from <> 0) or (size > 0) then
          contentRangeBegin := intToStr(from);
        if size > 0 then
          contentRangeEnd := intToStr(from+size-1);

          if size >= 0 then
          begin
            httpCli.Head;
            if httpCli.ContentLength < from then
              Exit;
          end;

        get();
        if fs.Size > 0 then
          begin
            SetLength(Result, fs.Size);
            fs.Seek(0, soFromBeginning);
            fs.Read(Result[1], Length(Result));
          end;
       finally
        fs.free;
        Free;
      end


end; // httpGet

function httpFileSize(const url: string): int64;
var
  httpCli: ThttpClient;
begin
  Result := -1;
  httpCli := ThttpClient.createURL(url, autoDownloadLibs);
  if Assigned(httpCli) then
with httpCli do
  try
    try
      head();
      result := contentLength
     except result:=-1
      end;
  finally free
    end;
end; // httpFileSize

function httpGetFile1(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
var
  httpCli: ThttpClient;
  supposed: int64;
  reply: Tfilestream;
begin
  supposed := 0;
  httpCli := ThttpClient.createURL(url, autoDownloadLibs);
  if Assigned(httpCli) then
  with httpCli do
    try
      reply := NIL;
      reply := TfileStream.Create(filename, fmCreate);
      rcvdStream := reply;
      onDocData := notify;
      result := TRUE;
      try
        get()
       except
        result := FALSE;
        errMsg := ReasonPhrase;
      end;
      supposed := ContentLength;
     finally
      if Assigned(reply) then
        reply.free;
      free;
    end;
  result := result and (sizeOfFile(filename)=supposed);
  if not result then
    deleteFile(filename);
end; // httpGetFile

function httpGetFile(const url, filename: string; var errMsg: String; notify: TProgressFunc=NIL): Boolean;
var
  httpCli: ThttpClient;
  supposed: int64;
  reply: Tfilestream;
begin
  supposed := 0;
  httpCli := ThttpClient.createURL(url, autoDownloadLibs);
  if Assigned(httpCli) then
  with httpCli do
    try
      reply := NIL;
      reply := TfileStream.Create(filename, fmCreate);
      rcvdStream := reply;
      fOnProgress := notify;
      onDocData := httpCli.onHttpGetUpdate;
      result := TRUE;
      try
        get()
       except
        result := FALSE;
        errMsg := ReasonPhrase;
      end;
      supposed := ContentLength;
     finally
      if Assigned(reply) then
        reply.free;
      free;
    end;
  result := result and (sizeOfFile(filename)=supposed);
  if not result then
    deleteFile(filename);
end; // httpGetFile

function httpGetRaw(const url: string; maxSize: Int64; var ResultRaw: RawByteString; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
var
  httpCli: ThttpClient;
  supposed: int64;
  reply: TMemoryStream;
begin
  supposed := 0;
  ResultRaw := '';
  httpCli := ThttpClient.createURL(url, autoDownloadLibs);
  if Assigned(httpCli) then
  with httpCli do
    try
      reply := TMemoryStream.Create;
      rcvdStream := reply;
      onDocData := notify;
      result := TRUE;
      try
        get()
       except
        result := FALSE;
        errMsg := ReasonPhrase;
      end;
      supposed := ContentLength;
      if result then
        begin
          SetLength(ResultRaw, reply.Size);
          if reply.Size > 0 then
            CopyMemory(@ResultRaw[1], reply.Memory, reply.Size);
        end;
     finally
      if Assigned(reply) then
        reply.free;
      free;
    end;
  result := result and (Length(ResultRaw)=supposed);
  if not result then
    ResultRaw := '';
end; // httpGetRaw


function httpGetFileWithCheck(const url, filename: string; var errMsg: String; notify: TProgressFunc=NIL): Boolean;
const
  sigFileExt = '.sig';
//  tmpSubFolder = 'tmp.download';
var
//  tmpFolder: String;
  tmpFile: String;
  resultFile: String;
  pubKey: RawByteString;
  sign64: RawByteString;
begin
//  tmpFolder := ExtractFileDir(filename) + tmpSubFolder + PathDelim;
  resultFile := ExtractFileName(filename);
  tmpFile := filename + '.downloading';

//  if not DirectoryExists(tmpFolder, false) then
//    CreateDirRecursive(tmpFolder);

  Result := httpGetFile(url, tmpFile, errMsg, notify);
  if Result then
    begin
      Result := httpGetRaw(url + sigFileExt, 5555, sign64, errMsg);
    end;
  if Result then
    begin
     pubKey := getRes('RDpubkey');
     Result := verifyEccSignFile(tmpFile, sign64, pubKey);
     if not Result then
       errMsg := unsignesErr;
    end;
  if not result then
    begin
      if FileExists(tmpFile, false) then
        begin
          deleteFile(tmpFile);
          if FileExists(tmpFile + sigFileExt, false) then
            deleteFile(tmpFile + sigFileExt);
        end;
    end
   else
    begin
      MoveFile(PChar(tmpFile), PChar(filename));
    end;
end; // httpGetFileWithCheck

function httpGetFileWithCheck1(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
const
  sigFileExt = '.sig';
//  tmpSubFolder = 'tmp.download';
var
//  tmpFolder: String;
  tmpFile: String;
  resultFile: String;
  pubKey: RawByteString;
  sign64: RawByteString;
begin
//  tmpFolder := ExtractFileDir(filename) + tmpSubFolder + PathDelim;
  resultFile := ExtractFileName(filename);
  tmpFile := filename + '.downloading';

//  if not DirectoryExists(tmpFolder, false) then
//    CreateDirRecursive(tmpFolder);

  Result := httpGetFile1(url, tmpFile, errMsg, notify);
  if Result then
    begin
      Result := httpGetRaw(url + sigFileExt, 5555, sign64, errMsg);
    end;
  if Result then
    begin
     pubKey := getRes('RDpubkey');
     Result := verifyEccSignFile(tmpFile, sign64, pubKey);
     if not Result then
       errMsg := unsignesErr;
    end;
  if not result then
    begin
      if FileExists(tmpFile, false) then
        begin
          deleteFile(tmpFile);
          if FileExists(tmpFile + sigFileExt, false) then
            deleteFile(tmpFile + sigFileExt);
        end;
    end
   else
    begin
      MoveFile(PChar(tmpFile), PChar(filename));
    end;
end; // httpGetFileWithCheck

function getIPs(): TStringDynArray;
{$IFDEF USE_IPv6}
var
  a6: TStringDynArray;
  I: Integer;
{$ENDIF USE_IPv6}
begin
  try
   {$IFDEF USE_IPv6}
    result := listToArray(localIPlist(sfIPv4));
    a6 := listToArray(localIPlist(sfIPv6));
    if Length(a6) > 0 then
      begin
        for I := Low(a6) to High(a6) do
          a6[i] := '[' + a6[i] + ']';
        Result := Result + a6;
      end;
  {$ELSE USE_IPv6}
    result := listToArray(localIPlist);
  {$ENDIF USE_IPv6}
   except
     result := NIL
  end;
end;

function getLocalIPs({$IFDEF USE_IPv6}const ASocketFamily: TSocketFamily = sfIPv4 {$ENDIF USE_IPv6}): TStringDynArray;
begin
  result := listToArray(localIPlist({$IFDEF USE_IPv6}ASocketFamily{$ENDIF USE_IPv6}));
end;

function getIP(): String;
var
  i: integer;
  ips: Tstrings;
begin
  ips := LocalIPlist();
  case ips.count of
    0: result := '';
    1: result := ips[0];
    else
      i:=0;
      while (i < ips.count-1) and isLocalIP(ips[i]) do
        inc(i);
      result := ips[i];
    end;
end; // getIP


function findRedirection(var h, p: String; const agent: String): Boolean;
var
  http: THttpCli;
begin
  result := FALSE;
  http := Thttpcli.create(NIL);
  try
    http.url := h;
    http.agent := agent; //HFS_HTTP_AGENT;
    try
      http.get()
     except // a redirection will result in an exception
      if (http.statusCode < 300) or (http.statusCode >= 400) then
        exit;
      result := TRUE;
      h := http.hostname;
      p := http.ctrlSocket.Port;
    end;
   finally
    http.free
  end
end;

function checkHTTPSCanWork(var missing: TStringDynArray): Boolean;
 {$IFDEF USE_SSL}
var
  files: array of string; // = ['libcrypto-1_1.dll','libssl-1_1.dll'];
//  missing: TStringDynArray;
 {$ENDIF ~USE_SSL}
begin
 {$IFDEF USE_SSL}
  missing := NIL;
//  m := NIL;
  SetLength(files, 2);
  files[0] := GLIBEAY_300DLL_Name;
  files[1] := GSSLEAY_300DLL_Name;
  for var s in files do
    if not FileExists(s) and not dllIsPresent(s) then
      addString(s, missing);
  if missing=NIL then
    exit(TRUE);
 {$ENDIF USE_SSL}
//  m := missing;
  Result := False;
end;

function checkHTTPSCanWork(): Boolean; OverLoad;
var
  m: TStringDynArray;
begin
  Result := checkHTTPSCanWork(m);
end;


class function ThttpClient.createURL(const url: String; canHTTPS: TBoolFunc): ThttpClient;
begin
  if startsText('https://', url)
   and not (Assigned(CanHTTPS) and canHTTPS()) then
    exit(NIL);
  result := ThttpClient.Create(NIL);
  result.URL := url;
  result.fCanHTTPS := canHTTPS;
  result.fAgent := HFS_HTTP_AGENT;
  result.Agent := HFS_HTTP_AGENT;
 {$IFDEF USE_SSL}
  if checkHTTPSCanWork() then
    result.SslContext := TSslContext.Create(NIL)
   else
    begin
      result.followRelocation := False;
      result.SslContext := NIL;
      result.CtrlSocket.SslEnable := False;
    end;
 {$ENDIF USE_SSL}
end;

constructor ThttpClient.create(AOwner: TComponent);
begin
  inherited;
 {$IFDEF USE_SSL}
  followRelocation := TRUE;
 {$ENDIF USE_SSL}
end; // create

destructor ThttpClient.Destroy;
begin
 {$IFDEF USE_SSL}
  if Assigned(SslContext) then
    SslContext.free;
  SslContext:=NIl;
 {$ENDIF USE_SSL}
  inherited destroy;
end;

procedure ThttpClient.onHttpGetUpdate(sender: TObject; buffer: Pointer; len: integer);
var
  prg: Real;
begin
  if Assigned(fOnProgress) then
    with sender as ThttpCli do
     begin
      prg := safeDiv(0.0+RcvdCount, contentLength);
      if not fOnProgress(prg) then
        abort();
     end;
end; // onHttpGetUpdate

//function getExternalAddress(var res: String; provider: PString=NIL; doLog: Boolean = false): Boolean;
function getExternalAddress(var res: String; provider: PString=NIL; doLogFunc: TAdd2LogEvent = NIL): Boolean;

  procedure loadIPservices(src: String='');
  var
    l:string;
    sA: RawByteString;
  begin
    if src = '' then
      begin
        if now()-IPservicesTime < 1 then exit; // once a day
        IPservicesTime:=now();
        try
          sA := trim(httpGet(IP_SERVICES_URL));
         except
          exit
        end;
        src := (UnUTF(sA));
      end;
    IPservices := NIL;
    while src > '' do
      begin
        l := chopLine(src);
        if ansiStartsText('http://', l) then
          addString(l, IPservices);
      end;
  end; // loadIPservices

const {$J+}
  lastProvider: string = ''; // this acts as a static variable
var
  s, mark, addr: string;
  sA: RawByteString;
  i: integer;
begin
  result := FALSE;
  if customIPservice > '' then
    s := customIPservice
  else
    begin
      loadIPservices();
      if IPservices = NIL then
        loadIPservices(UnUTF(getRes('IPservices')));
      if IPservices = NIL then
        exit;

      repeat
        s := IPservices[random(length(IPservices))];
      until s <> lastProvider;
      lastProvider:=s;
    end;
  addr := chop('|', s);
  if assigned(provider) then
    provider^ := addr;
  mark := s;
  try
    sA := httpGet(addr);
    s := UnUTF(sA);
   except
    exit
  end;
  if mark > '' then
    chop(mark, s);
  s := trim(s);
  if s = '' then
    exit;
  // try to determine length
  i := 1;
  while (i < length(s)) and (i < 15) and (s[i+1] in ['0'..'9','.']) do
    inc(i);
  while (i > 0) and (s[i] = '.') do
    dec(i);
  setLength(s,i);
  result := checkAddressSyntax(s, false) and not isLocalIP(s);
  if not result then
    exit;
  if (res <> s) and Assigned(doLogFunc) then //mainFrm.logOtherEventsChk.checked then
    doLogFunc('New external address: '+s+' via '+hostFromURL(addr));
  res := s;
end; // getExternalAddress


initialization
  autoDownloadLibs := NIL;
end.
