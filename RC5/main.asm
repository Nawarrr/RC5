;
; RC5.asm
; 
; Author : Abdelrahman Medhat Saad Nawar

.EQU ROUNDS =  8
.EQU DATA_SIZE = 0x01
.EQU DATA_IN = 0x0280
.EQU ENC_DATA = 0x0400
.EQU DEC_DATA = 0x0500
.EQU Ko = 0x0200
.EQU So = 0x0210

; Macros

.macro ROTL 
		TST @2
		BREQ ZEROL
	ROTL_LOOP:
		clc
		SBRC @0 , 7
		SEC
		ROL @1
		ROL @0
		DEC @2
		BRNE ROTL_LOOP
	ZEROL:
		nop
.endmacro


.macro ROTR
		TST @2
		BREQ ZEROR
	ROTR_LOOP:
		clc
		SBRC @1 , 0
		SEC
		ROR @0
		ROR @1
		DEC @2
		BRNE ROTR_LOOP
	ZEROR:
		nop
.endmacro




;DATA SAMPLE 
	ldi r16, 0x69
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
	; User Input Data
	sts 0x0280, r16
	sts 0x0281, r16
	sts 0x0282, r16
	sts 0x0283, r16


KEY_EXP:
	ldi Zl , low(So)  ; Loading address of So in Z
	ldi Zh , high(So) 
	ldi r16 , low(0xB7E1) ; loading Pw in r17 r16 
	ldi r17 , high(0xB7E1)
	st  Z  , r16    ; Storing Pw as So 
	std  Z+1  , r17
	ldi r18, low(0x9E37)	; Qw in Registers  r19 r18 
	ldi r19, high(0x9E37)	
	ldi r20 , 17        ; number of iterations
	LOOP_K1 :
		ld r16 , Z+ ; loading S[i-1] in r17  r16
		ld r17 , Z+
		add r16 , r18 ; adding S[i-1] to Qw
		adc r17  , r19 
		st z , r16 ; Storing in the next location
		std z+1 , r17 
		dec r20
		brne LOOP_K1
	ldi Yl , LOW(Ko) ; Loading address of Ko in Y
	ldi Yh , HIGH(Ko)
	ldi Zl , low(So)  ; Loading address of So in Z
	ldi Zh , high(So)
	clr R0 ; A in R0 and R1
	clr R1
	clr R2 ; B in R2 and R3
	clr R3
	ldi R25 , 54
	LOOP_K2:
		add R0 , R2 ; A = A + B
		adc R1 , R3
		ld R4 , Z   ; Loading Si to R4,R5
		ldd R5 , Z+1
		add R0 , R4 ; A = Si + A
		adc R1 , R5
		ldi R22 , 3 ; Rotation Counter
		ROTL R0 , R1 , R22 ; Rotating A Left 3 times
		st Z , R0 ; Storing A in S[i]
		std Z+1 , R1 
		add R2 , R0 ; B = B + A
		adc R3 , R1
		mov R22, R2 ; Setting Rotation Counter
		andi R22,0x0F
		ld R4 , Y ; Loading L[i]
		ldd R5 , Y+1
		add R2 , R4 ; B = L[i] + B
		adc R3 , R5
		ROTL R2,R3,R22
		st Y , R2 ; Storing B in L[i]
		std Y+1 , R3
		;;;;; Checking if exceeding the S array (mod)
		call I_RESET
		;;;;; Checking if exceeding the L array (mod)
		call J_RESET
 
		dec R25
		brne LOOP_K2

ENCRYPTION:

	ldi yl , LOW(DATA_IN) ; Pointer on the start of input data
	ldi yh , HIGH(DATA_IN) 
	ldi xl , LOW(ENC_DATA) ; Pointer on the Envrypted Data location
	ldi xh , HIGH(ENC_DATA)
 	ldi R25 , DATA_SIZE 
DATA_ENCRY:
	ldi zl , LOW(So) ; Pointer on So
	ldi zh , HIGH(So)
	ld R16 , y+ ; Loading A in R16, R17
	ld R17 , y+ 
	ld R18 , y+ ; Loading B in R18 , R19
	ld R19 , y+
	ld R22 , z+ ; Loading S[0]
	ld R23 , z+
	add R16 , R22 ; A + S[0]
	adc R17 , R23 
	ld R22 , z+  ; Loading S[1]
	ld R23 , z+
	add R18 , R22 ; B + S[1]
	adc R19 , R23
	ldi R24 , ROUNDS ; Counter for encryption rounds

