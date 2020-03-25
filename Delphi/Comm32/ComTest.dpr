program ComTest;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  ComDrv32 in 'ComDrv32.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'TCommPortDriver Test';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
