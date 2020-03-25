unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComDrv32, StdCtrls, ComCtrls;

type
  TTWI_Buffer = packed record
    UserCommand,
    DataByte1,
    DataByte2: Byte
  end;


  TfLCDBabe = class(TForm)
    CommPortDriver: TCommPortDriver;
    Memo1: TMemo;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    LCD00: TButton;
    LCD01: TButton;
    LCD02: TButton;
    LCD03: TButton;
    LCD04: TButton;
    LCD05: TButton;
    LCD06: TButton;
    LCD07: TButton;
    LCD08: TButton;
    LCD09: TButton;
    LCD0A: TButton;
    LCD0B: TButton;
    LCD0C: TButton;
    LCD0D: TButton;
    LCD0E: TButton;
    LCD0F: TButton;
    LCD10: TButton;
    LCD11: TButton;
    LCD12: TButton;
    LCD00_data1: TEdit;
    LCD04_data1: TEdit;
    LCD05_data1: TEdit;
    LCD06_data1_2: TEdit;
    LCD0A_data1: TEdit;
    LCD0F_data1: TEdit;
    LCD10_data2: TEdit;
    LCD10_data1: TEdit;
    LCD12_data1: TEdit;
    LCD12_data2: TEdit;
    Input: TEdit;
    TextToLCD: TButton;
    Received: TMemo;
    Label21: TLabel;
    StatusBar: TStatusBar;
    bOpen: TButton;
    bClose: TButton;
    Label22: TLabel;
    Label23: TLabel;
    Transmitted: TMemo;
    procedure CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
    procedure TextToLCDClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bOpenClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure LCD00Click(Sender: TObject);
    procedure LCD01Click(Sender: TObject);
    procedure LCD02Click(Sender: TObject);
    procedure LCD03Click(Sender: TObject);
    procedure LCD04Click(Sender: TObject);
    procedure LCD05Click(Sender: TObject);
    procedure LCD06Click(Sender: TObject);
    procedure LCD07Click(Sender: TObject);
    procedure LCD08Click(Sender: TObject);
    procedure LCD09Click(Sender: TObject);
    procedure LCD0AClick(Sender: TObject);
    procedure LCD0BClick(Sender: TObject);
    procedure LCD0CClick(Sender: TObject);
    procedure LCD0DClick(Sender: TObject);
    procedure LCD0EClick(Sender: TObject);
    procedure LCD0FClick(Sender: TObject);
    procedure LCD10Click(Sender: TObject);
    procedure LCD11Click(Sender: TObject);
    procedure LCD12Click(Sender: TObject);
  private
    TWI_OUT_Buffer: TTWI_Buffer;
    procedure ApplyCOMMSettings;
    procedure OpenCOMMPort;
    procedure CloseCOMMPort;
    function CommSettingsToStr: string;
    //--------------------------------------------------------------------------
    procedure rgCommPortClick;
    procedure rgDataBitsClick;
    procedure rgParityClick;
    procedure rgStopBitsClick;
    procedure rgBaudRateClick;
    procedure rgHandshakeClick;
    procedure bSetDTRClick;
    procedure bClearDTRClick;
    procedure bSetRTSClick;
    procedure bClearRTSClick;
    procedure Button1Click;      //cancel
    procedure bOpenRS232Click;   //open
    //--------------------------------------------------------------------------
    function IsByte(Stringy: string; var aByte: Byte): boolean;
    function IsWord(Stringy: string; var aLowByte,aHighByte: Byte): boolean;
  public
    function SendTo_I2C_Slave(UserCommand:Byte; DataByte1:integer = -1; DataByte2:integer = -1): boolean;
  end;

var
  fLCDBabe: TfLCDBabe;

implementation
uses uRS232;
{$R *.dfm}


procedure TfLCDBabe.FormDestroy(Sender: TObject);
begin
  if CommPortDriver.Connected then CommPortDriver.Disconnect
end;


procedure TfLCDBabe.ApplyCOMMSettings;
var wasConnected: boolean;
begin
  wasConnected := CommPortDriver.Connected;
  // de CommPortDriver moet niet verbonden zijn tijdens wijzigingen aan de instellingen
  if wasConnected then CloseCOMMPort;
  // instellingen overnemen
  CommPortDriver.ComPort := TComPortNumber(ord(fRS232.rgCommPort.ItemIndex));
  rgBaudRateClick;
  rgDataBitsClick;
  rgParityClick;
  rgStopBitsClick;
  rgHandshakeClick;
  // (opnieuw) verbinden
  if wasConnected then OpenCOMMPort;
