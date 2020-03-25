;-------------------------------------------------------------------
;--- Een Digital Accessory Decoder voor de trein-modelbouw
;---
;---	CK = 7.372800 MHz
;---	TCK = CK/8
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us (10ms)
;---
;---	          __    __
;---	         |  |  |  |  |
;---	         |pB|  |  |  |
;---	------+--+  +--+  +--+
;---	      .pA.  .  .  .  .      pA = periode A
;---	      .  .  .  .  .  .      pB = periode B
;---	      ....  ....  ....	     . = signaal door booster gemaakt
;---
;---	         *     *     *       * = verwerk periode A
;---	      #     #     #          # = verwerk periode B
;---
;-------------------------------------------------------------------

;--- Accessory Decoder packet DCCByte2 (1AAACDDD)
;---		DD D bits                     DD D bits
;---				 +-------------+
;---		00 0/	-|B0         A0|-	\ 00 0
;---		   1\	-|B1         A1|-	/    1
;---		01 0/	-|B2         A2|-	\ 01 0
;---		   1\	-|B3         A3|-	/    1
;---		10 0/	-|B4         A4|-	\ 10 0
;---		   1\	-|B5         A5|-	/    1
;---		11 0/	-|B6         A6|-	\ 11 0
;---		   1\	-|B7         A7|-	/    1
;---				 |             |		
;---				 |             |		
;---				 |             |		
;---				 |           C7|-	\ 11 1
;---				 |           C6|-	/    0
;---	   UART RxD	-|D0         C5|-	\ 10 1
;---	   UART TxD	-|D1         C4|-	/    0
;---	switch INT0 -|D2         C3|-	\ 01 1
;---		  LED A	-|D3         C2|-	/    0
;---		  LED B	-|D4         C1|-	\ 00 1
;---		  LED C	-|D5         C0|-	/    0
;---	 DCC-stream -|D6         D7|- DCC-ACK
;---				 +-------------+		
;---
;---	Onze AVR wissel-decoder heeft 3 poorten: A,B & C met elk 8 wissels.
;---	Poort A beslaat DCC wissel-adres: [A_CV_521:A_CV_513]	=>	521 bevat hoogste 3 bits, 513 de laagste 6 bits
;---	Poort B beslaat DCC wissel-adres: [B_CV_521:B_CV_513]		(in CV formaat opgeslagen dus..)
;---	Poort C beslaat DCC wissel-adres: [C_CV_521:C_CV_513]
;---
;--- Een packet voor Basic Accessory Decoders:
;--- De 3 DDD-bits bepalen om welke pin van een AVR-poort het gaat.
;--- DDD==0? dan pin 0, DDD==6? dan pin 6 van de AVR-poort.
;--- De C-bit bepaalt de activering of de-activering van de pin.
;--- Bij de-activering gaat het signaal uit op de beide pins van het output-paar van de betreffende wissel.
;--- Bij activering komt er signaal op alleen de pin aangegeven met de DDD-bits.
;---
;--- De verbonden schakelaar (op PD2 "INT0") is om de decoder in "learn-mode" te schakelen.
;--- De LED's A,B of C geven aan, welke decoder is geselecteerd in "learn-mode".
;--- Als een adres is gestuurd, en de decoder het adres heeft "geleerd", gaat de betreffende LED weer uit
;--- en wordt de "learn-mode" beeindigd.
;---
;--- Om de timeout-waarden voor Functie1,F2,F3 & F4 te regelen, is Timer2 in gebruik.
;--- Deze timercounter moet een resolutie hebben van 10ms. (tellen in stappen van 10ms dus..)
;--- Timer2 is een 8-bits timer/counter MET een compare-match mogelijkheid.
;--- De prescale wordt ingesteld op: TCK=CK/1024 ticks per seconde
;--- Elke 10ms komen er dan: TCK*0.01 ticks (waarde is ver binnen bereik 8bit voor elke bestaande AVR)
;---
;--- Timer0 is in gebruik om het ACK-signaal te genereren (6ms, +-1ms) op PD7.
;--- Deze timer is 8bit en is alleen een timercounter die kan tellen en overlopen (er is verder geen compare-match
;--- noch een input-capture of wat dan ook). De timer0 is daarom zo ingesteld, dat er T0-OVF interrupts worden
;--- gebruikt om de ACK-duur te meten/bepalen.
;-------------------------------------------------------------------


;--- Configuration Variables voor Accessory Decoders:
;--- VERPLICHT
;---	Decoder Address LSB					513		6 LSB of accessory decoder address
;---	Decoder Address MSB					521		3 MSB of accessory decoder address
;---	Manufacturer Version Info			519		Manufacturer defined version info (READONLY)
;---	Manufacturer ID						520		Values assigned by NMRA (READONLY)
;---	Accessory Decoder Configuration		541		similar to CV#29 (Configuration Data #1); for acc. decoders
;--- OPTIONEEL
;---	Auxiliary Activation				514		Auxiliary activation of outputs
;---	Time On F1							515
;---	Time On F2							516
;---	Time On F3							517
;---	Time On F4							518
;---
;--- CV520: "Public Domain & Do-It-Yourself Decoders" heeft waarde: 00001101 = 0x0D = 13
;---
;--- Instructions packets using Direct CV Addressing are 4 byte packets of the format:
;---	long-preamble 0 0111CCAA 0 AAAAAAAA 0 DDDDDDDD 0 EEEEEEEE 1
;-------------------------------------------------------------------

;---------------------------------------
; Een Basic Accessory Decoder packet is 3 bytes groot.
; Een Extended packet is 3 t/m 6 bytes groot.
; Packets 1e byte Adres bereiken:
;	00000000			(0)						Broadcast address
;	00000001-01111111	(1-127)(inclusive)		Multi-Function decoders with 7 bit addresses
;	10000000-10111111	(128-191)(inclusive)	Basic Accessory Decoders with 9 bit addresses and
;												Extended Accessory Decoders with 11-bit addresses
;	11000000-11100111	(192-231)(inclusive)	Multi Function Decoders with 14 bit addresses
;	11101000-11111110	(232-254)(inclusive)	Reserved for Future Use
;	11111111			(255)					Idle Packet
;---------------------------------------
;* {instruction-bytes} declaraties: C = instruction bit, D = data bit
; {instruction-bytes} =	CCCDDDDD,
;						CCCDDDDD 0 DDDDDDDD, or
;						CCCDDDDD 0 DDDDDDDD 0 DDDDDDDD 1
;
; * Configuration Variable Access Instruction (111):
; (Configuration Variable Access Instruction - Short Form:	{instruction byte} = 1111CCCC DDDDDDDD		!!niet gebruikt door UJE)
; Configuration Variable Access Instruction - Long Form:	{instruction byte} = 1110CCAA AAAAAAAA DDDDDDDD
; AA AAAAAAAA = 10-bit CV adres + 1 (2MSB-8LSB)				=> CV #1 = 00 00000000
; CC = 00	Reserved for future use
; CC = 01	Verify byte			
; CC = 10	Write byte
; CC = 11	Bit manipulation
; Verify Byte: The contents of the Configuration Variable as indicated by the 10 bit address are compared with the data
;	byte (DDDDDDDD). If the decoder successfully receives this packet and the values are identical, the Digital Decoder 
;	shall respond with an the contents of the CV as the Decoder Response Transmission, if enabled.
;	Write Byte: The contents of the Configuration Variable as indicated by the 10 bit address are replaced by the data byte
;	(DDDDDDDD). Two identical packets are needed before the decoder shall modify a configuration variable. 
;	These two packets need not be back to back on the track. However any other packet to the same decoder will
;	invalidate the write operation. (This includes broadcast packets.) If the decoder successfully receives this second
;	identical packet, it shall respond with a configuration variable access acknowledgment.
;
;* Basic Accessory Decoder Packet address for operations mode programming:
; {instruction byte} = 10AAAAAA 1AAACDDD
;	AAAAAA AAA = decoder adres (2e byte 3 bits geinverteerd als MSB, 1e byte bits als LSB)
;	Where DDD is used to indicate the output whose CVs are being modified and C=1.
;	If CDDD= 0000 then the CVs refer to the entire decoder. The resulting packet would be:
;	{preamble} 10AAAAAA 0 1AAACDDD 0 (1110CCAA 0 AAAAAAAA 0 DDDDDDDD) 0 EEEEEEEE 1
;			Accessory-Decoder-Address (Configuration-Variable-Access-Instruction) Error-Byte
;* Extended Decoder Control Packet address for operations mode programming:
; {instruction byte} = 10AAAAAA 0AAA0AA1
;	{preamble} 10AAAAAA 0 0AAA0AA1 0 (1110CCAA 0 AAAAAAAA 0 DDDDDDDD) 0 EEEEEEEE 1
;			Accessory-Decoder-Address (Configuration-Variable-Access-Instruction) Error-Byte
;---------------------------------------
;
; {error detection byte} = EEEEEEEE
; De waarde van het error-detection byte = adres-byte XOR instruction-byte
;---------------------------------------
;
; 11111111 00000000 11111111	Idle packet
; 00000000 00000000 00000000	Reset packet
; 00000000 01DC0001 EEEEEEEE	Broadcast stop
;
;---------------------------------------
; The format for packets intended for Basic Accessory Digital Decoders is:
;	{preamble} 0 10AAAAAA 0 1AAACDDD 0 EEEEEEEE 1
; Broadcast Command for Basic Accessory Decoders:
;	{preamble} 0 10111111 0 1000CDDD 0 EEEEEEEE 1
;
; The Extended Accessory Decoder Control Packet:
;	{preamble} 0 10AAAAAA 0 0AAA0AA1 0 000XXXXX 0 EEEEEEEE 1
; Broadcast Command for Extended Accessory Decoders:
;	{preamble} 0 10111111 0 00000111 0 000XXXXX 0 EEEEEEEE 1
;-------------------------------------------------------------------
;
; NMRA commando overzicht: http://srcpd.sourceforge.net/srcp/srcp-0.7.3-engl.pdf
; voorbeeldje:	SET GA N <addr> <port> <action> <delay>
;				WRITE GA <protocol> <dest-type> <dest-addr> <value>
;				VERIFY GA N <dest-type> <dest-addr> <value>
; Dat ziet er dan ongeveer zo uit:
;				WRITE GA N CV 541 128
;				VERIFY GA N CV 541 128
;-------------------------------------------------------------------

