{
Copyright (C) 2002-2020 Massimo Melina (www.rejetto.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


HTTP Server Lib

==== TO DO
* https
* upload bandwidth control (can it be done without multi-threading?)

}
{$I- }

unit HSlib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  classes, messages, sysutils, strUtils, inifiles, types,
  Forms, extctrls,
  OverbyteIcsWSocket,
  OverbyteIcsWSocketS,
 {$IFNDEF FPC}
{$IFDEF USE_SSL}
  OverbyteIcsSslBase,
{$ENDIF USE_SSL}
 {$ENDIF ~FPC}
  contnrs
  ;

const
  VERSION = '2.12.0';

type
  ThttpSrv=class;

  ThttpConn=class;

  ThttpMethod=( HM_UNK, HM_GET, HM_POST, HM_HEAD );

  ThttpEvent=(
    HE_OPEN,            // server is listening
    HE_CLOSE,           // server does not listen anymore
    HE_CONNECTED,       // a client just connected
    HE_DISCONNECTED,    // client communication terminated
    HE_GOT,             // other peer sent sth
    HE_SENT,            // we sent sth
    HE_REQUESTING,      // a possible new request starts here
    HE_GOT_HEADER,      // header part was fully received
    HE_REQUESTED,       // a full request has been submitted
    HE_STREAM_READY,    // reply stream ready
    HE_REPLIED,         // the reply has been sent
    HE_POST_FILE,       // new file is posted
    HE_POST_MORE_FILE,  // more data has come for the previous file
    HE_POST_END_FILE,   // last file done
    HE_POST_VARS,       // variables are available
    HE_POST_VAR,        // single variable available
    HE_POST_END,        // POST section terminated
    HE_LAST_BYTE_DONE,  // useful to count full downloads
    HE_CANT_OPEN_FILE,  // error
    HE_DESTROID         // Destroid socket
  );

  ThttpConnState=(
    HCS_IDLE,               // connected but idle
    HCS_REQUESTING,         // getting request
    HCS_POSTING,            // getting post data
    HCS_REPLYING,           // a reply is pending
    HCS_REPLYING_HEADER,    // sending header
    HCS_REPLYING_BODY,      // sending body
    HCS_DISCONNECTED        // disconnected
  );

  ThttpReplyMode=(
    HRM_REPLY,              // reply header+body
    HRM_REPLY_HEADER,       // reply header only
    HRM_DENY,               // answer a deny code
    HRM_UNAUTHORIZED,       // bad user/pwd
    HRM_NOT_FOUND,          // answer a not-found code
    HRM_BAD_REQUEST,        // answer a bad-request code
    HRM_INTERNAL_ERROR,     // answer an internal-error code
    HRM_CLOSE,              // close connection with no reply
    HRM_IGNORE,             // does nothing, connection remains open
    HRM_METHOD_NOT_ALLOWED, // answer a method-not-allowed code
    HRM_REDIRECT,           // redirection to another URL
    HRM_OVERLOAD,           // server is overloaded, retry later
    HRM_TOO_LARGE,          // the request has exceeded the max length allowed
    HRM_MOVED,              // moved permanently to another url
    HRM_NOT_MODIFIED        // use the one in your cache, client
  );

  ThttpReply = record
   private
    bodyBr: RawByteString;    // specifies reply body according to bodyMode
    fHeader: RawByteString;            // full raw header (optional)
    fAdditionalHeaders: RawByteString; // these are appended to predefined headers (opt)
    procedure setBody(const b: RawByteString);
    procedure setBodyU(const b: UnicodeString);
    function  getBodyU: UnicodeString;
    procedure setHeader(const h: RawByteString);
    procedure setHeaderU(const h: UnicodeString);
    function  getHeaderU: UnicodeString;
   public
    mode: ThttpReplyMode;
    contentType: RawByteString;       // ContentType header (optional)
    bodyMode :(
      RBM_FILE,         // variable body specifies a file
//      RBM_STRING,       // variable body specifies byte content
      RBM_RAW,        // variable body specifies byte content
      RBM_TEXT,       // variable body specifies byte content
      RBM_STREAM        // refer to bodyStream
    );
    bodyStream: Tstream;   // note: the stream is automatically freed
    IsCompressed: Boolean; // Is body Compressed
    comprType: RawByteString; // Is body GZiped or ZStd or Br
    isBodyUTF8: Boolean;   // Is body UTF8 string
    firstByte, lastByte: int64;  // body interval for partial replies (206)
    realm,           // this will appear in the authentication dialog
    url: string;     // used for redirections
    reason: RawByteString;          // customized reason phrase
    resumeForbidden: boolean;
    procedure headerAdd(const h: String); OverLoad;
    procedure headerAdd(const h: RawByteString); OverLoad;
    procedure Clear;
    procedure ClearAdditionalHeaders;
    property Body: RawByteString read bodyBr write setBody;
    property BodyU: UnicodeString read getBodyU write setBodyU;
    property header: RawByteString read fHeader write setHeader;
    property headerU: UnicodeString read getHeaderU write setHeaderU;
   end;

  ThttpRequest = record
    full: RawByteString;           // the raw request, byte by byte
    method: ThttpMethod;
    url: string;
    ver: string;
    firstByte, lastByte: int64;  // body interval for partial requests
    headers, cookies: ThashedStringList;
    user,pwd: string;
    end;

  ThttpPost = record
    length: int64;          // multipart form-data length
    boundary,               // multipart form-data boundary
    header,                 // contextual header
    data: RawByteString;    // misc data
    varname,                // post variable name
    filename: string;       // name of posted file
    mode: (PM_NONE, PM_URLENCODED, PM_MULTIPART);
   end;

  TspeedLimiter = class
  // connections can be bound to a limiter. The limiter is a common limited
  // resource (the bandwidth) that is consumed.
   protected
    P_maxSpeed: integer;              // this is the limit we set. MAXINT means disabled.
    procedure setMaxSpeed(v:integer);
   public
    availableBandwidth: integer;    // this is the resource itself
    property maxSpeed: integer read P_maxSpeed write setMaxSpeed;
    constructor create(max:integer=MAXINT);
  end;

{$IFDEF USE_SSL}
  ThttpConn = class(TSslWSocketClient)
{$ELSE ~USE_SSL}
  ThttpConn = class(TWSocketClient)
{$ENDIF USE_SSL}
  protected
    P_srv: ThttpSrv;        // reference to the server
    stream: Tstream;
    P_address: string;
    P_port: string;
    brecvd: int64;          // bytes received from the client
    bsent: int64;           // bytes sent to the client
    bsent_body: int64;      // bytes sent to the client (current body only)
    bsent_bodies: int64;    // bytes sent to the client (for all bodies)
    P_requestCount: integer;
    P_destroying: boolean;  // destroying is in progress
    P_sndBuf: integer;
    P_v6: boolean;
    persistent: boolean;
    disconnecting: boolean; // disconnected() has been called
    lockCount: integer;     // prevent freeing of the object
    dontFulFil: boolean;
    firstPostFile: boolean;
    lastPostItemPos, FbytesPostedLastItem: int64;
    // post handling
    inBoundaries: boolean;   // we are between form-data boundaries
    postDataReceived: int64; // bytes received in post data
    // used to calculate actual speed
    lastBsent, lastBrecvd: int64;
    lastSpeedTime: int64;
    P_speedOut, P_speedIn: real;

    buffer: RawByteString;       // internal buffer for incoming data
    // event handlers
    procedure StartConnection; OverRide;
    procedure disconnected(Sender: TObject; Error: Word);
    procedure dataavailable(Sender: TObject; Error: Word);
    procedure senddata(sender: TObject; bytes: Integer);
    procedure datasent(sender: TObject; error: word);
    function  fullBodySize(): Int64;
    function  partialBodySize(): Int64;
    function  sendNextChunk(max: Integer=MAXINT): Integer;
    function  getBytesToSend(): Int64;
    function  getBytesToPost(): Int64;
    function  getBytesGot(): Int64;
    procedure notify(ev:ThttpEvent);
    procedure tryNotify(ev:ThttpEvent);
    procedure calculateSpeed();
    procedure sendheader(const h: String); OverLoad;
    procedure sendheader(const h: RawByteString=''); OverLoad;
    function  replyHeader_mode(mode: ThttpReplyMode): RawByteString;
    function  replyHeader_code(code: Integer): RawByteString;
    function  getDontFree(): Boolean;
    procedure processInputBuffer();
    procedure clearRequest();
    procedure clearReply();
    procedure setSndbuf(v: Integer);
    function  getICSBufSize: Integer;
    procedure setICSBufSize(v: Integer);
    function  getIsDisconnected: Boolean;
    function  getIsSendingStream: Boolean;
  public
//    sock: Twsocket;             // client-server communication socket
    httpState: ThttpConnState;  // what is doing now with this
    httpRequest: ThttpRequest;  // it requests
    reply: ThttpReply;          // we serve
    post: ThttpPost;            // it posts
    data: pointer;              // user data
    paused: boolean;            // while (not paused) do senddata()
    eventData: RawByteString;
    ignoreSpeedLimit: boolean;
    limiters: TobjectList;     // every connection can be bound to a number of TspeedLimiter
    constructor create(server: ThttpSrv; acceptingSock: TWsocket);
    destructor Destroy; override;
    procedure disconnect();
//    procedure addHeader(s: String; overwrite: Boolean=TRUE); OverLoad; // append an additional header line
    procedure addHeader(const s: RawByteString; overwrite: Boolean=TRUE); OverLoad; // append an additional header line
    procedure addHeader(const s: String; overwrite: Boolean=TRUE); OverLoad;
    procedure addHeader(const h, v: RawByteString; overwrite: Boolean=TRUE); OverLoad; // append an additional header line
    procedure addHeader(const h, v: String; overwrite: Boolean=TRUE); OverLoad;
    function  setHeaderIfNone(const s: String): Boolean; OverLoad;// set header if not already existing
    function  setHeaderIfNone(const s: RawByteString): Boolean; OverLoad;// set header if not already existing
    function  setHeaderIfNone(const name: RawByteString; const s: String): Boolean; OverLoad;
    function  setHeaderIfNone(const name: RawByteString; const s: RawByteString): Boolean; OverLoad;
    procedure removeHeader(name: RawByteString);
    function  getHeader(const h: String): String;  // extract the value associated to the specified header field
    function  getCookie(const k: String): String;
    procedure setCookie(const k, v: String; pairs: array of string; const extra: String='');
    procedure delCookie(const k: String);
    function  isAcceptEncoding(const enc: String): Boolean;
    function  getBuffer(): RawByteString;
    function  initInputStream(): boolean;
    procedure socketSetNoDelay;
    property address: String read P_address;      // other peer ip address
    property port: String read P_port;            // other peer port
    property v6: Boolean read P_v6;
    property requestCount: integer read P_requestCount;
    property bytesToSend: int64 read getBytesToSend;
    property bytesToPost: int64 read getBytesToPost;
    property bytesSent: int64 read bsent_bodies;
    property bytesSentLastItem: int64 read bsent_body;
    property bytesPartial: int64 read partialBodySize;
    property bytesFullBody: int64 read fullBodySize;
    property bytesGot: int64 read getBytesGot;
    property bytesPosted: int64 read postDataReceived;
    property bytesPostedLastItem: int64 read FbytesPostedLastItem;
    property speedIn: real read P_speedIn;  // (bytes_recvd/s)
    property speedOut: real read P_speedOut;  // (bytes_sent/s)
    property disconnectedByServer: boolean read disconnecting;
    property destroying: boolean read P_destroying;
    property dontFree: boolean read getDontFree;
    property getLockCount: integer read lockCount;
    property icsBufSize: integer read getICSBufSize write setICSBufSize;
    property sndBuf: integer read P_sndBuf write setSndBuf;
    property hsrv: ThttpSrv read P_srv;
    property isDisconnected: Boolean read getIsDisconnected;
    property isSendingStream: Boolean read getIsSendingStream;
   end;

  ThttpSrv = class
  protected
    timer: Ttimer;
    lockTimerevent: boolean;
    lastHertz: Tdatetime;

    P_port: string;
    P_autoFree: boolean;
    P_speedIn, P_speedOut: real;
    bsent, brecvd: int64;
    procedure setPort(v:string);
    function  getActive():boolean;
    procedure setActive(v:boolean);
    procedure connected(Sender: TObject; Error: Word);
    procedure OnClientConnect(Sender: TObject;
                              Client: TWSocketClient;
                              Error: Word);
    procedure OnClientDisconnect(Sender: TObject;
                              Client: TWSocketClient;
                              Error: Word);
    procedure disconnected(Sender: TObject; Error: Word);
    procedure bgexception(Sender: TObject; E: Exception; var CanClose: Boolean);
    procedure setAutoFree(v: Boolean);
    procedure notify(ev: ThttpEvent; conn: ThttpConn);
    procedure hertzEvent();
    procedure timerEvent(sender: TObject);
    procedure calculateSpeed();
    procedure processDisconnecting();
 {$IFDEF USE_SSL}
    procedure ClientVerifyPeer(Sender        : TObject;
                               var Ok        : Integer;
                               Cert          : TX509Base);
    procedure SslServerSslHandshakeDone(Sender: TObject; ErrCode: Word; PeerCert: TX509Base;
      var Disconnect: Boolean);
 {$ENDIF USE_SSL}
//    procedure WMSslNotTrusted(var Msg: TMessage); message WM_SSL_NOT_TRUSTED;
  public
{$IFDEF USE_SSL}
    sock: TSslWSocketServer;     // listening multiple sockets With SSL
{$ELSE ~USE_SSL}
    sock: TWsocketServer;     // listening multiple sockets
{$ENDIF USE_SSL}
//    sock: Twsocket;     // listening socket
    conns,          // full list of connected clients
    disconnecting,  // list of pending disconnections
    offlines,       // disconnected clients to be freed
    q,              // clients waiting for data to be sent
    limiters: TobjectList;
    data: pointer;      // user data
    persistentConnections: boolean;  // if FALSE disconnect clients after they're served
    onEvent: procedure(event: ThttpEvent; conn: ThttpConn) of object;
    constructor create(); overload;
    destructor Destroy(); override;
    property active:boolean read getActive write setActive; // r we listening?
    property port:string read P_port write setPort;
    property bytesSent:int64 read bsent;
    property bytesReceived:int64 read brecvd;
    property speedIn:real read P_speedIn;  // (bytes_recvd/s)
    property speedOut:real read P_speedOut;  // (bytes_sent/s)
    property autoFreeDisconnectedClients: boolean read P_autoFree write setAutoFree;
    function start(const onAddress: String='*'): Boolean; // returns true if all is ok
    procedure stop();
    procedure disconnectAll(wait: Boolean=FALSE);
    procedure freeConnList(l: TObjectList);
   end;

const
  TIMER_HZ = 100;
  MINIMUM_CHUNK_SIZE = 2*1024;
  MAXIMUM_CHUNK_SIZE = 1024*1024;
  HRM2CODE: array [ThttpReplyMode] of integer = (200, 200, 403, 401, 404, 400,
  	500, 0, 0, 405, 302, 429, 413, 301, 304 );
  METHOD2STR: array [ThttpMethod] of string = ('UNK','GET','POST','HEAD');
  HRM2STR: array [ThttpReplyMode] of string = ('Head+Body', 'Head only', 'Deny',
    'Unauthorized', 'Not found', 'Bad request', 'Internal error', 'Close',
    'Ignore', 'Unallowed method', 'Redirect', 'Overload', 'Request too large',
    'Moved permanently', 'Not Modified');

implementation

uses
  Windows,
 {$IFNDEF FPC}
  mormot.core.base,
 {$ENDIF ~FPC}
{$IFDEF UNICODE}
  AnsiStrings,
//  AnsiClasses,
{$ENDIF UNICODE}
  OverbyteIcsTypes,
  math,
  RDUtils, Base64,
  HSUtils,
  srvConst;

const
  HEADER_LIMITER: RawByteString = CRLFA+CRLFA;
  MAX_REQUEST_LENGTH = 64*1024;
  MAX_INPUT_BUFFER_LENGTH = 256*1024;
  HexCharsW: set of Char = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
                            'A', 'B', 'C', 'D', 'E', 'F']; //
  // used as body content when the user did not specify any
  HRM2BODY: array [ThttpReplyMode] of AnsiString = (
  	'200 - OK',
    '200 - OK (header only)',
    '403 - You are not allowed to access this file',
    '401 - You are not authorized to access this file',
    '404 - File not found',
    '400 - Bad request',
    '500 - Internal server error',
    '',
    '',
    '405 - Method not allowed',
    '<html><head><meta http-equiv="refresh" content="url=%url%" /></head><body onload=''window.location="%url%"''>302 - <a href="%url%">Redirection to %url%</a></body></html>',
    '429 - Server is overloaded, retry later',
    '413 - The request has exceeded the max length allowed',
    '301 - Moved permanently to <a href="%url%">%url%</a>',
    '' // RFC2616: The 304 response MUST NOT contain a message-body
  );
