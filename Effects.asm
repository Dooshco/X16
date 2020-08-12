; Simplest Sound Effects Library for BASIC Programs
; Author:		Dusan Strakl
; More Info:	8BITCODING.COM
;
; System:		Commander X16
; Version:		Emulator R.37
; Compiler:		CC65
; Build using:	cl65 -t cx16 Effects.asm -C cx16-asm.cfg -o EFFECTS.PRG


VERA_LOW		= $9F20
VERA_MID		= $9F21
VERA_HIGH		= $9F22
VERA_DATA0		= $9F23
IRQ_VECTOR 		= $0314
OLD_IRQ_HANDLER = $06
PSG_CHANNEL		= $1F9FC
PSG_VOLUME		= PSG_CHANNEL + 2

.macro VERA_SET addr, increment
	lda #((^addr) | (increment << 4))
	sta VERA_HIGH
	lda #(>addr)
	sta VERA_MID
	lda #(<addr)
	sta VERA_LOW
.endmacro

.org $0400
;.org $9000					; Alternative memory location
.segment "CODE"


;*******************************************************************************
; ENTRY SECTION
; ******************************************************************************
jmp ping 
jmp shoot
jmp zap
jmp explode

ping:
;*******************************************************************************
	ldx #0
	jmp common

shoot:
; ******************************************************************************
	ldx #10
	jmp common

zap:
;*******************************************************************************
	ldx #20
	jmp common

explode:
;*******************************************************************************
	ldx #30

common:
;*******************************************************************************
	ldy #0							; move 10 bytes from definitions
:	lda sounds,x
	sta channel15,y
	inx
	iny
	cpy #10
	bne :-

	lda #255						; Start playing
	sta phase

	lda running						; is IRQ player already running
	bne return

	sei 							; insert new IRQ player
	lda IRQ_VECTOR
	sta OLD_IRQ_HANDLER
  	lda #<Play
  	sta IRQ_VECTOR
  	lda IRQ_VECTOR+1
  	sta OLD_IRQ_HANDLER+1
  	lda #>Play
  	sta IRQ_VECTOR+1
  	cli
	lda #1
	sta running

return:
	rts




; ******************************************************************************
; IRQ PLAY SECTION
; ******************************************************************************
Play:

	lda phase
	cmp #0							; if phase = 0 - Exit
	bne :+
	jmp exit

:	cmp #1							; if phase = 1 - Release
	bne :+
	jmp release

:	lda #1							; else phase = 255 - Start
	sta phase

	VERA_SET PSG_CHANNEL,1

	lda frequency					; read and set frequency
	sta VERA_DATA0
	lda frequency+1
	sta VERA_DATA0
	lda volume+1
	ora #%11000000
	sta VERA_DATA0					; starting Volume  = volume
	lda waveform
	sta VERA_DATA0					; set waveform
	jmp exit

;*******************************************************************************
release:
;*******************************************************************************
	lda release_count
	bne release_loop				; not finished yet

	VERA_SET PSG_VOLUME,0
	stz VERA_DATA0					; set volume to 0 at the end of Release phase

	stz phase						; release finished, exit
	jmp exit

release_loop:

	sec								; decrease 16 bit volume
	lda volume
	sbc vol_change
	sta volume
	lda volume+1
	sbc vol_change+1
	sta volume+1

	sec								; decrease 16 bit frequency
	lda frequency
	sbc freq_change
	sta frequency
	lda frequency+1
	sbc freq_change+1
	sta frequency+1

	VERA_SET PSG_CHANNEL,1

	lda frequency					; read and set frequency
	sta VERA_DATA0
	lda frequency+1
	sta VERA_DATA0

	lda volume+1
	ora #%11000000
	sta VERA_DATA0					; read and set volume

	dec release_count

exit:
	jmp (OLD_IRQ_HANDLER)



; ******************************************************************************
; VARIABLES
; ******************************************************************************
running:			.byte 0			; 0 - not running, 1 - running
phase:				.byte 0			; 0 - not playing, 255 - Start, 1 - Play Release

channel15:
release_count:		.byte 0

frequency:			.word 0
waveform:			.byte 0

volume:				.word 0
vol_change:			.word 0
freq_change:		.word 0

sounds:
ping_envelope:		.byte 100,199,9,160,0,63,161,0,0,0
shoot_envelope:		.byte 20,107,17,224,0,63,0,3,0,0
zap_envelope:		.byte 37,232,10,96,0,63,179,1,100,0
explode_envelope:	.byte 200,125,5,224,0,63,80,0,0,0
