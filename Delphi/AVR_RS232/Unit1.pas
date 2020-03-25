unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ComDrv32;

type
  TfAVR = class(TForm)
    Tekst: TMemo;
    rgCommPort: TRadioGroup;
    bConnect: TButton;
    rgDataBits: TRadioGroup;
    rgParity: TRadioGroup;
    rgStopBits: TRadioGroup;
    bDisconnect: TButton;
    rgHandshake: TRadioGroup;
    rgBaudRate: TRadioGroup;
    gbDTR: TGroupBox;
    bSetDTR: TButton;
    bClearDTR: TButton;
    gbRTS: TGroupBox;
    bSetRTS: TButton;
    bClearRTS: TButton;
    tbPWM1A: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    tbPWM1B: TTrackBar;
    Label3: TLabel;
    tbPWM2: TTrackBar;
    CommPortDriver: TCommPortDriver;
    StatusBar: TStatusBar;
    lDutyCycle1A: TLabel;
    lDutyCycle1B: TLabel;
    lDutyCycle2: TLabel;
    Label7: TLabel;
    cbTOP1A: TCheckBox;
    cbTOP1B: TCheckBox;
    cbTOP2: TCheckBox;
    lDutyCycle1AByte: TLabel;
    lDutyCycle1BByte: TLabel;
    lDutyCycle2Byte: TLabel;
    procedure tbPWM1AChange(Sender: TObject);
    procedure tbPWM1BChange(Sender: TObject);
    procedure tbPWM2Change(Sender: TObject);

    procedure rgCommPortClick(Sender: TObject);
    procedure rgBaudRateClick(Sender: TObject);
    procedure rgDataBitsClick(Sender: TObject);
    procedure rgParityClick(Sender: TObject);
    procedure rgStopBitsClick(Sender: TObject);
    procedure rgHandshakeClick(Sender: TObject);
    procedure bSetDTRClick(Sender: TObject);
    procedure bClearDTRClick(Sender: TObject);
    procedure bSetRTSClick(Sender: TObject);
    procedure bClearRTSClick(Sender: TObject);

    procedure bConnectClick(Sender: TObject);
    procedure bDisconnectClick(Sender: TObject);
    procedure CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbTOP1AClick(Sender: TObject);
    procedure cbTOP1BClick(Sender: TObject);
    procedure cbTOP2Click(Sender: TObject);
  private
    RxBuffer : array[0..1024] of byte;
    procedure applyCommSettings;
    procedure sendPWMData(PWM, dutyCycle: byte);
    function DutyCyclePercent(tbPos, tbMax : integer) : string;
    procedure disableControls;
    procedure enableControls;
  public
    { Public declarations }
  end;

var
  fAVR: TfAVR;

implementation
{$R *.dfm}

procedure TfAVR.FormCreate(Sender: TObject);
begin
  disableControls
end;

procedure TfAVR.FormDestroy(Sender: TObject);
begin
  if CommPortDriver.Connect then CommPortDriver.Disconnect
end;



procedure TfAVR.applyCommSettings;
var wasConnected: boolean;
begin
  wasConnected := CommPortDriver.Connected;
  // de CommPortDriver moet niet verbonden zijn tijdens wijzigingen aan de instellingen
  if wasConnected then bDisconnectClick(nil);
  // instellingen overnemen
  CommPortDriver.ComPort := TComPortNumber(ord(rgCommPort.ItemIndex));
  rgBaudRateClick(nil);
  rgDataBitsClick(nil);
  rgParityClick(nil);
  rgStopBitsClick(nil);
  rgHandshakeClick(nil);
  // (opnieuw) verbinden
  if wasConnected then bConnectClick(nil);
end;

procedure TfAVR.rgCommPortClick(Sender: TObject);
begin
  //
end;

procedure TfAVR.rgBaudRateClick(Sender: TObject);
begin
  CommPortDriver.ComPortSpeed := TComPortBaudRate(rgBaudRate.ItemIndex+1);
end;

procedure TfAVR.rgDataBitsClick(Sender: TObject);
begin
  CommPortDriver.ComPortDataBits := TComPortDataBits(rgDataBits.ItemIndex);
end;

procedure TfAVR.rgParityClick(Sender: TObject);
begin
  CommPortDriver.ComPortParity := TComPortParity(rgParity.ItemIndex);
end;

procedure TfAVR.rgStopBitsClick(Sender: TObject);
begin
  CommPortDriver.ComPortStopBits := TComPortStopBits(rgStopBits.ItemIndex);
end;

procedure TfAVR.rgHandshakeClick(Sender: TObject);
begin
  case rgHandshake.ItemIndex of
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

procedure TfAVR.bSetDTRClick(Sender: TObject);
begin
  CommPortDriver.ToggleDTR(true);
end;

procedure TfAVR.bClearDTRClick(Sender: TObject);
begin
  CommPortDriver.ToggleDTR(false);
end;

procedure TfAVR.bSetRTSClick(Sender: TObject);
begin
  CommPortDriver.ToggleRTS(true);
end;

