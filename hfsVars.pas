unit hfsVars;
{$I NoRTTI.inc}

interface
uses
  Graphics,
//  Forms,
  Controls,
  ComCtrls,
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
  lastDialogFolder: UnicodeString;  // stores last for open dialog, to make it persistent
  clock: integer;       // program ticks (tenths of second)
  // workaround for splitters' bad behaviour
  lastGoodLogWidth, lastGoodConnHeight: integer;
  usingFreePort: boolean=TRUE; // the actual server port set was 0
//  upTime: Tdatetime;           // the server is up since...
  trayed: boolean;             // true if the window has been minimized to tray
  addFolderDefault: string;    // how to default adding a folder (real/virtual)
//  autoFingerprint: integer;    // create fingerprint on file addition
  altPressedForMenu: boolean;  // used to enable the menu on ALT key
  noDownloadTimeout: integer;  // autoclose the application after (minutes)
  connectionsInactivityTimeout: integer; // autokick connection after (seconds)
  lastUpdateCheck: Tdatetime;
  lastUpdateCheckFN: string;   // eventual temp file for saving lastUpdateCheck
  recentFiles: TStringDynArray; // recently loaded files
  addingItemsCounter: integer = -1; // -1 is disabled
//  stopAddingItems,
  queryingClose: boolean;
//  tpl_help: string;
  lastWindowRect: Trect;
  tplEditor: UnicodeString;
  tplLast: Tdatetime;
  tplImport: boolean;
  eventScriptsLast, runScriptLast: Tdatetime;
  graphInEasyMode: boolean;
  logMaxLines: integer;     // number of lines
  windowsShuttingDown: boolean = FALSE;
  quitASAP: boolean;  // deferred quit
  quitting: boolean; // ladies, we're quitting
  scrollFilesBox: integer = -1;
  defaultCfg: string;
  tplIsCustomized: boolean;
  fakingMinimize: boolean; // user clicked the [X] but we simulate the [_]
  loginRealm: string;
  serializedConnColumns: string;
  logFontName: string;
  logFontSize: integer;
  applicationFullyInitialized: boolean;
  lockTimerevent: boolean;
  logRightClick: Tpoint;
  warnManyItems: boolean = TRUE;
  startupFilename: string;
  trustedFiles, filesToAddQ: TstringDynArray;
  backuppedCfg: string;
  refusedUpdate: string;
  updateWaiting: string;
  filesBoxRatio: real;
  fromTray: boolean; // used to notify about an eventy happening from a tray action
  userInteraction: record
    disabled: boolean;
    bakVisible: boolean;  // backup value for mainFrm.visible
    end;
  userIcsBuffer, userSocketBuffer: integer;
  searchLogTime, searchLogWhiteTime, timeTookToSearchLog: TdateTime;
  sbarTextTimeout: Tdatetime;
  sbarIdxs: record  // indexes within the statusbar
    totalIn, totalOut, banStatus, customTpl, oos, out, notSaved: integer;
    end;
  cachedIPs: String; // To optimize

const
//  UPDATE_URL = 'https://www.rejetto.com/hfs/hfs.updateinfo.txt';
 {$IFDEF WIN64}
  UPDATE_URL = 'http://rnq.ru/HFS/hfs.updateinfo.x64.txt';
 {$ELSE WIN32}
  UPDATE_URL = 'http://rnq.ru/HFS/hfs.updateinfo.txt';
 {$ENDIF}
const
  UPDATE_ON_DISK = 'hfs.updateinfo.txt';

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
