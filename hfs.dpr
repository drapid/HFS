{
Copyright (C) 2002-2014  Massimo Melina (www.rejetto.com)

This file is part of HFS ~ HTTP File Server.

    HFS is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HFS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with HSG; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
{$INCLUDE defs.inc }
{ $SetPEOptFlags $100 } //IMAGE_DLLCHARACTERISTICS_NX_COMPAT
 {$SETPEOPTFLAGS $140} // NX + ASLR
{$STRINGCHECKS OFF}
program hfs;

{$R 'data.res' 'res\data.rc'}

uses
  {$IFDEF EX_DEBUG}
  ftmExceptionForm,
  {$ENDIF }
  Forms,
  windows,
  types,
  hsLib in 'srv\hsLib.pas',
  RDUtils,
  sysUtils,
  main in 'main.pas' {mainFrm},
  newuserpassDlg in 'newuserpassDlg.pas' {newuserpassFrm},
  optionsDlg in 'optionsDlg.pas' {optionsFrm},
  utillib in 'utillib.pas',
  monoLib in 'lib\monoLib.pas',
  regexpr in 'lib\regexpr.pas',
  longinputDlg in 'lib\longinputDlg.pas' {longinputFrm},
  folderKindDlg in 'lib\folderKindDlg.pas' {folderKindFrm},
  shellExtDlg in 'lib\shellExtDlg.pas' {shellExtFrm},
  diffDlg in 'lib\diffDlg.pas' {diffFrm},
  purgeDlg in 'lib\purgeDlg.pas' {purgeFrm},
  ipsEverDlg in 'ipsEverDlg.pas' {ipsEverFrm},
  HSUtils in 'srv\HSUtils.pas',
  parserLib in 'srv\parserLib.pas',
  scriptLib in 'srv\scriptLib.pas',
  fileLib in 'srv\fileLib.pas',
  srvUtils in 'srv\srvUtils.pas',
  serverLib in 'srv\serverLib.pas',
  IconsLib in 'srv\IconsLib.pas' {IconsDM: TDataModule},
  srvClassesLib in 'srv\srvClassesLib.pas',
  srvConst in 'srv\srvConst.pas',
  srvVars in 'srv\srvVars.pas',
  netUtils in 'srv\netUtils.pas',
  listSelectDlg in 'listSelectDlg.pas' {listSelectFrm},
  filepropDlg in 'filepropDlg.pas' {filepropFrm},
  runscriptDlg in 'runscriptDlg.pas' {runScriptFrm},
  hfsJclOthers in 'jcl\hfsJclOthers.pas',
  hfsGlobal in 'hfsGlobal.pas',
  hfsVars in 'hfsVars.pas',
  langLib in 'langLib.pas',
  progFrmLib in 'lib\progFrmLib.pas',
  hfs.tray in 'hfs.tray.pas',
  HFS.Macroses in 'HFS.Macroses.pas';

{$R *.res}

  procedure processSlaveParams(const params: String);
  var
    ss: TStringDynArray;
  begin
    if mainfrm = NIL then
      exit;
    ss := split(#13, params);
    processParams_before(ss);
    mainfrm.processParams_after(ss);
  end;

  function isSingleInstance(): boolean;
  var
    params: TStringDynArray;
    ini, tpl: string;
  begin
    result := FALSE;
    // the -i parameter affects loadCfg()
    params := paramsAsArray();
    processParams_before(params, 'i');
    loadCfg(ini, tpl);
    chop('only-1-instance=', ini);
    if ini = '' then
      exit;
    ini := chopLine(ini);
    result := sameText(ini, 'yes');
  end; // isSingleInstance

begin
  mono.onSlaveParams := processSlaveParams;
  if not holdingKey(VK_CONTROL) then
    begin
    if not mono.init('HttpFileServer') then
      begin
      msgDlg('monoLib error: '+mono.error, MB_ICONERROR+MB_OK);
      halt(1);
      end;
    if not mono.master and isSingleInstance() then
      begin
      mono.sendParams();
      exit;
      end;
    end;
  {$IFDEF EX_DEBUG}initErrorHandler(format('HFS %s (%s)', [VERSION, VERSION_BUILD]));{$ENDIF}
  Application.Initialize();
  Application.CreateForm(TIconsDM, IconsDM);
  Application.CreateForm(TmainFrm, mainFrm);
  Application.CreateForm(TnewuserpassFrm, newuserpassFrm);
  Application.CreateForm(ToptionsFrm, optionsFrm);
  Application.CreateForm(TdiffFrm, diffFrm);
  Application.CreateForm(TipsEverFrm, ipsEverFrm);
  Application.CreateForm(TrunScriptFrm, runScriptFrm);
  mainfrm.finalInit();
  Application.Run;
  {$IFDEF EX_DEBUG}closeErrorHandler();{$ENDIF}
end.
