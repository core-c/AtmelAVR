{
  +-----------------------------------------------------------------------------
  |
  | ComDrv32.pas (see ComDrv16.pas for Delphi 1.0)
  |
  | COM Port Driver for Delphi 2.0
  |
  | Written by Marco Cocco
  | Copyright (c) 1996-97 by Marco Cocco. All rights reseved.
  | Copyright (c) 1996-97 by d3k The Artisan Of Ware. All rights reseved.
  |
  | Please send comments to d3k@mdnet.it
  | URL: http://www.mdlive.com/d3k/
  |
  +-----------------------------------------------------------------------------
  | v1.00/32 - Feb 15th, 1997
  | original Delphi 2.0 implementation
  +-----------------------------------------------------------------------------
  | v1.00/16 - May 21st, 1997
  | ported to Delphi 1.0
  +-----------------------------------------------------------------------------
  | v1.02/32 - Jun 5th, 1997
  | new property: ComPortHandle
  |   > COM port device handle made public (read/write)
  | new proc: SendZString( pchar string )
  |   > send C-style strings
  | new proc: FlushBuffers( in, out: boolean )
  |   > flush incoming data buffer (if in=TRUE)
  |   > flush outcoming data buffer (if out=TRUE)
  | new property: EnableDTROnOpen: boolean
  |   > set to TRUE (default) to set DTR to high on connect and to leave
  |     it high until disconnect.
  |     set to FALSE to set DTR to low on connect and to leave it low
  | new procs: ToggleDTR( onOff: boolean )
  |            ToggleRTS( onOff: boolean )
  |   > manually set on/off DTR/RTS line. You must disable HW handshaking before
  |     using there procs. You also must set EnableDRTOnOpen to FALSE.
  |     These procs are usefull if you are driving a RS232 to RS485 converter.
  |     (Set DTR high on TX, reset it to low on end of TX)
  | new proc: function OutFreeSpace: word
  |   > returns available free space in the output data buffer or 65535
  |     if the COM port is not open
  | new property: OutputTimeout: word
  |   > timeout for output (milliseconds)
  | changed proc: function SendData( DataPtr: pointer;
  |                                  DataSize: integer ): integer
  |   > sends a block of memory. Breaks the data block in smaller blocks if it
  |     is too large to fit the available free space in the output buffer.
  |     The OutputTimeout property value is the timeout (in millisends) for
  |     one small packet being correctly sent. Returns DataSize if all ok or a
  |     value less than zero if a timeout occurred (abs(result) is the number
  |     of bytes sent).
  +-----------------------------------------------------------------------------
  |
  | * This component built up on request of Mark Kuhnke.
  | * Porting to Delphi 1.0 done up on request of Paul Para (paul@clark.com)
  |
  | Greetings to:
  |  - Igor Gitman (gitman@interlog.com)
  |      he reported me the COM1 bug (16 bit version only)
  |
  +-----------------------------------------------------------------------------
  | Do you need additional features ? Feel free to ask for it!
  +-----------------------------------------------------------------------------

  ******************************************************************************
  *   Permission to use, copy,  modify, and distribute this software and its   *
  *        documentation without fee for any purpose is hereby granted,        *
  *   provided that the above copyright notice appears on all copies and that  *
  *     both that copyright notice and this permission notice appear in all    *
  *                         supporting documentation.                          *
  *                                                                            *
  * NO REPRESENTATIONS ARE MADE ABOUT THE SUITABILITY OF THIS SOFTWARE FOR ANY *
  *    PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.   *
  *   NEITHER MARCO COCCO OR D3K SHALL BE LIABLE FOR ANY DAMAGES SUFFERED BY   *
  *                          THE USE OF THIS SOFTWARE.                         *
  ******************************************************************************
  * d3k - The Artisan Of Ware - A Marco Cocco's Company                        *
  * Casella Postale 99 - 09047 Selargius (CA) - ITALY                          *
  * Phone +39 70 846091 (Italian Speaking)  Fax +39 70 848331                  *
  ******************************************************************************

  ------------------------------------------------------------------------------
   Check our site for the last release of this code: http://www.mdlive.com/d3k/
  ------------------------------------------------------------------------------
  Other Dr Kokko's components:
    - TFLXPlayer (play FLI/FLC animations) - *UNSUPPORTED* *V2.0 COMING SOON*
    - TCommPortDriver (send/received data to/from COM ports - Delphi 1.0)
    - TD3KBitmappedLabel (label with bitmapped font support)
    - TO97Menus (MS Office 97 like menus) (**)
    - TExplorerTreeView, TExploterListView (make your own disk explorer)
      (Explorer Clone source code included!) (**)

    (**) = COMING SOON (as on Jun 5th, 1997)

    Check our site for new components !
  ------------------------------------------------------------------------------
}

