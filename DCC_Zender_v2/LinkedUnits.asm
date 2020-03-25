;---------------------------------------------------------------------------------
;---
;---  Ron's eigen units linken							Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------


;--- in te linken units:
;.equ Linked_AVR_Core		= 1		; "AVR_Core.asm"		altijd ingelinkt.
;.equ Linked_AVR_16			= 0		; "AVR_16.asm"
;.equ Linked_AVR_Delay		= 0		; "AVR_Delay.asm"
;.equ Linked_AVR_Buffer		= 0		; "AVR_Buffer.asm"
;.equ Linked_AVR_LED		= 0		; "AVR_LED.asm"
;.equ Linked_8535_EEPROM	= 0		; "8535_EEPROM.asm"
;.equ Linked_8535_AC		= 0		; "8535_AC.asm"
;.equ Linked_8535_ADC		= 0		; "8535_ADC.asm"
;.equ Linked_8535_Timer0	= 0		; "8535_Timer0.asm"
;.equ Linked_8535_Timer1	= 0		; "8535_Timer1.asm"
;.equ Linked_8535_Timer2	= 0		; "8535_Timer2.asm"
;.equ Linked_8535_Timers	= 0		; "8535_Timers.asm"		gebruikt: 8535_Timer0,8535_Timer1 & 8535_Timer2
;.equ Linked_8535_UART		= 0		; "8535_UART.asm"
;.equ Linked_LCD_HD44780	= 0		; "LCD_HD44780.asm"		gebruikt: AVR_Delay
;.equ Linked_AVR_String		= 0		; "AVR_String.asm"		gebruikt: AVR_16
;															zelf nog inlinken: 8535_UART en/of LCD_HD44780
;															(anders wordt er nog niets afgebeeld..)


.if Link_AVR_Core == 1
	.include "AVR_Core.asm"			; AVR Core
.endif
.if Link_AVR_16 == 1
	.include "AVR_16.asm"			; 16-bit bewerkingen en I/O
.endif
.if Link_AVR_Delay == 1
	.include "AVR_Delay.asm"		; Vertragingen in US, MS & Seconden
.endif
.if Link_AVR_Buffer == 1
	.include "AVR_Buffer.asm"		; Buffers in SRAM
.endif
.if Link_AVR_LED == 1
	.include "AVR_LED.asm"			; LED's
.endif
.if Link_8535_EEPROM == 1
	.include "8535_EEPROM.asm"		; EEPROM geheugen lezen & schrijven
.endif
.if Link_8535_AC == 1
	.include "8535_AC.asm"			; De Analog-Comparator
.endif
.if Link_8535_ADC == 1
	.include "8535_ADC.asm"			; De Analog-Digital-Converter
.endif
.if Link_8535_Timer0 == 1
	.include "8535_Timer0.asm"		; Timer0 constanten en macro's
.endif
.if Link_8535_Timer1 == 1
	.include "8535_Timer1.asm"		; Timer1 constanten en macro's
.endif
.if Link_8535_Timer2 == 1
	.include "8535_Timer2.asm"		; Timer2 constanten en macro's
.endif
.if Link_8535_Timers == 1
	.include "8535_Timers.asm"		; Timers 0, 1 & 2
.endif
.if Link_8535_UART == 1
	.include "8535_UART.asm"		; De UART RS232 COM:poort
.endif
.if Link_LCD_HD44780 == 1
	.include "LCD_HD44780.asm"		; Liquid Crystal Display HD44780
.endif
.if Link_AVR_String == 1
	.include "AVR_String.asm"		; Strings afbeelden (op COM: of LCD)
.endif


;nog mee bezig..
;.include "TWI_I2C.asm"					; Two Wire Interface (I2C)
;.include "KBD_Keyboard.asm"			; PC Toetsenbord
;.include "ETH_NE2000.asm"				; NE2000 compatible ethernet controller
