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
	ld	bc, _BOOT
	jp	NEXT
	;; 
DONE$	defw	DONE$+2
PUTS	pop	hl		; Top of stack in hl
	call	0a9aH		; Move hl to acc
	call	0fbdH		; Convert to ascii
	call	2f0aH		; Print
	jp	06ccH		; Jump out to BASIC
include zfinner.asm	
include	zfmacro.asm
include zfprim.asm
include zfouter.asm	
include zfio.asm
	;; 
	;; 
MSG	defb	'Z80 FORTH',0x0D,'(cold)',0x0D,0
OK	defb	'OK> ',0	
SAVEBC	defw	0x0
BUFP	defw	BUFFER		; Parsing pointer in BUFFER
BUFFER	defs	256		; Line buffer
WORDBUF	defs	32		; FORTH word buffer/token
WORDFLG	defb	0x0		; FLAGS set or reset during FIND
SECBEG	defs	126		; Section: Return Stack
SECRSP	defb	0x0	
	;; Outer interpreter loop in FORTH
	;;   _ Address prefix
	;;   $ Secondary word suffix
_BOOT	defw	COLD	
_VM	defw	PROMPT, INLINE
_NXTWD	defw	WORD, ZBRANCH, _VM
	defw	FIND, DUP, NBRANCH, _EXEWD, DONE$
_EXEWD	defw	INTERPRET, UBRANCH, _NXTWD
SECUSER defw	0x0
	end	START
	
	
