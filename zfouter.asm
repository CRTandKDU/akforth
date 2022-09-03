	;; ---------------------------------------------------- 
	;; OUTER INTERPRETER/COMPILER
	;; ----------------------------------------------------
	defconstant '0',1,0,ZERO,0x0
	defconstant 'TRUE',4,0,TRUE,0x1
	defconstant 'FALSE',5,0,FALSE,0x0	
	;; ----------------------------------------------------
	defvar 'LATEST',6,0,LATEST,nPROMPT
	defvar 'HERE',4,0,HERE,SECUSER
	defvar 'STATE',5,f_hid,STATE,0x0
	;; ----------------------------------------------------
	defcode 'COLD',4,0,COLD
	ld	hl, nPROMPT
	ld	(vLATEST), hl
	ld	hl, SECUSER
	ld	(vHERE), hl
	ld	hl, 0x0
	ld	(vSTATE), hl
	jp	(iy)
	;; ----------------------------------------------------
	defcode 'INTERPRET',9,0,INTERPRET
	ld	a, (vSTATE)
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
	ld	de, (vLATEST)
	ld	hl, (vHERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	dec	hl
	ld	(vLATEST), hl
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
	ld	(vHERE), hl
	ld	a, 2
	ld	(vSTATE), a
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
	ld	hl, (vHERE)
	pop	de		; Find code address in header
	ex	de, hl
	push	de
	CFA
	pop	de
	ex	de, hl		; Now in de, store it vHERE
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(vHERE), hl
	jp	(iy)
comp3	ld	de, LIT		; Literal compile to LIT <lit>
	ld	hl, (vHERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	pop	de
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(vHERE), hl
	jp	(iy)
	;;
	defcode ';',1,f_imm,SEMICOLON
	ld	de, SEMI
	ld	hl, (vHERE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(vHERE), hl
	ld	a, 0
	ld	(vSTATE), a
	jp	(iy)
	;; 
	defcode	':',1,0,COLON
	ld	a, 1
	ld	(vSTATE), a
	jp	(iy)
	;; 
