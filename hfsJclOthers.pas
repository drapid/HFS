unit hfsJclOthers;

interface
uses
  Windows, System.SysUtils, System.Classes;

{$DEFINE BORLAND}

{ Set FreePascal to Delphi mode }
{$IFDEF FPC}
  {$MODE DELPHI}
  {$ASMMODE Intel}
  {$UNDEF BORLAND}
  {$DEFINE CPUASM}
   // FPC defines CPU32, CPU64 and Unix automatically
{$ENDIF}
{$IFDEF BORLAND}
  {$IFDEF LINUX}
    {$DEFINE KYLIX}
  {$ENDIF LINUX}
  {$IFNDEF CLR}
    {$IFNDEF CPUX86}
      // CPUX86 is not defined, which means it most likely is a 64 bits compiler.
      // However, this is only the case if either of two other symbols are defined:
      // http://docwiki.embarcadero.com/RADStudio/Seattle/en/Conditional_compilation_%28Delphi%29
      {$DEFINE CPU64}
      {$DEFINE DELPHI64_TEMPORARY}
      {$IFNDEF CPUX64}
        {$IFNDEF CPU64BITS}
          {$DEFINE CPU386}  // None of the two 64-bits symbols are defined, assume this is 32-bit
          {$DEFINE CPU32}
          {$UNDEF CPU64}
          {$UNDEF DELPHI64_TEMPORARY}
        {$ENDIF ~CPU64BITS}
      {$ENDIF ~CPUX64}
    {$ELSE ~CPUX86}
      {$DEFINE CPU386}
      {$DEFINE CPU32}
    {$ENDIF ~CPUX86}

    // The ASSEMBLER symbol appeared with Delphi 7
    {$IFNDEF COMPILER7_UP}
      {$DEFINE CPUASM}
    {$ELSE}
      {$IFDEF ASSEMBLER}
        {$DEFINE CPUASM}
      {$ENDIF ASSEMBLER}
    {$ENDIF ~COMPILER7_UP}
  {$ENDIF ~CLR}
{$ENDIF BORLAND}


function PathAddSeparator(const Path: string): string;
function PathRemoveSeparator(const Path: string): string;
function IsDirectory(const FileName: string): Boolean;
function DirectoryExists(const Name: string): Boolean;
function ForceDirectories(Name: string): Boolean;

// Path Manipulation
//
// Various support routines for working with path strings. For example, building a path from
// elements or extracting the elements from a path, interpretation of paths and transformations of
// paths.
const
  {$IFDEF UNIX}
  // renamed to DirDelimiter
  // PathSeparator    = '/';
  DirDelimiter = '/';
  DirSeparator = ':';
  {$ENDIF UNIX}
  {$IFDEF MSWINDOWS}
  PathDevicePrefix = '\\.\';
  // renamed to DirDelimiter
  // PathSeparator    = '\';
  DirDelimiter = '\';
  DirSeparator = ';';
  PathUncPrefix    = '\\';
  {$ENDIF MSWINDOWS}

type
  {$IFDEF FPC}
  Largeint = Int64;
  {$ELSE ~FPC}
  {$IFDEF CPU32}
  SizeInt = Integer;
  {$ENDIF CPU32}
  {$IFDEF CPU64}
  SizeInt = NativeInt;
  {$ENDIF CPU64}
  PSizeInt = ^SizeInt;
  PPointer = ^Pointer;
  PByte = System.PByte;
  Int8 = ShortInt;
  Int16 = Smallint;
  Int32 = Integer;
  UInt8 = Byte;
  UInt16 = Word;
  UInt32 = LongWord;
  PCardinal = ^Cardinal;
  {$IFNDEF COMPILER7_UP}
  UInt64 = Int64;
  {$ENDIF ~COMPILER7_UP}
  PWideChar = System.PWideChar;
  PPWideChar = ^PWideChar;
  PPAnsiChar = ^PAnsiChar;
  PInt64 = type System.PInt64;
  {$ENDIF ~FPC}
  PPInt64 = ^PInt64;
  PPPAnsiChar = ^PPAnsiChar;

type
  TJclAddr32 = Cardinal;
  {$IFDEF FPC}
  TJclAddr64 = QWord;
  {$IFDEF CPU64}
  TJclAddr = QWord;
  {$ENDIF CPU64}
  {$IFDEF CPU32}
  TJclAddr = Cardinal;
  {$ENDIF CPU32}
  {$ENDIF FPC}
  {$IFDEF BORLAND}
  TJclAddr64 = Int64;
  {$IFDEF CPU64}
  TJclAddr = TJclAddr64;
  {$ENDIF CPU64}
  {$IFDEF CPU32}
  TJclAddr = TJclAddr32;
  {$ENDIF CPU32}
  {$ENDIF BORLAND}
  PJclAddr = ^TJclAddr;


// EJclError
type
  EJclError = class(Exception);

  EJclPathError = class(EJclError);
  EJclFileUtilsError = class(EJclError);

// EJclWin32Error
type
  EJclWin32Error = class(EJclError)
  private
    FLastError: DWORD;
    FLastErrorMsg: string;
  public
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    constructor CreateRes(Ident: Integer); overload;
    constructor CreateRes(ResStringRec: PResStringRec); overload;
    property LastError: DWORD read FLastError;
    property LastErrorMsg: string read FLastErrorMsg;
  end;

