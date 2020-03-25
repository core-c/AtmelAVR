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

;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17				; Een register voor algemeen gebruik
.def TWI_Data		= R18				;
.def TWI_Address	= R19				;
.def TWI_Status		= R20				;
;--------------------------------------/

.equ CharRequestSlaveTx = '?'			; Het teken om de slave te laten schrijven wat die heeft onthouden van de laatste overdracht (naar hem toe)


.MACRO Force_SCL_Low
	sbi		TWI_PORT_DDR, TWI_SCL		; force SCL low
.ENDMACRO

.MACRO Force_SDA_Low
	sbi		TWI_PORT_DDR, TWI_SDA		; force SDA low
.ENDMACRO

.MACRO Release_SCL
	cbi		TWI_PORT_DDR, TWI_SCL		; release SCL
.ENDMACRO

.MACRO Release_SDA
	cbi		TWI_PORT_DDR, TWI_SDA		; release SDA
.ENDMACRO

.MACRO WaitFor_SCL_High
_1:
	sbis	TWI_PIN, TWI_SCL			; wait SCL high
	rjmp	_1
.ENDMACRO

.MACRO SDA_To_CarryFlag
	clc									;	clear carry flag
	sbic	TWI_PIN, TWI_SDA			;   if SDA is high
	sec									;	  set carry flag
.ENDMACRO





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

.equ PostScaler = 8						; Een test wees uit dat de 5.0 µs te hoog was gegrepen..
;---------------------------------------
;--- 5.0 µs
;---------------------------------------
TWI_hp_delay:
	push	R22
	ldi		R22, PostScaler
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
	pop		R22
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				         37 clockcycles


;---------------------------------------
;--- 2.5 µs
;---------------------------------------
TWI_qp_delay:
	push	R22
	ldi		R22, PostScaler
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
	pop		R22
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				         19 clockcycles



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
	Force_SCL_Low						; force SCL low
	Release_SDA							; release SDA
	rcall	TWI_hp_delay				; half period delay
	Release_SCL							; release SCL
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
	Force_SCL_Low						; force SCL low
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
	Force_SCL_Low						; force SCL low

	brcc	TWI_write_low				; if bit high
	nop									;	(equalize number of cycles)
	Release_SDA							;	release SDA
	rjmp	TWI_write_high
TWI_write_low:							; else
	Force_SCL_Low						;   force SCL low
	rjmp	TWI_write_high				;	(equalize number of cycles)
TWI_write_high:
	rcall	TWI_hp_delay				; half period delay
	Release_SCL							; release SCL
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
	Force_SCL_Low						; force SCL low
	Release_SDA							; release SDA
	rcall	TWI_hp_delay				; half period delay
	Release_SCL							; release SCL
	WaitFor_SCL_High					; wait SCL high (In case wait states are inserted)
	SDA_To_CarryFlag					; clear carry flag if SDA == low, else carry =1
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
	rol		TWI_Status					; store acknowledge (used by TWI_put_ack)

	ldi		TWI_Data, 0x01				; data = 0x01
TWI_read_bit:							; do
	Force_SCL_Low						;   force SCL low
	rcall	TWI_hp_delay				;   half period delay
	Release_SCL							;	release SCL
	rcall	TWI_hp_delay				;   half period delay
	SDA_To_CarryFlag					;	clear carry flag if SDA == low, else carry =1
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
	Force_SCL_Low						; force SCL low

	ror		TWI_Status					; get status bit
	brcc	TWI_put_ack_low				; if bit low goto assert low
	Release_SDA							;	release SDA
	rjmp	TWI_put_ack_high
TWI_put_ack_low:						; else
	Force_SDA_Low						;	force SDA low
TWI_put_ack_high:

	rcall	TWI_hp_delay				; half period delay
	Release_SCL							; release SCL
	WaitFor_SCL_High					; wait SCL high
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
	Force_SCL_Low						; force SCL low
	Force_SDA_Low						; force SDA low
	rcall	TWI_hp_delay				; half period delay
	Release_SCL							; release SCL
	rcall	TWI_qp_delay				; quarter period delay
	Release_SDA							; release SDA
	rcall	TWI_hp_delay				; half period delay
	ret


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
TWI_init:
	clr		TWI_Status					; clear TWI status register (SREG bewaren tijdens INT)
	cbi		TWI_PORT_DDR, TWI_SCL		; set TWI pins to open colector
	cbi		TWI_Port, TWI_SCL			;
	cbi		TWI_PORT_DDR, TWI_SDA		;
	cbi		TWI_Port, TWI_SDA			;
	ret





;---------------------------------------
;--- De waarde in register "temp" schrijven
;--- naar de slave met adres "TWI_Address"
;--------------------------------------\
TWI_WriteToSlave:
	LED_Aan LED_TWI						; "TWI Activity" LED aan

	rcall	TWI_init
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
	rcall	TWI_start					; Send start condition and address

	ldi		TWI_Data,$00				; LCD UserCommand (0x00 == LCD character lineprint)
	rcall	TWI_do_transfer				; Execute transfer

	mov		TWI_Data, temp				; register "temp" bevat de te verzenden data
	rcall	TWI_do_transfer				; Execute transfer

	rcall	TWI_stop					; Send stop condition

	LED_Uit LED_TWI						; "TWI Activity" LED uit
	ret
;--------------------------------------/


;---------------------------------------
;--- Een byte lezen van de slave met
;--- adres "TWI_Address" en
;--- plaatsen in de TWI invoer-buffer.
;--------------------------------------\
TWI_ReadFromSlave:
	LED_Aan LED_TWI						; "TWI Activity" LED aan
	
	push	R24
	lsl		TWI_Address					; Slave-adres in bit7-1 plaatsen
	mov		R24, TWI_Address			; adres tijdelijk bewaren

	rcall	TWI_init
	ori		TWI_Address, TWI_Flag_Write	; Read/not-write in bit0
	rcall	TWI_start					; Send start condition and address

;#	ldi		TWI_Data,$00				; ..
;#	rcall	TWI_do_transfer				; Execute transfer

	mov		TWI_Address, R24			; adres weer ophalen
	ori		TWI_Address, TWI_Flag_Read	; Read/not-write in bit0
	rcall	TWI_rep_start				; Send repeated start condition and address

	sec									; Set no acknowledge (read is followed by a stop condition)
	rcall	TWI_do_transfer				; Execute transfer (read)

	rcall	TWI_stop					; Send stop condition

	rcall	StoreByteSRAMInto_TWI_IN_Buffer

	pop		R24

	LED_Uit LED_TWI						; "TWI Activity" LED uit
	ret
;--------------------------------------/
