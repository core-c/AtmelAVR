;*************************************************************************************
;***
;*** Een LED-dimmer voor 3 LED's.
;***  Hardware-matige 8-bits PWM (Timer2) met output op PD7 (OC2), standaard pin.
;***  Hardware-matige 8-bits PWM (Timer1) met output op PD4 (OC1A) & PD5 (OC1B).
;***  UART besturing vanaf PC voor 3 PWM's.
;***  ADC op PINA0. AD-waarden worden over RS232 naar de PC gestuurd.
;***
;***  De Timer1- & Timer2 prescale zetten we beiden op CK/256. Bij een hardware 
;***  8-bits PWM wordt de PWM-frequentie uiteindelijk TCK/510. (7372800/256)/510=
;***  28800/510=56.5Hz. (volgens mij zien mensen dan geen geknipper meer van de
;***  LED's. De LED's zullen dan dimmen op een frequentie van 56.5/(2^8)=0.22Hz
;***
;***  Er is ook een INT0-handler voor een aangesloten schakelaar op AVR pin 16.
;***  Indrukken van de schakelaar zorgt ervoor dat de aangesloten looplicht-LED's
;***  ge-reset worden op de waarde 001 (alleen laagste bit op 1).
;***
;***  De hoogste 3 aangesloten rode LED's (bits[3..5]) geven de richting van een
;***  motor aan. De laagste 3 bits[0..2] worden per (T2-tick) ge-roteerd.
;***  De rode LED's aan poort C blijven roteren zolang de timer2 loopt; Die draait
;***  altijd door, ook al wordt de schakelaar ingedrukt.
;***  !! De waarde op de poort wordt wèl ge-reset op 0b00000001 !!
;***
;***
;***  Wat me opvalt is dat de hardware-PWM's van Timer1 (8-bits) op de uiterste
;***  waarden van de TimerCounter1 (BOTTOM & TOP) de LED's laten knipperen. De 
;***  PWM's van Timer2 leveren dit effect niet op. (gebruik TimerOverflowIRQ ??)
;***
;***
;*** !! Gebruik het PC-programma AVR-RS232 v2
;***
;*************************************************************************************

.include "8535def.inc"

;--- De RS232 data buffer --------------
.include "RotatingBuffer.asm"
;---------------------------------------


; De PostScaler
.equ vertraging	= 8						; om de 'vertraging'-aantal Timer2-Overflow's speciale code uitvoeren
										; (dwz. de ADC-bytes verzenden over RS232  &  de rode LED's scrollen)
										; /(n+1) => T2OI/(8+1) = 56.5/9 =>
										; met een freq. van  6.27 Hz wordt een DelayedAction uitgevoerd.

; De aangesloten PWM-LED's op portD
.equ LED1A		= PD5					; deze LED gebruiken we voor T1A
.equ LED1B		= PD4					; deze LED gebruiken we voor T1B
.equ LED2		= PD7					; deze LED gebruiken we voor T2

; De signalen tbv. de richtingen van de 3 motoren op portC
.equ M1A_Direction	= PC5
.equ M1B_Direction	= PC4
.equ M2_Direction	= PC3




; Register synoniemen
.def fREG				= R8			; voor gebruik in de ISP's bewaren flag-register
.def temp				= R16
.def tempL				= R17
.def Motor				= R18
.def DutyCycle			= R1
.def Direction			= R23			; boolean: 0=false, 1=true
.def vDelay				= R19			; De PostScaler voor Delayed-Actions
.def DelayedAction		= R24			; boolean: 0=false, 1=true
.def AD_ValueL			= R9
.def AD_ValueH			= R10
.def LED1A_Brightness	= R20			; de felheid van de LED (=duty-cycle)
.def LED1B_Brightness	= R21			;
.def LED2_Brightness	= R22			;




;- De vector-tabel voor een AT90S8535 --
.CSEG									; Het code-segment selecteren
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp INT0_Interrupt					; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti;rjmp Timer2_Compare			; Timer2 compare match Vector Address
	rjmp Timer2_Overflow				; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti;rjmp Timer1A_Compare			; Timer1 Output Compare A Interrupt Vector Address
	reti;rjmp Timer1B_Compare			; Timer1 Output Compare B Interrupt Vector Address
	reti;rjmp Timer1_Overflow			; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	rjmp UART_Rx_Interrupt				; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti;rjmp UART_Tx_Interrupt			; UART Transmit Complete Interrupt Vector Address
	rjmp ADC_CC_Interrupt				; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;---------------------------------------







RESET:
	; interrupts uitschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL

	; 1 looplicht-LED aanzetten.
	; Bits[0..2] van poort C zijn de LED's voor het looplichtje,
	; Bits[3..5] van poort C zijn de LED's tbv. de richting van elke motor.
	; Eenmalig de IO-richting instellen op OUTPUT voor de bewuste pinnen van Port C...
	ldi		temp, (1<<M1A_Direction | 1<<M1B_Direction | 1<<M2_Direction | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	; ...Dan een waarde naar de poort schrijven
	ldi		temp, 0b00000001			; bits[5..3] = richting motoren, bits[2..0] = looplicht
	out		PORTC, temp

	; Port D pinnen tbv. de PWM-signalen als OUTPUT instellen.
	; We gebruiken HW-PWM, dus we gebruiken de standaard pinnen: OC1A, OC1B & OC2.
	sbi		DDRD, LED1A					; de LED aan Port C PIN
	sbi		DDRD, LED1B					; tbv. de gele LED
	sbi		DDRD, LED2					; tbv. de groene LED

	; De begin-waarde voor de brightness instellen
	ldi		LED2_Brightness, $40
	ldi		LED1A_Brightness, $80
	ldi		LED1B_Brightness, $FF
	; de vertraging instellen
	ldi		vDelay, vertraging
	; De boolean tbv. speciale acties
	clr		DelayedAction


	;--- De externe interrupt IRQ0 instellen ------------------------------------------------------------
	; externe interrupt IRQ0 inschakelen in Global Interrupt Mask Register (tbv schakelaar)
	in		temp, GIMSK
	ori		temp, (1<<INT0)
	out		GIMSK, temp
	; externe interrupt IRQ0 activeren op vallende flank
	; (trigger als de knop IN-gedrukt wordt)
	in		temp, MCUCR
	ori		temp, (1<<ISC01)
	out		MCUCR, temp


	;--- De UART instellen ------------------------------------------------------------------------------
	; de RS232 Data-Ontvangst-Buffer in SRAM inintialiseren
	rcall	UART_Initialize_Buffer
	; De UART zelf initialiseren
	rcall	UART_Initialize


	;--- De Timers instellen ----------------------------------------------------------------------------
	; De interrupts voor Overflow & Compare-Match instellen
	; Timer2 wordt gebruikt voor het LED-looplicht en voor 
	; de UART-Transmissies van de ADC-data die ge-sampled is.
	ldi		temp, (0<<OCIE1A | 0<<OCIE1B | 0<<TOIE1 | 0<<OCIE2 | 1<<TOIE2) ; alleen overflow T2
	out		TIMSK, temp

	;--- De duty-cycles instellen
	; Output Compare Register 1A
	clr		temp
	out		OCR1AH, temp
	out		OCR1AL, LED1A_Brightness
	; Output Compare Register 1B
	out		OCR1BH, temp
	out		OCR1BL, LED1B_Brightness
	; Output Compare Register 2
	out		OCR2, LED2_Brightness

	;--- Timer2- & Timer1-counter instellen
	; Timer CouNTer 1
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp;LED1A_Brightness
	; Timer CouNTer 2
	out		TCNT2, temp

	;--- Timer2 Clock en PWM instellen,
	; De Timer1 in hardware-PWM mode schakelen, anders kunnen we
	; geen 2 PWM pulzen genereren.
	; HW Non-Inverted PWM selecteren voor beide Timer1, 1A & 1B.
	ldi		temp, (1<<COM1A1 | 0<<COM1A0 | 1<<COM1B1 | 0<<COM1B0 | 0<<PWM11 | 1<<PWM10)
	out		TCCR1A, temp
	; TCK instellen op CK/256
	ldi		temp, (1<<CS12 | 0<<CS11 | 0<<CS10);CK/256
;	ldi		temp, (1<<CS12 | 0<<CS11 | 1<<CS10);CK/1024
	out		TCCR1B, temp
	;
	; Timer2 Hardware PWM-mode inschakelen, Non-Inverted PWM selecteren, Clock op CK/256 instellen.
	ldi		temp, (1<<PWM2 | 1<<COM21 | 0<<COM20 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	out		TCCR2, temp

	;--- De ADC instellen -------------------------------------------------------------------------------
	rcall	ADC_Initialize
	; interrupts inschakelen
	sei
	; start de eerste AD-conversie.
	; Als Free-Running-mode is geselecteerd, dan volgen de andere conversies "automatisch"
	sbi		ADCSR, ADSC

	;--- De mainloop ------------------------------------------------------------------------------------
eLoop:
	; eventuele seriële data verwerken (zsm).
	rcall	UART_ProcessRecordIn
	; Na de (software)-vertraging wat extra code uitvoeren.
	; Dit doe ik omdat er wel zo ontzettend veel Timer2-ticks komen
	; als een AVR op 7.3728MHz loopt (/128 voor timer). De vertraging is als het ware
	; een Post-Overflow. (De vertraging functioneert als een
	; deler op de Timer-2 events.)
	sbrs	DelayedAction, 0 ; Als DelayedAction niet gezet is, dan springen naar eLoop.
	rjmp	eLoop

	; Als er ge-samplede waarden klaar staan van de ADC,
	; dan deze nu verzenden over RS232 naar de PC.
	rcall	ADC_ProcessValuesOut

	; De laagste 3 rode LED's laten scrollen (looplicht).
	rcall	LED_ProcessScroll

	; De boolean op false om aan te geven
	; dat we klaar zijn met de uitvoer van de extra code
	clr		DelayedAction
	; De main-loop herhalen....
	rjmp eLoop












;------------------------------------------
;--- De INT0 Interrupt-Handler
;------------------------------------------
INT0_Interrupt:
	in		fREG, SREG
	push	temp
	;--- Als de schakelaar wordt ingedrukt, wordt INT0 gegenereerd.
	; zet 1 bit aan op poort C
	in		temp, PORTC ; port=output, pin=input
;@	in		temp, PINC
	andi	temp, 0b11111000
	ori		temp, 0b00000001
	out		PORTC, temp
	;
	pop		temp
	out		SREG, fREG
	reti









;------------------------------------------
;--- Subroutine: Scroll de 3 laagste LED's
;------------------------------------------
LED_ProcessScroll:
	; De laagste 3 bits van poort C (LED's) rotaten/shiften
	; De andere bits ongemoeid laten....
	in		temp, PORTC	;port=output, pin=input
;@	in		temp, PINC
	mov		tempL, temp
	andi	temp, 0b11111000
	andi	tempL, 0b00000111
	lsl		tempL
	sbrc	tempL, 0b00001000
	ori		tempL, 0b00000001
	andi	tempL, 0b00000111
	add		temp, tempL
	out		PORTC, temp
	ret







;##;---------------------------------------
;##;- De LED-fader subroutine voor LED2
;##;---------------------------------------
;##LED2Fader:
;##	; De duty-cycle aanpassen voor het LED-fade effect
;##	tst		LED2_CountingUp
;##	breq	TelOmlaag
;##TelOmhoog:
;##	inc		LED2_Brightness
;##	brne	done
;##	clr		LED2_CountingUp
;##	dec		LED2_Brightness				; brightness corrigeren (max=TOP, niet 0)
;##	rjmp	done
;##TelOmlaag:
;##	dec		LED2_Brightness
;##	brne	done
;##	ser		LED2_CountingUp
;##	inc		LED2_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
;##done:
;##	; De duty-cycle instellen op het Output-Compare-Register voor Timer2
;##	out		OCR2, LED2_Brightness
;##	ret




;##;---------------------------------------
;##;- De LED-fader subroutine voor LED1A
;##;---------------------------------------
;##LED1AFader:
;##	push	tREG
;##	; De duty-cycle aanpassen voor het LED-fade effect
;##	tst		LED1A_CountingUp
;##	breq	TelOmlaag1A
;##TelOmhoog1A:
;##	inc		LED1A_Brightness
;##	brne	done1A
;##	clr		LED1A_CountingUp
;##	dec		LED1A_Brightness				; brightness corrigeren (max=TOP, niet 0)
;##	rjmp	done1A
;##TelOmlaag1A:
;##	dec		LED1A_Brightness
;##	brne	done1A
;##	ser		LED1A_CountingUp
;##	inc		LED1A_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
;##done1A:
;##	; De duty-cycle instellen op het Output-Compare-Register voor Timer1A
;##	clr		tREG
;##	out		OCR1AH, tREG
;##	out		OCR1AL, LED1A_Brightness
;##	;
;##	pop		tREG
;##	ret




;##;---------------------------------------
;##;- De LED-fader subroutine voor LED1B
;##;---------------------------------------
;##LED1BFader:
;##	push	tREG
;##	; De duty-cycle aanpassen voor het LED-fade effect
;##	tst		LED1B_CountingUp
;##	breq	TelOmlaag1B
;##TelOmhoog1B:
;##	inc		LED1B_Brightness
;##	brne	done1B
;##	clr		LED1B_CountingUp
;##	dec		LED1B_Brightness				; brightness corrigeren (max=TOP, niet 0)
;##	rjmp	done1B
;##TelOmlaag1B:
;##	dec		LED1B_Brightness
;##	brne	done1B
;##	ser		LED1B_CountingUp
;##	inc		LED1B_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
;##done1B:
;##	; De duty-cycle instellen op het Output-Compare-Register voor Timer1B
;##	clr		tREG
;##	out		OCR1BH, tREG
;##	out		OCR1BL, LED1B_Brightness
;##	;
;##	pop		tREG
;##	ret




;**;---------------------------------------
;**;- De Timer1-Overflow Interrupt-Handler
;**;---------------------------------------
;Timer1_Overflow:
;**	; Als de timer-counter de TOP bereikt heeft,
;**	; wordt een Overflow-interrupt gegenereerd.
;	;
;	; De uitgang van het PWM-signaal hoog maken
;	; bij de start van een nieuwe puls.
;**;	sbi		PORTD, LED1A
;**;	sbi		PORTD, LED1B
;**	;
;**;@@	; Een extra vertraging inbouwen
;**;@@	dec		delay
;**;@@	brne	doneHere
;**;@@	ldi		delay, vertraging
;**	;
;**;##	tst		LED_OnOff					; staat de dimmer aan??
;**;##	breq	doneHere1
;**;##	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
;**;##	rcall	LED1AFader
;**;##	rcall	LED1BFader
;**;##doneHere1:
;	reti






;**;---------------------------------------
;**;- De Timer1A-Compare Interrupt-Handler
;**;---------------------------------------
;**Timer1A_Compare:
;**	;--- Als de timer1-counter = OCR1A, wordt een Comnpare-interrupt gegenereerd.
;**	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
;**;	cbi		PORTD, LED1A
;**	reti







;**;---------------------------------------
;**;- De Timer1B-Compare Interrupt-Handler
;**;---------------------------------------
;**Timer1B_Compare:
;**	;--- Als de timer1-counter = OCR1B, wordt een Comnpare-interrupt gegenereerd.
;**	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
;**;	cbi		PORTD, LED1B
;**	reti







;---------------------------------------
;- De Timer2-Overflow Interrupt-Handler
;---------------------------------------
Timer2_Overflow:
;	push	temp
;	push	tempL
	in		fREG, SREG
	; Als de timer-counter de TOP bereikt heeft,
	; wordt een Overflow-interrupt gegenereerd.
	;
	; Bij Software PWM:
	; De uitgang van het PWM-signaal hoog maken
	; bij de start van een nieuwe puls.
;	sbi		PORTD, LED2
	;
	; Een extra vertraging inbouwen voor de rode LED-shift op poort C
	dec		vDelay
	brne	PostScalerDone
	ldi		vDelay, vertraging			; de vertraging opnieuw initiëren.
	; De boolean zetten om aan te geven dat de verzamelde gegevens
	; nu verwerkt kunnen worden in de mainloop-procedures.
	ser		DelayedAction
PostScalerDone:
	;
;##	tst		LED_OnOff					; staat de dimmer aan??
;##	breq	doneHere
;##	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
;##	rcall	LED2Fader
;##doneHere:
	;
	out		SREG, fREG
;	pop		tempL
;	pop		temp
	reti






;**;---------------------------------------
;**;- De Timer2-Compare Interrupt-Handler
;**;---------------------------------------
;**Timer2_Compare:
;**	;--- Als de timer-counter = OCR2, wordt een Comnpare-interrupt gegenereerd.
;**	;
;**	; Bij Software PWM:
;**	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
;**;	cbi		PORTD, LED2
;**	reti











;------------------------------------------
;--- Subroutine: Record in Rx-Data-Buffer??
;------------------------------------------
UART_ProcessRecordIn:
	; Als er genoeg bytes in de buffer staan om een record te vullen dan verwerken die bytes
	LoadRegister temp, BytesInBuffer
	cpi		temp, 3
;**	cpi		temp, 2

	brsh	RecordInBuffer
	rjmp	doneCheck

RecordInBuffer:
	; lees de 3 bytes uit de buffer en verwerk ze
	LoadByteFromBuffer Motor,     RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize ; motor
	LoadByteFromBuffer DutyCycle, RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize ; PWM-dutyCycle
	LoadByteFromBuffer Direction, RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize ; richting ;**
;**	ser		Direction

	; Bepaal voor welke motor de data bedoeld is
	cpi		Motor, $1A
	brne	is1B
	; Timer1-CompareA waarde instellen (PWM puls breedte)
	clr		temp
	out		OCR1AH, temp
	out		OCR1AL, DutyCycle
	; De richting op de AVR-pin instellen
	sbrc	Direction, 0
	sbi		PORTC, M1A_Direction
	sbrs	Direction, 0
	cbi		PORTC, M1A_Direction
	rjmp	doneCheck
is1B:
	cpi		Motor, $1B
	brne	is2
	; Timer1-CompareB waarde instellen (PWM puls breedte)
	clr		temp
	out		OCR1BH, temp
	out		OCR1BL, DutyCycle
	; De richting op de AVR-pin instellen
	sbrc	Direction, 0
	sbi		PORTC, M1B_Direction
	sbrs	Direction, 0
	cbi		PORTC, M1B_Direction
	rjmp	doneCheck
is2:
	cpi		Motor, $2
	brne	doneCheck
	; Timer2-Compare waarde instellen (PWM puls breedte)
	out		OCR2, DutyCycle
	; De richting op de AVR-pin instellen
	sbrc	Direction, 0
	sbi		PORTC, M2_Direction
	sbrs	Direction, 0
	cbi		PORTC, M2_Direction
doneCheck:
	ret



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

;	; was er een framing-error??
;	in		tempL, USR
;	sbrs	tempL, FE
;	rjmp	NoFrameError
;@@	; Bij een Frame-Error dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
;	rjmp	doneRx
;NoFrameError:

;@@	; was er een overrun?? (laatst ontvangen byte nog niet verwerkt)
;	in		tempL, UCR
;	sbrs	tempL, 3 						; OR-bit
;	rjmp	NoOverrun
;@@	; Bij een overrun dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
;	rjmp	doneRx
;NoOverrun:

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
;--- Subroutine: ADC samples klaar voor Tx??
;------------------------------------------
ADC_ProcessValuesOut:
	; Er staan wat ge-samplede waarden klaar om te verzenden over RS232
	mov		temp, AD_ValueL
	rcall	UART_transmit
	mov		temp, AD_ValueH
	rcall	UART_transmit
	ret


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
;	in		fREG, SREG
	; De geconverteerde waarden inlezen van de ADC en
	; bewaren in de toegewezen registers.
	in		AD_ValueL, ADCL
	in		AD_ValueH, ADCH
	;
;	out		SREG, fREG
	reti



