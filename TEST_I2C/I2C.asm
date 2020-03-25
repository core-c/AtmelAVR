;**** A P P L I C A T I O N   N O T E   A V R 3 0 0 ************************
;*
;* Title		: TWI (Single) Master Implementation
;* Version		: 1.0
;* Last updated	: 2002.05.03
;* Target		: AT90Sxxxx (any AVR device)
;*
;* Support email	: avr@atmel.com
;*
;* DESCRIPTION
;* 	Basic routines for communicating with TWI slave devices. This
;*	"single" master implementation is limited to one bus master on the
;*	TWI bus. Most applications do not need the multimaster ability
;*	the TWI bus provides. A single master implementation uses, by far,
;*	less resources and is less XTAL frequency dependent.
;*
;*	Some features :
;*	* All interrupts are free, and can be used for other activities.
;*	* Supports normal and fast mode.
;*	* Supports both 7-bit and 10-bit addressing.
;*	* Supports the entire AVR microcontroller family.
;*
;*	Main TWI functions :
;*	'TWI_start' -		Issues a start condition and sends address
;*				and transfer direction.
;*	'TWI_rep_start' -	Issues a repeated start condition and sends
;*				address and transfer direction.
;*	'TWI_do_transfer' -	Sends or receives data depending on
;*				direction given in address/dir byte.
;*	'TWI_stop' -		Terminates the data transfer by issue a
;*				stop condition.
;*
;* USAGE
;*	Transfer formats is described in the AVR300 documentation.
;*	(An example is shown in the 'main' code).	
;*
;* NOTES
;*	The TWI routines can be called either from non-interrupt or
;*	interrupt routines, not both.
;*
;* STATISTICS
;*	Code Size	: 81 words (maximum)
;*	Register Usage	: 4 High, 0 Low
;*	Interrupt Usage	: None
;*	Other Usage	: Uses two I/O pins on port D
;*	XTAL Range	: N/A
;*
;***************************************************************************


;/*
;;**** Includes ****
;
;.include "1200def.inc"			; change if an other device is used
;
;;**** Global TWI Constants ****
;
;.equ	SCLP	= 1			; SCL Pin number (port D)
;.equ	SDAP	= 0			; SDA Pin number (port D)
;
;.equ	b_dir	= 0			; transfer direction bit in TWIadr
;
;.equ	TWIrd	= 1
;.equ	TWIwr	= 0
;
;;**** Global Register Variables ****
;
;.def	TWIdelay= r16			; Delay loop variable
;.def	TWIdata	= r17			; TWI data transfer register
;.def	TWIadr	= r18			; TWI address and direction register
;.def	TWIstat	= r19			; TWI bus status register
;
;;**** Interrupt Vectors ****
;
;	;rjmp	RESET			; Reset handle
;;	( rjmp	EXT_INT0 )		; ( IRQ0 handle )
;;	( rjmp	TIM0_OVF )		; ( Timer 0 overflow handle )
;;	( rjmp	ANA_COMP )		; ( Analog comparator handle )
;*/



.equ CharRequestSlaveTx	= '?'	; Verzoek om een slave-transmit
.equ CharFindSlaves		= '@'	; Zoek slaves in het adresbereik [8..0b01111000]
.equ CharBusSpeedUp		= '>'	; Bus-snelheid verhogen
.equ CharBusSpeedDown	= '<'	; Bus-snelheid verlagen
.equ CharWriteServo		= '|'	; lees de LCD cursor positie van de slave


;--- I2C Connecties -------------------\
.equ TWI_PORT		= PORTC				; De OUTPUT poort op de AVR
.equ TWI_PIN		= PINC				; De INPUT poort op de AVR
.equ TWI_PORT_DDR	= DDRC				; De richting van de poort op de AVR
.equ TWI_SCL		= PC0				; De Serial CLock lijn
.equ TWI_SDA		= PC1				; De Serial DAta lijn
;--------------------------------------/

;--- I2C Richting (slave) -------------\
.equ TWI_Flag_Read	= 1					; De bitwaarde voor een Lees-actie
.equ TWI_Flag_Write	= 0					; De bitwaarde voor een Schrijf-actie
.equ TWI_Direction	= 0					; Het bitnummer (in TWI_Address) van de bit die de richting aanduidt
;--------------------------------------/


