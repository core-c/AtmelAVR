; speciale scan-codes ------------------
.equ scExtended	= $E0
.equ scKeyUp	= $F0
.equ scLShift	= $12
.equ scRShift	= $59
.equ scLCtrl	= $14
.equ scRCtrl	= $14 ;scExtended scRCtrl	(scExtended scKeyUp scRCtrl)
.equ scLAlt		= $11
.equ scRAlt		= $11 ;scExtended scRAlt	(scExtended scKeyUp scRAlt)
.equ scArrowUp	= $75 ;scExtended scArrowUp	(scExtended scKeyUp scArrowUp)
.equ scArrowDn	= $72 ;scExtended scArrowDn	(scExtended scKeyUp scArrowDn)
.equ scArrowL	= $6B ;scExtended scArrowL	(scExtended scKeyUp scArrowL)
.equ scArrowR	= $74 ;scExtended scArrowR	(scExtended scKeyUp scArrowR)
.equ scESC		= $76
.equ scEnter	= $5A
.equ scBS		= $66
.equ scCAPSL	= $58
.equ scF1		= $05
.equ scF2		= $06
.equ scF3		= $04
.equ scF4		= $0C
.equ scF5		= $03
.equ scF6		= $0B
.equ scF7		= $83
.equ scF8		= $0A
.equ scF9		= $01
.equ scF10		= $09
.equ scF11		= $78
.equ scF12		= $07
.equ scTAB		= $0D
.equ scLWin		= $1F ;scExtended scLWin	(scExtended scKeyUp scLWin)
.equ scRWin		= $27 ;scExtended scRWin	(scExtended scKeyUp scRWin)
.equ scContext	= $2F ;scExtended scContext	(scExtended scKeyUp scContext)
.equ scINS		= $70 ;scExtended scINS		(scExtended scKeyUp scINS)
.equ scDEL		= $71 ;scExtended scDEL		(scExtended scKeyUp scDEL)
.equ scHome		= $6C ;scExtended scHome	(scExtended scKeyUp scHome)
.equ scEnd		= $69 ;scExtended scEnd		(scExtended scKeyUp scEnd)
.equ scPgUp		= $7D ;scExtended scPgUp	(scExtended scKeyUp scPgUp)
.equ scPgDn		= $7A ;scExtended scPgDn	(scExtended scKeyUp scPgDn)
;.equ scPrtSc	= E0,12, E0,7C				(E0,F0,7C, E0,F0,12)
.equ scScollL	= $7E
;.equ scPause	= E1,14,77, E1,F0,14, F0,77 (geen break scancode)
.equ scNUML		= $77
.equ scKPEnter	= $5A ;scExtended scKPEnter	(scExtended scKeyUp scKPEnter)
.equ scKPDiv	= $4A ;scExtended scKPDiv	(scExtended scKeyUp scKPDiv)


;toetsen die met een Ctrl-combinatie gedrukt kunnen worden
.equ scG		= $34
.equ scX		= $22
.equ scP		= $4D
.equ scO		= $44
.equ scU		= $3C
.equ scB		= $32
.equ scA		= $1C
.equ scW		= $1D
.equ sc1		= $16
.equ scDot		= $49


