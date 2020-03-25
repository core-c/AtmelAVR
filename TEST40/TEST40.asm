
;*******************************************************************************
;***
;*** Een servo aansturing.
;***
;***  PWM puls interval = 40ms.  Een puls van 1ms zorgt ervoor dat de servo
;***  helemaal linksom gestuurd wordt. Een puls van 2ms draait de servo helemaal
;***  rechtsom. => Een puls van 1.5ms plaatst de servo in het midden.
;***
;*** Software-matige PWM. 16-bit timer1
;*** met Overflow A-, Overflow B- & Compare-Interrupts.
;***
;***  Onze AVR's clockspeed bedraagt 7.3728 Mhz  =  7372800 Hz.
;***  De Timer-PreScale wordt ingesteld op CK/8.
;***	clockspeed / 8	= 7372800 / 8 = 921600 Hz Timer-frequentie.
;*** 
;***  De PWM-resolutie bepaalt de TOP-waarde van de Timer-Counter :
;***	 8 bits PWM : Timer-Counter TOP =	00FF	0000000011111111	 255
;***	 9 bits PWM : Timer-Counter TOP =	01FF	0000000111111111	 511
;***	10 bits PWM : Timer-Counter TOP =	03FF	0000001111111111	1023
;***
;*** De timer-counter waarden voor een pulsinterval van 40ms wordt verkregen door
;*** de volgende CompareA- & CompareB-waarden voor timer1: 36864 & 18432 (9000h & 4800h).
;*** Een pulsbreedte van 1ms duurt 2.5% van de volle 40ms  =>  2.5% * 36864 = 921.6 ticks.
;*** Een pulsbreedte van 2ms duurt 5% van de volle 40ms  =>  5% * 36864 = 1843.2 ticks.
;*** 
;***
;***
;***
;***
;*************************************************************************************
;
.include "8535def.inc"

;--- De RS232 data buffer --------------
.include "RotatingBuffer.asm"
;---------------------------------------

;--- constanten tbv. PWM ---------------
.include "CoreDef.inc"


;--- De clock-frequentie (CK) van onze AVR (in Hz.)
.equ CK = 7372800
;--- tijdsduren in milliseconden (timerticks)
.equ ms1	= 922			; 039Ah
.equ ms0_5	= ms1/2			;
.equ ms1_5	= (ms2-ms1)/2	;
.equ ms2	= 1843			; 0733h
.equ ms3	= 3*ms1			;


; De Software PWM TOP-waarde instellen (PWM-frequentie)
; Dit is de CompareA waarde.
.equ PWM_FREQ		= 18432;50Hz    ;36864;40Hz
;--- De Timer1 CompareB-waarde ----------
.equ DUTY_CYCLE		= ms1_5










;--- Register synoniemen ---------------
.def fREG		= R8					; voor gebruik in de ISP's bewaren flag-register
.def temp		= R16
.def tempL		= R17
.def Treg		= R20					; regsiter tbv. de timer-handler
.def AD_ValueL	= R21
.def AD_ValueH	= R22




;--- Macro's ---------------------------
.MACRO SET_STACKPOINTER
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL
.ENDMACRO

.MACRO SET_PIN_AS_OUTPUT;(Poort: byte; Pin : bit-nummer)
	; Éen bit van een poort als output zetten
	ldi		temp, (1<<@1)				; argument(1) is de Pin
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_PINS_AS_OUTPUT;(Poort: byte; Pins : byte-mask)
	clr		temp
	ori		temp, @1					; argument(1) is het Pins-masker
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_LEDS;(Poort: byte; Pins : byte-mask)
	ldi		temp, @1
	out		@0, temp
.ENDMACRO

.MACRO SET_PWM_DUTYCYCLE_1B;(CompareB-waarde : word)
	ldi		temp, high(@0)				; argument(0) is de pulsbreedte (CompareB-waarde)
	ldi		tempL, low(@0)
	out		OCR1BH, temp
	out		OCR1BL, tempL
