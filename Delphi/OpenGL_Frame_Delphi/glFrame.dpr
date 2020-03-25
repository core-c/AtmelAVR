program glTest;

uses
  Forms,
  uForm in 'uForm.pas' {fGL};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfGL, fGL);
  Application.Run;
end.