;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
;.list
;--------------------------------------/

;--- COMPILER DIRECTIVES --------------\
.equ Packet4Bytes		= 1				; test op 4 byte ACC.Decoder
.equ Packet6Bytes		= 1				; test op 6 byte ACC.Decoder
.equ Do_ServiceMode		= 1				; test op (4 byte) ServiceMode-packets
.equ Do_OperationsMode	= 0				; test op (6 byte) OperationsMode-packets
.equ ValidAddrOnly		= 1				; test op geldige, ingestelde DCC AC-adressen
.equ ShowPacketBytes	= 1				; complete packet inhoud afbeelden (hexadecimaal)
.equ ShowDCCAddress		= 1				; het DCC-Accessory adres afbeelden (decimaal)
.equ ShowAVRpin			= 1				; de doel-pin op de AVR afbeelden
.equ ShowAVRport		= 1				; de doel-poort op de AVR afbeelden
.equ ShowServiceMode	= 1				; afbeelden of een Service-Mode packet is ontvangen
.equ ShowCVAddress		= 1				; het CV# afbeelden (bij CV-programmeer acties)
.equ ShowCVAction		= 1				; de (CV-programmeer-)actie afbeelden (VERIFY/WRITE/BIT)
.equ InvertOutput		= 0				; alle wissel-uitgangen inverteren
.equ SeinDecoder		= 1				; functioneren als sein- ipv wissel-decoder
.equ ExecuteLearnPacket	= 0				; de instructie in het "learn-address" packet meteen uitvoeren na "leren"
.equ GenerateFTimeouts	= 0				; Timeouts voor Functies zelf genereren (per 10ms instelbaar)
.equ GenerateACKsignal	= 1				; Een extra ACK signaal maken op PD7
;--------------------------------------/


;--- CONSTANTEN -----------------------\
.equ CK 			= 7372800			; CPU clock frequentie	; 7372800
.equ TCK 			= CK/8				; timer1 frequentie		; CK/8
.equ Min1 			= 0.000052 * TCK	; duur van een (halve/positieve) bit (in timerticks)
.equ Max1 			= 0.000064 * TCK
.equ Min0 			= 0.000090 * TCK
.equ Max0 			= 0.010000 * TCK
; tbv. de ACK puls
.equ TCK0			= CK/64				; timer0 frequentie		; CK/64 = 115200 Hz
.equ TOVFCK			= TCK0/256			; timer0 overflow freq.	; TCK0/8b = 450 Hz (0.00222s)
.equ TOVFCount_ACK	= 0.006*TOVFCK		; 6ms == hoeveel OVF's?	; 6ms / (1/TOVFCK)
; de schakelaar voor de "Learnig-Mode"
.equ SwitchesDDR	= DDRD
.equ SwitchesPort	= PORTD
.equ SwitchesIn		= PIND
.equ SwitchPin		= PD2				; PD2 = INT0
; 3 LED's voor aanduiding welke learn-mode decoder is geselecteerd
.equ LEDsDDR		= DDRD
.equ LEDsPort		= PORTD
.equ LED_A			= PD3
.equ LED_B			= PD4
.equ LED_C			= PD5
; input capture pin op AVR verbonden met de DCC-stream
.equ CaptureDDR		= DDRD
.equ CapturePort	= PORTD
.equ CaptureIn		= PIND
.equ CapturePin		= PD6
; de DCC-ACKnowledge pin op de AVR
.equ ACKDDR			= DDRD
.equ ACKPort		= PORTD
.equ ACKIn			= PIND
.equ ACKPin			= PD7
; strings/chars
.equ CHR_0				= '0'
.equ CHR_1				= '1'
.equ CHR_ErrorDetected	= '*'
; stappen in het proces: ontvangen packet
.equ _Preamble			= 0				; wachten totdat PreambleCount=12
.equ _DataStartBit		= 3				; ==0? ..een data-byte volgt, ==1? ..packet-end
.equ _DataByte			= 4				; 8-bits ontvangen, daarna goto step 3 _DataStartBit
;---------------------------------------
; vlaggen voor de "learn-mode" (register "LearnModeFlags")
.equ NormalOperation	= (0<<7)		; bit7==0?  niet in learn-mode
.equ NotLearning		= NormalOperation
.equ Learning_			= 7				; bit7==1?  dan is de decoder in learn-mode..anders niet
.equ LearnC_			= 2				; bit2==1?  Decoder C geselecteerd
.equ LearnB_			= 1				; bit1==1?  Decoder B geselecteerd
.equ LearnA_			= 0				; bit0==1?  Decoder A geselecteerd
.equ Learning			= (1<<Learning_)
.equ LearnC				= (1<<LearnC_)
.equ LearnB				= (1<<LearnB_)
.equ LearnA				= (1<<LearnA_)
;--------------------------------------/


