	;; zf.asm Laborious elaborations
	;; Sources are numerous:
	;;   https://github.com/nornagon/jonesforth/blob/master/jonesforth.S
	;;   https://www.bradrodriguez.com/papers/moving1.htm
	;;   Threaded Interpretive Languages (1981) R. G. Loeliger
	;; Conventions:
	;;   RSP   ix Return Stack Pointer
	;;   NEXT  iy
	;;   IP    bc Instruction Pointer
	;;   SP    sp Stack pointer
	;;   W     de Working register, Word address
	;;   X     hl Scratch register
	org 7000H
START	xor	a
	ld	(409cH),a
	ld	hl, MSG
	call	2f0aH
	;; 
	ld	iy, NEXT
	ld	ix, SECRSP
	ld	a,0x41
	push	af
	ld	bc, SECCODE
	jp	NEXT
	;; 
DONE	defw	DONE+2
PUTS	pop	hl		; Top of stack in hl
	call	0a9aH		; Move hl to acc
	call	0fbdH		; Convert to ascii
	call	2f0aH		; Print
	jp	06ccH
include zfinner.asm	
include	zfmacro.asm
include zfprim.asm
include zfio.asm
	;; 
LATEST	defw	nPROMPT
	;; 
MSG	defb	'Z80 FORTH',0x0D,0
OK	defb	'OK> ',0	
SAVEBC	defw	0x0
BUFP	defw	BUFFER	
BUFFER	defs	256		; Line buffer
WORDBUF	defs	32		; FORTH word buffer/token
SECRSP	defs	128
	;; Main intereter loop in FORTH
SECCODE	defw	PROMPT, INLINE
NXTWRD	defw	WORD, ZBRANCH, SECCODE
	defw	FIND, NBRANCH, NXTWRD, DONE
	end	START
	
	