var
  freq: int64;

function replyHeader_IntPositive(const name: String; int: Int64): String;
begin
  result := '';
  if int >= 0 then
    result := name+': '+intToStr(int)+CRLF;
end;

{
function replyHeader_Str(const name:string; const str:string):string;
begin
result:='';
if str > '' then result:=name+': '+str+CRLF;
end;
}
function replyHeader_Str(const name:RawByteString; const str:RawByteString): RawByteString; OverLoad;
begin
result:='';
if str > '' then result:=name+': '+str+CRLFA;
end;

function replyHeader_Str(const name:RawByteString; const str:String): RawByteString; OverLoad;
begin
result:='';
if str > '' then result:=name+': '+ StrToUTF8(str)+CRLFA;
end;

procedure THTTPReply.setBody(const b: RawByteString);
begin
  bodyBr := b;
  isBodyUTF8 := False;
  IsCompressed := False;
  comprType := '';
end;

procedure THTTPReply.setBodyU(const b: UnicodeString);
begin
  bodyBr := UTF8Encode(b);
  isBodyUTF8 := True;
  IsCompressed := False;
  comprType := '';
end;

function THTTPReply.getBodyU: UnicodeString;
begin
  if not IsCompressed then
    begin
      if isBodyUTF8 then
        Result := UTF8ToString(bodyBr)
       else
        Result := UnUTF(bodyBr)
    end
   else
    Result := '' ; // ToDo ZDecompress