;--- REGISTER ALIASSEN ----------------\
.def ACK_OVFCounter	= R7				; de timer0 OVF's timeout-counter tbv. de ACK-puls
.def Mask0			= R8				; AVR poort masker voor de pin (van een paar outputs) van een aangesloten wissel
.def DecAddrHPortA	= R9				; MSB adres van decoder op poort A
.def DecAddrLPortA	= R10				; LSB adres van decoder op poort A
.def DecAddrHPortB	= R11				; MSB adres van decoder op poort B
.def DecAddrLPortB	= R12				; LSB adres van decoder op poort B
.def DecAddrHPortC	= R13				; MSB adres van decoder op poort C
.def DecAddrLPortC	= R14				; LSB adres van decoder op poort C
.def LearnModeFlags	= R15				; vlaggen voor de "learn-mode" (poort-selectie/LED's)
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17				; nog 1..
.def temp3			= R18				; en nog 1..
.def PreambleCount	= R19				; aantal sequentiele "1"-bits ontvangen
.def Step			= R20				; de huidige stap in proces ontvangen bitstream
.def DataByte		= R21				; de opgespaarde bits van de huidige databyte
.def DCCByte1		= R22				; bytes in de buffer: 1e byte
.def DCCByte2		= R23				; bytes in de buffer: 2e byte
.def DCCByte3		= R24				; bytes in de buffer: 3e byte
.def DCCByte4		= R25				; bytes in de buffer: 4e byte
;.def XL								; pointer naar te schrijven adres in PacketStream
;.def XH
.def DCCByte5		= R28				; bytes in de buffer: 5e byte
.def DCCByte6		= R29				; bytes in de buffer: 6e byte
;.def ZL								; bitduur in timerticks voor periode B
;.def ZH								;   "  "
;--------------------------------------/


;--- Variablelen in SRAM --------------\
.DSEG
PacketStream:		.BYTE 16			; 16 bytes data voor de stream (zeker genoeg..)
PacketStreamCount:	.BYTE 1				; het aantal bytes in deze buffer
;--------------------------------------/


;--- CVariablelen in EEPROM -----------\
.ESEG
; de decoder die poort A gebruikt
;.equ A_TrueAddress	= 2					; het DCC-AC adres van decoder A
A_CV_521:	.db $00	;521 Decoder Address MSB = 3 MSB of accessory decoder address
A_CV_513:	.db $02	;513 Decoder Address LSB = 6 LSB of accessory decoder address
; de decoder die poort B gebruikt
;.equ A_TrueAddress	= 3					; het DCC-AC adres van decoder B
B_CV_521:	.db $00	; MSB
B_CV_513:	.db $03	; LSB
; de decoder die poort C gebruikt
;.equ A_TrueAddress	= 6					; het DCC-AC adres van decoder C
C_CV_521:	.db $00	; MSB
C_CV_513:	.db $06	; LSB
;--------------------------------------/


;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp HANDLER_SWITCH					; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	.if GenerateFTimeouts == 1
		rjmp HANDLER_10MS				; Timer2 compare match Vector Address
	.else
		reti							; Timer2 compare match Vector Address
	.endif
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	.if GenerateACKsignal == 1
		rjmp HANDLER_ACK				; Overflow0 Interrupt Vector Address
	.else
		reti							; Overflow0 Interrupt Vector Address
	.endif
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/


;--- Teksten in Code Segment ----------\
;!!!!! teksten moeten een even aantal bytes lang zijn !!!!!
.CSEG
MsgWisselAdr:		.db "Decoders ABC CV-addr: ", EOS_Character
MsgWisselDecoder:	.db "Decoder-", EOS_Character
MsgWisselLearning:	.db " put into Learn-Mode", EOS_Character
MsgWisselLearned:	.db " learned address: ", EOS_Character
;---
MsgCVWrite:			.db "WRITE ", EOS_Character
MsgCVVerify:		.db "VERIFY", EOS_Character
MsgCVBit:			.db "BIT ", EOS_Character
;---
MsgServiceMode:		.db "<Service Mode>", EOS_Character
MsgOperationsMode:	.db "<Operation Mode>", EOS_Character
;--------------------------------------/


;--- INCLUDE FILES --------------------\
.include "8535_EEPROM.asm"				; EEPROM lezen/schrijven
.include "RS232.asm"					; UART routines
.include "NumToStr.asm"					; nummers afbeelden
;--------------------------------------/










;---------------------------------------
;--- MACRO's
;--------------------------------------\
.MACRO initStackPointer					; De stack-pointer instellen op het einde van het RAM
	ldi		temp2, high(RAMEND)
	ldi		temp, low(RAMEND)
	out		SPH, temp2
	out		SPL, temp
.ENDMACRO


.MACRO ResetCounter						; de TimerCounter1 op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO ReadCounter;(ValueH,ValueL: register)	; de TimerCounter1 uitlezen in registers "ValueH" & "ValueL"
	in		@1, TCNT1L
	in		@0, TCNT1H
.ENDMACRO


; wachten op de volgende flank toggle op de capture-pin
.MACRO WaitFor1							; wacht op een opgaande flank
_0:	sbis	CaptureIn, CapturePin
	rjmp	_0
.ENDMACRO

.MACRO WaitFor0							; wacht op een neergaande flank
_0:	sbic	CaptureIn, CapturePin
	rjmp	_0
.ENDMACRO


; controleren op geldige "0"- & "1"-bits
.MACRO CheckPuls;(ValueH,ValueL: register)
;
; <<#####|      1      |##########|      0      |#####>>		(# = ongeldig)
;        ^             ^          ^             ^
;        Min1_______Max1          Min0_______Max0
;

	; Value < Min1 ?
	cpi		@1, low(Min1)
	ldi		temp, high(Min1)
	cpc		@0, temp
	brlo	_2							; bit ongeldig
	; Value <= Max1 ?
	cpi		@1, low(Max1+1)
	ldi		temp, high(Max1+1)
	cpc		@0, temp
	brlo	_1							; geldige "1"
	; Value < Min0 ?
	cpi		@1, low(Min0)
	ldi		temp, high(Min0)
	cpc		@0, temp
	brlo	_2							; bit ongeldig
	; Value <= Max0 ?
	cpi		@1, low(Max0+1)
	ldi		temp, high(Max0+1)
	cpc		@0, temp
	brlo	_0							; geldige "0"
_2:	;ongeldige bit
	rjmp	_3
_0:	; een geldige "0"
	HANDLE_0							; Verwerk een geldige "0"-bit
	rjmp	_3
_1:	; een geldige "1"					; Verwerk een geldige "1"-bit
	HANDLE_1
_3:	
.ENDMACRO


.MACRO HANDLE_0
	cpi		Step, _Preamble
	brne	_3
	;----------------------------------\
	cpi		PreambleCount, 12			; Preamble = 12 seq. "1"-bits ontvangen
	brlo	_0
	; Er is een "0"-bit ontvangen als sein PacketStartBit
	; De preamble is binnen, goto volgende stap
	ldi		Step, _DataByte
	ldi		DataByte, 1					; opnieuw een byte gaan opsparen van de bus; reset DataByte
	rjmp	_0
	;-------
_3:	cpi		Step, _DataStartBit
	brne	_1
	;----------------------------------\
	; er is een "0"-bit ontvangen als sein DataStartBit
	ldi		Step, _DataByte
	ldi		DataByte, 1					; opnieuw een byte gaan opsparen van de bus; reset DataByte
	rjmp	_0
	;-------
_1:	cpi		Step, _DataByte
	brne	_0
	;----------------------------------\
	lsl		DataByte					; een "0" inschuiven in DataByte
	brcc	_0							; nog geen 8 bits gehad? dan goto _0
	; byte is binnen. goto volgende stap
	ldi		Step, _DataStartBit
	; bewaren in SRAM buffer
	PushByteToStream DataByte
	;-------
_0:	clr		PreambleCount				; Preamble detectie resetten
.ENDMACRO

.MACRO HANDLE_1
	inc		PreambleCount				; Preamble detectie teller ophogen
_1:	cpi		Step, _DataByte
	brne	_2
	;----------------------------------\
	lsl		DataByte
	brcs	_3							; 8 bits gehad? dan goto _3
	ori		DataByte, 1					; er is een "1"-bit voor de DataByte ontvangen; inschuiven in DataByte
	rjmp	_0
_3:	; byte is binnen. goto volgende stap
	ldi		Step, _DataStartBit
	ori		DataByte, 1					; er is een "1"-bit voor de DataByte ontvangen; inschuiven in DataByte
	; bewaren in SRAM buffer
	PushByteToStream DataByte
	rjmp	_0
	;-------
_2:	cpi		Step, _DataStartBit
	brne	_0
	;----------------------------------\
	; Er is een Packet-End-Bit "1" ontvangen ipv. een Data-Start-Bit "0"
	; begin weer aan een nieuwe packet..
	ldi		Step, _Preamble
	; het packet in de SRAM buffer verwerken..
	; (dit zou tot 5ms mogen duren)
	rcall	ProcessPacket
	;-------
_0:
.ENDMACRO



.MACRO ResetStream
	ldi		XL, low(PacketStream)
	ldi		XH, high(PacketStream)
	; X verwijst nu naar de eerste byte in de PacketStream-buffer..
.ENDMACRO

.MACRO PushByteToStream;(Value:register)
	; X verwijst naar het volgende te schrijven adres in de PacketStream-buffer..
	st		X+, @0						; [X] := @0,  X++
.ENDMACRO

.MACRO Packet_Display
	lds		temp2, PacketStreamCount
	ldi		XL, low(PacketStream)
	ldi		XH, high(PacketStream)
_1:	ld		R16, X+
	rcall	HexByte						; data
	dec		temp2
	brne	_1
	ldi		R16, ':'
	rcall	UART_transmit
_0:	rcall	UART_Space
.ENDMACRO



.MACRO If_NotPacketLength_GoTo;(Address:label; PacketSize:constant8)
	lds		temp, PacketStreamCount
	cpi		temp, @1
	breq	_0							; het is een 3 byte packet..
	rjmp	@0							; Het packet is NIET 3 bytes lang
_0:
.ENDMACRO

.MACRO If_ErrorDetected_GoTo;(Address:label; PacketSize:constant8)
	; controleer het packet mbv. de error-detection
	; dwz. (6 bytes packets:) DCCByte1 XOR DCCByte2 XOR DCCByte3 XOR DCCByte4 XOR DCCByte5 = DCCByte6, anders een error detected..
	mov		temp3, DCCByte1
	eor		temp3, DCCByte2
	.if @1 == 3
		cp		temp3, DCCByte3
	.endif
	.if @1 == 4
		eor		temp3, DCCByte3
		cp		temp3, DCCByte4
	.endif
	.if @1 == 5
		eor		temp3, DCCByte3
		eor		temp3, DCCByte4
		cp		temp3, DCCByte5
	.endif
	.if @1 == 6
		eor		temp3, DCCByte3
		eor		temp3, DCCByte4
		eor		temp3, DCCByte5
		cp		temp3, DCCByte6
	.endif
	breq	_0
	.if ShowPacketBytes == 1
		; er is een fout in de overdracht gedetecteerd. :-(
		ldi		R16, CHR_ErrorDetected
		rcall	UART_transmit
	.endif
	rjmp	@0
_0:	
.ENDMACRO



.MACRO If_IDLEPacket_GoTo;(Address:label)
	cpi		DCCByte1, $FF				; IDLE packet?
	brne	_0
	rjmp	@0							; ja? dan klaar..
_0:
.ENDMACRO

.MACRO If_BroadcastPacket_GoTo;(Address:label)
	; is het een (basic of extended) broadcast packet voor een Accessory Decoder
	; (Byte1=10111111 en Byte2=x111xxxx)
	cpi		DCCByte1, 0b10111111
	brne	_0
	;2e byte (1AAACDDD) waarvan alle A-bits op 1?
	mov		temp3, DCCByte2
	com		temp3						; de 3 A-bits zijn geinverteerd
	andi	temp3, 0b01110000
	brne	_0
	; we hebben een broadcast packet ontvangen voor een Accessory Decoder
	; De 2e byte (1AAACDDD) bevat de C & DDD bits zoals in een Basic packet.
	;
	; ..(voorlopig maar even inslikken die broadcast)
	rjmp	@0
_0:
.ENDMACRO

; een Service-Mode Direct CV-access packet is 4 bytes groot
.MACRO If_NoServiceModePacket_GoTo;(Address:label)
; Instructions packets using Direct CV Addressing are 4 byte packets of the format:
;	long-preamble 0 0111CCAA 0 AAAAAAAA 0 DDDDDDDD 0 EEEEEEEE 1
	; Byte1=0111CCAA?
	mov		temp, DCCByte1
	andi	temp, 0b11110000
	cpi		temp, 0b01110000
	breq	_0							; indien geen CVar operatie? dan skippen..
	rjmp	@0							;
_0:	; Het betreft een Service-Mode packet..
	.if ShowServiceMode == 1
		; informatie afbeelden op COM: poort
		push	ZH
		push	ZL
		ldi		ZH, high(2*MsgServiceMode)
		ldi		ZL, low(2*MsgServiceMode)
		rcall	UART_transmit_String
		pop		ZL
		pop		ZH
		rcall	UART_Space
	.endif
.ENDMACRO

.MACRO If_NoAccessoryPacket_GoTo;(Address:label)
	;adres voor: 	Basic Accessory Decoders with 9 bit addresses and
	;				Extended Accessory Decoders with 11-bit addresses
	;adresbereik:	10000000-10111111 (1e byte in buffer)
	sbrs	DCCByte1, 7					; hoogste bit niet gezet? => geen Accessory Decoder geadresseerd
	rjmp	@0
;	cpi		DCCByte1, 0b11000000		; adres binnen bereik voor Accessory Decoders? (bovengrens)
;	brlo	_0
	sbrc	DCCByte1, 6					; bit gezet? => geen Accessory Decoder geadresseerd
	rjmp	@0							; buiten bereik..klaar.
_0:
.ENDMACRO

.MACRO If_ExtendedPacket_GoTo;(Address:label)
	; als nu bit 7 van de 2e byte is gewist, is een extended packet ontvangen (met een 11-bits adres)
	sbrs	DCCByte2, 7
	; ..(voorlopig maar even inslikken die 11 bitter)
	rjmp	@0
.ENDMACRO

.MACRO If_NoCVProgrammingPacket_GoTo;(Address:label)
;byte 1 & 2: 10AAAAAA 1AAACDDD voldoet
	; Byte3=1110CCAA?
	mov		temp, DCCByte3
	andi	temp, 0b11110000
	cpi		temp, 0b11100000
	breq	_0							; indien geen CVar operatie? dan skippen..
	rjmp	@0							; ..want het is geen Operations-Mode packet..
_0:	; Het betreft een CVar operatie
	; DCCByte5 bevat de CVar databyte, DCCByte6 bevat de error-detection byte
.ENDMACRO

.MACRO If_AddressNotOnboard_GoTo;(Address:label; ValueH,ValueL:register)
	; test of er 1 van de 3 decoders is geadresseerd..
	;	@0:@1 == DecAddrHPortA:DecAddrLPortA ?
	cp		@2, DecAddrLPortA
	cpc		@1, DecAddrHPortA
	brne	_1
	rjmp	_0 ;geldig
	;	@0:@1 == DecAddrHPortB:DecAddrLPortB ?
_1:	cp		@2, DecAddrLPortB
	cpc		@1, DecAddrHPortB
	brne	_2
	rjmp	_0 ;geldig
	;	@0:@1 == DecAddrHPortC:DecAddrLPortC ?
_2:	cp		@2, DecAddrLPortC
	cpc		@1, DecAddrHPortC
	breq	_0
_3:	; ongeldig
	rjmp	@0 ;GEEN_ADRES_VOOR_DEZE_DECODER
_0:	; geldig
.ENDMACRO




; een Speed and Direction byte samenstellen
; invoer:  @1 = register met waarde voor Speed		(waarden: 1..28)
;          @2 = register met waarde voor Direction	(waarden: ==0 achteruit, <>0 vooruit)
; uitvoer: @0 = register met DCC packet byte(2)
.MACRO SpeedDirection_Byte;(ByteValue, Speed,Direction)
	; uitvoer byte formaat: 01DCSSSS
	; CS3S2S1S0	Speed		CS3S2S1S0	Speed		CS3S2S1S0	Speed		CS3S2S1S0	Speed
	; 00000 	Stop		00100		Step 5		01000		Step 13		01100		Step 21
	; 10000		Stop (I)	10100		Step 6		11000		Step 14		11100		Step 22
	; 00001		E-Stop*		00101		Step 7		01001		Step 15		01101		Step 23
	; 10001		E-Stop* (I)	10101		Step 8		11001		Step 16		11101		Step 24
	; 00010		Step 1		00110		Step 9		01010		Step 17		01110		Step 25
	; 10010		Step 2		10110		Step 10		11010		Step 18		11110		Step 26
	; 00011		Step 3		00111		Step 11		01011		Step 19		01111		Step 27
	; 10011		Step 4		10111		Step 12		11011		Step 20		11111		Step 28
	;
	; Bytewaarde = Speed + 3
	ldi		@0, 3
	add		@0, @1
	; dan bit 0 van @0 aan de linkerkant van SSSS plaatsen (ipv aan de rechterkant (LSb))
	lsr		@0					; C bit in de carry-flag, en SSSS bits op de juiste plek..
	brcc	_1
	ori		@0, 0b00010000		; carry was gezet, dus C bit weer aanzetten..
_1:	cpi		@2, 0				; richting achteruit?
	breq	_0
	ori		@0, 0b00100000		; vooruit
_0:	ori		@0, 0b01000000		; vaste waarde voor bits7 & 6
.ENDMACRO

.MACRO Byte_SpeedDirection;(Speed,Direction, ByteValue)
	push	ZH
	; richting
	ldi		@1, 0				; Direction := achteruit
	mov		ZH, @2
	andi	ZH, 0b00100000		; D bit (richting)
	breq	_1
	ldi		@1, 1				; Direction := vooruit
_1:	; snelheid
	mov		@0, @2
	andi	@0, 0b00001111		; SSSS bits
	lsl		@0					; SSSS bits staan nu op hun plek
	; C bit aan de rechterkant plaatsen (LSb maken)
	mov		ZH, @2
	andi	ZH, 0b00010000		; C bit
	breq	_2
	ori		@0, 0b00000001
_2: ; nu 3 aftrekken van de berekende snelheid
	subi	@0, 3
_0:
	pop		ZH
.ENDMACRO




; een 9-bit adres omzetten naar een 3+6 bits adresvorm
.MACRO b_9_36;(ValueH,ValueL:register)
	lsl		@0
	lsl		@0
	andi	@0, 0b00000111
	sbrc	@1, 7
	ori		@0, 0b00000010
	sbrc	@1, 6
	ori		@0, 0b00000001
	andi	@1, 0b00111111
.ENDMACRO

; een 3+6 bits adres omzetten naar een 9-bit adres
.MACRO b_36_9;(ValueH,ValueL:register)
	sbrc	@0, 0
	ori		@1, 0b01000000
	sbrc	@0, 1
	ori		@1, 0b10000000
	lsr		@0
	lsr		@0
.ENDMACRO

.MACRO b_9_Local;(ValueH,ValueL:register; DecoderPoort:PORT)
	.if @2 == PORTA
		mov		DecAddrHPortA, @0		; adres overnemen naar een laag register-paar
		mov		DecAddrLPortA, @1		; voor EZ-access en storage
	.endif
	.if @2 == PORTB
		mov		DecAddrHPortB, @0
		mov		DecAddrLPortB, @1
	.endif
	.if @2 == PORTC
		mov		DecAddrHPortC, @0
		mov		DecAddrLPortC, @1
	.endif
.ENDMACRO



.MACRO Get_EECV_ManufacturerVersionInfo;(Value:register)
	ldi		@0, $09						; "Manufacturer Version Info"
.ENDMACRO

.MACRO Get_EECV_ManufacturerID;(Value:register)
	ldi		@0, $0D						; "Public Domain & Do-It-Yourself Decoders"
.ENDMACRO


.MACRO Get_EECV_Address;(ValueH,ValueL:register; DecoderPoort:PORT)
	push	YH
	push	YL
	.if @2 == PORTA
		; CV513 (LSB-6b) uit EEPROM naar @1
		ldi		YH, high(A_CV_513)
		ldi		YL, low(A_CV_513)
		EEPROM_Read @1, YH,YL
		; CV521 (MSB-3b) uit EEPROM naar @0
		ldi		YH, high(A_CV_521)
		ldi		YL, low(A_CV_521)
		EEPROM_Read @0, YH,YL
	.endif
	.if @2 == PORTB
		; CV513 (LSB-6b) uit EEPROM naar @1
		ldi		YH, high(B_CV_513)
		ldi		YL, low(B_CV_513)
		EEPROM_Read @1, YH,YL
		; CV521 (MSB-3b) uit EEPROM naar @0
		ldi		YH, high(B_CV_521)
		ldi		YL, low(B_CV_521)
		EEPROM_Read @0, YH,YL
	.endif
	.if @2 == PORTC
		; CV513 (LSB-6b) uit EEPROM naar @1
		ldi		YH, high(C_CV_513)
		ldi		YL, low(C_CV_513)
		EEPROM_Read @1, YH,YL
		; CV521 (MSB-3b) uit EEPROM naar @0
		ldi		YH, high(C_CV_521)
		ldi		YL, low(C_CV_521)
		EEPROM_Read @0, YH,YL
	.endif
	; als 1 word vormen
	b_36_9 @0,@1
	pop		YL
	pop		YH
.ENDMACRO

.MACRO Set_EECV_Address;(ValueH,ValueL:register; DecoderPoort:PORT)
	push	YH
	push	YL
	; 9-bits adres omzetten naar 3+6 bits
	b_9_36 @0,@1
	; de 2 CVars schrijven in EEPROM
	.if @2 == PORTA
		; CV513 (LSB-6b) uit EEPROM naar R16
		ldi		YH, high(A_CV_513)
		ldi		YL, low(A_CV_513)
		EEPROM_Write YH,YL, @1
		; CV521 (MSB-3b) uit EEPROM naar R17
		ldi		YH, high(A_CV_521)
		ldi		YL, low(A_CV_521)
		EEPROM_Write YH,YL, @0
	.endif
	.if @2 == PORTB
		; CV513 (LSB-6b) uit EEPROM naar R16
		ldi		YH, high(B_CV_513)
		ldi		YL, low(B_CV_513)
		EEPROM_Write YH,YL, @1
		; CV521 (MSB-3b) uit EEPROM naar R17
		ldi		YH, high(B_CV_521)
		ldi		YL, low(B_CV_521)
		EEPROM_Write YH,YL, @0
	.endif
	.if @2 == PORTC
		; CV513 (LSB-6b) uit EEPROM naar R16
		ldi		YH, high(C_CV_513)
		ldi		YL, low(C_CV_513)
		EEPROM_Write YH,YL, @1
		; CV521 (MSB-3b) uit EEPROM naar R17
		ldi		YH, high(C_CV_521)
		ldi		YL, low(C_CV_521)
		EEPROM_Write YH,YL, @0
	.endif
	pop		YL
	pop		YH
.ENDMACRO



.MACRO Get_DCCAddress9;(ValueH,ValueL: register)
	; Het 9-bits DCC-adres bepalen van de wissel:
	;!! let erop dat de A-bits van DCCByte2 zijn geinverteerd
	mov		@1, DCCByte1
	andi	@1, 0b00111111
	sbrs	DCCByte2, 4					; bit 4 van 2e byte gezet? dan skippen..
	ori		@1, 0b01000000				; ..anders bit 6 zetten van @1
	sbrs	DCCByte2, 5					; bit 5 van 2e byte gezet? dan skippen..
	ori		@1, 0b10000000				; ..anders bit 7 zetten van @1
	clr		@0
	sbrs	DCCByte2, 6					; bit 4 van 2e byte gezet? dan skippen..
	ori		@0, 0b00000001				; ..anders bit 0 zetten van @0
	.if ShowDCCAddress == 1
		; informatie afbeelden op COM: poort
		;.if @0 != R31
		;	mov		ZH, @0
		;.endif
		;.if @1 != R30
		;	mov		ZL, @1
		;.endif
		rcall	Decimal
		rcall	UART_Space
	.endif
.ENDMACRO

.MACRO Get_WisselAddress2
	; De DDD-bits van de 2e byte (1AAACDDD) filteren naar "Mask0" en "Mask1" (AVR-poortpin maskers).
	; Deze bits bepalen om welke wissel het gaat (1 van de 4 op een enkel DCC-"Accessory"-adres)
	; of alle wissels (op DCC-adres) als CDDD = 0000.
	mov		temp2, DCCByte2				; 2e byte in de buffer

_2:	andi	temp2, 0b00000111			; DDD-bits overhouden
	; even omrekenen naar 2 poort maskers..
	; De te gebruiken AVR pin-nummer is nu gelijk aan de waarde van temp2
	; Het masker dat ik wil hebben: Mask0=2^temp2
	ldi		temp3, 1
	mov		Mask0, temp3
	cpi		temp2, 0
	breq	_0
_1:	lsl		Mask0
	dec		temp2
	brne	_1
_0:
	.if ShowAVRpin == 1
		; informatie afbeelden op COM: poort
		; AVR-poort pin nummer
		push	R16
		mov		R16, DCCByte2
		andi	R16, 0b00000111
		ori		R16, 0b00110000
		rcall	UART_transmit
		;rcall	UART_Space
		pop		R16
	.endif
.ENDMACRO


.MACRO Write_AVRport;(DCCAddrH,DCCAddrL: register)
	; "DCCAddr" = DCC_BaseAddress? dan betreft het een wissel op PORTA
	cp		@1, DecAddrLPortA
	cpc		@0, DecAddrHPortA
	brne	_1
	Switch_Wissel PORTA
	.if ShowAVRport == 1
		; informatie afbeelden op COM: poort
		ldi		R16, 'A'
		rcall	UART_transmit
	.endif
	rjmp	_0
_1:	; "DCCAddr" = DCC_BaseAddress+1? dan betreft het een wissel op PORTB
	cp		@1, DecAddrLPortB
	cpc		@0, DecAddrHPortB
	brne	_2
	Switch_Wissel PORTB
	.if ShowAVRport == 1
		; informatie afbeelden op COM: poort
		ldi		R16, 'B'
		rcall	UART_transmit
	.endif
	rjmp	_0
_2:	; "DCCAddr" = DCC_BaseAddress+2? dan betreft het een wissel op PORTC
	cp		@1, DecAddrLPortC
	cpc		@0, DecAddrHPortC
	brne	_0
	Switch_Wissel PORTC
	.if ShowAVRport == 1
		; informatie afbeelden op COM: poort
		ldi		R16, 'C'
		rcall	UART_transmit
	.endif
_0:
	.if ShowAVRport == 1
		rcall	UART_Space
	.endif
.ENDMACRO

.MACRO Switch_Wissel;(AVRpoort:PORT)
	in		temp, @0
	; activeren of deactiveren?
	sbrc	DCCByte2, 3						; C-bit gewist? dan de volgende instructie overslaan
	rjmp	_1								; C-bit is nu gezet..
	; DE-ACTIVEER, pin op 0
	.if InvertOutput == 0
		com		Mask0						;bit niet inverteren
		and		temp, Mask0					;
	.else
		or		temp, Mask0					;bit inverteren
	.endif
	rjmp	_2
_1:	; ACTIVEER, pin op 1
	.if InvertOutput == 0
		or		temp, Mask0					;bit niet inverteren
	.else
		com		Mask0						;bit inverteren
		and		temp, Mask0					;
	.endif
_2:	out		@0, temp
.ENDMACRO



.MACRO Get_CVarAddress10;(ValueH,ValueL: register)
	; het (CVar adres - 1) staat in DCCByte1 & DCCByte2: (1110CCAA AAAAAAAA)
	mov		@0, DCCByte1
	andi	@0, 0b00000011
	mov		@1, DCCByte2
	; 1 optellen bij het gevonden adres..
	adiw	@1, 1
	.if ShowCVAddress == 1
		; informatie afbeelden op COM: poort
		; Het CV adres
		push	ZH
		push	ZL
		ldi		R16, 'C'
		rcall	UART_transmit
		ldi		R16, 'V'
		rcall	UART_transmit
		mov		ZH, @0
		mov		ZL, @1
		rcall	Decimal
		rcall	UART_Space
		pop		ZL
		pop		ZH
	.endif
.ENDMACRO

.MACRO Handle_CV;(CVH,CVL, DataByte: register; OnError:Label)
; Direct CV addressing packet: long-preamble 0 0111CCAA 0 AAAAAAAA 0 DDDDDDDD 0 EEEEEEEE 1
;!!!!! Het aangereikte (packet-)CV-adres is 1 hoger dan het werkelijke CV#  !!!!!
;!!!!! De argumenten CVH:CVL zijn al gecorrigeerd (1 verlaagd) voor deze macro wordt aangeroepen !!!!!

	; CVar schrijven? (DCCByte1=1110CCAA, CC=11)
	mov		temp, DCCByte1
	andi	temp, 0b00001100
	cpi		temp, 0b00001100
	breq	_1							; CV WRITE
	cpi		temp, 0b00000100
	breq	_2							; CV VERIFY
	cpi		temp, 0b00001000
	breq	_3							; CV BIT MANIPULATION
	rjmp	@3							; ..een andere operatie zou niet moeten kunnen..;)
_1:	; CV WRITE
	; De CV #CV van DCC-device met adres DCCAddress9 instellen op waarde DataByte.
	; De decoder mag (of moet?) een ACK sturen nadat de CV-waarde is aangepast in de decoder.
	.if ShowCVAction == 1
		push	ZH
		push	ZL
		ldi		ZH, high(2*MsgCVWrite)
		ldi		ZL, low(2*MsgCVWrite)
		rcall	UART_transmit_String
		pop		ZL
		pop		ZH
		mov		R16, @2
		rcall	HexByte					; data byte voor CV-Write
	.endif
	rjmp	_0
_2:	; CV VERIFY
	; De CV #CV van DCC-device met adres DCCAddress verifieren met waarde DataByte.
	; Een ACK geven indien de beide waarden overeenkomen.
	.if ShowCVAction == 1
		push	ZH
		push	ZL
		ldi		ZH, high(2*MsgCVVerify)
		ldi		ZL, low(2*MsgCVVerify)
		rcall	UART_transmit_String
		rcall	UART_Space
		pop		ZL
		pop		ZH
		mov		R16, @2
		rcall	HexByte					; data byte voor CV-Verify
	.endif
	rjmp	_0
_3:	; CV BIT MANUPILATION
	; Het packet-formaat voor een CV-Bit-Manipulation:
	; long-preamble 0 011110AA 0 AAAAAAAA 0 111KDBBB 0 EEEEEEEE 1
	; K=1 signifies a "Bit Write" operation and K=0 signifies a "Bit Verify" operation.
	; D contains the value of the bit to be verified or written.
	; BBB represents the bit position within the CV (000 being defined as bit 0).
	; Ook hier weer een ACK geven indien operatie klaar.
	.if ShowCVAction == 1
		push	ZH
		push	ZL

		ldi		ZH, high(2*MsgCVBit)
		ldi		ZL, low(2*MsgCVBit)
		rcall	UART_transmit_String

		; K bit
		mov		temp, DCCByte3
		andi	temp, 0b00010000
		breq	_4
		ldi		ZH, high(2*MsgCVWrite)
		ldi		ZL, low(2*MsgCVWrite)
		rcall	UART_transmit_String
		rjmp	_5

_4:		ldi		ZH, high(2*MsgCVVerify)
		ldi		ZL, low(2*MsgCVVerify)
		rcall	UART_transmit_String
		rcall	UART_Space

_5:		; D bit
		mov		temp, DCCByte3
		andi	temp, 0b00001000
		breq	_6
		ldi		temp, '1'
		rjmp	_7
_6:		ldi		temp, '0'
_7:		rcall	UART_transmit
		ldi		temp, '<'
		rcall	UART_transmit
		rcall	UART_transmit

		; BBB bits
		mov		temp, DCCByte3
		andi	temp, 0b00000111
		mov		ZL, temp
		clr		ZH
		rcall	Decimal
		rcall	UART_Space

		pop		ZL
		pop		ZH
		mov		R16, @2
		rcall	HexByte					; data byte voor CV-Bit Manipulation
	.endif
_0:
.ENDMACRO



.MACRO EnterLearningMode				; start de "learning-mode"
	ldi		R16, (Learning | LearnA)
	mov		LearnModeFlags, R16
	LearnFlagsToLEDs					; alleen LED_A aan
.ENDMACRO

.MACRO EnterNormalMode					; start de normale bedrijfs-modus
	ldi		R16, NormalOperation
	mov		LearnModeFlags, R16
	LearnFlagsToLEDs					; alle LED's uit
.ENDMACRO

.MACRO LED_On;(LED:8b-constante)
	sbi		LEDsPort, @0
.ENDMACRO

.MACRO LED_Off;(LED:8b-constante)
	cbi		LEDsPort, @0
.ENDMACRO

.MACRO LearnFlagsToLEDs
	LED_Off LED_A
	sbrc	LearnModeFlags, LearnA_
	LED_On LED_A
	LED_Off LED_B
	sbrc	LearnModeFlags, LearnB_
	LED_On LED_B
	LED_Off LED_C
	sbrc	LearnModeFlags, LearnC_
	LED_On LED_C
.ENDMACRO

.MACRO SelectNextDecoder
	mov		R16, LearnModeFlags
	lsl		R16							; "Learning"-bit naar de carry-flag
	brcc	_0							; niet in learn-mode.. ?!! zou niet moeten kunnen.. ;)
	sbrc	R16, (LearnC_+1)			; 3 bits overflow?
	ori		R16, (LearnA)
	andi	R16, (LearnC | LearnB | LearnA)
	ori		R16, Learning
	mov		LearnModeFlags, R16
	LearnFlagsToLEDs
	; melding op COM: afbeelden..
	ldi		ZH, high(2*MsgWisselDecoder)
	ldi		ZL, low(2*MsgWisselDecoder)
	rcall	UART_transmit_String
	;
	sbrc	LearnModeFlags, LearnA_
	rjmp	_1							; poort A is geselecteerd
	sbrc	LearnModeFlags, LearnB_
	rjmp	_2							; poort B
	sbrc	LearnModeFlags, LearnC_
	rjmp	_3							; poort C
	rjmp	_0							; geen enkele poort geselecteerd.. ?!! zou niet moeten kunnen.. ;)
