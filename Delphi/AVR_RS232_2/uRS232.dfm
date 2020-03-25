object fRS232: TfRS232
  Left = 657
  Top = 114
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Setup RS232 Communication'
  ClientHeight = 335
  ClientWidth = 356
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
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object rgCommPort: TRadioGroup
    Left = 6
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
    TabOrder = 0
  end
  object rgDataBits: TRadioGroup
    Left = 94
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
    TabOrder = 1
  end
  object rgParity: TRadioGroup
    Left = 182
    Top = 8
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
    TabOrder = 2
  end
  object rgStopBits: TRadioGroup
    Left = 270
    Top = 8
    Width = 81
    Height = 65
    Caption = ' StopBits '
    ItemIndex = 0
    Items.Strings = (
      '1'
      '1'#189
      '2')
    TabOrder = 3
  end
  object rgHandshake: TRadioGroup
    Left = 94
    Top = 112
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
    TabOrder = 4
  end
  object rgBaudRate: TRadioGroup
    Left = 6
    Top = 96
    Width = 83
    Height = 201
    Caption = ' Baudrate '
    ItemIndex = 5
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
    TabOrder = 5
  end
  object gbDTR: TGroupBox
    Left = 94
    Top = 200
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
    TabOrder = 6
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
    Left = 182
    Top = 200
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
    TabOrder = 7
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
  object bOpenRS232: TButton
    Left = 272
    Top = 304
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 8
  end
  object Button1: TButton
    Left = 192
    Top = 304
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 9
  end
end
