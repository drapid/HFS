unit HFS.Macroses;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface
uses
  Windows, Types, UITypes,
  Dialogs, serverLib, srvClassesLib;

procedure runTimedEvents(fs: TFileServer);

function setItemMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function deleteItemMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function notifyMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function saveVFSMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function saveCFGMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function setCFGMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function vfsSelectMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function getINIMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function setINIMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function dialogMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function execMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function clipboardMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function focusMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function playMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function createFileFingerPrintMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
function speedLimitPerAddressMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;

implementation
uses
  sysUtils, StrUtils, iniFiles, Graphics, forms, clipbrd, MMsystem,
  DateUtils,
  RegExpr,
  RnQtrayLib,
  fileLib, parserLib, srvUtils,
  scriptLib,
  hfsGlobal,
  main, utilLib, hfsVars,
  srvConst, srvVars;

var
  timedEventsRE: TRegExpr;
  eventsLastRun: TstringToIntHash;


  function par(pars: TPars; idx: integer; const name: String=''; doTrim: Boolean=TRUE): UnicodeString; overload;
  begin
    if ((idx < 0) or (idx >= pars.count)) and (name = '') then
      Exit('');
    try
      result := pars.parExNE(idx, name, doTrim)
     except
      result := ''
    end
  end;

  function par(pars: TPars; const name: String=''; doTrim: Boolean=TRUE; const defval: String=''): String; overload;
  begin
    result := defval;

    if name > '' then
      begin
        if pars.TryGetValue(name, Result) then
          if doTrim then
            Exit(trim(result))
           else
            exit;
      end;
  end;


   {$IFNDEF HFS_SERVICE}
  function stringToTrayMessageType(const s: String): TBalloonIconType;
  begin
    if compareText(s,'warning') = 0 then
      result:= bitWarning
    else if compareText(s,'error') = 0 then
      result:= bitError
    else if compareText(s,'info') = 0 then
      result:= bitInfo
    else
      result:= bitNone
  end; // stringTotrayMessageType
   {$ENDIF ~HFS_SERVICE}

  function getVarSpace(md: TmacroData; var varname: String): THashedStringList;
  begin
    varname:=trim(varname);
    if ansiStartsStr(G_VAR_PREFIX, varname) then
      begin
      result := staticVars;
      delete(varname,1,length(G_VAR_PREFIX));
      end
    else if assigned(md.cd) then
      result:=md.cd.vars
    else if assigned(md.tempVars) then
      result:=md.tempVars
    else
      raise Exception.create('no namespace available');
  end; // getVarSpace

  // this is for cases where normally we want a "clean" output. User can still detect outcome by using macro "length".
  // Reason for having this instead of using in place a simple "result:=if_(cond, ' ')" is to evidence our purpose. It's not faster or cleaner, it's more semantic.
function setItemMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  function isFalse(const s: String): boolean;
  begin result:=(s='') or (strToFloatDef(s,1) = 0) end;

  function isTrue(const s: String): boolean; inline;
  begin result := not isFalse(s) end;

  procedure setItem();
  var
    f: Tfile;
    act: TfileAction;

    function get(const prefix: String): TStringDynArray;
    begin
    result := onlyExistentAccounts(split(';', pars.parEx(prefix+FILEACTION2STR[act])));
    uniqueStrings(result);
    end;

    function getb(const prefix: String; val: TStringDynArray): Boolean;
    var
      s: String;
    begin
      Result := pars.parExistVal(prefix+FILEACTION2STR[act], s);
      if Result then
       begin
         val := onlyExistentAccounts(split(';', s));
         uniqueStrings(val);
       end;
    end;

    procedure setAttr(a: TfileAttribute; const parName: String);
    var
      v: String;
    begin
      if pars.parExistVal(parname, v) then
        try
          if isTrue(v) then
            include(f.flags, a)
          else
            exclude(f.flags, a);
        except end;
    end; // setAttr
  var
    v: String;
    valSA: TStringDynArray;
  begin
    result := '';
    f := fs.findFileByURL(pars[0], cbData.folder);
    if f = NIL then exit; // doesn't exist

    if pars.parExistVal('comment', v) then
     try
       f.setDynamicComment(fs.LP, macroDequote(v))
     except end;
    if pars.parExistVal('name', v) then
      f.name := v;
    if pars.parExistVal('resource', v) then
      f.resource := v;
    if pars.parExistVal('diff template', v) then
      f.diffTpl := v;
    if pars.parExistVal('files filter', v) then
      f.filesFilter := v;
    if pars.parExistVal('folders filter', v) then
      f.foldersFilter := v;

    // following commands make no sense on temporary items
    if freeIfTemp(f) then exit;

    setAttr(FA_HIDDEN, 'hide');
    setAttr(FA_HIDDENTREE, 'hide tree');
    setAttr(FA_DONT_LOG, 'no log');
    setAttr(FA_ARCHIVABLE, 'archivable');
    setAttr(FA_BROWSABLE, 'browsable');
    setAttr(FA_DL_FORBIDDEN, 'download forbidden');
    if f.isFolder() then
      try f.dontCountAsDownloadMask := pars.parEx('not as download') except end
    else
      setAttr(FA_DONT_COUNT_AS_DL, 'not as download');

    for act:=low(act) to high(act) do
      begin
        valSA := NIL;
        if getB('', valSA) then
          f.accounts[act] := valSA;
        if getB('add ', valSA) then
          addUniqueArray(f.accounts[act], valSA);
        if getB('remove ', valSA) then
          removeArray(f.accounts[act], valSA);
      end;
    VFSmodified:=TRUE;
   {$IFNDEF HFS_SERVICE}
    mainfrm.filesBox.repaint();
   {$ENDIF ~HFS_SERVICE}
  end; // setItem