unit ComDrv32;

interface

uses
  Windows, Messages, SysUtils, Classes, Forms;

type
  // COM Port Baud Rates
  TComPortBaudRate = ( br110, br300, br600, br1200, br2400, br4800,
                       br9600, br14400, br19200, br38400, br56000,
                       br57600, br115200{v1.02: removed ->, br128000, br256000} );
  // COM Port Numbers
  TComPortNumber = ( pnCOM1, pnCOM2, pnCOM3, pnCOM4 );
  // COM Port Data bits
  TComPortDataBits = ( db5BITS, db6BITS, db7BITS, db8BITS );
  // COM Port Stop bits
  TComPortStopBits = ( sb1BITS, sb1HALFBITS, sb2BITS );
  // COM Port Parity
  TComPortParity = ( ptNONE, ptODD, ptEVEN, ptMARK, ptSPACE );
  // COM Port Hardware Handshaking
  TComPortHwHandshaking = ( hhNONE, hhRTSCTS );
  // COM Port Software Handshaing
  TComPortSwHandshaking = ( shNONE, shXONXOFF );

  TComPortReceiveDataEvent = procedure( Sender: TObject; DataPtr: pointer; DataSize: integer ) of object;

  TCommPortDriver = class(TComponent)
  protected
    FComPortHandle             : THANDLE; // COM Port Device Handle

    FComPort                   : TComPortNumber; // COM Port to use (1..4)
    FComPortBaudRate           : TComPortBaudRate; // COM Port speed (brXXXX)
    FComPortDataBits           : TComPortDataBits; // Data bits size (5..8)
    FComPortStopBits           : TComPortStopBits; // How many stop bits to use (1,1.5,2)
    FComPortParity             : TComPortParity; // Type of parity to use (none,odd,even,mark,space)
    FComPortHwHandshaking      : TComPortHwHandshaking; // Type of hw handshaking to use
    FComPortSwHandshaking      : TComPortSwHandshaking; // Type of sw handshaking to use
    FComPortInBufSize          : word; // Size of the input buffer
    FComPortOutBufSize         : word; // Size of the output buffer
    FComPortReceiveData        : TComPortReceiveDataEvent; // Event to raise on data reception
    FComPortPollingDelay       : word; // ms of delay between COM port pollings
    FEnableDTROnOpen           : boolean; { enable/disable DTR line on connect }
    FOutputTimeout             : word; { output timeout - milliseconds }
    FNotifyWnd                 : HWND; // This is used for the timer
    FTempInBuffer              : pointer;

    procedure SetComHandle( Value: THANDLE );
    procedure SetComPort( Value: TComPortNumber );
    procedure SetComPortBaudRate( Value: TComPortBaudRate );
    procedure SetComPortDataBits( Value: TComPortDataBits );
    procedure SetComPortStopBits( Value: TComPortStopBits );
    procedure SetComPortParity( Value: TComPortParity );
    procedure SetComPortHwHandshaking( Value: TComPortHwHandshaking );
    procedure SetComPortSwHandshaking( Value: TComPortSwHandshaking );
    procedure SetComPortInBufSize( Value: word );
    procedure SetComPortOutBufSize( Value: word );
    procedure SetComPortPollingDelay( Value: word );

    procedure ApplyCOMSettings;

    procedure TimerWndProc( var msg: TMessage );
  public
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;

    function Connect: boolean;
    procedure Disconnect;
    function Connected: boolean;
    { v1.02: flushes the rx/tx buffers }
    procedure FlushBuffers( inBuf, outBuf: boolean );
    { v1.02: returns the output buffer free space or 65535 if
             not connected }
    function OutFreeSpace: word;

    { Send data }
    { v1.02: changed result time from 'boolean' to 'integer'. See the docs
             for more info }
    function SendData( DataPtr: pointer; DataSize: integer ): integer;
    // Send a pascal string (NULL terminated if $H+ (default))
    function SendString( s: string ): boolean;
    // v1.02: send a C-style strings (NULL terminated)
    function SendZString( s: pchar ): boolean;
    // v1.02: set DTR line high (onOff=TRUE) or low (onOff=FALSE).
    //        You must not use HW handshaking.
    procedure ToggleDTR( onOff: boolean );
    // v1.02: set RTS line high (onOff=TRUE) or low (onOff=FALSE).
    //        You must not use HW handshaking. 
    procedure ToggleRTS( onOff: boolean );

    // v1.02: make the Handle to the com port public (for TAPI...)
    property ComHandle: THANDLE read FComPortHandle write SetComHandle;
  published
    // Which COM Port to use
    property ComPort: TComPortNumber read FComPort write SetComPort default pnCOM2;
    // COM Port speed (bauds)
    property ComPortSpeed: TComPortBaudRate read FComPortBaudRate write SetComPortBaudRate default br9600;
    // Data bits to used (5..8, for the 8250 the use of 5 data bits with 2 stop bits is an invalid combination,
    // as is 6, 7, or 8 data bits with 1.5 stop bits)
    property ComPortDataBits: TComPortDataBits read FComPortDataBits write SetComPortDataBits default db8BITS;
    // Stop bits to use (1, 1.5, 2)
    property ComPortStopBits: TComPortStopBits read FComPortStopBits write SetComPortStopBits default sb1BITS;
    // Parity Type to use (none,odd,even,mark,space)
    property ComPortParity: TComPortParity read FComPortParity write SetComPortParity default ptNONE;
    // Hardware Handshaking Type to use:
    //  cdNONE          no handshaking
    //  cdCTSRTS        both cdCTS and cdRTS apply (** this is the more common method**)
    property ComPortHwHandshaking: TComPortHwHandshaking
             read FComPortHwHandshaking write SetComPortHwHandshaking default hhNONE;
    // Software Handshaking Type to use:
    //  cdNONE          no handshaking
    //  cdXONXOFF       XON/XOFF handshaking
    property ComPortSwHandshaking: TComPortSwHandshaking
             read FComPortSwHandshaking write SetComPortSwHandshaking default shNONE;
    // Input Buffer size
    property ComPortInBufSize: word read FComPortInBufSize write SetComPortInBufSize default 2048;
    // Output Buffer size
    property ComPortOutBufSize: word read FComPortOutBufSize write SetComPortOutBufSize default 2048;
    // ms of delay between COM port pollings
    property ComPortPollingDelay: word read FComPortPollingDelay write SetComPortPollingDelay default 50;
    // v1.02: Set to TRUE to enable DTR line on connect and to leave it on until disconnect.
    //        Set to FALSE to disable DTR line on connect. 
    property EnableDTROnOpen: boolean read FEnableDTROnOpen write FEnableDTROnOpen default true;
    // v1.02: Output timeout (milliseconds)
    property OutputTimeout: word read FOutputTimeOut write FOutputTimeout default 4000;
    // Event to raise when there is data available (input buffer has data)
    property OnReceiveData: TComPortReceiveDataEvent read FComPortReceiveData write FComPortReceiveData;
  end;

