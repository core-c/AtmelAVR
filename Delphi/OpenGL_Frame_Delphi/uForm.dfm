object fGL: TfGL
  Left = 252
  Top = 114
  Width = 464
  Height = 419
  Caption = 'glTest'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pGL: TPanel
    Left = 0
    Top = 0
    Width = 456
    Height = 235
    Cursor = crHandPoint
    Align = alClient
    BevelOuter = bvNone
    Color = clNone
    Ctl3D = False
    FullRepaint = False
    ParentCtl3D = False
    TabOrder = 0
    OnResize = pGLResize
  end
  object pControls: TPanel
    Left = 0
    Top = 235
    Width = 456
    Height = 150
    Align = alBottom
    Constraints.MaxHeight = 150
    Constraints.MinHeight = 150
    TabOrder = 1
  end
  object ApplicationEvents: TApplicationEvents
    OnIdle = ApplicationEventsIdle
    Left = 16
    Top = 16
  end
end
