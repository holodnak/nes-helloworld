.MEMORYMAP
	SLOTSIZE $8000
	DEFAULTSLOT 0
	SLOT 0 $8000
.ENDME

.ROMBANKMAP
	BANKSTOTAL 1
	BANKSIZE $8000
	BANKS 1
.ENDRO

.include "defines.i"
.include "macros.i"

.BANK 0 SLOT 0

.ORG $0000

asciichr:
.INCBIN "ascii.chr" READ 1536

palette:
	.db	$0f,$00,$10,$20,  $0f,$1a,$2a,$3a,  $0f,$0f,$0f,$0f,  $0f,$0f,$0f,$0f
	.db	$0f,$0f,$0f,$0f,  $0f,$1a,$2a,$3a,  $0f,$12,$22,$32,  $0f,$1d,$2d,$3d

.ORG $2000

sprites:
	.db	$CE,$FF,$20,$00,
	.db	$40,$48,$01,$00,
	.db	$42,$45,$01,$08,
	.db	$44,$4C,$01,$10,
	.db	$46,$4C,$01,$18,
	.db	$48,$4F,$01,$20,
	.db	$4A,$57,$01,$30,
	.db	$4C,$4F,$01,$38,
	.db	$4E,$52,$01,$40,
	.db	$50,$4C,$01,$48,
	.db	$52,$44,$01,$50,
.repeat 53
	.db	$FF,$FF,$FF,$FF,
.endr

helloworld:
	.db	"hello world",0

.ORG $4000

;;initialize the nes
initnes:
	ldsty	$40,$4017		;;disable frame irq
	ldsty	$0F,$4015		;;setup volume
	ldx	#0
	stx.w	PPUCTRL			;;disable nmi
	stx.w	PPUMASK			;;disable rendering
	stx.w	$4010				;;disable dmc irq
	lda	#0
	sta	PPUCTRL
	sta	PPUMASK
	rts

;;wait for vblank, missing it sometimes
ppuwait:
	bit PPUSTATUS
	bpl ppuwait
	rts

;;zero out a tile
zerotile:
	lda	#0

;;fill a tile with specific byte (A register)
filltile:
	ldy	#16
-	sta	PPUDATA
	dey
	bne	-
	rts

;;copy data to vram
copyvram:
	lda	($00),y		; copy one byte
	sta	PPUDATA
	iny
	bne	copyvram		; repeat until we finish the page
	inc	$01			; go to the next page
	dex
	bne	copyvram		; repeat until weve copied enough pages
	rts

;;clear vram/nametables
;;y = number of bytes
;;x = number of pages
clearvram:
	lda	#0
-	sta	PPUDATA
	dey
	bne	-					; repeat until we finish the page
	dex
	bne	-					; repeat until weve copied enough pages
	rts

;;copy string from ($00) to ppu memory (helper for init)
copystring:
	ldy	#0
-	lda	($00),y
	iny
	cmp	#0
	beq	+
	sta	PPUDATA
	bne	-
+	rts

 ;;copy all vram/palette/sprites to ppu
setupppu:

	;;setup ppu for data copy
	ldy	PPUSTATUS		;;reset the toggle
	ldsty	$02,PPUADDR		;;load high byte of destination address
	ldsty	$00,PPUADDR		;;load low byte of destination address

	;;copy chr
	ldsta	$80,$01			;;high byte of source address
	ldsta	$00,$00			;;low byte of source address
	ldx	#6					; number of 256-byte pages to copy
	jsr	copyvram

	;;copy palette data
	ldsty	$3F,PPUADDR		;;setup destination ppu address
	ldsty	$00,PPUADDR
	ldx	#32				;;number of bytes to copy from the palette
-	lda	($00),y			;;load byte to copy to ppu
	sta	PPUDATA			;;write byte to ppu
	iny						;;increment source address
	dex						;;decrement counter
	bne	-					;;repeat until all copied

	;;copy sprite data
	lda	#0					;;sprite data address
	sta	OAMADDR
	lda	#$A0				;;page to dma from
	sta	$4014				;;execute sprite dma

	;;setup tile 0
	ldy	#0					;;starting index into the first page
	sty.w	PPUADDR			;;load the destination address into the PPU
	sty.w	PPUADDR
	jsr	zerotile			;;write all 0s to tile

	;;setup tile $FF for sprite0 hit
	ldsty	$0F,PPUADDR		;;upper byte of dest addr
	ldsty	$F0,PPUADDR		;;lower byte of dest addr
	lda	#$FF				;;byte to fill with
	jsr	filltile			;;fill tile with $FF

	;;clear nametables
	ldsty	$20,PPUADDR		;;high byte of destination
	ldsty	$00,PPUADDR		;;low byte of destination
	ldx	#4					;;number of 256 byte loops
	jsr	clearvram

	;;write sprite0 hit tile
	ldsty	$23,PPUADDR		;;high byte of destination address
	ldsty	$40,PPUADDR		;;low byte of destination address
	ldsta	$FF,PPUDATA

	;;write sprite0 hit tile attribute
	ldsty	$23,PPUADDR		;;high byte of destination address
	ldsty	$F0,PPUADDR		;;low byte of destination address
	ldsta	$70,PPUDATA

	;;write attributes for the status bar
	ldsta	$50,PPUDATA
	ldsta	$50,PPUDATA
	ldsta	$50,PPUDATA
	ldsta	$50,PPUDATA

	;;copy the info string into scrolling area
	ldsty	$23,PPUADDR			;;high byte of destination address
	ldsty	$62,PPUADDR			;;low byte of destination address
	ldsta	>helloworld,$01	;;high byte of source address
	ldsta	<helloworld,$00	;;low byte of source address
	jsr	copystring

	rts						;;return

