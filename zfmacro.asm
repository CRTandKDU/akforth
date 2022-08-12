f_imm	defl	0x80
f_lit	defl	0x40	
f_hid	defl	0x20
f_msk	defl	0x1f		; length mask
link	defl	0
	
CFA	macro			; Block address in HL -- Code address in HL
	inc	hl
	inc	hl
	ld	a, (hl)
	and	f_msk
	ld	e, a		; Warning: uses de
	ld	d, 0
	add	hl, de
	inc	hl
	endm
	
defword	macro 	name, namelen, flags, label	
`n`label	defw	link
link	defl	`n`label	
	defb	flags + namelen
	defb	name
label	defw	DOCOL
	endm
	;; 
defcode	macro	name, namelen, flags, label
`n`label	defw	link
link	defl	`n`label	
	defb	flags + namelen
	defb	name
label	defw	`c`label
`c`label	
	endm
	;;