_1:	ldi		R16, 'A'
	rjmp	_4
_2:	ldi		R16, 'B'
	rjmp	_4
_3:	ldi		R16, 'C'
_4:	rcall	UART_transmit
	;
	ldi		ZH, high(2*MsgWisselLearning)
	ldi		ZL, low(2*MsgWisselLearning)
	rcall	UART_transmit_String
_0:	rcall	UART_CrLf
.ENDMACRO

.MACRO Check_LearningMode
	; indien in "learn-mode":
	; Nu het ontvangen DCC-AC adres overnemen naar de geselecteerde decoder
	; (Het packet is reeds gecontrolleerd op errors, dus geldig..)
	sbrs	LearnModeFlags, Learning_
	rjmp	_0
;InLearningMode:
	; Het DCC-AC adres staat nu in regsiter Z.
	; Het adres overnemen naar de locale registers voor de betreffende decoder,
	; en naar de CVar's in EEPROM.
	; Daarna de learning-mode stoppen..
	;Do_LearnA:
	sbrs LearnModeFlags, LearnA_
	rjmp	_1
	b_9_Local ZH,ZL, PORTA				; Z := 9b DCC AC-adres lokaal bewaren in lage registers
	Set_EECV_Address ZH,ZL, PORTA		; 9b DCC-AC adres bewaren in CVar's
	DecoderAddr_Display ZH,ZL, PORTA
	rjmp	_3
