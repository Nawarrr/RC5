;
; RC5.asm
;
; Author : Abdelrahman Medhat Saad Nawar
;
.EQU ROUNDS =  8
.EQU DATA_SIZE = 0x01
.EQU DATA_IN = 0x0280
.EQU ENC_DATA = 0x0400
.EQU Ko = 0x0200
.EQU So = 0x0210




;DATA SAMPLEEEEEEEEEEEEEEEEEEE FROM FADYYYYY
	sts 0x0200, r16
	sts 0x0201, r16
	sts 0x0202, r16
	sts 0x0203, r16
	sts 0x0204, r16
	sts 0x0205, r16
	sts 0x0206, r16
	sts 0x0207, r16
	sts 0x0208, r16
	sts 0x0209, r16
	sts 0x020A, r16
	sts 0x020b, r16
	ldi r16,0xFF
	; user data
	sts 0x0280, r16
	sts 0x0281, r16
	sts 0x0282, r16
	sts 0x0283, r16


KEY EXP:
	ldi xl , low(So)  ; Loading address of So in X
	ldi xh , high(So) 
	ldi r16 , low(0xB7E1) ; loading Pw in r17 r16 
	ldi r17 , high(0xB7E1)
	st  x+  , r16    ; Storing Pw as So 
	st  x+  , r17
	ldi r18, low(0x9E37)	; Qw in Registers  r19 r18 
	ldi r19, high(0x9E37)	
	ldi r20 , 54        ; number of iterations
	LOOP :
		ld r16 , x-2 ; loading S[i-1] in r17  r16
		ld r17 , x-1
		ADD r16 , r18 ; adding S[i-1] to Qw
		ADC r17 , r19 
		st x+ , r16 ; Storing in the next location
		st x+ , r17 
		dec r20
		brne LOOP
		re



ROTL :
;Using R1 and R2 , R22 as counter
	ROTL LOOP:
		SBRC R1 , 7
		SEC
		ROL R2
		ROL R1
		DEC R22
		BRNE ROTL LOOP
	
	
RORL:
;Using R1 and R2 , R22 as counter
	RORL LOOP:
		SBRC R1 , 0
		SEC
		ROR R2
		ROR R1
		DEC R22
		BRNE RORL LOOP

