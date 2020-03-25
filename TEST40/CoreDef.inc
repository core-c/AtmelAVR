
;--- Timer frequenties -----------------
.equ TIMERFREQ_CK1024	= (1<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock/1024 
.equ TIMERFREQ_CK256	= (1<<CS12 | 0<<CS11 | 0<<CS10)	; timerFrequentie = clock/256
.equ TIMERFREQ_CK64		= (0<<CS12 | 1<<CS11 | 1<<CS10)	; timerFrequentie = clock/64
.equ TIMERFREQ_CK8		= (0<<CS12 | 1<<CS11 | 0<<CS10)	; timerFrequentie = clock/8
.equ TIMERFREQ_CK		= (0<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock
.equ TIMERFREQ_OFF		= (0<<CS12 | 0<<CS11 | 0<<CS10)	; timer uitschakelen
;--- Timer Flags -----------------------
.equ TIMER1_OVERFLOW	= (1<<TOIE1)
.equ TIMER1_COMPAREA	= (1<<OCIE1A)
.equ TIMER1_COMPAREB	= (1<<OCIE1B)


;--- Hardware PWM-modes ----------------
.equ PWM_OFF	= (0<<PWM11  | 0<<PWM10)
.equ PWM_8BITS	= (0<<PWM11  | 1<<PWM10)
.equ PWM_9BITS	= (1<<PWM11  | 0<<PWM10)
.equ PWM_10BITS	= (1<<PWM11  | 1<<PWM10)
; COM1B1:COM1B0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareB)
.equ PWM_NON_INVERTED_1B	= (1<<COM1B1 | 0<<COM1B0)
.equ PWM_INVERTED_1B		= (1<<COM1B1 | 1<<COM1B0)
; COM1A1:COM1A0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareA)
.equ PWM_NON_INVERTED_1A	= (1<<COM1A1 | 0<<COM1A0)
.equ PWM_INVERTED_1A		= (1<<COM1A1 | 1<<COM1A0)
;
.equ PWM_8BITS_NON_INVERTED_1B	= (PWM_8BITS  | PWM_NON_INVERTED_1B)
.equ PWM_9BITS_NON_INVERTED_1B	= (PWM_9BITS  | PWM_NON_INVERTED_1B)
.equ PWM_10BITS_NON_INVERTED_1B	= (PWM_10BITS | PWM_NON_INVERTED_1B)
.equ PWM_8BITS_INVERTED_1B		= (PWM_8BITS  | PWM_INVERTED_1B)
.equ PWM_9BITS_INVERTED_1B		= (PWM_9BITS  | PWM_INVERTED_1B)
.equ PWM_10BITS_INVERTED_1B		= (PWM_10BITS | PWM_INVERTED_1B)
;
.equ PWM_8BITS_NON_INVERTED_1A	= (PWM_8BITS  | PWM_NON_INVERTED_1A)
.equ PWM_9BITS_NON_INVERTED_1A	= (PWM_9BITS  | PWM_NON_INVERTED_1A)
.equ PWM_10BITS_NON_INVERTED_1A	= (PWM_10BITS | PWM_NON_INVERTED_1A)
.equ PWM_8BITS_INVERTED_1A		= (PWM_8BITS  | PWM_INVERTED_1A)
.equ PWM_9BITS_INVERTED_1A		= (PWM_9BITS  | PWM_INVERTED_1A)
.equ PWM_10BITS_INVERTED_1A		= (PWM_10BITS | PWM_INVERTED_1A)
;
.equ PWM_8BITS_TOP	= 0b11111111		; De TOP-waarde voor 8-bits = 2^8 - 1	(HW-PWM)
.equ PWM_9BITS_TOP	= 0b111111111		; De TOP-waarde voor 9-bits = 2^9 - 1	(HW-PWM)
.equ PWM_10BITS_TOP	= 0b1111111111		; De TOP-waarde voor 10-bits = 2^10 - 1	(HW-PWM)
;--- Software PWM ----------------------
; COM1A1:COM1A0  HW pin PD5 (OC1A) output on CompareA Match
.equ PWM_COMPAREA_ACTION_OFF	= (0<<COM1A1 | 0<<COM1A0)	; geen actie op pin D5
.equ PWM_COMPAREA_ACTION_TOGGLE	= (0<<COM1A1 | 1<<COM1A0)	; toggle PinD5
.equ PWM_COMPAREA_ACTION_0		= (1<<COM1A1 | 0<<COM1A0)	; PinD5 op 0
.equ PWM_COMPAREA_ACTION_1		= (1<<COM1A1 | 1<<COM1A0)	; PinD5 op 1
; COM1B1:COM1B0  HW pin PD4 (OC1B) output on CompareB Match
.equ PWM_COMPAREB_ACTION_OFF	= (0<<COM1B1 | 0<<COM1B0)	; geen actie op pin D4
.equ PWM_COMPAREB_ACTION_TOGGLE	= (0<<COM1B1 | 1<<COM1B0)	; toggle PinD4
.equ PWM_COMPAREB_ACTION_0		= (1<<COM1B1 | 0<<COM1B0)	; PinD4 op 0
.equ PWM_COMPAREB_ACTION_1		= (1<<COM1B1 | 1<<COM1B0)	; PinD4 op 1

.equ PWM_16BITS_TOP	= 0b1111111111111111; De TOP-waarde voor 16-bits = 2^16 - 1	(SW-PWM)
.equ TOP			= PWM_16BITS_TOP	; De timer1 TOP-waarde
;---------------------------------------