end;

procedure TfLCDBabe.OpenCOMMPort;
begin
  // extra form met instellingen oproepen
  if fRS232.showModal <> mrOK then exit;
  // instellingen toewijzen/gebruiken
  ApplyCommSettings;
  // verbinden....
  if CommPortDriver.Connect then begin
    StatusBar.SimpleText := 'RS232 Connected '+ CommSettingsToStr;
    fLCDBabe.SetFocus;
  end else begin // Error !
    StatusBar.SimpleText := 'Error: could not connect';
    MessageBeep(0);
  end;
end;

procedure TfLCDBabe.CloseCOMMPort;
begin
  if CommPortDriver.Connected then CommPortDriver.Disconnect;
  StatusBar.SimpleText := 'Disconnected';
end;

procedure TfLCDBabe.CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
var i: integer;
    b: byte;
begin
  For i:=0 to DataSize-1 do begin
    b := byte(pointer(integer(DataPtr)+i)^);
    Received.Lines.Add(IntToStr(b) +'   $'+ IntToHex(b,2) +'    '+ Chr(b));
  end;
end;

function TfLCDBabe.CommSettingsToStr: string;
begin
  Result := Result + ' to ';
  case TComPortNumber(ord(fRS232.rgCommPort.ItemIndex)) of
    pnCOM1 : Result := Result + 'COM1';
    pnCOM2 : Result := Result + 'COM2';
    pnCOM3 : Result := Result + 'COM3';
    pnCOM4 : Result := Result + 'COM4';
  end;
  Result := Result + ' @ ';
  case TComPortBaudRate(fRS232.rgBaudRate.ItemIndex+1) of
    br110 : Result := Result + '110 bps';
    br300 : Result := Result + '300 bps';
    br600 : Result := Result + '600 bps';
    br1200 : Result := Result + '1200 bps';
    br2400 : Result := Result + '2400 bps';
    br4800 : Result := Result + '4800 bps';
    br9600 : Result := Result + '9600 bps';
    br14400 : Result := Result + '14400 bps';
    br19200 : Result := Result + '19200 bps';
    br38400 : Result := Result + '38400 bps';
    br56000 : Result := Result + '56000 bps';
    br57600 : Result := Result + '57600 bps';
    br115200 : Result := Result + '115200 bps';
  end;
  Result := Result + ' (';
  case TComPortDataBits(fRS232.rgDataBits.ItemIndex) of
    db5BITS : Result := Result + '5';
    db6BITS : Result := Result + '6';
    db7BITS : Result := Result + '7';
    db8BITS : Result := Result + '8';
  end;
  case TComPortParity(fRS232.rgParity.ItemIndex) of
    ptNONE : Result := Result + 'N';
    ptODD : Result := Result + 'O';
    ptEVEN : Result := Result + 'E';
    ptMARK : Result := Result + 'M';
    ptSPACE : Result := Result + 'S';
  end;
  case TComPortStopBits(fRS232.rgStopBits.ItemIndex) of
    sb1BITS : Result := Result + '1';
    sb1HALFBITS : Result := Result + '1½';
    sb2BITS : Result := Result + '2';
  end;
  Result := Result + ')';
end;


//------------------------------------------------------------------------------


procedure TfLCDBabe.rgCommPortClick;
begin
  //
end;

procedure TfLCDBabe.rgDataBitsClick;
begin
  CommPortDriver.ComPortDataBits := TComPortDataBits(fRS232.rgDataBits.ItemIndex);
end;

procedure TfLCDBabe.rgParityClick;
begin
  CommPortDriver.ComPortParity := TComPortParity(fRS232.rgParity.ItemIndex);
end;

procedure TfLCDBabe.rgStopBitsClick;
begin
  CommPortDriver.ComPortStopBits := TComPortStopBits(fRS232.rgStopBits.ItemIndex);
end;

procedure TfLCDBabe.rgBaudRateClick;
begin
  CommPortDriver.ComPortSpeed := TComPortBaudRate(fRS232.rgBaudRate.ItemIndex+1);
