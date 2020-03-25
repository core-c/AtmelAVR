
;*************************************************************************************
;***
;***  Een AT-Keyboard implementatie.
;***
;***  De keyboard-clock wordt aangesloten op de INT1-pin van de AVR.
;***  De keyboard-data wordt aangesloten op een willekeurige pin, in dit geval PB1.
;***
;***
;***    keyboard 5-pin DIN connector:	pin #1 (Clock)	->	AVR-INT1 (PD3, pin #17)
;***    								pin #2 (Data)	->	AVR-PB1 (pin #2)
;***    	   2*						pin #3 (Not Connected)
;***    	 4*   *5					pin #4 (GND)	->	AVR-GND
;***    	 1*	_ *3					pin #5 (VCC)	->	AVR-VCC
;***
;***    keyboard 6-pin MiniDIN (PS/2):	pin #1 (Data)	->	AVR-PB1 (pin #2)
;***									pin #2 (Not Connected)
;***		  6*|*5						pin #3 (GND)	->	AVR-GND
;***		 4*   *3					pin #4 (VCC)	->	AVR-VCC
;***		 2* _ *1					pin #5 (Clock)	->	AVR-INT1 (PD3, pin #17)
;***									pin #6 (Not Connected)
;***
;***  De gezonden keyboard-data is serieel:
;***    1 startbit (altijd 0), 
;***    8 data-bits[0..7] (scancode),
;***    1 parity-bit,
;***    1 stopbit (altijd 1).
;***
;***  De AT-toetsenbord scancode(s) voor het loslaten van een toets is de normale
;***  scancode(s) voorafgegaand door $F0. Een ESC indrukken: scancode = $EC
;***                                      Een ESC loslaten: scancodes = $F0 $EC
;***  Enkele SCANCODES die niet kloppen!!!!!!!!!!:
;***	A: $1C		H: $33		O: $44		V: $2A
;***	B: $32		I: $43		P: $4D		W: $1D
;***	C: $21		J: $3B		Q: $15		X: $22
;***	D: $23		K: $42		R: $2D		Y: $35
;***	E: $24		L: $4B		S: $1B		Z: $1A
;***	F: $2B		M: $3A		T: $2C
;***	G: $34		N: $31		U: $3C
;***
;***	0: $45		1: $16		2: $1E		3: $26
;***	4: $25		5: $2E		6: $36		7: $3D
;***	8: $3E		9: $46
;***
;***	F1: $05		F2: $06		F3: $04		F4: $0C
;***	F5: $03		F6: $0B		F7: $83		F8: $0A
;***	F9: $01		F10: $09	F11: $78	F12: $07
;***
;***	L-Shift: $12		L-Ctrl: $14			L-Alt: $11
;***	R-Shift: $59		R-Ctrl: $E0 $14		R-Alt: $E0 $11
;***	Enter: $5A		ESC: $76
;***
;***	Pijl links: $E0 $6B		boven: $E0 $75		onder: $E0 $72		rechts: $E0 $74
;***
;*************************************************************************************

;--- Include files ---------------------
.include "8535def.inc"					; AVR AT90S8535 constanten
.include "IO.inc"						; Instellen I/O-poorten

;--- REGISTER ALIASSEN -----------------
.def CharReg	= R0					; tbv. LPM-instructie
.def temp		= R16					; Een register voor algemeen gebruik
.def temp2		= R17					;  "
.def temp3		= R18					;  "
.def temp4		= R19					;  "
.def delay0		= R20					; Een register alleen tbv delays
.def delay1		= R21					;  "
.def delay2		= R22					;  "


;--- Het begin van het CODE-segment ----
.CSEG
;--- De AVR-AT90S8535 vector-tabel -----
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	rjmp KB_Interrupt					; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
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
;---------------------------------------

.include "Keyboard.asm"					; toetsenbord routines
.include "LCD.asm"						; LC-Display routines





RESET:
	; interrupts uitschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		temp2, low(RAMEND)
	out		SPH, temp
	out		SPL, temp2

	; Er komt een LED aan pin PD7, dus als output instellen
	sbi		DDRD, PD7						; als output
	; De keyboard data-lijn als input instellen
	cbi		DDRB, PB1
	; poort D2 als input zetten tbv. INT1 Keyboard-input
	cbi		DDRD, PD3
	sbi		PORTD, PD3; met de interne pull-up actief

	; LCD-Display initialiseren
	rcall	LCD_Initialise
	; Scherm aan, cursor aan, knipperen uit
	ldi		temp, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode
	; Het toetsenbord initialiseren
	rcall	KB_Initialize

	; interrupts inschakelen
	sei
	; LED aan
	sbi		PORTD, PD7
eLoop:
	; verwerkt toetsen-aanslagen in de toetsen-buffer
	rcall	KB_Process
	; blijft 'ie nou hangen.?....
	rjmp eLoop





;---------------------------------------
;--- verwerkt de toetsen-aanslagen
;--- in de toetsen-buffer.
;---------------------------------------
KB_Process:
	; als de buffer leeg is, wordt de carry-flag gewist, anders gezet..
	IsBufferEmpty KeysInBuffer
	brcc	DoneProcess
	;LoadByteSRAMFromBuffer(aRegister, aAddressBuffer, aAddressOutput, aAddressBytesInBuffer, aBufferSize)	
	LoadByteSRAMFromBuffer temp, KeyBuffer, KeyOutput, KeysInBuffer, KeyBufferSize
	brcs	DoneProcess						; buffer lezen was mislukt
	; print de waarde in temp
	rcall	LCD_Data
; of..
;	rcall	LCD_LinePrintChar				; met behoud van logische regel-volgorde
DoneProcess:
	ret




