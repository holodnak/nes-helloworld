;;save registers to stack
.macro pushregs
	pha
	tya
	pha
	txa
	pha
.endm

;;restore registers from stack
.macro popregs
	pla
	tax
	pla
	tay
	pla
.endm

.macro ldsta
	lda	#\1
	sta	\2
.endm

.macro ldsty
	ldy	#\1
	sty.w	\2
.endm