_1:	sbrs LearnModeFlags, LearnB_
	rjmp	_2
	b_9_Local ZH,ZL, PORTB
	Set_EECV_Address ZH,ZL, PORTB
	DecoderAddr_Display ZH,ZL, PORTB
	rjmp	_3
_2:	sbrs LearnModeFlags, LearnC_
	rjmp	_3
	b_9_Local ZH,ZL, PORTC
	Set_EECV_Address ZH,ZL, PORTC
	DecoderAddr_Display ZH,ZL, PORTC
_3:
	EnterNormalMode
	.if ExecuteLearnPacket == 0
		rjmp	StopPacketTest			; de "learn" opdracht niet meteen uitvoeren, na het leren..
	.endif
_0:
.ENDMACRO

.MACRO DecoderAddr_Display;(DCCAddrH,DCCAddrL:register; AVRpoort:PORT)
	push	XL
	push	XH
	mov		XL, @1
	mov		XH, @0
	; melding tekst afbeelden
	ldi		ZH, high(2*MsgWisselDecoder)
	ldi		ZL, low(2*MsgWisselDecoder)
	rcall	UART_transmit_String
	.if @2 == PORTA
		ldi		R16, 'A'
		rcall	UART_transmit
	.endif
	.if @2 == PORTB
		ldi		R16, 'B'
		rcall	UART_transmit
	.endif
	.if @2 == PORTC
		ldi		R16, 'C'
		rcall	UART_transmit
	.endif
	ldi		ZH, high(2*MsgWisselLearned)
	ldi		ZL, low(2*MsgWisselLearned)
	rcall	UART_transmit_String
	; DCC-AC adres afbeelden
	mov		ZH, XH
	mov		ZL, XL
	rcall	Decimal
	;
	pop		XH
	pop		XL
