unit srvVars;
{$I NoRTTI.inc}

interface
uses
  Classes, Types, iniFiles, regexpr,
  hsLib, srvClassesLib, srvConst;

// global variables
var
  globalLimiter: TspeedLimiter;
  ip2obj: THashedStringList;
  sessions: Tsessions;
  etags: THashedStringList;
  forwardedMask: string;
  defaultIP: string;    // the IP address to use forming URLs
  autoupdatedFiles: TstringToIntHash;   // download counter for temp Tfile.s
  updateASAP: string;
  iconsCache: TiconsCache;
  filesStayFlaggedForMinutes: integer;
  autoFingerprint: integer;    // create fingerprint on file addition
  toAddFingerPrint: TStringList;
  usersInVFS: TusersInVFS;    // keeps track of user/pwd in the VFS
  loadingVFS: record
    resetLetBrowse, unkFK, disableAutosave, visOnlyAnon, bakAvailable, useBackup, macrosFound: boolean;
    build: string;
   end;
  VFSmodified: boolean; // TRUE if the VFS changes have not been saved
  VFScounterMod: boolean; // if any counter has changed
//  listenOn: string;  // interfaces HFS should listen on
//  port: string;
  lastEverySec: TDateTime;
  lastActivityTime: Tdatetime;  // used for the "no download timeout"
  lastFilelistTpl: Tdatetime;
  upTime: Tdatetime;           // the server is up since...
  inTotalOfs, outTotalOfs: int64; // used to cumulate in/out totals
  hitsLogged, downloadsLogged, uploadsLogged: integer;
  dontLogAddressMask: string;
  renamePartialUploads: string;
  ipsEverConnected: THashedStringList;
  toDelete: Tlist;             // connections pending for deletion
  customIPservice: string;
  mimeTypes, address2name, IPservices: TUnicodeStringDynArray;
  thumbsShowToExt: TStringDynArray;
  thumbsShowToExtStr: String;
  IPservicesTime: TdateTime;
  uploadPaths: TstringDynArray;
  minDiskSpace: int64; // in MB. an int32 would suffice, but an int64 will save us
  selfTesting: boolean;
  banlist: array of record ip,comment: String; end;
  noReplyBan: boolean;
  allowedReferer: string;      // check over the Refer header field
  speedLimit: real;            // overall limit, Kb/s --- it virtualizes the value of globalLimiter.maxSpeed, that's actually set to zero when streaming is paused
  speedLimitIP: real;
  openInBrowser: string; // to not send the "attachment" suggestion in header
  inBrowserIfMIME: boolean;

  maxConnections: integer;     // max number of connections (total)
  maxConnectionsIP: integer;   // ...from a single address
  maxContempDLs: integer;      // max number of contemporaneous downloads
  maxContempDLsIP: integer;    // ...from a single address
  maxContempDLsUser: integer;  // ...from a single user
  maxIPs: integer;             // max number of different addresses connected
  maxIPsDLing: integer;        // max number of different addresses downloading

  tplFilename: UnicodeString; // when empty, we are using the default tpl
  dmBrowserTpl, filelistTpl: Ttpl;
  noMacrosTpl: Ttpl;
  accounts: Taccounts;

var
  runningOnRemovable: boolean;
  exePath: string;
  cfgPath, tmpPath: string;
  GMToffset: integer; // in minutes
  externalIP: string;

var
  onlyDotsRE: TRegExpr;
  graph: record
  	rate: integer;    // update speed
    lastOut, lastIn: int64; // save bytesSent and bytesReceived last values
    maxV: int64;    // max value in scale
    size: integer;    // height of the box
    samplesIn, samplesOut: array [0..3000] of int64; // 1 sample, 1 pixel
    beforeRecalcMax: integer;  // countdown
   end;
  flashOn: string;             // describes when to flash the taskbar
  logFile: record
    filename: string;
    apacheFormat: string;
    apacheZoneString: string;
   end;
  setThreadExecutionState: function(d:dword):dword; stdcall; // as variable, because not available on Win95

  function applyThumbsExtStr(str: String): Boolean;

implementation
  uses
    SysUtils, srvUtils;

function applyThumbsExtStr(str: String): Boolean;
var
  arr: TStringDynArray;
begin
  try
    arr := split(';', str, False);
    for var I := Low(arr) to High(arr) do
      arr[i] := Trim(arr[i]);
    sortArray(arr);
    Result := True;
   except
    Result := False;
  end;
  if Result then
    begin
      thumbsShowToExt := arr;
      thumbsShowToExtStr := str;
    end;
end;



INITIALIZATION

MIMEtypes := toSA([
	'*.htm;*.html', 'text/html',
  '*.jpg;*.jpeg;*.jpe', 'image/jpeg',
  '*.gif', 'image/gif',
  '*.png', 'image/png',
  '*.bmp', 'image/bmp',
  '*.ico', 'image/x-icon',
  '*.mpeg;*.mpg;*.mpe', 'video/mpeg',
  '*.avi', 'video/x-msvideo',
  '*.txt', 'text/plain',
  '*.css', 'text/css',
  '*.js',  'text/javascript',
  '*.mkv', 'video/x-matroska',
  '*.mp3', 'audio/mp3',
  '*.mp4', 'video/mp4',
  '*.m3u8', 'application/x-mpegURL',
  '*.webp', 'image/webp'
]);

  applyThumbsExtStr(thumbsShowToExtDefaultStr);

  globalLimiter := TspeedLimiter.create();
  iconsCache := TiconsCache.create();

FINALIZATION

  if Assigned(globalLimiter) then
    FreeAndNil(globalLimiter);
  iconsCache.free;

end.
