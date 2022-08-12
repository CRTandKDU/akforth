	defcode 'INTERPRET',9,0,INTERPRET
	ld	a, (STATE)
	inc	a
	dec	a
	jr	NZ, comp1	; Mode is not INTERPRET, jump
	ld	a, (WORDFLG)	; Mode is INTERPRET
	and	f_lit		; Is literal?
	jp	Z, EXECUTE	;   No: execute
	jp	(iy)		;   Yes: literal already on TOS
comp1	cp	1		; Creating new word header?
	jr	NZ, comp2
	exx
	ld	de, (LATEST)
	ld	hl, (HERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	dec	hl
	ld	(LATEST), hl
	ld	a, (WORDBUF)
	inc	hl
	inc	hl
	ld	(hl), a
	inc	hl
	ex	de, hl
	ld	hl, WORDBUF+1
	ld	c, a
	ld	b, 0
	ldir
	ex	de, hl
	ld	de, DOCOL
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	ld	a, 2
	ld	(STATE), a
	exx
	jp	(iy)
comp2	ld	a, (WORDFLG)
	and	f_lit
	jp	NZ, comp3		; Is this a LIT?
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)		; Length+Flags byte
	and	f_imm
	jp	NZ, EXECUTE
	ld	hl, (HERE)
	pop	de		; Find code address in header
	ex	de, hl
	push	de
	CFA
	pop	de
	ex	de, hl		; Now in de, store it HERE
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	jp	(iy)
comp3	ld	de, LIT		; Literal compile to LIT <lit>
	ld	hl, (HERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	pop	de
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	jp	(iy)
	;;
	defcode ';',1,f_imm,SEMICOLON
	ld	de, SEMI
	ld	hl, (HERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	ld	a, 0
	ld	(STATE), a
	jp	(iy)
	;; 
	defcode	':',1,0,COLON
	ld	a, 1
	ld	(STATE), a
	jp	(iy)
	;; 
