; Toestanden op de I2C-bus

;===========================
; Bus vrij
;
;  SDA ________________
;   :
;   :
;
;  SCL ________________
;   :
;   :
;

;===========================
; Een START conditie op de bus
;
;  SDA ____
;   :      \
;   :       \__________
;
;  SCL _________
;   :           \
;   :            \_____
;

;===========================
; Een STOP conditie op de bus
;
;  SDA            ______
;   :            /
;   :  _________/
;
;  SCL      ____________
;   :      /
;   :  ___/
;

;===========================
; Een bit-cyclus op de bus bij lees- & schrijf-acties:
;
;  SDA ___  ____________
;   :     \/
;   :  ___/\____________
;
;  SCL          ______
;   :          /:     \
;   :  _______/ :      \
;        :      :
;    t ..:......:.......  Op tijdstip 1 moet de slave zijn data schrijven naar de bus
;        1      2         Op tijdstip 2 moet de slave data lezen van de bus
;
;


;--- Compiler Directives --\
.equ PRG = 0				; type prg gecompileerd: 0=Reply laatst ontvangen teken, 1=geef de huidige LCD-cursor-positie terug
;--------------------------/


;--- Constanten -----------\
.equ Slave_Address	= $30
;--- Connecties I2C --------
.equ TWI_SCL		= PD4	; = PIND4 = DDD4
.equ TWI_SDA		= PD2	; = PIND2 = DDD2
.equ TWI_DDR		= DDRD	; Data Direction Register
.equ TWI_PIN		= PIND	; Port INput
.equ TWI_PORT		= PORTD	; Port output
;--------------------------/


;--- Registers ------------\
.def Reply			= R1	; De waarde van dit register wordt teruggezonden door de slave als de master om een slave-transmit vraagt
.def TWI_Address	= R23
.def TWI_Data		= R24
.def TWI_AddrRW		= R25
;--------------------------/



;--- Macros ---------------------------\
.MACRO StartWaitState					; start wait state
	sbi		TWI_DDR, TWI_SCL			; 							[sbi DDRD,DDD4]
	;LED_Aan LED_Waitstate
.ENDMACRO

.MACRO EndWaitState						; end wait state
	;LED_Uit LED_Waitstate
	cbi		TWI_DDR, TWI_SCL			; 							[cbi DDRD,DDD4]
.ENDMACRO


.MACRO WaitFor_SCL_Low					; wacht totdat SCL laag wordt (zolang SCL hoog is)
_1:	sbic	TWI_PIN, TWI_SCL			; 							[sbic PIND,PIND4]
	rjmp	_1
.ENDMACRO

.MACRO WaitFor_SCL_High					; wacht totdat SCL hoog wordt (zolang SCL laag is)
_1:	sbis	TWI_PIN, TWI_SCL			; 							[sbis PIND,PIND4]
	rjmp	_1
.ENDMACRO


.MACRO WaitFor_SDA_Low					; wacht totdat SDA laag wordt (zolang SDA hoog is)
_1:	sbic	TWI_PIN, TWI_SDA			; 							[sbic PIND,PIND2]
	rjmp	_1
.ENDMACRO

.MACRO WaitFor_SDA_High					; wacht totdat SDA hoog wordt (zolang SDA laag is)
_1:	sbis	TWI_PIN, TWI_SDA			; 							[sbis PIND,PIND2]
	rjmp	_1
.ENDMACRO


.MACRO Release_SDA						; SDA vrijgeven
	cbi		TWI_DDR, TWI_SDA			; 							[cbi DDRD,DDD2]
	; door de pull-up weerstanden wordt het niveau omhoog getrokken
.ENDMACRO

.MACRO Force_SDA						; SDA laag forceren
	sbi		TWI_DDR, TWI_SDA			; 							[sbi DDRD,DDD2]
.ENDMACRO


.MACRO Acknowledge						; Acknowledge-signaal op SDA
	Force_SDA							; 							[sbi DDRD,DDD2]
.ENDMACRO

.MACRO NotAcknowledge					; NOT-Acknowledge-signaal op SDA
	Release_SDA							; 							[cbi DDRD,DDD2]
.ENDMACRO

.MACRO WriteACK_ToMaster				; Een ACK sturen naar de master(receiver)
	Acknowledge
	WaitFor_SCL_High
	;WaitFor_SCL_Low
	;Release_SDA
.ENDMACRO

.MACRO WriteNACK_ToMaster				; Een NACK sturen naar de master(receiver)
	NotAcknowledge
	WaitFor_SCL_High
	WaitFor_SCL_Low
	Release_SDA
.ENDMACRO

