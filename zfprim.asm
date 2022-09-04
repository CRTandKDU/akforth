;; ----------------------------------------------------
defcode 'SKIP',4,0,SKIP
	jp	(iy)
;; ----------------------------------------------------
defcode '.',1,0,DOT
	ld	(SAVEBC), bc
	pop	hl
	call	0a9aH		; Move hl to acc
	call	0fbdH		; Convert to ascii
	call	2f0aH		; Print
	ld	a,0x20
	call	033H		; destroys de
	ld	bc, (SAVEBC)
	jp	(iy)
;; ---------------------------------------------------- 
;; MEMORY PRIMITIVES
;; ----------------------------------------------------
defcode	'C!',2,0,CSTR
	pop	hl
	pop	de
	ld	(hl), e
	jp	(iy)
;; ----------------------------------------------------
defcode	'C@',1,0,CFTCH
	pop	hl
	ld	e, (hl)
	ld	d, 0x0
	push	de
	jp	(iy)
;; ---------------------------------------------------- 
defcode	'!',1,0,STORE
	pop	hl
	pop	de
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jp	(iy)
;; ----------------------------------------------------
defcode	'@',1,0,FETCH
	pop	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	de
	jp	(iy)
defcode	'&',1,0,ALTFTC
	jr	cFETCH
;; ---------------------------------------------------- 
defcode	'CMOVE',5,0,CMOVE
	exx
	pop	bc
	pop	de
	pop	hl
	or	a
	ld	a, c
	inc	a
	dec	a
	jr	NZ, cldir
	ld	a, b
	inc 	a
	dec	a
	jr	NZ, cldir
cmovend	exx
	jp	(iy)
cldir	ldir
	jr	cmovend
;; ---------------------------------------------------- 
;; RETURN STACK PRIMITIVES
;; ----------------------------------------------------
defcode '>R',2,0,TOR
	pop	hl
	dec	ix		; (SP) -> RSP
	ld	(ix+0),h
	dec	ix
	ld	(ix+0),l
	jp	(iy)
;; ---------------------------------------------------- 
defcode 'R>',2,,FROMR	; (RSP) -> SP
	ld	l,(ix+0)
	inc	ix
	ld	h,(ix+0)
	inc	ix
	push	hl
	jp	(iy)
;; ---------------------------------------------------- 
defcode 'R&',2,,RSPTOP	; (RSP) -> SP
	push	bc
	jp	(iy)
;; ---------------------------------------------------- 
;; STACK PRIMITIVES
;; ---------------------------------------------------- 
defcode 'DROP',4,0,DROP
	pop	hl
	jp	(iy)
;; ----------------------------------------------------
defcode 'SWAP',4,0,SWAP
	pop	hl
	pop	de
	push	hl
	push	de
	jp	(iy)
;; ----------------------------------------------------
defcode 'DUP',3,0,DUP
	pop	hl
	push	hl
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'OVER',4,0,OVER
	pop	hl
	pop	de
	push	de
	push	hl
	push	de
	jp	(iy)
;; ----------------------------------------------------
defcode	'ROT',3,0,ROT
	exx
	pop	hl
	pop	de
	pop	bc
	push	hl
	push	bc
	push	de
	exx
	jp	(iy)
;; ----------------------------------------------------
defcode '?DUP',4,0,QDUP
	pop	hl
	push	hl
	inc	l
	dec	l
	jr	NZ, _qdup
	inc	h
	dec	h
	jr	NZ, _qdup
	jp	(iy)
_qdup	push	hl	
	jp	(iy)
;; ---------------------------------------------------- 
;; TESTING TOS VALUES
;; ----------------------------------------------------
defcode	'=',1,0,EQUAL
	pop	hl
	pop	de
	or	a
	sbc	hl, de
	jp	Z, cTRUE
	jp	cFALSE
;; ----------------------------------------------------
defcode	'<',1,0,LTHAN
	pop	de
	pop	hl
	or	a
	sbc	hl, de
	jp	M, cTRUE
	jp	cFALSE
;; ----------------------------------------------------
defcode	'>',1,0,GTHAN
	pop	de
	pop	hl
	or	a
	sbc	hl, de
	jp	M, cFALSE
	jp	cTRUE
;; ----------------------------------------------------
defcode	'0=',2,0,ZEQUAL
	pop	hl
	ld	de, 0x0
	or	a
	sbc	hl, de
	jp	Z, cTRUE
	jp	cFALSE
;; ----------------------------------------------------
defcode 'NOT',3,0,BNOT
	jr	cZEQUAL
;; ----------------------------------------------------
defcode	'0<',2,0,ZNEG
	pop	hl
	ld	de, 0x0
	or	a
	sbc	hl, de
	jp	M, cTRUE
	jp	cFALSE