procedure Register;

implementation

constructor TCommPortDriver.Create( AOwner: TComponent );
begin
  inherited Create( AOwner );
  // Initialize to default values
  FComPortHandle             := 0;       // Not connected
  FComPort                   := pnCOM2;  // COM 2
  FComPortBaudRate           := br9600;  // 9600 bauds
  FComPortDataBits           := db8BITS; // 8 data bits
  FComPortStopBits           := sb1BITS; // 1 stop bit
  FComPortParity             := ptNONE;  // no parity
  FComPortHwHandshaking      := hhNONE;  // no hardware handshaking
  FComPortSwHandshaking      := shNONE;  // no software handshaking
  FComPortInBufSize          := 2048;    // input buffer of 2048 bytes
  FComPortOutBufSize         := 2048;    // output buffer of 2048 bytes
  FComPortReceiveData        := nil;     // no data handler
  FComPortPollingDelay       := 50;      // poll COM port every 50ms
  FOutputTimeout             := 4000;    // output timeout - 4000ms 
  FEnableDTROnOpen           := true;    // DTR high on connect 
  // Temporary buffer for received data 
  GetMem( FTempInBuffer, FComPortInBufSize );
  // Allocate a window handle to catch timer's notification messages
  if not (csDesigning in ComponentState) then
    FNotifyWnd := AllocateHWnd( TimerWndProc );
