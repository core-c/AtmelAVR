
; speciale scan-codes ------------------
.equ scExtended	= $C0; van compaq-kb
.equ scKeyUp	= $E0
.equ scLShift	= $24
.equ scRShift	= $B2
.equ scLCtrl	= $28
.equ scRCtrl	= $28 ;scExtended scRCtrl (scExtended scKeyUp scRCtrl)
.equ scLAlt		= $22
.equ scRAlt		= $22 ;scExtended scRAlt (scExtended scKeyUp scRAlt)
.equ scESC		= $EC
.equ scEnter	= $B4
.equ scTAB		= $1A
.equ scBS		= $CC



;--- Het begin van het EEPROM-segment --
.ESEG									; EEPROM
.ORG $0000
; De ASCII-codes voor toetsen met een 1-byte scancode (bij indrukken)
ScanCodes1:
	;Scancode___ASCII-code
	; Letters
	.db $38,	$61	;(a)
	.db $64,	$62	;(b)
	.db $42,	$63	;(c)
	.db $46,	$64	;(d)
	.db $48,	$65	;(e)
	.db $56,	$66	;(f)
	.db $68,	$67	;(g)
	.db $66,	$68	;(h)
	.db $86,	$69	;(i)
	.db $76,	$6A	;(j)
	.db $84,	$6B	;(k)
	.db $96,	$6C	;(l)
	.db $74,	$6D	;(m)
	.db $62,	$6E	;(n)
	.db $88,	$6F	;(o)
	.db $9A,	$70	;(p)
	.db $2A,	$71	;(q)
	.db $5A,	$72	;(r)
	.db $36,	$73	;(s)
	.db $58,	$74	;(t)
	.db $78,	$75	;(u)
	.db $54,	$76	;(v)
	.db $3A,	$77	;(w)
	.db $44,	$78	;(x)
	.db $6A,	$79	;(y)
	.db $34,	$7A	;(z)
	; Cijfers
	.db $8A,	$30	;(0)
	.db $2C,	$31	;(1)
	.db $3C,	$32	;(2)
	.db $4C,	$33	;(3)
	.db $4A,	$34	;(4)
	.db $5C,	$35	;(5)
	.db $6C,	$36	;(6)
	.db $7A,	$37	;(7)
	.db $7C,	$38	;(8)
	.db $8C,	$39	;(9)
	; anders, maar wel een af te beelden teken
	.db $9C,	$2D	;(-)
	.db $AA,	$3D	;(=)
	.db $52,	$20	;( ) spatie
	.db $A8,	$5B	;([)
	.db $B6,	$5C	;(])
	.db $1C,	$60	;(`)
	.db $A4,	$27	;(')
	.db $82,	$2C	;(,)
	.db $92,	$2E	;(.)
	.db $98,	$3B	;(;)
	.db $94,	$2F	;(/)
	.db $BA,	$00	;(\) ?
	; aflsuiter van deze tabel (word-aligned)
	.db $00,	$00


ScanCodes1_Shifted:
	;___ASCII___ASCII
	; Cijfers
	.db $30,	$29	;())
	.db $31,	$21	;(!)
	.db $32,	$40	;(@)
	.db $33,	$23	;(#)
	.db $34,	$24	;($)
	.db $35,	$25	;(%)
	.db $36,	$5E	;(^)
	.db $37,	$26	;(&)
	.db $38,	$2A	;(*)
	.db $39,	$28	;(()
	; andere af te beelden tekens
	.db $2D,	$5F	;(_)
	.db $3D,	$2B	;(+)
	.db $5B,	$7B	;({)
	.db $5C,	$7D	;(})
	.db $60,	$00	;(~) ?
	.db $27,	$22	;(")
	.db $2C,	$3C	;(<)
	.db $2E,	$3E	;(>)
	.db $3B,	$3A	;(:)
	.db $2F,	$7C	;(?) !
;	.db $BA,	$00	;(|) ??
	; aflsuiter van deze tabel (word-aligned)
	.db $00,	$00




;--- Het begin van het CODE-segment ----
.CSEG									; FLASH/PROGRAM
