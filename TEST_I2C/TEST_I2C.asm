;---------------------------------------------------------------------------------------------------
;--- Een I2C-Master implementatie.
;---------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------
;--- Connecties met AVR:
;---
;---							|---------------|
;---	LED Running			T0	|PB0         PA0|
;---	LED Error			T1	|PB1         PA1|
;---	LED RS232 activity	AIN0|PB2         PA2|
;---	LED I2C activity	AIN1|PB3         PA3|
;---							|            PA4|
;---							|            PA5|
;---							|            PA6|
;---							|            PA7|
;---							|               |
;---							|               |
;---							|               |
;---							|            PC7|
;---							|            PC6|
;---	 						|PD0         PC5|
;---	 						|PD1         PC4|
;---	 						|PD2         PC3|
;---	 						|PD3         PC2|
;---	 						|PD4         PC1|			I2C SDA		(->slave PD2)
;---							|PD5         PC0|			I2C SCL		(->slave PD4)
;---							|PD6         PD7|
;---							|---------------|
;---
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "System.inc"					; 
.include "RotatingBuffer.asm"			; Een roterende buffer in SRAM
;.list
;--------------------------------------/


;--- LED Connecties -------------------\
.equ LED_PORT		= PORTB				; De poort op de AVR
.equ LED_PORT_DDR	= DDRB				; De richting van de poort op de AVR
.equ LED_Running	= PB0				; De lijn voor de "Running" LED indicator
.equ LED_Error		= PB1				; De lijn voor de "Error" LED indicator
.equ LED_RS232		= PB2				; De lijn voor de "RS232 Activity" LED indicator
.equ LED_TWI		= PB3				; De lijn voor de "I2C Acyivity" LED indicator
;--------------------------------------/

;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17				; Een register voor algemeen gebruik
.def TWI_Data		= R18				; 
.def TWI_Address	= R19				; 
.def TWI_Status		= R20				; 
.def Servo_Progress	= R21				; 
;--------------------------------------/



;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	rjmp UART_Rx_Interrupt				; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/



;--- INCLUDED SUB-ROUTINES ------------\
.include "Delays.asm"					; vertraging sub-routine's
.include "I2C.asm"						; I2C sub-routine's
.include "RS232.asm"					; RS232 sub-routine's
;--------------------------------------/




;---------------------------------------
;--- AnalogComparator_Initialize
;--------------------------------------\
AnalogComparator_Initialize:
	; De analog-comparator uitschakelen om vermogen te besparen
	ldi		temp, (1<<ACD)				; ACD = Analog Compare Disable
	out		ACSR, temp					; ACSR = Analog comparator Control & Status Register
	ret
;--------------------------------------/


;---------------------------------------
;--- LEDs_Initialize
;--------------------------------------\
LEDs_Initialize:
	; De aangesloten LED's
	sbi		LED_PORT_DDR, LED_Running	; Beide LED poorten als output instellen
	sbi		LED_PORT_DDR, LED_Error		;
	sbi		LED_PORT_DDR, LED_RS232		;
	sbi		LED_PORT_DDR, LED_TWI		;
	sbi		LED_PORT, LED_Running		; "Running" LED aan
	cbi		LED_PORT, LED_Error			; "Error" LED uit
	cbi		LED_PORT, LED_RS232			; "RS232 Activity" LED uit
	cbi		LED_PORT, LED_TWI			; "TWI Activity" LED uit
	ret
;--------------------------------------/










;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer

	rcall	AnalogComparator_Initialize	; initialiseer de Analog Comparator

	rcall	LEDs_Initialize				; initialiseer de aangesloten LEDs

	;--- De UART instellen ------------\
	rcall	UART_Initialize_Buffer		; de RS232 Data-Ontvangst-Buffer in SRAM
	rcall	UART_Initialize				; De UART zelf initialiseren
	;----------------------------------/

	;--- I2C instellen ----------------\
	rcall	TWI_Initialize_Buffers		; initialiseer de invoer- & uitvoer-buffers voor TWI
	rcall	TWI_Initialize				; intialiseer de Two-Wire-Interface (I2C)
	;----------------------------------/

	sei									; interrupts weer toelaten

	rcall	delay25ms
	rcall	UART_transmit_InitString

main_loop:
	rcall	UART_ProcessRecordIn		; eventuele seriële RS232 data verwerken (zsm).
	rcall	TWI_ProcessMessages			; eventuele seriële I2C data verwerken..
	rjmp 	main_loop
;--------------------------------------/
