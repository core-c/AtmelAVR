program LCD_I2C_Slave;

uses
  Forms,
  uRS232,
  Unit1 in 'Unit1.pas' {fLCDBabe};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfLCDBabe, fLCDBabe);
  Application.CreateForm(TfRS232, fRS232);
  Application.Run;
end.
