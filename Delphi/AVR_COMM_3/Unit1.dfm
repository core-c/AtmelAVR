object fLCDBabe: TfLCDBabe
  Left = 254
  Top = 118
  Width = 481
  Height = 448
  Caption = 'AVR LCD I2C Slave'
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
    0000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000099
    9999999009999900999999900000000999000990999009900999009900000009
    9900000099000990099900099000000999000009990000000999000990000009
    9900000999000000099900099000000999000009990000000999000990000009
    9900000999000000099900099000000999000009990000000999000990000009
    9900000099000990099900099000000999000000999009900999009900000099
    9990000009999900999999900000000000000000000000000000000000000000
    1111101111111100011111000000000001110011100011001110011000000000
    0111000110000000110001100000000001110000110000011100000000000000
    0111000001110001110000000000000001110000000110011100000000000000
    0111000000001101110000000000000001110000000011011100000000000000
    0111000110001100110001100000000001110001100111001110011000000000
    1111100011111000011111000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000FFFFFFFFC018301FE39198CFE3F398E7E3E3
    F8E7E3E3F8E7E3E3F8E7E3E3F8E7E3E3F8E7E3F398E7E3F198CFC1F8301FFFFF
    FFFFF040383FF8C7319FF8E7F39FF8F3E3FFF8F8E3FFF8FE63FFF8FF23FFF8FF
    23FFF8E7339FF8E6319FF070783FFFFFFFFFFFFFFFFFFC7C47C781011011FFFF
    FFFF81111111FC444447FFFFFFFF280000001000000020000000010004000000
    0000C00000000000000000000000000000000000000000000000000080000080
    00000080800080000000800080008080000080808000C0C0C0000000FF0000FF
    000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000999
    9009990999000990009900099090099000990009909009900099000990900990
    0009990999000000000000000000000101110011000000010100010000000001
    0010010000000001000101000000000101110011000000000000000000000000
    00000000000000000000000000000000000000000000FFFF0000862300009CE5
    00009CE500009CE500009E230000FFFF0000E8CF0000EBBF0000EDBF0000EEBF
    0000E8CF0000FFFF0000FFFF00002222000088880000}
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 21
    Height = 13
    Caption = 'LCD'
  end
  object Label21: TLabel
    Left = 8
    Top = 280
    Width = 152
    Height = 13
    Caption = 'Ontvangen via RS232 van AVR'
  end
  object Label22: TLabel
    Left = 224
    Top = 376
    Width = 83
    Height = 13
    Caption = 'RS232-connectie'
  end
  object Label23: TLabel
    Left = 8
    Top = 160
    Width = 153
    Height = 13
    Caption = 'Verzonden via RS232 naar AVR'
  end
  object Memo1: TMemo
    Left = 8
    Top = 24
    Width = 169
    Height = 65
    Color = clMoneyGreen
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier'
    Font.Style = []
    Lines.Strings = (
      '12345678901234567890'
      '12345678901234567890'
      '12345678901234567890'
      '12345678901234567890')
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
  end
  object GroupBox1: TGroupBox
    Left = 184
    Top = 8
    Width = 281
    Height = 353
    Caption = ' LCD UserCommands '
    TabOrder = 1
    object Label2: TLabel
      Left = 56
      Top = 32
      Width = 108
      Height = 13
      Caption = 'LCD character lineprint'
    end
    object Label3: TLabel
      Left = 56
      Top = 48
      Width = 150
      Height = 13
      Caption = 'LCD-cursor naar volgende regel'
    end
    object Label4: TLabel
      Left = 56
      Top = 64
      Width = 84
      Height = 13
      Caption = 'LCD-cursor Home'
    end
    object Label5: TLabel
      Left = 56
      Top = 80
      Width = 130
      Height = 13
      Caption = 'LCD-cursor naar EndOfLine'
    end
    object Label6: TLabel
      Left = 56
      Top = 96
      Width = 125
      Height = 13
      Caption = 'LCD print hex.nibble (b3-0)'
    end
    object Label7: TLabel
      Left = 56
      Top = 112
      Width = 87
      Height = 13
      Caption = 'LCD print hex.byte'
    end
    object Label8: TLabel
      Left = 56
      Top = 128
      Width = 90
      Height = 13
      Caption = 'LCD print hex.word'
    end
    object Label9: TLabel
      Left = 56
      Top = 144
      Width = 67
      Height = 13
      Caption = 'LCD Scroll-Up'
    end
    object Label10: TLabel
      Left = 56
      Top = 160
      Width = 78
      Height = 13
      Caption = 'LCD Backspace'
    end
    object Label11: TLabel
      Left = 56
      Top = 176
      Width = 55
      Height = 13
      Caption = 'LCD Delete'
    end
    object Label12: TLabel
      Left = 56
      Top = 192
      Width = 98
      Height = 13
      Caption = 'LCD Insert character'
    end
    object Label13: TLabel
      Left = 56
      Top = 208
      Width = 77
      Height = 13
      Caption = 'LCD pijl omhoog'
    end
    object Label14: TLabel
      Left = 56
      Top = 224
      Width = 73
      Height = 13
      Caption = 'LCD pijl omlaag'
    end
    object Label15: TLabel
      Left = 56
      Top = 240
      Width = 84
      Height = 13
      Caption = 'LCD pijl naar links'
    end
    object Label16: TLabel
      Left = 56
      Top = 256
      Width = 92
      Height = 13
      Caption = 'LCD pijl naar rechts'
    end
    object Label17: TLabel
      Left = 56
      Top = 272
      Width = 36
      Height = 13
      Caption = 'LCD Fill'
    end
    object Label18: TLabel
      Left = 56
      Top = 288
      Width = 120
      Height = 13
      Caption = 'LCD Clear Line from (X,Y)'
    end
    object Label19: TLabel
      Left = 56
      Top = 304
      Width = 90
      Height = 13
      Caption = 'LCD SplashScreen'
    end
    object Label20: TLabel
      Left = 56
      Top = 320
      Width = 99
      Height = 13
      Caption = 'LCD Set Cursor (X,Y)'
    end
    object LCD00: TButton
      Left = 8
      Top = 32
      Width = 41
      Height = 13
      Caption = '$00'
      TabOrder = 0
      OnClick = LCD00Click
    end
    object LCD01: TButton
      Left = 8
      Top = 48
      Width = 41
      Height = 13
      Caption = '$01'
      TabOrder = 1
      OnClick = LCD01Click
    end
    object LCD02: TButton
      Left = 8
      Top = 64
      Width = 41
      Height = 13
      Caption = '$02'
      TabOrder = 2
      OnClick = LCD02Click
    end
    object LCD03: TButton
      Left = 8
      Top = 80
      Width = 41
      Height = 13
      Caption = '$03'
      TabOrder = 3
      OnClick = LCD03Click
    end
    object LCD04: TButton
      Left = 8
      Top = 96
      Width = 41
      Height = 13
      Caption = '$04'
      TabOrder = 4
      OnClick = LCD04Click
    end
    object LCD05: TButton
      Left = 8
      Top = 112
      Width = 41
      Height = 13
      Caption = '$05'
      TabOrder = 5
      OnClick = LCD05Click
    end
    object LCD06: TButton
      Left = 8
      Top = 128
      Width = 41
      Height = 13
      Caption = '$06'
      TabOrder = 6
      OnClick = LCD06Click
    end
    object LCD07: TButton
      Left = 8
      Top = 144
      Width = 41
      Height = 13
      Caption = '$07'
      TabOrder = 7
      OnClick = LCD07Click
    end
    object LCD08: TButton
      Left = 8
      Top = 160
      Width = 41
      Height = 13
      Caption = '$08'
      TabOrder = 8
      OnClick = LCD08Click
    end
    object LCD09: TButton
      Left = 8
      Top = 176
      Width = 41
      Height = 13
      Caption = '$09'
      TabOrder = 9
      OnClick = LCD09Click
    end
    object LCD0A: TButton
      Left = 8
      Top = 192
      Width = 41
      Height = 13
      Caption = '$0A'
      TabOrder = 10
      OnClick = LCD0AClick
    end
    object LCD0B: TButton
      Left = 8
      Top = 208
      Width = 41
      Height = 13
      Caption = '$0B'
      TabOrder = 11
      OnClick = LCD0BClick
    end
    object LCD0C: TButton
      Left = 8
      Top = 224
      Width = 41
      Height = 13
      Caption = '$0C'
      TabOrder = 12
      OnClick = LCD0CClick
    end
    object LCD0D: TButton
      Left = 8
      Top = 240
      Width = 41
      Height = 13
      Caption = '$0D'
      TabOrder = 13
      OnClick = LCD0DClick
    end
    object LCD0E: TButton
      Left = 8
      Top = 256
      Width = 41
      Height = 13
      Caption = '$0E'
      TabOrder = 14
      OnClick = LCD0EClick
    end
    object LCD0F: TButton
      Left = 8
      Top = 272
      Width = 41
      Height = 13
      Caption = '$0F'
      TabOrder = 15
      OnClick = LCD0FClick
    end
    object LCD10: TButton
      Left = 8
      Top = 288
      Width = 41
      Height = 13
      Caption = '$10'
      TabOrder = 16
      OnClick = LCD10Click
    end
    object LCD11: TButton
      Left = 8
      Top = 304
      Width = 41
      Height = 13
      Caption = '$11'
      TabOrder = 17
      OnClick = LCD11Click
    end
    object LCD12: TButton
      Left = 8
      Top = 320
      Width = 41
      Height = 13
      Caption = '$12'
      TabOrder = 18
      OnClick = LCD12Click
    end
    object LCD00_data1: TEdit
      Left = 240
      Top = 32
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 19
    end
    object LCD04_data1: TEdit
      Left = 240
      Top = 96
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 20
    end
    object LCD05_data1: TEdit
      Left = 240
      Top = 112
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 21
    end
    object LCD06_data1_2: TEdit
      Left = 208
      Top = 128
      Width = 65
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 22
    end
    object LCD0A_data1: TEdit
      Left = 240
      Top = 192
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 23
    end
    object LCD0F_data1: TEdit
      Left = 240
      Top = 272
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
    end
    object LCD10_data2: TEdit
      Left = 240
      Top = 288
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 25
    end
    object LCD10_data1: TEdit
      Left = 207
      Top = 288
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
    end
    object LCD12_data1: TEdit
      Left = 207
      Top = 320
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 27
    end
    object LCD12_data2: TEdit
      Left = 240
      Top = 320
      Width = 33
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 28
    end
  end
  object Input: TEdit
    Left = 8
    Top = 96
    Width = 169
    Height = 21
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier'
    Font.Style = []
    MaxLength = 20
    ParentFont = False
    TabOrder = 2
  end
  object TextToLCD: TButton
    Left = 104
    Top = 120
    Width = 75
    Height = 25
    Caption = 'Send'
    TabOrder = 3
    OnClick = TextToLCDClick
  end
  object Received: TMemo
    Left = 8
    Top = 296
    Width = 169
    Height = 97
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 4
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 395
    Width = 473
    Height = 19
    Panels = <>
  end
  object bOpen: TButton
    Left = 312
    Top = 368
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 6
    OnClick = bOpenClick
  end
  object bClose: TButton
    Left = 392
    Top = 368
    Width = 75
    Height = 25
    Caption = 'Close'
    Enabled = False
    TabOrder = 7
    OnClick = bCloseClick
  end
  object Transmitted: TMemo
    Left = 8
    Top = 176
    Width = 169
    Height = 97
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 8
  end
  object CommPortDriver: TCommPortDriver
    ComPortSpeed = br19200
    OnReceiveData = CommPortDriverReceiveData
    Left = 192
    Top = 368
  end
end
