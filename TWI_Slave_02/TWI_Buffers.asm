
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
TWI_IN_Buffer_Count:	.BYTE 1					; Het aantal bytes in de buffer
TWI_OUT_Buffer:			.BYTE TWI_BufferSize	; De TWI-uitvoer buffer
TWI_OUT_Buffer_Input:	.BYTE 2					;
TWI_OUT_Buffer_Output:	.BYTE 2					;
TWI_OUT_Buffer_Count:	.BYTE 1					;
;----------------------------------------------/
.CSEG




;---------------------------------------
;--- TWI_Buffers_Initialize
;--------------------------------------\
TWI_Clear_In_Buffer:
	StoreIByteSRAM TWI_IN_Buffer_Count, 0
	StoreIWordSRAM TWI_IN_Buffer_Input, TWI_IN_Buffer
	StoreIWordSRAM TWI_IN_Buffer_Output, TWI_IN_Buffer
	ret
TWI_Clear_Out_Buffer:
	StoreIByteSRAM TWI_OUT_Buffer_Count, 0
	StoreIWordSRAM TWI_OUT_Buffer_Input, TWI_OUT_Buffer
	StoreIWordSRAM TWI_OUT_Buffer_Output, TWI_OUT_Buffer
	ret
TWI_Initialize_Buffers:
	; De invoer-buffer
	rcall	TWI_Clear_In_Buffer
	; De uitvoer-buffer
	rcall	TWI_Clear_Out_Buffer
	ret
;--------------------------------------/


;---------------------------------------
;--- TWI_Buffer handling routines
;--- (!spreek de routines voor lage SRAM-adressen aan! suffix 8)
;--------------------------------------\
LoadByteFrom_TWI_IN_Buffer:
	LoadByteSRAMFromBuffer8 R16, TWI_IN_Buffer, TWI_IN_Buffer_Output, TWI_IN_Buffer_Count, TWI_BufferSize
	ret

StoreByteInto_TWI_IN_Buffer:
	StoreByteSRAMIntoBuffer8 R16, TWI_IN_Buffer, TWI_IN_Buffer_Input, TWI_IN_Buffer_Count, TWI_BufferSize
	ret

LoadByteFrom_TWI_OUT_Buffer:
	LoadByteSRAMFromBuffer8 R16, TWI_OUT_Buffer, TWI_OUT_Buffer_Output, TWI_OUT_Buffer_Count, TWI_BufferSize
	ret

StoreByteInto_TWI_OUT_Buffer:
	StoreByteSRAMIntoBuffer8 R16, TWI_OUT_Buffer, TWI_OUT_Buffer_Input, TWI_OUT_Buffer_Count, TWI_BufferSize
	ret

PeekByteFrom_TWI_IN_Buffer:
	PeekByteSRAMFromBuffer R16, TWI_IN_Buffer_Output, TWI_IN_Buffer_Count
	ret

Get_TWI_IN_Buffer_Count:
	lds		R16, TWI_IN_Buffer_Count
	ret
;--------------------------------------/


;---------------------------------------
;--- TWI_ProcessMessages
;--------------------------------------\
TWI_ProcessMessages:
Check_Input:
	;
	;rjmp	Check_Input					; meer bytes ontvangen?
Done_Input:


Check_Output:
	;
	;rjmp	Check_Output				; meer bytes te schrijven?
Done_Output:
	ret
;--------------------------------------/
