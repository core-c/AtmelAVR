unit Unit1;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ComDrv32, ActnList, Menus, ImgList;


const
  cLEDsTimeOut = 200; //ms
  // ImageList afbeeldingen
  cLED_rood    = 0;
  cLED_groen   = 2;
  cLED_blauw   = 4;
  cPijl_Omhoog = 6;
  cPijl_Omlaag = 7;

  // motor-richting
  cUp   = $00;
  cDown = $FF;

  // motor-snelheid
  cOFF = $00;

type
  TPWMRec = packed record
    // element[0] = PWM (1A, 1B of 2)     hoogste bit bepaald de richting (0 of 1)
    // element[1] = Duty-Cycle (0-255)
    // element[2] = Richting (0, 255)
    Data : array[0..2] of byte;
  end;

type
  TfAVR = class(TForm)
    MainMenu: TMainMenu;
    menuFile: TMenuItem;
    menuFileExit: TMenuItem;
    menuConnection: TMenuItem;
    menuConnectionOpen: TMenuItem;
    menuConnectionClose: TMenuItem;
    menuAbout: TMenuItem;
    ActionList: TActionList;
    ActionFileExit: TAction;
    ActionConnectionOpen: TAction;
    ActionConnectionClose: TAction;

    CommPortDriver: TCommPortDriver;
    StatusBar: TStatusBar;
    Tekst: TMemo;
    ActionAbout: TAction;
    gbPWM: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lDutyCycle1A: TLabel;
    lDutyCycle1B: TLabel;
    lDutyCycle2: TLabel;
    Label7: TLabel;
    lDutyCycle1AByte: TLabel;
    lDutyCycle1BByte: TLabel;
    lDutyCycle2Byte: TLabel;
    tbPWM1A: TTrackBar;
    tbPWM1B: TTrackBar;
    tbPWM2: TTrackBar;
    cbTOP1A: TCheckBox;
    cbTOP1B: TCheckBox;
    cbTOP2: TCheckBox;
    ImageList: TImageList;
    imgRx: TImage;
    imgTx: TImage;
    TimerRx: TTimer;
    TimerTx: TTimer;
    rgOperation: TRadioGroup;
    gbEngineRunTime: TGroupBox;
    tbDuration: TTrackBar;
    Label6: TLabel;
    lDuration: TLabel;
    TimerEngineRunTime: TTimer;
    bSetMaxDuration: TButton;
    rgMotor: TRadioGroup;
    tbM1A: TTrackBar;
    tbM1B: TTrackBar;
    tbM2: TTrackBar;
    mRx: TMemo;
    mTx: TMemo;
    Label8: TLabel;
    Label9: TLabel;
    imgRunning1A: TImage;
    imgRunning1B: TImage;
    imgRunning2: TImage;
    imgDirection1A: TImage;
    imgDirection1B: TImage;
    imgDirection2: TImage;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure ActionFileExitExecute(Sender: TObject);
    procedure ActionConnectionOpenExecute(Sender: TObject);
    procedure ActionConnectionCloseExecute(Sender: TObject);

    procedure CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);

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
    procedure cbTOP1AClick(Sender: TObject);
    procedure cbTOP1BClick(Sender: TObject);
    procedure cbTOP2Click(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
    procedure TimerTxTimer(Sender: TObject);
    procedure TimerRxTimer(Sender: TObject);
    procedure tbDurationChange(Sender: TObject);
    procedure bSetMaxDurationClick(Sender: TObject);
    procedure rgOperationClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimerEngineRunTimeTimer(Sender: TObject);
    procedure mRxDblClick(Sender: TObject);
    procedure mTxDblClick(Sender: TObject);
  private
    RxBuffer : array[0..1024] of byte;
    PWM1A_Rec, PWM1B_Rec, PWM2_Rec : TPWMRec;
    allowArrowKeys: boolean;
    procedure applyCommSettings;
    procedure sendPWMData(PWM, dutyCycle, Direction: byte);
    function DutyCyclePercent(tbPos, tbMax : integer) : string;
    procedure disableControls;
    procedure enableControls;
    function CommSettingsToStr : string;
    procedure SwitchLED(var aLED: TTimer; SwitchedOn: boolean);
  public
    { Public declarations }
  end;

var
  fAVR: TfAVR;

implementation

uses uRS232, uAbout;
{$R *.dfm}

{--- ACTIONS ------------------------------------------------------------------}
procedure TfAVR.ActionFileExitExecute(Sender: TObject);
begin
  Close
end;

procedure TfAVR.ActionConnectionOpenExecute(Sender: TObject);
begin
  // extra form met instellingen oproepen
  if fRS232.showModal <> mrOK then exit;
  // instellingen toewijzen/gebruiken
  ApplyCommSettings;
  // verbinden....
  if CommPortDriver.Connect then begin
    enableControls;
    StatusBar.SimpleText := 'Connected to '+ CommSettingsToStr;
    Tekst.Lines.Add('RS232-connection established to the AVR AT90S8535');
    fAVR.SetFocus;
  end else begin // Error !
    disableControls;
    StatusBar.SimpleText := 'Error: could not connect. Check COM port settings and try again.';
    MessageBeep(0);
  end;
end;

procedure TfAVR.ActionConnectionCloseExecute(Sender: TObject);
begin
  if CommPortDriver.Connected then CommPortDriver.Disconnect;
  disableControls;
  StatusBar.SimpleText := 'Disconnected';
  Tekst.Lines.Add('RS232-connection closed to the AVR AT90S8535');
end;

procedure TfAVR.ActionAboutExecute(Sender: TObject);
begin
  fAbout.showModal
end;
{------------------------------------------------------------------------------}




// ontvangen data als tekst afbeelden.
procedure TfAVR.CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: Integer);
var i: integer;
    s: string;