begin
  setItem;
end;

function deleteItemMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
  procedure spaceIf(condition:boolean);
  begin if condition then result:=' ' else result:='' end;

  procedure deleteItem();
  var
    f: Tfile;
  begin
    f:= fs.findFileByURL(p);
    spaceIf(assigned(f)); // so you can know if something really has been deleted
    if f = NIL then
      exit; // doesn't exist
   {$IFDEF HFS_SERVICE}
   fs.removeFile(f);
   {$ELSE ~HFS_SERVICE}
    mainFrm.remove(f);
   {$ENDIF HFS_SERVICE}
    VFSmodified := TRUE;
  end; // deleteItem
begin
  if pars.count > 0 then
    p := pars[0] // a handy shortcut for the first parameter
   else
    p := '';
  deleteItem;
end;


function notifyMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  function parF(idx:integer):extended; overload;
  begin result:=strToFloat(par(pars, idx)) end;

  function parF(idx:integer; def:extended):extended; overload;
  begin result:=strToFloatDef(par(pars, idx), def) end;

  function parF(const name: String; def: extended): extended; overload;
  begin result:=strToFloatDef(par(pars, name), def) end;
begin
  tray.balloon(pars[0], parF('timeout',3), stringTotrayMessageType(par(pars, 'type')), par(pars, 'title'));
  result:='';
end;

function saveVFSMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
begin
  mainfrm.saveVFS(first(par(pars, 0), lastFileOpen));
  result:='';
end;

function saveCFGMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
begin
  p := par(pars, 0);
  if p = 'file' then
    savemode:=SM_FILE
   else if p = 'registry' then
    savemode:=SM_USER
   else if p = 'global registry' then
    savemode:=SM_SYSTEM;
  mainFrm.saveCFG();
  result:='';
end;

function setCFGMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  procedure trueIf(condition:boolean);
  begin if condition then result:='1' else result:='' end;

var
  p: String;
begin
  p := par(pars, 0);
  trueIf(mainfrm.setcfg(p))
end;

function vfsSelectMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  // this is for cases where normally we want a "clean" output. User can still detect outcome by using macro "length".
  // Reason for having this instead of using in place a simple "result:=if_(cond, ' ')" is to evidence our purpose. It's not faster or cleaner, it's more semantic.
  procedure spaceIf(condition:boolean);
  begin if condition then result:=' ' else result:='' end;
var
  p, s: String;
begin
  p := par(pars, 0);
          if pars.count = 0 then
            try
              result:= fs.url(mainFrm.selectedFile)
             except
              result := ''
            end
          else if p = 'next' then
            if mainFrm.selectedFile = NIL then
              spaceIf(FALSE)
            else
              begin
              with mainFrm.filesBox do
                selected := selected.getNext();
              spaceIf(TRUE);
              end
          else
            try
              s := pars.parEx('path');
              spaceIf(FALSE);
              mainFrm.filesBox.selected := fs.findFilebyURL(s, NIL, FALSE).node;
              spaceIf(TRUE);
            except end;
