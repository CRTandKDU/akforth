;; ----------------------------------------------------
defcode	'CFA',4,0,TOCFA
	pop	hl
	CFA
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	',',1,0,COMMA
	pop	de
	ld	hl, (vHERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(vHERE), hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'IMMEDIATE',9,0,IMMEDIATE
	ld	hl, (vLATEST)
	inc	hl
	inc	hl
	ld	a, f_imm
	xor	(hl)
	ld	(hl), a
	jp	(iy)
;; ----------------------------------------------------
defword	"'",1,0,TICK
	defw	WORD
	defw	FIND
	defw	TOCFA
	defw	SEMI
;; ----------------------------------------------------

	
	
	