.ESEG									;--- Het begin van een EEPROM-segment ----  EEPROM
.ORG $0000								; beginadres = 0000
; De ASCII-codes voor toetsen met een
; 1-byte scancode (bij indrukken)
ScanCodes1:
	;Scancode___ASCII-code
	; Letters
	.db scA,	$61	;(a)
	.db scB,	$62	;(b)
	.db $21,	$63	;(c)
	.db $23,	$64	;(d)
	.db $24,	$65	;(e)
	.db $2B,	$66	;(f)
	.db scG,	$67	;(g)
	.db $33,	$68	;(h)
	.db $43,	$69	;(i)
	.db $3B,	$6A	;(j)
	.db $42,	$6B	;(k)
	.db $4B,	$6C	;(l)
	.db $3A,	$6D	;(m)
	.db $31,	$6E	;(n)
	.db scO,	$6F	;(o)
	.db scP,	$70	;(p)
	.db $15,	$71	;(q)
	.db $2D,	$72	;(r)
	.db $1B,	$73	;(s)
	.db $2C,	$74	;(t)
	.db scU,	$75	;(u)
	.db $2A,	$76	;(v)
	.db scW,	$77	;(w)
	.db scX,	$78	;(x)
	.db $35,	$79	;(y)
	.db $1A,	$7A	;(z)
	; Cijfers
	.db $45,	$30	;(0)
	.db sc1,	$31	;(1)
	.db $1E,	$32	;(2)
	.db $26,	$33	;(3)
	.db $25,	$34	;(4)
	.db $2E,	$35	;(5)
	.db $36,	$36	;(6)
	.db $3D,	$37	;(7)
	.db $3E,	$38	;(8)
	.db $46,	$39	;(9)
	; anders, maar wel een af te beelden teken
	.db $4E,	$2D	;(-)
	.db $55,	$3D	;(=)
	.db $29,	$20	;( ) spatie
	.db $54,	$5B	;([)
	.db $5B,	$5D	;(])
	.db $0E,	$60	;(`)
	.db $52,	$27	;(')
	.db $41,	$2C	;(,)
	.db scDot,	$2E	;(.)
	.db $4C,	$3B	;(;)
	.db $4A,	$2F	;(/)
	.db $5D,	$00	;(\) ? geen teken aanwezig in LCD-font
	; aflsuiter van deze tabel (word-aligned)
	.db $00,	$00




ScanCodesKP1:
	;Scancode___ASCII-code
	; KeyPad
	.db $7C,	$2A	;(*)
	.db $7B,	$2D	;(-)
	.db $79,	$2B	;(+)
	.db $71,	$2E	;(.)
	.db $70,	$30	;(0)
	.db $69,	$31	;(1)
	.db $72,	$32	;(2)
	.db $7A,	$33	;(3)
	.db $6B,	$34	;(4)
	.db $73,	$35	;(5)
	.db $74,	$36	;(6)
	.db $6C,	$37	;(7)
	.db $75,	$38	;(8)
	.db $7D,	$39	;(9)
	; aflsuiter van deze tabel (word-aligned)
	.db $00,	$00




ScanCodes1_Shifted:
	;___ASCII___ASCII shifted
	; Cijfers
	.db $30,	$29	;())	= shift 0
	.db $31,	$21	;(!)	= shift 1
	.db $32,	$40	;(@)	= shift 2
	.db $33,	$23	;(#)	= shift 3
	.db $34,	$24	;($)	= shift 4
	.db $35,	$25	;(%)	= shift 5
	.db $36,	$5E	;(^)	= shift 6
	.db $37,	$26	;(&)	= shift 7
	.db $38,	$2A	;(*)	= shift 8
	.db $39,	$28	;(()	= shift 9
	; andere af te beelden tekens
	.db $2D,	$5F	;(_)	= shift -
	.db $3D,	$2B	;(+)	= shift =
	.db $5B,	$7B	;({)	= shift [
	.db $5D,	$7D	;(})	= shift ]
	.db $60,	$00	;(~) ? geen teken aanwezig in LCD-font
	.db $27,	$22	;(")	= shift '
	.db $2C,	$3C	;(<)	= shift ,
	.db $2E,	$3E	;(>)	= shift .
	.db $3B,	$3A	;(:)	= shift ;
	.db $2F,	$3F	;(?) 	= shift /
;	.db $BA,	$00	;(|) !
	; aflsuiter van deze tabel (word-aligned)
	.db $00,	$00
;--------------------------------------/

; Keyboard response codes (KB -> Host)
.equ rcBATsuccessful	= $AA			; Basic Assurance Test
.equ rcError			= $FC
.equ rcResend			= $FE
.equ rcAcknowledge		= $FA

; Keyboard control codes (Host -> KB)
; Als het keyboard een commando ontvangt, reageert het met het terugzenden van een 'rcAcknowledge' ($FA).
; Als de host de bevestiging van het keyboard ontvangen heeft, kan de host een argument of volgend commando sturen.
; zie voor uitleg: http://panda.cs.ndsu.nodak.edu/%7Eachapwes/PICmicro/keyboard/atkeyboard.html
.equ ccReset					= $FF	; KB antwoordt met 'rcAcknowledge' en gaat in reset-mode
.equ ccResend					= $FE	; KB zendt laatst gezonden (non $FE) byte opnieuw
.equ ccSetDefault				= $F6	; KB in scanmode set 2, standaard typematic rate/delay op 10.9cps / 500ms
.equ ccDisable					= $F5	; KB stopt met scannen en wacht op volgende instructie
.equ ccEnable					= $F4	; Schakel het KB weer in en begin weer te scannen
.equ ccSetTypematicRateDelay	= $F3	; Host zend hierna nog 1 argument byte:
										;	bits[4-0]	Rate (cps)				bits[6-5]	Delay (s)
										;	$00			2.0						00b			0.25
										;	$01			2.1						01b			0.50
										;	$02			2.3						10b			0.75
										;	$03			2.5						11b			1.00
										;	$04			2.7
										;	$05			3.0
										;	$06			3.3
										;	$07			3.7
										;	$08			4.0
										;	$09			4.3
										;	$0A			4.6
										;	$0B			5.0
										;	$0C			5.5
										;	$0D			6.0
										;	$0E			6.7
										;	$0F			7.5
										;	$10			8.0
										;	$11			8.6
										;	$12			9.2
										;	$13			10.0
										;	$14			10.9
										;	$15			12.0
										;	$16			13.3
										;	$17			15.0
										;	$18			16.0
										;	$19			17.1
										;	$1A			18.5
										;	$1B			20.0
										;	$1C			21.8
										;	$1D			24.0
										;	$1E			26.7
										;	$1F			30.0
.equ ccReadID					= $F2	; KB antwoordt met 2 bytes: $AB $83
.equ ccSetScancodeSet			= $F0	; KB antwoordt met een 'rcAcknowledge'
										; waarna het 1 byte argument dient te worden gezonden door de host.
										; Het argument:	$00  KB antwoordt met een 'rcAcknowledge' & een byte die de huidige scancode set aangeeft
										; 				$01  stel in op scancode set 1, KB antwoordt met een 'rcAcknowledge'
										;				$02  stel in op scancode set 2, KB antwoordt met een 'rcAcknowledge'
										;				$03  stel in op scancode set 3, KB antwoordt met een 'rcAcknowledge'
.equ ccEcho						= $EE	; KB antwoordt met een $EE
.equ ccSetLEDs					= $ED	; Host zend hierna nog 1 argument byte:
										; bit[0] = Scroll Lock
										; bit[1] = Num Lock
										; bit[2] = Caps Lock
										; bits[7..3] altijd op 0 houden.



.CSEG									;--- Het begin van een CODE-segment ----  FLASH/PROGRAM
