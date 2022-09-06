;;; ----------------------------------------------------
defcode	'CFA>',4,0,TOCFA
	pop	hl
	CFA
	push	hl
	jp	(iy)
;;; ----------------------------------------------------
defcode	',',1,0,COMMA
	pop	de
	ld	hl, (vHERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(vHERE), hl
	jp	(iy)
;;; ----------------------------------------------------
defcode	'IMMEDIATE',9,0,IMMEDIATE
	ld	hl, (vLATEST)
	inc	hl
	inc	hl
	ld	a, f_imm
	xor	(hl)
	ld	(hl), a
	jp	(iy)
;;; ----------------------------------------------------
defword	"'",1,0,TICK
	defw	WORD
	defw	FIND
	defw	TOCFA
	defw	SEMI
;;; ----------------------------------------------------
;;; IF ELSE THEN implemented in FORTH
;;; ----------------------------------------------------
;;; <TOS> IF <words> THEN <words>
;;; <TOS> IF <words> ELSE <words> THEN <words>
;;; ----------------------------------------------------
defword	'IF',2,f_imm,CTLIF
	defw	LIT
	defw	ZBRANCH
	defw	COMMA
	defw	HERE
	defw	FETCH
	defw	ZERO
	defw	COMMA
	defw	SEMI
defword 'THEN',4,f_imm,CTLTHEN
	defw	HERE
	defw	FETCH
	defw	SWAP
	defw	STORE
	defw	SEMI
defword	'ELSE',4,f_imm,CTLELSE
	defw	LIT
	defw	UBRANCH
	defw	COMMA
	defw	HERE
	defw	FETCH
	defw	ZERO
	defw	COMMA
	defw	SWAP
	defw	HERE
	defw	FETCH
	defw	SWAP
	defw	STORE
	defw	SEMI
;;; ----------------------------------------------------
;;; LOOPS implemented in FORTH
;;; ----------------------------------------------------
;;; BEGIN <loop-words> <TOS> UNTIL
;;; BEGIN <TOS> WHILE <loop-words> REPEAT
;;; ----------------------------------------------------
defword	'BEGIN',5,f_imm,CTLBEG
	defw	HERE
	defw	FETCH
	defw	SEMI
defword	'UNTIL',5,f_imm,CTLUNTIL
	defw	LIT
	defw	ZBRANCH
	defw	COMMA
	defw	COMMA
	defw	SEMI
defword 'WHILE',5,f_imm,CTLWHILE
	defw	LIT
	defw	ZBRANCH
	defw	COMMA
	defw	HERE
	defw	FETCH
	defw	ZERO
	defw	COMMA
	defw	SEMI
defword	'REPEAT',6,f_imm,CTLREPEAT
	defw	LIT
	defw	UBRANCH
	defw	COMMA
	defw	SWAP
	defw	COMMA
	defw	HERE
	defw	FETCH
	defw	SWAP
	defw	STORE
	defw	SEMI
	
	
	
