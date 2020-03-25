;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
;--------------------------------------/




;--- CONSTANTEN -----------------------\
.equ CK = 7372800						; AVR clock frequentie (VERPLICHT hier te definieren)
;--------------------------------------/


;--- Compiler Directives --------------\  Geef aan welke units men wil gebruiken:
.equ Link_AVR_16			= 0			; "AVR_16.asm"
.equ Link_AVR_Delay			= 0			; "AVR_Delay.asm"
.equ Link_AVR_Buffer		= 0			; "AVR_Buffer.asm"
.equ Link_8535_EEPROM		= 0			; "8535_EEPROM.asm"
.equ Link_8535_AC			= 0			; "8535_AC.asm"
.equ Link_8535_ADC			= 0			; "8535_ADC.asm"
.equ Link_8535_Timer0		= 0			; "8535_Timer0.asm"
.equ Link_8535_Timer1		= 0			; "8535_Timer1.asm"
.equ Link_8535_Timer2		= 0			; "8535_Timer2.asm"
.equ Link_8535_Timers		= 0			; "8535_Timers.asm"
.equ Link_8535_UART			= 0			; "8535_UART.asm"
.equ Link_LCD_HD44780		= 0			; "LCD_HD44780.asm"
.equ Link_AVR_String		= 0			; "AVR_String.asm"
;---------------------------------------
;included "LinkedUnits.asm" regelt de rest..:-)
;--------------------------------------/





;--- "AVR_Buffer.asm" buffer in SRAM --\
.if Link_AVR_Buffer == 1				; unit "AVR_Buffer.asm" test
.equ TheBufferSize = 32					; De grootte van de buffer (in bytes) CONSTANTE
.DSEG									; Data Segment (SRAM) addresseren
	BufferSize:		.BYTE 1				; de grootte van de buffer
	BufferCount: 	.BYTE 1				; Het aantal bytes in de buffer
	BufferPtrR:		.BYTE 2				; De pointer bij lezen uit de buffer (H:L)
	BufferPtrW:		.BYTE 2				; De pointer bij schrijven in de buffer (H:L)
	Buffer: 		.BYTE TheBufferSize	; de buffer vanaf adres "Buffer", met een grootte van "BufferSize" bytes
.CSEG									; Code Segment (FLASH/PM) addresseren

.equ TheStackSize = 16
.DSEG									; Data Segment (SRAM) addresseren
	StackPtr:		.BYTE 2				; De pointer bij lezen/schrijven in de buffer (H:L)
	Stack:	 		.BYTE TheStackSize	; de buffer vanaf adres "Stack", met een grootte van "TheStackSize" bytes
.CSEG									; Code Segment (FLASH/PM) addresseren
.endif
;--------------------------------------/





;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
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
	rjmp RESET		;	.org $000		; Reset Handler
	reti			;	.org INT0addr	; External Interrupt0 Vector Address
	reti			;	.org INT1addr	; External Interrupt1 Vector Address
	reti			;	.org OC2addr	; Timer2 compare match Vector Address
	reti			;	.org OVF2addr	; Timer2 overflow Vector Address
	reti			;	.org ICP1addr	; Timer1 Input Capture Vector Address
	reti			;	.org OC1Aaddr	; Timer1 Output Compare A Interrupt Vector Address
	reti			;	.org OC1Baddr	; Timer1 Output Compare B Interrupt Vector Address
	reti			;	.org OVF1addr	; Overflow1 Interrupt Vector Address
	reti			;	.org OVF0addr	; Overflow0 Interrupt Vector Address
	reti			;	.org SPIaddr	; SPI Interrupt Vector Address
	reti			;	.org URXCaddr	; UART Receive Complete Interrupt Vector Address
	reti			;	.org UDREaddr	; UART Data Register Empty Interrupt Vector Address
	reti			;	.org UTXCaddr	; UART Transmit Complete Interrupt Vector Address
	reti			;	.org ADCCaddr	; ADC Conversion Complete Interrupt Vector Address
	reti			;	.org ERDYaddr	; EEPROM Write Complete Interrupt Vector Address
	reti			;	.org ACIaddr	; Analog Comparator Interrupt Vector Address