.equ SlaveAddress_LCD	= $30
.equ SlaveAddress_Servo	= $40


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
.CSEG
;----------------------------------------------/


;---------------------------------------
;--- De macro's verpakt als sub-routine's
;--------------------------------------\
;!! spreek de routines voor lage SRAM adressen aan (..8) !!
StoreByteInto_TWI_IN_Buffer:
	StoreByteSRAMIntoBuffer8 TWI_Data, TWI_IN_Buffer, TWI_IN_Buffer_Input, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

StoreByteInto_TWI_OUT_Buffer:
	StoreByteSRAMIntoBuffer8 temp, TWI_OUT_Buffer, TWI_OUT_Buffer_Input, TWI_OUT_BytesInBuffer, TWI_BufferSize
	ret

LoadByteFrom_TWI_IN_Buffer:
	LoadByteSRAMFromBuffer8 temp, TWI_IN_Buffer, TWI_IN_Buffer_Output, TWI_IN_BytesInBuffer, TWI_BufferSize
	ret

LoadByteFrom_TWI_OUT_Buffer:
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




;***************************************************************************
;*
;* FUNCTION
;*	TWI_hp_delay
;*	TWI_qp_delay
;*
;* DESCRIPTION
;*	hp - half TWI clock period delay (normal: 5.0us / fast: 1.3us)
;*	qp - quarter TWI clock period delay (normal: 2.5us / fast: 0.6us)
;*
;*	SEE DOCUMENTATION !!!
;*
;* USAGE
;*	no parameters
;*
;* RETURN
;*	none
;*
;***************************************************************************

;--------------------------------------\
.equ PostScaler_ = 64					;  64 ->  64x1ms=64ms			per halve bitcycle op de bus => 128ms/bitcycle = 7.8125 bps
.equ PostScaler = 200					; 200     200x5us=1000us=1ms
;---------------------------------------
.DSEG
VarPostScaler_:	.BYTE 1					; outerloop variabele
VarPostScaler:	.BYTE 1					; innerlopp variabele
.CSEG
;--------------------------------------/



;---------------------------------------
;--- 5.0 µs
;---------------------------------------
TWI_hp_delay:
	push	R23
	push	R22
	;ldi	R23, PostScaler_
	lds		R23, VarPostScaler_
TWI_hp_delay_outerloop:
	;ldi	R22, PostScaler
	lds		R22, VarPostScaler
TWI_hp_delay_innerloop:

delay5_0us:								;5.0 micro-seconde (36.9 clockcycles @ 7.372800 MHz)
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	push	R21							; 2 cycles	|	  1*2 =   2 +
	ldi		R21, 8						; 1 cycle	|	  1*1 =   1 +
innerloop5_0us:
	dec		R21							; 1 cycle	|	  8*1 =   8 +
	brne	innerloop5_0us				; 2 cycles	>	  7*2 =  14 +	;7 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	nop									; 1 cycle	|	  1*1 =	  1 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	pop		R21							; 2 cycles	|	  1*2 =   2 +

	dec		R22
	brne	TWI_hp_delay_innerloop
	dec		R23
	brne	TWI_hp_delay_outerloop
	pop		R22
	pop		R23
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				         37 clockcycles


;---------------------------------------
;--- 2.5 µs
;---------------------------------------
TWI_qp_delay:
	push	R23
	push	R22
	;ldi	R23, PostScaler_
	lds		R23, VarPostScaler_
TWI_qp_delay_outerloop:
	;ldi	R22, PostScaler
	lds		R22, VarPostScaler
TWI_qp_delay_innerloop:

delay2_5us:								;2.5 micro-seconde (18.4 clockcycles @ 7.372800 MHz)
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	push	R21							; 2 cycles	|	  1*2 =   2 +
	ldi		R21, 2						; 1 cycle	|	  1*1 =   1 +
innerloop2_5us:
	dec		R21							; 1 cycle	|	  2*1 =   2 +
	brne	innerloop2_5us				; 2 cycles	>	  1*2 =   2 +	;1 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	nop									; 1 cycle	|	  1*1 =	  1 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	pop		R21							; 2 cycles	|	  1*2 =   2 +

	dec		R22
	brne	TWI_qp_delay_innerloop
	dec		R23
	brne	TWI_qp_delay_outerloop
	pop		R22
	pop		R23
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				         19 clockcycles




