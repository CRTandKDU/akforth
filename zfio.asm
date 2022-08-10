	;; ----------------------------------------------------
	defcode 'FIND',4,0,FIND
	ld	(SAVEBC), bc
	ld	hl, LATEST
flast	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	push	hl		; Keep current ptr
	ld	a,(hl)		; Is hl==0x00?
	inc	hl
	inc	a
	dec	a
	jr	NZ, ftest
	ld	a,(hl)		; Is hl==0x00?
	inc	a
	dec	a
	jr	Z, notfd	; Not found in dictionary
ftest	ld	de, WORDBUF	; Compare length (Pascal)
	inc	hl
	ld	a, (de)
	ld	b, a
	cp	(hl)
	jr	NZ, fnext	; Check next word
fmatch	inc	de
	inc	hl
	ld	a, (de)
	cp	(hl)
	jr	NZ, fnext
	djnz	fmatch
found	jr	fdone		; Leave hl on stack
fnext	pop	hl
	jr	flast
notfd	pop	hl
	ld	l, 0
	ld	h, 0
	push	hl
fdone	ld	bc, (SAVEBC)	
	jp	(iy)
	;; ----------------------------------------------------
	defcode 'INLINE',6,0,INLINE
	exx
	ld	hl, BUFFER
	ld	(40A7H), hl
	ld	(BUFP), hl	; Clears BUFFER
	push	hl
	pop	de
	inc	de
	ld	(hl), 0
	ld	bc, 254
	ldir
	call	0361H
	exx
	jp	(iy)
	;; ----------------------------------------------------
	defcode 'WORD',4,0,WORD
	exx
	ld	hl, (BUFP)
	ld	a,(hl)
	inc	a
	dec	a
	jr	NZ, wskip
	ld	h, 0		; Push 0 on stack, end of line reached
	ld	l, 0
	push	hl
	jr	wdone
wskip	ld	b, 0
	ld	c, 0x20
	ld	a, c
skipsp
	cp	(hl)
	jr	NZ, skipout
	inc	hl
	jr	skipsp
skipout
	push	hl
count	
	inc	b
	inc	hl
	ld	a, (hl)
	cp	c
	jr	z, cntout
	inc	a
	dec	a
	jr	NZ,count	; Still more chars
	dec	hl
cntout
	inc	hl
	ld	(BUFP), hl	; Store for next token
	ld	de, WORDBUF	; Copy token to WORDBUF Pascal+C
	ld	a,b
	ld	(de), a
	inc	de
	pop	hl
	ld	c, b
	ld	b, 0
	ldir
	xor	a
	ld	(de), a
	ld	a, (WORDBUF)	; Push length of word on stack
	ld	l, a
	ld	h, 0
	push 	hl
wdone	exx
	jp	(iy)
	;; ----------------------------------------------------
	defcode 'PROMPT',6,0,PROMPT
	ld	(SAVEBC), bc
	ld	hl, OK
	call	2f0aH
	ld	bc, (SAVEBC)
	jp	(iy)
	;; 
	
