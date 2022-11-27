unit netUtils;

interface

uses
  Classes, types, Windows,
  OverbyteIcshttpProt;

  function httpGetStr(const url: string; from: int64=0; size: int64=-1): string;
  function httpGet(const url:string; from:int64=0; size:int64=-1): RawByteString;
  function httpGetFile(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
  function httpGetFileWithCheck(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
  function httpFileSize(const url: string): int64;
  function getIPs(): TStringDynArray;
  function checkAddressSyntax(address:string; mask:boolean=TRUE):boolean;

implementation

uses
  sysutils, StrUtils,
  OverbyteIcsWSocket,
  RDUtils, RDFileUtil, RnQCrypt,
  hfsGlobal, srvConst, srvUtils, srvVars,
  HSLib, classesLib;

function httpGetStr(const url:string; from:int64=0; size:int64=-1):string;
var
  reply: Tstringstream;
begin
if size = 0 then
  exit('');
reply:=TStringStream.Create('');
with ThttpClient.createURL(url) do
  try
    rcvdStream:=reply;
    if (from <> 0) or (size > 0) then
      contentRangeBegin:=intToStr(from);
    if size > 0 then
      contentRangeEnd:=intToStr(from+size-1);
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
  httpCli := ThttpClient.createURL(url);
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
  httpCli := ThttpClient.createURL(url);
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

function httpGetFile(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
var
  httpCli: ThttpClient;
  supposed: int64;
  reply: Tfilestream;
begin
  supposed := 0;
  httpCli := ThttpClient.createURL(url);
  if Assigned(httpCli) then
  with httpCli do
    try
      reply := NIL;
      reply := TfileStream.Create(filename, fmCreate);
      rcvdStream := reply;
      onDocData:=notify;
      result:=TRUE;
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
  httpCli := ThttpClient.createURL(url);
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


function httpGetFileWithCheck(const url, filename: string; var errMsg: String; notify: TdocDataEvent=NIL): Boolean;
resourcestring
  unsignesErr = 'Signature is not valid';
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
      MoveFile(PWideChar(tmpFile), PWideChar(filename));
    end;
end; // httpGetFileWithCheck

function checkAddressSyntax(address:string; mask:boolean=TRUE):boolean;
var
  a1, a2: string;
  sf: TSocketFamily;
begin
if not mask then
  exit(WSocketIsIPEx(address, sf));
result:=FALSE;
if address = '' then exit;
while (address > '') and (address[1] = '\') do
  delete(address,1,1);
while address > '' do
  begin
  a2 := chop(';', address);
  if sameText(a2, 'lan') then
    continue;
  a1:=chop('-', a2);
  if a2 > '' then
    if not checkAddressSyntax(a1, FALSE)
    or not checkAddressSyntax(a2, FALSE) then
      exit;
  if reMatch(a1, '^[?*a-f0-9\.:]+$', '!') = 0 then
    exit;
  end;
result:=TRUE;
end; // checkAddressSyntax

function getIPs():TStringDynArray;
var
  a6: TStringDynArray;
  I: Integer;
begin
  try
    result := listToArray(localIPlist(sfIPv4));
    a6 := listToArray(localIPlist(sfIPv6));
    if Length(a6) > 0 then
      begin
        for I := Low(a6) to High(a6) do
          a6[i] := '[' + a6[i] + ']';
        Result := Result + a6;
      end;
   except
     result := NIL
  end;
end;

end.
