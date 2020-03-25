
;-------------------------------------------------------------------
;--- Een DCC-Decoder voor de trein-modelbouw
;---
;---	Pin D6 (ICP) op de AT90S8535
;---	CK = 7372800 Hz
;---	TCK = CK, dus evenveel timerticks als clockticks per seconde
;---	ICP gebruiken we om de tijdsduur tussen 2 signaalveranderingen op een pin te meten
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us
;---	              "1" duur 383.3856 - 471.8592 ticks, "0" 663.552 - 73728 ticks (TCK=CK, CK=7.372800MHz)
;---	              "1" duur 52-64 ticks, "0" 90 - 10000 ticks (TCK=CK/8, CK=8MHz)
;---	De tijd tussen 2 packets moet zijn tenminste 5 ms. (40000 timerticks)
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
;--------------------------------------/

;--- CONSTANTEN -----------------------\
.equ CK = 8000000						; AVR clock frequentie (VERPLICHT hier te definieren)
;--------------------------------------/

;--- Compiler Directives --------------\  Geef aan welke units men wil gebruiken:
.equ Link_AVR_Core			= 1			; "AVR_Core.asm"	ALTIJD 1	READ-ONLY
.equ Link_AVR_16			= 0			; "AVR_16.asm"
.equ Link_AVR_Delay			= 0			; "AVR_Delay.asm"
.equ Link_AVR_Buffer		= 1			; "AVR_Buffer.asm"
.equ Link_AVR_LED			= 0			; "AVR_LED.asm"
.equ Link_8535_EEPROM		= 1			; "8535_EEPROM.asm"
.equ Link_8535_AC			= 0			; "8535_AC.asm"
.equ Link_8535_ADC			= 0			; "8535_ADC.asm"
.equ Link_8535_Timer0		= 0			; "8535_Timer0.asm"
.equ Link_8535_Timer1		= 0			; "8535_Timer1.asm"
.equ Link_8535_Timer2		= 0			; "8535_Timer2.asm"
.equ Link_8535_Timers		= 1			; "8535_Timers.asm"
.equ Link_8535_UART			= 0			; "8535_UART.asm"
.equ Link_LCD_HD44780		= 0			; "LCD_HD44780.asm"
.equ Link_AVR_String		= 0			; "AVR_String.asm"
;---------------------------------------
;included "LinkedUnits.asm" regelt de rest..:-)
;--------------------------------------/




;--- CONSTANTEN -----------------------\
;.equ CK = 8000000						; AVR clock frequentie
.equ TCK = CK/8							; timer1 frequentie						; CK/8
.equ Tick = 1/TCK						; de duur van 1 (timer)tick in seconden	; 1/TCK
.equ Puls1 = 60							; 60 timerticks = 60us
.equ Puls0 = 100						; 100 timerticks = 100us
.equ PulsEnd = $FFFF

; de zender moet om de 30ms een packet verzenden.
; we gebruiken Timer0 om een frequentie van
; (ongeveer) 30ms te genereren.
; CK=8MHz, T0CK=CK/1024, T0_OVF om de 256 timerticks =>
; frequentie-interval komt uit op 0.032768 seconden, dat is 32.768 ms
.equ T0CK = CK/1024
.equ SecCountPerSecond = 30				; (1/0.032768)

; Als er een trein op het aparte stukje spoor is gedetecteerd,
; wordt de trein gestopt. Na een bepaalde tijd moet de trein weer aanrijden.
; Deze tussenliggende tijd wordt OOK gemeten mbv. timer0.
; Om de 30 OVF0 interrupts wordt de seconde-teller verhoogd.
.equ STOP_SECONDS		= 10			; de trein staat zoveel sec. stil alvorens aan te rijden..

; een Preamble van 15 bits
.equ LENGTH_PREAMBLE	= 15			; x"1"-bits vormen een packet preamble
.equ BIT_PACKET_START	= 0
.equ BIT_PACKET_END		= 1
.equ BIT_DATA_START		= 0
.equ BIT_DATA_END		= 1
.equ BYTE_BROADCAST		= 0b00000000
;.equ PACKET_IDLE		= 0xFF00FF
;.equ PACKET_RESET		= 0x000000
.equ MAX_PACKET_SIZE	= 7				; maximaal packet van MAX_PACKET_SIZE bytes groot
;LED's
.equ LED_SendingPacket	= PC1
.equ LED_BezetMelder	= PC0
;--------------------------------------/



