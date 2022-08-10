SEMI	defw	SEMI+2		; RSP -> IP
	ld	c,(ix+0)
	inc	ix
	ld	b,(ix+0)
	inc	ix
NEXT	ld	a,(bc)		; IP -> hl
	ld	l,a
	inc	bc
	ld	a,(bc)
	ld	h,a
	inc	bc
RUN	ld	e,(hl)		; hl -> W
	inc	hl
	ld	d,(hl)
	inc	hl
	ex	de,hl
	jp	(hl)		; JUMP (W)
DOCOL	dec	ix		; IP -> RSP
	ld	(ix+0),b
	dec	ix
	ld	(ix+0),c
	ld	c,e		; W -> IP
	ld	b,d
	jp	(iy)
EXECUTE	defw	EXECUTE+2	
	pop	hl
	jr	RUN
