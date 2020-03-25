;;-----------------------------------------------
;;--- EEPROM.
;;--- I2C Slave LCD User Commands
;;----------------------------------------------\
;.equ EOT = $FF									; End Of Table symbool
;.ESEG                             				; het EEPROM-segment aanspreken
;; Command-code		Aantal Data-bytes
;LCD_CommandCodes:
;	.db $00, 		1							; LCD character lineprint
;	.db $01,		0							; LCD-cursor naar volgende regel (CrLf)
;	.db $02,		0							; LCD-cursor Home
;	.db $03,		0							; LCD-cursor naar EndOfLine
;	.db $04,		1							; LCD print hex.nibble (b3-0)
;	.db $05,		1							; LCD print hex.byte
;	.db $06,		2							; LCD print hex.word
;	.db $07,		0							; LCD Scroll-Up
;	.db $08,		0							; LCD Backspace
;	.db $09,		0							; LCD Delete
;	.db $0A,		1							; LCD Insert character
;	.db $0B,		0							; LCD pijl omhoog
;	.db $0C,		0							; LCD pijl omlaag
;	.db $0D,		0							; LCD pijl naar links
;	.db $0E,		0							; LCD pijl naar rechts
;	.db $0F,		1							; LCD Fill
;	.db $10,		2							; LCD Clear Line from (X,Y)
;	.db $11,		0							; LCD SplashScreen
;	.db $12,		2							; LCD Set Cursor (X,Y)
;	.db EOT,		EOT							; End of Table marker
;;----------------------------------------------/