;--- Wachttijden in EEPROM ------------\
.ESEG									; Data Segment (SRAM) addresseren
	SomeTime:	.db 20					; maximaal SecCountPerSecond
.CSEG									; Code Segment (FLASH/PM) addresseren
;--------------------------------------/





;--- "AVR_Buffer.asm" buffer in SRAM --\
.equ TheBufferSize = LENGTH_PREAMBLE + (MAX_PACKET_SIZE*9); De grootte van de buffer (in bytes) CONSTANTE
.DSEG									; Data Segment (SRAM) addresseren
	BufferSize:		.BYTE 1				; de grootte van de buffer
	BufferCount: 	.BYTE 1				; Het aantal bytes in de buffer
	BufferPtrR:		.BYTE 2				; De pointer bij lezen uit de buffer (H:L)
	BufferPtrW:		.BYTE 2				; De pointer bij schrijven in de buffer (H:L)
	Buffer: 		.BYTE TheBufferSize	; de buffer vanaf adres "Buffer", met een grootte van "BufferSize" bytes
.CSEG									; Code Segment (FLASH/PM) addresseren
;--------------------------------------/





;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17
.def hooglaag		= R18				; indicator hoog/laag signaal te maken
.def DCC_TX			= R19				; indicator DCC packet aan het verzenden
.def Seconds		= R20				; seconde teller
.def SecondsCount	= R21				; de seconde hulp teller voor aantal OVF0 interrupts
.def LocalSomeTime	= R22				; een wachttijd (uit EEPROM gelezen, lokaal gemaakt)
;.def XL = R26
;.def XH = R27
;.def YL = R28
;.def YH = R29
;.def ZL = R30
;.def ZH = R31
;--------------------------------------/


;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	rjmp Timer1_Interrupt_CompareA		; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	rjmp Timer0_Overflow				; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/

;--- Ron's Macro's & Subroutines ------\
.include "LinkedUnits.asm"				; interne compiler-directives verwerking en unit-linking
;--------------------------------------/





RESET:
	cli
	StackPointer_Initialize
	; alle interrupts uitschakelen
	Disable_Interrupts
app_init:
	;--------------------------------------\
	ldi		R17, high(SomeTime)				; een wachttijd uit EEPROM lezen
	ldi		R16, low(SomeTime)
	EEPROM_Read LocalSomeTime, R17,R16

	Buffer_Initialize Buffer, TheBufferSize	; een ringbuffer FIFO

	; de applicatie initialiseren
	rcall	App_Initialize
	
	; de timer en interrupts
	rcall	Timer0_Initialize				; 32ms timing
	rcall	Timer1_Initialize				; bit-signaal uit

	; interrupts inschakelen
	ldi		R16, (1<<OCIE1A | 1<<TOIE0)		; Timer1-OutputCompareA & Timer0-Overflow
	Enable_Interrupts R16
	sei
	;--------------------------------------/

	;-- SPEED x forward
	rcall	WaitUntilPacketSent				; verzenden klaar?
	; een speed5-packet verzenden..
;	ldi		ZL, low(2*Broadcast_Speed14_Forward)
;	ldi		ZH, high(2*Broadcast_Speed14_Forward)
	ldi		ZL, low(2*Broadcast_Speed10_Forward)
	ldi		ZH, high(2*Broadcast_Speed10_Forward)
;	ldi		ZL, low(2*Broadcast_Speed8_Forward)
;	ldi		ZH, high(2*Broadcast_Speed8_Forward)
	rcall	WaitUntilPacketStart

main_loop:
	; test of er een trein op het aparte spoor rijdt
	rcall	TrainDetected
	breq	main_loop						; geen trein gedetecteerd..

	sbi		PORTC, LED_BezetMelder			; LED aan "BEZET-MELDER"

	; Er bevindt zich een trein op het aparte stukje spoor.
	; Wacht nu tot het huidige packet is verzonden..
	rcall	WaitUntilPacketSent