begin
  // De LED doen oplichten
  SwitchLED(TimerRx, true);
  // De bytes ontvangen
  if DataSize<=SizeOf(RxBuffer) then begin
    Move(DataPtr, RxBuffer[0], DataSize);
    i := 0;
    s := '';
    repeat
      case RxBuffer[i] of
        13: begin {een nieuwe regel beginnen}
               mRx.Lines.Add(s);
               s := '';
             end;
        10: {nix doen};
      else
        s := s + IntToHex(RxBuffer[i],2) +' ';
      end;
      Inc(i);
    until i>DataSize;
    if s<>'' then mRx.Lines.Add(s);
  end else begin
    StatusBar.SimpleText := 'Too much data received for processing';
    Tekst.Lines.Add('Too much data received from the AVR AT90S8535 for processing');
  end;
end;
{------------------------------------------------------------------------------}




procedure TfAVR.FormCreate(Sender: TObject);
begin
  // Vaste gegevens van de PWM-Data records vullen
  PWM1A_Rec.Data[0] := $1A;
  PWM1B_Rec.Data[0] := $1B;
  PWM2_Rec.Data[0] := $02;
  //
  allowArrowKeys := false;
  // De LED's afbeelden
  ImageList.Draw(imgRx.Canvas,0,0, cLED_rood);
  ImageList.Draw(imgTx.Canvas,0,0, cLED_groen);
  ImageList.Draw(imgRunning1A.Canvas,0,0, cLED_blauw);
  ImageList.Draw(imgRunning1B.Canvas,0,0, cLED_blauw);
  ImageList.Draw(imgRunning2.Canvas,0,0, cLED_blauw);
  // en de controls
  disableControls;
  rgOperation.ItemIndex := 0;
  gbEngineRunTime.Enabled := false;
  gbEngineRunTime.Visible := false;
  TimerEngineRunTime.Interval := tbDuration.Position;
end;

procedure TfAVR.FormDestroy(Sender: TObject);
begin
  if CommPortDriver.Connected then CommPortDriver.Disconnect
end;

procedure TfAVR.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case rgOperation.ItemIndex of
    1: begin
         if not CommPortDriver.Connected then exit;
         if not allowArrowKeys then exit;
