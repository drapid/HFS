unit hfsVars;
{$I NoRTTI.inc}

interface
uses
 {$IFDEF FMX}
  FMX.Graphics, System.UITypes,
  FMX.TreeView,
 {$ELSE ~FMX}
  Graphics,
//  Forms,
  Controls,
  ComCtrls,
 {$ENDIF FMX}
  Classes, Types, iniFiles, hsLib, srvClassesLib, hfsGlobal;

// global variables
var
//  srv: ThttpSrv;
//  globalLimiter: TspeedLimiter;
//  ip2obj: THashedStringList;
//  sessions: Tsessions;
//  etags: THashedStringList;
  cfgLoaded: boolean;
  addToFolder: string; // default folder where to add items from the command line
  lastDialogFolder: string;  // stores last for open dialog, to make it persistent
  clock: integer;       // program ticks (tenths of second)
  // workaround for splitters' bad behaviour
  lastGoodLogWidth, lastGoodConnHeight: integer;
  tray_ico: Ticon;             // the actual icon shown in tray
  usingFreePort: boolean=TRUE; // the actual server port set was 0
//  upTime: Tdatetime;           // the server is up since...
  trayed: boolean;             // true if the window has been minimized to tray
  flashOn: string;             // describes when to flash the taskbar
  addFolderDefault: string;    // how to default adding a folder (real/virtual)
  toDelete: Tlist;             // connections pending for deletion
  speedLimitIP: real;
  maxConnections: integer;     // max number of connections (total)
  maxConnectionsIP: integer;   // ...from a single address
  maxContempDLs: integer;      // max number of contemporaneous downloads
  maxContempDLsIP: integer;    // ...from a single address
  maxContempDLsUser: integer;  // ...from a single user
  maxIPs: integer;             // max number of different addresses connected
  maxIPsDLing: integer;        // max number of different addresses downloading
//  autoFingerprint: integer;    // create fingerprint on file addition
  renamePartialUploads: string;
  allowedReferer: string;      // check over the Refer header field
  altPressedForMenu: boolean;  // used to enable the menu on ALT key
  noDownloadTimeout: integer;  // autoclose the application after (minutes)
  connectionsInactivityTimeout: integer; // autokick connection after (seconds)
  lastUpdateCheck, lastFilelistTpl: Tdatetime;
  lastUpdateCheckFN: string;   // eventual temp file for saving lastUpdateCheck
  lastActivityTime: Tdatetime;  // used for the "no download timeout"
  recentFiles: TStringDynArray; // recently loaded files
  addingItemsCounter: integer = -1; // -1 is disabled
//  stopAddingItems,
  queryingClose: boolean;
//  tpl_help: string;
  lastWindowRect: Trect;
  tplEditor: string;
  tplLast: Tdatetime;
  tplImport: boolean;
  eventScriptsLast, runScriptLast: Tdatetime;
  graphInEasyMode: boolean;
  cfgPath, tmpPath: string;
  logMaxLines: integer;     // number of lines
  windowsShuttingDown: boolean = FALSE;
  dontLogAddressMask: string;
  openInBrowser: string; // to not send the "attachment" suggestion in header
  quitASAP: boolean;  // deferred quit
  quitting: boolean; // ladies, we're quitting
  scrollFilesBox: integer = -1;
  defaultCfg: string;
  selfTesting: boolean;
  tplIsCustomized: boolean;
  fakingMinimize: boolean; // user clicked the [X] but we simulate the [_]
  loginRealm: string;
  serializedConnColumns: string;
  VFScounterMod: boolean; // if any counter has changed
  logFontName: string;
  logFontSize: integer;
  applicationFullyInitialized: boolean;
  lockTimerevent: boolean;
  logRightClick: Tpoint;
  warnManyItems: boolean = TRUE;
  startupFilename: string;
  trustedFiles, filesToAddQ: TstringDynArray;
  setThreadExecutionState: function(d:dword):dword; stdcall; // as variable, because not available on Win95
  backuppedCfg: string;
  updateASAP: string;
  refusedUpdate: string;
  updateWaiting: string;
  filesBoxRatio: real;
  fromTray: boolean; // used to notify about an eventy happening from a tray action
  userInteraction: record
    disabled: boolean;
    bakVisible: boolean;  // backup value for mainFrm.visible
    end;
  logFile: record
    filename: string;
    apacheFormat: string;
    apacheZoneString: string;
    end;
  userIcsBuffer, userSocketBuffer: integer;
  searchLogTime, searchLogWhiteTime, timeTookToSearchLog: TdateTime;
  sbarTextTimeout: Tdatetime;
  sbarIdxs: record  // indexes within the statusbar
    totalIn, totalOut, banStatus, customTpl, oos, out, notSaved: integer;
    end;
  cachedIPs: String; // To optimize

const
  trayShowCode: array[TTrayShows] of string = ('downloads', 'connections', 'uploads', 'hits', 'ips', 'ips-ever', '');
var
 //  trayShows: string;           // describes the content of the tray icon
  trayShows: TTrayShows;          // describes the content of the tray icon

  function strToTrayShow(const s: String): TTrayShows;

implementation

function strToTrayShow(const s: String): TTrayShows;
begin
  if s = 'connections' then
    Exit(TS_connections)
   else if s = 'downloads' then
    Exit(TS_downloads)
   else if s = 'uploads' then
    Exit(TS_uploads)
   else if s = 'hits' then
    Exit(TS_hits)
   else if s = 'ips' then
    Exit(TS_ips)
   else if s = 'ips-ever' then
    Exit(TS_ips_ever);
  Result := TS_none;
end;


end.