;	ldi		ZL, low(2*Broadcast_Speed13_Forward)
;	ldi		ZH, high(2*Broadcast_Speed13_Forward)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed12_Forward)
;	ldi		ZH, high(2*Broadcast_Speed12_Forward)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed11_Forward)
;	ldi		ZH, high(2*Broadcast_Speed11_Forward)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed10_Forward)
	ldi		ZH, high(2*Broadcast_Speed10_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed9_Forward)
	ldi		ZH, high(2*Broadcast_Speed9_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed8_Forward)
	ldi		ZH, high(2*Broadcast_Speed8_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed7_Forward)
	ldi		ZH, high(2*Broadcast_Speed7_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed6_Forward)
	ldi		ZH, high(2*Broadcast_Speed6_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed5_Forward)
	ldi		ZH, high(2*Broadcast_Speed5_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed4_Forward)
	ldi		ZH, high(2*Broadcast_Speed4_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed3_Forward)
	ldi		ZH, high(2*Broadcast_Speed3_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed2_Forward)
	ldi		ZH, high(2*Broadcast_Speed2_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed1_Forward)
	ldi		ZH, high(2*Broadcast_Speed1_Forward)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime



	; Het opgegeven aantal seconden wachten..
	; ..maar om de seconde nog een Stop-packet sturen.
	ldi		Seconds, 0
	mov		R16, Seconds
WaitForSeconds:
	; wacht 1 seconde lang..
	cp		R16, Seconds
	breq	WaitForSeconds

	; verzenden klaar?
	rcall	WaitUntilPacketSent
	; een stop-packet verzenden..
	ldi		ZL, low(2*Broadcast_Stop_I)
	ldi		ZH, high(2*Broadcast_Stop_I)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	ldi		ZL, low(2*Broadcast_Stop_I)
	ldi		ZH, high(2*Broadcast_Stop_I)

	; wacht STOP_SECONDS seconden lang..
	mov		R16, Seconds
	cpi		Seconds, STOP_SECONDS
	brne	WaitForSeconds



	; De trein mag weer aanrijden, de andere kant op..
	;-- SPEED 1
	; verzenden klaar?
	rcall	WaitUntilPacketSent



	ldi		ZL, low(2*Broadcast_Speed1)
	ldi		ZH, high(2*Broadcast_Speed1)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed2)
	ldi		ZH, high(2*Broadcast_Speed2)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed3)
	ldi		ZH, high(2*Broadcast_Speed3)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed4)
	ldi		ZH, high(2*Broadcast_Speed4)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed5)
	ldi		ZH, high(2*Broadcast_Speed5)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed6)
	ldi		ZH, high(2*Broadcast_Speed6)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed7)
	ldi		ZH, high(2*Broadcast_Speed7)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed8)
	ldi		ZH, high(2*Broadcast_Speed8)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed9)
	ldi		ZH, high(2*Broadcast_Speed9)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

	ldi		ZL, low(2*Broadcast_Speed10)
	ldi		ZH, high(2*Broadcast_Speed10)
	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed11)
;	ldi		ZH, high(2*Broadcast_Speed11)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed12)
;	ldi		ZH, high(2*Broadcast_Speed12)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed13)
;	ldi		ZH, high(2*Broadcast_Speed13)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime

;	ldi		ZL, low(2*Broadcast_Speed14)
;	ldi		ZH, high(2*Broadcast_Speed14)
;	rcall	WaitUntilPacketTransmitted		; verzenden klaar?
;	rcall	WaitSomeTime


	; Wacht tot de trein van het aparte stukje spoor is..
DoDepart:
	rcall	TrainDetected
	brne	DoDepart						; trein nog gedetecteerd..

	cbi		PORTC, LED_BezetMelder			; LED uit "BEZET-MELDER"

	rcall	WaitUntilPacketSent				; verzenden klaar?
	rcall	WaitASecond
	rcall	WaitASecond
	rcall	WaitASecond
	rcall	WaitASecond

	; een speed5-packet verzenden..
;	ldi		ZL, low(2*Broadcast_Speed14_Forward)
;	ldi		ZH, high(2*Broadcast_Speed14_Forward)
	ldi		ZL, low(2*Broadcast_Speed10_Forward)
	ldi		ZH, high(2*Broadcast_Speed10_Forward)
;	ldi		ZL, low(2*Broadcast_Speed8_Forward)
;	ldi		ZH, high(2*Broadcast_Speed8_Forward)
	rcall	WaitUntilPacketStart

	rjmp	main_loop













