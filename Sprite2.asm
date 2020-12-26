; Assembly Demo of Sprite IRQ Animation
; System: Commander X16
; Version: Emulator R.38+
; Author: Dusan Strakl
; Date: December 2020
; Compiler: CC65
; Build using:	cl65 -t cx16 Sprite2.asm -o SPRITE2.PRG


.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

; VERA Registers
VERA_LOW	    = $9F20
VERA_MID	    = $9F21
VERA_HIGH	    = $9F22
VERA_DATA0	    = $9F23
VERA_CTRL	    = $9F25

; Memory Locations
IRQ_VECTOR 		= $0314
OLD_IRQ_HANDLER = $06
WORK_REGISTER   = $02

; VRAM Locations
SPRITE_GRAPHICS = $4000
SPRITE1         = $FC08


;******************************************************************************
; MAIN PROGRAM
;******************************************************************************
main:

    ; Define Sprite
    stz VERA_CTRL
    lda #$10
    ora #<SPRITE_GRAPHICS
    sta VERA_HIGH
    lda #>SPRITE_GRAPHICS
    sta VERA_MID
    stz VERA_LOW

    lda #<data
    sta WORK_REGISTER
    lda #>data
    sta WORK_REGISTER+1
    ldx #32
    ldy #0
:   lda (WORK_REGISTER),y
    sta VERA_DATA0              ; move 32 x 256 bytes to VRAM
    iny 
    bne :-
    inc WORK_REGISTER+1
    dex
    bne :-

    ; Initiate Sprite
    lda $9F29
    ora #%01000000
    sta $9F29

    lda #$11
    sta VERA_HIGH
    lda #>SPRITE1
    sta VERA_MID
    lda #<SPRITE1
    sta VERA_LOW

    stz VERA_DATA0
    lda #%10000010
    sta VERA_DATA0
    stz VERA_DATA0
    stz VERA_DATA0
    stz VERA_DATA0
    stz VERA_DATA0
    lda #%00001100
    sta VERA_DATA0
    lda #%10100000
    sta VERA_DATA0

    ; Insert new IRQ Vector
	sei
	lda IRQ_VECTOR
	sta OLD_IRQ_HANDLER
    lda #<BounceSprite
    sta IRQ_VECTOR
    lda IRQ_VECTOR+1
    sta OLD_IRQ_HANDLER+1
    lda #>BounceSprite
    sta IRQ_VECTOR+1
    cli

    rts


;******************************************************************************
; BOUNCE SPRITE - IRQ Handler
;******************************************************************************
BounceSprite:
    ; Update X
    lda PosX
    clc
    adc DeltaX
    sta PosX
    lda PosX+1
    adc DeltaX+1
    sta PosX+1

    ; Update Y
    lda PosY
    clc
    adc DeltaY
    sta PosY
    lda PosY+1
    adc DeltaY+1
    sta PosY+1

check_right:   
    lda PosX+1
    cmp #$02
    bne check_left
    lda PosX
    cmp #$5F
    bne check_left

    ; hit the right edge, DeltaX <= -1
    lda #255
    sta DeltaX
    sta DeltaX+1
    jmp check_bottom

check_left:
    lda PosX+1
    bne check_bottom
    lda PosX
    bne check_bottom

    ; hit the left edge, DeltaX <= +1
    lda #1
    sta DeltaX
    stz DeltaX+1

check_bottom:   
    lda PosY+1
    cmp #$01
    bne check_top
    lda PosY
    cmp #$BF
    bne check_top

    ; hit the bottom edge, DeltaY <= -1
    lda #255
    sta DeltaY
    sta DeltaY+1
    jmp animate

check_top:
    lda PosY+1
    bne animate
    lda PosY
    bne animate

    ; hit the top edge, DeltaY <= +1
    lda #1
    sta DeltaY
    stz DeltaY+1


animate:
    ; Update Frame
    inc Frame
    lda Frame
    cmp #8
    bne :+
    lda #0
:   sta Frame

    ; Multiply by 32
    sta WORK_REGISTER
    stz WORK_REGISTER+1

	asl WORK_REGISTER
	rol WORK_REGISTER+1
	asl WORK_REGISTER
	rol WORK_REGISTER+1
	asl WORK_REGISTER
	rol WORK_REGISTER+1
	asl WORK_REGISTER
	rol WORK_REGISTER+1
	asl WORK_REGISTER
	rol WORK_REGISTER+1

    ; add starting address ($4000 translates to $0200)
    lda WORK_REGISTER+1
    clc
    adc #$02
    sta WORK_REGISTER+1



    ; Update Sprite to VERA
    stz VERA_CTRL
    lda #$11
    sta VERA_HIGH
    lda #$FC
    sta VERA_MID
    lda #$08
    sta VERA_LOW

    lda WORK_REGISTER
    sta VERA_DATA0
    lda WORK_REGISTER+1
    ora #$80
    sta VERA_DATA0
    lda PosX
    sta VERA_DATA0
    lda PosX+1
    sta VERA_DATA0
    lda PosY
    sta VERA_DATA0
    lda PosY+1
    sta VERA_DATA0

    jmp (OLD_IRQ_HANDLER)


.segment "DATA"

    ; Variables
    PosX:   .word   100
    PosY:   .word   100
    Frame:  .byte   0
    DeltaX: .word   1
    DeltaY: .word   1

    ; Sprite Graphics
