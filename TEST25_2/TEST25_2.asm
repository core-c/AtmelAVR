;*************************************************************************************
;***
;***  Een AT-Keyboard implementatie.
;***
;*************************************************************************************

;--- Include files ---------------------
.include "8535def.inc"					; AVR AT90S8535 constanten
.include "System.inc"						; constanten tbv instellen I/O-poorten

;--- REGISTER ALIASSEN ----------------\
.def CharReg	= R0					; tbv. LPM-instructie
.def temp		= R16					; Een register voor algemeen gebruik
.def temp2		= R17					;  "
.def temp3		= R18					;  "
.def temp4		= R19					;  "
.def delay0		= R20					; Een register alleen tbv delays
.def delay1		= R21					;  "
.def delay2		= R22					;  "
;--- LCD.asm
;.def CharReg	= R0					; tbv. LPM-instructie
;.def temp		= R16					; Een register voor algemeen gebruik
;.def temp2		= R17					;  "
;.def temp3		= R18					;  "
;.def temp4		= R19					;  "
;.def delay0	= R20					; Een register alleen tbv delays
;.def delay1	= R21					;  "
;.def delay2	= R22					;  "
;--- RotatingBuffer.asm
;.def mRegL		= R24					; Macro Register Low
;.def mRegH		= R25					; Macro Register High
;.def ZL		= R30					; gedefinieerd in 8535def.inc
;.def ZH		= R31					; gedefinieerd in 8535def.inc
;--------------------------------------/



.CSEG									;--- Het begin van het CODE-segment ----
;--- De AVR-AT90S8535 vector-tabel ----\
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
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
;--------------------------------------/

.include "Keyboard.asm"					; toetsenbord routines
.include "LCD.asm"						; LC-Display routines





RESET:
	; interrupts uitschakelen
	cli
	initStackPointer						; stackpointer op einde RAM instellen

	; Er komt een LED aan pin PD7, dus als output instellen
	sbi		DDRD, PD7					; als output


	; LCD-Display initialiseren
	rcall	LCD_Initialize
	; Scherm aan, cursor aan, knipperen uit
	ldi		temp, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_ON)
	rcall	LCD_DisplayMode

	; Het toetsenbord initialiseren
	rcall	KB_Initialize


	; interrupts inschakelen
	sei
	; LED continue aan
	sbi		PORTD, PD7
MainLoop:
	;-----------------------------------------------------------
	; Verwerk de scancodes in de scancode-buffer naar ASCII-codes
	; en plaats de ASCII-codes in een aparte ASCII-code buffer.
	; Met deze methode wordt de KB_Interrupt_Handler zo min
	; mogelijk belast omdat alle data buiten de handler wordt
	; verwerkt en de handler zelf zsm. afgehandeld wordt.
	rcall	KB_ProcessMessages
	;-----------------------------------------------------------

	; verwerkt toetsen-aanslagen in de toetsen ASCII-buffer
	rcall	KB_Process
	; blijft 'ie nou hangen.? ;)....
	rjmp MainLoop





;---------------------------------------
;--- verwerkt de toetsen-aanslagen
;--- in de toetsen-buffer.
;---------------------------------------
KB_Process:
	; als de buffer leeg is, wordt de carry-flag gewist, anders gezet..
	IsBufferEmpty ASCIIInBuffer
	brcc	DoneProcess
	;LoadByteSRAMFromBuffer(aRegister, aAddressBuffer, aAddressOutput, aAddressBytesInBuffer, aBufferSize)	
	LoadByteSRAMFromBuffer temp, ASCIIBuffer, ASCIIOutput, ASCIIInBuffer, ASCIIBufferSize
	brcs	DoneProcess						; buffer lezen was mislukt

	rcall	LCD_GetINS						; Is de Insert-mode ingeschakeld?
	brne	InsertChar
;OverwriteChar:
	; het teken in 'temp' afbeelden
	rcall	LCD_LinePrintChar				; met behoud van logische regel-volgorde
	rjmp	DoneProcess
InsertChar:
	rcall	LCD_Insert

DoneProcess:
	ret




