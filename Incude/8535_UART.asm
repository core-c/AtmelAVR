;---------------------------------------------------------------------------------
;---
;---  UART constanten en macro's						Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_UART
	.ifndef Link_8535_UART						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_UART = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_UART = 1					;
.endif






;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Set_UART_Baudrate
;--- Beschrijving:	De UART baudrate instellen
;---				invoer: constante "CK" bevat de AVR clockfrequentie in Hz.
;---				        constante "BPS" bevat de gewenste baudrate
;--------------------------------------------
.MACRO Set_UART_Baudrate;(CK,BPS: constante)
	; BAUD = CK / 16(UBBR+1)  <=>  UBBR = CK/BAUD /16-1
	.if (@0/@1)/16-1 < 0
		.error "ERROR: UART baudrate too high (UBRR<0)"
	.endif
	.if (@0/@1)/16-1 > 255
		.error "ERROR: UART baudrate too low (UBRR>255)"
	.endif
	.message "UART baudrate set"
	ldi		R16, (@0/@1)/16-1
	out		UBRR, R16
.ENDMACRO





;---------------------------------------------------------------------------------
;--- UCR	- UART Control Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  RXCIE |  TXCIE |  UDRIE |  RXEN  |  TXEN  |  CHR9  |  RXB8  |  TXB8  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		RXCIE				RX Complete Interrupt Enable
;---	Bit 6		TXCIE				TX Complete Interrupt Enable
;---	Bit 5		UDRIE				UART Data Register Empty Interrupt Enable
;---	Bit 4		RXEN				Receiver Enable
;---	Bit 3		TXEN				Transmitter Enable
;---	Bit 2		CHR9				9 Bit Characters
;---	Bit 1		RXB8				Receive Data Bit 8
;---	Bit 0		TXB8				Transmit Data Bit 8
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- UART Interrupt Enable
;--------------------------------------------
.equ UART_INTERRUPTENABLE_RXCOMPLETE		= (1<<RXCIE)
.equ UART_INTERRUPTENABLE_TXCOMPLETE		= (1<<TXCIE)
.equ UART_INTERRUPTENABLE_DATAREGISTEREMPTY	= (1<<UDRIE)


;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupt_RxComplete
;--- Beschrijving:	Interrupt uitschakelen voor UART ontvangst klaar
;--------------------------------------------
.MACRO Disable_Interrupt_RxComplete
	cbi		UCR, RXCIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_TxComplete
;--- Beschrijving:	Interrupt uitschakelen voor UART zenden klaar
;--------------------------------------------
.MACRO Disable_Interrupt_TxComplete
	cbi		UCR, TXCIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_DataRegisterEmpty
;--- Beschrijving:	Interrupt uitschakelen voor UART Data-Register-leeg
;--------------------------------------------
.MACRO Disable_Interrupt_DataRegisterEmpty
	cbi		UCR, UDRIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_RxComplete
;--- Beschrijving:	Interrupt inschakelen voor UART ontvangst klaar
;--------------------------------------------
.MACRO Enable_Interrupt_RxComplete
	sbi		UCR, RXCIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_TxComplete
;--- Beschrijving:	Interrupt inschakelen voor UART zenden klaar
;--------------------------------------------
.MACRO Enable_Interrupt_TxComplete
	sbi		UCR, TXCIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_DataRegisterEmpty
;--- Beschrijving:	Interrupt inschakelen voor UART Data-Register-leeg
;--------------------------------------------
.MACRO Enable_Interrupt_DataRegisterEmpty
	sbi		UCR, UDRIE
.ENDMACRO



;--------------------------------------------
;--- Naam:			Disable_UART_Receiver
;--- Beschrijving:	De UART-ontvanger uitschakelen
;--------------------------------------------
.MACRO Disable_UART_Receiver
	cbi		UCR, RXEN
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_UART_Receiver
;--- Beschrijving:	De UART-ontvanger inschakelen
;--------------------------------------------
.MACRO Enable_UART_Receiver
	sbi		UCR, RXEN
.ENDMACRO



;--------------------------------------------
;--- Naam:			Disable_UART_Transmitter
;--- Beschrijving:	De UART-zender uitschakelen
;--------------------------------------------
.MACRO Disable_UART_Transmitter
	cbi		UCR, TXEN
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_UART_Transmitter
;--- Beschrijving:	De UART-zender inschakelen
;--------------------------------------------
.MACRO Enable_UART_Transmitter
	sbi		UCR, TXEN
.ENDMACRO





;---------------------------------------------------------------------------------
;--- USR	- UART Status Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|   RXC  |   TXC  |  UDRE  |   FE   |   OR   |        |        |        |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		RXC					UART Receive Complete
;---	Bit 6		TXC					UART Transmit Complete
;---	Bit 5		UDRE				UART Data Register Empty
;---	Bit 4		FE					Framing Error
;---	Bit 3		OR					OverRun
;---	Bit 2..0						Reserved Bits
;---
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			UART_TransmitByte
;--- Beschrijving:	Een byte verzenden over de COM: poort
;---				invoer: register "Value" bevat de te schrijven byte-waarde
;--------------------------------------------
.MACRO UART_TransmitByte;(Value: register)
_0:	sbis	USR, UDRE
	rjmp	_0
	out		UDR, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			UART_TransmitCrLf
;--- Beschrijving:	Een CrLf verzenden over de COM: poort
;--------------------------------------------
.MACRO UART_TransmitCrLf
	ldi		R16, 13
	UART_TransmitByte R16
	ldi		R16, 10
	UART_TransmitByte R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			UART_TransmitSpace
;--- Beschrijving:	Een spatie verzenden over de COM: poort
;--------------------------------------------
.MACRO UART_TransmitSpace
	ldi		R16, ' '
	UART_TransmitByte R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			UART_TransmitTAB
;--- Beschrijving:	Een TAB verzenden over de COM: poort
;--------------------------------------------
.MACRO UART_TransmitTAB
	ldi		R16, 9
	UART_TransmitByte R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			UART_TransmitBS
;--- Beschrijving:	Een BackSpace verzenden over de COM: poort
;--------------------------------------------
.MACRO UART_TransmitBS
	ldi		R16, 8
	UART_TransmitByte R16
.ENDMACRO


;--------------------------------------------
;--- Naam:			UART_ReceiveByte
;--- Beschrijving:	Een byte ontvangen van de COM: poort
;---				uitvoer: register "Value" bevat de gelezen byte
;---				         de carry-flag is gezet als er zich een fout heeft voorgedaan
;--------------------------------------------
.MACRO UART_ReceiveByte;(Value: register)
	; controleren op een frame error
	sbic	USR, FE
	rjmp	_0								; stoppen bij een frame error
	; Lees de ontvangen byte van het UART Data Register,
	in		@0, UDR
	; controleren op een overrun error
	clc
	sbic	USR, OR
_0:	sec										; byte is ongeldig
.ENDMACRO





;---------------------------------------------------------------------------------
;--- Subroutine's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			UART_Transmit
;--- Beschrijving:	Een byte verzenden over de COM: poort
;---				invoer: register R16 bevat de te schrijven byte-waarde
;--------------------------------------------
UART_Transmit:
	UART_TransmitByte R16
	ret