end;

procedure TfLCDBabe.rgHandshakeClick;
begin
  case fRS232.rgHandshake.ItemIndex of
    0: // none
      begin
        CommPortDriver.ComPortHwHandshaking := hhNone;
        CommPortDriver.ComPortSwHandshaking := shNone;
      end;
    1: // RTS/CTS
      begin
        CommPortDriver.ComPortHwHandshaking := hhRTSCTS;
        CommPortDriver.ComPortSwHandshaking := shNone;
      end;
    2: // XON/XOFF
      begin
        CommPortDriver.ComPortHwHandshaking := hhNone;
        CommPortDriver.ComPortSwHandshaking := shXONXOFF;
      end;
    3: // RTS/CTS + XON/XOFF
      begin
        CommPortDriver.ComPortHwHandshaking := hhRTSCTS;
        CommPortDriver.ComPortSwHandshaking := shXONXOFF;
      end;
  end;
end;

procedure TfLCDBabe.bSetDTRClick;
begin
  CommPortDriver.ToggleDTR(true);
end;

procedure TfLCDBabe.bClearDTRClick;
begin
  CommPortDriver.ToggleDTR(false);
end;

procedure TfLCDBabe.bSetRTSClick;
begin
  CommPortDriver.ToggleRTS(true);
end;

procedure TfLCDBabe.bClearRTSClick;
begin
  CommPortDriver.ToggleRTS(false);
end;

procedure TfLCDBabe.Button1Click;      //cancel
begin
  //
end;

procedure TfLCDBabe.bOpenRS232Click;   //open
begin
  //
end;


//------------------------------------------------------------------------------


procedure TfLCDBabe.bOpenClick(Sender: TObject);
begin
  // open de RS232-verbinding
  OpenCOMMPort;
  bOpen.Enabled := not CommPortDriver.Connected;
  bClose.Enabled := CommPortDriver.Connected;
end;

procedure TfLCDBabe.bCloseClick(Sender: TObject);
begin
  // sluit de RS232-verbinding
  CloseCOMMPort;
  bOpen.Enabled := not CommPortDriver.Connected;
  bClose.Enabled := CommPortDriver.Connected;
end;

function TfLCDBabe.SendTo_I2C_Slave(UserCommand:Byte; DataByte1:integer = -1; DataByte2:integer = -1): boolean;
var BufferLen: integer;
    s: string;
begin
  if not CommPortDriver.Connected then exit;
  // De gegevens in de TWI-buffer plaatsen voor verzending
  TWI_OUT_Buffer.UserCommand := UserCommand;
  BufferLen := 1;
  s := IntToHex(UserCommand,2);
  // De eerste data byte (eventueel opgegeven)
  if DataByte1 <> -1 then begin
    TWI_OUT_Buffer.DataByte1 := DataByte1 mod 255;
    BufferLen := 2;
    s := s +' '+ IntToHex(DataByte1,2);
  end;
  // De tweede data byte (eventueel opgegeven)
  if DataByte2 <> -1 then begin
    TWI_OUT_Buffer.DataByte2 := DataByte2 mod 255;
    BufferLen := 3;
    s := s +' '+ IntToHex(DataByte2,2);
  end;
  // verzenden over RS232
  CommPortDriver.SendData(@TWI_OUT_Buffer, BufferLen);
  // de memo bijwerken op het form
  Transmitted.Lines.Add(s);
  //
  SendTo_I2C_Slave := true;
end;


//------------------------------------------------------------------------------


function TfLCDBabe.IsByte(Stringy: string; var aByte: Byte): boolean;
var Code: integer;
    Nummer: word;
begin
  Result := false;
  Val(Stringy, Nummer, Code);
  if Code=0 then
    If Nummer <= 255 then begin
      aByte := Nummer;
      Result := true;
    end;
end;

function TfLCDBabe.IsWord(Stringy: string; var aLowByte, aHighByte: Byte): boolean;
var Code: integer;
    Nummer: word;
begin
  Result := false;
  Val(Stringy, Nummer, Code);
  if Code=0 then begin
    aLowByte := Nummer mod 256;
    aHighByte := Nummer div 256;
    Result := true;
  end;
end;


