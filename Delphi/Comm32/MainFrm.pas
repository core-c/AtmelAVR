{
  TCommPortDriver demo
  v1.00 15/FEB/1997 First implementation
  v1.01 19/APR/1997 Some bug fixes (in the demo)
}

unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls,

  ComDrv32;

type
  TMainForm = class(TForm)
    CommPortDriver: TCommPortDriver;
    Panel1: TPanel;
    StatusBar: TStatusBar;
    TxMemo: TMemo;
    ConnectBtn: TButton;
    DisconnectBtn: TButton;
    QuitBtn: TButton;
    ComPortRG: TRadioGroup;
    BaudRateRG: TRadioGroup;
    DataBitsRG: TRadioGroup;
    ParityRG: TRadioGroup;
    HandshakingRG: TRadioGroup;
    RxMemo: TMemo;
    Panel2: TPanel;
    Panel3: TPanel;
    ClrInMemo: TButton;
    ClrOutMemo: TButton;
    SetDTRBtn: TButton;
    ClrDTRBtn: TButton;
    SetRTSBtn: TButton;
    ClrRTSBtn: TButton;
    procedure QuitBtnClick(Sender: TObject);
    procedure TxMemoKeyPress(Sender: TObject; var Key: Char);
    procedure CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer;
      DataSize: Integer);
    procedure ConnectBtnClick(Sender: TObject);
    procedure DisconnectBtnClick(Sender: TObject);
    procedure BaudRateRGClick(Sender: TObject);
    procedure DataBitsRGClick(Sender: TObject);
    procedure ParityRGClick(Sender: TObject);
    procedure HandshakingRGClick(Sender: TObject);
    procedure ComPortRGClick(Sender: TObject);
    procedure ClrInMemoClick(Sender: TObject);
    procedure ClrOutMemoClick(Sender: TObject);
    procedure SetDTRBtnClick(Sender: TObject);
    procedure ClrDTRBtnClick(Sender: TObject);
    procedure SetRTSBtnClick(Sender: TObject);
    procedure ClrRTSBtnClick(Sender: TObject);
  private
    procedure ApplyCommSettings;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.QuitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.TxMemoKeyPress(Sender: TObject; var Key: Char);
var s: string;
begin
  if CommPortDriver.Connected then
    // Commit data only when RETURN key is pressed
    case Key of
      #13: if TxMemo.Lines.Count>0 then
           begin
             s := TxMemo.Lines[TxMemo.Lines.Count-1];
             CommPortDriver.SendData( pchar(s), length(s) );
             CommPortDriver.SendData( @Key, 1 );
           end
           else CommPortDriver.SendData( @Key, 1 );

    end;
end;

procedure TMainForm.CommPortDriverReceiveData(Sender: TObject;
  DataPtr: Pointer; DataSize: Integer);
var p: pchar;
    s: string;
begin
  // Get current line
  if RxMemo.Lines.Count <> 0 then
    s := RxMemo.Lines[RxMemo.Lines.Count-1]
  else
    s := '';
  // Parse incoming text
  p := DataPtr;
  while DataSize > 0 do
  begin
    case p^ of
      #10:; // LF
      #13: // CR - cursor to next line
        begin
          if RxMemo.Lines.Count <> 0 then
            RxMemo.Lines[RxMemo.Lines.Count-1] := s
          else
            RxMemo.Lines.Add( s );
          RxMemo.Lines.Add( '' );
          s := '';
        end;
      #8: // Backspace - delete last char
        delete( s, length(s), 1 );
      else // Any other char - add it to the current line
        s := s + p^;
    end;
    dec( DataSize );
    inc( p );
  end;
  // If current line isn't empty
  if (s<>'') then
    if RxMemo.Lines.Count <> 0 then
      // Update current line
      RxMemo.Lines[RxMemo.Lines.Count-1] := s
    else
      // New line - add it
      RxMemo.Lines.Add( s );
  RxMemo.Update;
end;

procedure TMainForm.ConnectBtnClick(Sender: TObject);
begin
  // Apply settings
  ApplyCommSettings;
  // Connect
  if CommPortDriver.Connect then
  begin
    ConnectBtn.Enabled := false;
    DisconnectBtn.Enabled := true;
    StatusBar.SimpleText := 'Connected';
    TxMemo.SetFocus;
  end
  else // Error !
    begin
      StatusBar.SimpleText := 'Error: could not connect. Check COM port settings and try again.';
      MessageBeep( 0 );
    end;
end;

procedure TMainForm.DisconnectBtnClick(Sender: TObject);
begin
  StatusBar.SimpleText := 'Disconnected';
  CommPortDriver.Disconnect;
  DisconnectBtn.Enabled := false;
  ConnectBtn.Enabled := true;
end;

procedure TMainForm.BaudRateRGClick(Sender: TObject);
begin
  CommPortDriver.ComPortSpeed := TComPortBaudRate(BaudRateRG.ItemIndex+1);
end;

procedure TMainForm.DataBitsRGClick(Sender: TObject);
begin
  CommPortDriver.ComPortDataBits := TComPortDataBits(DataBitsRG.ItemIndex);
end;

procedure TMainForm.ParityRGClick(Sender: TObject);
begin
  CommPortDriver.ComPortParity := TComPortParity(ParityRG.ItemIndex);
end;

procedure TMainForm.HandshakingRGClick(Sender: TObject);
begin
  case HandshakingRG.ItemIndex of
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

procedure TMainForm.ComPortRGClick(Sender: TObject);
begin
  // Apply com settings
  //ApplyCommSettings;
end;

procedure TMainForm.ApplyCommSettings;
var wasConnected: boolean;
begin
  wasConnected := CommPortDriver.Connected;
  // This change needs CommPortDriver not connected
  if wasConnected then
    DisconnectBtnClick( nil );

  CommPortDriver.ComPort := TComPortNumber(ord(ComPortRG.ItemIndex));
  BaudRateRGClick( nil );
  DataBitsRGClick( nil );
  ParityRGClick( nil );
  HandshakingRGClick( nil );

  // Reconnect
  if wasConnected then
    ConnectBtnClick( nil );
end;

procedure TMainForm.ClrInMemoClick(Sender: TObject);
begin
  RxMemo.Lines.Clear;
end;

procedure TMainForm.ClrOutMemoClick(Sender: TObject);
begin
  TxMemo.Lines.Clear;
end;

procedure TMainForm.SetDTRBtnClick(Sender: TObject);
begin
  CommPortDriver.ToggleDTR( true );
end;

procedure TMainForm.ClrDTRBtnClick(Sender: TObject);
begin
  CommPortDriver.ToggleDTR( false );
end;

procedure TMainForm.SetRTSBtnClick(Sender: TObject);
begin
  CommPortDriver.ToggleRTS( true );
end;

procedure TMainForm.ClrRTSBtnClick(Sender: TObject);
begin
  CommPortDriver.ToggleRTS( false );
end;

end.