//         if not (ssCtrl in Shift) then exit;
         case Key of
           33 {PgUp}: begin
                        // richting en snelheid instellen
                        case rgMotor.ItemIndex of
                          0 : begin
                                sendPWMData($1A, tbPWM1A.Position, cUp);
                                ImageList.Draw(imgDirection1A.Canvas,0,0, cPijl_Omhoog);
                              end;
                          1 : begin
                                sendPWMData($1B, tbPWM1B.Position, cUp);
                                ImageList.Draw(imgDirection1B.Canvas,0,0, cPijl_Omhoog);
                              end;
                          2 : begin
                                sendPWMData($2, tbPWM2.Position, cUp);
                                ImageList.Draw(imgDirection2.Canvas,0,0, cPijl_Omhoog);
                              end;
                        end;
                        // De LED aanschakelen
                        SwitchLED(TimerEngineRunTime, true);
                        // verder gebruik van de groupbox niet toestaan
                        gbEngineRunTime.Enabled := false;
                        allowArrowKeys := false;
                      end;
           34 {PgDn}: begin
                        // richting en snelheid instellen
                        case rgMotor.ItemIndex of
                          0 : begin
                                sendPWMData($1A, tbPWM1A.Position, cDown);
                                ImageList.Draw(imgDirection1A.Canvas,0,0, cPijl_Omlaag);
                              end;
                          1 : begin
                                sendPWMData($1B, tbPWM1B.Position, cDown);
                                ImageList.Draw(imgDirection1B.Canvas,0,0, cPijl_Omlaag);
                              end;
                          2 : begin
                                sendPWMData($2, tbPWM2.Position, cDown);
                                ImageList.Draw(imgDirection2.Canvas,0,0, cPijl_Omlaag);
                              end;
                        end;
                        // De LED aanschakelen
                        SwitchLED(TimerEngineRunTime, true);
                        // verder gebruik van de groupbox niet toestaan
                        gbEngineRunTime.Enabled := false;
                        allowArrowKeys := false;
                      end;
         end;
       end;
  end;
end;
{------------------------------------------------------------------------------}




procedure TfAVR.TimerRxTimer(Sender: TObject);
begin
  SwitchLED(TimerRx, false);
end;

procedure TfAVR.TimerTxTimer(Sender: TObject);
begin
  SwitchLED(TimerTx, false);
end;
{------------------------------------------------------------------------------}




procedure TfAVR.disableControls;
begin
  // controls die niet gebruikt mogen worden, uitschakelen.
  rgOperation.Visible := false;
  gbEngineRunTime.Visible := false;
  gbPWM.Visible := false;
  // De menu-keuzes
  ActionConnectionOpen.Enabled := true;
  ActionConnectionClose.Enabled := false;
end;

procedure TfAVR.enableControls;
begin
  // controls die weer gebruikt mogen worden, inschakelen.
  rgOperation.Visible := true;
  if rgOperation.ItemIndex = 1 then gbEngineRunTime.Visible := true;
  gbPWM.Visible := true;
  // De menu-keuzes
  ActionConnectionOpen.Enabled := false;
  ActionConnectionClose.Enabled := true;
end;

procedure TfAVR.applyCommSettings;
var wasConnected: boolean;
begin
  wasConnected := CommPortDriver.Connected;
  // de CommPortDriver moet niet verbonden zijn tijdens wijzigingen aan de instellingen
  if wasConnected then ActionConnectionCloseExecute(nil);
  // instellingen overnemen
  CommPortDriver.ComPort := TComPortNumber(ord(fRS232.rgCommPort.ItemIndex));
  rgBaudRateClick(nil);
  rgDataBitsClick(nil);
  rgParityClick(nil);
  rgStopBitsClick(nil);
  rgHandshakeClick(nil);
  // (opnieuw) verbinden
  if wasConnected then ActionConnectionOpenExecute(nil);
end;




function TfAVR.CommSettingsToStr: string;
begin
  case TComPortNumber(ord(fRS232.rgCommPort.ItemIndex)) of
    pnCOM1 : Result := 'COM1';
    pnCOM2 : Result := 'COM2';
    pnCOM3 : Result := 'COM3';
    pnCOM4 : Result := 'COM4';
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



procedure TfAVR.rgCommPortClick(Sender: TObject);
begin
  //
end;

procedure TfAVR.rgBaudRateClick(Sender: TObject);
begin
  CommPortDriver.ComPortSpeed := TComPortBaudRate(fRS232.rgBaudRate.ItemIndex+1);
end;

procedure TfAVR.rgDataBitsClick(Sender: TObject);
begin
  CommPortDriver.ComPortDataBits := TComPortDataBits(fRS232.rgDataBits.ItemIndex);
end;

procedure TfAVR.rgParityClick(Sender: TObject);
begin
  CommPortDriver.ComPortParity := TComPortParity(fRS232.rgParity.ItemIndex);
end;

procedure TfAVR.rgStopBitsClick(Sender: TObject);
begin
  CommPortDriver.ComPortStopBits := TComPortStopBits(fRS232.rgStopBits.ItemIndex);
end;

procedure TfAVR.rgHandshakeClick(Sender: TObject);
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
{------------------------------------------------------------------------------}




