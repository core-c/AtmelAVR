program AVR_RS232_2;

uses
  Forms,
  Unit1 in 'Unit1.pas' {fAVR},
  uRS232 in 'uRS232.pas' {fRS232},
  uAbout in 'uAbout.pas' {fAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'AVR_RS232_2';
  Application.CreateForm(TfAVR, fAVR);
  Application.CreateForm(TfRS232, fRS232);
  Application.CreateForm(TfAbout, fAbout);
  Application.Run;
end.