;***************************************************************************
;*
;* FUNCTION
;*	TWI_init
;*
;* DESCRIPTION
;*	Initialization of the TWI bus interface.
;*
;* USAGE
;*	Call this function once to initialize the TWI bus. No parameters
;*	are required.
;*
;* RETURN
;*	None
;*
;* NOTE
;*	PORTD and DDRD pins not used by the TWI bus interface will be
;*	set to Hi-Z (!).
;*
;* COMMENT
;*	This function can be combined with other PORTD initializations.
;*
;***************************************************************************

TWI_Initialize:
	ldi		R16, PostScaler_			; variabelen voor PostScaler vertraging
	sts		VarPostScaler_, R16
	ldi		R16, PostScaler
	sts		VarPostScaler, R16
TWI_init:
	clr		TWI_Status					;
	cbi		TWI_PORT_DDR, TWI_SCL		; TWI pinnen als open collector instellen
	cbi		TWI_Port, TWI_SCL			;
	cbi		TWI_PORT_DDR, TWI_SDA		;
	cbi		TWI_Port, TWI_SDA			;
	ret



;***************************************************************************
;*
;* FUNCTION
;*	TWI_rep_start
;*
;* DESCRIPTION
;*	Assert repeated start condition and sends slave address.
;*
;* USAGE
;*	TWIadr - Contains the slave address and transfer direction.
;*
;* RETURN
;*	Carry flag - Cleared if a slave responds to the address.
;*
;* NOTE
;*	IMPORTANT! : This funtion must be directly followed by TWI_start.
;*
;***************************************************************************

TWI_rep_start:
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low
	cbi		TWI_PORT_DDR, TWI_SDA		; release SDA
	rcall	TWI_hp_delay				; half period delay
	cbi		TWI_PORT_DDR, TWI_SCL		; release SCL
	rcall	TWI_qp_delay				; quarter period delay


;***************************************************************************
;*
;* FUNCTION
;*	TWI_start
;*
;* DESCRIPTION
;*	Generates start condition and sends slave address.
;*
;* USAGE
;*	TWIadr - Contains the slave address and transfer direction.
;*
;* RETURN
;*	Carry flag - Cleared if a slave responds to the address.
;*
;* NOTE
;*	IMPORTANT! : This funtion must be directly followed by TWI_write.
;*
;***************************************************************************

TWI_start:
	mov		TWI_Data, TWI_Address		; copy address to transmitt register
	sbi		TWI_PORT_DDR, TWI_SDA		; force SDA low
	rcall	TWI_qp_delay				; quarter period delay


;***************************************************************************
;*
;* FUNCTION
;*	TWI_write
;*
;* DESCRIPTION
;*	Writes data (one byte) to the TWI bus. Also used for sending
;*	the address.
;*
;* USAGE
;*	TWIdata - Contains data to be transmitted.
;*
;* RETURN
;*	Carry flag - Set if the slave respond transfer.
;*
;* NOTE
;*	IMPORTANT! : This funtion must be directly followed by TWI_get_ack.
;*
;***************************************************************************

TWI_write:
	sec									; set carry flag
	rol		TWI_Data					; shift in carry and out bit one
	rjmp	TWI_write_first
TWI_write_bit:
	lsl		TWI_Data					; if transmit register empty
TWI_write_first:
	breq	TWI_get_ack					;	goto get acknowledge
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low

	brcc	TWI_write_low				; if bit high
	nop									;	(equalize number of cycles)
	cbi		TWI_PORT_DDR, TWI_SDA		;   release SDA
	rjmp	TWI_write_high
TWI_write_low:							; else
	sbi		TWI_PORT_DDR, TWI_SDA		;	force SDA low
	rjmp	TWI_write_high				;	(equalize number of cycles)
TWI_write_high:
	rcall	TWI_hp_delay				; half period delay
	cbi		TWI_PORT_DDR, TWI_SCL		; release SCL
	rcall	TWI_hp_delay				; half period delay

	rjmp	TWI_write_bit


;***************************************************************************
;*
;* FUNCTION
;*	TWI_get_ack
;*
;* DESCRIPTION
;*	Get slave acknowledge response.
;*
;* USAGE
;*	(used only by TWI_write in this version)
;*
;* RETURN
;*	Carry flag - Cleared if a slave responds to a request.
;*
;***************************************************************************