procedure TfAVR.sendPWMData(PWM, dutyCycle, Direction: byte);
begin
  if not CommPortDriver.Connected then exit;
  case PWM of
    $1A : begin
            if dutyCycle <> PWM1A_Rec.Data[1] then begin
              PWM1A_Rec.Data[1] := dutyCycle;
              PWM1A_Rec.Data[2] := Direction;
              CommPortDriver.SendData(@PWM1A_Rec.Data[0],SizeOf(TPWMRec));
              // De bytes afbeelden in de Tx-memo
              mTx.Lines.Add( IntToHex(PWM1A_Rec.Data[0],2) +' '+ IntToHex(PWM1A_Rec.Data[1],2) +' '+ IntToHex(PWM1A_Rec.Data[2],2) );
              // De LED doen oplichten
              SwitchLED(TimerTx, true);
            end;
          end;
    $1B : begin
            if dutyCycle <> PWM1B_Rec.Data[1] then begin
              PWM1B_Rec.Data[1] := dutyCycle;
              PWM1B_Rec.Data[2] := Direction;
              CommPortDriver.SendData(@PWM1B_Rec.Data[0],SizeOf(TPWMRec));
              // De bytes afbeelden in de Tx-memo
              mTx.Lines.Add( IntToHex(PWM1B_Rec.Data[0],2) +' '+ IntToHex(PWM1B_Rec.Data[1],2) +' '+ IntToHex(PWM1B_Rec.Data[2],2) );
              // De LED doen oplichten
              SwitchLED(TimerTx, true);
            end;
          end;
    $02 : begin
            if dutyCycle <> PWM2_Rec.Data[1] then begin
              PWM2_Rec.Data[1] := dutyCycle;
              PWM2_Rec.Data[2] := Direction;
              CommPortDriver.SendData(@PWM2_Rec.Data[0],SizeOf(TPWMRec));
              // De bytes afbeelden in de Tx-memo
              mTx.Lines.Add( IntToHex(PWM2_Rec.Data[0],2) +' '+ IntToHex(PWM2_Rec.Data[1],2) +' '+ IntToHex(PWM2_Rec.Data[2],2) );
              // De LED doen oplichten
              SwitchLED(TimerTx, true);
            end;
          end;
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
  case rgOperation.ItemIndex of
    0: begin
         // indien men verbonden is, de PWM verzenden naar de AVR
         sendPWMData($1A, tbPWM1A.Position, cUp);
       end;
    1: begin
       end;
  end;
  // Overnemen naar de mini-trackbar (indicator)
  tbM1A.SelEnd := tbPWM1A.SelEnd;
  tbM1A.Position := tbPWM1A.Position;
end;

procedure TfAVR.tbPWM1BChange(Sender: TObject);
begin
  tbPWM1B.SelEnd := tbPWM1B.Position;
  lDutyCycle1BByte.Caption := IntToStr(tbPWM1B.Position);
  lDutyCycle1B.Caption := DutyCyclePercent(tbPWM1B.Position, tbPWM1B.Max);
  case rgOperation.ItemIndex of
    0: begin
         // indien men verbonden is, de PWM verzenden naar de AVR
         sendPWMData($1B, tbPWM1B.Position, cUp);
       end;
    1: begin
       end;
  end;
  // Overnemen naar de mini-trackbar (indicator)
  tbM1B.SelEnd := tbPWM1B.SelEnd;
  tbM1B.Position := tbPWM1B.Position;
end;

procedure TfAVR.tbPWM2Change(Sender: TObject);
begin
  tbPWM2.SelEnd := tbPWM2.Position;
  lDutyCycle2Byte.Caption := IntToStr(tbPWM2.Position);
  lDutyCycle2.Caption := DutyCyclePercent(tbPWM2.Position, tbPWM2.Max);
  case rgOperation.ItemIndex of
    0: begin
         // indien men verbonden is, de PWM verzenden naar de AVR
         sendPWMData($2, tbPWM2.Position, cUp);
       end;
    1: begin
       end;
  end;
  // Overnemen naar de mini-trackbar (indicator)
  tbM2.SelEnd := tbPWM2.SelEnd;
  tbM2.Position := tbPWM2.Position;
end;


procedure TfAVR.cbTOP1AClick(Sender: TObject);
begin
  if cbTOP1A.Checked then tbPWM1A.Max := 255
                     else tbPWM1A.Max := 254;
  // Overnemen naar de mini-trackbar (indicator)
  tbM1A.Max := tbPWM1A.Max;
end;