end;

function getINIMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
begin
  p := par(pars, 0);
  result := getKeyFromString(mainFrm.getCfg(), p)
end;

function setINIMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
begin
  p := par(pars, 0);
  result:='';
  mainfrm.setCfg(p);
end;

function dialogMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
  procedure dialog();
  type
      t_s2c = record s: String; val: byte; end;
  const
    STR2CODE: array [1..7] of t_s2c = (
      (s:'okcancel=1'; val: 1),
      (s:'yesno=4'; val: 4),
      (s:'yesnocancel=3'; val: 3),
      (s:'error=16'; val: 16),
      (s:'question=32'; val: 32),
      (s:'warning=48'; val: 48),
      (s:'information=64'; val: 64)
    );
  var
    code: integer;
    decode: TStringDynArray;
    d2: string;
    buttons, icon: boolean;
  begin
    decode := split(' ', par(pars, 1));
    code:=0;
    for var d in decode do
     begin
      d2 := d + '=';
      for var s in STR2CODE do
        if ansiStartsStr(d2, s.s) then
          inc(code, s.val);
     end;
    buttons := code AND 15 > 0;
    icon:=code SHR 4 > 0;
    if not icon and buttons then
      inc(code, MB_ICONQUESTION);
    case msgDlg(p, code, par(pars, 2)) of
      MRYES, MROK: result := if_(buttons, '1'); // if only OK button is available, then return nothing
      MRCANCEL: result := if_(code and MB_YESNOCANCEL = MB_YESNOCANCEL, 'cancel'); // for the YESNOCANCEL, we return cancel to allow to tell NO from CANCEL
      else result:='';
      end;
  end; // dialog
begin
  p := par(pars, 0);
  dialog()
end;

function execMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
const
  name = 'exec';

  // this is for cases where normally we want a "clean" output. User can still detect outcome by using macro "length".
  // Reason for having this instead of using in place a simple "result:=if_(cond, ' ')" is to evidence our purpose. It's not faster or cleaner, it's more semantic.
  procedure spaceIf(condition:boolean);
  begin if condition then result:=' ' else result:='' end;
  function parF(const name:string; def:extended):extended; overload;
  begin result:=strToFloatDef(par(pars, name), def) end;

  procedure macroError(const msg: String);
  begin result := '<div class=macroerror>macro error: '+name+nonEmptyConcat('<br>',msg)+'</div>' end;

  procedure deprecatedMacro(const what: String=''; const instead: String='');
  begin
    fs.add2Log('WARNING, deprecated macro: '+first(what, name)+nonEmptyConcat(' - Use instead: ',instead), NIL, clRed);
  end;

  procedure unsatisfied(b: Boolean=TRUE);
  begin
    if b then
      macroError('cannot be used here')
  end;

  function satisfied(p:pointer):boolean;
  begin
    result := assigned(p);
    unsatisfied(not result);
  end;

  function setVar(varname: String; const value: String; space: THashedStringList=NIL): Boolean;
  var
    o: Tobject;
    i: integer;
  begin
  result:=FALSE;
  if space = NIL then
    space := getVarSpace(cbData^, varname);
  if not satisfied(space) then exit;
  i:=space.indexOfName(varname);
  if i < 0 then
    if value = '' then exit(TRUE) // all is good the way it is
    else i:=space.add(varname+'='+value)
  else
    if value > '' then // in case of empty value, there's no need to assign, because we are going to delete it (after we cleared the bound object)
      space.valueFromIndex[i]:=value;

  assert(i >= 0, 'setVar: i<0');
  // the previous hash object linked to this data is not valid anymore, and must be freed
  o:=space.objects[i];
  freeAndNIL(o);

  if value = '' then
    space.delete(i)
  else
    space.objects[i]:=NIL;
  result:=TRUE;
  end; // setVar


var
  p: String;
  s: string;
  code: cardinal;
  unnamedPars: integer; // this is a guessing of the number of unnamed parameters. just guessing because there's no true distinction between a parameter "value" named "key", and parameter "key=value"