end;

destructor TCommPortDriver.Destroy;
begin
  // Be sure to release the COM device
  Disconnect;
  // Free the temporary buffer
  FreeMem( FTempInBuffer, FComPortInBufSize );
  // Destroy the timer's window
  DeallocateHWnd( FNotifyWnd );
  inherited Destroy;
end;

// v1.02: The COM port handle made public and writeable.
// This lets you connect to external opened com port.
// Setting ComPortHandle to 0 acts as Disconnect.
procedure TCommPortDriver.SetComHandle( Value: THANDLE );
begin
  // If same COM port then do nothing
  if FComPortHandle = Value then
    exit;
  { If value is $FFFFFFFF then stop controlling the COM port
    without closing in }
  if Value = $FFFFFFFF then
  begin
    if Connected then
      { Stop the timer }
      if Connected then
        KillTimer( FNotifyWnd, 1 );
    { No more connected }
    FComPortHandle := 0;
  end
  else
  begin
    { Disconnect }
    Disconnect;
    { If Value is = 0 then exit now }
    { (ComPortHandle := 0 acts as Disconnect) }
    if Value = 0  then
      exit;

    { Set COM port handle }
    FComPortHandle := Value;

    { Start the timer (used for polling) }
    SetTimer( FNotifyWnd, 1, FComPortPollingDelay, nil );
  end;
end;

procedure TCommPortDriver.SetComPort( Value: TComPortNumber );
begin
  // Be sure we are not using any COM port
  if Connected then
    exit;
  // Change COM port
  FComPort := Value;
end;

procedure TCommPortDriver.SetComPortBaudRate( Value: TComPortBaudRate );
begin
  // Set new COM speed
  FComPortBaudRate := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortDataBits( Value: TComPortDataBits );
begin
  // Set new data bits
  FComPortDataBits := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortStopBits( Value: TComPortStopBits );
begin
  // Set new stop bits
  FComPortStopBits := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortParity( Value: TComPortParity );
begin
  // Set new parity
  FComPortParity := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortHwHandshaking( Value: TComPortHwHandshaking );
begin
  // Set new hardware handshaking
  FComPortHwHandshaking := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortSwHandshaking( Value: TComPortSwHandshaking );
begin
  // Set new software handshaking
  FComPortSwHandshaking := Value;
  // Apply changes
  if Connected then
    ApplyCOMSettings;
end;

procedure TCommPortDriver.SetComPortInBufSize( Value: word );
begin
  { Do nothing if connected }
  if Connected then
    exit;
  // Free the temporary input buffer
  FreeMem( FTempInBuffer, FComPortInBufSize );
  // Set new input buffer size
  FComPortInBufSize := Value;
  // Allocate the temporary input buffer
  GetMem( FTempInBuffer, FComPortInBufSize );