procedure TfAVR.cbTOP1BClick(Sender: TObject);
begin
  if cbTOP1B.Checked then tbPWM1B.Max := 255
                     else tbPWM1B.Max := 254;
  // Overnemen naar de mini-trackbar (indicator)
  tbM1B.Max := tbPWM1B.Max;
end;

procedure TfAVR.cbTOP2Click(Sender: TObject);
begin
  if cbTOP2.Checked then tbPWM2.Max := 255
                    else tbPWM2.Max := 254;
  // Overnemen naar de mini-trackbar (indicator)
  tbM2.Max := tbPWM2.Max;
end;











procedure TfAVR.rgOperationClick(Sender: TObject);
begin
  // stop alle motoren
  tbPWM1A.Position := 0;
  tbPWM1B.Position := 0;
  tbPWM2.Position := 0;
  sendPWMData($1A, cOFF, cUp);
  sendPWMData($1B, cOFF, cUp);
  sendPWMData($2, cOFF, cUp);
  //
  case rgOperation.ItemIndex of
    0: begin
         gbEngineRunTime.Enabled := false;
         gbEngineRunTime.Visible := false;
         allowArrowKeys := false;
       end;
    1: begin
         gbEngineRunTime.Enabled := true;
         gbEngineRunTime.Visible := true;
         allowArrowKeys := true;
       end;
  end;
end;


procedure TfAVR.tbDurationChange(Sender: TObject);
begin
  lDuration.Caption := FloatToStr(tbDuration.Position/1000);
  TimerEngineRunTime.Interval := tbDuration.Position;
end;


procedure TfAVR.bSetMaxDurationClick(Sender: TObject);
var s: string;
    r: real;
    i: integer;
begin
  s := FloatToStr(tbDuration.Max/1000);
  s := InputBox('Engine Run Time', 'New Maximum Duration (in seconds): ',s);
  // comma's in punten omzetten (local settings negeren)
  for i:=1 to length(s) do if s[i] = '.' then s[i] := ',';
  //
  try
    r := StrToFloat(s);
    tbDuration.Max := Round(r*1000);
    tbDuration.Frequency := Round(tbDuration.Max/10);
    TimerEngineRunTime.Interval := tbDuration.Position;
  except
    // fout bij omzetten string -> real
  end;
end;


procedure TfAVR.TimerEngineRunTimeTimer(Sender: TObject);
begin
  // De LED uitschakelen
  SwitchLED(TimerEngineRunTime, false);
  // stop de motoren
  case rgMotor.ItemIndex of
    0 : begin
          sendPWMData($1A, cOFF, cUp);
          imgDirection1A.Picture := nil;
        end;
    1 : begin
          sendPWMData($1B, cOFF, cUp);
          imgDirection1B.Picture := nil;
        end;
    2 : begin
          sendPWMData($2, cOFF, cUp);
          imgDirection2.Picture := nil;
        end;
  end;
  // er mag weer op de pijltjes toetsen gedrukt worden....
  allowArrowKeys := true;
  // ....en een andere motor gekozen worden
  gbEngineRunTime.Enabled := true;
end;


procedure TfAVR.SwitchLED(var aLED: TTimer; SwitchedOn: boolean);
var ILidx: integer;
    vControl : TImage;
begin
  // De ImageListIndex bepalen
  if aLED = TTimer(TimerRx) then begin
    ILidx := cLED_rood;
    vControl := imgRx;
  end;
  if aLED = TTimer(TimerTx) then begin
    ILidx := cLED_groen;
    vControl := imgTx;
  end;
  if aLED = TTimer(TimerEngineRunTime) then begin
    ILidx := cLED_blauw;
    case rgMotor.ItemIndex of
      0 : vControl := imgRunning1A;
      1 : vControl := imgRunning1B;
      2 : vControl := imgRunning2;
    end;
  end;
  // Timer aan/uit schakelen
  if SwitchedOn then begin
    Inc(ILidx);  // De LED selecteren die aan is
    aLED.Enabled := false;
    if aLED<>TTimer(TimerEngineRunTime) then aLED.Interval := cLEDsTimeOut;
    aLED.Enabled := true;
  end else
    aLED.Enabled := false;
  // De LED tekenen
  ImageList.Draw(vControl.Canvas,0,0, ILidx);
  vControl.Invalidate;
end;


{------------------------------------------------------------------------------}
procedure TfAVR.mRxDblClick(Sender: TObject);
begin
  mRx.Lines.Clear
end;

procedure TfAVR.mTxDblClick(Sender: TObject);
begin
  mTx.Lines.Clear
end;

end.
