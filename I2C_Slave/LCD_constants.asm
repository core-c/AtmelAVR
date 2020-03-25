;.cseg

;--- De teksten in programma-geheugen --
Line0:	.db	"AVR @ 4.0000000 MHz.", EOS_Symbol
Line1:	.db	"LCD @ 8-bit", EOS_Symbol
Line2:	.db	"I2C @ Slave mode", EOS_Symbol		; regel bevat zelf-gedefinieerde tekens
Line3:	.db	"<------ Data ------>", EOS_Symbol


;--- Zelf-gedefinieerde tekens in programma-geheugen --
;          	  ___12345
;CChar0:	.db	0b00000000;1
;		.db	0b00000000;2
;		.db	0b00010000;3
;		.db	0b00010000;4
;		.db	0b00010000;5
;		.db	0b00010000;6
;		.db	0b00000000;7
;		.db	0b00000000;|
;CChar1:	.db	0b00000000
;		.db	0b00000000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00000000
;		.db	0b00000000
;CChar2:	.db	0b00000000
;		.db	0b00000000
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00000000
;		.db	0b00000000
;CChar3:	.db	0b00000000
;		.db	0b00000000
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00000000
;		.db	0b00000000
;CChar4:	.db	0b00000000
;		.db	0b00000000
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00000000
;		.db	0b00000000

; Omdat het Flash/programma-geheugen per word is te adresseren
; dienen de bytes voor de patronen ook per word worden opgeslagen.
CChar0:	.dw	0b0000000000000000;2,1
		.dw	0b0001000000010000;4,3
		.dw	0b0001000000010000;6,5
		.dw	0b0000000000000000;8,7
CChar1:	.dw	0b0000000000000000
		.dw	0b0001100000011000
		.dw	0b0001100000011000
		.dw	0b0000000000000000
CChar2:	.dw	0b0000000000000000
		.dw	0b0001110000011100
		.dw	0b0001110000011100
		.dw	0b0000000000000000
CChar3:	.dw	0b0000000000000000
		.dw	0b0001111000011110
		.dw	0b0001111000011110
		.dw	0b0000000000000000
CChar4:	.dw	0b0000000000000000
		.dw	0b0001111100011111
		.dw	0b0001111100011111
		.dw	0b0000000000000000
