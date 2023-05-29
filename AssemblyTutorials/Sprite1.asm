; Assembly Demo of Sprite Setup
; System: Commander X16
; Version: Emulator R.38+
; Author: Dusan Strakl
; Date: December 2020
; Compiler: CC65
; Build using:	cl65 -t cx16 Sprite1.asm -o SPRITE1.PRG


.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

; I/O Registers
VERA_LOW	= $9F20
VERA_MID	= $9F21
VERA_HIGH	= $9F22
VERA_DATA0	= $9F23
VERA_CTRL	= $9F25

;******************************************************************************
; MAIN PROGRAM
;******************************************************************************
main:

; Define Sprite
    stz VERA_CTRL
    lda #$10
    sta VERA_HIGH
    lda #$40
    sta VERA_MID
    stz VERA_LOW

    ldy #0
:   lda data,Y
    sta VERA_DATA0
    iny 
    bne :-

; Initiate Sprite
    lda $9F29
    ora #%01000000
    sta $9F29

    lda #$11
    sta VERA_HIGH
    lda #$FC
    sta VERA_MID
    stz VERA_LOW

    stz VERA_DATA0
    lda #$82
    sta VERA_DATA0
    lda #$F9
    sta VERA_DATA0
    lda #$03
    sta VERA_DATA0
    stz VERA_DATA0
    stz VERA_DATA0
    lda #%00001100
    sta VERA_DATA0
    lda #%01010000
    sta VERA_DATA0

    rts


data:   .byte 16,16,16,16,16,16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 16,38,38,38,38,38,16, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 16,50,50,50,50,38,16, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 16,50,50,50,38,16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 16,50,50,50,50,38,16, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte 16,50,16,16,50,50,38,16, 0, 0, 0, 0, 0, 0, 0, 0
        .byte  0,16,16, 0,16,50,50,38,16, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0,16,50,50,38,16, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0,16,50,50,38,16, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0,16,50,16, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0,16, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0