data:   
    ; Frame 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 22, 35, 42, 42, 34, 41, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 56, 49, 35, 24, 24, 35, 49, 42, 23, 22, 22, 41, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 49, 56, 49, 35, 25, 25, 25, 25, 24, 56, 56, 42, 35, 22, 55, 55, 41, 19, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 49, 56, 42, 25, 25, 26, 26, 26, 43, 57, 57, 56, 56, 56, 42, 41, 48, 48, 21, 20, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 23, 35, 50, 36, 26, 26, 26, 27, 43, 57, 57, 57, 57, 57, 56, 35, 24, 23, 34, 41, 21, 33, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 24, 24, 43, 57, 57, 51, 43, 26, 37, 50, 58, 57, 57, 57, 57, 50, 25, 24, 23, 23, 21, 48, 47, 47, 0, 0, 0, 0
    .byte 0, 0, 0, 23, 24, 43, 57, 57, 57, 58, 58, 51, 37, 51, 58, 58, 58, 57, 57, 43, 25, 24, 24, 23, 22, 55, 54, 54, 19, 0, 0, 0
    .byte 0, 0, 21, 24, 35, 57, 57, 57, 58, 58, 58, 37, 29, 29, 28, 44, 58, 58, 57, 36, 25, 25, 24, 23, 23, 55, 55, 54, 40, 18, 0, 0
    .byte 0, 0, 23, 24, 50, 57, 57, 58, 58, 58, 51, 29, 30, 30, 29, 29, 28, 37, 44, 26, 26, 25, 24, 24, 23, 55, 55, 54, 47, 19, 0, 0
    .byte 0, 21, 24, 35, 57, 57, 57, 58, 58, 58, 38, 30, 30, 30, 30, 30, 29, 28, 44, 57, 50, 43, 24, 24, 23, 34, 55, 54, 54, 40, 18, 0
    .byte 0, 22, 24, 49, 57, 57, 57, 58, 58, 51, 30, 31, 31, 31, 31, 30, 29, 28, 50, 57, 57, 57, 56, 42, 42, 48, 55, 54, 54, 47, 18, 0
    .byte 0, 56, 42, 42, 50, 57, 57, 58, 58, 38, 30, 31, 31, 31, 31, 30, 29, 37, 58, 58, 57, 57, 56, 56, 56, 34, 41, 47, 54, 54, 19, 0
    .byte 48, 56, 42, 25, 25, 36, 43, 51, 51, 29, 30, 31, 31, 31, 31, 30, 29, 51, 58, 58, 57, 57, 56, 56, 56, 22, 22, 21, 33, 47, 18, 17
    .byte 55, 56, 23, 25, 25, 26, 27, 28, 44, 27, 29, 30, 31, 31, 30, 30, 28, 58, 58, 57, 57, 57, 56, 56, 56, 22, 22, 21, 20, 19, 53, 53
    .byte 55, 55, 35, 24, 25, 26, 27, 27, 58, 58, 51, 44, 38, 30, 30, 29, 44, 58, 58, 57, 57, 57, 56, 56, 49, 22, 21, 21, 20, 19, 235, 53
    .byte 55, 55, 35, 24, 25, 26, 26, 36, 58, 58, 58, 58, 58, 51, 44, 29, 51, 58, 57, 57, 57, 56, 56, 56, 41, 22, 21, 21, 20, 19, 235, 53
    .byte 55, 48, 23, 24, 24, 25, 26, 43, 57, 58, 58, 58, 58, 58, 58, 51, 37, 43, 57, 57, 57, 56, 56, 56, 34, 22, 21, 20, 20, 19, 53, 53
    .byte 55, 41, 23, 23, 24, 25, 25, 50, 57, 57, 58, 58, 58, 58, 58, 44, 27, 26, 25, 36, 49, 56, 56, 55, 22, 21, 21, 20, 19, 18, 53, 53
    .byte 47, 48, 22, 23, 24, 24, 24, 57, 57, 57, 57, 57, 57, 57, 57, 26, 26, 26, 25, 25, 24, 35, 42, 48, 22, 21, 20, 20, 19, 18, 53, 16
    .byte 18, 34, 34, 22, 23, 24, 24, 56, 57, 57, 57, 57, 57, 57, 50, 26, 25, 25, 25, 24, 24, 23, 22, 48, 48, 33, 33, 19, 19, 235, 53, 16
    .byte 0, 21, 48, 55, 41, 35, 35, 56, 56, 56, 56, 57, 57, 57, 43, 25, 25, 24, 24, 24, 23, 23, 21, 55, 54, 54, 54, 235, 18, 235, 53, 0
    .byte 0, 20, 47, 55, 55, 55, 49, 42, 56, 56, 56, 56, 56, 56, 24, 24, 24, 24, 23, 23, 23, 22, 41, 55, 54, 54, 54, 53, 53, 17, 16, 0
    .byte 0, 19, 33, 54, 55, 55, 41, 23, 23, 35, 42, 49, 56, 49, 24, 23, 23, 23, 23, 22, 22, 21, 47, 54, 54, 54, 53, 53, 235, 17, 16, 0
    .byte 0, 0, 33, 54, 54, 55, 55, 22, 22, 23, 23, 23, 34, 34, 23, 23, 23, 22, 22, 22, 21, 40, 54, 54, 54, 53, 53, 53, 17, 16, 0, 0
    .byte 0, 0, 18, 40, 54, 54, 54, 21, 22, 22, 22, 22, 21, 55, 55, 48, 34, 22, 21, 21, 20, 54, 54, 54, 53, 53, 53, 17, 17, 16, 0, 0
    .byte 0, 0, 0, 18, 54, 54, 54, 21, 21, 21, 21, 21, 41, 55, 55, 55, 55, 54, 40, 236, 47, 54, 54, 53, 53, 53, 17, 17, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 53, 47, 54, 20, 20, 20, 20, 21, 47, 54, 54, 54, 54, 54, 54, 47, 19, 235, 53, 53, 53, 17, 17, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 235, 19, 19, 19, 20, 20, 33, 54, 54, 54, 54, 54, 54, 47, 19, 19, 18, 18, 17, 53, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 18, 53, 235, 18, 235, 54, 54, 54, 53, 53, 235, 18, 18, 18, 18, 17, 17, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 235, 53, 53, 18, 235, 235, 53, 53, 235, 18, 18, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 53, 235, 18, 235, 235, 53, 17, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 17, 16, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 1
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 22, 42, 42, 42, 34, 21, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 42, 35, 24, 24, 24, 42, 35, 23, 23, 23, 34, 48, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 49, 42, 23, 25, 25, 25, 25, 42, 56, 56, 49, 42, 42, 55, 55, 48, 21, 19, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 49, 42, 25, 25, 25, 26, 36, 50, 57, 57, 57, 56, 56, 35, 35, 41, 48, 34, 21, 40, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 23, 49, 43, 36, 26, 26, 36, 57, 57, 57, 57, 57, 57, 42, 24, 24, 24, 23, 22, 34, 34, 47, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 23, 42, 57, 57, 57, 51, 43, 50, 58, 58, 58, 57, 57, 57, 36, 25, 25, 24, 23, 23, 55, 48, 47, 47, 0, 0, 0, 0
    .byte 0, 0, 0, 23, 42, 57, 57, 57, 57, 58, 36, 27, 44, 51, 58, 58, 58, 50, 26, 26, 25, 24, 24, 23, 55, 55, 54, 40, 19, 0, 0, 0
    .byte 0, 0, 21, 35, 56, 57, 57, 57, 58, 37, 28, 29, 29, 29, 28, 44, 58, 36, 27, 26, 25, 25, 24, 23, 55, 55, 55, 54, 33, 18, 0, 0
    .byte 0, 0, 23, 49, 57, 57, 57, 58, 51, 28, 29, 29, 30, 30, 29, 29, 37, 51, 44, 26, 26, 25, 24, 24, 55, 55, 55, 54, 33, 19, 0, 0
    .byte 0, 21, 35, 56, 57, 57, 57, 58, 37, 29, 29, 30, 30, 30, 30, 30, 51, 58, 58, 57, 50, 43, 24, 24, 56, 55, 55, 54, 40, 19, 18, 0
    .byte 0, 34, 49, 56, 57, 57, 57, 51, 28, 29, 30, 31, 31, 31, 31, 38, 58, 58, 58, 57, 57, 57, 56, 42, 49, 55, 55, 54, 47, 19, 18, 0
    .byte 0, 48, 35, 42, 50, 57, 57, 36, 29, 29, 30, 31, 31, 31, 31, 45, 58, 58, 58, 58, 57, 57, 56, 42, 23, 22, 41, 47, 47, 19, 19, 0
    .byte 48, 41, 24, 25, 25, 36, 43, 27, 28, 29, 30, 31, 31, 31, 30, 52, 58, 58, 58, 58, 57, 57, 56, 42, 23, 22, 22, 21, 33, 19, 18, 17
    .byte 55, 35, 24, 25, 25, 26, 44, 51, 51, 27, 29, 30, 31, 31, 29, 59, 58, 58, 58, 57, 57, 57, 56, 35, 23, 22, 22, 21, 20, 47, 53, 235
    .byte 55, 23, 24, 24, 25, 26, 43, 58, 58, 58, 51, 44, 38, 29, 44, 58, 58, 58, 58, 57, 57, 57, 56, 24, 23, 22, 21, 21, 20, 47, 53, 53
    .byte 55, 22, 23, 24, 25, 36, 57, 57, 58, 58, 58, 58, 58, 51, 44, 58, 58, 58, 57, 57, 57, 56, 49, 23, 23, 22, 21, 21, 20, 47, 53, 53
    .byte 55, 22, 23, 24, 24, 36, 57, 57, 57, 58, 58, 58, 58, 44, 28, 28, 37, 43, 57, 57, 57, 56, 42, 23, 22, 22, 21, 20, 33, 53, 53, 53
    .byte 55, 22, 23, 23, 24, 42, 57, 57, 57, 57, 58, 58, 58, 36, 27, 27, 27, 26, 25, 36, 49, 56, 23, 23, 22, 21, 21, 20, 19, 53, 53, 53
    .byte 47, 21, 22, 23, 24, 49, 56, 57, 57, 57, 57, 57, 50, 26, 27, 26, 26, 26, 25, 25, 24, 42, 41, 34, 22, 21, 20, 20, 40, 53, 53, 17
    .byte 18, 48, 34, 22, 23, 49, 56, 56, 57, 57, 57, 57, 50, 26, 26, 26, 25, 25, 25, 24, 24, 49, 55, 55, 48, 33, 33, 19, 235, 53, 53, 16
    .byte 0, 40, 55, 55, 41, 41, 56, 56, 56, 56, 56, 57, 35, 25, 25, 25, 25, 24, 24, 24, 35, 48, 55, 55, 54, 54, 54, 235, 235, 53, 53, 0
    .byte 0, 33, 54, 55, 55, 34, 22, 42, 56, 56, 56, 49, 24, 24, 24, 24, 24, 24, 23, 23, 41, 55, 55, 55, 54, 54, 54, 235, 18, 17, 16, 0
    .byte 0, 19, 47, 54, 55, 34, 22, 23, 23, 35, 42, 49, 24, 24, 24, 23, 23, 23, 23, 22, 48, 55, 54, 54, 54, 54, 53, 18, 235, 17, 16, 0
    .byte 0, 0, 47, 54, 54, 41, 22, 22, 22, 23, 23, 41, 49, 34, 23, 23, 23, 22, 22, 41, 55, 54, 54, 54, 54, 53, 235, 18, 17, 16, 0, 0
    .byte 0, 0, 18, 54, 54, 40, 21, 21, 22, 22, 22, 48, 55, 55, 55, 48, 34, 22, 21, 54, 54, 54, 54, 54, 53, 53, 18, 17, 17, 16, 0, 0
    .byte 0, 0, 0, 235, 54, 54, 20, 21, 21, 21, 21, 48, 55, 55, 55, 55, 55, 54, 40, 47, 54, 54, 54, 53, 53, 235, 17, 17, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 53, 47, 40, 20, 20, 20, 33, 54, 54, 54, 54, 54, 54, 40, 20, 33, 19, 235, 53, 53, 235, 17, 17, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 18, 19, 47, 19, 20, 40, 54, 54, 54, 54, 54, 47, 19, 19, 19, 19, 18, 18, 53, 17, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 18, 235, 53, 235, 235, 54, 54, 54, 54, 53, 19, 19, 18, 18, 18, 235, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 53, 53, 18, 18, 235, 235, 53, 18, 18, 18, 18, 17, 17, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 17, 235, 235, 235, 53, 17, 17, 17, 17, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 17, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 2
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 22, 42, 56, 49, 23, 22, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 23, 24, 24, 24, 42, 49, 35, 24, 23, 34, 48, 48, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 41, 23, 24, 25, 25, 35, 56, 56, 56, 56, 49, 42, 49, 55, 55, 41, 21, 33, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 42, 24, 25, 25, 25, 50, 57, 57, 57, 57, 57, 49, 24, 24, 35, 41, 34, 22, 21, 40, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 49, 49, 43, 36, 25, 50, 57, 57, 57, 57, 57, 57, 36, 25, 25, 24, 24, 23, 48, 34, 41, 40, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 42, 56, 57, 57, 57, 36, 43, 58, 58, 58, 58, 57, 43, 26, 26, 25, 25, 24, 35, 55, 55, 48, 47, 40, 0, 0, 0, 0
    .byte 0, 0, 0, 35, 56, 57, 57, 57, 36, 27, 28, 27, 44, 51, 58, 51, 27, 27, 26, 26, 25, 24, 42, 56, 55, 55, 47, 20, 19, 0, 0, 0
    .byte 0, 0, 34, 56, 56, 57, 57, 51, 27, 28, 28, 29, 29, 29, 28, 51, 28, 27, 27, 26, 25, 25, 42, 56, 55, 55, 55, 229, 20, 235, 0, 0
    .byte 0, 0, 41, 56, 57, 57, 57, 27, 28, 28, 29, 29, 30, 30, 37, 58, 58, 51, 44, 26, 26, 25, 42, 56, 55, 55, 55, 236, 20, 19, 0, 0
    .byte 0, 34, 56, 56, 57, 57, 44, 27, 28, 29, 29, 30, 30, 30, 52, 59, 58, 58, 58, 57, 50, 43, 49, 56, 56, 55, 55, 47, 20, 19, 235, 0
    .byte 0, 34, 56, 56, 57, 50, 26, 28, 28, 29, 30, 31, 31, 30, 59, 59, 58, 58, 58, 57, 57, 50, 24, 42, 49, 55, 55, 47, 20, 19, 18, 0
    .byte 0, 23, 35, 42, 50, 43, 27, 28, 29, 29, 30, 31, 31, 45, 59, 59, 58, 58, 58, 58, 57, 50, 25, 24, 23, 22, 41, 40, 20, 19, 19, 0
    .byte 48, 23, 24, 25, 36, 51, 44, 27, 28, 29, 30, 31, 30, 59, 59, 59, 58, 58, 58, 58, 57, 35, 25, 24, 23, 22, 22, 21, 40, 40, 18, 17
    .byte 41, 23, 24, 25, 36, 57, 57, 51, 51, 27, 29, 30, 45, 59, 59, 59, 58, 58, 58, 57, 57, 35, 25, 24, 23, 22, 22, 21, 47, 54, 53, 235
    .byte 41, 23, 24, 24, 35, 57, 57, 58, 58, 58, 51, 45, 52, 59, 59, 58, 58, 58, 58, 57, 50, 25, 24, 24, 23, 22, 21, 33, 54, 54, 53, 235
    .byte 41, 23, 23, 24, 49, 57, 57, 57, 58, 58, 58, 51, 29, 37, 44, 58, 58, 58, 57, 57, 50, 25, 24, 23, 23, 22, 21, 33, 54, 54, 53, 235
    .byte 41, 22, 23, 24, 49, 57, 57, 57, 57, 58, 58, 44, 28, 28, 28, 28, 37, 43, 57, 57, 35, 25, 24, 23, 22, 22, 21, 33, 54, 53, 53, 17
    .byte 41, 22, 23, 23, 49, 56, 57, 57, 57, 57, 58, 37, 28, 28, 27, 27, 27, 26, 25, 36, 35, 24, 23, 23, 22, 21, 21, 47, 54, 53, 53, 17
    .byte 33, 22, 22, 23, 49, 56, 56, 57, 57, 57, 50, 26, 27, 27, 27, 26, 26, 26, 25, 43, 56, 56, 41, 34, 22, 21, 20, 47, 54, 53, 53, 17
    .byte 40, 48, 34, 41, 56, 56, 56, 56, 57, 57, 50, 26, 26, 26, 26, 26, 25, 25, 25, 49, 56, 56, 55, 55, 48, 33, 40, 54, 53, 53, 53, 16
    .byte 0, 54, 55, 48, 34, 48, 56, 56, 56, 56, 35, 25, 25, 25, 25, 25, 25, 24, 35, 56, 56, 55, 55, 55, 54, 54, 47, 40, 235, 53, 53, 0
    .byte 0, 54, 54, 55, 34, 23, 22, 42, 56, 56, 23, 24, 24, 24, 24, 24, 24, 24, 49, 55, 55, 55, 55, 55, 54, 54, 19, 19, 18, 17, 16, 0
    .byte 0, 235, 54, 54, 34, 22, 22, 23, 23, 42, 42, 23, 24, 24, 24, 23, 23, 35, 55, 55, 55, 55, 54, 54, 54, 47, 19, 18, 235, 17, 16, 0
    .byte 0, 0, 54, 54, 40, 21, 22, 22, 22, 34, 55, 55, 49, 34, 23, 23, 23, 48, 55, 55, 55, 54, 54, 54, 54, 19, 18, 18, 17, 16, 0, 0
    .byte 0, 0, 235, 54, 47, 21, 21, 21, 22, 41, 55, 55, 55, 55, 55, 48, 34, 55, 55, 54, 54, 54, 54, 54, 18, 18, 18, 17, 17, 16, 0, 0
    .byte 0, 0, 0, 235, 54, 33, 20, 21, 21, 41, 55, 55, 55, 55, 55, 55, 41, 21, 40, 47, 54, 54, 54, 235, 18, 18, 17, 17, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 235, 19, 20, 20, 20, 40, 54, 54, 54, 54, 54, 40, 20, 20, 20, 33, 19, 235, 235, 18, 18, 17, 17, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 18, 235, 47, 19, 54, 54, 54, 54, 54, 54, 33, 20, 19, 19, 19, 19, 18, 53, 53, 17, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 53, 53, 18, 235, 54, 54, 54, 40, 19, 19, 19, 18, 18, 235, 53, 53, 16, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 53, 235, 18, 18, 235, 235, 18, 18, 18, 18, 18, 17, 53, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17, 235, 235, 53, 53, 17, 17, 17, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 17, 16, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 3
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 22, 56, 42, 41, 23, 22, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 24, 24, 35, 49, 56, 49, 35, 24, 42, 48, 55, 48, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 22, 24, 24, 24, 49, 56, 56, 56, 56, 49, 24, 35, 49, 55, 48, 22, 34, 40, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 23, 24, 25, 35, 50, 57, 57, 57, 57, 50, 43, 25, 24, 24, 35, 42, 34, 22, 41, 40, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 56, 49, 43, 36, 57, 57, 57, 57, 57, 57, 44, 26, 26, 25, 25, 24, 42, 55, 48, 34, 55, 40, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 56, 56, 57, 43, 26, 36, 43, 58, 58, 58, 43, 27, 27, 26, 26, 25, 25, 49, 56, 55, 55, 48, 33, 40, 0, 0, 0, 0
    .byte 0, 0, 0, 49, 56, 57, 57, 26, 27, 27, 28, 27, 44, 51, 27, 28, 27, 27, 26, 26, 25, 49, 56, 56, 55, 48, 21, 20, 40, 0, 0, 0
    .byte 0, 0, 41, 56, 56, 57, 36, 27, 27, 28, 28, 29, 29, 51, 58, 44, 28, 27, 27, 26, 36, 56, 56, 56, 55, 55, 21, 20, 33, 235, 0, 0
    .byte 0, 0, 56, 56, 57, 42, 26, 27, 28, 28, 29, 29, 45, 59, 58, 58, 58, 51, 44, 26, 36, 57, 56, 56, 55, 55, 48, 21, 20, 40, 0, 0
    .byte 0, 48, 56, 56, 50, 26, 27, 27, 28, 29, 29, 30, 52, 59, 59, 59, 58, 58, 58, 57, 43, 42, 49, 56, 56, 55, 48, 21, 20, 19, 235, 0
    .byte 0, 41, 56, 56, 42, 26, 27, 28, 28, 29, 30, 45, 59, 59, 59, 59, 58, 58, 58, 57, 36, 25, 24, 42, 49, 55, 48, 21, 20, 19, 235, 0
    .byte 0, 23, 35, 49, 43, 26, 27, 28, 29, 29, 30, 52, 59, 59, 59, 59, 58, 58, 58, 51, 26, 26, 25, 24, 23, 22, 34, 20, 20, 19, 235, 0
    .byte 20, 23, 24, 35, 57, 50, 44, 27, 28, 29, 38, 59, 59, 59, 59, 59, 58, 58, 58, 36, 26, 26, 25, 24, 23, 22, 34, 54, 47, 40, 18, 17
    .byte 22, 23, 24, 42, 57, 57, 57, 51, 51, 27, 44, 59, 59, 59, 59, 59, 58, 58, 58, 37, 26, 25, 25, 24, 23, 22, 34, 54, 54, 54, 53, 235
    .byte 22, 23, 24, 49, 57, 57, 57, 58, 58, 58, 37, 37, 52, 59, 59, 58, 58, 58, 51, 27, 26, 25, 24, 24, 23, 22, 41, 54, 54, 54, 53, 18
    .byte 22, 23, 23, 49, 56, 57, 57, 57, 58, 44, 28, 29, 29, 37, 44, 58, 58, 58, 44, 26, 26, 25, 24, 23, 23, 22, 48, 54, 54, 54, 53, 18
    .byte 22, 22, 35, 56, 56, 57, 57, 57, 57, 36, 28, 28, 28, 28, 28, 28, 37, 43, 26, 26, 25, 25, 24, 23, 22, 22, 48, 54, 54, 53, 53, 17
    .byte 21, 22, 34, 56, 56, 56, 57, 57, 57, 26, 27, 27, 28, 28, 27, 27, 27, 44, 57, 43, 35, 24, 23, 23, 22, 41, 54, 54, 54, 53, 53, 17
    .byte 20, 22, 34, 56, 56, 56, 56, 57, 50, 26, 26, 27, 27, 27, 27, 26, 26, 43, 57, 56, 56, 56, 41, 34, 22, 41, 54, 54, 54, 53, 53, 17
    .byte 47, 48, 41, 48, 56, 56, 56, 56, 42, 25, 26, 26, 26, 26, 26, 26, 36, 57, 56, 56, 56, 56, 55, 55, 48, 33, 47, 54, 53, 53, 17, 16
    .byte 0, 54, 55, 34, 34, 48, 56, 56, 42, 25, 25, 25, 25, 25, 25, 25, 42, 56, 56, 56, 56, 55, 55, 55, 40, 20, 33, 40, 235, 53, 17, 0
    .byte 0, 54, 54, 34, 22, 23, 22, 42, 35, 24, 24, 24, 24, 24, 24, 24, 49, 56, 56, 55, 55, 55, 55, 55, 40, 20, 19, 19, 18, 17, 16, 0
    .byte 0, 47, 54, 20, 21, 22, 22, 23, 55, 49, 42, 23, 24, 24, 24, 42, 56, 56, 55, 55, 55, 55, 54, 54, 20, 19, 19, 18, 235, 17, 16, 0
    .byte 0, 0, 54, 47, 21, 21, 22, 22, 55, 55, 55, 55, 49, 34, 23, 41, 55, 55, 55, 55, 55, 54, 54, 33, 19, 19, 18, 18, 17, 16, 0, 0
    .byte 0, 0, 235, 54, 20, 21, 21, 21, 55, 55, 55, 55, 55, 55, 55, 34, 48, 55, 55, 54, 54, 54, 47, 19, 19, 18, 18, 17, 16, 16, 0, 0
    .byte 0, 0, 0, 54, 40, 20, 20, 21, 54, 55, 55, 55, 55, 55, 41, 21, 21, 21, 40, 47, 54, 54, 19, 19, 18, 18, 17, 16, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 18, 19, 20, 20, 54, 54, 54, 54, 54, 54, 20, 20, 20, 20, 20, 33, 40, 235, 18, 18, 18, 17, 17, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 18, 235, 47, 54, 54, 54, 54, 54, 40, 20, 20, 20, 19, 19, 19, 235, 53, 53, 53, 17, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 53, 235, 18, 235, 54, 47, 19, 19, 19, 19, 19, 18, 235, 53, 53, 53, 16, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 53, 18, 18, 18, 235, 18, 18, 18, 18, 18, 53, 53, 53, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17, 235, 53, 53, 53, 17, 17, 53, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 16, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 4
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 22, 42, 42, 23, 23, 22, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 24, 35, 49, 56, 56, 49, 35, 42, 56, 55, 55, 34, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 22, 24, 24, 49, 56, 56, 56, 56, 49, 24, 23, 35, 49, 48, 22, 22, 34, 33, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 23, 24, 42, 50, 57, 57, 57, 57, 43, 25, 25, 25, 24, 24, 42, 42, 34, 22, 48, 47, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 56, 49, 35, 50, 57, 57, 57, 57, 43, 26, 26, 26, 26, 25, 24, 49, 56, 55, 48, 41, 48, 40, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 56, 56, 42, 26, 26, 36, 43, 58, 51, 26, 27, 27, 27, 26, 26, 35, 56, 56, 56, 55, 48, 34, 33, 33, 0, 0, 0, 0
    .byte 0, 0, 0, 49, 56, 42, 26, 26, 27, 27, 28, 37, 51, 37, 27, 28, 27, 27, 26, 43, 57, 56, 56, 56, 55, 21, 21, 20, 40, 0, 0, 0
    .byte 0, 0, 49, 56, 49, 25, 26, 27, 27, 28, 28, 44, 58, 58, 58, 44, 28, 27, 27, 50, 57, 56, 56, 56, 55, 22, 21, 20, 40, 235, 0, 0
    .byte 0, 0, 56, 56, 35, 26, 26, 27, 28, 28, 37, 58, 59, 59, 58, 58, 58, 51, 44, 57, 57, 57, 56, 56, 55, 22, 21, 21, 33, 47, 0, 0
    .byte 0, 48, 56, 49, 25, 26, 27, 27, 28, 29, 51, 59, 59, 59, 59, 59, 58, 58, 44, 26, 36, 42, 49, 56, 56, 22, 22, 21, 20, 47, 235, 0
    .byte 0, 41, 56, 35, 25, 26, 27, 28, 28, 37, 59, 59, 59, 59, 59, 59, 58, 58, 27, 27, 26, 25, 24, 42, 49, 22, 22, 21, 20, 19, 53, 0
    .byte 0, 23, 42, 43, 36, 26, 27, 28, 29, 51, 59, 59, 59, 59, 59, 59, 58, 51, 28, 27, 26, 26, 25, 24, 23, 48, 41, 20, 20, 19, 53, 0
    .byte 20, 23, 42, 56, 57, 50, 44, 27, 37, 58, 59, 59, 59, 59, 59, 59, 58, 37, 28, 27, 26, 26, 25, 24, 23, 55, 55, 54, 47, 40, 53, 17
    .byte 22, 23, 56, 56, 57, 57, 57, 51, 44, 51, 59, 59, 59, 59, 59, 59, 58, 28, 28, 27, 26, 25, 25, 24, 23, 55, 55, 54, 54, 54, 19, 235
    .byte 22, 23, 56, 56, 57, 57, 57, 58, 28, 29, 28, 37, 52, 59, 59, 58, 44, 28, 27, 27, 26, 25, 24, 24, 230, 55, 55, 54, 54, 54, 18, 18
    .byte 22, 23, 48, 56, 56, 57, 57, 51, 27, 28, 28, 29, 29, 37, 44, 58, 37, 27, 27, 26, 26, 25, 24, 23, 34, 55, 55, 54, 54, 54, 18, 18
    .byte 22, 22, 48, 56, 56, 57, 57, 43, 27, 27, 28, 28, 28, 28, 28, 37, 51, 44, 26, 26, 25, 25, 24, 23, 48, 55, 55, 54, 54, 53, 18, 17
    .byte 21, 34, 55, 56, 56, 56, 57, 36, 26, 27, 27, 27, 28, 28, 27, 43, 57, 57, 57, 43, 35, 24, 23, 23, 55, 55, 54, 54, 54, 53, 18, 17
    .byte 20, 22, 48, 56, 56, 56, 56, 25, 26, 26, 26, 27, 27, 27, 26, 57, 57, 57, 57, 56, 56, 56, 41, 22, 55, 55, 54, 54, 54, 53, 18, 17
    .byte 47, 48, 48, 48, 56, 56, 56, 25, 25, 25, 26, 26, 26, 26, 36, 57, 57, 57, 56, 56, 56, 56, 55, 34, 34, 47, 47, 54, 53, 235, 17, 16
    .byte 0, 54, 21, 22, 34, 48, 49, 24, 24, 25, 25, 25, 25, 25, 42, 56, 56, 56, 56, 56, 56, 55, 48, 22, 21, 20, 33, 40, 235, 235, 17, 0
    .byte 0, 54, 20, 22, 22, 23, 23, 49, 23, 24, 24, 24, 24, 24, 49, 56, 56, 56, 56, 55, 55, 55, 41, 21, 20, 20, 19, 19, 235, 53, 16, 0
    .byte 0, 47, 47, 21, 21, 22, 22, 55, 55, 49, 42, 23, 24, 35, 56, 56, 56, 56, 55, 55, 55, 48, 20, 20, 20, 19, 19, 18, 235, 16, 16, 0
    .byte 0, 0, 47, 20, 21, 21, 21, 55, 55, 55, 55, 55, 49, 41, 55, 55, 55, 55, 55, 55, 55, 33, 20, 20, 19, 19, 18, 235, 53, 16, 0, 0
    .byte 0, 0, 235, 40, 20, 21, 21, 55, 55, 55, 55, 55, 48, 22, 22, 34, 48, 55, 55, 54, 47, 20, 20, 19, 19, 18, 18, 53, 16, 16, 0, 0
    .byte 0, 0, 0, 235, 33, 20, 20, 54, 54, 55, 55, 55, 41, 21, 21, 21, 21, 21, 40, 40, 33, 20, 19, 19, 18, 18, 17, 16, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 18, 40, 33, 47, 54, 54, 54, 54, 33, 21, 21, 20, 20, 20, 20, 40, 47, 18, 18, 18, 18, 17, 16, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 235, 235, 47, 54, 54, 54, 47, 20, 20, 20, 20, 20, 19, 40, 53, 53, 53, 53, 53, 17, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 53, 18, 18, 235, 40, 19, 19, 19, 19, 19, 18, 53, 53, 53, 53, 53, 17, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 235, 18, 18, 235, 235, 18, 18, 18, 235, 53, 53, 53, 53, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17, 53, 53, 53, 53, 17, 53, 53, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 17, 17, 17, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 5
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 34, 23, 23, 23, 23, 41, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 42, 49, 56, 56, 56, 42, 35, 56, 56, 55, 41, 22, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 22, 35, 49, 56, 56, 56, 49, 35, 24, 25, 23, 35, 42, 23, 22, 21, 48, 33, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 23, 42, 56, 57, 57, 57, 50, 25, 26, 25, 25, 25, 24, 49, 49, 42, 34, 41, 55, 33, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 49, 35, 42, 50, 57, 57, 51, 26, 27, 26, 26, 26, 26, 35, 56, 56, 56, 55, 48, 48, 48, 33, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 56, 42, 25, 26, 26, 36, 44, 37, 27, 27, 27, 27, 27, 26, 50, 57, 56, 56, 56, 55, 22, 21, 20, 33, 0, 0, 0, 0
    .byte 0, 0, 0, 49, 42, 25, 26, 26, 27, 27, 51, 58, 44, 37, 27, 28, 27, 36, 57, 57, 57, 56, 56, 56, 22, 22, 21, 40, 47, 0, 0, 0
    .byte 0, 0, 49, 49, 25, 25, 26, 27, 27, 51, 58, 58, 58, 58, 58, 44, 28, 51, 57, 57, 57, 56, 56, 56, 23, 22, 21, 20, 54, 235, 0, 0
    .byte 0, 0, 56, 35, 25, 26, 26, 27, 37, 58, 58, 58, 59, 59, 58, 58, 51, 37, 43, 57, 57, 57, 56, 56, 23, 22, 21, 21, 47, 54, 0, 0
    .byte 0, 48, 49, 24, 25, 26, 27, 27, 51, 58, 58, 59, 59, 59, 59, 59, 37, 28, 28, 26, 36, 42, 49, 56, 23, 22, 22, 21, 33, 54, 235, 0
    .byte 0, 41, 35, 25, 25, 26, 27, 37, 58, 58, 59, 59, 59, 59, 59, 52, 29, 28, 28, 27, 26, 25, 24, 35, 42, 22, 22, 21, 33, 54, 53, 0
    .byte 0, 35, 49, 35, 36, 26, 27, 51, 58, 58, 59, 59, 59, 59, 59, 45, 29, 29, 28, 27, 26, 26, 25, 42, 56, 48, 41, 20, 229, 54, 53, 0
    .byte 20, 42, 56, 56, 57, 50, 36, 51, 58, 58, 59, 59, 59, 59, 59, 29, 29, 29, 28, 27, 26, 26, 25, 42, 56, 55, 55, 54, 47, 47, 53, 17
    .byte 22, 49, 56, 56, 57, 57, 44, 28, 37, 51, 59, 59, 59, 59, 52, 30, 29, 28, 28, 27, 26, 25, 24, 49, 56, 55, 55, 54, 54, 40, 19, 235
    .byte 22, 55, 56, 56, 57, 57, 44, 27, 28, 29, 28, 37, 52, 59, 37, 29, 29, 28, 27, 27, 26, 25, 24, 56, 55, 55, 55, 54, 54, 40, 18, 18
    .byte 22, 55, 56, 56, 56, 50, 26, 27, 27, 28, 28, 29, 29, 37, 44, 29, 28, 27, 27, 26, 26, 25, 35, 56, 55, 55, 55, 54, 54, 19, 18, 18
    .byte 22, 55, 56, 56, 56, 50, 26, 26, 27, 27, 28, 28, 28, 37, 58, 58, 51, 44, 26, 26, 25, 25, 42, 56, 55, 55, 55, 54, 47, 19, 18, 17
    .byte 21, 55, 55, 56, 56, 35, 25, 26, 26, 27, 27, 27, 28, 51, 58, 58, 57, 57, 57, 43, 35, 24, 49, 55, 55, 55, 54, 54, 47, 19, 18, 17
    .byte 20, 55, 55, 56, 56, 35, 25, 25, 26, 26, 26, 27, 37, 57, 57, 57, 57, 57, 57, 56, 56, 42, 42, 41, 55, 55, 54, 54, 47, 18, 18, 17
    .byte 47, 34, 48, 48, 56, 35, 24, 25, 25, 25, 26, 26, 35, 57, 57, 57, 57, 57, 56, 56, 56, 42, 23, 22, 34, 47, 47, 54, 18, 18, 17, 16
    .byte 0, 236, 21, 22, 34, 42, 23, 24, 24, 25, 25, 25, 50, 57, 57, 56, 56, 56, 56, 56, 48, 22, 22, 22, 21, 20, 33, 40, 18, 235, 17, 0
    .byte 0, 40, 21, 22, 22, 41, 48, 49, 23, 24, 24, 24, 49, 56, 56, 56, 56, 56, 56, 55, 34, 22, 22, 21, 20, 20, 19, 18, 53, 53, 16, 0
    .byte 0, 47, 20, 21, 21, 48, 55, 55, 55, 49, 42, 35, 56, 56, 56, 56, 56, 56, 55, 48, 21, 21, 21, 20, 20, 19, 19, 53, 53, 16, 16, 0
    .byte 0, 0, 40, 20, 21, 48, 55, 55, 55, 55, 55, 34, 34, 41, 55, 55, 55, 55, 55, 41, 21, 21, 20, 20, 19, 19, 235, 53, 53, 16, 0, 0
    .byte 0, 0, 235, 33, 20, 20, 54, 55, 55, 55, 55, 21, 22, 22, 22, 34, 48, 55, 48, 21, 21, 20, 20, 19, 19, 18, 53, 53, 16, 16, 0, 0
    .byte 0, 0, 0, 18, 229, 33, 54, 54, 54, 55, 48, 21, 21, 21, 21, 21, 21, 21, 33, 33, 20, 20, 19, 19, 18, 235, 53, 16, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 19, 40, 47, 54, 54, 54, 47, 21, 21, 21, 21, 20, 20, 40, 54, 54, 47, 18, 18, 18, 235, 53, 16, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 235, 53, 40, 54, 54, 47, 20, 20, 20, 20, 20, 33, 54, 54, 53, 53, 53, 53, 17, 53, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 235, 18, 18, 18, 19, 19, 19, 19, 19, 53, 53, 53, 53, 53, 53, 17, 17, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 53, 18, 18, 53, 53, 235, 18, 18, 53, 53, 53, 53, 53, 53, 17, 17, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 53, 53, 53, 235, 235, 17, 53, 53, 16, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 17, 17, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 6
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 34, 23, 23, 35, 34, 41, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 34, 42, 56, 56, 56, 42, 35, 42, 56, 56, 49, 22, 22, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 34, 42, 56, 56, 56, 42, 24, 25, 25, 25, 23, 42, 35, 23, 22, 41, 48, 33, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 35, 56, 56, 57, 57, 35, 25, 26, 26, 25, 25, 24, 56, 56, 49, 42, 48, 55, 55, 33, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 35, 24, 42, 50, 57, 36, 26, 27, 27, 26, 26, 25, 50, 57, 56, 56, 56, 55, 34, 48, 40, 20, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 42, 25, 25, 26, 26, 50, 43, 26, 27, 27, 27, 27, 43, 57, 57, 57, 56, 56, 41, 23, 22, 21, 33, 33, 0, 0, 0, 0
    .byte 0, 0, 0, 41, 24, 25, 26, 26, 50, 58, 58, 58, 44, 37, 27, 37, 58, 57, 57, 57, 57, 56, 42, 23, 22, 22, 33, 54, 47, 0, 0, 0
    .byte 0, 0, 41, 23, 25, 25, 26, 36, 58, 58, 58, 58, 58, 58, 58, 37, 58, 58, 57, 57, 57, 56, 42, 23, 23, 22, 21, 47, 54, 18, 0, 0
    .byte 0, 0, 42, 24, 25, 26, 26, 51, 58, 58, 58, 58, 59, 59, 51, 29, 28, 37, 43, 57, 57, 57, 42, 24, 23, 22, 21, 40, 54, 54, 0, 0
    .byte 0, 41, 23, 25, 25, 26, 43, 58, 58, 58, 58, 59, 59, 59, 38, 30, 29, 28, 28, 26, 36, 42, 35, 24, 23, 22, 22, 229, 54, 54, 235, 0
    .byte 0, 41, 24, 25, 25, 25, 57, 58, 58, 58, 59, 59, 59, 52, 31, 30, 29, 28, 28, 27, 26, 36, 49, 42, 42, 22, 22, 20, 54, 54, 235, 0
    .byte 0, 48, 49, 35, 36, 43, 57, 58, 58, 58, 59, 59, 59, 38, 31, 30, 29, 29, 28, 27, 26, 36, 56, 56, 56, 48, 41, 33, 54, 54, 53, 0
    .byte 33, 56, 56, 56, 57, 44, 43, 51, 58, 58, 59, 59, 52, 30, 31, 30, 29, 29, 28, 27, 26, 43, 56, 56, 56, 55, 55, 54, 40, 47, 249, 17
    .byte 41, 56, 56, 56, 50, 26, 27, 28, 37, 51, 59, 59, 45, 31, 30, 30, 29, 28, 28, 27, 26, 50, 56, 56, 56, 55, 55, 47, 20, 19, 19, 235
    .byte 41, 55, 56, 56, 50, 26, 27, 27, 28, 29, 28, 45, 38, 30, 30, 29, 29, 28, 27, 27, 36, 57, 56, 56, 55, 55, 55, 47, 20, 19, 18, 235
    .byte 41, 55, 56, 56, 35, 26, 26, 27, 27, 28, 28, 37, 58, 51, 44, 29, 28, 27, 27, 26, 36, 56, 56, 56, 55, 55, 55, 47, 20, 19, 18, 235
    .byte 41, 55, 56, 56, 35, 25, 26, 26, 27, 27, 28, 44, 58, 58, 58, 58, 51, 44, 26, 26, 50, 56, 56, 56, 55, 55, 55, 47, 20, 19, 18, 17
    .byte 41, 55, 55, 56, 35, 25, 25, 26, 26, 27, 27, 51, 58, 58, 58, 58, 57, 57, 57, 43, 49, 56, 56, 55, 55, 55, 54, 33, 19, 19, 18, 17
    .byte 40, 55, 55, 49, 23, 24, 25, 25, 26, 26, 36, 57, 57, 57, 57, 57, 57, 57, 57, 42, 24, 35, 42, 41, 55, 55, 54, 33, 19, 18, 18, 17
    .byte 40, 34, 48, 41, 23, 24, 24, 25, 25, 25, 35, 57, 57, 57, 57, 57, 57, 57, 56, 23, 24, 23, 23, 22, 34, 47, 40, 19, 19, 18, 17, 16
    .byte 0, 21, 21, 22, 34, 35, 23, 24, 24, 25, 49, 57, 57, 57, 57, 56, 56, 56, 49, 24, 23, 23, 22, 22, 21, 20, 40, 235, 18, 235, 17, 0
    .byte 0, 20, 21, 22, 48, 55, 48, 49, 23, 24, 49, 56, 56, 56, 56, 56, 56, 56, 35, 23, 23, 22, 22, 21, 20, 20, 54, 53, 53, 53, 16, 0
    .byte 0, 18, 20, 21, 48, 55, 55, 55, 55, 42, 42, 49, 56, 56, 56, 56, 56, 49, 22, 22, 22, 21, 21, 20, 20, 40, 53, 53, 53, 16, 16, 0
    .byte 0, 0, 33, 20, 33, 55, 55, 55, 55, 41, 23, 23, 34, 41, 55, 55, 55, 34, 22, 22, 21, 21, 20, 20, 19, 53, 53, 53, 53, 16, 0, 0
    .byte 0, 0, 235, 20, 33, 54, 54, 55, 55, 41, 22, 22, 22, 22, 22, 34, 48, 21, 21, 21, 21, 20, 20, 19, 235, 53, 53, 53, 16, 16, 0, 0
    .byte 0, 0, 0, 18, 33, 54, 54, 54, 54, 40, 21, 21, 21, 21, 21, 21, 40, 54, 40, 33, 20, 20, 19, 18, 53, 53, 53, 16, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 18, 47, 54, 54, 54, 20, 20, 21, 21, 21, 21, 40, 54, 54, 54, 54, 47, 18, 18, 53, 53, 53, 16, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 53, 18, 40, 54, 33, 20, 20, 20, 20, 20, 54, 54, 54, 54, 53, 53, 249, 18, 17, 53, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 18, 18, 18, 18, 19, 19, 19, 235, 53, 53, 53, 53, 53, 53, 235, 17, 17, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 18, 235, 53, 53, 235, 235, 53, 53, 53, 53, 53, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 53, 53, 235, 18, 235, 17, 53, 53, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 17, 16, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; Frame 7
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 34, 23, 42, 42, 34, 41, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 56, 56, 49, 35, 24, 35, 42, 56, 42, 22, 22, 21, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 34, 56, 56, 56, 35, 25, 25, 25, 25, 24, 49, 42, 35, 23, 22, 55, 40, 19, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 42, 56, 56, 42, 36, 26, 26, 26, 26, 25, 42, 56, 56, 56, 49, 41, 48, 55, 41, 20, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 24, 24, 42, 50, 26, 26, 26, 27, 27, 26, 43, 57, 57, 57, 56, 56, 42, 23, 34, 48, 21, 33, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 24, 25, 25, 43, 57, 51, 43, 26, 27, 27, 44, 57, 57, 57, 57, 57, 56, 35, 23, 23, 22, 34, 40, 40, 0, 0, 0, 0
    .byte 0, 0, 0, 23, 24, 25, 25, 57, 57, 58, 58, 58, 44, 37, 51, 58, 58, 57, 57, 57, 57, 35, 24, 23, 22, 22, 47, 54, 40, 0, 0, 0
    .byte 0, 0, 21, 24, 25, 25, 50, 57, 58, 58, 58, 58, 58, 37, 28, 44, 58, 58, 57, 57, 50, 25, 24, 23, 23, 22, 48, 54, 47, 18, 0, 0
    .byte 0, 0, 23, 24, 25, 43, 57, 58, 58, 58, 58, 58, 44, 30, 29, 29, 28, 37, 43, 57, 50, 25, 24, 24, 23, 22, 34, 54, 54, 235, 0, 0
    .byte 0, 21, 24, 25, 25, 50, 57, 58, 58, 58, 58, 59, 38, 30, 30, 30, 29, 28, 28, 26, 36, 43, 24, 24, 23, 22, 34, 54, 54, 54, 18, 0
    .byte 0, 22, 24, 25, 43, 57, 57, 58, 58, 58, 59, 45, 31, 31, 31, 30, 29, 28, 28, 26, 50, 57, 56, 42, 42, 22, 34, 54, 54, 54, 18, 0
    .byte 0, 56, 49, 35, 42, 57, 57, 58, 58, 58, 59, 38, 31, 31, 31, 30, 29, 29, 28, 36, 57, 57, 56, 56, 56, 48, 48, 47, 54, 54, 18, 0
    .byte 40, 56, 56, 49, 25, 36, 43, 51, 58, 58, 52, 30, 31, 31, 31, 30, 29, 29, 28, 51, 57, 57, 56, 56, 56, 55, 48, 21, 33, 47, 235, 17
    .byte 41, 56, 56, 35, 25, 26, 27, 28, 37, 51, 37, 30, 31, 31, 30, 30, 29, 28, 28, 50, 57, 57, 56, 56, 56, 55, 48, 21, 20, 19, 18, 53
    .byte 55, 55, 56, 35, 25, 26, 27, 27, 28, 28, 51, 44, 38, 30, 30, 29, 29, 28, 37, 57, 57, 57, 56, 56, 55, 55, 40, 21, 20, 19, 18, 53
    .byte 55, 55, 56, 35, 25, 26, 26, 27, 27, 44, 58, 58, 58, 51, 44, 29, 28, 27, 43, 57, 57, 56, 56, 56, 55, 55, 21, 21, 20, 19, 18, 53
    .byte 55, 55, 49, 24, 24, 25, 26, 26, 27, 51, 58, 58, 58, 58, 58, 58, 51, 44, 57, 57, 57, 56, 56, 56, 55, 55, 21, 20, 20, 19, 18, 53
    .byte 55, 55, 49, 23, 24, 25, 25, 26, 26, 57, 58, 58, 58, 58, 58, 58, 57, 43, 25, 36, 49, 56, 56, 55, 55, 40, 21, 20, 19, 19, 18, 53
    .byte 40, 55, 41, 23, 24, 24, 25, 25, 36, 57, 57, 57, 57, 57, 57, 57, 57, 43, 25, 25, 24, 35, 42, 41, 55, 40, 20, 20, 19, 18, 235, 16
    .byte 18, 34, 41, 22, 23, 24, 24, 25, 43, 57, 57, 57, 57, 57, 57, 57, 50, 25, 25, 24, 24, 23, 23, 22, 34, 33, 33, 19, 19, 18, 17, 16
    .byte 0, 21, 21, 48, 41, 35, 23, 24, 42, 56, 56, 57, 57, 57, 57, 56, 42, 24, 24, 24, 23, 23, 22, 22, 21, 54, 54, 235, 18, 235, 17, 0
    .byte 0, 20, 21, 48, 55, 55, 48, 49, 49, 56, 56, 56, 56, 56, 56, 56, 35, 24, 23, 23, 23, 22, 22, 21, 40, 54, 54, 53, 53, 53, 16, 0
    .byte 0, 19, 20, 47, 55, 55, 55, 55, 23, 35, 42, 49, 56, 56, 56, 49, 23, 23, 23, 22, 22, 21, 21, 20, 54, 54, 53, 53, 53, 17, 16, 0
    .byte 0, 0, 20, 33, 54, 55, 55, 55, 22, 23, 23, 23, 34, 41, 55, 22, 23, 22, 22, 22, 21, 21, 20, 47, 54, 53, 53, 53, 53, 16, 0, 0
    .byte 0, 0, 18, 33, 54, 54, 54, 55, 22, 22, 22, 22, 22, 22, 22, 48, 34, 22, 21, 21, 21, 20, 33, 54, 53, 53, 53, 53, 16, 16, 0, 0
    .byte 0, 0, 0, 19, 40, 54, 54, 54, 21, 21, 21, 21, 21, 21, 41, 55, 55, 54, 40, 33, 20, 33, 47, 53, 53, 53, 53, 16, 16, 0, 0, 0
    .byte 0, 0, 0, 0, 235, 47, 54, 54, 20, 20, 20, 21, 21, 20, 54, 54, 54, 54, 54, 54, 47, 18, 53, 53, 53, 53, 16, 16, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 235, 18, 40, 19, 20, 20, 20, 20, 40, 54, 54, 54, 54, 54, 53, 18, 18, 18, 17, 53, 16, 16, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 235, 18, 18, 235, 18, 19, 40, 54, 54, 53, 53, 53, 53, 235, 18, 18, 17, 17, 16, 16, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 17, 235, 53, 53, 53, 235, 235, 53, 53, 53, 53, 235, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 53, 235, 18, 18, 235, 17, 53, 17, 17, 17, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 17, 16, 16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
