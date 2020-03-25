
;--- LED Connecties -------------------\
.equ LED_PORT			= PORTB			; De poort op de AVR
.equ LED_PORT_DDR		= DDRB			; De richting van de poort op de AVR
.equ LED_Running		= PB0			; De lijn voor de "Running" LED indicator (groen driehoek)
.equ LED_Error			= PB1			; De lijn voor de "Error" LED indicator (rood)
.equ LED_TWI_Activity	= PB2			; De lijn voor de "I2C Acyivity" LED indicator (rood)
.equ LED_TWI_AddrMatch	= PB3			; De lijn voor de "TWI Slave Address Match" LED indicator (groen)
;.equ LED_TWI_In		= PB4			; "De slave is aan het ontvangen van de master"
;.equ LED_TWI_Out		= PB5			; "De slave is aan het verzenden naar de master"
;.equ LED_Waitstate		= PB6			; Een waitstate is actief
;--------------------------------------/


;--- MACRO's --------------------------\
.MACRO LED_Aan;(LED)
	sbi		LED_PORT, @0				; Een LED aan
.ENDMACRO

.MACRO LED_Uit;(LED)
	cbi		LED_PORT, @0				; Een LED uit
.ENDMACRO

.MACRO CarryFlag_To_LED;(LED)
	brcc	_1
	LED_Aan @0							; LED aan als carryflag=1
_1:	brcs	_2
	LED_Uit @0							; LED uit als carryflag=0
_2:	;nop
.ENDMACRO
;--------------------------------------/


;-------------------------------------------
;--- De LED's initialiseren
;------------------------------------------\
LED_Initialize:
	; De poort-richting instellen op OUTPUT
	sbi		LED_PORT_DDR, LED_Running		;
	sbi		LED_PORT_DDR, LED_Error			;
	sbi		LED_PORT_DDR, LED_TWI_Activity	;
	sbi		LED_PORT_DDR, LED_TWI_AddrMatch	;
	; alle LED's uit
	LED_Uit LED_Running						; "Running" LED ff uit laten..
	LED_Uit LED_Error						; "Error" LED uit
	LED_Uit LED_TWI_Activity				; "TWI Activity" LED uit
	LED_Uit LED_TWI_AddrMatch				; "TWI Address Match" LED uit
	ret
;------------------------------------------/