reset:
	sei						;;disable irq
	cld						;;disable decimal mode
	ldx	#$FF
	txs						;;setup stack
	inx
-	sta	$000,x			;;clear ram
	sta	$100,x
	sta	$200,x
	sta	$300,x
	sta	$400,x
	sta	$500,x
	sta	$600,x
	sta	$700,x
	inx
	bne	-

	jsr	initnes					;;initialize the nes
	jsr	ppuwait					;;let ppu warm up, wait for vblank
	jsr	ppuwait
	jsr	setupppu					;;copy all ppu data and setup other stuff
	jsr	timerreset

	ldsty	$00,PPUSCROLL			;;reset scroll to 0,0
	ldsty	$00,PPUSCROLL
	ldsty	$1E,PPUMASK				;;enable rendering

	ldsty	$80,PPUCTRL				;;enable nmi
	cli								;;enable irq

	ldx #0
	stx $ee

mainloop:
-	lda	$2002						;;wait until sprite0 flag clears
	and	#%01000000
	bne	-

	ldx	PPUSTATUS				;;reset toggle
	ldx	#0							;;restore scroll to 0,0
	stx.w	PPUSCROLL
	stx.w	PPUSCROLL

-	lda	$2002						;;wait for sprite0 hit
	and	#%01000000
	beq	-

	lda	SCROLL_X					;;update scroll register with new x value
	sta	$2005
	lda	#$00
	sta	$2005

	lda	#%10000000				;;enable nmi
	sta	PPUCTRL

	jmp	mainloop					;;keep looping

nmi:
	pushregs					;;save registers

	lda	#%00000000		;;disable NMI
	sta	PPUCTRL

	ldsty	$00,PPUSCROLL	;;scroll x offset
	ldsty	$00,PPUSCROLL	;;scroll y offset

	jsr	scrollinc		;;increment scrolling
	jsr	timerinc			;;increment nsf play timer

	popregs
	rti

irq:
	rti

;;draw the play timer
drawtimer:

	ldsty	$23,PPUADDR		;;high byte of destination address
	ldsty	$19,PPUADDR		;;low byte of destination address

	lda	#0
	sta	PPUDATA

	lda	TIME_MINUTES
	and	#$F0
	cmp	#0
	beq	+
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$30
+	sta	PPUDATA
	lda	TIME_MINUTES
	and	#$0F
	clc
	adc	#$30
	sta	PPUDATA

	lda	#$3A
	sta	PPUDATA

	lda	TIME_SECONDS
	and	#$F0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	clc
	adc	#$30
	sta	PPUDATA
	lda	TIME_SECONDS
	and	#$0F
	clc
	adc	#$30
	sta	PPUDATA

	rts

;;increment bottom scrolling area
scrollinc:
	ldx	SCROLL_X			;;increment scroll x
	inx
	stx.w	SCROLL_X
	rts

;;increment the play timer
timerinc:
	jsr	incframes
	cpx	#0
	bne	+
	jsr	incseconds
	cpx	#0
	bne	+
	jsr	incminutes
+	rts

;;reset play timer
timerreset:
	lda	#0
	sta	TIME_FRAMES
	sta	TIME_SECONDS
	sta	TIME_MINUTES
	rts

;;increment frame counter
;;leaves frame count in x
incframes:
	ldx	TIME_FRAMES				;;load frame count
	inx								;;increment
	cpx	#60						;;check if it is 60
	bne	+							;;branch if not equal
	ldx	#0							;;reset to 0
+	stx.w	TIME_FRAMES				;;save frame count
	rts

;;increment seconds counter
;;leaves seconds in x
incseconds:
	ldx	TIME_SECONDS			;;load seconds counter
	inx								;;increment
	txa
	and	#$0F						;;keep lower four bits
	cmp	#$0A						;;check for overflow
	bne	+

	;;process upper nibble
	txa
	clc
	adc	#6							;;add 6 to $A, making lower nibble 0 and incrementing upper
	tax
	and	#$F0						;;keep upper bits
	cmp	#$60						;;check for overflow
	bne	+
	lda	#0							;;zero
	tax
+	stx.w	TIME_SECONDS
	rts

;;increment minutes counter
;;leaves minutes in x
incminutes:
	ldx	TIME_MINUTES
	inx
	txa
	and	#$0F						;;keep lower four bits
	cmp	#$0A						;;check for overflow
	bne	+
	txa								;;process upper nibble
	clc
	adc	#6							;;add 6 to $A, making lower nibble 0 and incrementing upper
	tax
	and	#$F0						;;keep upper bits
	cmp	#$A0						;;check for overflow
	bne	+
	lda	#0							;;zero
	tax
+	stx.w	TIME_MINUTES
	rts

;vectors
.ORG $7FFA
	.dw	nmi
	.dw	reset
	.dw	irq
