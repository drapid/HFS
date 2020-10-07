unit srvConst;
{$I NoRTTI.inc}

interface
uses
  graphics, Types, SysUtils;

const
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

const
  libsBaseUrl = 'http://rejetto.com/hfs/';

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

implementation

end.
