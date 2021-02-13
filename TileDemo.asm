; Assembly Tile Demo
; System: Commander X16
; Version: Emulator R.38+
; Author: Dusan Strakl
; Date: January 2021
; Compiler: CC65
; Build using:	cl65 -t cx16 TileDemo.asm -o TILEDEMO.PRG

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


;main:
;*******************************************************************************
; Section 1 - Change @ character of defualt font into smiley face
;*******************************************************************************
    stz VERA_CTRL                       ; Use Data Register 0
    lda #$10
    sta VERA_HIGH                       ; Set Increment to 1
    lda #$F8
    sta VERA_MID                        ; Set High Byte to $F8
    stz VERA_LOW                        ; Set Low Byte to $00

    ldx #0                              
:   lda Smiley,x                        ; read from Smiley Data
    sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    inx
    cpx #8
    bne :-

;*******************************************************************************
; Section 2 - Build a 16x16 256 color tile in VRAM location $12000
;*******************************************************************************
    stz VERA_CTRL                       ; Use Data Register 0
    lda #$11
    sta VERA_HIGH                       ; Set Increment to 1, High Byte to 1
    lda #$20
    sta VERA_MID                        ; Set Middle Byte to $20
    stz VERA_LOW                        ; Set Low Byte to $00

    ldx #0                              
:   lda Brick,x                         ; read from Brick Data
    sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    inx
    bne :-

;*******************************************************************************
; Section 3 - Configure Layer 0
;*******************************************************************************
    lda #%00000011                      ; 32 x 32 tiles, 8 bits per pixel
    sta $9F2D
    lda #$20                            ; $20 points to $4000 in VRAM
    sta $9F2E                           ; Store to Map Base Pointer

    lda #$93                            ; $48 points to $12000, Width and Height 16 pixel
    sta $9F2F                           ; Store to Tile Base Pointer

;*******************************************************************************
; Section 4 - Fill the Layer 0 with all bricks
;*******************************************************************************
    stz VERA_CTRL                       ; Use Data Register 0
    lda #$10
    sta VERA_HIGH                       ; Set Increment to 1, High Byte to 0
    lda #$40
    sta VERA_MID                        ; Set Middle Byte to $40
    stz VERA_LOW                        ; Set Low Byte to $00

    ldy #32
    lda #0                              
:   ldx #32
:   sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    sta VERA_DATA0                      ; Write Attribute
    dex     
    bne :-
    dey
    bne :--


;*******************************************************************************
; Section 5 - Turn on Layer 0
;*******************************************************************************
    lda $9F29
    ora #%00110000                      ; Bits 4 and 5 are set to 1
    sta $9F29                           ; So both Later 0 and 1 are turned on


;*******************************************************************************
; Section 6 - Change Layer 1 to 256 Color Mode
;*******************************************************************************
    lda $9F34
    ora #%001000                        ; Set bit 3 to 1, rest unchanged
    sta $9F34


;*******************************************************************************
; Section 7 - Clear Layer 1
;*******************************************************************************
    stz VERA_CTRL                       ; Use Data Register 0
    lda #$10
    sta VERA_HIGH                       ; Set Increment to 1, High Byte to 0
    stz VERA_MID                        ; Set Middle Byte to $00
    stz VERA_LOW                        ; Set Low Byte to $00

    lda #30
    sta $02                             ; save counter for rows
    ldy #$01                            ; Color Attribute white on black background
    lda #$20                            ; Blank character                              
    ldx #0
:   sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    sty VERA_DATA0                      ; Write Attribute
    inx     
    bne :-
    dec $02
    bne :-

;*******************************************************************************
; Section 8 - Write to Layer 1 in 256 colors
;*******************************************************************************
    stz VERA_CTRL                       ; Use Data Register 0
    lda #$10
    sta VERA_HIGH                       ; Set Increment to 1, High Byte to 0
    lda #13
    sta VERA_MID                        ; Set Middle Byte to 15th row
    lda #24
    sta VERA_LOW                        ; Set Low Byte to 12th column
    ldx #180
    ldy #0
    lda #0
:   sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    stx VERA_DATA0                      ; Write Attribute
    inx
    iny
    cpy #16
    bne :-


    lda #15
    sta VERA_MID                        ; Set Middle Byte to 15th row
    lda #24
    sta VERA_LOW                        ; Set Low Byte to 12th column
    ldx #16
    ldy #0
:   lda text,y
    sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    stx VERA_DATA0                      ; Write Attribute
    inx
    iny
    cpy #16
    bne :-

    lda #17
    sta VERA_MID                        ; Set Middle Byte to 15th row
    lda #24
    sta VERA_LOW                        ; Set Low Byte to 12th column
    ldx #100
    ldy #0
    lda #0
:   sta VERA_DATA0                      ; Write to VRAM with +1 Autoincrement
    stx VERA_DATA0                      ; Write Attribute
    inx
    iny
    cpy #16
    bne :-


;*******************************************************************************
; Section 9 - Scale Display x2 for resolution of 320 x 240 pixels
;*******************************************************************************
    lda #$40
    sta $9F2A
    sta $9F2B


    rts

text:
    .byte $17,$05,$20,$08,$01,$16,$05,$20,$07,$12,$01,$06,$06,$09,$14,$09


Smiley:
    .byte $3C,$42,$A5,$81,$A5,$99,$42,$3C

Brick:
    .byte 8,8,8,8,8,8,8,229,8,8,8,8,8,8,8,8
    .byte 42,42,42,42,42,42,41,229,8,42,42,42,42,42,42,42
    .byte 42,42,42,42,42,42,41,229,8,42,44,42,42,42,42,42
    .byte 42,42,44,44,42,42,41,229,8,42,42,42,42,42,42,42
    .byte 42,42,42,42,42,42,41,229,8,42,42,42,42,42,42,42
    .byte 42,42,42,42,42,42,41,229,8,42,42,42,42,41,41,42
    .byte 41,41,41,41,41,41,41,229,8,41,41,41,41,41,41,41
    .byte 229,229,229,229,229,229,229,229,229,229,229,229,229,229,229,229
    .byte 229,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    .byte 229,8,8,42,44,44,42,42,42,42,42,42,42,42,42,41
    .byte 229,8,42,42,42,42,42,42,42,42,42,42,42,42,42,41
    .byte 229,8,42,42,42,42,41,41,42,42,42,42,42,42,42,41
    .byte 229,8,42,42,42,42,42,42,42,42,42,42,42,41,42,41
    .byte 229,8,42,42,42,42,42,42,42,42,42,42,42,42,42,41
    .byte 229,8,41,41,41,41,41,41,41,41,41,41,41,41,41,41
    .byte 229,229,229,229,229,229,229,229,229,229,229,229,229,229,229,229