TWI_get_ack:
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low
	cbi		TWI_PORT_DDR, TWI_SDA		;   release SDA
	rcall	TWI_hp_delay				; half period delay
	cbi		TWI_PORT_DDR, TWI_SCL		; release SCL

TWI_get_ack_wait:
	sbis	TWI_PIN, TWI_SCL			; wait SCL high (In case wait states are inserted)
	rjmp	TWI_get_ack_wait

	clc									; clear carry flag
	sbic	TWI_PIN, TWI_SDA			; if SDA is high
	sec									;	set carry flag
	rcall	TWI_hp_delay				; half period delay
	ret


;***************************************************************************
;*
;* FUNCTION
;*	TWI_do_transfer
;*
;* DESCRIPTION
;*	Executes a transfer on bus. This is only a combination of TWI_read
;*	and TWI_write for convenience.
;*
;* USAGE
;*	TWIadr - Must have the same direction as when TWI_start was called.
;*	see TWI_read and TWI_write for more information.
;*
;* RETURN
;*	(depends on type of transfer, read or write)
;*
;* NOTE
;*	IMPORTANT! : This funtion must be directly followed by TWI_read.
;*
;***************************************************************************

TWI_do_transfer:
	sbrs	TWI_Address, TWI_Direction	; if dir = write
	rjmp	TWI_write					;	goto write data


;***************************************************************************
;*
;* FUNCTION
;*	TWI_read
;*
;* DESCRIPTION
;*	Reads data (one byte) from the TWI bus.
;*
;* USAGE
;*	Carry flag - 	If set no acknowledge is given to the slave
;*			indicating last read operation before a STOP.
;*			If cleared acknowledge is given to the slave
;*			indicating more data.
;*
;* RETURN
;*	TWIdata - Contains received data.
;*
;* NOTE
;*	IMPORTANT! : This funtion must be directly followed by TWI_put_ack.
;*
;***************************************************************************

TWI_read:
	rol		TWI_Status					; store acknowledge
										; (used by TWI_put_ack)
	ldi		TWI_Data, 0x01				; data = 0x01
TWI_read_bit:							; do
	sbi		TWI_PORT_DDR, TWI_SCL		;   force SCL low
	rcall	TWI_hp_delay				;   half period delay

	cbi		TWI_PORT_DDR, TWI_SCL		;   release SCL

WS_Read:
	sbis	TWI_PIN, TWI_SCL			; wait SCL high (ivm. waitstates)
	rjmp	WS_Read

	rcall	TWI_hp_delay				;   half period delay

	clc									;	clear carry flag
	sbic	TWI_PIN, TWI_SDA			;   if SDA is high
	sec									;	  set carry flag

	rol		TWI_Data					;   store data bit
	brcc	TWI_read_bit				; while receive register not full


;***************************************************************************
;*
;* FUNCTION
;*	TWI_put_ack
;*
;* DESCRIPTION
;*	Put acknowledge.
;*
;* USAGE
;*	(used only by TWI_read in this version)
;*
;* RETURN
;*	none
;*
;***************************************************************************

TWI_put_ack:
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low

	ror		TWI_Status					; get status bit
	brcc	TWI_put_ack_low				; if bit low goto assert low
	cbi		TWI_PORT_DDR, TWI_SDA		;   release SDA
	rjmp	TWI_put_ack_high
TWI_put_ack_low:						; else
	sbi		TWI_PORT_DDR, TWI_SDA		;	force SDA low
TWI_put_ack_high:

	rcall	TWI_hp_delay				; half period delay
	cbi		TWI_PORT_DDR, TWI_SCL		;   release SCL
TWI_put_ack_wait:
	sbis	TWI_PIN, TWI_SCL			; wait SCL high
	rjmp	TWI_put_ack_wait
	rcall	TWI_hp_delay				; half period delay
	ret


;***************************************************************************
;*
;* FUNCTION
;*	TWI_stop
;*
;* DESCRIPTION
;*	Assert stop condition.
;*
;* USAGE
;*	No parameters.
;*
;* RETURN
;*	None.
;*
;***************************************************************************

TWI_stop:
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low
	sbi		TWI_PORT_DDR, TWI_SDA		; force SDA low
	rcall	TWI_hp_delay				; half period delay
	cbi		TWI_PORT_DDR, TWI_SCL		; release SCL
	rcall	TWI_qp_delay				; quarter period delay
	cbi		TWI_PORT_DDR, TWI_SDA		; release SDA
	rcall	TWI_hp_delay				; half period delay
	ret