end;

procedure THTTPReply.setHeaderU(const h: UnicodeString);
begin
  fHeader := UTF8Encode(h);
  includeTrailingString(fHeader, CRLFA);
end;

procedure THTTPReply.setHeader(const h: RawByteString);
begin
  fHeader := h;
  includeTrailingString(fHeader, CRLFA);
end;

procedure THTTPReply.headerAdd(const h: String);
var
  r: RawByteString;
begin
  if h > '' then
    begin
      r := UTF8Encode(h);
      includeTrailingString(r, CRLFA);
      fHeader := fHeader + r;
    end;
end;

procedure THTTPReply.headerAdd(const h: RawByteString);
var
  r: RawByteString;
begin
  if h > '' then
    begin
      r := h;
      includeTrailingString(r, CRLFA);
      fHeader := fHeader + r;
    end;
end;

function THTTPReply.getHeaderU: UnicodeString;
begin
  Result := UnUTF(fHeader);
end;

procedure THTTPReply.Clear;
begin
  fHeader:='';
  bodyMode := RBM_RAW;
  bodyBr := '';
  IsCompressed := False;
  comprType := '';
  fAdditionalHeaders := '';
  mode:=HRM_IGNORE;
//  firstByte:=request.firstByte;
//  lastByte:=request.lastByte;
  realm:='Password protected resource';
  reason:='';
end;

procedure THTTPReply.ClearAdditionalHeaders;
begin
  fAdditionalHeaders := '';
end;

/////// SERVER

function ThttpSrv.start(const onAddress: String='*'): Boolean;
begin
  result := FALSE;
  if active or not assigned(sock) then
    exit;
  try
    if onAddress = '[*]' then
      begin
        sock.addr := '[0::0]';
       {$IFDEF USE_IPv6}
        sock.SocketFamily := sfIPv6;
       {$ENDIF USE_IPv6}
      end
     else
      begin
        if onAddress = '' then
          begin
            sock.addr := '0.0.0.0';
          {$IFDEF USE_IPv6}
            sock.MultiListenSockets.Clear();
            with Sock.MultiListenSockets.Add do
              begin
                Addr := '[0::0]';
                port := self.port;
                SocketFamily := sfIPv6;
              end;
          {$ENDIF USE_IPv6}
          end
//          onAddress:='*';
        else if //(onAddress = '') or
          (onAddress = '*') then
          sock.addr := '0.0.0.0'
         else
          sock.addr := onAddress;
      end;
    sock.port := port;
  //  sock.proto:='6';
    sock.proto := 'tcp';
 {$IFDEF USE_IPv6}
    sock.SocketFamily := sfAny;
 {$ENDIF USE_IPv6}

 {$IFDEF USE_SSL}
    sock.SslEnable      := False;
 {$ENDIF USE_SSL}
{
    SslContext1.SslCertFile          := CertFileEdit.Text;
    SslContext1.SslPassPhrase        := PassPhraseEdit.Text;
    SslContext1.SslPrivKeyFile       := PrivKeyFileEdit.Text;
    SslContext1.SslCAFile            := CAFileEdit.Text;
    SslContext1.SslCAPath            := CAPathEdit.Text;
    SslContext1.SslVerifyPeer        := VerifyPeerCheckBox.Checked;
}
//    sock.SetAcceptableHostsList(AcceptableHostsEdit.Text);
//    sock.Listen;

 {$IFDEF USE_IPv6}
    if onAddress = '' then
      sock.MultiListen
     else
 {$ENDIF USE_IPv6}
      sock.listen();

    if port = '0' then
      P_port := sock.getxport();
    result := TRUE;

    notify(HE_OPEN, NIL);
   except
  end;
end; // start

procedure ThttpSrv.stop();
begin
  if assigned(sock) then
 {$IFDEF USE_IPv6}
   begin
    try
      sock.MultiClose
     except
    end;
    try
      sock.multiListenSockets.clear()
     except
    end;
   end;
 {$ELSE ~USE_IPv6}
   try
     sock.Close
    except
   end;
 {$ENDIF USE_IPv6}
end;

{$IFDEF USE_IPv6}
procedure ThttpSrv.SslServerSslHandshakeDone(Sender: TObject; ErrCode: Word; PeerCert: TX509Base;
  var Disconnect: Boolean);
begin
// ToDo write log
end;

procedure ThttpSrv.ClientVerifyPeer(Sender: TObject;
  var Ok: Integer; Cert: TX509Base);
var
    Issuer : String;
begin
    Issuer := Cert.IssuerOneLine;
{    if Ok <> 0 then
        Display('Received certificate. Issuer = "' + Issuer + '"')
    else begin
        if Cert.VerifyResult = X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN then begin
            if FTrustedList.IndexOf(Issuer) >= 0 then begin
                Display('Received certificate. Issuer = "' + Issuer + '"');
                Display('We trust this one');
                Ok := 1;
                Exit;
            end;
            FNotTrusted := Issuer;
            (Sender as TSslWSocket).CloseDelayed;
            PostMessage(Handle, WM_SSL_NOT_TRUSTED, 0, 0);
            Exit;
        end;
        Display('Can''t verify certificate:');
        Display('  Issuer = "' + Issuer + '"');
        Display('  Error  = ' + IntToStr(Cert.VerifyResult) + ' (' + Cert.VerifyErrMsg + ')');
    end;
}
end;
 {$ENDIF USE_IPv6}

procedure ThttpSrv.connected(Sender: TObject; Error: Word);
begin
//  if error=0 then
//    ThttpConn.create(self, sender as Twsocket)
end;

procedure ThttpSrv.OnClientConnect(Sender: TObject;
                              Client: TWSocketClient;
                              Error: Word);
var
  i: Integer;
