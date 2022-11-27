unit srvVars;
{$I NoRTTI.inc}

interface
uses
//  Graphics, Classes, Controls, Types, iniFiles, hsLib, srvClassesLib, srvConst;
  Classes, Types, iniFiles, regexpr,
  hsLib, srvClassesLib, srvConst;

// global variables
var
  srv: ThttpSrv;
  globalLimiter: TspeedLimiter;
  ip2obj: THashedStringList;
  sessions: Tsessions;
  etags: THashedStringList;
  forwardedMask: string;
  defaultIP: string;    // the IP address to use forming URLs
  autoupdatedFiles: TstringToIntHash;   // download counter for temp Tfile.s
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
  listenOn: string;  // interfaces HFS should listen on
  port: string;
  upTime: Tdatetime;           // the server is up since...
  inTotalOfs, outTotalOfs: int64; // used to cumulate in/out totals
  hitsLogged, downloadsLogged, uploadsLogged: integer;
  ipsEverConnected: THashedStringList;
  customIPservice: string;
  mimeTypes, address2name, IPservices: TstringDynArray;
  IPservicesTime: TdateTime;
  uploadPaths: TstringDynArray;
  minDiskSpace: int64; // in MB. an int32 would suffice, but an int64 will save us

  defaultTpl, dmBrowserTpl, filelistTpl: Ttpl;
  accounts: Taccounts;

var
  runningOnRemovable: boolean;
  exePath: string;
var
  onlyDotsRE: TRegExpr;
  graph: record
  	rate: integer;    // update speed
    lastOut, lastIn: int64; // save bytesSent and bytesReceived last values
    maxV: integer;    // max value in scale
    size: integer;    // height of the box
    samplesIn, samplesOut: array [0..3000] of integer; // 1 sample, 1 pixel
    beforeRecalcMax: integer;  // countdown
   end;

implementation
  uses
    srvUtils;

INITIALIZATION

MIMEtypes:=toSA([
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

end.