begin
  p := par(pars, 0);
  s := macroDequote(par(pars, 1));
  if fileOrDirExists(s) then
    s := quoteIfAnyChar(' ', s)
  else
    begin
      unnamedPars := 0;
      if pars.count > 0 then
        for var i:=0 to pars.count-1 do
          begin
            pars[i] := xtpl(pars[i], ['{:|:}','|']);
            if (i = unnamedPars) and (pos('=',pars[i]) = 0) then
              inc(unnamedPars);
          end;

      if unnamedPars < 2 then
        s := '';
    end;

  if pars.parExist('out') or pars.parExist('timeout') or pars.parExist('exit code') then
    try
      spaceIf(captureExec(macroDequote(p)+nonEmptyConcat(' ', s), s, code, parF('timeout', 2)));
      try
        setVar(pars.parEx('exit code'), intToStr(code))
       except
      end;
      setVar(pars.parEx('out'), s);
    except end
  else
    spaceIf(exec(macroDequote(p), s))
end;

function clipboardMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  function getVar(varname:string):string; overload;
  begin result:=getVarSpace(cbData^, varname).values[varname] end;
var
  p: String;
begin
  p := par(pars, 0);
  if p = '' then
    begin
      result := clipboard.asText
    end
   else
    begin
      try
        setClip(getVar(pars.parEx('var')))
       except
        setClip(p)
      end;
      result:='';
    end;
end;

function focusMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
begin
        application.restore();
        application.bringToFront();
        result:='';
end;

function playMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
begin
  p := par(pars, 0);
  result:='';
  playSound(Pchar(p), 0, SND_ALIAS or SND_ASYNC or SND_NOWAIT);
end;

function createFileFingerPrintMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
var
  p: String;
begin
  p := par(pars, 0);
  result := createFingerprint(p)
end;

function speedLimitPerAddressMacro(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars2; cbData: PMacroData): UnicodeString;
  function parF(idx:integer):extended; overload;
  begin result:=strToFloat(par(pars, idx)) end;
var
  p: String;
begin
  p := par(pars, 0);
  begin
    if pars.count = 1 then
      setSpeedLimitIP(parF(0))
    else
      with objByIp(fs.htSrv, p) do
        begin
        limiter.maxSpeed := round(parF(1)*1000);
        customizedLimiter := TRUE;
        end;
    result:='';
  end
end;


procedure runTimedEvents(fs: TFileServer);
var
  i: integer;
  sections: TStringDynArray;
  re: TRegExpr;
  t, last: Tdatetime;
  section: string;

  procedure handleAtCase();
  begin
    t := now();
    // we must convert the format, because our structure stores integers
    last := unixToDatetime(eventsLastRun.getInt(section));
    if (strToInt(re.match[9]) = hourOf(t))
    and (strtoInt(re.match[10]) = minuteOf(t))
    and (t-last > 0.9) then // approximately 1 day should have been passed
      begin
       eventsLastRun.setInt(section, datetimeToUnix(t));
       runEventScript(fs, section);
      end;
  end; // handleAtCase

  procedure handleEveryCase();
  begin
  // get the XX:YY:ZZ
  t:=strToFloat(re.match[2]);
  if re.match[4] > '' then
    t:=t*60+strToInt(re.match[4]);
  if re.match[6] > '' then
    t:=t*60+strToInt(re.match[6]);
  // apply optional time unit
  case upcase(getFirstChar(re.match[7])) of
    'M': t:=t*60;
    'H': t:=t*60*60;
    end;
  // now "t" is in seconds
  if (t > 0) and ((clock div 10) mod round(t) = 0) then
    runEventScript(fs, section);
  end; // handleEveryCase

begin
  if timedEventsRE = NIL then
   begin
    timedEventsRE:=TRegExpr.create; // yes, i know, this is never freed, but we need it for the whole time
    timedEventsRE.expression:='(every +([0-9.]+)(:(\d+)(:(\d+))?)? *([a-z]*))|(at (\d+):(\d+))';
    timedEventsRE.modifierI:=TRUE;
    timedEventsRE.compile();
   end;

  if eventsLastRun = NIL then
    eventsLastRun:=TstringToIntHash.create; // yes, i know, this is never freed, but we need it for the whole time

  re := timedEventsRE; // a shortcut
  sections := eventScripts.getSections();
  if length(sections) > 0 then
   for i:=0 to length(sections)-1 do
    begin
     section := sections[i]; // a shortcut
     if not re.exec(section) then
       continue;

      try
        if re.match[1] > '' then
          handleEveryCase()
         else
          handleAtCase();
       except
      end; // ignore exceptions
    end;
end; // runTimedEvents


end.
