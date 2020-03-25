;---------------------------------------
;--- De TWI invoer- & uitvoer-buffers
;--- in SRAM.
;----------------------------------------------\
.equ TWI_BufferSize	= 16           				; de gewenste grootte van de buffer(s) (in bytes)
.DSEG                             				; het data-segment aanspreken
.org 0x0060										; De 1e byte van de buffer op begin van SRAM plaatsen
TWI_IN_Buffer:			.BYTE TWI_BufferSize	; De TWI-invoer buffer
TWI_IN_Buffer_Input:	.BYTE 2					; pointer naar de nieuw toe te voegen byte
TWI_IN_Buffer_Output:	.BYTE 2					; pointer naar de uit de buffer te lezen byte
TWI_IN_BytesInBuffer:	.BYTE 1					; Het aantal bytes in de buffer
TWI_OUT_Buffer:			.BYTE TWI_BufferSize	; De TWI-uitvoer buffer
TWI_OUT_Buffer_Input:	.BYTE 2					;
TWI_OUT_Buffer_Output:	.BYTE 2					;
TWI_OUT_BytesInBuffer:	.BYTE 1					;
;----------------------------------------------/
.CSEG


;---------------------------------------
;--- De macro's verpakt als sub-routine's
;--------------------------------------\
;!! spreek de routines voor lage SRAM adressen aan (suffix 8) uit RotatingBuffer.asm !!
; De routines speciaal voor SRAM adressen tot $100 zijn korter, en dus sneller.
; Door de TWI Buffers dmv. .org 0x0060 vanaf adres $60 plaatst in SRAM is het mogelijk
; om de snellere routines (met zekerheid) aan te roepen.
StoreByteSRAMInto_TWI_IN_Buffer:
	StoreByteSRAMIntoBuffer8 TWI_Data, TWI_IN_Buffer, TWI_IN_Buffer_Input, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

StoreByteSRAMInto_TWI_OUT_Buffer:
	StoreByteSRAMIntoBuffer8 temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Input, TWI_OUT_BytesInBuffer, TWI_BufferSize
	ret

LoadByteSRAMFrom_TWI_IN_Buffer:
	LoadByteSRAMFromBuffer8 temp, TWI_IN_Buffer, TWI_IN_Buffer_Output, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

LoadByteSRAMFrom_TWI_OUT_Buffer:
	LoadByteSRAMFromBuffer8 temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Output, TWI_OUT_BytesInBuffer, TWI_BufferSize
	ret
;--------------------------------------/


;---------------------------------------
;--- TWI_Buffers_Initialize
;--------------------------------------\
TWI_Initialize_Buffers:
	; De invoer-buffer
	StoreIByteSRAM TWI_IN_BytesInBuffer, 0
	StoreIWordSRAM TWI_IN_Buffer_Input, TWI_IN_Buffer
	StoreIWordSRAM TWI_IN_Buffer_Output, TWI_IN_Buffer
	; De uitvoer-buffer
	StoreIByteSRAM TWI_OUT_BytesInBuffer, 0
	StoreIWordSRAM TWI_OUT_Buffer_Input, TWI_OUT_Buffer
	StoreIWordSRAM TWI_OUT_Buffer_Output, TWI_OUT_Buffer
	ret
;--------------------------------------/



;---------------------------------------
;--- TWI_ProcessMessages
;--------------------------------------\
TWI_ProcessMessages:
Check_Output:
	; Is de uitvoer-buffer gevuld met te verzenden data?
	IsBufferEmpty TWI_OUT_BytesInBuffer
	brcc	Done_Output					; Er is geen input als de carry-flag is gewist..
	
	; Er is output in de uitvoer-buffer
	rcall	LoadByteSRAMFrom_TWI_OUT_Buffer
	brcs	Done_Output					; buffer lezen was mislukt als de carry-flag gezet is
	; register "temp" bevat de uit de uitvoer-buffer gelezen byte

	;willen we van de slave lezen?
	cpi		temp, CharRequestSlaveTx
	brne	SchrijfNaarSlave
	; het speciale teken om data op te vragen van de slave (ala demo style)
	; ipv. een CharRequestSlaveTx sturen nu een lees-actie starten.
LeesVanSlave:
	ldi		TWI_Address, $30			; Het slave-adres instellen
	rcall	TWI_ReadFromSlave			; De byte in register "temp" inlezen
	rjmp	Check_Output				; meer bytes te schrijven?

SchrijfNaarSlave:
	ldi		TWI_Address, $30			; Het slave-adres instellen
	rcall	TWI_WriteToSlave			; De byte in register "temp" verzenden

	rjmp	Check_Output				; meer bytes te schrijven?
Done_Output:

Check_Input:
	; Is de invoer-buffer gevuld met te lezen data?
	IsBufferEmpty TWI_IN_BytesInBuffer
	brcc	Done_Input					; Er is geen input als de carry-flag is gewist..
	
	; Er is input in de invoer-buffer
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	Done_Input					; buffer lezen was mislukt als de carry-flag gezet is
	; register "temp" bevat de uit de invoer-buffer gelezen byte

	; De byte gelezen van de I2C-slave nu schrijven naar de RS232-poort
	rcall	UART_transmit
;	rcall	StoreByteSRAMInto_RS232_OUT_Buffer

	rjmp	Check_Input					; meer bytes te lezen?
Done_Input:
	ret
;--------------------------------------/
