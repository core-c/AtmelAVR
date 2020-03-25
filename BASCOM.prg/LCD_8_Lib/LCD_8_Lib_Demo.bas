
$regfile = "8535def.dat"                                    '' tbv. AT90S8535


'';--- Toegekende poorten & pinnen ----------\
'';--- De control-port en control-lijnen -----
Const Lcd_ctrl_port = Porta                                 ''; De control-port (alleen als OUTPUT)
Const Lcd_ctrl_ddr = Ddra                                   ''; Het Data-Direction-Register van de control-port
Const Lcd_rs = Pa5                                          ''; RS op pin 5 van poort A
Const Lcd_rw = Pa6                                          ''; RW op pin 6 van poort A
Const Lcd_e = Pa7                                           ''; E op pin 7 van poort A
'';--- De data-port en data-lijnen -----------
Const Lcd_data_port = Portc                                 ''; De data-port DB7-0 (INPUT/OUTPUT)
Const Lcd_data_ddr = Ddrc                                   '';
Const Lcd_data_in = Pinc                                    ''; Input data lezen van deze poort
Const Lcd_busy = Pc7                                        ''; Busy-Flag op pin 7 van poort C (=DB7)
'';--- De datalijnen -------------------------
Const Lcd_db0 = Pc0                                         '';
Const Lcd_db1 = Pc1                                         '';
Const Lcd_db2 = Pc2                                         '';
Const Lcd_db3 = Pc3                                         '';
Const Lcd_db4 = Pc4                                         '';
Const Lcd_db5 = Pc5                                         '';
Const Lcd_db6 = Pc6                                         '';
Const Lcd_db7 = Pc7                                         '';
'';------------------------------------------/


$lib "LCD_8_Lib.lbx"                                        '' Ron's Bascom Library voor een 8-bit LCD IF.

$external Lcd_initialize                                    ''routines in de library
$external Lcd_put                                           ''
$external Lcd_get                                           ''
$external Lcd_cursorhome                                    ''
$external Lcd_cls                                           ''
$external Lcd_setcursor                                     ''
''$external Lcd_getcursor                                     ''

Declare Sub Lcd_initialize                                  '' Het LCD iniitialiseren
Declare Sub Lcd_put(byref Bytetosend As Byte)               '' Een data-byte zenden voor afbeelden
Declare Function Lcd_get() As Byte                          '' Een data-byte lezen (CGRAM/DDRAM)
Declare Sub Lcd_cursorhome                                  '' De LCD-cursor op de beginpositie plaatsen
Declare Sub Lcd_cls                                         '' De LCD-inhoud wissen
Declare Sub Lcd_setcursor(byref Xx As Byte , Byref Yy As Byte)       '' De LCD-cursor plaatsen op (XX,YY)
''Declare Sub Lcd_getcursor(byref Xx As Byte , Byref Yy As Byte)       '' De LCD-cursorpositie lezen in (XX,YY)



'Declare Sub Justprint(byref S As String)                    ''bascom sub. dump een tekst naar het LCD

'Sub Justprint(byref S As String)
'   For I = 1 To Len(s)
'      Sb = Mid(s , I , 1)
'      Thisbyte = Asc(sb)
'      Lcd_put Thisbyte                                      ''== Call Lcd_put(b)
'   Next
'End Sub





Dim S As String * 20
Dim X As Byte
Dim Y As Byte

Dim Ch As String * 1
Dim I As Integer
Dim Thisbyte As Byte



''Config LCD = 20 * 4
''Config LCDMODE = PORT
''Config LCDBUS = 8
''Config LCDPIN=PIN, PORT=PORTC, E=PORTA.7, RS=PORTA.5
Lcd_initialize                                              ''== Call Lcd_initialize


S = " BASCOM Library LCD "
'Justprint S
For I = 1 To Len(s)
   Ch = Mid(s , I , 1)
   Thisbyte = Asc(ch)
   Lcd_put Thisbyte                                         ''== Call Lcd_put(Ch)
Next

X = 0                                                       ''vooraan
Y = 1                                                       ''2e regel
Lcd_setcursor X , Y                                         '' Lcd_setcursor(0,1)

S = " 8bit PORT-mode v.9 "
'Justprint S
For I = 1 To Len(s)
   Ch = Mid(s , I , 1)
   Thisbyte = Asc(ch)
   Lcd_put Thisbyte                                         ''== Call Lcd_put(Ch)
Next

X = 0                                                       ''vooraan
Y = 2                                                       ''3e regel
Lcd_setcursor X , Y                                         '' Lcd_setcursor(0,2)

S = "vet koel heftig gaaf"
'Justprint S
For I = 1 To Len(s)
   Ch = Mid(s , I , 1)
   Thisbyte = Asc(ch)
   Lcd_put Thisbyte                                         ''== Call Lcd_put(Ch)
Next

X = 0                                                       ''vooraan
Y = 3                                                       ''4e regel
Lcd_setcursor X , Y                                         '' Lcd_setcursor(0,3)

S = "__/¦ñ__,-'ñ__|ñ|ñ___"
'Justprint S
For I = 1 To Len(s)
   Ch = Mid(s , I , 1)
   Thisbyte = Asc(ch)
   Lcd_put Thisbyte                                         ''== Call Lcd_put(Ch)
Next

X = 19                                                      ''vooraan
Y = 3                                                       ''4e regel
Lcd_setcursor X , Y                                         '' Lcd_setcursor(19,3)

End                                                         '' NODIG! want anders wordt de library-code vanaf hier uitgevoerd!!