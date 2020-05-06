unit hfsGlobal;

interface
uses
  graphics, Types;

const
{$I RnQBuiltTime.inc}
  VERSION = '2.4rc5 RD';
  VERSION_BUILD = '302';
  VERSION_STABLE = {$IFDEF STABLE } TRUE {$ELSE} FALSE {$ENDIF};
  CURRENT_VFS_FORMAT :integer = 1;
  CRLF = #13#10;
  TAB = #9;
  BAK_EXT = '.bak';
  CORRUPTED_EXT = '.corrupted';
  COMMENT_FILE_EXT = '.comment';
  VFS_FILE_IDENTIFIER = 'HFS.VFS';
  CFG_KEY = 'Software\rejetto\HFS';
  CFG_FILE = 'hfs.ini';
  TPL_FILE = 'hfs.tpl';
  IPS_FILE = 'hfs.ips.txt';
  VFS_TEMP_FILE = '~temp.vfs';
  HFS_HTTP_AGENT = 'HFS/'+VERSION;
  COMMENTS_FILE = 'hfs.comments.txt';
  DESCRIPT_ION = 'descript.ion';
  DIFF_TPL_FILE = 'hfs.diff.tpl';
  FILELIST_TPL_FILE = 'hfs.filelist.tpl';
  EVENTSCRIPTS_FILE = 'hfs.events';
  MACROS_LOG_FILE = 'macros-log.html';
  PREVIOUS_VERSION = 'hfs.old.exe';
  SESSION_COOKIE = 'HFS_SID_';
  PROTECTED_FILES_MASK = 'hfs.*;*.htm*;descript.ion;*.comment;*.md5;*.corrupted;*.lnk';
  G_VAR_PREFIX = '#';
  HOURS = 24;
  MINUTES = HOURS*60;
  SECONDS = MINUTES*60; // Tdatetime * SECONDS = time in seconds
  ETA_FRAME = 5; // time frame for ETA (in seconds)
  DOWNLOAD_MIN_REFRESH_TIME :Tdatetime = 1/(5*SECONDS); // 5 Hz
  BYTES_GROUPING_THRESHOLD :Tdatetime = 1/SECONDS; // group bytes in log
  IPS_THRESHOLD = 50;  // used to avoid an external file for few IPs (ipsEverConnected list)
  STATUSBAR_REFRESH = 10; // tenth of second
  MAX_RECENT_FILES = 5;
  MANY_ITEMS_THRESHOLD = 1000;
  KILO = 1024;
  MEGA = KILO*KILO;
  COMPRESSION_THRESHOLD = 10*KILO; // if more than X bytes, VFS files are compressed
  STARTING_SNDBUF = 32000;
  YESNO :array [boolean] of string=('no','yes');
  DEFAULT_MIME = 'application/octet-stream';
  IP_SERVICES_URL = 'http://hfsservice.rejetto.com/ipservices.php';
  SELF_TEST_URL = 'http://hfstest.rejetto.com/';

  USER_ANONYMOUS = '@anonymous';
  USER_ANYONE = '@anyone';
  USER_ANY_ACCOUNT = '@any account';

  ALWAYS_ON_WEB_SERVER = 'google.com';
  ADDRESS_COLOR = clGreen;
  BG_ERROR = $BBBBFF;
  ENCODED_TABLE_HEADER = 'this is an encoded table'+CRLF;

  DEFAULT_MIME_TYPES: array [0..23] of string = (
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
    '*.webp', 'image/webp'
  );

  ICONMENU_NEW = 1;

  ICON_UNIT = 31;
  ICON_ROOT = 1;
  ICON_LINK = 4;
  ICON_FILE = 37;
  ICON_FOLDER = 6;
  ICON_REAL_FOLDER = 19;
  ICON_LOCK = 12;
  ICON_EASY = 29;
  ICON_EXPERT = 35;

  USER_ICON_MASKS_OFS = 10000;
  // messages
resourcestring
  S_PORT_LABEL = 'Port: %s';
  S_PORT_ANY = 'any';
  DISABLED = 'disabled';
  // messages
  MSG_UNPROTECTED_LINKS = 'Links are NOT actually protected.'
    +#13'The feature is there to be used with the "list protected items only..." option.'
    +#13'Continue?';
  MSG_SAME_NAME ='An item with the same name is already present in this folder.'
    +#13'Continue?';
  MSG_OPTIONS_SAVED = 'Options saved';
  MSG_SOME_LOCKED = 'Some items were not affected because locked';
  MSG_ITEM_LOCKED = 'The item is locked';
  MSG_INVALID_VALUE = 'Invalid value';
  MSG_EMPTY_NO_LIMIT = 'Leave blank to get no limits.';
  MSG_ADDRESSES_EXCEED = 'The following addresses exceed the limit:'#13'%s';
  MSG_NO_TEMP = 'Cannot save temporary file';
  MSG_ERROR_REGISTRY = 'Can''t write to registry.'
    +#13'You may lack necessary rights.';
  MSG_MANY_ITEMS = 'You are putting many files.'
    +#13'Try using real folders instead of virtual folders.'
    +#13'Read documentation or ask on the forum for help.';
  MSG_ADD_TO_HFS = '"Add to HFS" has been added to your Window''s Explorer right-click menu.';
  MSG_SINGLE_INSTANCE = 'Sorry, this feature only works with the "Only 1 instance" option enabled.'
    +#13#13'You can find this option under Menu -> Start/Exit'
    +#13'(only in expert mode)';
  MSG_ENABLED =   'Option enabled';
  MSG_DISABLED = 'Option disabled';
  MSG_COMM_ERROR = 'Network error. Request failed.';
  MSG_DDNS_badauth='invalid user/password';
  MSG_DDNS_notfqdn='incomplete hostname, required form aaa.bbb.com';
  MSG_DDNS_nohost='specified hostname does not exist';
  MSG_DDNS_notyours='specified hostname belongs to another username';
  MSG_DDNS_numhost='too many or too few hosts found';
  MSG_DDNS_abuse='specified hostname is blocked for update abuse';
  MSG_DDNS_dnserr='server error';
  MSG_DDNS_911='server error';
  MSG_DDNS_notdonator='an option specified requires payment';
  MSG_DDNS_badagent='banned client';


type
//  Pboolean = ^boolean;

  Paccount = ^Taccount;
	Taccount = record   // user/pass profile
    user, pwd, redir, notes: string;
    wasUser: string; // used in user renaming panel
    enabled, noLimits, group: boolean;
    link: TStringDynArray;
   end;
  Taccounts = array of Taccount;

  TfilterMethod = function(self:Tobject):boolean;

  Thelp = ( HLP_NONE, HLP_TPL );

  TdownloadingWhat = ( DW_UNK, DW_FILE, DW_FOLDERPAGE, DW_ICON, DW_ERROR, DW_ARCHIVE );

  TpreReply =  (PR_NONE, PR_BAN, PR_OVERLOAD);

  TuploadResult = record
    fn, reason:string;
    speed:integer;
    size: int64;
    end;

var
  runningOnRemovable: boolean;
  exePath: string;

implementation

end.
