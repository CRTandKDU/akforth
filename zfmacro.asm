f_imm	defl	0x80
f_hid	defl	0x20
f_msk	defl	0x1f		; length mask
link	defl	0

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