end;

procedure TCommPortDriver.SetComPortOutBufSize( Value: word );
begin
  { Do nothing if connected }
  if not Connected then
    exit;
  // Set new output buffer size
  FComPortOutBufSize := Value;
end;

procedure TCommPortDriver.SetComPortPollingDelay( Value: word );
begin
  // If new delay is not equal to previous value...
  if Value <> FComPortPollingDelay then
  begin
    // Stop the timer
    if Connected then
      KillTimer( FNotifyWnd, 1 );
    // Store new delay value
    FComPortPollingDelay := Value;
    // Restart the timer
    if Connected then
      SetTimer( FNotifyWnd, 1, FComPortPollingDelay, nil );
  end;
end;

const
  Win32BaudRates: array[br110..br115200] of DWORD =
    ( CBR_110, CBR_300, CBR_600, CBR_1200, CBR_2400, CBR_4800, CBR_9600,
      CBR_14400, CBR_19200, CBR_38400, CBR_56000, CBR_57600, CBR_115200{v1.02 removed: CRB_128000, CBR_256000} );

const
  dcb_Binary              = $00000001;
  dcb_ParityCheck         = $00000002;
  dcb_OutxCtsFlow         = $00000004;
  dcb_OutxDsrFlow         = $00000008;
  dcb_DtrControlMask      = $00000030;
    dcb_DtrControlDisable   = $00000000;
    dcb_DtrControlEnable    = $00000010;
    dcb_DtrControlHandshake = $00000020;
  dcb_DsrSensivity        = $00000040;
  dcb_TXContinueOnXoff    = $00000080;
  dcb_OutX                = $00000100;
  dcb_InX                 = $00000200;
  dcb_ErrorChar           = $00000400;
  dcb_NullStrip           = $00000800;
  dcb_RtsControlMask      = $00003000;
    dcb_RtsControlDisable   = $00000000;
    dcb_RtsControlEnable    = $00001000;
    dcb_RtsControlHandshake = $00002000;
    dcb_RtsControlToggle    = $00003000;
  dcb_AbortOnError        = $00004000;
  dcb_Reserveds           = $FFFF8000;

// Apply COM settings.
procedure TCommPortDriver.ApplyCOMSettings;
var dcb: TDCB;
begin
  // Do nothing if not connected
  if not Connected then
    exit;

  // Clear all
  fillchar( dcb, sizeof(dcb), 0 );
  // Setup dcb (Device Control Block) fields
  dcb.DCBLength := sizeof(dcb); // dcb structure size
  dcb.BaudRate := Win32BaudRates[ FComPortBaudRate ]; // baud rate to use
  // Set fBinary: Win32 does not support non binary mode transfers
  // (also disable EOF check)
  dcb.Flags := dcb_Binary;
  if EnableDTROnOpen then
    { Enabled the DTR line when the device is opened and leaves it on }
    dcb.Flags := dcb.Flags or dcb_DtrControlEnable;

  case FComPortHwHandshaking of // Type of hw handshaking to use
    hhNONE:; // No hardware handshaking
    hhRTSCTS: // RTS/CTS (request-to-send/clear-to-send) hardware handshaking
      dcb.Flags := dcb.Flags or dcb_OutxCtsFlow or dcb_RtsControlHandshake;
  end;
  case FComPortSwHandshaking of // Type of sw handshaking to use
    shNONE:; // No software handshaking
    shXONXOFF: // XON/XOFF handshaking
      dcb.Flags := dcb.Flags or dcb_OutX or dcb_InX;
  end;
  dcb.XONLim := FComPortInBufSize div 4; // Specifies the minimum number of bytes allowed
                                         // in the input buffer before the XON character is sent
                                         // (or CTS is set)
  dcb.XOFFLim := 1; // Specifies the maximum number of bytes allowed in the input buffer
                    // before the XOFF character is sent. The maximum number of bytes
                    // allowed is calculated by subtracting this value from the size,
                    // in bytes, of the input buffer
  dcb.ByteSize := 5 + ord(FComPortDataBits); // how many data bits to use
  dcb.Parity := ord(FComPortParity); // type of parity to use
  dcb.StopBits := ord(FComPortStopbits); // how many stop bits to use
  dcb.XONChar := #17;  // XON ASCII char
  dcb.XOFFChar := #19; // XOFF ASCII char
  SetCommState( FComPortHandle, dcb );
  { Flush buffers }
  FlushBuffers( true, true );
  // Setup buffers size
  SetupComm( FComPortHandle, FComPortInBufSize, FComPortOutBufSize );
