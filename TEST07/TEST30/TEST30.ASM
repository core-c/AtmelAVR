

;*************************************************************************************
;***
;*** Een LED-dimmer voor 3 LED's.
;***  Software-matige 8-bits PWM (Timer2) met output op PD7 (OC2), standaard pin.
;***  Hardware-matige 8-bits PWM (Timer1) met output op PD4 (OC1A) & PD5 (OC1B).
;***  (Hoewel we bij software-matige PWM zelf de output-pin kunnen selecteren voor
;***   het PWM-signaal, kies ik er nu voor om de standaard poort te gebruiken.)
;***  UART besturing vanaf PC voor 3 PWM's.
;***
;***
;***  De Timer1- & Timer2 prescale zetten we beiden op CK/256. Bij een hardware 
;***  8-bits PWM wordt de PWM-frequentie uiteindelijk TCK/510. (7372800/256)/256=
;***  28800/256=125.5Hz. (volgens mij zien mensen dan geen geknipper meer van de
;***  LED's ;) De LED's zullen dan dimmen op een frequentie van 112.5/(2^8)=0.44Hz
;***  Bij een software-matige PWM op timer2 wordt de uiteindelijke PWM-frequentie 
;***  2x zo hoog, dit geldt voor de groene timer2-LED.
;***
;***  Er is ook een INT0-handler voor een aangesloten schakelaar op AVR pin 16.
;***  Als de schakelaar wordt ingedrukt, wordt de dimmer in pauze-stand gezet.
;***  Nogmaals indrukken om de dimmer weer verder te starten.
;***  NB: Als de dimmer in pauze-stand staat, worden er nog steeds PWM-pulzen naar
;***  de LED's gestuurd (zodat deze dimmen). De pulsbreedte wordt echter niet meer
;***  aangepast, totdat de schakelaar nogmaals ingedrukt wordt.
;***  De rode LED's aan poort C blijven roteren zolang de timer2 loopt; Die draait
;***  altijd door, ook al wordt de schakelaar ingedrukt (LED-dimmer gepauzeerd).
;***  !! De waarde op de poort wordt wèl ge-reset op 0b00010000 !!
;***
;***
;***  Wat me opvalt is dat de hardware-PWM's van Timer1 (8-bits) op de uiterste
;***  waarden van de TimerCounter1 (BOTTOM & TOP) de LED's laten knipperen. De 
;***  software-matige PWM's van Timer2 leveren dit effect niet op.
;***  (misschien dat dit effect niet te zien is als de duty-cycle ingesteld wordt
;***   op een compare-match ipv. een overflow).
;***
;*************************************************************************************

.include "8535def.inc"

.equ LED_GREEN		= PD7				; de PWM output pinnen met de
.equ LED_YELLOW		= PD4				; toegewezen/verbonden LED-kleuren.
.equ LED_ORANGE		= PD5				;

.equ LED1A	= LED_ORANGE				; deze LED gebruiken we voor T1A
.equ LED1B	= LED_YELLOW				; deze LED gebruiken we voor T1B
.equ LED2	= LED_GREEN					; deze LED gebruiken we voor T2

; De PostScaler
.equ vertraging	= 8

; Register synoniemen
.def AD_ValueL			= R14
.def AD_ValueH			= R15
.def temp				= R16
.def tempL				= R17
.def LED1A_Brightness	= R18			; de felheid van de LED (=duty-cycle)
.def LED1B_Brightness	= R20			;
.def LED2_Brightness	= R22			;
.def LED_OnOff			= R24			; de aan/uit status: 0=uit, 1=aan
.def tREG				= R25			; voor gebruik in de ISP's
.def lastRead			= R26			; laatst gelezen byte van UART-Rx
.def lastRead2			= R27			; de 2e gelezen byte
.def vDelay				= R28			; De PostScaler




; Het begin van het CODE-segment
.cseg
;--- De vector-tabel -------------------
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp IRQ0_Interrupt					; External Interrupt0 Vector Address
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
	reti								; UART Transmit Complete Interrupt Vector Address
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
	; nog even een LED aanzetten ter indicatie dat de AVR runt.
	ldi		temp, (1<<PC5 | 1<<PC4 | 1<<PC3 | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	ldi		temp, 0bx00000001
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM

	; poort D als output zetten voor de PWM output-pinnen
	sbi		DDRD, LED1A					; tbv. de oranje LED
	sbi		DDRD, LED1B					; tbv. de gele LED
	sbi		DDRD, LED2					; tbv. de groene LED

	ldi		LED2_Brightness, $80		; De begin-brightness op 50% instellen
	ldi		LED1A_Brightness, $80
	ldi		LED1B_Brightness, $80
	; schakel de dimmer aan
	ser		LED_OnOff

	; de vertraging instellen
	ldi		vDelay, vertraging

	;--- De UART instellen ------------------------------------------------------------------------------
	; De baudrate instellen op 19200@7.3728MHz  met een afwijking van 0.0%
	ldi		temp, 23
	rcall	UART_Initialize

	;--- De ADC instellen -------------------------------------------------------------------------------
	rcall	ADC_Initialize

	;--- De externe interrupt IRQ0 instellen ------------------------------------------------------------
	; externe interrupt IRQ0 inschakelen in Global Interrupt Mask Register
	in		temp, GIMSK
	ori		temp, (1<<INT0)
	out		GIMSK, temp
	; externe interrupt IRQ0 activeren op vallende flank (trigger als de knop INgedrukt wordt)
	in		temp, MCUCR
	ori		temp, (1<<ISC01)
	out		MCUCR, temp
	;----------------------------------------------------------------------------------------------------

	; De interrupts voor Overflow ($$ & Compare-Match) inschakelen
;$$	ldi		temp, (1<<OCIE1A | 1<<OCIE1B | 1<<TOIE1 | 1<<OCIE2 | 1<<TOIE2)
;##	ldi		temp, (1<<TOIE1 | 1<<OCIE2 | 1<<TOIE2)
;	ldi		temp, (1<<OCIE2 | 1<<TOIE2) ; swpwm
	ldi		temp, (0<<OCIE2 | 1<<TOIE2) ; hwpwm
	out		TIMSK, temp

	; De duty-cycle instellen
	out		OCR2, LED2_Brightness
	;
	clr		temp
	out		OCR1AH, temp
	out		OCR1AL, LED1A_Brightness
	;
	clr		temp
	out		OCR1BH, temp
	out		OCR1BL, LED1B_Brightness

	; Timer2-counter op de TOP instellen,
	; zodat direct een puls gestart wordt.
	clr		temp
	out		TCNT2, temp
	;
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp;LED1A_Brightness

	; Timer2 instellen en starten; Timer2Clock op CK/256 instellen.
	; Bij Software PWM:
	; Hardware PWM-mode uitschakelen:   PWM2 => 0=uit, 1=8bits
;	ldi		temp, (0<<PWM2 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	; Bij Hardware PWM:
	ldi		temp, (1<<PWM2 | 1<<COM21 | 0<<COM20 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	out		TCCR2, temp
	;
	; De Timer1 in hardware-PWM mode schakelen, anders kunnen we
	; geen 2 PWM pulzen genereren.
	; HW Non-Inverted PWM selecteren voor beide counters, 1A & 1B.
	ldi		temp, (1<<COM1A1 | 0<<COM1A0 | 1<<COM1B1 | 0<<COM1B0 | 0<<PWM11 | 1<<PWM10)
	out		TCCR1A, temp
	; TCK instellen op CK/256
	ldi		temp, (1<<CS12 | 0<<CS11 | 0<<CS10);CK/256
;	ldi		temp, (1<<CS12 | 0<<CS11 | 1<<CS10);CK/1024
	out		TCCR1B, temp

	; interrupts inschakelen
	sei
eLoop:
	rjmp eLoop






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
;**Timer1_Overflow:
;**	; Als de timer-counter de TOP bereikt heeft,
;**	; wordt een Overflow-interrupt gegenereerd.
;**	;
;**	; De uitgang van het PWM-signaal hoog maken
;**	; bij de start van een nieuwe puls.
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
;**	reti






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
	push	tREG
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
	brne	verder; doneHere
	ldi		vDelay, vertraging
	; de waarde op poort C (LED's) rotaten/shiften
	in		tREG, PORTC
	rol		tREG
	out		PORTC, tREG
	; En de geconverteerde ADC-waarde over RS232 verzenden naar de PC (Low/High)
	mov		temp, AD_ValueL
	rcall	UART_transmit
	mov		temp, AD_ValueH
	rcall	UART_transmit

verder:
	;
;##	tst		LED_OnOff					; staat de dimmer aan??
;##	breq	doneHere
;##	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
;##	rcall	LED2Fader
;##doneHere:
	;
	pop		tREG
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
;--- De INT0 Interrupt-Handler
;------------------------------------------
IRQ0_Interrupt:
	push	tREG
	;--- Als de schakelaar wordt ingedrukt, wordt INT0 gegenereerd.
	; toggle de dimmer aan/uit status
	com		LED_OnOff
	; zet 1 bit aan op poort C
	ldi		tREG, 0bx00000001
	out		PORTC, tREG					; 1 LED aan bij 8-bits PWM
	;
	pop		tREG
	reti



;------------------------------------------
;--- De UART-Rx Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	push	temp
	push	tempL

	in		temp, UDR
	push	temp
	; de gelezen byte ook naar poort C  (LED's)
;!!	out		PORTC, temp

;%%	; de waarde ook echo'en naar de COM-out van de AVR
;%%	ldi		temp, 'h'
;%%	rcall	UART_transmit
;%%	ldi		temp, 'i'
;%%	rcall	UART_transmit
;%%	ldi		temp, 13
;%%	rcall	UART_transmit

	pop		temp
is1A:
	cpi		temp, $1A
	brne	is1B
	mov		lastRead, temp
	rjmp	doneRx

is1B:
	cpi		temp, $1B
	brne	is2
	mov		lastRead, temp
	rjmp	doneRx

is2:
	cpi		temp, $2
	brne	isData
	mov		lastRead, temp
	rjmp	doneRx

isData:
	mov		lastRead2, temp
;set1A:
	cpi		lastRead, $1A
	brne	set1B
	; Timer1-CompareA waarde instellen (PWM puls breedte)
	clr		temp
	mov		tempL, lastRead2
	out		OCR1AH, temp
	out		OCR1AL, tempL
	rjmp	doneRx

set1B:
	cpi		lastRead, $1B
	brne	set2
	; Timer1-CompareB waarde instellen (PWM puls breedte)
	clr		temp
	mov		tempL, lastRead2
	out		OCR1BH, temp
	out		OCR1BL, tempL
	rjmp	doneRx

set2:
	cpi		lastRead, $2
	brne	doneRx
	out		OCR2, lastRead2
;	nop
;	rjmp	doneRx

doneRx:
	pop		tempL
	pop		temp
	reti



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet tevoren
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	out		UBRR, temp
	;Schakel de receiver, transmitter & TXCint in
	ldi		temp, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE)
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
	sbis	USR, UDRE
	rjmp	UART_transmit
	out		UDR, temp
	ret









;------------------------------------------
;--- ADC: Initialiseer de ADC. (subroutine)
;------------------------------------------
ADC_Initialize:
	; Poort A pin 0 als input instellen
	ldi		temp, (0<<PINA0)
	out		DDRA, temp

	; Selecteer ADC kanaal 0 op de multiplexer
	ldi		temp, 0
	out		ADMUX, temp

	; ADC Enable
	; ADC Free Running Mode selecteren
	; ADC Interrupt Enable na Conversion-Complete
	; ADC prescale instellen: 7.73728 MHz / 128 = 57600 Hz
	ldi		temp, (1<<ADEN | 1<<ADFR | 1<<ADIE | 1<<ADPS2 | 1<<ADPS1 | 1<<ADPS0)
	out		ADCSR, temp

	ret



;------------------------------------------
;--- ADC: Conversion Complete (interrupt)
;------------------------------------------
ADC_CC_Interrupt:
	push	temp
	push	tempL

	in		tempL, ADCL
	in		temp, ADCH
	;De geconverteerde waarden bewaren
	mov		AD_ValueL, tempL
	mov		AD_ValueH, temp

	pop		tempL
	pop		temp
	reti



