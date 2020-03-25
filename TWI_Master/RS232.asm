;-----------------------------------------------
;--- De RS232 invoer-buffer in SRAM.
;----------------------------------------------\
.equ RS232_BufferSize = 16						; Buffer van 0x0060-0x0070 in SRAM (!!niet voorbij 256-byte boundry!!)
.DSEG                             				; het data-segment aanspreken
RS232_IN_Buffer:		.BYTE RS232_BufferSize	; alloceer de RS232 data-buffer
RS232_IN_Buffer_Input:	.BYTE 2					; het adres voor de nieuw toe te voegen byte
RS232_IN_Buffer_Output:	.BYTE 2					; het adres voor de uit de buffer te lezen byte
RS232_IN_BytesInBuffer:	.BYTE 1					; Het aantal bytes in de buffer
;----------------------------------------------/
.CSEG




.equ EOS_Character	= '$'


;!! spreek de routines voor alle mogelijke SRAM adressen aan
StoreByteSRAMInto_RS232_IN_Buffer:
	StoreByteSRAMIntoBuffer temp, RS232_IN_Buffer, RS232_IN_Buffer_Input, RS232_IN_BytesInBuffer, RS232_BufferSize
	ret

LoadByteSRAMFrom_RS232_IN_Buffer:
	LoadByteSRAMFromBuffer temp, RS232_IN_Buffer, RS232_IN_Buffer_Output, RS232_IN_BytesInBuffer, RS232_BufferSize
	ret


;------------------------------------------
;--- Subroutine: Initialiseer Rx-Data-Buffer
;-----------------------------------------\
UART_Initialize_Buffer:
	; variabelen instellen voor het aantal bytes in de buffer.
	StoreIByteSRAM RS232_IN_BytesInBuffer, 0
	; De buffer pointers instellen op het begin van de buffer.
	; voor (buffer) inkomende bytes....
	StoreIWordSRAM RS232_IN_Buffer_Input, RS232_IN_Buffer
	; voor (buffer) uitgaande bytes....
	StoreIWordSRAM RS232_IN_Buffer_Output, RS232_IN_Buffer
	ret
;-----------------------------------------/



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;-----------------------------------------\
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
;-----------------------------------------/



;------------------------------------------
;--- UART: Verzend een byte. (subroutine)
;---
;--- De te verzenden byte tevoren in
;--- register 'temp' laden.
;-----------------------------------------\
UART_transmit:
	LED_Aan LED_RS232					; "RS232 Activity" LED aan

UART_Not_Ready:
	; Klaar om te verzenden ??
	sbis	USR, UDRE
	rjmp	UART_Not_Ready
	out		UDR, temp

	LED_Uit LED_RS232					; "RS232 Activity" LED aan
	ret
;-----------------------------------------/



;------------------------------------------
;--- De UART-Rx Interrupt-Handler
;-----------------------------------------\
UART_Rx_Interrupt:
	push	R21
	in		R21, SREG
	push	R21
	push	temp

	LED_Aan LED_RS232					; "RS232 Activity" LED aan

	; Lees de ontvangen byte van het UART Data Register,
	in		temp, UDR
	; plaats de byte in de roterende data-buffer
	rcall	StoreByteSRAMInto_RS232_IN_Buffer

doneRx:
	LED_Uit LED_RS232					; "RS232 Activity" LED aan

	pop		temp
	pop		R21
	out		SREG, R21
	pop		R21
	reti
;-----------------------------------------/




;%%;------------------------------------------
;%%;--- De UART-Tx-Complete Interrupt-Handler
;%%;------------------------------------------
;%%UART_Tx_Interrupt:
;%%doneTx:
;%%	reti




;------------------------------------------
;--- De initString naar de PC sturen
;-----------------------------------------\
UART_transmit_InitString:
	ldi		ZL, low(2*InitString)
	ldi		ZH, high(2*InitString)
loop:
	lpm
	adiw	ZL,1
	mov		temp, R0
	cpi		temp, EOS_Character
	breq	endloop
	rcall	UART_transmit
	rjmp	loop
endloop:
	ret
;------------------------------------------
InitString: ; de tekst in program-memory (daarom de lpm instructie)
	.db 13,10, "AVR 'I2C-Master' RS232 -> RS232 PC", 13,10, EOS_Character,0 ; aligned
;-----------------------------------------/



;------------------------------------------
;--- Subroutine: Record in Rx-Data-Buffer??
;-----------------------------------------\
UART_ProcessRecordIn:
	; Is de invoer-buffer gevuld met te lezen data?
	IsBufferEmpty RS232_IN_BytesInBuffer
	brcc	Done_ProcessRecordIn

	; Als er genoeg bytes in de buffer staan om een record te vullen dan verwerken die bytes
	LoadByteSRAM temp, RS232_IN_BytesInBuffer
	cpi		temp, 1
	brsh	RecordInBuffer
	rjmp	Done_ProcessRecordIn

RecordInBuffer:
	; lees de byte uit de buffer
	rcall	LoadByteSRAMFrom_RS232_IN_Buffer
	brcs	Done_ProcessRecordIn		; buffer lezen was mislukt als de carry-flag gezet is

	; De byte gelezen van de RS232-poort nu schrijven naar de I2C-slave
	rcall	StoreByteSRAMInto_TWI_OUT_Buffer

Done_ProcessRecordIn:
	ret
;-----------------------------------------/