end;

function TCommPortDriver.Connect: boolean;
var comName: array[0..4] of char;
    tms: TCOMMTIMEOUTS;
begin
  // Do nothing if already connected
  Result := Connected;
  if Result then
    exit;
  // Open the COM port
  StrPCopy( comName, 'COM' );
  comName[3] := chr( ord('1') + ord(FComPort) );
  comName[4] := #0;
  FComPortHandle := CreateFile(
                                comName,
                                GENERIC_READ or GENERIC_WRITE,
                                0, // Not shared
                                nil, // No security attributes
                                OPEN_EXISTING,
                                FILE_ATTRIBUTE_NORMAL,
                                0 // No template
                              ) ;
  Result := Connected;
  if not Result then
    exit;
  // Apply settings
  ApplyCOMSettings;
  // Setup timeouts: we disable timeouts because we are polling the com port!
  tms.ReadIntervalTimeout := 1; // Specifies the maximum time, in milliseconds,
                                // allowed to elapse between the arrival of two
                                // characters on the communications line
  tms.ReadTotalTimeoutMultiplier := 0; // Specifies the multiplier, in milliseconds,
                                       // used to calculate the total time-out period
                                       // for read operations.
  tms.ReadTotalTimeoutConstant := 1; // Specifies the constant, in milliseconds,
                                     // used to calculate the total time-out period
                                     // for read operations.
  tms.WriteTotalTimeoutMultiplier := 0; // Specifies the multiplier, in milliseconds,
                                        // used to calculate the total time-out period
                                        // for write operations.
  tms.WriteTotalTimeoutConstant := 0; // Specifies the constant, in milliseconds,
                                      // used to calculate the total time-out period
                                      // for write operations.
  SetCommTimeOuts( FComPortHandle, tms );
  // Start the timer (used for polling)
  SetTimer( FNotifyWnd, 1, FComPortPollingDelay, nil );
end;

procedure TCommPortDriver.Disconnect;
begin
  if Connected then
  begin
    // Stop the timer (used for polling)
    KillTimer( FNotifyWnd, 1 );
    // Release the COM port
    CloseHandle( FComPortHandle );
    // No more connected
    FComPortHandle := 0;
  end;
end;

function TCommPortDriver.Connected: boolean;
begin
  Result := FComPortHandle > 0;
end;

// v1.02: flish rx/rx buffers 
procedure TCommPortDriver.FlushBuffers( inBuf, outBuf: boolean );
var dwAction: DWORD;
begin
  if not Connected then
    exit;
  // Flush the incoming data buffer
  dwAction := 0;
  if outBuf then
    dwAction := dwAction or PURGE_TXABORT or PURGE_TXCLEAR;
  if inBuf then
    dwAction := dwAction or PURGE_RXABORT or PURGE_RXCLEAR;
  PurgeComm( FComPortHandle, dwAction );
end;

// v1.02: returns the output buffer free space or 65535 if
//        not connected }
function TCommPortDriver.OutFreeSpace: word;
var stat: TCOMSTAT;
    errs: DWORD;
begin
  if not Connected then
    Result := 65535
  else
  begin
    ClearCommError( FComPortHandle, errs, @stat );
    Result := FComPortOutBufSize - stat.cbOutQue;
  end;
