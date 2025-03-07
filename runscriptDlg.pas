unit runscriptDlg;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TrunScriptFrm = class(TForm)
    resultBox: TMemo;
    Panel1: TPanel;
    runBtn: TButton;
    autorunChk: TCheckBox;
    sizeLbl: TLabel;
    procedure runBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  runScriptFrm: TrunScriptFrm;

implementation

{$R *.dfm}

uses
  main, srvUtils, srvClassesLib, scriptLib, RDFileUtil;

procedure TrunScriptFrm.runBtnClick(Sender: TObject);
var
  tpl: Ttpl;
begin
  tpl := Ttpl.create;
  try
    try
      tpl.fullText := loadFile(tempScriptFilename);
      resultBox.text := runScript(mainFrm.fileSrv, tpl[''], NIL, tpl);
      sizeLbl.Caption := getTill(':', sizeLbl.Caption)+': '+intToStr(length(resultBox.text));
     except
      on e:Exception do
        resultBox.text:=e.message
    end;
   finally
    tpl.free
  end;
end;

end.
