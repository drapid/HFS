unit srvConst;
{$I NoRTTI.inc}

interface
uses
  {$IFDEF FMX}
  {$ELSE ~FMX}
  Graphics,
  {$ENDIF FMX}
  Types, SysUtils;

const
  VERSION = '2.4.0 RC9 RD' {$IFDEF CPUX64 } +' x64' {$ENDIF};
  VERSION_BUILD = '321';
  VERSION_STABLE = {$IFDEF STABLE } TRUE {$ELSE} FALSE {$ENDIF};
  CURRENT_VFS_FORMAT: integer = 1;
  CRLF = #13#10;
  CRLFA = RawByteString(#13#10);
  TAB = #9;
  HOURS = 24;
  MINUTES = HOURS*60;
  SECONDS = MINUTES*60; // Tdatetime * SECONDS = time in seconds
  KILO = 1024;
  MEGA = KILO*KILO;
  CORRUPTED_EXT = '.corrupted';
  COMMENT_FILE_EXT = '.comment';
  COMMENTS_FILE = 'hfs.comments.txt';
  DESCRIPT_ION = 'descript.ion';
  DIFF_TPL_FILE = 'hfs.diff.tpl';
  FILELIST_TPL_FILE = 'hfs.filelist.tpl';
  SESSION_COOKIE = 'HFS_SID_';
  VFS_FILE_IDENTIFIER = 'HFS.VFS';
  COMPRESSION_THRESHOLD = 10*KILO; // if more than X bytes, VFS files are compressed

  ETA_FRAME = 5; // time frame for ETA (in seconds)

  USER_ANONYMOUS = '@anonymous';
  USER_ANYONE = '@anyone';
  USER_ANY_ACCOUNT = '@any account';

  DEFAULT_MIME_TYPES: array [0..25] of string = (
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
    '*.webp', 'image/webp'
  );


  DOW2STR: array [1..7] of string=( 'Sun','Mon','Tue','Wed','Thu','Fri','Sat' );
  MONTH2STR: array [1..12] of string = ( 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec' );

//const
//  libsBaseUrl = 'http://rejetto.com/hfs/';

type
  TcharSetA = TSysCharSet; //set of char;
  TcharSetW = set of Char deprecated 'Holds Char values in the ordinal range of 0..255 only.'; //set of char;
  PstringDynArray = ^TstringDynArray;

  Paccount = ^Taccount;
	Taccount = record   // user/pass profile
    user, pwd, redir, notes: string;
    wasUser: string; // used in user renaming panel
    enabled, noLimits, group: boolean;
    link: TStringDynArray;
   end;
  Taccounts = array of Taccount;

  TdownloadingWhat = ( DW_UNK, DW_FILE, DW_FOLDERPAGE, DW_ICON, DW_ERROR, DW_ARCHIVE );

  TpreReply =  (PR_NONE, PR_BAN, PR_OVERLOAD);

type
  TaccountRecursionStopCase = (ARSC_REDIR, ARSC_NOLIMITS, ARSC_IN_SET);

const // Messages
  MSG_SPEED_KBS = '%.1f kB/s';

resourcestring
  MSG_MAX_CON = 'Max connections';
  MSG_MAX_CON_SING = 'Max connections from single address';
  MSG_MAX_SIM_ADDR = 'Max simultaneous addresses';
  MSG_MAX_SIM_ADDR_DL = 'Max simultaneous addresses downloading';
  MSG_MAX_SIM_DL_SING = 'Max simultaneous downloads from single address';
  MSG_MAX_SIM_DL = 'Max simultaneous downloads';

implementation

end.