;--------------------------------------\
;--- De waarde in register "temp" schrijven naar de slave met adres "TWI_Address"
TWI_WriteToSlave:
	push	R16
	sbi		LED_PORT, LED_TWI			; "TWI Activity" LED aan

	rcall	TWI_init
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
	rcall	TWI_start					; Send start condition and address

	mov		TWI_Data, temp				; register "temp" bevat de te verzenden data
	rcall	TWI_do_transfer				; Execute transfer

	rcall	TWI_stop					; Send stop condition

	cbi		LED_PORT, LED_TWI			; "TWI Activity" LED uit
	pop		R16
	ret
;--------------------------------------/


;--------------------------------------\
;--- Een byte lezen van de slave met adres "TWI_Address" en plaatsen in de invoer-buffer
TWI_ReadFromSlave:
	push	R16
	push	R24
	sbi		LED_PORT, LED_TWI			; "TWI Activity" LED aan
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
;	mov		R24, TWI_Address			; adres tijdelijk bewaren

	rcall	TWI_init
;	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
;	rcall	TWI_start					; Send start condition and address

;	mov		TWI_Address, R24			; adres weer ophalen
	ori		TWI_Address, TWI_Flag_Read	; Read/not-write in bit0
;	rcall	TWI_rep_start				; Send repeated start condition and address
	rcall	TWI_start					; Send start condition and address

	sec									; Set no acknowledge (read is followed by a stop condition)
	rcall	TWI_do_transfer				; Execute transfer (read)

	rcall	TWI_stop					; Send stop condition

	rcall	StoreByteInto_TWI_IN_Buffer

	cbi		LED_PORT, LED_TWI			; "TWI Activity" LED uit
	pop		R24
	pop		R16
	ret
;--------------------------------------/



;--------------------------------------\
;--- Schrijf een byte naar een servo.
;--- input: R16 = te schrijven waarde
;---        $00=links,$80=midden,$FF=rechts
;---------------------------------------
TWI_WriteServo:
	push	R16
	ldi		TWI_Address, SlaveAddress_Servo
	sbi		LED_PORT, LED_TWI			; "TWI Activity" LED aan

	rcall	TWI_init
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
	rcall	TWI_start					; Send start condition and address

	mov		TWI_Data, temp				; register "temp" bevat de te verzenden data
	rcall	TWI_do_transfer				; Execute transfer

	rcall	TWI_stop					; Send stop condition

	cbi		LED_PORT, LED_TWI			; "TWI Activity" LED uit
	pop		R16
	ret
;--------------------------------------/



;--------------------------------------\
SlaveFoundString:
	.db 13,10, "I2C-Slave(s) @ ", EOS_Character,0
;---------------------------------------
TWI_FindSlaves:
	ldi		ZL, LOW(2*SlaveFoundString)
	ldi		ZH, HIGH(2*SlaveFoundString)
	rcall	UART_transmit_String

	sbi		LED_PORT, LED_TWI			; "TWI Activity" LED aan

	push	R16
	push	R24
	push	R25
	ldi		R24, 8						; 1e te testen slave-adres
NextSlave:
	mov		TWI_Address, R24

	rcall	TWI_init
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
	rcall	TWI_start					; Send start condition and address

	ser		R25
	brcs	NoSlaveFound
	; Er is een slave gevonden op het adres in 'R24'..
	clr		R25
NoSlaveFound:

	rcall	TWI_stop					; Send stop condition

	tst		R25
	brne	NSF

	; de waarde in R24 hexadecimaal afbeelden
	mov		R16, R24
	lsr		R16
	lsr		R16
	lsr		R16
	lsr		R16
	cpi		R16, 10
	brlo	hexa
	ldi		R25, 55
	add		R16, R25
	rjmp	ishexa
hexa:
	ori		R16, $30
ishexa:
	rcall	UART_transmit

	mov		R16, R24
	andi	R16, $0F
	cpi		R16, 10
	brlo	hexa2
	ldi		R25, 55
	add		R16, R25
	rjmp	ishexa2
hexa2:
	ori		R16, $30
ishexa2:
	rcall	UART_transmit

	; plus een hexadecimaal aanduiding..
	ldi		R16, 'h'
	rcall	UART_transmit
	; plus een spatie..
	ldi		R16, ' '
	rcall	UART_transmit

