�
 TMAINFORM 0�  TPF0	TMainFormMainFormLeftTop� Width~Height�CaptionTCommPortDriver Test
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 	Icon.Data
�             �     (       @         �                        �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ���                                                       3333           333333         3;����33       �������30      ��������33     ����  ���30    ����� ��30    ������� ��3    ���������3   ���������30  �����������30  �����������30  ���������30  ���������30  ���������30  ���������30  ���  �  ���30   ���  �  ���3    ���������3    ����������0    ���������30     ���������3      �������30       �������3         �����3           ���3                                                      �������������������  ��  �  ?�  �  �  �  �  �  �  �  �  �  �  �  �  �  �  �  �  ?�  �  �������������������PositionpoScreenCenterPixelsPerInch`
TextHeight TPanelPanel1Left Top WidthvHeighteAlignalTop
BevelOuterbvNoneTabOrder  TButton
ConnectBtnLeftTopWidthKHeightCaption&ConnectTabOrder OnClickConnectBtnClick  TButtonDisconnectBtnLeftTop(WidthKHeightCaption&DisconnectEnabledTabOrderOnClickDisconnectBtnClick  TButtonQuitBtnLeftTopDWidthKHeightCaption&QuitTabOrderOnClickQuitBtnClick  TRadioGroup	ComPortRGLeftTTopWidthEHeight]Caption
 COM Port 	ItemIndexItems.StringsCOM1COM2COM3COM4 TabOrderOnClickComPortRGClick  TRadioGroup
BaudRateRGLeft� TopWidth� Height]Caption Baud rate Columns	ItemIndexItems.Strings30060012002400480096001440019200384005600057600115200 TabOrderOnClickBaudRateRGClick  TRadioGroup
DataBitsRGLeftXTopWidth=Height]Caption
 Data bits	ItemIndexItems.Strings5678 TabOrderOnClickDataBitsRGClick  TRadioGroupParityRGLeft�TopWidthAHeight]Caption Parity 	ItemIndex Items.Stringsnoneoddevenmarkspace TabOrderOnClickParityRGClick  TRadioGroupHandshakingRGLeft�TopWidth� Height]Caption Handshaking 	ItemIndex Items.StringsnoneRTS/CTSXON/XOFFRTS/CTS + XON/XOFF TabOrderOnClickHandshakingRGClick   
TStatusBar	StatusBarLeft TopzWidthvHeightPanels SimplePanel	
SimpleTextDisconnected  TMemoTxMemoLeft Top� WidthvHeight{AlignalBottom
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style 
ParentFont
ScrollBarsssBothTabOrder
OnKeyPressTxMemoKeyPress  TMemoRxMemoLeft TopvWidthvHeightvAlignalClient
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style 
ParentFontReadOnly	
ScrollBarsssBothTabOrder  TPanelPanel2Left Top� WidthvHeightAlignalBottom	AlignmenttaLeftJustify
BevelOuterbvNoneCaptionTransmitTabOrder TButton
ClrOutMemoLeft1TopWidthKHeightCaptionCLEAR
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrder OnClickClrOutMemoClick  TButton	SetDTRBtnLeft|TopWidthKHeightCaptionSET DTR
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrderOnClickSetDTRBtnClick  TButton	ClrDTRBtnLeft� TopWidthKHeightCaptionCLR DTR
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrderOnClickClrDTRBtnClick  TButton	SetRTSBtnLeftTopWidthKHeightCaptionSET RTS
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrderOnClickSetRTSBtnClick  TButton	ClrRTSBtnLeft]TopWidthKHeightCaptionCLR RTS
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrderOnClickClrRTSBtnClick   TPanelPanel3Left TopeWidthvHeightAlignalTop	AlignmenttaLeftJustify
BevelOuterbvNoneCaptionReceiveTabOrder TButton	ClrInMemoLeft1TopWidthKHeightCaptionCLEAR
Font.ColorclBlackFont.Height�	Font.NameSmall Fonts
Font.Style 
ParentFontTabOrder OnClickClrInMemoClick   TCommPortDriverCommPortDriverComPortPollingDelay OnReceiveDataCommPortDriverReceiveDataLeftTop�    