.ENDMACRO

.MACRO SET_PWM_FREQ_1A;(CompareA-waarde : word)
	ldi		temp, high(@0)				; argument(0) is de PWM-frequentie (CompareA-waarde)
	ldi		tempL, low(@0)
	out		OCR1AH, temp
	out		OCR1AL, tempL
.ENDMACRO

.MACRO SET_TIMER1_PWM_MODE;(PWM-mode : byte)
	ldi		temp, @0					; argument(0) is de PWM-mode byte
	out		TCCR1A, temp 
.ENDMACRO

.MACRO SET_TIMER1FREQ;(frequentie : byte)
	ldi		temp, @0					; argument(0) is de Timer1-Clock
	out		TCCR1B, temp
.ENDMACRO

.MACRO RESET_TIMER1COUNTER_ON_COMPAREA
	in		temp, TCCR1B
	ori		temp, (1<<CTC1)				; CTC1 = clear timer-counter on compare match A
	out		TCCR1B, temp
.ENDMACRO

.MACRO CLEAR_TIMER1COUNTER
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO USE_INTERRUPTS;(InterruptFlags : byte-mask)
	in		temp, TIMSK					; Het Timer-Interrupt-Mask-Register aanspreken
	ori		temp, @0					; argument(0) is het Interrupt-Enable-Flag masker
	out		TIMSK, temp
.ENDMACRO

.MACRO MAIN_LOOP
eLoop:
	rjmp eLoop							; eeuwige lus....
.ENDMACRO





;--- De vector-tabel -------------------
; Het begin van het CODE-segment
.CSEG									; Het code-segment selecteren
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het geheugen
	rjmp RESET							; Reset Handler
	reti								; External Interrupt 0
	reti								; External Interrupt 1
	reti								; Timer2 compare match
	reti								; Timer2 overflow
	reti								; Timer1 Input Capture
	rjmp Timer_Interrupt_CompareA		; Timer1 Output Compare A
	rjmp Timer_Interrupt_CompareB		; Timer1 Output Compare B
	reti								; Timer1 Overflow
	reti								; Timer0 Overflow
	reti								; SPI
	rjmp UART_Rx_Interrupt				; UART Receive Complete
	reti								; UART Data Register Empty
	reti								; UART Transmit Complete
	rjmp ADC_CC_Interrupt				; ADC Conversion Complete
	reti								; EEPROM Write Complete
	reti								; Analog Comparator
;---------------------------------------




RESET:
	; De stack-pointer instellen op het einde van het RAM
	SET_STACKPOINTER
	; zorg ervoor dat geen interrupts voorvallen tijdens zetten van deze PWM-mode
	cli
	clr		temp
	out		TIMSK, temp

	;nog even wat LED's aanzetten ter indicatie dat de AVR runt.
	SET_PINS_AS_OUTPUT DDRC, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)
	; alle LED's aan bij 16-bits software PWM test 40
	SET_LEDS PORTC, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)


	; poort D pin 4 (OC1B) als output zetten voor de PWM output-pin
	SET_PIN_AS_OUTPUT DDRD, PIND4


	;--- De UART instellen ------------------------------------------------------------------------------
	; de RS232 Data-Ontvangst-Buffer in SRAM inintialiseren
	rcall	UART_Initialize_Buffer
	; De UART zelf initialiseren
	rcall	UART_Initialize


	; Hardware-matige PWM uitschakelen, hardware-matige pin-output ook uitschakelen.
	; We gebruiken alleen de timer-counter en compare registers voor de telling.
	; De pin-out regelen we zelf in de onCompare(A & B)Match handlers.
	SET_TIMER1_PWM_MODE	(PWM_COMPAREA_ACTION_OFF | PWM_COMPAREB_ACTION_OFF | PWM_OFF)

	; Timer1 clock instellen.
	SET_TIMER1FREQ TIMERFREQ_CK8
	
	; De Timer1-Counter resetten op een CompareA Match
	RESET_TIMER1COUNTER_ON_COMPAREA
	
	; De PWM TOP-waarde instellen (PWM-frequentie)
	SET_PWM_FREQ_1A PWM_FREQ
	; De duty-cycle instellen op een 16-bit waarde
	SET_PWM_DUTYCYCLE_1B DUTY_CYCLE

	USE_INTERRUPTS (TIMER1_COMPAREA | TIMER1_COMPAREB)

	; de counter op 0 instellen om direct met een puls te beginnen
	CLEAR_TIMER1COUNTER

	;--- De ADC instellen -------------------------------------------------------------------------------
	rcall	ADC_Initialize
	; interrupts inschakelen
	sei
	; start de eerste AD-conversie.
	; Als Free-Running-mode is geselecteerd, dan volgen de andere conversies "automatisch"
	sbi		ADCSR, ADSC
	;----------------------------------------------------------------------------------------------------

