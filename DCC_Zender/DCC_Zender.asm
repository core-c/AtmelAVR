
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
.include "System.inc"					; 
;.list
;--------------------------------------/



;--- CONSTANTEN -----------------------\
.equ CK = 8000000						; CPU clock frequentie					; 8000000
.equ TCK = CK/8							; timer1 frequentie						; CK/8
.equ Tick = 1/TCK						; de duur van 1 (timer)tick in seconden	; 1/TCK
.equ Puls1 = 60							; 60us
.equ Puls0 = 100						; 100us
.equ PulsEnd = $FFFF
; de zender moet om de 30ms een packet verzenden.
; we gebruiken Timer0 om een frequentie van
; (ongeveer) 30ms te genereren.
; CK=8MHz, T0CK=CK/1024, T0_OVF om de 256 timerticks =>
; frequentie-interval komt uit op 0.032768 seconden, dat is 32.768 ms
.equ T0CK = CK/1024



;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17
.def hooglaag		= R18
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
	rjmp Timer_Interrupt_CompareA		; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/



;--- bitstream
;--------------------------------------\
BitStream:
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,1,0,0,1, 0, 0,1,1,1,1,1,0,1, 1,    1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,0,0,0,1, 0, 0,1,1,1,0,1,0,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1,     PulsEnd, $FF

; SET GA N 13 1 1 2000
; $84 F9 7D (aan)
; 	11111111111111 0 10000100 0 11111001 0 01111101 1
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,1,0,0,1, 0, 0,1,1,1,1,1,0,1, 1, PulsEnd, $FF
 
;IdleStream:
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 1,1,1,1,1,1,1,1, 1

; $84 F1 75 (uit)
; 	11111111111111 0 10000100 0 11110001 0 01110101 1
;.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 1,0,0,0,0,1,0,0, 0, 1,1,1,1,0,0,0,1, 0, 0,1,1,1,0,1,0,1, 1, PulsEnd, $FF
;

; Broadcast packet MET speed op step 5
;	$00, 0b01DCSSSS, EEEEEEEE		D=1 forward, D=0 backward
.DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0, 0,0,0,0,0,0,0,0, 0, 0,1,1,0,0,1,0,0, 0, 0,1,1,0,0,1,0,0, 1, PulsEnd, $FF
;--------------------------------------/




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
	; compareA waarde instellen op een lange pauze
	ldi		temp, high(5530)			; 6ms
	out		OCR1AH, temp
	ldi		temp, low(5530)
	out		OCR1AL, temp
;of..
;	ldi		temp, 0						; willekeurige waarde 
;	out		OCR1AH, temp				;
;	ldi		temp, $FF					;
;	out		OCR1AL, temp				;


	; pointer naar begin BitStream verplaatsen
	ldi		ZL, low(2*BitStream)
	ldi		ZH, high(2*BitStream)
	ldi		hooglaag, 0

Done_Handle_Bit:
	ret






;---------------------------------------
;--- De Timer1 initialiseren
;--------------------------------------\
Timer_Initialize:
	; interrupts tegengaan
	clr		temp
	out		TIMSK, temp
	; poort D pin 6 als output instellen
	; voor de DCC-output
	sbi		DDRD, PD6
	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp
	; De Timer1: noise canceler uit
	; clear counter on compareA match
	; TCK op CK/8
	ldi		temp, (0<<ICNC1 | 1<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
	out		TCCR1B, temp
	; timer1 compareA match interrupt inschakelen
	ldi		temp, (1<<OCIE1A)
	out		TIMSK, temp
	; de eerste "1"-bit beginnen
	; en de compareA waarde instellen
	ldi		hooglaag, 1
	sbi		PORTD, PD6
	; compareA waarde instellen voor de eerste match
	; (schrijven high/low:)
	ldi		temp, 0
	out		OCR1AH, temp
	ldi		temp, Puls1
	out		OCR1AL, temp
	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
	ret
;--------------------------------------/



 ;---------------------------------------
;--- De Timer1 CompareA handler
;--------------------------------------\
Timer_Interrupt_CompareA:
; 	push	temp2
	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp
	
	rcall	Handle_Bit

	pop		temp
	out		SREG, temp
	pop		temp
;	pop		temp2
	reti
;--------------------------------------/



;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer

	;-- initialisatie
	; de pointer naar de bitstream in CSEG
	ldi		ZL, low(2*BitStream)
	ldi		ZH, high(2*BitStream)
	; de timer en interrupts
	rcall	Timer_Initialize
	;--

	sei									; interrupts weer toelaten

main_loop:
	rjmp 	main_loop
;--------------------------------------/