//=== JclWin32 ===============================================================
resourcestring
  RsWin32Error        = 'Win32 error: %s (%u)%s%s';
  RsELibraryNotFound  = 'Library not found: %s';
  RsEFunctionNotFound = 'Function not found: %s.%s';

//=== JclNTFS ================================================================
resourcestring
  RsInvalidArgument = '%s: Invalid argument <%s>';
  RsNtfsUnableToDeleteSymbolicLink = 'Unable to delete temporary symbolic link';
  RsEUnableToCreatePropertyStorage = 'Unable to create property storage';
  RsEIncomatibleDataFormat = 'Incompatible data format';

//=== JclFileUtils ===========================================================
resourcestring
  // Path manipulation
  RsPathInvalidDrive = '%s is not a valid drive';
  RsCannotCreateDir = 'Unable to create directory';

//== { EJclWin32Error } ======================================================
// Cross-Platform Compatibility
const
  // line delimiters for a version of Delphi/C++Builder
  NativeLineFeed       = Char(#10);
  NativeCarriageReturn = Char(#13);
  NativeCrLf           = string(#13#10);
const
  {$IFDEF MSWINDOWS}
  NativeLineBreak      = NativeCrLf;
  {$ENDIF MSWINDOWS}
  {$IFDEF UNIX}
  NativeLineBreak      = NativeLineFeed;
  {$ENDIF UNIX}

// memory initialization
// first parameter is "out" to make FPC happy with uninitialized values
procedure ResetMemory(out P; Size: Longint);

// Identification
type
  TFileSystemFlag =
   (
    fsCaseSensitive,            // The file system supports case-sensitive file names.
    fsCasePreservedNames,       // The file system preserves the case of file names when it places a name on disk.
    fsSupportsUnicodeOnDisk,    // The file system supports Unicode in file names as they appear on disk.
    fsPersistentACLs,           // The file system preserves and enforces ACLs. For example, NTFS preserves and enforces ACLs, and FAT does not.
    fsSupportsFileCompression,  // The file system supports file-based compression.
    fsSupportsVolumeQuotas,     // The file system supports disk quotas.
    fsSupportsSparseFiles,      // The file system supports sparse files.
    fsSupportsReparsePoints,    // The file system supports reparse points.
    fsSupportsRemoteStorage,    // ?
    fsVolumeIsCompressed,       // The specified volume is a compressed volume; for example, a DoubleSpace volume.
    fsSupportsObjectIds,        // The file system supports object identifiers.
    fsSupportsEncryption,       // The file system supports the Encrypted File System (EFS).
    fsSupportsNamedStreams,     // The file system supports named streams.
    fsVolumeIsReadOnly          // The specified volume is read-only.
                                // Windows 2000/NT and Windows Me/98/95:  This value is not supported.
   );

  TFileSystemFlags = set of TFileSystemFlag;

function GetVolumeFileSystemFlags(const Volume: string): TFileSystemFlags;

// WinBase.h line 10251

function SetVolumeMountPointW(lpszVolumeMountPoint, lpszVolumeName: LPCWSTR): BOOL; stdcall;
{$EXTERNALSYM SetVolumeMountPointW}

function GetVolumeNameForVolumeMountPointW(lpszVolumeMountPoint: LPCWSTR;
  lpszVolumeName: LPWSTR; cchBufferLength: DWORD): BOOL; stdcall;
{$EXTERNALSYM GetVolumeNameForVolumeMountPointW}

// line 3189


function BackupSeek(hFile: THandle; dwLowBytesToSeek, dwHighBytesToSeek: DWORD;
  out lpdwLowByteSeeked, lpdwHighByteSeeked: DWORD;
  var lpContext: Pointer): BOOL; stdcall;
{$EXTERNALSYM BackupSeek}



type
  {$EXTERNALSYM _REPARSE_DATA_BUFFER}
  _REPARSE_DATA_BUFFER = record
    ReparseTag: DWORD;
    ReparseDataLength: Word;
    Reserved: Word;
    case Integer of
      0: ( // SymbolicLinkReparseBuffer and MountPointReparseBuffer
        SubstituteNameOffset: Word;
        SubstituteNameLength: Word;
        PrintNameOffset: Word;
        PrintNameLength: Word;
        PathBuffer: array [0..0] of WCHAR);
      1: ( // GenericReparseBuffer
        DataBuffer: array [0..0] of Byte);
  end;
  {$EXTERNALSYM REPARSE_DATA_BUFFER}
  REPARSE_DATA_BUFFER = _REPARSE_DATA_BUFFER;
  {$EXTERNALSYM PREPARSE_DATA_BUFFER}
  PREPARSE_DATA_BUFFER = ^_REPARSE_DATA_BUFFER;
  TReparseDataBuffer = _REPARSE_DATA_BUFFER;
  PReparseDataBuffer = PREPARSE_DATA_BUFFER;

const
  {$EXTERNALSYM REPARSE_DATA_BUFFER_HEADER_SIZE}
  REPARSE_DATA_BUFFER_HEADER_SIZE = 8;

const
  {$EXTERNALSYM IO_REPARSE_TAG_VALID_VALUES}
  IO_REPARSE_TAG_VALID_VALUES = DWORD($E000FFFF);

//
// Maximum allowed size of the reparse data.
//

const
  MAXIMUM_REPARSE_DATA_BUFFER_SIZE = 16 * 1024;
  {$EXTERNALSYM MAXIMUM_REPARSE_DATA_BUFFER_SIZE}

//
// Predefined reparse tags.
// These tags need to avoid conflicting with IO_REMOUNT defined in ntos\inc\io.h
//

  IO_REPARSE_TAG_RESERVED_ZERO = (0);
  {$EXTERNALSYM IO_REPARSE_TAG_RESERVED_ZERO}
  IO_REPARSE_TAG_RESERVED_ONE  = (1);
  {$EXTERNALSYM IO_REPARSE_TAG_RESERVED_ONE}

//
// The value of the following constant needs to satisfy the following conditions:
//  (1) Be at least as large as the largest of the reserved tags.
//  (2) Be strictly smaller than all the tags in use.
//

  IO_REPARSE_TAG_RESERVED_RANGE = IO_REPARSE_TAG_RESERVED_ONE;
  {$EXTERNALSYM IO_REPARSE_TAG_RESERVED_RANGE}


const
  IO_REPARSE_TAG_MOUNT_POINT = DWORD($A0000003);
  {$EXTERNALSYM IO_REPARSE_TAG_MOUNT_POINT}
  IO_REPARSE_TAG_HSM         = DWORD($C0000004);
  {$EXTERNALSYM IO_REPARSE_TAG_HSM}
  IO_REPARSE_TAG_SIS         = DWORD($80000007);
  {$EXTERNALSYM IO_REPARSE_TAG_SIS}
  IO_REPARSE_TAG_DFS         = DWORD($8000000A);
  {$EXTERNALSYM IO_REPARSE_TAG_DFS}
  IO_REPARSE_TAG_FILTER_MANAGER = DWORD($8000000B);
  {$EXTERNALSYM IO_REPARSE_TAG_FILTER_MANAGER}
  IO_COMPLETION_MODIFY_STATE = $0002;
  {$EXTERNALSYM IO_COMPLETION_MODIFY_STATE}
  IO_COMPLETION_ALL_ACCESS   = DWORD(STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $3);
  {$EXTERNALSYM IO_COMPLETION_ALL_ACCESS}
  DUPLICATE_CLOSE_SOURCE     = $00000001;
  {$EXTERNALSYM DUPLICATE_CLOSE_SOURCE}
  DUPLICATE_SAME_ACCESS      = $00000002;
  {$EXTERNALSYM DUPLICATE_SAME_ACCESS}

  RtdlGetVolumeNameForVolumeMountPointW: function(lpszVolumeMountPoint: LPCWSTR;
    lpszVolumeName: LPWSTR; cchBufferLength: DWORD): BOOL stdcall = GetVolumeNameForVolumeMountPointW;

  RtdlSetVolumeMountPointW: function(lpszVolumeMountPoint: LPCWSTR;
    lpszVolumeName: LPCWSTR): BOOL stdcall = SetVolumeMountPointW;


// shlguid.h line 404

const
  FMTID_ShellDetails: TGUID = '{28636aa6-953d-11d2-b5d6-00c04fd918d0}';
  {$EXTERNALSYM FMTID_ShellDetails}

  PID_FINDDATA        = 0;
  {$EXTERNALSYM PID_FINDDATA}
  PID_NETRESOURCE     = 1;
  {$EXTERNALSYM PID_NETRESOURCE}
  PID_DESCRIPTIONID   = 2;
  {$EXTERNALSYM PID_DESCRIPTIONID}
  PID_WHICHFOLDER     = 3;
  {$EXTERNALSYM PID_WHICHFOLDER}
  PID_NETWORKLOCATION = 4;
  {$EXTERNALSYM PID_NETWORKLOCATION}
  PID_COMPUTERNAME    = 5;
  {$EXTERNALSYM PID_COMPUTERNAME}

// PSGUID_STORAGE comes from ntquery.h
const
  FMTID_Storage: TGUID = '{b725f130-47ef-101a-a5f1-02608c9eebac}';
  {$EXTERNALSYM FMTID_Storage}

// Image properties
const
  FMTID_ImageProperties: TGUID = '{14b81da1-0135-4d31-96d9-6cbfc9671a99}';
  {$EXTERNALSYM FMTID_ImageProperties}

// The GUIDs used to identify shell item attributes (columns). See IShellFolder2::GetDetailsEx implementations...

const
  FMTID_Displaced: TGUID = '{9B174B33-40FF-11d2-A27E-00C04FC30871}';
  {$EXTERNALSYM FMTID_Displaced}
  PID_DISPLACED_FROM = 2;
  {$EXTERNALSYM PID_DISPLACED_FROM}
  PID_DISPLACED_DATE = 3;
  {$EXTERNALSYM PID_DISPLACED_DATE}

const
  FMTID_Briefcase: TGUID = '{328D8B21-7729-4bfc-954C-902B329D56B0}';
  {$EXTERNALSYM FMTID_Briefcase}
  PID_SYNC_COPY_IN = 2;
  {$EXTERNALSYM PID_SYNC_COPY_IN}

const
  FMTID_Misc: TGUID = '{9B174B34-40FF-11d2-A27E-00C04FC30871}';
  {$EXTERNALSYM FMTID_Misc}
  PID_MISC_STATUS      = 2;
  {$EXTERNALSYM PID_MISC_STATUS}
  PID_MISC_ACCESSCOUNT = 3;
  {$EXTERNALSYM PID_MISC_ACCESSCOUNT}
  PID_MISC_OWNER       = 4;
  {$EXTERNALSYM PID_MISC_OWNER}
  PID_HTMLINFOTIPFILE  = 5;
  {$EXTERNALSYM PID_HTMLINFOTIPFILE}
  PID_MISC_PICS        = 6;
  {$EXTERNALSYM PID_MISC_PICS}

const
  FMTID_WebView: TGUID = '{F2275480-F782-4291-BD94-F13693513AEC}';
  {$EXTERNALSYM FMTID_WebView}
  PID_DISPLAY_PROPERTIES = 0;
  {$EXTERNALSYM PID_DISPLAY_PROPERTIES}
  PID_INTROTEXT          = 1;
  {$EXTERNALSYM PID_INTROTEXT}

const
  FMTID_MUSIC: TGUID = '{56A3372E-CE9C-11d2-9F0E-006097C686F6}';
  {$EXTERNALSYM FMTID_MUSIC}
  PIDSI_ARTIST    = 2;
  {$EXTERNALSYM PIDSI_ARTIST}
  PIDSI_SONGTITLE = 3;
  {$EXTERNALSYM PIDSI_SONGTITLE}
  PIDSI_ALBUM     = 4;
  {$EXTERNALSYM PIDSI_ALBUM}
  PIDSI_YEAR      = 5;
  {$EXTERNALSYM PIDSI_YEAR}
  PIDSI_COMMENT   = 6;
  {$EXTERNALSYM PIDSI_COMMENT}
  PIDSI_TRACK     = 7;
  {$EXTERNALSYM PIDSI_TRACK}
  PIDSI_GENRE     = 11;
  {$EXTERNALSYM PIDSI_GENRE}
  PIDSI_LYRICS    = 12;
  {$EXTERNALSYM PIDSI_LYRICS}

const
  FMTID_DRM: TGUID = '{AEAC19E4-89AE-4508-B9B7-BB867ABEE2ED}';
  {$EXTERNALSYM FMTID_DRM}
  PIDDRSI_PROTECTED   = 2;
  {$EXTERNALSYM PIDDRSI_PROTECTED}
  PIDDRSI_DESCRIPTION = 3;
  {$EXTERNALSYM PIDDRSI_DESCRIPTION}
  PIDDRSI_PLAYCOUNT   = 4;
  {$EXTERNALSYM PIDDRSI_PLAYCOUNT}
  PIDDRSI_PLAYSTARTS  = 5;
  {$EXTERNALSYM PIDDRSI_PLAYSTARTS}
  PIDDRSI_PLAYEXPIRES = 6;
  {$EXTERNALSYM PIDDRSI_PLAYEXPIRES}

//  FMTID_VideoSummaryInformation property identifiers
const
  FMTID_Video: TGUID = '{64440491-4c8b-11d1-8b70-080036b11a03}';
  {$EXTERNALSYM FMTID_Video}
  PIDVSI_STREAM_NAME   = $00000002; // "StreamName", VT_LPWSTR
  {$EXTERNALSYM PIDVSI_STREAM_NAME}
  PIDVSI_FRAME_WIDTH   = $00000003; // "FrameWidth", VT_UI4
  {$EXTERNALSYM PIDVSI_FRAME_WIDTH}
  PIDVSI_FRAME_HEIGHT  = $00000004; // "FrameHeight", VT_UI4
  {$EXTERNALSYM PIDVSI_FRAME_HEIGHT}
  PIDVSI_TIMELENGTH    = $00000007; // "TimeLength", VT_UI4, milliseconds
  {$EXTERNALSYM PIDVSI_TIMELENGTH}
  PIDVSI_FRAME_COUNT   = $00000005; // "FrameCount". VT_UI4
  {$EXTERNALSYM PIDVSI_FRAME_COUNT}
  PIDVSI_FRAME_RATE    = $00000006; // "FrameRate", VT_UI4, frames/millisecond
  {$EXTERNALSYM PIDVSI_FRAME_RATE}
  PIDVSI_DATA_RATE     = $00000008; // "DataRate", VT_UI4, bytes/second
  {$EXTERNALSYM PIDVSI_DATA_RATE}
  PIDVSI_SAMPLE_SIZE   = $00000009; // "SampleSize", VT_UI4
  {$EXTERNALSYM PIDVSI_SAMPLE_SIZE}
  PIDVSI_COMPRESSION   = $0000000A; // "Compression", VT_LPWSTR
  {$EXTERNALSYM PIDVSI_COMPRESSION}
  PIDVSI_STREAM_NUMBER = $0000000B; // "StreamNumber", VT_UI2
  {$EXTERNALSYM PIDVSI_STREAM_NUMBER}

//  FMTID_AudioSummaryInformation property identifiers
const
  FMTID_Audio: TGUID = '{64440490-4c8b-11d1-8b70-080036b11a03}';
  {$EXTERNALSYM FMTID_Audio}
  PIDASI_FORMAT        = $00000002; // VT_BSTR
  {$EXTERNALSYM PIDASI_FORMAT}
  PIDASI_TIMELENGTH    = $00000003; // VT_UI4, milliseconds
  {$EXTERNALSYM PIDASI_TIMELENGTH}
  PIDASI_AVG_DATA_RATE = $00000004; // VT_UI4,  Hz
  {$EXTERNALSYM PIDASI_AVG_DATA_RATE}
  PIDASI_SAMPLE_RATE   = $00000005; // VT_UI4,  bits
  {$EXTERNALSYM PIDASI_SAMPLE_RATE}
  PIDASI_SAMPLE_SIZE   = $00000006; // VT_UI4,  bits
  {$EXTERNALSYM PIDASI_SAMPLE_SIZE}
  PIDASI_CHANNEL_COUNT = $00000007; // VT_UI4
  {$EXTERNALSYM PIDASI_CHANNEL_COUNT}
  PIDASI_STREAM_NUMBER = $00000008; // VT_UI2
  {$EXTERNALSYM PIDASI_STREAM_NUMBER}
  PIDASI_STREAM_NAME   = $00000009; // VT_LPWSTR
  {$EXTERNALSYM PIDASI_STREAM_NAME}
  PIDASI_COMPRESSION   = $0000000A; // VT_LPWSTR
  {$EXTERNALSYM PIDASI_COMPRESSION}

const
  FMTID_ControlPanel: TGUID = '{305CA226-D286-468e-B848-2B2E8E697B74}';
  {$EXTERNALSYM FMTID_ControlPanel}
  PID_CONTROLPANEL_CATEGORY = 2;
  {$EXTERNALSYM PID_CONTROLPANEL_CATEGORY}

const
  FMTID_Volume: TGUID = '{9B174B35-40FF-11d2-A27E-00C04FC30871}';
  {$EXTERNALSYM FMTID_Volume}
  PID_VOLUME_FREE       = 2;
  {$EXTERNALSYM PID_VOLUME_FREE}
  PID_VOLUME_CAPACITY   = 3;
  {$EXTERNALSYM PID_VOLUME_CAPACITY}
  PID_VOLUME_FILESYSTEM = 4;
  {$EXTERNALSYM PID_VOLUME_FILESYSTEM}

const
  FMTID_Share: TGUID = '{D8C3986F-813B-449c-845D-87B95D674ADE}';
  {$EXTERNALSYM FMTID_Share}
  PID_SHARE_CSC_STATUS = 2;
  {$EXTERNALSYM PID_SHARE_CSC_STATUS}

const
  FMTID_Link: TGUID = '{B9B4B3FC-2B51-4a42-B5D8-324146AFCF25}';
  {$EXTERNALSYM FMTID_Link}
  PID_LINK_TARGET = 2;
  {$EXTERNALSYM PID_LINK_TARGET}

const
  FMTID_Query: TGUID = '{49691c90-7e17-101a-a91c-08002b2ecda9}';
  {$EXTERNALSYM FMTID_Query}
  PID_QUERY_RANK = 2;
  {$EXTERNALSYM PID_QUERY_RANK}

const
  FMTID_SummaryInformation: TGUID = '{f29f85e0-4ff9-1068-ab91-08002b27b3d9}';
  {$EXTERNALSYM FMTID_SummaryInformation}
  FMTID_DocumentSummaryInformation: TGUID = '{d5cdd502-2e9c-101b-9397-08002b2cf9ae}';
  {$EXTERNALSYM FMTID_DocumentSummaryInformation}
  FMTID_MediaFileSummaryInformation: TGUID = '{64440492-4c8b-11d1-8b70-080036b11a03}';
  {$EXTERNALSYM FMTID_MediaFileSummaryInformation}
  FMTID_ImageSummaryInformation: TGUID = '{6444048f-4c8b-11d1-8b70-080036b11a03}';
  {$EXTERNALSYM FMTID_ImageSummaryInformation}

// imgguids.h line 75

// Property sets
const
  FMTID_ImageInformation: TGUID = '{e5836cbe-5eef-4f1d-acde-ae4c43b608ce}';
  {$EXTERNALSYM FMTID_ImageInformation}
  FMTID_JpegAppHeaders: TGUID = '{1c4afdcd-6177-43cf-abc7-5f51af39ee85}';
  {$EXTERNALSYM FMTID_JpegAppHeaders}

// objbase.h line 390
const
  STGFMT_STORAGE  = 0;
  {$EXTERNALSYM STGFMT_STORAGE}
  STGFMT_NATIVE   = 1;
  {$EXTERNALSYM STGFMT_NATIVE}
  STGFMT_FILE     = 3;
  {$EXTERNALSYM STGFMT_FILE}
  STGFMT_ANY      = 4;
  {$EXTERNALSYM STGFMT_ANY}
  STGFMT_DOCFILE  = 5;
  {$EXTERNALSYM STGFMT_DOCFILE}
// This is a legacy define to allow old component to builds
  STGFMT_DOCUMENT = 0;
  {$EXTERNALSYM STGFMT_DOCUMENT}

// objbase.h line 913
const
  Ole32Lib = 'ole32.dll';

type
  tagSTGOPTIONS = record
    usVersion: Word;             // Versions 1 and 2 supported
    reserved: Word;              // must be 0 for padding
    ulSectorSize: Cardinal;      // docfile header sector size (512)
    pwcsTemplateFile: PWideChar; // version 2 or above
  end;
  {$EXTERNALSYM tagSTGOPTIONS}
  STGOPTIONS = tagSTGOPTIONS;
  {$EXTERNALSYM STGOPTIONS}
  PSTGOPTIONS = ^STGOPTIONS;
  {$EXTERNALSYM PSTGOPTIONS}

function StgCreateStorageEx(const pwcsName: PWideChar; grfMode: DWORD;
  stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
  riid: PGUID; out stgOpen: IInterface): HResult; stdcall;
{$EXTERNALSYM StgCreateStorageEx}

function StgOpenStorageEx(const pwcsName: PWideChar; grfMode: DWORD;
  stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
  riid: PGUID; out stgOpen: IInterface): HResult; stdcall;
{$EXTERNALSYM StgOpenStorageEx}


implementation
uses
  strUtils,   System.Character;

constructor EJclWin32Error.Create(const Msg: string);
begin
  FLastError := GetLastError;
  FLastErrorMsg := SysErrorMessage(FLastError);
  inherited CreateResFmt(@RsWin32Error, [FLastErrorMsg, FLastError, NativeLineBreak, Msg]);
end;

constructor EJclWin32Error.CreateFmt(const Msg: string; const Args: array of const);
begin
  FLastError := GetLastError;
  FLastErrorMsg := SysErrorMessage(FLastError);
  inherited CreateResFmt(@RsWin32Error, [FLastErrorMsg, FLastError, NativeLineBreak, Format(Msg, Args)]);
end;

constructor EJclWin32Error.CreateRes(Ident: Integer);
begin
  FLastError := GetLastError;
  FLastErrorMsg := SysErrorMessage(FLastError);
  inherited CreateResFmt(@RsWin32Error, [FLastErrorMsg, FLastError, NativeLineBreak, LoadStr(Ident)]);
end;

constructor EJclWin32Error.CreateRes(ResStringRec: PResStringRec);
begin
  FLastError := GetLastError;
  FLastErrorMsg := SysErrorMessage(FLastError);
  inherited CreateResFmt(@RsWin32Error, [FLastErrorMsg, FLastError, NativeLineBreak, LoadResString(ResStringRec)]);
end;

// memory initialization
procedure ResetMemory(out P; Size: Longint);
begin
  if Size > 0 then
  begin
    Byte(P) := 0;
    FillChar(P, Size, 0);
  end;
end;


{$IFDEF MSWINDOWS}
function IsDirectory(const FileName: string): Boolean;
var
  R: DWORD;
begin
  R := GetFileAttributes(PChar(FileName));
  Result := (R <> DWORD(-1)) and ((R and FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;
{$ENDIF MSWINDOWS}
{$IFDEF UNIX}
function IsDirectory(const FileName: string; ResolveSymLinks: Boolean): Boolean;
var
  Buf: TStatBuf64;
begin
  Result := False;
  if GetFileStatus(FileName, Buf, ResolveSymLinks) = 0 then
    Result := S_ISDIR(Buf.st_mode);
end;
{$ENDIF UNIX}

function StrEnsurePrefix(const Prefix, Text: string): string;
var
  PrefixLen: SizeInt;
begin
  PrefixLen := Length(Prefix);
  if Copy(Text, 1, PrefixLen) = Prefix then
    Result := Text
  else
    Result := Prefix + Text;
end;


//=== Path manipulation ======================================================

function PathAddSeparator(const Path: string): string;
begin
  Result := Path;
  if (Path = '') or (Path[Length(Path)] <> DirDelimiter) then
    Result := Path + DirDelimiter;
end;

function PathRemoveSeparator(const Path: string): string;
var
  L: Integer;
begin
  L := Length(Path);
  if (L <> 0) and (Path[L] = DirDelimiter) then
    Result := Copy(Path, 1, L - 1)
  else
    Result := Path;
end;

function PathAddExtension(const Path, Extension: string): string;
begin
  Result := Path;
  // (obones) Extension may not contain the leading dot while ExtractFileExt
  // always returns it. Hence the need to use StrEnsurePrefix for the SameText
  // test to return an accurate value.
  if (Path <> '') and (Extension <> '') and
    not SameText(ExtractFileExt(Path), StrEnsurePrefix('.', Extension)) then
  begin
    if Path[Length(Path)] = '.' then
      Delete(Result, Length(Path), 1);
    if Extension[1] = '.' then
      Result := Result + Extension
    else
      Result := Result + '.' + Extension;
  end;
end;

function PathAppend(const Path, Append: string): string;
var
  PathLength: Integer;
  B1, B2: Boolean;
begin
  if Append = '' then
    Result := Path
  else
  begin
    PathLength := Length(Path);
    if PathLength = 0 then
      Result := Append
    else
    begin
      // The following code may look a bit complex but all it does is add Append to Path ensuring
      // that there is one and only one path separator character between them
      B1 := Path[PathLength] = DirDelimiter;
      B2 := Append[1] = DirDelimiter;
      if B1 and B2 then
        Result := Copy(Path, 1, PathLength - 1) + Append
      else
      begin
        if not (B1 or B2) then
          Result := Path + DirDelimiter + Append
        else
          Result := Path + Append;
      end;
    end;
  end;
end;

function PathBuildRoot(const Drive: Byte): string;
begin
  {$IFDEF UNIX}
  Result := DirDelimiter;
  {$ENDIF UNIX}
  {$IFDEF MSWINDOWS}
  // Remember, Win32 only allows 'a' to 'z' as drive letters (mapped to 0..25)
  if Drive < 26 then
    Result := Char(Drive + 65) + ':\'
  else
    raise EJclPathError.CreateResFmt(@RsPathInvalidDrive, [IntToStr(Drive)]);
  {$ENDIF MSWINDOWS}
end;


{$IFDEF MSWINDOWS}
{ TODO -cHelp : Donator (incl. TFileSystemFlag[s]): Robert Rossmair }

function GetVolumeFileSystemFlags(const Volume: string): TFileSystemFlags;
const
  FileSystemFlags: array [TFileSystemFlag] of DWORD =
    ( FILE_CASE_SENSITIVE_SEARCH,   // fsCaseSensitive
      FILE_CASE_PRESERVED_NAMES,    // fsCasePreservedNames
      FILE_UNICODE_ON_DISK,         // fsSupportsUnicodeOnDisk
      FILE_PERSISTENT_ACLS,         // fsPersistentACLs
      FILE_FILE_COMPRESSION,        // fsSupportsFileCompression
      FILE_VOLUME_QUOTAS,           // fsSupportsVolumeQuotas
      FILE_SUPPORTS_SPARSE_FILES,   // fsSupportsSparseFiles
      FILE_SUPPORTS_REPARSE_POINTS, // fsSupportsReparsePoints
      FILE_SUPPORTS_REMOTE_STORAGE, // fsSupportsRemoteStorage
      FILE_VOLUME_IS_COMPRESSED,    // fsVolumeIsCompressed
      FILE_SUPPORTS_OBJECT_IDS,     // fsSupportsObjectIds
      FILE_SUPPORTS_ENCRYPTION,     // fsSupportsEncryption
      FILE_NAMED_STREAMS,           // fsSupportsNamedStreams
      FILE_READ_ONLY_VOLUME         // fsVolumeIsReadOnly
    );
var
  MaximumComponentLength, Flags: Cardinal;
  Flag: TFileSystemFlag;
begin
  Flags := 0;
  MaximumComponentLength := 0;
  if not GetVolumeInformation(PChar(PathAddSeparator(Volume)), nil, 0, nil,
    MaximumComponentLength, Flags, nil, 0) then
    RaiseLastOSError;
  Result := [];
  for Flag := Low(TFileSystemFlag) to High(TFileSystemFlag) do
    if (Flags and FileSystemFlags[Flag]) <> 0 then
      Include(Result, Flag);
end;

{$ENDIF MSWINDOWS}

procedure GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: string);
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := GetModuleHandle(PChar(ModuleName));
    if ModuleHandle = 0 then
    begin
      ModuleHandle := SafeLoadLibrary(PChar(ModuleName));
      if ModuleHandle = 0 then
        raise EJclError.CreateResFmt(@RsELibraryNotFound, [ModuleName]);
    end;
    P := GetProcAddress(ModuleHandle, PChar(ProcName));
    if not Assigned(P) then
      raise EJclError.CreateResFmt(@RsEFunctionNotFound, [ModuleName, ProcName]);
  end;
end;


type
  TSetVolumeMountPointW = function (lpszVolumeMountPoint, lpszVolumeName: LPCWSTR): BOOL; stdcall;

var
  _SetVolumeMountPointW: TSetVolumeMountPointW = nil;

function SetVolumeMountPointW(lpszVolumeMountPoint, lpszVolumeName: LPCWSTR): BOOL;
begin
  GetProcedureAddress(Pointer(@_SetVolumeMountPointW), kernel32, 'SetVolumeMountPointW');
  Result := _SetVolumeMountPointW(lpszVolumeMountPoint, lpszVolumeName);
end;

type
  TDeleteVolumeMountPointW = function (lpszVolumeMountPoint: LPCWSTR): BOOL; stdcall;

var
  _DeleteVolumeMountPointW: TDeleteVolumeMountPointW = nil;

function DeleteVolumeMountPointW(lpszVolumeMountPoint: LPCWSTR): BOOL;
begin
  GetProcedureAddress(Pointer(@_DeleteVolumeMountPointW), kernel32, 'DeleteVolumeMountPointW');
  Result := _DeleteVolumeMountPointW(lpszVolumeMountPoint);
end;

type
  TGetVolumeNameForVolumeMountPointW = function (lpszVolumeMountPoint: LPCWSTR;
  lpszVolumeName: LPWSTR; cchBufferLength: DWORD): BOOL; stdcall;

var
  _GetVolumeNameForVolMountPointW: TGetVolumeNameForVolumeMountPointW = nil;

function GetVolumeNameForVolumeMountPointW(lpszVolumeMountPoint: LPCWSTR;
  lpszVolumeName: LPWSTR; cchBufferLength: DWORD): BOOL;
begin
  GetProcedureAddress(Pointer(@_GetVolumeNameForVolMountPointW), kernel32, 'GetVolumeNameForVolumeMountPointW');
  Result := _GetVolumeNameForVolMountPointW(lpszVolumeMountPoint, lpszVolumeName, cchBufferLength);
end;

{$IFDEF MSWINDOWS}
function DirectoryExists(const Name: string): Boolean;
var
  R: DWORD;
begin
  R := GetFileAttributes(PChar(Name));
  Result := (R <> DWORD(-1)) and ((R and FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;
{$ENDIF MSWINDOWS}

{$IFDEF UNIX}
function DirectoryExists(const Name: string; ResolveSymLinks: Boolean): Boolean;
begin
  Result := IsDirectory(Name, ResolveSymLinks);
end;
{$ENDIF UNIX}

// This routine is copied from FileCtrl.pas to avoid dependency on that unit.
// See the remark at the top of this section

function ForceDirectories(Name: string): Boolean;
var
  ExtractPath: string;
begin
  Result := True;
  if Length(Name) = 0 then
    raise EJclFileUtilsError.CreateRes(@RsCannotCreateDir);
  Name := PathRemoveSeparator(Name);
  {$IFDEF MSWINDOWS}
  ExtractPath := ExtractFilePath(Name);
  if ((Length(Name) = 2) and (Copy(Name, 2,1) = ':')) or DirectoryExists(Name) or (ExtractPath = Name) then
    Exit;
  {$ENDIF MSWINDOWS}
  {$IFDEF UNIX}
  if (Length(Name) = 0) or DirectoryExists(Name) then
    Exit;
  ExtractPath := ExtractFilePath(Name);
  {$ENDIF UNIX}
  Result := (ExtractPath = '') or ForceDirectories(ExtractPath);
  if Result then
  begin
    {$IFDEF MSWINDOWS}
    SetLastError(ERROR_SUCCESS);
    {$ENDIF MSWINDOWS}
    Result := Result and CreateDir(Name);
    {$IFDEF MSWINDOWS}
    Result := Result or (GetLastError = ERROR_ALREADY_EXISTS);
    {$ENDIF MSWINDOWS}
  end;
end;

type
  TBackupSeek = function (hFile: THandle; dwLowBytesToSeek, dwHighBytesToSeek: DWORD;
    out lpdwLowByteSeeked, lpdwHighByteSeeked: DWORD;
    var lpContext: Pointer): BOOL; stdcall;

var
  _BackupSeek: TBackupSeek = nil;

function BackupSeek(hFile: THandle; dwLowBytesToSeek, dwHighBytesToSeek: DWORD;
  out lpdwLowByteSeeked, lpdwHighByteSeeked: DWORD;
  var lpContext: Pointer): BOOL;
begin
  GetProcedureAddress(Pointer(@_BackupSeek), kernel32, 'BackupSeek');
  Result := _BackupSeek(hFile, dwLowBytesToSeek, dwHighBytesToSeek, lpdwLowByteSeeked, lpdwHighByteSeeked, lpContext);
end;

type
  TStgCreateStorageEx = function (const pwcsName: PWideChar; grfMode: DWORD;
    stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
    riid: PGUID; out stgOpen: IInterface): HResult; stdcall;

var
  _StgCreateStorageEx: TStgCreateStorageEx = nil;

function StgCreateStorageEx(const pwcsName: PWideChar; grfMode: DWORD;
  stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
  riid: PGUID; out stgOpen: IInterface): HResult;
begin
  GetProcedureAddress(Pointer(@_StgCreateStorageEx), Ole32Lib, 'StgCreateStorageEx');
  Result := _StgCreateStorageEx(pwcsName, grfMode, stgfmt, grfAttrs, pStgOptions, reserved2, riid, stgOpen);
end;

type
  TStgOpenStorageEx = function (const pwcsName: PWideChar; grfMode: DWORD;
    stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
    riid: PGUID; out stgOpen: IInterface): HResult; stdcall;

var
  _StgOpenStorageEx: TStgOpenStorageEx = nil;

function StgOpenStorageEx(const pwcsName: PWideChar; grfMode: DWORD;
  stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: PSTGOPTIONS; reserved2: Pointer;
  riid: PGUID; out stgOpen: IInterface): HResult;
begin
  GetProcedureAddress(Pointer(@_StgOpenStorageEx), Ole32Lib, 'StgOpenStorageEx');
  Result := _StgOpenStorageEx(pwcsName, grfMode, stgfmt, grfAttrs, pStgOptions, reserved2, riid, stgOpen);
end;


end.