;	MAIN_LOOP
eLoop:
	; eventuele seriële data verwerken (zsm).
	rcall	UART_ProcessRecordIn
	;	
	rjmp eLoop							; eeuwige lus....








;--- De Timer-Compare-A Interrupt routine -------------------------------------------
Timer_Interrupt_CompareA:
;	in		status, SREG
	; pin op 1
	in		Treg, PORTD
	ori		Treg, (1<<PIND4)			; set Bit
	out		PORTD, Treg
	;
;	; de counter resetten
;	clr		Treg
;	out		TCNT1H, Treg
;	out		TCNT1L, Treg
	; omdat de CTC1 bit in het TCCR1B register wordt de counter
	; "automatisch" op 0 gezet bij een CompareA match.
	;
;	out		SREG, status
	reti





;--- De Timer-Compare-B Interrupt routine -------------------------------------------
Timer_Interrupt_CompareB:
	; Een timer-compare interrupt komt voor als de timer-teller de compare-waarde
	; heeft afgeteld. De CompareB-waarde representeert de pulsbreedte.
	; Als een compare-interrupt plaatsvindt moeten we de pin zelf weer laag maken.
	;
;	in		status, SREG
	;
	; pin op 0
	in		Treg, PORTD
	andi	Treg, ~(1<<PIND4)			; Clear Bit van register 'temp'
	out		PORTD, Treg
	;
;	out		SREG, status
	reti






;------------------------------------------
;--- ADC: Initialiseer de ADC. (subroutine)
;------------------------------------------
ADC_Initialize:
	; Poort A pin 0 als input instellen
	cbi		DDRA, PINA0
	; pushpull instellen??
	; 

	; ADC Enable
	; ADC Free Running Mode selecteren
	; ADC Interrupt Enable na Conversion-Complete
	; ADC prescale instellen: 7.73728 MHz / 128 = 57600 Hz
	ldi		temp, (1<<ADEN | 1<<ADFR | 1<<ADIE | 1<<ADPS2 | 1<<ADPS1 | 1<<ADPS0)
	out		ADCSR, temp

	; Selecteer ADC kanaal 0 op de multiplexer
	ldi		temp, 0
	out		ADMUX, temp

	ret



;------------------------------------------
;--- ADC: Conversion Complete (interrupt)
;------------------------------------------
ADC_CC_Interrupt:
	in		fREG, SREG
	; De geconverteerde waarden inlezen van de ADC.
	; Waarden lopen van $0000-$03FF (0-1023)
	; Ik tel zolang de AD-waarde op bij ms1 (922)
	; De uitkomst wordt dan max. 101 te hoog.
	; Een te hoge waarde wordt gecorrigeerd.
	in		AD_ValueL, ADCL
	in		AD_ValueH, ADCH
	; register Z laden met de waarde voor 1 milliseconde
	ldi		ZL, low(ms1)
	ldi		ZH, high(ms1)
	; nu de ADC-waarde erbij optellen
;	clc
	add		ZH, AD_ValueH
;	clc							;adiw	ZL, AD_ValueL
	add		ZL, AD_ValueL
	brcc	noCarry
	inc		ZH