begin
  ThttpConn(Client).P_srv := Self;

  ThttpConn(Client).httpRequest.headers := ThashedStringList.create;
  ThttpConn(Client).httpRequest.headers.nameValueSeparator := ':';
  ThttpConn(Client).limiters := TObjectList.create;
  ThttpConn(Client).limiters.ownsObjects := FALSE;
  ThttpConn(Client).P_address := Client.GetPeerAddr();
  ThttpConn(Client).P_port := Client.GetPeerPort();
 {$IFDEF USE_IPv6}
  ThttpConn(Client).P_v6 := sock.SocketFamily = sfIPv6;
 {$ELSE ~USE_IPv6}
  ThttpConn(Client).P_v6 := false;
 {$ENDIF USE_IPv6}
  ThttpConn(Client).httpState := HCS_IDLE;

 {$IFDEF USE_SSL}
  ThttpConn(Client).OnSslVerifyPeer := ClientVerifyPeer;
  ThttpConn(Client).SslEnable := false;
 {$ENDIF USE_SSL}

  conns.add(ThttpConn(Client));
  ThttpConn(Client).clearRequest();
  ThttpConn(Client).clearReply();
  QueryPerformanceCounter(ThttpConn(Client).lastSpeedTime);

  i := sizeOf(ThttpConn(Client).P_sndBuf);
  if WSocket_getsockopt(Client.HSocket, SOL_SOCKET, SO_SNDBUF, @ThttpConn(Client).P_sndBuf, i) <> NO_ERROR then
    ThttpConn(Client).P_sndBuf:=0;

  Self.notify(HE_CONNECTED, ThttpConn(Client));
  if ThttpConn(Client).reply.mode <> HRM_CLOSE then
    exit;
  ThttpConn(Client).dontFulFil := TRUE;
  ThttpConn(Client).disconnect();
end;

procedure ThttpSrv.disconnected(Sender: TObject; Error: Word);
begin notify(HE_CLOSE, NIL) end;

procedure ThttpSrv.OnClientDisconnect(Sender: TObject;
                              Client: TWSocketClient;
                              Error: Word);
begin
  ThttpConn(Client).httpState := HCS_DISCONNECTED;
//  Self.disconnecting.Add(ThttpConn(Client));
  disconnecting.Remove(ThttpConn(Client));
  q.remove(ThttpConn(Client));
  conns.remove(ThttpConn(Client));
  offlines.Remove(ThttpConn(Client));
  notify(HE_DISCONNECTED, ThttpConn(Client));
end;

constructor ThttpSrv.create();
begin
{$IFDEF USE_SSL}
  sock := TSslWSocketServer.create(NIL);
{$ELSE ~USE_SSL}
  sock := TWSocketServer.create(NIL);
{$ENDIF USE_SSL}
//  sock := TWSocket.create(NIL);
  sock.OnSessionAvailable := connected;
  sock.OnSessionClosed := disconnected;
  sock.OnBgException := bgexception;
//  sock.MultiThreaded := True;
  sock.ClientClass := ThttpConn;
  sock.OnClientConnect := Self.OnClientConnect;
  sock.OnClientDisconnect := Self.OnClientDisconnect;
 {$IFDEF USE_SSL}
  sock.OnSslHandshakeDone := SslServerSslHandshakeDone;
 {$ENDIF USE_SSL}

  conns := TobjectList.create;
  conns.OwnsObjects := FALSE;
  offlines := TobjectList.create;
  offlines.OwnsObjects:=FALSE;
  q := TobjectList.create;
  q.OwnsObjects := FALSE;
  disconnecting := TobjectList.create;
  disconnecting.OwnsObjects := FALSE;
  limiters := TobjectList.create;
  limiters.OwnsObjects := FALSE;
  timer := Ttimer.create(NIL);
  timer.OnTimer := timerEvent;
  timer.Interval := 1000 div TIMER_HZ;
  timer.Enabled := TRUE;
//  sock.SetAcceptableHostsList()
  Port := '80';
  autoFreeDisconnectedClients := TRUE;
  persistentConnections := TRUE;
end; // create

destructor ThttpSrv.destroy();
begin
  freeAndNIL(timer);
  stop();
  disconnectAll(TRUE);
  processDisconnecting();
  freeAndNIL(sock);
  freeConnList(conns);
  freeAndNIL(conns);
  freeAndNIL(disconnecting);
  freeAndNIL(offlines);
  freeAndNIL(q);
  freeAndNIL(limiters);
  inherited;
end; // destroy

procedure ThttpSrv.hertzEvent();
var
  i: integer;
begin
if now()-lastHertz < 1/(24*60*60) then exit;
lastHertz:=now();
calculateSpeed();
for i:=0 to limiters.Count-1 do
  try
    with limiters[i] as TspeedLimiter do
      availableBandwidth:=maxSpeed;
  except end;
end; // hertzEvent

procedure ThttpSrv.processDisconnecting();
var
  c: ThttpConn;
  i: integer;
begin
  if disconnecting.Count = 0 then
    Exit;
  i := disconnecting.Count-1;
  while i >= 0 do
  begin
    if disconnecting.Count > i then
      begin
       c := disconnecting[i] as ThttpConn;
       dec(i);
      end
     else
      begin
       dec(i);
       continue;
      end;
    if c.dontFree then
      continue;
    c.processInputBuffer(); // serve, till the end.
    disconnecting.delete(i+1);
    q.remove(c);
    conns.remove(c);
    offlines.add(c);
    notify(HE_DISCONNECTED, c);
  end;
end; // processDisconnecting

procedure ThttpSrv.timerEvent(sender: TObject);

  procedure processPipelines();
  var
    i: integer;
  begin
    i := 0;
    if conns.count > 0 then
      while i < conns.count do
       begin
         try
           with ThttpConn(conns[i]) do
            if (httpState in [HCS_IDLE, HCS_DISCONNECTED]) and (buffer > '') then
              processInputBuffer();
          except
         end;
         Inc(i);
       end;
  end; // processPipelines

  procedure processQ();
  var
    c: ThttpConn;
    toQ: Tobjectlist;
    i, chunkSize: integer;
  begin
    toQ := Tobjectlist.create;
    try
      toQ.ownsObjects:=FALSE;
      while q.count > 0 do
        begin
          c := NIL;
          try
            c := q.first() as ThttpConn; // got an AV here, had no better solution than adding a try statement www.rejetto.com/forum/?topic=6204
            q.delete(0);
           except
          end;
          if c = NIL then
            continue;

          try
            chunkSize:= RDUtils.ifThen(c.paused, 0, MAXINT);
            if not c.ignoreSpeedLimit then
              for i:=0 to c.limiters.Count-1 do
                with c.limiters[i] as TspeedLimiter do
                  if availableBandwidth >= 0 then
                    chunkSize := min(chunkSize, availableBandwidth);
            if chunkSize <= 0 then
              begin
              toQ.add(c);
              continue;
              end;
            if c.destroying or (c.httpState = HCS_DISCONNECTED)
             or (c = NIL) or (c.State <> wsConnected) then
              continue;
            // serve the pending connection with a data chunk
            chunkSize := c.sendNextChunk(chunkSize);
            for i:=0 to c.limiters.Count-1 do
              with c.limiters[i] as TspeedLimiter do
                dec(availableBandwidth, chunkSize);
           except
          end;
        end;
      q.assign(toQ, laOR);
     finally
      toQ.Free
    end;
  end; // processQ

begin
  hertzEvent();

  lockTimerevent := TRUE;
  try
    processDisconnecting();
    if autoFreeDisconnectedClients then
      freeConnList(offlines);
    processPipelines();
    processQ();
   finally
    lockTimerevent := FALSE
  end;
end; // timerEvent

procedure ThttpSrv.notify(ev: ThttpEvent; conn: ThttpConn);
begin
  if not assigned(onEvent) then
    exit;
  if assigned(conn) then
  begin
    inc(conn.lockCount);
    conn.pause();
  end;
// event handler shall not break our thing
  try
    onEvent(ev, conn);
   finally
    //if assigned(sock) then sock.resume();
    if assigned(conn) then
      begin
      dec(conn.lockCount);
      conn.resume();
      end;
  end;
end;

function Thttpsrv.getActive():boolean;
begin
  result := assigned(sock) and (sock.State=wsListening)
end;

procedure ThttpSrv.setActive(v:boolean);
begin
if v <> active then
  if v then start() else stop()
end; // setactive

procedure ThttpSrv.freeConnList(l:TobjectList);
begin
while l.count > 0 do
  with l.first() as ThttpConn do
    try
      try
        l.delete(0)
       finally
        free
      end
     except
      Application.ProcessMessages;
    end;