.ENDMACRO


.MACRO ACK_StartPuls
	.if GenerateACKsignal == 1
		; de AVR-pin voor het ACK-signaal op 1
		sbi		ACKPort, ACKPin
		; de telling voor het aantal timer0 OVF's te wachten resetten..
		ldi		R16, TOVFCount_ACK
		mov		ACK_OVFCounter, R16
		; aangeven dat we Timer0 OVF interrupts willen krijgen..
		in		temp, TIMSK
		ori		temp, (1<<TOIE0)
		out		TIMSK, temp
		; TCK0 op 0
		clr		R16
		out		TCNT0, R16
	.endif
.ENDMACRO

.MACRO ACK_StopPuls
	.if GenerateACKsignal == 1
		; de AVR-pin voor het ACK-signaal op 0
		cbi		ACKPort, ACKPin
		; nu niet verder reageren op T0-OVF interrupts..
		in		temp, TIMSK
		andi	temp, ~(1<<TOIE0)
		out		TIMSK, temp
	.endif
.ENDMACRO
;--------------------------------------/







;---------------------------------------
;--- Een DCC packet byte(2e) omzetten
;--- naar een Speed and Direction
;--- invoer:	DCCByte2
;--- uitvoer:	R16 = Speed
;---         	R17 = Direction
;--------------------------------------\
Byte_To_SpeedDirection:
	Byte_SpeedDirection R16,R17, DCCByte2
	ret
