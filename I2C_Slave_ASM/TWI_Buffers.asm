;-----------------------------------------------
;--- SRAM.
;--- De TWI invoer- & uitvoer-buffers.
;----------------------------------------------\
.equ TWI_BufferSize	= 16           				; de gewenste grootte van de buffer(s) (in bytes)
.DSEG                             				; het data-segment aanspreken
.org 0x0060										; De 1e byte van de buffer op begin van SRAM plaatsen (tbv. de suffix 8 subs)
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
;--- TWI_Buffer handling routines
;--- (!spreek de routines voor lage SRAM-adressen aan! suffix 8)
;--------------------------------------\
LoadByteSRAMFrom_TWI_IN_Buffer:
	;LoadByteSRAMFromBuffer temp, TWI_IN_Buffer, TWI_IN_Buffer_Output, TWI_IN_BytesInBuffer, TWI_BufferSize
	LoadByteSRAMFromBuffer8 temp, TWI_IN_Buffer, TWI_IN_Buffer_Output, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

LoadByteSRAMFrom_TWI_OUT_Buffer:
	;LoadByteSRAMFromBuffer temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Output, TWI_OUT_BytesInBuffer, TWI_BufferSize
	LoadByteSRAMFromBuffer8 temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Output, TWI_OUT_BytesInBuffer, TWI_BufferSize
	ret

StoreByteSRAMInto_TWI_IN_Buffer:
	;StoreByteSRAMIntoBuffer temp, TWI_IN_Buffer, TWI_IN_Buffer_Input, TWI_IN_BytesInBuffer, TWI_BufferSize
	StoreByteSRAMIntoBuffer8 temp, TWI_IN_Buffer, TWI_IN_Buffer_Input, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

StoreByteSRAMInto_TWI_OUT_Buffer:
	;StoreByteSRAMIntoBuffer temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Input, TWI_OUT_BytesInBuffer, TWI_BufferSize
	StoreByteSRAMIntoBuffer8 temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Input, TWI_OUT_BytesInBuffer, TWI_BufferSize
	ret
;--------------------------------------/


;---------------------------------------
;--- TWI_ProcessMessages
;--------------------------------------\
TWI_ProcessMessages:
;Check_Output:
;	; Is de uitvoer-buffer gevuld met te verzenden data?
;	IsBufferEmpty TWI_OUT_BytesInBuffer
;	brcc	Done_Output					; Er is geen input als de carry-flag is gewist..
;	
;	; Er is output in de uitvoer-buffer
;	rcall	LoadByteSRAMFrom_TWI_OUT_Buffer
;	brcs	Done_Output					; buffer lezen was mislukt als de carry-flag gezet is
;	; register "temp" bevat de uit de uitvoer-buffer gelezen byte
;
;	; ...
;
;	rjmp	Check_Output				; meer bytes te schrijven?
;Done_Output:

Check_Input:
	; Verwerk de, eventueel in de TWI_IN_Buffer staande, LCD-UserCommands
	rcall	UserCommand_Process			; Unit1.asm
	ret
;--------------------------------------/
