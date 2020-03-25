program AVR_RS232;

uses
  Forms,
  Unit1 in 'Unit1.pas' {fAVR};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'AVR_COMM';
  Application.CreateForm(TfAVR, fAVR);
  Application.Run;
end.