;--------------------------------------/

;---------------------------------------
;--- Een DCC packet byte(2e) berekenen
;--- voor Speed and Direction
;--- invoer:	R16 = Speed
;---         	R17 = Direction
;--- uitvoer:	DCCByte2
;--------------------------------------\
SpeedDirection_To_Byte:
	SpeedDirection_Byte DCCByte2, R16,R17
	ret
;--------------------------------------/






;---------------------------------------
;--- Een DCC packet verwerken
;--------------------------------------\
ProcessPacket:
	; X verwijst naar de byte net na einde PacketStream-buffer..
	; dus: Aantal bytes in buffer = (X - PacketStream)
	subi	XL, low(PacketStream)
	ldi		temp, high(PacketStream)
	sbc		XH, temp
	sts		PacketStreamCount, XL		; aantal bytes in buffer bewaren..
	
;	if ShowPacketBytes == 1
;		Packet_Display					; alle packets laten zien (incl. IDLE etc)
;	.endif
	;
	; makkelijk refereren naar bytes in de packet-buffer..
	lds		DCCByte1, PacketStream		; 1e byte in de buffer lezen		; 3 cycles
	lds		DCCByte2, PacketStream+1	; 2e byte in de buffer lezen
	lds		DCCByte3, PacketStream+2	; 3e byte in de buffer lezen
	lds		DCCByte4, PacketStream+3	; 4e byte in de buffer lezen
	lds		DCCByte5, PacketStream+4	; 5e byte in de buffer lezen
	lds		DCCByte6, PacketStream+5	; 6e byte in de buffer lezen
	;lds	DCCByte7, PacketStream+6	; 7e byte in de buffer lezen

	If_IDLEPacket_GoTo Done_ProcessPacket

	.if ShowPacketBytes == 1
		Packet_Display						; alle packets laten zien (excl. IDLE)
	.endif


	;----------------------------------\
	.if Packet4Bytes == 1
		If_NotPacketLength_GoTo NoPacket4, 4
		If_ErrorDetected_GoTo StopPacketTest, 4

;		.if ShowPacketBytes == 1		; 4-byte packets laten zien..
;			Packet_Display
;		.endif

		;-------------------------------
		;--- Een 4 byte packet: Service-Mode Direct CV-Access
		.if Do_ServiceMode == 1
			If_NoServiceModePacket_GoTo NoServiceModePacket

			; het 10-bits CVar adres filteren naar register X
			Get_CVarAddress10 XH, XL
			; de CV schrijven of verifieren
			Handle_CV XH,XL, DCCByte3, StopPacketTest
			
			; een ACKnowledge puls starten,
			; via timer0 wordt die puls beeindigd.
			rjmp	ACKnowledge_Packet
			;ACK_StartPuls
			;rjmp	StopPacketTest
			;
		NoServiceModePacket:
		.endif
		;-------------------------------

	NoPacket4:
	.endif
	;----------------------------------/


	If_NoAccessoryPacket_GoTo StopPacketTest

	If_ExtendedPacket_GoTo StopPacketTest

	If_BroadcastPacket_GoTo StopPacketTest

;	.if ShowPacketBytes == 1	; alleen Accessory packets laten zien..
;		Packet_Display			; ..de adressen kunnen nog ongeldig zijn voor deze decoder(s)
;	.endif


	;----------------------------------\
	.if Packet6Bytes == 1
		If_NotPacketLength_GoTo NoPacket6, 6
		; we hebben een Accessory Decoder adres te pakken..(in een 6 byte packet)
		If_ErrorDetected_GoTo StopPacketTest, 6
		; Het packet is correct..

		;-------------------------------
		;--- Een 6 byte packet: Operations-Mode Direct CV-Access
		.if Do_OperationsMode == 1
			If_NoCVProgrammingPacket_GoTo NoOperationsModePacket
			;
		NoOperationsModePacket:
		.endif
		;-------------------------------

		;---
	NoPacket6:
	.endif
	;----------------------------------/


	If_NotPacketLength_GoTo StopPacketTest, 3
	; we hebben een Accessory Decoder adres te pakken..(in een 3 byte packet)
	If_ErrorDetected_GoTo StopPacketTest, 3

	; Nu het 9-bits DCC-adres bepalen van de (4) wissel(s) en plaatsen in register Z
	Get_DCCAddress9 ZH,ZL


	;----------------------------------\
	Check_LearningMode
	;----------------------------------/


	; test of er 1 van de 3 decoders is geadresseerd..
	.if ValidAddrOnly == 1
		If_AddressNotOnboard_GoTo StopPacketTest, ZH,ZL
	.endif
	; Het 2-bit subadres van de wissel uit DCCByte2 halen (1AAACDDD)
	Get_WisselAddress2
	; de AVR poort beschrijven en daarmee de wissel (op DCC GA-adres Z) aansturen
	Write_AVRport ZH,ZL

ACKnowledge_Packet:
	; een acknowledge geven na verwerken van een Basic Accessory Packet
	ACK_StartPuls

StopPacketTest:
	rcall	UART_CrLf

Done_ProcessPacket:
	ResetStream
	ret
;--------------------------------------/


;---------------------------------------
;--- De Capture pin instellen
;--------------------------------------\
Capture_Initialize:
	cbi		CaptureDDR, CapturePin		; "input capture" pin als input
	cbi		CapturePORT, CapturePin		; tri-state
	ret
;--------------------------------------/


;---------------------------------------
;--- De ACKknowledge pin instellen
;--------------------------------------\
ACK_Initialize:
	sbi		ACKDDR, ACKPin				; "DCC ACK" pin als output
	cbi		ACKPORT, ACKPin				; zero output
	ret
;--------------------------------------/


;---------------------------------------
;--- De AVR poorten initialiseren
;--------------------------------------\
WisselPoort_Initialize:
	cbi		ADCSR, ADEN					; ADC disable
	; alle wissel-poorten op output
	ser		temp
	out		DDRA, temp
	out		DDRB, temp
	out		DDRC, temp
.if InvertOutput == 0
	clr		temp						; niet inverteren
.else
	ser		temp						; geinverteerd
.endif
	out		PORTA, temp
	out		PORTB, temp
	out		PORTC, temp
	ret
;--------------------------------------/