;---------------------------------------
;--- De Timer0 overflow handler
;--- 32 milliseconden verstreken; Zend een packet
;---
;--- Verhoog ook de SecondsCount (en evt. Seconds)
;--- voor de seconde-timing.
;--------------------------------------\
Timer0_Overflow:
	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp

	; zijn we nog bezig met het verzenden van een packet?
	cpi		DCC_TX, 1
	breq	CountSeconds

	sbi		PORTC, LED_SendingPacket	; LED aan "bezig packet te verzenden"
	ldi		DCC_TX, 1					; "bezig packet te verzenden" markering aan
	Enable_Interrupt_CompareMatch1A		; begin het packet te verzenden (on interrupt OC1A)

CountSeconds:
	; seconde meting
	inc		SecondsCount
	cpi		SecondsCount, SecCountPerSecond
	brne	Done_Timer0_Overflow
	; een seconde is verstreken..
	inc		Seconds
	ldi		SecondsCount, 0

Done_Timer0_Overflow:
	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/



;---------------------------------------
;--- De Timer1 CompareA handler
;--- Het gegenereerde DCC-signaal.
;--------------------------------------\
Timer1_Interrupt_CompareA:
 	push	temp2
	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp
	
	rcall	Handle_Bit

	pop		temp
	out		SREG, temp
	pop		temp
	pop		temp2
	reti
;--------------------------------------/



;---------------------------------------
;--- De Timer0 initialiseren
;--------------------------------------\
Timer0_Initialize:
	Timer0Clock_PrescaleCK1024
	Clear_TimerCounter0
	ret
;--------------------------------------/