noCarry:
;**	; nu zorgen dat de waarde niet boven 0733h uitkomt
;**	cpi		ZH, $07
;**	brne	writeDutyCycle		;brlo
;**	cpi		ZL, $33
;**	brlo	writeDutyCycle
;**	ldi		ZL, $33
	;
writeDutyCycle:
	;SET_PWM_DUTYCYCLE_1B ZH*256+ZL
	out		OCR1BH, ZH
	out		OCR1BL, ZL
	;
doneCC:
	out		SREG, fREG
	reti









;------------------------------------------
;--- Subroutine: Initialiseer Rx-Data-Buffer
;------------------------------------------
UART_Initialize_Buffer:
	; variabelen instellen voor het aantal bytes in de buffer.
	StoreByte BytesInBuffer, 0
	; De buffer pointers instellen op het begin van de buffer.
	; voor (buffer) inkomende bytes....
	StoreWord RS232Input, RS232Buffer
	; voor (buffer) uitgaande bytes....
	StoreWord RS232Output, RS232Buffer
	ret



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	; De baudrate instellen op 19200
	; (met een afwijking van 0.0% @ 7.3728MHz)
	ldi		temp, 23 ; 19200
	;ldi		temp, 47 ; 9600
	out		UBRR, temp
	;Schakel de receiver, transmitter & TXCint in
	ldi		temp, (1<<RXCIE) | (1<<RXEN) | (1<<TXEN)
	out		UCR, temp
	ret



;------------------------------------------
;--- UART: Verzend een byte. (subroutine)
;---
;--- De te verzenden byte tevoren in
;--- register 'temp' laden.
;------------------------------------------
UART_transmit:
	; Klaar om te verzenden ??
;	sbis	USR, RXC		;!!!!!DEBUG!!!!! testje
;	rjmp	UART_transmit	;
;	sbis	USR, TXC		;!!!!!DEBUG!!!!! testje
;	rjmp	UART_transmit	;
	;
	sbis	USR, UDRE
	rjmp	UART_transmit
	out		UDR, temp
	ret



;------------------------------------------
;--- De UART-Rx Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	in		fREG, SREG
	push	temp
	; Lees de ontvangen byte van het UART Data Register,
	in		temp, UDR

	; was er een framing-error??
	in		tempL, USR
	sbrs	tempL, FE
	rjmp	NoFrameError
;@@	; Bij een Frame-Error dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
	rjmp	doneRx
NoFrameError:

	; was er een overrun?? (laatst ontvangen byte nog niet verwerkt)
	in		tempL, UCR
	sbrs	tempL, 3 						; OR-bit
	rjmp	NoOverrun
;@@	; Bij een overrun dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
	rjmp	doneRx
NoOverrun:

	; plaats de byte in de roterende data-buffer
	StoreByteIntoBuffer temp, RS232Buffer, RS232Input, BytesInBuffer, RS232BufferSize

doneRx:
	pop		temp
	out		SREG, fREG
	reti




;%%;------------------------------------------
;%%;--- De UART-Tx-Complete Interrupt-Handler
;%%;------------------------------------------
;%%UART_Tx_Interrupt:
;%%doneTx:
;%%	reti



;------------------------------------------
;--- Subroutine: Record in Rx-Data-Buffer??
;------------------------------------------
UART_ProcessRecordIn:
	; Als er genoeg bytes in de buffer staan om een record te vullen dan verwerken die bytes
	LoadRegister temp, BytesInBuffer
	cpi		temp, 2
	brsh	RecordInBuffer
	rjmp	doneCheck
	;
RecordInBuffer:
	; lees de 2 bytes uit de buffer en verwerk ze als 1 16-bit getal
	LoadByteFromBuffer tempL, RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize
	LoadByteFromBuffer temp, RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize
	;
	;SET_PWM_DUTYCYCLE_1B tempH*256+tempL
	out		OCR1BH, temp
	out		OCR1BL, tempL
	
	;
doneCheck:
	ret



