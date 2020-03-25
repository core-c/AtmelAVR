.include "m32def.inc"

;--- De AVR ATMega32 Interrupt "vector" tabel --------------------------------------
.CSEG
.org $0000		; RESET Vector Address
rjmp RESET		;^--------------------^
.org INT0addr	; External Interrupt0 Vector Address
reti
.org INT1addr	; External Interrupt1 Vector Address
reti
.org INT2addr	; External Interrupt2 Vector Address
reti
.org OC2addr	; Output Compare2 Interrupt Vector Address
reti
.org OVF2addr	; Overflow2 Interrupt Vector Address
reti
.org ICP1addr	; Input Capture1 Interrupt Vector Address
reti
.org OC1Aaddr	; Output Compare1A Interrupt Vector Address
reti
.org OC1Baddr	; Output Compare1B Interrupt Vector Address
reti
.org OVF1addr	; Overflow1 Interrupt Vector Address
reti
.org OC0addr	; Output Compare0 Interrupt Vector Address
reti
.org OVF0addr	; Overflow0 Interrupt Vector Address
reti
.org SPIaddr	; SPI Interrupt Vector Address
reti
.org URXCaddr	; USART Receive Complete Interrupt Vector Address
reti
.org UDREaddr	; USART Data Register Empty Interrupt Vector Address
reti
.org UTXCaddr	; USART Transmit Complete Interrupt Vector Address
reti
.org ADCCaddr	; ADC Interrupt Vector Address
reti
.org ERDYaddr	; EEPROM Interrupt Vector Address
reti
.org ACIaddr	; Analog Comparator Interrupt Vector Address
reti
.org TWSIaddr   ; Irq. vector address for Two-Wire Interface
reti
.org SPMRaddr	; Store Program Memory Ready Interrupt Vector Address
reti
;-----------------------------------------------------------------------------------




.include "M32_TWI.asm"

RESET:
main_loop:
	rjmp	main_loop

