; Paralax Demo using one layer and LINE Interrupts
; Author:		Dusan Strakl
; More Info:	8BITCODING.COM
;
; System:		Commander X16
; Version:		Emulator R.38+
; Compiler:		CC65
; Build using:	cl65 -t cx16 Para.asm  -o PARA.PRG

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

VERA_LOW		= $9F20
VERA_MID		= $9F21
VERA_HIGH		= $9F22
VERA_DATA0		= $9F23
VERA_CTRL	    = $9F25
IRQ_VECTOR 		= $0314
OLD_IRQ_HANDLER = $06

IEN             = $9F26
ISR             = $9F27
IRQ_LINE        = $9F28

jmp main

; Variables
Index:      .byte 0
LineLO:     .byte 0,  80, 160, 240, 64, 144
LineHI:     .byte 0,   0,   0,   0,   1,   1
Increment:  .byte 1,   2,   3,   4,   5,   6
ScrollLO:   .byte 0,   0,   0,   0,   0,   0
ScrollHI:   .byte 0,   0,   0,   0,   0,   0


main:
;*******************************************************************************

    lda #$40                            ; 2X Scale Horizontally and Vertically
    sta $9F2A
    sta $9F2B

    jsr CustomTiles
    jsr DrawWaves

    ldx Index                           ; Initialize Line IRQ to first value
    lda LineLO,x 
    sta IRQ_LINE

    lda #%00000011                      ; LINE and VSYNC are active
    sta IEN

	sei 								; insert new IRQ player
	lda IRQ_VECTOR
	sta OLD_IRQ_HANDLER
    lda #<ProcessIRQ
    sta IRQ_VECTOR
    lda IRQ_VECTOR+1
    sta OLD_IRQ_HANDLER+1
    lda #>ProcessIRQ
    sta IRQ_VECTOR+1
    cli

return:
	rts


; ******************************************************************************
; IRQ HANDLER
; ******************************************************************************
ProcessIRQ:
    lda ISR
    and #%00000010
    bne LINE_handler

	jmp (OLD_IRQ_HANDLER)               ; pass through

LINE_handler:
    ldx Index

    clc                                 ; Add Increment to Scroll value
    lda ScrollLO,x
    adc Increment,x
    sta ScrollLO,x 
    bcc :+
    inc ScrollHI,x

:   lda ScrollHI,X                      ; slow down scrolling by half
    lsr 
    sta $9F38                           ; and write to VERA Scroll registers
    lda ScrollLO,x 
    ror 
    sta $9F37

    inx                                 ; go to next Index and wrap around
    cpx #6
    bne :+
    ldx #0
:   stx Index

    lda LineLO,x                        ; set Line IRQ to next value
    sta IRQ_LINE
    lda LineHI,x
    beq :+
    lda #%10000011                      ; Don't forget the IRQ Bit 8
    sta IEN
    jmp LINE_exit
:   lda #%00000011
    sta IEN

LINE_exit:
    lda #%00000010
    sta ISR                             ; Clear LINE flag

    ply                                 ; Restore CPU Registers
    plx
    pla

    rti                                 ; Don't bother going to default IRQ handler


;*******************************************************************************
; Define custom tiles
;*******************************************************************************
CustomTiles:
	stz VERA_CTRL
    lda #$10
	sta VERA_HIGH
	lda #$FB
	sta VERA_MID
	lda #$80
	sta VERA_LOW

    ldx #0                              ; define custom tiles
:   lda TileGraphics,x
    sta VERA_DATA0
    inx
    cpx #32
    bne :-

    rts

;*******************************************************************************
; Draw the colorful waves
;*******************************************************************************
DrawWaves:
	stz VERA_CTRL                       ; Draw background
    lda #$10
	sta VERA_HIGH
	lda #$00
	sta VERA_MID
	lda #$00
	sta VERA_LOW

    ldy #$06
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of blue wave
    ldy #$69
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of brown wave
    ldy #$92
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of red wave
    ldy #$28
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of orange wave
    ldy #$87
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of yellow line
    ldy #$75
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawWave                        ; start of green wave
    ldy #$55
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank
    jsr DrawBlank

    rts


DrawWave:
    ldx #32
:   lda #$70                           
    sta VERA_DATA0
    sty VERA_DATA0
    lda #$71
    sta VERA_DATA0
    sty VERA_DATA0
    lda #$72
    sta VERA_DATA0
    sty VERA_DATA0
    lda #$73
    sta VERA_DATA0
    sty VERA_DATA0
    dex
    bne :-
    rts

DrawBlank:
    ldx #$80
    lda #$20
:   sta VERA_DATA0
    sty VERA_DATA0
    dex
    bne :-
    rts




TileGraphics:
    .byte $00,$00,$00,$00,$01,$07,$1F,$FF
    .byte $07,$1F,$7F,$FF,$FF,$FF,$FF,$FF
    .byte $E0,$F8,$FE,$FF,$FF,$FF,$FF,$FF
    .byte $00,$00,$00,$00,$80,$E0,$F8,$FF

