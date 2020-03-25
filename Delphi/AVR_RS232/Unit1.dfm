object fAVR: TfAVR
  Left = 258
  Top = 114
  BorderStyle = bsSingle
  Caption = 'AVR RS232'
  ClientHeight = 492
  ClientWidth = 565
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010002002020100000000000E80200002600000010101000000000002801
    00000E0300002800000020000000400000000100040000000000800200000000
    0000000000000000000000000000000000000000800000800000008080008000
    0000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF00
    0000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000090000000000900009000090009000900900
    0000000090000900009000900090090000000009090090900090090900900900
    0000000909009090009009090090099999900009090090900090090900900900
    0009009000990009009090009090090000090090009900090090900090900900
    0009009000990009009900000990090000090900009900009099000009900999
    9990090000000000909000000090000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    FFFFFFFFFFFFBFF7BDDDBFF7BDDDBFEB5DADBFEB5DAD81EB5DADBEDCED75BEDC
    ED75BEDCECF9BEBCF4F981BFF5FDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    FFFFFFFFFFFF9C00FC07DDFEFDF7DDFEFDF7DDFEFDF7DDFEFDF7DDFEFDF7DDFE
    FDF7C1FE01F1FFFFFFFFFFFFFFFF280000001000000020000000010004000000
    0000C00000000000000000000000000000000000000000000000000080000080
    00000080800080000000800080008080000080808000C0C0C0000000FF0000FF
    000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000900
    0090900900090900090909090009099009090909000909090909090909090909
    0900090909090990090009099999000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    00000000000000000000000000000000000000000000FFFF0000BD6E0000BAAE
    00009AAE0000AAAA0000ABAA00009BA00000FFFF0000B0790000B77B0000B77B
    0000B77B0000B77B0000B77B000087030000FFFF0000}
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 380
    Width = 43
    Height = 13
    Caption = 'PWM 1A'
  end
  object Label2: TLabel
    Left = 8
    Top = 412
    Width = 43
    Height = 13
    Caption = 'PWM 1B'
  end
  object Label3: TLabel
    Left = 8
    Top = 444
    Width = 36
    Height = 13
    Caption = 'PWM 2'
  end
  object lDutyCycle1A: TLabel
    Left = 352
    Top = 381
    Width = 26
    Height = 13
    Caption = '50 %'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lDutyCycle1B: TLabel
    Left = 352
    Top = 413
    Width = 26
    Height = 13
    Caption = '50 %'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lDutyCycle2: TLabel
    Left = 352
    Top = 445
    Width = 26
    Height = 13
    Caption = '50 %'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label7: TLabel
    Left = 328
    Top = 360
    Width = 51
    Height = 13
    Caption = 'Duty-Cycle'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object lDutyCycle1AByte: TLabel
    Left = 328
    Top = 381
    Width = 12
    Height = 10
    Caption = '128'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -8
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lDutyCycle1BByte: TLabel
    Left = 328
    Top = 413
    Width = 12
    Height = 10
    Caption = '128'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -8
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object lDutyCycle2Byte: TLabel
    Left = 328
    Top = 445
    Width = 12
    Height = 10
    Caption = '128'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -8
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Tekst: TMemo
    Left = 0
    Top = 0
    Width = 385
    Height = 353
    TabOrder = 0
  end
  object rgCommPort: TRadioGroup
    Left = 392
    Top = 8
    Width = 81
    Height = 81
    Caption = ' COM-Port '
    ItemIndex = 0
    Items.Strings = (
      'COM1'
      'COM2'
      'COM3'
      'COM4')
    TabOrder = 1
  end
  object bConnect: TButton
    Left = 392
    Top = 440
    Width = 81
    Height = 25
    Caption = 'Open'
    TabOrder = 2
    OnClick = bConnectClick
  end
  object rgDataBits: TRadioGroup
    Left = 480
    Top = 8
    Width = 81
    Height = 81
    Caption = ' Data Bits '
    ItemIndex = 3
    Items.Strings = (
      '5'
      '6'
      '7'
      '8')
    TabOrder = 3
  end
  object rgParity: TRadioGroup
    Left = 480
    Top = 96
    Width = 81
    Height = 97
    Caption = ' Parity '
    ItemIndex = 0
    Items.Strings = (
      'None'
      'Odd'
      'Even'
      'Mark'
      'Space')
    TabOrder = 4
  end
  object rgStopBits: TRadioGroup
    Left = 480
    Top = 200
    Width = 81
    Height = 65
    Caption = ' StopBits '
    ItemIndex = 0
    Items.Strings = (
      '1'
      '1'#189
      '2')
    TabOrder = 5
  end
  object bDisconnect: TButton
    Left = 480
    Top = 440
    Width = 81
    Height = 25
    Caption = 'Close'
    Enabled = False
    TabOrder = 6
    OnClick = bDisconnectClick
  end
  object rgHandshake: TRadioGroup
    Left = 392
    Top = 304
    Width = 169
    Height = 81
    Caption = ' Handshake '
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'None'
      'RTS/CTS'
      'Xon/Xoff'
      'RTS/CTS + Xon/Xoff')
    ParentFont = False
    TabOrder = 7
  end
  object rgBaudRate: TRadioGroup
    Left = 392
    Top = 96
    Width = 81
    Height = 201
    Caption = ' Baudrate '
    ItemIndex = 7
    Items.Strings = (
      '300'
      '600'
      '1200'
      '2400'
      '4800'
      '9600'
      '14400'
      '19200'
      '38400'
      '56000'
      '57600'
      '115200')
    TabOrder = 8
  end
  object gbDTR: TGroupBox
    Left = 392
    Top = 392
    Width = 81
    Height = 41
    Caption = ' DTR '
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    object bSetDTR: TButton
      Left = 6
      Top = 16
      Width = 27
      Height = 17
      Caption = 'Set'
      Enabled = False
      TabOrder = 0
    end
    object bClearDTR: TButton
      Left = 38
      Top = 16
      Width = 35
      Height = 17
      Caption = 'Clear'
      Enabled = False
      TabOrder = 1
    end
  end
  object gbRTS: TGroupBox
    Left = 480
    Top = 392
    Width = 81
    Height = 41
    Caption = ' RTS '
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
    object bSetRTS: TButton
      Left = 6
      Top = 16
      Width = 27
      Height = 17
      Caption = 'Set'
      Enabled = False
      TabOrder = 0
    end
    object bClearRTS: TButton
      Left = 38
      Top = 16
      Width = 35
      Height = 17
      Caption = 'Clear'
      Enabled = False
      TabOrder = 1
    end
  end
  object tbPWM1A: TTrackBar
    Left = 56
    Top = 376
    Width = 256
    Height = 33
    Max = 255
    PageSize = 16
    Frequency = 16
    Position = 128
    SelEnd = 128
    TabOrder = 11
    OnChange = tbPWM1AChange
  end
  object tbPWM1B: TTrackBar
    Left = 56
    Top = 408
    Width = 256
    Height = 33
    Max = 255
    PageSize = 16
    Frequency = 16
    Position = 128
    SelEnd = 128
    TabOrder = 12
    OnChange = tbPWM1BChange
  end
  object tbPWM2: TTrackBar
    Left = 56
    Top = 440
    Width = 256
    Height = 33
    Max = 255
    PageSize = 16
    Frequency = 16
    Position = 128
    SelEnd = 128
    TabOrder = 13
    OnChange = tbPWM2Change
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 473
    Width = 565
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object cbTOP1A: TCheckBox
    Left = 306
    Top = 378
    Width = 17
    Height = 17
    Checked = True
    State = cbChecked
    TabOrder = 15
    OnClick = cbTOP1AClick
  end
  object cbTOP1B: TCheckBox
    Left = 306
    Top = 410
    Width = 17
    Height = 17
    Checked = True
    State = cbChecked
    TabOrder = 16
    OnClick = cbTOP1BClick
  end
  object cbTOP2: TCheckBox
    Left = 306
    Top = 442
    Width = 17
    Height = 17
    Checked = True
    State = cbChecked
    TabOrder = 17
    OnClick = cbTOP2Click
  end
  object CommPortDriver: TCommPortDriver
    OnReceiveData = CommPortDriverReceiveData
    Left = 528
    Top = 272
  end
end