procedure TfLCDBabe.LCD00Click(Sender: TObject);
var Data1: Byte;
begin
  // LCD character lineprint
  if isByte(LCD00_data1.Text, Data1) then SendTo_I2C_Slave($00,Data1);
end;

procedure TfLCDBabe.LCD01Click(Sender: TObject);
begin
  // LCD-cursor naar volgende regel
  SendTo_I2C_Slave($01);
end;

procedure TfLCDBabe.LCD02Click(Sender: TObject);
begin
  // LCD-cursor Home
  SendTo_I2C_Slave($02);
end;

procedure TfLCDBabe.LCD03Click(Sender: TObject);
begin
  // LCD-cursor naar EndOfLine
  SendTo_I2C_Slave($03);
end;

procedure TfLCDBabe.LCD04Click(Sender: TObject);
var Data1: Byte;
begin
  // LCD print hex.nibble (b3-0)
  if isByte(LCD04_data1.Text, Data1) then SendTo_I2C_Slave($04,Data1);
end;

procedure TfLCDBabe.LCD05Click(Sender: TObject);
var Data1: Byte;
begin
  // LCD print hex.byte
  if isByte(LCD05_data1.Text, Data1) then SendTo_I2C_Slave($05,Data1);
end;

procedure TfLCDBabe.LCD06Click(Sender: TObject);
var Data1, Data2: Byte;
begin
  // LCD print hex.word
  if IsWord(LCD06_data1_2.Text, Data1,Data2) then SendTo_I2C_Slave($06,Data1,Data2);
end;

procedure TfLCDBabe.LCD07Click(Sender: TObject);
begin
  // LCD Scroll-Up
  SendTo_I2C_Slave($07);
end;

procedure TfLCDBabe.LCD08Click(Sender: TObject);
begin
  // LCD Backspace
  SendTo_I2C_Slave($08);
end;

procedure TfLCDBabe.LCD09Click(Sender: TObject);
begin
  // LCD Delete
  SendTo_I2C_Slave($09);
end;

procedure TfLCDBabe.LCD0AClick(Sender: TObject);
var Data1: Byte;
begin
  // LCD Insert character
  if isByte(LCD0A_data1.Text, Data1) then SendTo_I2C_Slave($0A,Data1);
end;

procedure TfLCDBabe.LCD0BClick(Sender: TObject);
begin
  // LCD pijl omhoog
  SendTo_I2C_Slave($0B);
end;

procedure TfLCDBabe.LCD0CClick(Sender: TObject);
begin
  // LCD pijl omlaag
  SendTo_I2C_Slave($0C);
end;

procedure TfLCDBabe.LCD0DClick(Sender: TObject);
begin
  // LCD pijl naar links
  SendTo_I2C_Slave($0D);
end;

procedure TfLCDBabe.LCD0EClick(Sender: TObject);
begin
  // LCD pijl naar rechts
  SendTo_I2C_Slave($0E);
end;

procedure TfLCDBabe.LCD0FClick(Sender: TObject);
var Data1: Byte;
begin
  // LCD Fill
  if isByte(LCD0F_data1.Text, Data1) then SendTo_I2C_Slave($0F,Data1);
end;

procedure TfLCDBabe.LCD10Click(Sender: TObject);
var Data1, Data2: Byte;
begin
  // LCD Clear Line from (X,Y)
  if isByte(LCD10_data1.Text, Data1) and isByte(LCD10_data2.Text, Data1) then SendTo_I2C_Slave($10,Data1,Data2);
end;

procedure TfLCDBabe.LCD11Click(Sender: TObject);
begin
  // LCD SplashScreen
  SendTo_I2C_Slave($11);
end;

procedure TfLCDBabe.LCD12Click(Sender: TObject);
var Data1, Data2: Byte;
begin
  // LCD Set Cursor (X,Y)
  if isByte(LCD12_data1.Text, Data1) and isByte(LCD12_data2.Text, Data1) then SendTo_I2C_Slave($12,Data1,Data2);
end;



procedure TfLCDBabe.TextToLCDClick(Sender: TObject);
var i: integer;
    s: string;
begin
  if not CommPortDriver.Connected then exit;
  s := Input.Text;
  for i:=0 to Length(s) do SendTo_I2C_Slave($00,Ord(s[i]));
end;



end.