;; ----------------------------------------------------
defcode	'0>',2,0,ZPOS
	pop	hl
	ld	de, 0x0
	or	a
	sbc	hl, de
	jp	M, cFALSE
	jp	cTRUE
;; ---------------------------------------------------- 
;; BITWISE LOGICAL PRIMITIVES
;; ----------------------------------------------------
defcode	'AND',3,0,LGAND
	pop	hl
	pop	de
	ld	a, l
	and	e
	ld	l, a
	ld	a, h
	and	d
	ld	h, a
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'OR',2,0,LGOR
	pop	hl
	pop	de
	ld	a, l
	or	e
	ld	l, a
	ld	a, h
	or	d
	ld	h, a
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'XOR',3,0,LGXOR
	pop	hl
	pop	de
	ld	a, l
	xor	e
	ld	l, a
	ld	a, h
	xor	d
	ld	h, a
	push	hl
	jp	(iy)
;; ----------------------------------------------------
;; INTEGER ARITHMETICS 8b and 16b
;; ---------------------------------------------------- 
defcode	'NEGATE',6,0,LGNOT
	pop	de
	ld	hl, 0x0
	sbc	hl, de
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'1+',2,0,INC
	pop	hl
	inc	hl
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'1-',2,0,DEC
	pop	hl
	dec	hl
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'2+',2,0,INC2
	pop	hl
	inc	hl
	inc	hl
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode	'2-',2,0,DEC2
	pop	hl
	dec	hl
	dec	hl
	push	hl
	jp	(iy)
;; ---------------------------------------------------- 
defcode '+',1,0,ADD
	pop	de
	pop	hl
	add	hl,de
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode '-',1,0,SUB
	pop	de
	pop	hl
	sbc	hl,de
	push	hl
	jp	(iy)
;; ----------------------------------------------------
;; Unsigned mults from [[https://wikiti.brandonw.net/index.php?title=Z80_Routines:Math:Multiplication]]
;; ---------------------------------------------------- 
defcode	'BB*',3,0,BBMUL
	ld	(SAVEBC), bc	; This prim uses b, multiplies h by e and places the result in hl
	pop	de		; Keep lower byte in e
	pop	hl
	ld	h,l		; Keep lower byte in h
	ld	d, 0		; Combining the overhead and
	sla	h		; optimised first iteration
	sbc	a, a	
	and	e
	ld	l, a
	ld	b, 7
_loopb:
	add	hl, hl          
	jr	nc, $+3
	add	hl, de
	djnz	_loopb
	ld	bc, (SAVEBC)
	push	hl
	jp	(iy)
;; ----------------------------------------------------
defcode 'WB*',3,0,WBMUL
	ld	(SAVEBC), bc	;  multiplies de by a into hl
	pop	de
	pop	hl
	ld	a,l
	ld	l, 0
	ld	b, 8
_loopw	add	hl, hl
	add	a, a
	jr	NC, _lpw0
	add	hl, de
_lpw0	djnz	_loopw
	push	hl
	ld	bc, (SAVEBC)
	jp	(iy)
;; ---------------------------------------------------- 
;; LITERAL NUMBERS IN COMPILED (USER-DEFINED) WORDS
;; ---------------------------------------------------- 
defcode	'LIT',3,f_hid,LIT
	ld	a,(bc)
	ld	l,a
	inc	bc
	ld	a,(bc)
	ld	h,a
	inc 	bc
	push	hl
	jp	(iy)
;; ---------------------------------------------------- 
;; 1-WORD JUMP CONTROL STRUCTURES
;; ---------------------------------------------------- 
defcode	'ZBRANCH',7,0,ZBRANCH
	pop	hl
	inc	l
	dec	l
	jr	NZ, zbcont
	inc	h
	dec	h
	jr	NZ, zbcont
nbcont	ld	a,(bc)
	ld	l,a
	inc	bc
	ld	a,(bc)
	ld	h,a
	push	hl
	pop	bc
	jp	(iy)
zbcont	inc	bc
	inc	bc
	jp	(iy)
;; ----------------------------------------------------
defcode 'UBRANCH',7,0,UBRANCH
	jr	nbcont
;; ---------------------------------------------------- 
defcode	'NBRANCH',7,0,NBRANCH
	pop	hl
	inc	l
	dec	l
	jr	NZ, nbcont
	inc	h
	dec	h
	jr	NZ, nbcont
	jr	zbcont
;; ---------------------------------------------------- 
;; PERKS (also for test)
;; ---------------------------------------------------- 
defword	'DOUBLE',6,0,DOUBLE
	defw	DUP
	defw	ADD
	defw	SEMI
	