end;

// Send data
{function TCommPortDriver.SendData( DataPtr: pointer; DataSize: integer ): boolean;
var nsent: DWORD;
begin
  Result := WriteFile( FComPortHandle, DataPtr^, DataSize, nsent, nil );
  Result := Result and (nsent=DataSize);
end;}

{ Send data (breaks the data in small packets if it doesn't fit in the output
  buffer) }
function TCommPortDriver.SendData( DataPtr: pointer; DataSize: integer ): integer;
var nToSend, nsent: integer;
    t1: longint;
begin
  { 0 bytes sent }
  Result := 0;
  { Do nothing if not connected }
  if not Connected then
    exit;
  { Current time }
  t1 := GetTickCount;
  { Loop until all data sent or timeout occurred }
  while DataSize > 0 do
  begin
    { Get output buffer free space }
    nToSend := OutFreeSpace;
    { If output buffer has some free space... }
    if nToSend > 0 then
    begin
      { Don't send more bytes than we actually have to send }
      if nToSend > DataSize then
        nToSend := DataSize;
      { Send }
      WriteFile( FComPortHandle, DataPtr^, DataSize, cardinal(nsent), nil );
      { Update number of bytes sent }
      Result := Result + abs(nsent);
      { Decrease the count of bytes to send }
      DataSize := DataSize - abs(nsent);
      { Get current time }
      t1 := GetTickCount;
      { Continue. This skips the time check below (don't stop
        trasmitting if the FOutputTimeout is set too low) }
      continue;
    end;
    { Buffer is full. If we are waiting too long then
      invert the number of bytes sent and exit }
    if (GetTickCount-t1) > FOutputTimeout then
    begin
      Result := -Result;
      exit;
    end;
  end;
end;

// Send a pascal string (NULL terminated if $H+ (default))
function TCommPortDriver.SendString( s: string ): boolean;
var len: integer;
begin
  len := length( s );
  {$IFOPT H+}
  // New syle pascal string (NULL terminated)
  Result := SendData( pchar(s), len ) = len;
  {$ELSE}
  // Old style pascal string (s[0] = length)
  Result := SendData( pchar(@s[1]), len ) = len;
  {$ENDIF}
end;

// v1.02: send a C-style strings (NULL terminated) 
function TCommPortDriver.SendZString( s: pchar ): boolean;
var len: integer;
begin
  len := strlen( s );
  Result := SendData( s, len ) = len;
end;

// v1.02: set DTR line high (onOff=TRUE) or low (onOff=FALSE).
//        You must not use HW handshaking. 
procedure TCommPortDriver.ToggleDTR( onOff: boolean );
const funcs: array[boolean] of integer = (CLRDTR,SETDTR);
begin
  if Connected then
    EscapeCommFunction( FComPortHandle, funcs[onOff] );
end;

// v1.02: set RTS line high (onOff=TRUE) or low (onOff=FALSE).
//        You must not use HW handshaking. 
procedure TCommPortDriver.ToggleRTS( onOff: boolean );
const funcs: array[boolean] of integer = (CLRRTS,SETRTS);
begin
  if Connected then
    EscapeCommFunction( FComPortHandle, funcs[onOff] );
end;

// COM port polling proc
procedure TCommPortDriver.TimerWndProc( var msg: TMessage );
var nRead: dword;
begin
  if (msg.Msg = WM_TIMER) and Connected then
  begin
    nRead := 0;
    if ReadFile( FComPortHandle, FTempInBuffer^, FComPortInBufSize, nRead, nil ) then
      if (nRead <> 0) and Assigned(FComPortReceiveData) then
        FComPortReceiveData( Self, FTempInBuffer, nRead );
  end;
end;

procedure Register;
begin
  { Register this component and show it in the 'System' tab
    of the component palette }
  RegisterComponents('HCore', [TCommPortDriver]);
end;

end.