end; // freeConnList

procedure ThttpSrv.calculateSpeed();
var
  i: integer;
begin
P_speedOut:=0;
P_speedIn:=0;
i:=0;
while i < conns.count do
  begin
  ThttpConn(conns[i]).calculateSpeed();
  P_speedOut:=P_speedOut+ThttpConn(conns[i]).speedOut;
  P_speedIn:=P_speedIn+ThttpConn(conns[i]).speedIn;
  inc(i);
  end;
end; // calculateSpeed

procedure ThttpSrv.setPort(v:string);
begin
if active then
  raise Exception.Create(classname+': cannot change port while active');
P_port:=v
end; // setPort

procedure ThttpSrv.disconnectAll(wait:boolean=FALSE);
var
  i: integer;
  clone: Tlist;
begin
// on disconnection <conns> list changes. clone it for safer enumeration.
  clone := Tlist.Create;
  clone.Assign(conns);
// cast disconnection
  for i:=0 to clone.count-1 do
    ThttpConn(clone[i]).disconnect();
  if wait then
    for i:=0 to clone.count-1 do
      if conns.IndexOf(clone[i]) >= 0 then
        ThttpConn(clone[i]).WaitForClose();
  clone.free;
end; // disconnectAll

procedure ThttpSrv.setAutoFree(v:boolean);
begin P_autofree:=v end;

procedure ThttpSrv.bgexception(Sender: TObject; E: Exception; var CanClose: Boolean);
begin canClose:=FALSE end;

////////// CLIENT

constructor ThttpConn.create(server: ThttpSrv; acceptingSock: Twsocket);
var
  i: integer;
begin
// init socket
{
  sock := Twsocket.create(NIL);
//  sock.MultiThreaded := True;
  if acceptingSock <> NIL then
    sock.Dup(acceptingSock.accept())
   else
    sock.Dup(server.sock.accept());

  sock.OnDataAvailable := dataavailable;
  sock.OnSessionClosed := disconnected;
  sock.onSendData := senddata;
  sock.onDataSent := datasent;
  sock.LineMode := FALSE;

  P_srv := server;

  httpRequest.headers := ThashedStringList.create;
  httpRequest.headers.nameValueSeparator := ':';
  limiters := TObjectList.create;
  limiters.ownsObjects:=FALSE;
  P_address := sock.GetPeerAddr();
  P_port := sock.GetPeerPort();
}
 {$IFDEF USE_IPv6}
  P_v6 := acceptingSock.SocketFamily = sfIPv6;
 {$ELSE ~USE_IPv6}
  P_v6 := false;
 {$ENDIF USE_IPv6}
  httpState := HCS_IDLE;
  P_srv.conns.add(self);
  clearRequest();
  clearReply();
  QueryPerformanceCounter(lastSpeedTime);

  i := sizeOf(P_sndBuf);
  if WSocket_getsockopt(HSocket, SOL_SOCKET, SO_SNDBUF, @P_sndBuf, i) <> NO_ERROR then
    P_sndBuf:=0;

  server.notify(HE_CONNECTED, self);
  if reply.mode <> HRM_CLOSE then
    exit;
  dontFulFil := TRUE;
  disconnect();
end;

procedure ThttpConn.StartConnection;
begin
  Self.OnDataAvailable := dataavailable;
  Self.OnSessionClosed := disconnected;
  Self.onSendData := senddata;
  Self.onDataSent := datasent;
  Self.LineMode := FALSE;

//  P_srv := FServer;
end;

destructor ThttpConn.destroy;
begin
  if dontFree then
    raise exception.Create('still in use');
  P_destroying := TRUE;
  if assigned(Self) then
    try
     {$IFDEF FPC}
      Self.Shutdown(0);
     {$ELSE FPC}
      Self.Shutdown(SD_BOTH);
     {$ENDIF FPC}
      Self.WaitForClose();
     except
    end;
  if assigned(P_srv) and assigned(P_srv.offlines) then
    P_srv.offlines.remove(self);

  P_srv.q.remove(Self);
  P_srv.conns.remove(Self);
  P_srv.offlines.Remove(Self);
  P_srv.disconnecting.Remove(Self);

  P_srv.notify(HE_DESTROID, Self);

  freeAndNIL(httpRequest.headers);
  freeAndNIL(httpRequest.cookies);
  freeAndNil(stream);
//  freeAndNIL(sock);
  freeAndNIL(limiters);
  inherited;
end; // destroy

procedure ThttpConn.calculateSpeed();
var
	bytes: int64;
  now: int64;
  elapsed: Tdatetime;
begin
if freq = 0 then exit;

QueryPerformanceCounter(now);
elapsed:=(now-lastSpeedTime)/freq;
lastSpeedTime:=now;

bytes:=bsent-lastBsent;
lastBsent:=bsent;
P_speedOut:=bytes/elapsed;

bytes:=brecvd-lastBrecvd;
lastBrecvd:=brecvd;
P_speedIn:=bytes/elapsed;
end; // calculateSpeed

procedure ThttpConn.disconnected(Sender: TObject; Error: Word);
begin
  httpState := HCS_DISCONNECTED;
  P_srv.disconnecting.Add(self);
end;

function ThttpConn.getHeader(const h: String): String;
begin
  result := '';
  if httpRequest.method = HM_UNK then
    exit;
  result := trim(httpRequest.headers.values[h]);
end; // getHeader

function ThttpConn.isAcceptEncoding(const enc: String): Boolean;
var
  accHdr: String;
begin
  accHdr := getHeader('Accept-Encoding');
  result := ipos(enc, accHdr) > 0
end; // isAcceptEncoding

function ThttpConn.getBuffer(): RawByteString;
begin
  result:=buffer
end;

function ThttpConn.getCookie(const k: String): String;
begin
  result:='';
  if httpRequest.method = HM_UNK then
    exit;
  if httpRequest.cookies = NIL then
  begin
    httpRequest.cookies := ThashedStringList.create;
    with httpRequest.cookies do
     begin
       delimiter:=';';
       QuoteChar:=#0;
       delimitedText := getHeader('cookie');
     end;
  end;
  result := decodeURL(trim(httpRequest.cookies.values[k]));
end; // getCookie

procedure ThttpConn.delCookie(const k: String);
begin
  setCookie(k,'', ['expires','Thu, 01-Jan-70 00:00:01 GMT'])
end;

procedure ThttpConn.setCookie(const k, v: String; pairs: array of String; const extra: String='');
var
  i: integer;
  c: RawByteString;
begin
c:=RawByteString('Set-Cookie: ')+UTF8Encode(k)+'='+UTF8Encode(v)+'; ';
i:=0;
while i < length(pairs)-1 do
  begin
  c:=c+UTF8Encode(lowerCase(pairs[i])+'='+pairs[i+1])+RawByteString('; ');
  inc(i,2);
  end;
addHeader(c+UTF8Encode(extra));
end; // setCookie

procedure ThttpConn.clearRequest();
begin
  httpRequest.method := HM_UNK;
  httpRequest.ver:='';
  httpRequest.url:='';
  httpRequest.firstByte:=-1;
  httpRequest.lastByte:=-1;
  httpRequest.headers.clear();
  freeAndNIL(httpRequest.cookies);
  httpRequest.user:='';
  httpRequest.pwd:='';
end; // clearRequest

procedure ThttpConn.clearReply();
begin
  reply.Clear;
  reply.mode:=HRM_IGNORE;
  reply.firstByte := httpRequest.firstByte;
  reply.lastByte := httpRequest.lastByte;
  reply.realm:='Password protected resource';
end; // clearReply

procedure ThttpConn.processInputBuffer();

  function parseHeader(): Boolean;
  var