.MACRO ReadAcknowledge_FromMaster		; Een (N)ACK op SDA lezen van de master in de carryflag
	;Release_SDA
	WaitFor_SCL_High
	SDA_To_CarryFlag
	WaitFor_SCL_Low
.ENDMACRO


.MACRO WaitForActivity					; wacht op een signaalverandering op SDA/SCL
	in		R16, TWI_PIN				; sample SDA & SCL
	andi	R16, (1<<TWI_SCL|1<<TWI_SDA)
_1:	in		R17, TWI_PIN				; sample SDA & SCL
	andi	R17, (1<<TWI_SCL|1<<TWI_SDA)
	cp		R16, R17					; vergelijk
	breq	_1							; zolang er geen verandering is opgetreden, blijven proberen
.ENDMACRO


.MACRO If_ChangedToLow_JumpTo;(TWI_Pin, Label)
	; pinsignaal moet tevoren dus op 1 staan..
	sbrs	R16, @0
	rjmp	_1
	; het signaal stond op 1; Nu kijken of het naar 0 is veranderd..
	sbrs	R17, @0
	rjmp	@1
_1:	nop
.ENDMACRO

.MACRO If_ChangedToHigh_JumpTo;(TWI_Pin, Label)
	; pinsignaal moet tevoren dus op 0 staan..
	sbrc	R16, @0
	rjmp	_1
	; het signaal stond op 0; Nu kijken of het naar 1 is veranderd..
	sbrc	R17, @0
	rjmp	@1
_1:	nop
.ENDMACRO


.MACRO If_Low_JumpTo;(TWI_Pin, Label)	; "IF (R17 && (1<<TWI_Pin))=0 THEN GOTO Label"
	sbrs	R17, @0						; Als het signaal van 'TWI_Pin' nu laag is..
	rjmp	@1							; .. dan springen naar 'Label'
.ENDMACRO

.MACRO If_High_JumpTo;(TWI_Pin, Label)	; "IF (R17 && (1<<TWI_Pin))=1 THEN GOTO Label"
	sbrc	R17, @0						; Als het signaal van 'TWI_Pin' nu hoog is..
	rjmp	@1							; .. dan springen naar 'Label'
.ENDMACRO

.MACRO If_SCL_Low_JumpTo;(Label)		; Als SCL laag is, springen naar 'Label'
	If_Low_JumpTo TWI_SCL, @0			;
.ENDMACRO

.MACRO If_SCL_High_JumpTo;(Label)		; Als SCL hoog is, springen naar 'Label'
	If_High_JumpTo TWI_SCL, @0			;
.ENDMACRO

.MACRO If_SDA_Low_JumpTo;(Label)		; Als SDA laag is, springen naar 'Label'
	If_Low_JumpTo TWI_SDA, @0			;
.ENDMACRO

.MACRO If_SDA_High_JumpTo;(Label)		; Als SDA hoog is, springen naar 'Label'
	If_High_JumpTo TWI_SDA, @0			;
.ENDMACRO


.MACRO If_Low_Call;(TWI_Pin, Label)	; "IF (R17 && (1<<TWI_Pin))=0 THEN GOTO Label"
	sbrs	R17, @0						; Als het signaal van 'TWI_Pin' nu laag is..
	rcall	@1							; .. dan de sub op adres 'Label' aanroepen
.ENDMACRO

.MACRO If_High_Call;(TWI_Pin, Label)	; "IF (R17 && (1<<TWI_Pin))=1 THEN GOTO Label"
	sbrc	R17, @0						; Als het signaal van 'TWI_Pin' nu hoog is..
	rcall	@1							; .. dan de sub op adres 'Label' aanroepen
.ENDMACRO

.MACRO If_SCL_Low_Call;(Label)			; Als SCL laag is, springen naar 'Label'
	If_Low_Call TWI_SCL, @0				;
.ENDMACRO

.MACRO If_SCL_High_Call;(Label)			; Als SCL hoog is, springen naar 'Label'
	If_High_Call TWI_SCL, @0				;
.ENDMACRO

.MACRO If_SDA_Low_Call;(Label)			; Als SDA laag is, springen naar 'Label'
	If_Low_Call TWI_SDA, @0				;
.ENDMACRO

.MACRO If_SDA_High_Call;(Label)			; Als SDA hoog is, springen naar 'Label'
	If_High_Call TWI_SDA, @0				;
.ENDMACRO


.MACRO SDA_To_CarryFlag					; de status van SDA overnemen naar de carryflag.
	sec									;
	sbis	TWI_PIN, TWI_SDA			;							[sbis PIND,PIND4]
	clc									;
.ENDMACRO

.MACRO CarryFlag_To_SDA					; de status van de carryflag overnemen naar SDA.
	brcs	_1
	Force_SDA