;---------------------------------------
;--- De wissel software initialiseren
;--------------------------------------\
Wissel_Initialize:
	; wat tekst afbeelden..
	ldi		ZH, high(2*MsgWisselAdr)
	ldi		ZL, low(2*MsgWisselAdr)
	rcall	UART_transmit_String
	; AVR poort A decoder-adres ophalen uit EEPROM (en in Y plaatsen)
	Get_EECV_Address XH,XL, PORTA		; X := 9b DCC AC-adres
	b_9_Local XH,XL, PORTA				; X := 9b DCC AC-adres
	; afbeelden op COM:
	mov		ZH, DecAddrHPortA
	mov		ZL, DecAddrLPortA
	rcall	Decimal
	rcall	UART_Space
	; AVR poort B decoder-adres
	Get_EECV_Address XH,XL, PORTB
	b_9_Local XH,XL, PORTB
	; afbeelden op COM:
	mov		ZH, DecAddrHPortB
	mov		ZL, DecAddrLPortB
	rcall	Decimal
	rcall	UART_Space
	; AVR poort C decoder-adres
	Get_EECV_Address XH,XL, PORTC
	b_9_Local XH,XL, PORTC
	; afbeelden op COM:
	mov		ZH, DecAddrHPortC
	mov		ZL, DecAddrLPortC
	rcall	Decimal
	rcall	UART_CrLf
	; niet in learn-mode opstarten..
	EnterNormalMode
	ret

;---------------------------------------
;--- De AVR pinnen instellen voor schakelaars
;--------------------------------------\
Switch_Initialize:
	cbi		SwitchesDDR, SwitchPin		; schakelaar pin op input
	cbi		SwitchesPort, SwitchPin		; tri-state
	; INT0 instellen voor interrupts op een neergaande flank
	in		R16, MCUCR					; ISC01 & ISC00 op: 1 & 0 (falling edge)
	ori		R16, (1<<ISC01 | 0<<ISC00)
	out		MCUCR, R16
	; de interrupt inschakelen voor INT0 (op PD2)
	in		R16, GIMSK
	ori		R16, (1<<INT0)
	out		GIMSK, R16
	ret
;--------------------------------------/


;---------------------------------------
;--- De LED pinnen instellen
;--- (voor aanduiding learn-mode decoder)
;--------------------------------------\
LED_Initialize:
	; pin-richting op output
	sbi		LEDsDDR, LED_A
	sbi		LEDsDDR, LED_B
	sbi		LEDsDDR, LED_C
	; LED's uit
	LED_Off LED_A
	LED_Off LED_B
	LED_Off LED_C
	ret
;--------------------------------------/


;---------------------------------------
;--- De Timer1 initialiseren
;--------------------------------------\
Timer1_Initialize:
	; interrupts tegengaan
	clr		temp
	out		TIMSK, temp

	; De Timer1 HW-PWM uitschakelen
	;clr	temp
	out		TCCR1A, temp

	;-- waarden voor TCCR1B
	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture. (nvt nu)
	; ICES1: Input Capture Interrupts op opgaande flank laten genereren. (nvt nu)
	; CTC1:  Clear TCNT on compareA match uitschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK/8 (0,1,0)
	ldi		temp, (0<<ICNC1 | 0<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
	out		TCCR1B, temp

	; timer1 alle interrupts uitschakelen
	clr		temp
	out		TIMSK, temp

	; de counter op 0 instellen
	ResetCounter
	ret
;--------------------------------------/


.if GenerateFTimeouts == 1
	;---------------------------------------
	;--- De Timer2 initialiseren
	;--- tbv. de timeout's voor F1,F2,F3 & F4
	;--------------------------------------\
	Timer2_Initialize:
		; Elke 10ms een timeout-waarde aftellen.

		; PWM uitschakelen						(0<<PWM2)
		; output compare uitschakelen			(0<<COM21 | 0<<COM20)
		; clear timercounter on compare-match	(1<<CTC2)
		; prescale op CK/1024					(1<<CS22 | 1<<CS21 | 1<<CS20)
		; schrijven naar Timer2 Control Register
		ldi		temp, (0<<PWM2 | 0<<COM21 | 0<<COM20 | 1<<CTC2 | 1<<CS22 | 1<<CS21 | 1<<CS20)
		out		TCCR2, temp

		; de Compare-Match Interrupt inschakelen
		in		temp, TIMSK
		ori		temp, (1<<OCIE2)
		out		TIMSK, temp

		ret
	;--------------------------------------/


	;---------------------------------------
	;--- De 10ms handler
	;--------------------------------------\
	HANDLER_10MS:
		push	R16
		in		R16, SREG
		push	R16

		; doet niks nu..
		; ..zou de timeouts voor F1-F4
		; moeten verlagen.

	Done_HANDLER_10MS:
		pop		R16
		out		SREG, R16
		pop		R16
		reti
	;--------------------------------------/
.endif






.if GenerateACKsignal == 1
	;---------------------------------------
	;--- De Timer0 initialiseren
	;--- tbv. de countdown voor ACK
	;--------------------------------------\
	Timer0_Initialize:
		; prescale op CK/64					(0<<CS02 | 1<<CS01 | 1<<CS00)
		; schrijven naar Timer0 Control Register
		ldi		R16, (0<<CS02 | 1<<CS01 | 1<<CS00)
		out		TCCR0, R16

		; de Overflow Interrupt uitschakelen.
		; Deze interrupt wordt alleen gebruikt als een ACK-puls aan de gang is..
		in		temp, TIMSK
		ori		temp, (0<<TOIE0)
		out		TIMSK, temp

		ret
	;--------------------------------------/

	;---------------------------------------
	;--- De ACK handler
	;--------------------------------------\
	HANDLER_ACK:
		push	R16
		in		R16, SREG
		push	R16

		; test de ACK overflow0 countdown
		mov		R16, ACK_OVFCounter
		cpi		R16, 0
		breq	StopACKPuls
		; nu geldt: ACK_OVFCounter > 0
		dec		R16							; countdown verlagen..
		mov		ACK_OVFCounter, R16			; ..EN terugschrijven in het lage register
		cpi		R16, 0
		breq	StopACKPuls
		; nu geldt: ACK_OVFCounter nog steeds > 0
		; dwz. nog langer wachten op de volgende Timer0 OVF interrupt.
		rjmp	Done_HANDLER_ACK
	StopACKPuls:
		ACK_StopPuls						; ACK signaal laag maken

	Done_HANDLER_ACK:
		pop		R16
		out		SREG, R16
		pop		R16
		reti
	;--------------------------------------/
.endif




;---------------------------------------
;--- De external interrupt INT0 handler
;--------------------------------------\
HANDLER_SWITCH:
	push	R16
	in		R16, SREG
	push	R16

	; test of al in learn-mode
	sbrc	LearnModeFlags, Learning_
	rjmp	Select_Decoder
	; learning-mode is nog niet actief
	EnterLearningMode					; ga in "learning-mode"
	rjmp	Done_HANDLER_SWITCH

Select_Decoder:
	; learning-mode is al actief, selecteer de volgende decoder
	SelectNextDecoder

Done_HANDLER_SWITCH:
	pop		R16
	out		SREG, R16
	pop		R16
	reti
;--------------------------------------/





;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	;-- HW initialisatie ---------------
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer
	rcall	UART_Initialize				; de COM: poort
	rcall	WisselPoort_Initialize		; poorten A,B & C wissel outputs
	rcall	Switch_Initialize			; de schakelaar pin op input
	rcall	LED_Initialize				; de LED's voor aanduiding learn-mode decoder
	rcall	Capture_Initialize			; de input pin voor het DCC signaal
	rcall	Timer1_Initialize			; de 16b Timer1
	.if GenerateFTimeouts == 1
		rcall	Timer2_Initialize		; de 8b Timer2 (tbv. de 10ms handler)
	.endif
	.if GenerateACKsignal == 1
		rcall	ACK_Initialize			; de pin voor het DCC-ACK signaal
		rcall	Timer0_Initialize		; de 8b Timer0 (tbv. opwekken 6ms ACK-puls)
	.endif
	;-- SW initialisatie ---------------
	rcall	UART_transmit_InitString
	rcall	Wissel_Initialize			; de wissel software initialiseren
	ResetStream							; de packetstream buffer
	clr		PreambleCount				; de Preamble detectie teller
	ldi		Step, _Preamble				; de huidige stap
	sei									; interrupts weer toelaten

stream_loop:

	WaitFor0							; wachten totdat het (DCC) ICP-signaal laag wordt (PD6)
	; begin Periode B
	ReadCounter ZH, ZL					; de timercounter uitlezen in register Z
										; (alleen nog erin vanwege TCNT reset tijdverschillen; HW-ICP zou oplossen..)
	ResetCounter						; de counter op 0 instellen
	
	WaitFor1							; wachten totdat het (DCC) ICP-signaal hoog wordt (PD6)
	; begin periode A
	ReadCounter ZH, ZL					; de timercounter uitlezen in register Z
	ResetCounter						; de counter op 0 instellen

	CheckPuls ZH, ZL					; controleer ontvangen halve bit (periode B)

	rjmp 	stream_loop
;--------------------------------------/