//    r, s: string;
    h, h2: String;
    r, sR: RawByteString;
    u: String;
    i : integer;
  begin
    result := FALSE;
    r := httpRequest.full;

    // find first blank space
    for i:=1 to 10 do
      if i > length(r) then
        exit
       else if r[i]=' ' then
        break;

    clearRequest();
    post.header:='';
    post.mode:=PM_NONE;

    sR := uppercase(chop(i, 1, r));
    if sR='GET' then
      httpRequest.method := HM_GET
     else if sR='POST' then
      httpRequest.method := HM_POST
     else if sR='HEAD' then
      httpRequest.method := HM_HEAD
     else;

    httpRequest.url := UnUTF(chop(RawByteString(' '), r));

    sR := uppercase(chopLine(r));
    // if 'HTTP/' is not found, chop returns S
    if chop(RawByteString('HTTP/'),sR) = '' then
      httpRequest.ver := sR;

    httpRequest.headers.text := UnUTF(r);

    h := getHeader('Range');
    if ansiStartsText('bytes=', h) then
      begin
        delete(h,1,6);
        h2 := chop('-',h);
        try
          if h2>'' then
            httpRequest.firstByte:=strToInt64(h2);
          if h>'' then
            httpRequest.lastByte:=strToInt64(h);
         except
        end;
      end;

    h := getHeader('Authorization');
    if AnsiStartsText('Basic', h) then
      begin
        delete(h,1,6);
    //    s:= base64decode(s);
        u := UnUTF(Base64DecodeString(h));

        httpRequest.user := trim(chop(':',u));
        httpRequest.pwd := u;
      end;

    h := getHeader('Connection');
    persistent := P_srv.persistentConnections and
      (ansiStartsText('Keep-Alive', h) or (httpRequest.ver >= '1.1') and (ipos('close', h)=0));

    h := getHeader('Content-Type');
    if ansiStartsText('application/x-www-form-urlencoded', h) then
      post.mode := PM_URLENCODED
    else if ansiStartsText('multipart/form-data', h) then
      begin
        post.mode := PM_MULTIPART;
        chop('boundary=', h);
        post.boundary  := '--'+UTF8Encode(h);
      end;
    post.length := StrToInt64Def(getHeader('Content-Length'), 0);
    // the browser may not support 2GB+ files. This workaround works only for files under 4GB.
    if post.length < 0 then
      inc(post.length, int64(2) shl 31);

    result := TRUE;
  end; // parseHeader

  procedure handlePostMultipart();

    procedure handleLeftData(i: Integer);
    begin
      // the data processed below is related to the previous file
      post.data := chop(i, length(post.boundary), buffer);
      // if data was found, we must trim the CRLF between data and boundary
      setlength(post.data, length(post.data)-2);
      // we expect this data to have a filename, otherwise it is just discarded
      if post.filename > '' then
        tryNotify(HE_POST_MORE_FILE)
       else if post.varname > '' then
        tryNotify(HE_POST_VAR);
      FbytesPostedLastItem:=bytesPosted-length(buffer)-lastPostItemPos-length(post.boundary)-2;
      if post.filename > '' then
        tryNotify(HE_POST_END_FILE);
    end; // handleLeftData

  var
    i: integer;
    s, l, k, c: RawByteString;
    cU: UnicodeString;
  begin
    repeat
      { When the buffer is stuffed with file bytes only, we can avoid calling pos() and chop().
      // Unexpectedly this did not speed up anything. I report the try so you don't waste your time.
      if (bytesPosted < post.length-length(post.boundary)) and (post.filename > '') then
        begin
        post.data:=buffer;
        buffer:='';
        notify(HE_POST_MORE_FILE);
        break;
        end;
      }

      // a boundary point at a (sub)header or to the end of the post section
      i:=pos(post.boundary, buffer);
      if i = 0 then
        begin
        if post.filename = '' then
          post.data:=post.data+chop(length(buffer)-length(post.boundary), 0, buffer)
        else
          // no boundary, this is a chunk of the file we are receiving. notify the listener
          // only about the data we are sure it doesn't overlap a possibly coming boundary }
          begin
          post.data:=chop(length(buffer)-length(post.boundary), 0, buffer);
          if post.data > '' then
            tryNotify(HE_POST_MORE_FILE);
          end;
        break;
        end;
      // was it the end of the post section?
      if copy(buffer, i+length(post.boundary), 4) = RawByteString('--')+CRLFA then
        begin
        handleLeftData(i);
        chop(RawByteString('--'+CRLFA), buffer);
        tryNotify(HE_POST_END);
        httpState := HCS_REPLYING;
        post.filename:='';
        break;
        end;
      // we wait for the header to be complete
      if posEx(HEADER_LIMITER, buffer, i+length(post.boundary)) = 0 then
        break;
      handleLeftData(i);
      post.filename:='';
      post.data:='';
      post.header:=chop(HEADER_LIMITER, buffer);
      chopLine(post.header);
      // parse the header part
      s:=post.header;
      while s > '' do
        begin
        l:=chopLine(s);
        if l = '' then
          continue;
        k:=chop(RawByteString(':'), l);
        if not sameText(k, RawByteString('Content-Disposition')) then // we are not interested in other fields
          continue;
        k:=trim(chop(';', l));
        if not sameText(k, RawByteString('form-data')) then
          continue;
        while l > '' do
          begin
          c:=chop(nonQuotedPos(RawByteString(';'), l), l);
          k:=trim(chop(RawByteString('='), c));
          cU:=UnUTF(ansiDequotedStr(c,'"'));
          if sameText(k, RawByteString('filename')) then
            begin
            delete(cU, 1, lastDelimiter('/\',cU));
            post.filename:=cU;
            end
           else
          if sameText(k, RawByteString('name')) then
            post.varname:=cU;
          end;
        end;
      lastPostItemPos:=bytesPosted-length(buffer);
      if post.filename = '' then
        continue;
      firstPostFile:=FALSE;
      tryNotify(HE_POST_FILE);
    until false;
  end; // handlePostMultipart

  procedure handlePostData();
  begin
  case post.mode of
    PM_MULTIPART: handlePostMultipart();
    PM_URLENCODED:
      if bytesToPost <= 0 then
        begin
        post.data:=chop(bytesPosted+1, 0, buffer);
        tryNotify(HE_POST_VARS);
        end;
    end;
  if bytesToPost <= 0 then
    begin
    tryNotify(HE_POST_END);
    httpState := HCS_REPLYING
    end;
  end; // handlePostData

  procedure handleHeaderData();
  var
    i, sepLen: integer;
  begin
    // try to identify header length and position
    i:=pos(HEADER_LIMITER, buffer);
    sepLen:=4;
    if i <= 0 then
      begin
      // support for non-standard line separator
      i:=pos(RawByteString(#13#13), buffer);
      sepLen:=2;
      end;
    if i <= 0 then
      begin
      // no full header yet
      if pos(RawByteString(#3),buffer) > 0 then // search for a CTRL+C issued with a telnet session
        begin
        reply.mode:=HRM_CLOSE;
        disconnect();
        end;
      if length(buffer) > MAX_REQUEST_LENGTH then // and check for max length
        begin
        reply.mode:=HRM_TOO_LARGE;
        sendHeader(replyheader_mode(reply.mode));
        end;
      exit;
      end;
    httpRequest.full := chop(i,sepLen,buffer);
    if not parseHeader() then exit;
    notify(HE_GOT_HEADER);
    if httpRequest.method <> HM_POST then
      begin
      httpState := HCS_REPLYING;
      exit;
      end;
    httpState := HCS_POSTING;
    firstPostFile:=TRUE;
    postDataReceived:=length(buffer);
    handlePostData();
  end; // handleHeaderData

  function replyHeader_OK(contentLength:int64=-1): RawByteString;
  begin
    result:=replyheader_code(200)
      +format(RawByteString('Content-Length: %d')+CRLFA, [contentLength]);
  end; // replyHeader_OK

  function replyHeader_PARTIAL( firstB, lastB, totalB:int64): RawByteString;
  begin
    result:=replyheader_code(206)
      +format(RawByteString('Content-Range: bytes %d-%d/%d')+CRLFA+RawByteString('Content-Length: %d')+CRLFA,
          [firstB, lastB, totalB, lastB-firstB+1 ])
  end; // replyheader_PARTIAL

begin
  if buffer = '' then
    exit;
  if httpState = HCS_IDLE then
  begin
    httpState := HCS_REQUESTING;
    reply.contentType:='text/html; charset=utf-8';
    notify(HE_REQUESTING);
  end;
  case httpState of
    HCS_REPLYING,
    HCS_REPLYING_HEADER,
    HCS_REPLYING_BODY: exit; // wait until the job is done
    HCS_POSTING: handlePostData();
    HCS_REQUESTING: handleHeaderData();
  end;
  if httpState <> HCS_REPLYING then
    exit;
// handle reply
  clearReply();
  inc(P_requestCount);
  notify(HE_REQUESTED);
  if not initInputStream() then
  begin
    reply.mode:=HRM_INTERNAL_ERROR;
    reply.contentType:='text/html; charset=utf-8';
    notify(HE_CANT_OPEN_FILE);
  end;
  notify(HE_STREAM_READY);
case reply.mode of
  HRM_CLOSE: disconnect();
  HRM_IGNORE: ;
  HRM_NOT_FOUND,
  HRM_BAD_REQUEST,
  HRM_METHOD_NOT_ALLOWED,
  HRM_INTERNAL_ERROR,
  HRM_OVERLOAD,
  HRM_NOT_MODIFIED,
  HRM_DENY: sendHeader( replyheader_mode(reply.mode) );
  HRM_UNAUTHORIZED:
    sendHeader(replyheader_mode(reply.mode)
      +replyHeader_Str(RawByteString('WWW-Authenticate'),'Basic realm="'+reply.realm+'"') );
  HRM_REDIRECT, HRM_MOVED:
    sendHeader(replyheader_mode(reply.mode)+'Location: '+ StrToUTF8(reply.url) );
  HRM_REPLY, HRM_REPLY_HEADER:
    if stream = NIL then
      sendHeader( replyHeader_code(404) )
    else if (httpRequest.firstByte >= bytesFullBody) or (httpRequest.lastByte >= bytesFullBody) then
      sendHeader( replyHeader_code(400) )
    else if reply.header > '' then
        sendHeader()
    else if partialBodySize = fullBodySize then
      sendHeader( replyHeader_OK(bytesFullBody) )
    else
      with reply do
        sendHeader( replyHeader_PARTIAL(firstByte, lastByte, bytesFullBody) );
  end;//case
end; // processInputBuffer

procedure ThttpConn.dataavailable(Sender: TObject; Error: Word);
var
  s: RawByteString;
begin
  if error <> 0 then
    exit;
 {$IFDEF FPC}
  s := Self.ReceiveStr();
 {$ELSE ~FPC}
  s := Self.ReceiveStrA();
 {$ENDIF FPC}
  inc(brecvd, length(s));
  inc(P_srv.brecvd, length(s));
  if (s = '') or dontFulFil then
    exit;
  if httpState = HCS_POSTING then
    inc(postDataReceived, length(s));
  if length(buffer)+length(s) > MAX_INPUT_BUFFER_LENGTH then
  begin
    disconnect();
    try
      Self.Abort()
     except
    end; // please, brutally
    exit;
  end;
  buffer := buffer+s;
  eventData := s;
  notify(HE_GOT);
  processInputBuffer();
end; // dataavailable

procedure ThttpConn.senddata(sender: Tobject; bytes: integer);
begin
  if bytes <= 0 then
    exit;
  inc(bsent, bytes);
  inc(P_srv.bsent, bytes);
  if httpState = HCS_REPLYING_BODY then
    begin
      inc(bsent_body, bytes);
      inc(bsent_bodies, bytes);
    end;
  notify(HE_SENT);
end; // senddata

procedure ThttpConn.datasent(sender: Tobject; error: word);

  function toBeQueued(): Boolean;
  var
    i: integer;
  begin
  result:=TRUE;
  if paused then exit;
  for i:=0 to limiters.Count-1 do
    with limiters[i] as TspeedLimiter do
      if maxSpeed < MAXINT then
        exit;
  result:=FALSE;
  end; // toBeQueued

var
  notifyReplied: boolean;
begin
  if not (httpState in [HCS_REPLYING_HEADER, HCS_REPLYING_BODY]) then
    exit;

  if (httpState = HCS_REPLYING_HEADER) and (reply.mode <> HRM_REPLY_HEADER) then
    begin // the header is never sent splitted, so we know that at this stage we already sent it all
      httpState := HCS_REPLYING_BODY;
    // set up a default body for errors with no body set
      if ((stream = NIL) or (stream.size = 0)) and (reply.mode <> HRM_REPLY) then
      begin
        reply.bodyMode := RBM_TEXT;
        reply.Body := HRM2BODY[reply.mode];
        if reply.mode in [HRM_REDIRECT, HRM_MOVED] then
          reply.bodyU := stringReplace(reply.bodyU, '%url%', reply.url, [rfReplaceAll]);
        initInputStream();
      end;
    end;
  if (httpState = HCS_REPLYING_BODY) and (bytesToSend > 0) then
    begin
      if toBeQueued() then
        P_srv.q.add(self)
       else
        sendNextChunk();
      exit;
    end;
  notifyReplied := FALSE;
  if (httpState in [HCS_REPLYING_HEADER, HCS_REPLYING_BODY, HCS_DISCONNECTED])
  and (bytesToSend = 0) then
    begin
      notifyReplied:=TRUE;
      httpState := HCS_IDLE;
    end;

  if not persistent or not (reply.mode in [HRM_REPLY, HRM_REPLY_HEADER]) then
    disconnect()
   else
    // we must check the socket state, because a disconnection could happen while
    // this method is executing
    if Self.State <> wsClosed then
      httpState := HCS_IDLE;
  if notifyReplied then
    begin
      notify(HE_REPLIED);
      if stream.position = stream.size then
      begin
        freeAndNil(stream); // free file handle
        notify(HE_LAST_BYTE_DONE);
      end;
    end;
  // once the event has been notified, we reset the current counter
  if httpState = HCS_IDLE then
    bsent_body:=0;

  freeAndNil(stream);
end; // datasent

procedure ThttpConn.disconnect();
begin
  if disconnecting then
    exit;
  disconnecting := TRUE;
//  if sock = NIL then
//    exit;
  try
   {$IFDEF FPC}
    Self.Shutdown(0);
   {$ELSE FPC}
    Self.Shutdown(SD_BOTH);
   {$ENDIF FPC}
    Self.CloseDelayed();
   except
  end;
end; // disconnect

function ThttpConn.fullBodySize():int64;
begin if stream = NIL then result:=0 else result:=stream.Size end;

function ThttpConn.partialBodySize():int64;
begin
  if (reply.lastByte<0) and (reply.firstByte<0) then
    result := bytesFullBody
   else
    result := reply.lastByte-reply.firstByte+1
end; // partialBodySize

function ThttpConn.initInputStream():boolean;
var
  i: integer;
  s: String;
begin
  result := FALSE;
  FreeAndNil(stream);
  try
    case reply.bodyMode of
  //    RBM_RAW: stream := TAnsiStringStream.create(reply.body);
  //    RBM_TEXT: stream := TAnsiStringStream.create(reply.body);
      RBM_RAW: stream := TRawByteStringStream.create(reply.body);
      RBM_TEXT: stream := TRawByteStringStream.create(reply.body);
      RBM_FILE:
        begin
          s := reply.bodyU;
         {$IFDEF FPC}
          stream := TFileStream.Create(s, fmOpenRead+fmShareDenyNone);
         {$ELSE ~FPC}
          i := fileopen(s, fmOpenRead+fmShareDenyNone);
          if i = -1 then
            exit;
          stream := TFileStream.Create(i);
         {$ENDIF FPC}
        end;
      RBM_STREAM: stream := reply.bodyStream;
     end;
    with reply do
      if resumeForbidden or (firstByte < 0) and (lastByte < 0) then
        begin
          firstByte := 0;
          lastbyte := bytesFullBody-1;
        end
      else
        if lastByte < 0 then
          lastbyte:=bytesFullBody-1
         else
          if firstbyte < 0 then
            begin
              firstByte := bytesFullBody-lastByte;
              lastByte := bytesFullBody;
            end;

    if (reply.firstByte > 0) and (reply.mode = HRM_REPLY) then
      stream.Seek(httpRequest.firstByte, soBeginning);

    result := TRUE;
   except
  end;
end; // initInputStream

function ThttpConn.sendNextChunk(max: Integer=MAXINT): Integer;
var
  n, toSend: int64;
  buf: RawByteString;
begin
  result := 0;
  if stream = NIL then
    exit;
  n := trunc(speedOut*1.5);
  // the following line helps fast networks to reach max speed sooner.
  // in a test, a 3MB file has been downloaded locally at doubled speed.
  if (n = 0) or (bytesSentLastItem = 0) then
    n := max;
  if n > MAXIMUM_CHUNK_SIZE then
    n := MAXIMUM_CHUNK_SIZE;
  if n < MINIMUM_CHUNK_SIZE then
    n := MINIMUM_CHUNK_SIZE;
  if n > max then
    n := max;
  toSend := bytesToSend;
  if n > toSend then
    n := toSend;
  if n = 0 then
    exit;
  setLength(buf, n);
  n := stream.read(buf[1], n);
  setLength(buf, n);
  try
    result := Self.SendStr(buf)
   except
  end; // the socket may be accidentally closed
  if result < n then
    stream.Seek(n-result, soCurrent);
end; // sendNextChunk

procedure ThttpConn.socketSetNoDelay;
var
  i: Integer;
begin
  i := -1;
  WSocket_setsockopt(Self.HSocket, IPPROTO_TCP, TCP_NODELAY, @i, sizeOf(i));
end;

function ThttpConn.getBytesToSend():int64;
begin result:=bytesPartial-bsent_body end;

function ThttpConn.getBytesToPost():int64;
begin result:=post.length-bytesPosted end;

function ThttpConn.getbytesGot():int64;
begin result:=length(buffer) end;

procedure ThttpConn.notify(ev:ThttpEvent);
begin P_srv.notify(ev, self) end;

procedure ThttpConn.tryNotify(ev:ThttpEvent);
begin try P_srv.notify(ev, self) except end end;

procedure ThttpConn.sendheader(const h: string);
begin
  httpState := HCS_REPLYING_HEADER;
  if reply.header = '' then
    reply.headerU := h;
  reply.headerAdd(reply.fAdditionalHeaders);

  try
     Self.sendStr(reply.header+CRLFA);
   except
  end;
end; // sendHeader

procedure ThttpConn.sendheader(const h: RawByteString='');
begin
  httpState := HCS_REPLYING_HEADER;
  if reply.header = '' then
    reply.header := h;
  reply.headerAdd(reply.fAdditionalHeaders);

  try
     Self.sendStr(reply.header+CRLFA);
   except
  end;
end; // sendHeader

function replycode2reason(code:integer): RawByteString;
begin
case code of
  200: result:='OK';
  206: result:='Partial Content';
  301: result:='Moved Permanently';
  302: result:='Found';
  400: result:='Bad Request';
  401: result:='Unauthorized';
  403: result:='Forbidden';
  404: result:='Not Found';
  405: result:='Method Not Allowed';
  413: result:='Payload Too Large';
  429: result:='Too Many Requests';
  500: result:='Internal Server Error';
  503: result:='Service Unavailable';
  else result:='';
  end;
end; // replycode2reason

function ThttpConn.replyHeader_code(code:integer): RawByteString;
begin
if reply.reason = '' then reply.reason:=replycode2reason(code);
result:=format(RawByteString('HTTP/1.1 %d %s')+CRLFA, [code,reply.reason])
  + replyHeader_Str(RawByteString('Content-Type'),reply.contentType)
end;

function ThttpConn.replyHeader_mode(mode:ThttpReplyMode): RawByteString;
begin result:=replyHeader_code(HRM2CODE[mode]) end;

// return true if the operation succeded
function ThttpConn.setHeaderIfNone(const s: String): Boolean;
var
  name: RawByteString;
begin
  name := StrToUTF8(getNameOf(s));
  if name = '' then
    raise Exception.Create('Missing colon');
  result := namePos(name, reply.fAdditionalHeaders) = 0; // empty text will also be considered as existing
  if result then
    addHeader(s, FALSE); // with FALSE it's faster
end; // setHeaderIfNone

function ThttpConn.setHeaderIfNone(const s: RawByteString): Boolean;
var
  name: RawByteString;
begin
  name := getNameOf(s);
  if name = '' then
    raise Exception.Create('Missing colon');
  result := namePos(name, reply.fAdditionalHeaders) = 0; // empty text will also be considered as existing
  if result then
    addHeader(s, FALSE); // with FALSE it's faster
end; // setHeaderIfNone

// return true if the operation succeded
function ThttpConn.setHeaderIfNone(const name: RawByteString; const s: String): Boolean;
begin
  if name = '' then
    raise Exception.Create('Missing colon');
  result := namePos(name, reply.fAdditionalHeaders) = 0; // empty text will also be considered as existing
  if result then
    addHeader(name, StrToUTF8(s), FALSE); // with FALSE it's faster
end; // setHeaderIfNone

// return true if the operation succeded
function ThttpConn.setHeaderIfNone(const name: RawByteString; const s: RawByteString): Boolean;
begin
  if name = '' then
    raise Exception.Create('Missing colon');
  result := namePos(name, reply.fAdditionalHeaders) = 0; // empty text will also be considered as existing
  if result then
    addHeader(name, s, FALSE); // with FALSE it's faster
end; // setHeaderIfNone

procedure ThttpConn.removeHeader(name: RawByteString);
var
    i, eol: integer;
    s: RawByteString;
begin
  s := reply.fAdditionalHeaders;
  if s = '' then
    Exit;
  includeTrailingString(name, RawByteString(':'));
// see if it already exists
  i:=1;
  repeat
    i := namePos(name, s, i);
  if i = 0 then break;
  // yes it does
  eol:=posEx(RawByteString(#10), s, i);
  if eol = 0 then // this never happens, unless the string is corrupted. Just to be sounder.
    eol:=length(s);
  delete(s, i, eol-i+1); // remove it
  until false;
reply.fAdditionalHeaders:=s;
end; // removeHeader

procedure ThttpConn.addHeader(const s: RawByteString; overwrite: Boolean=TRUE);
begin
if overwrite then
  removeHeader(getNameOf(s));
//appendStr(reply.additionalHeaders, s+CRLF);
reply.fAdditionalHeaders := reply.fAdditionalHeaders + s + CRLFA;
end; // addHeader

procedure ThttpConn.addHeader(const s: String; overwrite: Boolean=TRUE);
begin
if overwrite then
  removeHeader(getNameOf(s));
//appendStr(reply.additionalHeaders, s+CRLF);
reply.fAdditionalHeaders := reply.fAdditionalHeaders + StrToUTF8(s) + CRLFA;
end; // addHeader

procedure ThttpConn.addHeader(const h, v: RawByteString; overwrite: Boolean=TRUE);
begin
  if overwrite then
    removeHeader(h);
  reply.fAdditionalHeaders := reply.fAdditionalHeaders + h + ': ' + v + CRLFA;
end; // addHeader

procedure ThttpConn.addHeader(const h, v: String; overwrite: Boolean=TRUE);
var
  hr: RawByteString;
begin
  hr :=  StrToUTF8(h);
  if overwrite then
    removeHeader(hr);
  reply.fAdditionalHeaders := reply.fAdditionalHeaders + hr + ': ' + StrToUTF8(v) + CRLFA;
end; // addHeader

function ThttpConn.getDontFree(): Boolean;
begin result:=lockCount > 0 end;

procedure ThttpConn.setSndbuf(v: Integer);
begin
  if P_sndBuf = v then
    exit;
  P_sndBuf := v;
  WSocket_setsockopt(Self.HSocket, SOL_SOCKET , SO_SNDBUF, @v, SizeOf(v));
end;

procedure ThttpConn.setICSBufSize(v: Integer);
begin
  Self.BufSize := v;
end;

function ThttpConn.getICSBufSize: Integer;
begin
  Result := Self.BufSize;
end;

function ThttpConn.getIsDisconnected: Boolean;
begin
  Result := httpState = HCS_DISCONNECTED;
end;

function ThttpConn.getIsSendingStream: Boolean;
begin
  Result := reply.bodyMode = RBM_STREAM;
end;

constructor TspeedLimiter.create(max: Integer=MAXINT);
begin maxSpeed:=max end;

procedure TspeedLimiter.setMaxSpeed(v: Integer);
begin
  P_maxSpeed:=v;
  availableBandwidth:=min(availableBandwidth, v);
end;

INITIALIZATION
queryPerformanceFrequency(freq);

end.