;--------------------------------------/


;--- Ron's Macro's & Subroutines ------\
.include "LinkedUnits.asm"				; interne compiler-directives verwerking en unit-linking
;--------------------------------------/




RESET:
	cli
	ldi		R17, high(RAMEND)
	ldi		R16, low(RAMEND)
	out		SPH, R17
	out		SPL, R16
	sei
app_init:

;--------------------------------------\
.ifdef Linked_AVR_Buffer				; unit "AVR_Buffer.asm" test
	Buffer_Initialize Buffer, TheBufferSize		; een ringbuffer FIFO
	LIFO_Initialize Stack						; een stackbuffer LIFO
.endif
;--------------------------------------/


;--------------------------------------\
.ifdef Linked_AVR_String				; unit "AVR_String.asm" test
	StringOutputTo_COM					; tenminste eenmalig op te geven !!
.endif
;--------------------------------------/


main_loop:

;--------------------------------------\
.ifdef Linked_AVR_Buffer				; unit "AVR_Buffer.asm" test
	;--- FIFO
	; schrijven naar de buffer (variant 1)
	ldi		R16, $11
	Buffer_Write Buffer, R16
	ldi		R16, $22
	Buffer_Write Buffer, R16
	ldi		R16, $AA
	Buffer_Write Buffer, R16
	ldi		R16, $55
	Buffer_Write Buffer, R16
	; schrijven naar de buffer (variant 2: iets korter/sneller dan variant 1)
	ldi		R16, $33
	Buffer_Write2 Buffer, R16, TheBufferSize
	ldi		R16, $77
	Buffer_Write2 Buffer, R16, TheBufferSize
	ldi		R16, $CC
	Buffer_Write2 Buffer, R16, TheBufferSize
	ldi		R16, $EE
	Buffer_Write2 Buffer, R16, TheBufferSize
	; lezen uit de buffer (variant 1)
	Buffer_Read R16, Buffer
	Buffer_Read R16, Buffer
	Buffer_Read R16, Buffer
	Buffer_Read R16, Buffer
	; lezen uit de buffer (variant 2)
	Buffer_Read2 R16, Buffer, TheBufferSize
	Buffer_Read2 R16, Buffer, TheBufferSize
	Buffer_Read2 R16, Buffer, TheBufferSize
	Buffer_Read2 R16, Buffer, TheBufferSize

	;--- LIFO
	; schrijven naar de buffer
	ldi		R16, $44
	LIFO_Push Stack, R16, TheStackSize
	ldi		R16, $88
	LIFO_Push Stack, R16, TheStackSize
	ldi		R16, $BB
	LIFO_Push Stack, R16, TheStackSize
	; lezen uit de buffer
	LIFO_Pop R16, Stack
	LIFO_Pop R16, Stack
	LIFO_Pop R16, Stack
	LIFO_Pop R16, Stack
	;brcs	fout
.endif
;--------------------------------------/


;--------------------------------------\
.ifdef Linked_AVR_Delay					; unit "AVR_Delay.asm" test
	Delay_US 100						; 100 micro-seconden vertraging
	Delay_MS 4							; 4 milli-seconden
	Delay_S 1							; 1 seconde
.endif
;--------------------------------------/


;--------------------------------------\
.ifdef Linked_AVR_String				; unit "AVR_String.asm" test
	StringOutputTo_COM_LCD				; ik wil vanaf nu naar COM & LCD afbeelden..
										; Als echter de unit "8535_UART.asm" niet is ingelinkt, wordt niet naar COM: afgebeeld..	
	ldi		ZL, low(16384)				; Als unit "LCD_HD44780.asm" niet is ingelinkt, wordt niet naar LCD afgebeeld..
	ldi		ZH, high(16384)
	rcall	Hex
	
	StringOutputOnlyTo_COM				; vanaf nu alleen op de COM: poort afbeelden

	ldi		ZL, low($4000)
	ldi		ZH, high($4000)
	rcall	Decimal
.endif
;--------------------------------------/


	rjmp	main_loop