NSF:
	inc		R24
	cpi		R24, 0b1111000				; HS-mode code
	brlo	NextSlave

	; plus een CRLF..
	rcall	UART_CrLf

	pop		R25
	pop		R24
	pop		R16

	cbi		LED_PORT, LED_TWI			; "TWI Activity" LED uit
	ret
;--------------------------------------/



;---------------------------------------
;--- input: R16 = outerloop waarde
;--- output: R16 = ASCII-waarde bus-outerloop ('7'..'0')
;--------------------------------------\
BusSpeed_To_ASCII:
	; maximale vertraging-waarde?
	cpi		R16, $FF
	brne	bit7_0
	ldi		R16, '*'					; * teruggeven als de vertraging maximaal is..
	ret
bit7_0:
	push	R17
	clr		R17
bitTest:
	lsr		R16
	brcs	bitFound
	inc		R17
	rjmp	bitTest
bitFound:
	mov		R16, R17
	ori		R16, $30
	pop		R17
	ret
;--------------------------------------/


;--------------------------------------\
BusSpeed_Message:
	ldi		ZL, low(2*BusSpeedString)
	ldi		ZH, high(2*BusSpeedString)
	rcall	UART_transmit_String
	rcall	BusSpeed_To_ASCII
	rcall	UART_transmit
	rcall	UART_CrLf
	ret
;--------------------------------------/

BusSpeedString:
	.db 13,10, "I2C Busspeed [outerloop.bit]: ", EOS_Character,0

;--------------------------------------\
BusSpeed_Down:
	push	R16
	push	ZH
	push	ZL
	; de outerloop verlengen..
	lds		R16, VarPostScaler_
	; vertaging al op maximaal?
	cpi		R16, $FF
	breq	DownOK						; er is geen grotere vertraging dan $FF..
	; bit schuiven
	lsl		R16
	brcc	DownOK
	; instellen op maximale vertraging
	ldi		R16, $FF
DownOK:
	sts		VarPostScaler_, R16
	; een melding geven aan de PC-user
	rcall	BusSpeed_Message
	pop		ZL
	pop		ZH
	pop		R16
	ret
;--------------------------------------/


;--------------------------------------\
BusSpeed_Up:
	push	R16
	push	ZH
	push	ZL
	; de outerloop verkorten..
	lds		R16, VarPostScaler_
	; vertraging nu op maximaal?
	cpi		R16, $FF
	brne	Up7_0
	; instellen op grootste vertraging (bit7..0 methode)..
	ldi		R16, 0b10000000
	rjmp	UpOK
Up7_0:
	lsr		R16
	brcc	UpOK
	; herstellen op de kortste vertraging..
	ldi		R16, 0b00000001
UpOK:
	sts		VarPostScaler_, R16
	; een melding geven aan de PC-user
	rcall	BusSpeed_Message
	pop		ZL
	pop		ZH
	pop		R16
	ret
;--------------------------------------/







;---------------------------------------
;--- TWI_ProcessMessages
;--------------------------------------\
TWI_ProcessMessages:
Check_Output:
	; Is de uitvoer-buffer gevuld met te verzenden data?
	IsBufferEmpty TWI_OUT_BytesInBuffer
	breq	Done_Output					; Er is geen input als de zero-flag is gezet..
	
	; Er is output in de uitvoer-buffer
	rcall	LoadByteFrom_TWI_OUT_Buffer
	brcs	Done_Output					; buffer lezen was mislukt als de carry-flag gezet is
	; register "temp" bevat de uit de uitvoer-buffer gelezen byte

Special1:
	; willen we naar slaves zoeken in het hele adresbereik?
	cpi		temp, CharFindSlaves
	brne	Special2
	rcall	TWI_FindSlaves				; slaves zoeken
	rjmp	SchrijfNaarSlave			; teken ook uitvoeren naar LCD..
	;rjmp	Check_Output				; teken 'inslikken'..
Special2:
	; willen we de bus-snelheid verlagen?
	cpi		temp, CharBusSpeedDown
	brne	Special3
	rcall	BusSpeed_Down
	rjmp	SchrijfNaarSlave			; teken ook uitvoeren naar LCD..
	;rjmp	Check_Output				; teken 'inslikken'..
