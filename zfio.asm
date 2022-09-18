;;; ---------------------------------------------------- 
;;; SAVE/LOAD DICTIONARY TO/FROM TAPE
;;; ----------------------------------------------------
defcode 'WLOAD',5,0,WLOAD
	exx
	xor	a
	call	0212H
	;; Skip BASIC leader
	call	0296H
	call	0314H		; Ignore d3d3
	call	0314H		; Ignore d3'F'
	call	0314H		; Read vLATEST into hl
	ld	(vLATEST), hl
	call	0314H		; Read vHERE
	ld	(vHERE), hl
	;; Load dictionary
	ex	de, hl
	ld	hl, SECUSER
wlblock	push	hl
	push	de
	ex	de, hl
	xor	a
	sbc	hl, de
	inc	h
	dec	h
	jr	NZ, wl255
	inc	l
	dec	l
	jr	NZ, wlless
	pop	de
	pop	hl
	call	01f8H
	exx
	jp	(iy)
wl255	ld	b, 0xff
wltop	pop	de
	pop	hl
wlloop	call	0235h
	ld	(hl), a
	inc	hl
	djnz	wlloop
	jr	wlblock
wlless	ld	b, l
	jr	wltop
defcode 'WSAVE',5,0,WSAVE
	exx
	;; BASIC leader
	or	a
	call	0212H
	call	0287H
	ld	a, 0xd3
	call	0264H
	ld	a, 0xd3
	call	0264H
	ld	a, 0xd3
	call	0264H
	ld	a, 'F'
	call	0264H
	;; 
	ld	hl, (vLATEST)
	ld	de, (vHERE)
	ld	a, l
	call	0264H
	ld	a, h
	call	0264H
	ld	a, e
	call	0264H
	ld	a, d
	call	0264H
	;; Save dictionary
	ld	hl, SECUSER
	ld	de, (vHERE)
wsblock	push	hl
	push	de
	ex	de, hl
	or	a
	sbc	hl, de
	inc	h
	dec	h
	jr	NZ, ws255
	inc	l
	dec	l
	jr	NZ, wsless
	pop	de
	pop	hl
	;; BASIC Tailer
	ld	a, 0x00
	call	0264H
	ld	a, 0x00
	call	0264H
	call	01f8H
	exx
	jp	(iy)
ws255	ld	b, 0xff
wstop	pop	de
	pop	hl
wsloop	ld	a, (hl)
	call	0264H
	inc	hl
	djnz	wsloop
	jr	wsblock
wsless	ld	b, l
	jr	wstop
;;; ---------------------------------------------------- 
;;; INPUT PARSING, DICTIONARY SEARCH
;;; ----------------------------------------------------
defcode 'FIND',4,0,FIND
	ld	a,(vSTATE)
	cp	1		; In step 1 compile mode?
	jr	NZ, ffind	; No: search word/number
	jp	(iy)
ffind	exx
	ld	hl, WORDFLG	; Used to signal word/lit
	ld	(hl), 0x0	; Reset before search
	ld	de, WORDBUF+1	; Check for literal string
	ld	a, (de)
	cp	0x22
	jr	Z, fstr		; Yes 
	ld	hl, vLATEST	; No: search dictionary
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
	ld	a, (vSTATE)	; Is state INTERPRETING?
	inc	a
	dec	a
	jr	Z, fmlen	; Yes: compare len w/o flag
	ld	a, (hl)		; i.e. unhide words
	and	a, f_msk
	cp	b
	jr	NZ, fnext	; Check next word
	jr	fmatch
fmlen	ld	a, (hl)		; No: compare len w flag
	cp	b		; i.e. hide words
	jr	NZ, fnext
fmatch	inc	de
	inc	hl
	ld	a, (de)
	cp	(hl)
	jr	NZ, fnext
	djnz	fmatch
found	jr	fdone		; Leave hl on stack
fnext	pop	hl
	jr	flast
fstr	ld	hl, WORDBUF	; Copy word to user mem w/o
	ld	c, (hl)		; opening double quote
	dec	c
	ld	b, 0x00
	ld	de, (vHERE)
	push	de
	inc	hl
	inc	hl
	ldir
	ld	(vHERE), de
	ld	hl, WORDFLG	; Signal a literal
	ld	(hl), f_lit
	jr	fdone
notfd	pop	hl		; Not a word -> a number
	ld	hl, WORDBUF+1	; P+C convention
	call	1e5aH		; Convert to hex in DE
	ld	hl, WORDFLG	; Signal a literal
	ld	(hl), f_lit
	ex	de, hl
	push	hl
fdone	exx
	jp	(iy)
;;; ----------------------------------------------------
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
;;; ----------------------------------------------------
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
;;; ----------------------------------------------------
defcode	'TYPE',4,0,TYPE	
	exx
	pop	hl
	call	28a7H
	ld	a, 0x20
	call	0033H
	exx
	jp	(iy)
;;; ----------------------------------------------------
defcode	'CR',2,0,CARRTN
	ld	(SAVEBC), bc
	ld	a, 0x0d
	call	0033H
	ld	bc, (SAVEBC)
	jp	(iy)
;;; ----------------------------------------------------
defcode 'PROMPT',6,0,PROMPT
	ld	(SAVEBC), bc
	ld	hl, OK
	call	2f0aH
	ld	bc, (SAVEBC)
	jp	(iy)
;;; 
	
