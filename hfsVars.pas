unit hfsVars;

interface
uses
  Graphics, Classes, Controls, Types, iniFiles, hsLib, classesLib;

// global variables
var
  srv: ThttpSrv;
  globalLimiter: TspeedLimiter;
  ip2obj: THashedStringList;
  sessions: Tsessions;
  etags: THashedStringList;
  addToFolder: string; // default folder where to add items from the command line
  lastDialogFolder: string;  // stores last for open dialog, to make it persistent
  clock: integer;       // program ticks (tenths of second)
  // workaround for splitters' bad behaviour
  lastGoodLogWidth, lastGoodConnHeight: integer;
  tray_ico: Ticon;             // the actual icon shown in tray
  usingFreePort: boolean=TRUE; // the actual server port set was 0
  upTime: Tdatetime;           // the server is up since...
  trayed: boolean;             // true if the window has been minimized to tray
  trayShows: string;           // describes the content of the tray icon
  flashOn: string;             // describes when to flash the taskbar
  addFolderDefault: string;    // how to default adding a folder (real/virtual)
  toDelete: Tlist;             // connections pending for deletion
  systemimages: Timagelist;    // system icons
  speedLimitIP: real;
  maxConnections: integer;     // max number of connections (total)
  maxConnectionsIP: integer;   // ...from a single address
  maxContempDLs: integer;      // max number of contemporaneous downloads
  maxContempDLsIP: integer;    // ...from a single address
  maxContempDLsUser: integer;  // ...from a single user
  maxIPs: integer;             // max number of different addresses connected
  maxIPsDLing: integer;        // max number of different addresses downloading
  autoFingerprint: integer;    // create fingerprint on file addition
  renamePartialUploads: string;
  allowedReferer: string;      // check over the Refer header field
  altPressedForMenu: boolean;  // used to enable the menu on ALT key
  noDownloadTimeout: integer;  // autoclose the application after (minutes)
  connectionsInactivityTimeout: integer; // autokick connection after (seconds)
  startingImagesCount: integer;
  lastUpdateCheck, lastFilelistTpl: Tdatetime;
  lastUpdateCheckFN: string;   // eventual temp file for saving lastUpdateCheck
  lastActivityTime: Tdatetime;  // used for the "no download timeout"
  recentFiles: TStringDynArray; // recently loaded files
  addingItemsCounter: integer = -1; // -1 is disabled
  stopAddingItems, queryingClose: boolean;
  port: string;
  tpl_help: string;
  lastWindowRect: Trect;
  defaultTpl, dmBrowserTpl, filelistTpl: Ttpl;
  tplEditor: string;
  tplLast: Tdatetime;
  tplImport: boolean;
  eventScriptsLast, runScriptLast: Tdatetime;
  autoupdatedFiles: TstringToIntHash;   // download counter for temp Tfile.s
  iconsCache: TiconsCache;
  usersInVFS: TusersInVFS;    // keeps track of user/pwd in the VFS
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
  sysidx2index: array of record sysidx, idx:integer; end; // maps system imagelist icons to internal imagelist
  loginRealm: string;
  serializedConnColumns: string;
  VFScounterMod: boolean; // if any counter has changed
  imagescache: array of string;
  logFontName: string;
  logFontSize: integer;
  forwardedMask: string;
  applicationFullyInitialized: boolean;
  lockTimerevent: boolean;
  filesStayFlaggedForMinutes: integer;
  logRightClick: Tpoint;
  warnManyItems: boolean = TRUE;
  startupFilename: string;
  trustedFiles, filesToAddQ: TstringDynArray;
  setThreadExecutionState: function(d:dword):dword; stdcall; // as variable, because not available on Win95
  listenOn: string;  // interfaces HFS should listen on
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
  loadingVFS: record
    resetLetBrowse, unkFK, disableAutosave, visOnlyAnon, bakAvailable, useBackup, macrosFound: boolean;
    build: string;
    end;
  userIcsBuffer, userSocketBuffer: integer;
  searchLogTime, searchLogWhiteTime, timeTookToSearchLog: TdateTime;
  sbarTextTimeout: Tdatetime;
  sbarIdxs: record  // indexes within the statusbar
    totalIn, totalOut, banStatus, customTpl, oos, out, notSaved: integer;
    end;
  graph: record
  	rate: integer;    // update speed
    lastOut, lastIn: int64; // save bytesSent and bytesReceived last values
    maxV: integer;    // max value in scale
    size: integer;    // height of the box
    samplesIn, samplesOut: array [0..3000] of integer; // 1 sample, 1 pixel
    beforeRecalcMax: integer;  // countdown
    end;
  defaultIP: string;    // the IP address to use forming URLs
  cachedIPs: String; // To optimize

implementation

end.