_1:	brcc	_2							; rjmp _2
	Release_SDA	
_2:	nop
.ENDMACRO


.MACRO ReceiveBit						; Een bit ontvangen van de bus en plaatsen in de carryflag
	; de master plaatst nu de bitwaarde op de bus..
	WaitFor_SCL_High
	; de bitwaarde op de bus is nu geldig om te ontvangen/lezen..
	SDA_To_CarryFlag					; De bitwaarde van de bus naar de carryflag overnemen
	WaitFor_SCL_Low
.ENDMACRO

.MACRO ReceiveBits;(Register)			; De resterende 7 bits van een byte ontvangen van de bus en plaatsen in 'Register'
_1:	ReceiveBit							; een bit ontvangen
	rol		@0							; in het 'Register' schuiven
	brcc	_1							; ..zit de initiële bit 0 nu in de carryflag?
.ENDMACRO

.MACRO ReceiveByte;(Register)			; Een byte ontvangen van de bus en plaatsen in 'Register'
	ldi		@0, 0b00000001				; bit 0 van het 'Register' op 1 zetten..
	ReceiveBits @0						; nested macro-calls gaan weer vanaf avrasm2-beta3..
.ENDMACRO


.MACRO TransmitBit
	; de slave zet nu de bitwaarde op de bus..
	CarryFlag_To_SDA
	WaitFor_SCL_High
	WaitFor_SCL_Low
	Release_SDA
.ENDMACRO

.MACRO TransmitByte;(Register)			; Een byte verzenden
	sec
	rol		@0
_1:	TransmitBit
	lsl		@0
	brne	_1
.ENDMACRO
;--------------------------------------/


;---------------------------------------
;--- WaitFor_Activity
;--------------------------------------\
WaitFor_Activity:
	WaitForActivity
	ret
;--------------------------------------/


;---------------------------------------
;--- WaitFor_STOP
;--------------------------------------\
WaitFor_STOP:
	WaitFor_SCL_High					; wacht op een opgaande flank op SCL (van 0 naar 1 dus)
	rcall	WaitFor_Activity			; wacht nu op een opgaande flank op SDA (van 0 naar 1)
	If_ChangedToHigh_JumpTo TWI_SDA, Done_WaitFor_STOP
	rjmp	WaitFor_STOP				; blijven proberen...
Done_WaitFor_STOP:
	ret
;--------------------------------------/


;---------------------------------------
;--- TWI_Initialize
;--------------------------------------\
TWI_Initialize:
	; SCL & SDA als open collector instellen
	cbi		TWI_DDR, TWI_SCL
	cbi		TWI_PORT, TWI_SCL
	cbi		TWI_DDR, TWI_SDA
	cbi		TWI_PORT, TWI_SDA
	ret
;--------------------------------------/



;---------------------------------------
;--- InComingData (binnenkomende data)
;--- input: TWI_Data
;--------------------------------------\
InComingData:
	push	R16
	; TWI_Data opslaan na ontvangst
	mov		Reply, TWI_Data
	; afbeelden op LCD
	mov		R16, TWI_Data
	; is het een code BS (BackSpace)?
	cpi		R16, 8
	brne	testLF
	rcall	LCD_BackSpace
	rjmp	Done_InComingData
	; is het een code LF (Line Feed)?
testLF:
	cpi		R16, 10
	brne	testCR
	;rcall	LCD_NextLine
	rjmp	Done_InComingData
	; is het een code CR (Carriage Return)?
testCR:
	cpi		R16, 13
	brne	filterLowerASCII
	rcall	LCD_NextLine
	rjmp	Done_InComingData
	; filter resterende codes:   8 <= code < $20
filterLowerASCII:
	cpi		R16, 8
	brlo	ToLCD
	cpi		R16, $20
	brsh	ToLCD
	rjmp	Done_InComingData

ToLCD:
	rcall	LCD_LinePrintChar

Done_InComingData:
	pop		R16
	ret
;--------------------------------------/

;---------------------------------------
;--- OutGoingData (uitgaande data)
;--- output: TWI_Data
;--------------------------------------\
OutGoingData:
	; TWI_Data laden om te verzenden
.if PRG == 0
	mov		TWI_Data, Reply
.elif PRG == 1
	push	R16
	rcall	LCD_GetDisplayAddr
	mov		TWI_Data, R16
	pop		R16
.endif
	ret
;--------------------------------------/



;---------------------------------------
;--- ScanBus
;--------------------------------------\
HandleTransaction:
	; De signalen op de lijnen SCL en SDA zijn nu hoog (bus niet bezet)
	rcall	WaitFor_Activity
	If_Low_JumpTo TWI_SCL, BusBusy
	If_Low_JumpTo TWI_SDA, StartCondition
	; SDA is zojuist hoog geworden.. Een STOP-conditie (bus vrij)
	rjmp	Done_HandleTransaction

