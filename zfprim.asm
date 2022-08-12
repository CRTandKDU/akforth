	defcode 'SKIP',4,0,SKIP
	pop	hl
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
	defcode	'LIT',3,0,LIT
	ld	a,(bc)
	ld	l,a
	inc	bc
	ld	a,(bc)
	ld	h,a
	inc 	bc
	push	hl
	jp	(iy)
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
	defword	'DOUBLE',6,0,DOUBLE
	defw	DUP
	defw	ADD
	defw	SEMI
	
