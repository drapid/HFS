unit hfsGlobal;
{$I NoRTTI.inc}

interface
uses
  System.UITypes,
 {$IFDEF FMX}
  FMX.Graphics,
 {$ELSE ~FMX}
  Graphics,
 {$ENDIF FMX}
  Types, SysUtils, srvConst;

const
{$I RnQBuiltTime.inc}
  CRLF = #13#10;
  CRLFA = RawByteString(#13#10);
  TAB = #9;
  BAK_EXT = '.bak';
  VFS_FILE_IDENTIFIER = 'HFS.VFS';
  CFG_KEY = 'Software\rejetto\HFS';
  CFG_FILE = 'hfs.ini';
  TPL_FILE = 'hfs.tpl';
  IPS_FILE = 'hfs.ips.txt';
  VFS_TEMP_FILE = '~temp.vfs';
  HFS_HTTP_AGENT = 'HFS/'+VERSION;
  EVENTSCRIPTS_FILE = 'hfs.events';
  MACROS_LOG_FILE = 'macros-log.html';
  PREVIOUS_VERSION = 'hfs.old.exe';
  PROTECTED_FILES_MASK = 'hfs.*;*.htm*;descript.ion;*.comment;*.md5;*.corrupted;*.lnk';
  G_VAR_PREFIX = '#';
  DOWNLOAD_MIN_REFRESH_TIME :Tdatetime = 1/(5*SECONDS); // 5 Hz
  BYTES_GROUPING_THRESHOLD :Tdatetime = 1/SECONDS; // group bytes in log
  IPS_THRESHOLD = 50;  // used to avoid an external file for few IPs (ipsEverConnected list)
  STATUSBAR_REFRESH = 10; // tenth of second
  MAX_RECENT_FILES = 5;
  MANY_ITEMS_THRESHOLD = 1000;
  COMPRESSION_THRESHOLD = 10*KILO; // if more than X bytes, VFS files are compressed
  STARTING_SNDBUF = 32000;
  YESNO :array [boolean] of string=('no','yes');
  DEFAULT_MIME = 'application/octet-stream';
  IP_SERVICES_URL = 'http://hfsservice.rejetto.com/ipservices.php';
  SELF_TEST_URL = 'http://hfstest.rejetto.com/';
//  LIBS_DOWNLOAD_URL = 'http://rejetto.com/hfs/';
  LIBS_DOWNLOAD_URL = 'http://libs.rnq.ru/';
  HFS_GUIDE_URL = 'http://www.rejetto.com/hfs/guide/';

  ALWAYS_ON_WEB_SERVER = 'google.com';
  ADDRESS_COLOR = TColors.Green;
  BG_ERROR = $BBBBFF;
  ENCODED_TABLE_HEADER = 'this is an encoded table'+CRLF;
  TRAY_ICON_SIZE = 32;

  // messages
resourcestring
  S_PORT_LABEL = 'Port: %s';
  S_PORT_ANY = 'any';
  DISABLED = 'disabled';
  MSG_OK = 'Ok';
  // messages
  MSG_MENU_VAL = ' (%s)';
  MSG_DL_TIMEOUT = 'No downloads timeout';
  MSG_MAX_CON = 'Max connections';
  MSG_MAX_CON_SING = 'Max connections from single address';
  MSG_MAX_SIM_ADDR = 'Max simultaneous addresses';
  MSG_MAX_SIM_ADDR_DL = 'Max simultaneous addresses downloading';
  MSG_MAX_SIM_DL_SING = 'Max simultaneous downloads from single address';
  MSG_MAX_SIM_DL = 'Max simultaneous downloads';
  MSG_SET_LIMIT = 'Set limit';
  MSG_UNPROTECTED_LINKS = 'Links are NOT actually protected.'
    +#13'The feature is there to be used with the "list protected items only..." option.'
    +#13'Continue?';
  MSG_SAME_NAME ='An item with the same name is already present in this folder.'
    +#13'Continue?';
  MSG_CONTINUE = 'Continue?';
  MSG_PROCESSING = 'Processing...';
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
  MSG_CON_PAUSED = 'paused';
  MSG_CON_SENT = '%s / %s sent';
  MSG_CON_RECEIVED = '%s / %s received';

type

//  Pboolean = ^boolean;

  TfilterMethod = function(self:Tobject):boolean;

  Thelp = ( HLP_NONE, HLP_TPL );

  TpreReply =  (PR_NONE, PR_BAN, PR_OVERLOAD);

type
  TTrayShows = (TS_downloads, TS_connections, TS_uploads, TS_hits, TS_ips, TS_ips_ever, TS_none);

implementation

end.