ENCRYPTION_ROUND : 
	EOR R16 , R18 ; A XOR B
	EOR R17 , R19
	MOV R20 , R18 ; Taking the lowest 4 bits of B  as the counter
	ANDI R20 , 0x0F
	ROTL R16 , R17 , R20 
	ld R22 , z+ ; Loading S[2i]
	ld R23 , z+
	add R16 ,R22 ; A = A + S[2i] 
	adc R17 , R23
	;;;
	EOR R18 , R16 ; B XOR A
	EOR R19 , R17
	MOV R20 , R16 ; Taking the lowest 4 bits of A  as the counter
	ANDI R20 , 0x0F
	ROTL R18 , R19 , R20
	ld R22 , z+ ; Loading S[2i + 1]
	ld R23 , z+
	add R18 , R22 ; B = B + S[2i + 1]
	adc R19 , R23
	dec R24 ; Decrementing the branch rounds counter
	brne ENCRYPTION_ROUND
	st  x+ , R16 
	st  x+ , R17 
	st  x+ , R18 
	st  x+ , R19 
	dec R25 ; Decrementing the input data size counter
	brne DATA_ENCRY

DECRYPTION:
	ldi xl , LOW(ENC_DATA)
	ldi xh , HIGH(ENC_DATA)
	ldi yl , LOW(DEC_DATA) ; Pointer on the start of input data
	ldi yh , HIGH(DEC_DATA) 
 	ldi R25 , DATA_SIZE 

DATA_DECRY:
	ldi zl , LOW(0x234) ; Last location of S array
	ldi zh , HIGH(0x234).
	ldi R24 , ROUNDS ; Counter for Decryption rounds
	ld R16 , x+ ;Loading A from Encrypted Data
	ld R17 , x+
	ld R18 , x+	 ;Loading B from Envrypted Data
 	ld R19 , x+
DECRYPTION_ROUND : 
	ld R23 , -z  ;Loading needed S 
	ld R22 , -z 
	sub R18, R22 ; B = B - S
	sbc R19 , R23 
	MOV R20, R16 ; Taking A lowest 4 bits as a rotation counter
	ANDI R20 , 0x0F
	ROTR R18 , R19 , R20
	EOR R18 , R16 ; B XOR A
	EOR R19 , R17
	;;;
	ld R23 , -z  ;Loading needed S 
	ld R22 , -z 
	sub R16  , R22 ; A = A - S
	sbc R17 ,  R23
	MOV R20, R18 ; Taking A lowest 4 bits as a rotation counter
	ANDI R20 , 0x0F
	ROTR R16 , R17 , R20
	EOR R16 , R18 ; A XOR B
	EOR R17 , R19
	dec R24
	brne DECRYPTION_ROUND 
	ld R23 , -z  ;Loading needed S 
	ld R22 , -z 
	sub R18, R22 ; B = B - S
	sbc R19 , R23 
	ld R23 , -z  ;Loading needed S 
	ld R22 , -z
	sub R16  , R22 ; A = A - S
	sbc R17 ,  R23
	st  y+ , R16 
	st  y+ , R17 
	st  y+ , R18 
	st  y+ , R19
	dec R25
	brne DATA_DECRY
		
 
I_RESET :
	inc zl ; We increment twice as the counter counts 16 bit values (2 Locations)
	inc zl
	ldi r20, 0x34 ;Load last location in R20
	cpse zl , r20 ; comparing the low bites as the higher bytes won't-
				  ;change (lower bits are enough to represent the diff between the first and last locations)
	ret	
	ldi zl , LOW(So); return to 0x210
	ret
J_RESET:
	inc yl ; We increment twice as the counter counts 16 bit values (2 Locations)
	inc yl
	ldi R20 , 0x0C ;Load last location in R20
	cpse yl , R20  ; comparing the low bites as the higher bytes won't-
				   ;change (lower bits are enough to represent the diff between the first and last locations)
	ret
	clr yl ; return to 0x200
	ret