;---------------------------------------
;--- De Timer1 initialiseren
;--------------------------------------\
Timer1_Initialize:
	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp
	; De Timer1: noise canceler uit
	; clear counter on compareA match
	; TCK op CK/8
	ldi		temp, (0<<ICNC1 | 1<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
	out		TCCR1B, temp
	; compareA waarde instellen voor de eerste match
	; (schrijven high/low:)
	ldi		temp, 0
	ldi		temp2, Puls1
	Set_Compare1A temp, temp2
	; de counter op 0 instellen
	Clear_TimerCounter1
	ret
;--------------------------------------/




;---------------------------------------
;--- App_Initialize
;--------------------------------------\
App_Initialize:
	; poort D pin 6 als output instellen
	; voor de DCC-output
	sbi		DDRD, PD6
	cbi		PORTD, PD6					; DCC-signaal initieel op 0
	; pin D7 wordt gebruikt voor de "BEZET-MELDER"
	; PD7 als input instellen
	cbi		DDRD, PD7					; input
	cbi		PORTD, PD7					; open-collector / geen interne pull-up's aan
	; een LED voor aanduiding "BEZET-MELDER"
	sbi		DDRC, LED_BezetMelder
	cbi		PORTC, LED_BezetMelder		; LED uit
	; een LED voor aanduiding "bezig packet te verzenden"
	sbi		DDRC, LED_SendingPacket
	cbi		PORTC, LED_SendingPacket	; LED uit
	; "bezig packet te verzenden" markering uit
	ldi		DCC_TX, 0
	; als eerste een "1"-bit gaan beginnen
	ldi		hooglaag, 1
	; de seconde teller op 0
	ldi		Seconds, 0
	ldi		SecondsCount, 0
	; de pointer naar de bitstream in CSEG
	ldi		ZL, low(2*Idle_Packet)
	ldi		ZH, high(2*Idle_Packet)
	ret
;--------------------------------------/



;---------------------------------------
;--- Handle_Bit
;--------------------------------------\
Handle_Bit:
	cpi		hooglaag, 1
	breq	NuLaag

	; output op 1
	sbi		PORTD, PD6
	ldi		hooglaag, 1
	; de compareA waarde staat al goed ingesteld
	rjmp	Done_Handle_Bit

NuLaag:
	; output op 0
	cbi		PORTD, PD6
	ldi		hooglaag, 0
	; de volgende compareA waarde instellen
	; Z register verhogen en pulsduur-waarde lezen
	adiw	ZL, 1
	lpm
	mov		temp2, R0
	; de laatste bit van de stream gehad?
	cpi		temp2, $FF
	breq	StreamEnd

	; 0 of 1 nu in temp2.
	; 0 = temp2:=Puls0,   1 = temp2:=Puls1
	cpi		temp2, 0
	brne	Is1
	ldi		temp2, Puls0
	rjmp	pd
Is1:ldi		temp2, Puls1
pd:

	; compareA waarde instellen
	ldi		temp, 0
	out		OCR1AH, temp
	out		OCR1AL, temp2
	rjmp	Done_Handle_Bit

StreamEnd:
	; de timer1 compareAMatch interrupt stoppen. timer0 zet m weer aan na 32ms..
	Disable_Interrupt_CompareMatch1A
	ldi		DCC_TX, 0					; "bezig packet te verzenden" markering uit
	cbi		PORTC, LED_SendingPacket	; LED uit "bezig packet te verzenden"

	; pointer naar begin BitStream verplaatsen
	ldi		ZL, low(2*Idle_Packet)
	ldi		ZH, high(2*Idle_Packet)
	; markering laag signaal maken
	ldi		hooglaag, 0

Done_Handle_Bit:
	ret
;--------------------------------------/



;---------------------------------------
;--- TrainDetected
;--- uitvoer: zero-flag = 1, als een trein is gedetecteerd op het aparte spoor
;---          zero-flag = 0, geen trein gedetecteerd..
;--------------------------------------\
TrainDetected:
	in		R16, PIND
	andi	R16, (1<<PD7)
	;sbic	PIND, PD7
	;sez
	;sbis	PIND, PD7
	;clz
	ret
;--------------------------------------/


;---------------------------------------
;--- WaitUntilPacketStart
;--------------------------------------\
WaitUntilPacketStart:
	cpi		DCC_TX, 1
	brne	WaitUntilPacketStart
	ret
;--------------------------------------/

;---------------------------------------
;--- WaitUntilPacketSent
;--------------------------------------\
WaitUntilPacketSent:
	cpi		DCC_TX, 0
	brne	WaitUntilPacketSent
	ret
;--------------------------------------/

;---------------------------------------
;--- WaitUntilPacketDone
;--------------------------------------\
WaitUntilPacketTransmitted:
	rcall	WaitUntilPacketStart
	rcall	WaitUntilPacketSent
	ret
;--------------------------------------/


;---------------------------------------
;--- WaitASecond
;--------------------------------------\
WaitASecond:
	; 1 seconde wachten..
	ldi		Seconds, 0
w1s:
	cpi		Seconds, 0
	breq	w1s
	ret
;--------------------------------------/


;---------------------------------------
;--- WaitSomeTime
;--------------------------------------\
WaitSomeTime:
	; kwart seconde wachten..
	ldi		SecondsCount, 0
wqs:
	;cp		SecondsCount, LocalSomeTime
	cpi		SecondsCount, 20
	brne	wqs
	ret
;--------------------------------------/




;--------------------------------------\
BitStream:								; in SRAM
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,1,0,0,1, 0, 0,1,1,1,1,1,0,1, 1,    1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,0,0,0,1, 0, 0,1,1,1,0,1,0,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     PulsEnd, $FF

; SET GA N 13 1 1 2000
; $84 F9 7D (aan)
; 	11111111111111 0 10000100 0 11111001 0 01111101 1
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,1,0,0,1, 0, 0,1,1,1,1,1,0,1, 1, PulsEnd, $FF

; $84 F1 75 (uit)
; 	11111111111111 0 10000100 0 11110001 0 01110101 1
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,0,0,0,1, 0, 0,1,1,1,0,1,0,1, 1, PulsEnd, $FF
;

; Broadcast packet: speed op step 5
;	$00, 0b01DCSSSS, EEEEEEEE		D=1 forward, D=0 backward
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,0,0, 0, 0,1,1,0,0,1,0,0, 1, PulsEnd, $FF


 
; Een IDLE packet
Idle_Packet:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1, PulsEnd, $FF



; Broadcast packet: Stop			(richting: vooruit)
Broadcast_Stop:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,0,0,0, 0, 0,1,1,0,0,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: Stop (I)		(richting: vooruit)
Broadcast_Stop_I:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,0,0,0, 0, 0,1,1,1,0,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: E-Stop*			(richting: vooruit)
Broadcast_EStop:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,0,0,1, 0, 0,1,1,0,0,0,0,1, 1, PulsEnd, $FF
; Broadcast packet: E-Stop* (I)		(richting: vooruit)
Broadcast_EStop_I:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,0,0,1, 0, 0,1,1,1,0,0,0,1, 1, PulsEnd, $FF

; Broadcast packet: Speed Step 1	(richting: achteruit)   _ _________
Broadcast_Speed1:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,0,1,0, 0, 0,1,0,0,0,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 2	(richting: achteruit)
Broadcast_Speed2:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,0,1,0, 0, 0,1,0,1,0,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 3	(richting: achteruit)
Broadcast_Speed3:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,0,1,1, 0, 0,1,0,0,0,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 4	(richting: achteruit)
Broadcast_Speed4:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,0,1,1, 0, 0,1,0,1,0,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 5	(richting: achteruit)
Broadcast_Speed5:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,1,0,0, 0, 0,1,0,0,0,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 6	(richting: achteruit)
Broadcast_Speed6:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,1,0,0, 0, 0,1,0,1,0,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 7	(richting: achteruit)
Broadcast_Speed7:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,1,0,1, 0, 0,1,0,0,0,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 8	(richting: achteruit)
Broadcast_Speed8:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,1,0,1, 0, 0,1,0,1,0,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 9	(richting: achteruit)
Broadcast_Speed9:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,1,1,0, 0, 0,1,0,0,0,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 10	(richting: achteruit)
Broadcast_Speed10:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,1,1,0, 0, 0,1,0,1,0,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 11	(richting: achteruit)
Broadcast_Speed11:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,0,1,1,1, 0, 0,1,0,0,0,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 12	(richting: achteruit)
Broadcast_Speed12:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,0,1,1,1, 0, 0,1,0,1,0,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 13	(richting: achteruit)
Broadcast_Speed13:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,0,0,0, 0, 0,1,0,0,1,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 14	(richting: achteruit)
Broadcast_Speed14:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,0,0,0, 0, 0,1,0,1,1,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 15	(richting: achteruit)
Broadcast_Speed15:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,0,0,1, 0, 0,1,0,0,1,0,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 16	(richting: achteruit)
Broadcast_Speed16:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,0,0,1, 0, 0,1,0,1,1,0,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 17	(richting: achteruit)
Broadcast_Speed17:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,0,1,0, 0, 0,1,0,0,1,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 18	(richting: achteruit)
Broadcast_Speed18:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,0,1,0, 0, 0,1,0,1,1,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 19	(richting: achteruit)
Broadcast_Speed19:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,0,1,1, 0, 0,1,0,0,1,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 20	(richting: achteruit)
Broadcast_Speed20:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,0,1,1, 0, 0,1,0,1,1,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 21	(richting: achteruit)
Broadcast_Speed21:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,1,0,0, 0, 0,1,0,0,1,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 22	(richting: achteruit)
Broadcast_Speed22:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,1,0,0, 0, 0,1,0,1,1,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 23	(richting: achteruit)
Broadcast_Speed23:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,1,0,1, 0, 0,1,0,0,1,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 24	(richting: achteruit)
Broadcast_Speed24:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,1,0,1, 0, 0,1,0,1,1,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 25	(richting: achteruit)
Broadcast_Speed25:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,1,1,0, 0, 0,1,0,0,1,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 26	(richting: achteruit)
Broadcast_Speed26:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,1,1,0, 0, 0,1,0,1,1,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 27	(richting: achteruit)
Broadcast_Speed27:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,0,1,1,1,1, 0, 0,1,0,0,1,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 28	(richting: achteruit)
Broadcast_Speed28:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,0,1,1,1,1,1, 0, 0,1,0,1,1,1,1,1, 1, PulsEnd, $FF



; Broadcast packet: Speed Step 1	(richting: vooruit)     _ _________
Broadcast_Speed1_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,0,1,0, 0, 0,1,1,0,0,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 2	(richting: vooruit)
Broadcast_Speed2_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,0,1,0, 0, 0,1,1,1,0,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 3	(richting: vooruit)
Broadcast_Speed3_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,0,1,1, 0, 0,1,1,0,0,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 4	(richting: vooruit)
Broadcast_Speed4_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,0,1,1, 0, 0,1,1,1,0,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 5	(richting: vooruit)
Broadcast_Speed5_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,0,0, 0, 0,1,1,0,0,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 6	(richting: vooruit)
Broadcast_Speed6_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,1,0,0, 0, 0,1,1,1,0,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 7	(richting: vooruit)
Broadcast_Speed7_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,0,1, 0, 0,1,1,0,0,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 8	(richting: vooruit)
Broadcast_Speed8_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,1,0,1, 0, 0,1,1,1,0,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 9	(richting: vooruit)
Broadcast_Speed9_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,1,0, 0, 0,1,1,0,0,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 10	(richting: vooruit)
Broadcast_Speed10_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,1,1,0, 0, 0,1,1,1,0,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 11	(richting: vooruit)
Broadcast_Speed11_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,1,1, 0, 0,1,1,0,0,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 12	(richting: vooruit)
Broadcast_Speed12_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,0,1,1,1, 0, 0,1,1,1,0,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 13	(richting: vooruit)
Broadcast_Speed13_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,0,0,0, 0, 0,1,1,0,1,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 14	(richting: vooruit)
Broadcast_Speed14_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,0,0,0, 0, 0,1,1,1,1,0,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 15	(richting: vooruit)
Broadcast_Speed15_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,0,0,1, 0, 0,1,1,0,1,0,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 16	(richting: vooruit)
Broadcast_Speed16_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,0,0,1, 0, 0,1,1,1,1,0,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 17	(richting: vooruit)
Broadcast_Speed17_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,0,1,0, 0, 0,1,1,0,1,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 18	(richting: vooruit)
Broadcast_Speed18_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,0,1,0, 0, 0,1,1,1,1,0,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 19	(richting: vooruit)
Broadcast_Speed19_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,0,1,1, 0, 0,1,1,0,1,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 20	(richting: vooruit)
Broadcast_Speed20_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,0,1,1, 0, 0,1,1,1,1,0,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 21	(richting: vooruit)
Broadcast_Speed21_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,1,0,0, 0, 0,1,1,0,1,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 22	(richting: vooruit)
Broadcast_Speed22_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,1,0,0, 0, 0,1,1,1,1,1,0,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 23	(richting: vooruit)
Broadcast_Speed23_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,1,0,1, 0, 0,1,1,0,1,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 24	(richting: vooruit)
Broadcast_Speed24_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,1,0,1, 0, 0,1,1,1,1,1,0,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 25	(richting: vooruit)
Broadcast_Speed25_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,1,1,0, 0, 0,1,1,0,1,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 26	(richting: vooruit)
Broadcast_Speed26_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,1,1,0, 0, 0,1,1,1,1,1,1,0, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 27	(richting: vooruit)
Broadcast_Speed27_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,1,1,1,1, 0, 0,1,1,0,1,1,1,1, 1, PulsEnd, $FF
; Broadcast packet: Speed Step 28	(richting: vooruit)
Broadcast_Speed28_Forward:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,1,1,1,1,1, 0, 0,1,1,1,1,1,1,1, 1, PulsEnd, $FF




;--------------------------------------/


;tabel met snelheden voor treinen
;CS3S2S1S0 	Speed		CS3S2S1S0 	Speed		CS3S2S1S0 	Speed		CS3S2S1S0 	Speed
;----------	-----------	----------- -----------	-----------	-----------	-----------	------------
;00000 		Stop 		00100 		Step 5 		01000 		Step 13 	01100 		Step 21
;10000 		Stop (I) 	10100 		Step 6 		11000 		Step 14 	11100 		Step 22
;00001 		E-Stop* 	00101 		Step 7 		01001 		Step 15 	01101 		Step 23
;10001 		E-Stop* (I) 10101 		Step 8 		11001 		Step 16 	11101 		Step 24
;00010 		Step 1 		00110 		Step 9 		01010 		Step 17 	01110 		Step 25
;10010 		Step 2 		10110 		Step 10 	11010 		Step 18 	11110 		Step 26
;00011 		Step 3 		00111 		Step 11 	01011 		Step 19 	01111 		Step 27
;10011 		Step 4 		10111 		Step 12 	11011 		Step 20 	11111 		Step 28
;
; Stop-instructies met een (I) erbij mogen optioneel de aangegeven richting (D) negeren..(Ignore)
; Een Emergency Stop (E) instructie haalt ook de stroom van de baan.