Special3:
	; willen we de bus-snelheid verhogen?
	cpi		temp, CharBusSpeedUp
	brne	Special4
	rcall	BusSpeed_Up
	rjmp	SchrijfNaarSlave			; teken ook uitvoeren naar LCD..
	;rjmp	Check_Output				; teken 'inslikken'..
Special4:
	; willen we naar een servo schrijven?
	cpi		temp, CharWriteServo
	brne	Special5
	; Er is een sein ontvangen om een servo te beschrijven.
	; Nu een (nieuwe) waarde in R16 plaatsen (servo-dutycycle [0..255])
	push	R16
	;ldi		R16, volgende byte die binnenkomt..

	;!!!!!DEBUG!!!!!

	ldi		TWI_Address, SlaveAddress_Servo	; Het slave-adres instellen
	rcall	TWI_WriteServo				; De byte in R16 naar de servo schrijven
	pop		R16
	rjmp	SchrijfNaarSlave			; teken ook uitvoeren naar LCD..
	;rjmp	Check_Output				; teken 'inslikken'..
Special5:
	; willen we van de LCD-slave lezen?
	cpi		temp, CharRequestSlaveTx
	brne	SchrijfNaarSlave
	ldi		TWI_Address, SlaveAddress_LCD	; Het slave-adres instellen
	rcall	TWI_ReadFromSlave			; De byte inlezen -> TWI_IN_Buffer
	;rjmp	SchrijfNaarSlave			; teken ook uitvoeren naar LCD..
	;rjmp	Check_Output				; teken 'inslikken'..

SchrijfNaarSlave:
	; standaard uitvoer naar LCD..
	ldi		TWI_Address, SlaveAddress_LCD	; Het slave-adres instellen
	rcall	TWI_WriteToSlave			; De byte in register "temp" verzenden
	rjmp	Check_Output				; meer bytes te schrijven?
Done_Output:

Check_Input:
	; Is de invoer-buffer gevuld met te lezen data?
	IsBufferEmpty TWI_IN_BytesInBuffer
	breq	Done_Input					; Er is geen input als de zero-flag is gezet..
	
	; Er is input in de invoer-buffer
	rcall	LoadByteFrom_TWI_IN_Buffer
	brcs	Done_Input					; buffer lezen was mislukt als de carry-flag gezet is
	; register "temp" bevat de uit de invoer-buffer gelezen byte
	;...
	;...
	; Doe iets met de gelezen byte..
	; De byte gelezen van de I2C-slave nu schrijven naar de RS232-poort
	rcall	UART_transmit
;	rcall	StoreByteSRAMInto_RS232_OUT_Buffer
	;...
	;...
	rjmp	Check_Input					; meer bytes te lezen?
Done_Input:

	ret
;--------------------------------------/







;/*
;;***************************************************************************
;;*
;;* PROGRAM
;;*	main - Test of TWI master implementation
;;*
;;* DESCRIPTION
;;*	Initializes TWI interface and shows an example of using it.
;;*
;;***************************************************************************
;
;;RESET:
;main:	rcall	TWI_init		; initialize TWI interface
;
;;**** Write data => Adr(00) = 0x55 ****
;
;	ldi	TWIadr,$A0+TWIwr	; Set device address and write            (ldi TWIadr, ($50<<1)+TWIwr)
;	rcall	TWI_start		; Send start condition and address
;
;	ldi	TWIdata,$00		; Write word address (0x00)
;	rcall	TWI_do_transfer		; Execute transfer
;
;	ldi	TWIdata,$55		; Set write data to 01010101b
;	rcall	TWI_do_transfer		; Execute transfer
;
;	rcall	TWI_stop		; Send stop condition
;
;;**** Read data => TWIdata = Adr(00) ****
;
;	ldi	TWIadr,$A0+TWIwr	; Set device address and write
;	rcall	TWI_start		; Send start condition and address
;
;	ldi	TWIdata,$00		; Write word address
;	rcall	TWI_do_transfer		; Execute transfer
;
;	ldi	TWIadr,$A0+TWIrd	; Set device address and read
;	rcall	TWI_rep_start		; Send repeated start condition and address
;
;	sec				; Set no acknowledge (read is followed by a stop condition)
;	rcall	TWI_do_transfer		; Execute transfer (read)
;
;	rcall	TWI_stop		; Send stop condition - releases bus
;
;	rjmp	main			; Loop forewer
;
;;**** End of File ****
;*/