StartCondition:
	LED_Aan LED_TWI_Activity
	;LED_Uit LED_TWI_In
	;LED_Uit LED_TWI_Out
	; Een START-conditie op de bus, nu is SCL=1 SDA=0..
	WaitFor_SCL_Low
	; Nu een byte lezen van de bus [7-bit Adres + RW]
	ReceiveByte TWI_AddrRW
	; Het ontvangen slave-adres bepalen
	mov		TWI_Address, TWI_AddrRW
	lsr		TWI_Address
	; Het ontvangen slave-adres vergelijken met dat van deze slave
	cpi		TWI_Address, Slave_Address
	breq	AddressMatch

AddressMiss:
	; Een Address-Miss is geconstateerd..
	; Nu een NOT-ACK sturen naar de (master)transmitter
	WriteNACK_ToMaster
	;wacht op een STOP-conditie (bus vrij)
	rjmp	Do_Handle_Stop

AddressMatch:
	LED_Aan LED_TWI_AddrMatch
	; Een Address-Match is geconstateerd..
	; Nu een ACKnowledge sturen naar de master-transmitter voor ontvangst van de byte
	Acknowledge
	;WriteACK_ToMaster
	; De richting bepalen (lezen/schrijven)
	andi	TWI_AddrRW, 0b00000001		; bit 0 waarde: 0=write, 1=read
	brne	Do_Handle_MasterRead

Do_Handle_MasterWrite:					; Slave-read
	;LED_Aan LED_TWI_In
	WaitFor_SCL_High					; wacht tot de ACK-puls begint
	WaitFor_SCL_Low
	Release_SDA
	; Controleer op een REPEATED START.
	; wacht op SCL hoog
	; sample SDA
	; wacht op activiteit
	; als SDA nu laag is, dan is een Sr voorgevallen  (-> wacht op SCL laag en lees byte TWI_AddrRW)
	; anders als SCL laag is geworden, hebben we het eerste bit van de volgende te lezen byte ontvangen (sample SDA)
	WaitFor_SCL_High
	ldi		TWI_Data, 0b00000001		; Een byte proberen te ontvangen in TWI_Data
	SDA_To_CarryFlag					; bit ontvangen..
	rol		TWI_Data					; ..en in TWI_Data schuiven
	rcall	WaitFor_Activity
	If_Low_JumpTo TWI_SCL, ReceivedBit7
	If_Low_JumpTo TWI_SDA, StartCondition
	; SDA is zojuist hoog geworden.. Een STOP-conditie (bus vrij)
	rjmp	Done_HandleTransaction
ReceivedBit7:
	; De byte van de bus ontvangen
	ReceiveBits TWI_Data
	Acknowledge							; Een ACK alvast op de bus plaatsen..
	;--- Nu de inkomende data verwerken
	; een waitstate starten tussen bit 0 en de ACK-puls..
	StartWaitState
	rcall	InComingData				; TWI_Data opslaan
	EndWaitState
	;---
	rjmp	Do_Handle_MasterWrite		; meer bytes te ontvangen?

Do_Handle_MasterRead:					; Slave-Write
	;LED_Aan LED_TWI_Out
	;--- Nu de uitgaande data verwerken
	StartWaitState
	rcall	OutGoingData				; TWI_Data ophalen..
	EndWaitState
	;---
	WaitFor_SCL_High					; wacht op de start van de ACK-puls
	WaitFor_SCL_Low						; wacht op het einde van de ACK puls
	Release_SDA
	; De byte naar de bus schrijven
	TransmitByte TWI_Data
	; Nu een (NOT-)ACKnowledge van de master(transmitter) ontvangen
	ReadAcknowledge_FromMaster
	brcc	Do_Handle_MasterRead			; na het ontvangen van een ACK meer bytes gaan ontvangen..
	; Er is een NOT-ACKnowledge ontvangen van de master(transmitter)
	; Nu wachten op een REPEATED START of STOP conditie
	WaitFor_SCL_High
	rjmp	HandleTransaction

BusBusy:
	; De bus is bezet.
	LED_Aan LED_Error					; bus bezet op een ongewenst moment..Error LED laten branden ter indicatie

Do_Handle_Stop:
	; Wacht nu op een STOP-conditie..
	rcall	WaitFor_STOP

Done_HandleTransaction:
	LED_Uit LED_TWI_Activity
	LED_Uit LED_TWI_AddrMatch
	LED_Uit LED_Error
	;LED_Uit LED_TWI_In
	;LED_Uit LED_TWI_Out
	ret
;--------------------------------------/
