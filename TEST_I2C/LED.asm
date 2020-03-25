;--- LED Connecties -------------------\
.equ LED_PORT		= PORTB				; De poort op de AVR
.equ LED_PORT_DDR	= DDRB				; De richting van de poort op de AVR
.equ LED_Running	= PB0				; De lijn voor de "Running" LED indicator
.equ LED_Error		= PB1				; De lijn voor de "Error" LED indicator
.equ LED_RS232		= PB2				; De lijn voor de "RS232 Activity" LED indicator
.equ LED_TWI		= PB3				; De lijn voor de "I2C Acyivity" LED indicator
;--------------------------------------/


.MACRO LED_Aan;(LED)
	sbi		LED_PORT, @0				; Een LED aan
.ENDMACRO

.MACRO LED_Uit;(LED)
	cbi		LED_PORT, @0				; Een LED uit
.ENDMACRO


;---------------------------------------
;--- LEDs_Initialize
;--------------------------------------\
LEDs_Initialize:
	; De poortrichting instellen als OUTPUT
	sbi		LED_PORT_DDR, LED_Running	;
	sbi		LED_PORT_DDR, LED_Error		;
	sbi		LED_PORT_DDR, LED_RS232		;
	sbi		LED_PORT_DDR, LED_TWI		;
	; Alle LED's uit
	LED_Aan LED_Running					; "Running" LED aan
	LED_Uit LED_Error					; "Error" LED uit
	LED_Uit LED_RS232					; "RS232 Activity" LED uit
	LED_Uit LED_TWI						; "TWI Activity" LED uit
	ret
;--------------------------------------/



