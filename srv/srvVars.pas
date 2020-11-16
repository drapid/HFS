unit srvVars;
{$I NoRTTI.inc}

interface
uses
  Graphics, Classes, Controls, Types, iniFiles, hsLib, srvClassesLib, srvConst;

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

  defaultTpl, dmBrowserTpl, filelistTpl: Ttpl;
  accounts: Taccounts;

var
  runningOnRemovable: boolean;
  exePath: string;

implementation

end.