procedure TfAVR.bClearRTSClick(Sender: TObject);
begin
  CommPortDriver.ToggleRTS(false);
end;

procedure TfAVR.bConnectClick(Sender: TObject);
begin
  // instellingen toewijzen/gebruiken
  ApplyCommSettings;
  // verbinden....
  if CommPortDriver.Connect then begin
    enableControls;
    StatusBar.SimpleText := 'Connected';
    Tekst.Lines.Add('RS232-connection established to the AVR AT90S8535');
    Tekst.SetFocus;
  end else begin // Error !
    disableControls;
    StatusBar.SimpleText := 'Error: could not connect. Check COM port settings and try again.';
    MessageBeep(0);
  end;
end;

procedure TfAVR.bDisconnectClick(Sender: TObject);
begin
  CommPortDriver.Disconnect;
  disableControls;
  StatusBar.SimpleText := 'Disconnected';
  Tekst.Lines.Add('RS232-connection closed to the AVR AT90S8535');
end;

// ontavngen data als tekst afbeelden.
procedure TfAVR.CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
var i: integer;
    s: string;
begin
  if DataSize<=SizeOf(RxBuffer) then begin
    Move(DataPtr, RxBuffer[0], DataSize);
    i := 0;
    s := '';
    repeat
      case RxBuffer[i] of
        13: begin {een nieuwe regel beginnen}
               Tekst.Lines.Add(s);
               s := '';
             end;
        10: {nix doen};
      else
        s := s + IntToHex(RxBuffer[i],2) +' ';
      end;
      Inc(i);
    until i>DataSize;
    if s<>'' then Tekst.Lines.Add(s);
  end else begin
    StatusBar.SimpleText := 'Too much data received for processing';
    Tekst.Lines.Add('Too much data received from the AVR AT90S8535 for processing');
  end;
end;


procedure TfAVR.sendPWMData(PWM, dutyCycle: byte);
var PWMData : array[0..1] of byte;
begin
  if CommPortDriver.Connected then begin
    PWMData[0] := PWM;
    PWMData[1] := dutyCycle;
    CommPortDriver.SendData(@PWMData[0],2);
  end;
end;

function TfAVR.DutyCyclePercent(tbPos,tbMax : integer): string;
var procent: single;
begin
  if tbMax = 0 then procent := 0.0 else procent := tbPos/tbMax*100.0;
  Result := IntToStr(round(procent)) + ' %'
end;


procedure TfAVR.tbPWM1AChange(Sender: TObject);
begin
  tbPWM1A.SelEnd := tbPWM1A.Position;
  lDutyCycle1AByte.Caption := IntToStr(tbPWM1A.Position);
  lDutyCycle1A.Caption := DutyCyclePercent(tbPWM1A.Position, tbPWM1A.Max);
  // indien men verbonden is, de PWM verzenden naar de AVR
  sendPWMData($1A, tbPWM1A.Position);
end;

procedure TfAVR.tbPWM1BChange(Sender: TObject);
begin
  tbPWM1B.SelEnd := tbPWM1B.Position;
  lDutyCycle1BByte.Caption := IntToStr(tbPWM1B.Position);
  lDutyCycle1B.Caption := DutyCyclePercent(tbPWM1B.Position, tbPWM1B.Max);
  // indien men verbonden is, de PWM verzenden naar de AVR
  sendPWMData($1B, tbPWM1B.Position);
end;

procedure TfAVR.tbPWM2Change(Sender: TObject);
begin
  tbPWM2.SelEnd := tbPWM2.Position;
  lDutyCycle2Byte.Caption := IntToStr(tbPWM2.Position);
  lDutyCycle2.Caption := DutyCyclePercent(tbPWM2.Position, tbPWM2.Max);
  // indien men verbonden is, de PWM verzenden naar de AVR
  sendPWMData($2, tbPWM2.Position);
end;


procedure TfAVR.cbTOP1AClick(Sender: TObject);
begin
  if cbTOP1A.Checked then tbPWM1A.Max := 255
                     else tbPWM1A.Max := 254;
end;

procedure TfAVR.cbTOP1BClick(Sender: TObject);
begin
  if cbTOP1B.Checked then tbPWM1B.Max := 255
                     else tbPWM1B.Max := 254;
end;

procedure TfAVR.cbTOP2Click(Sender: TObject);
begin
  if cbTOP2.Checked then tbPWM2.Max := 255
                    else tbPWM2.Max := 254;
end;


procedure TfAVR.disableControls;
begin
  // controls die niet gebruikt mogen worden, uitschakelen.
  tbPWM1A.Enabled := false;
  tbPWM1B.Enabled := false;
  tbPWM2.Enabled := false;
  // de knoppen
  bDisconnect.Enabled := false;
  bConnect.Enabled := true;
end;

procedure TfAVR.enableControls;
begin
  // controls die weer gebruikt mogen worden, inschakelen.
  tbPWM1A.Enabled := true;
  tbPWM1B.Enabled := true;
  tbPWM2.Enabled := true;
  // de knoppen
  bConnect.Enabled := false;
  bDisconnect.Enabled := true;
end;




end.
