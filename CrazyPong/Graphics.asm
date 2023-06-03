; Crazy Pong Demo Game
; System: Commander X16
; Version: Emulator R.41 Update
; Author: Dusan Strakl
; Date: January 2021, Update: November 2022


;******************************************************************************
; Configure Sprites 1:Ball, 2:Left Paddle, 3:Right Paddle
; Inputs: none
;******************************************************************************
ConfigureSprites:
    VERA_SET_ADDR $1FC08, 1             ; SPRITE 1 - Ball
    lda #$00
    sta VERA_DATA0                      ; Address 12:5
    lda #$88
    sta VERA_DATA0                      ; Mode + Address 16:13
    lda BallX
    sta VERA_DATA0                      ; X Position
    stz VERA_DATA0                      ; X Position
    lda BallY
    sta VERA_DATA0                      ; Y Position
    stz VERA_DATA0                      ; Y Position
    lda #%00111100                      ; Turn on in front, Collision Mask 0011
    sta VERA_DATA0
    lda #%00000000                      ; 8 x 8, Palette offset 0
    sta VERA_DATA0

    VERA_SET_ADDR $1FC10, 1             ; SPRITE 2 - Left Paddle
    lda #$02
    sta VERA_DATA0                      ; Address 12:5
    lda #$88
    sta VERA_DATA0                      ; Mode + Address 16:13
    lda LPaddleX
    sta VERA_DATA0                      ; X Position
    stz VERA_DATA0                      ; X Position
    lda LPaddleY
    sta VERA_DATA0                      ; Y Position
    stz VERA_DATA0                      ; Y Position
    lda #%00101100                      ; Turn on in front, Collision Mask 0010
    sta VERA_DATA0
    lda #%10000000                      ; 32 x 8, Palette offset 0
    sta VERA_DATA0

    VERA_SET_ADDR $1FC18, 1             ; SPRITE 3 - Right Paddle
    lda #$02
    sta VERA_DATA0                      ; Address 12:5
    lda #$88
    sta VERA_DATA0                      ; Mode + Address 16:13
    lda RPaddleX
    sta VERA_DATA0                      ; X Position
    lda #1
    sta VERA_DATA0                      ; X Position
    lda RPaddleY
    sta VERA_DATA0                      ; Y Position
    stz VERA_DATA0                      ; Y Position
    lda #%00011100                      ; Turn on in front, Collision Mask 0001
    sta VERA_DATA0
    lda #%10000000                      ; 32 x 8, Palette offset 0
    sta VERA_DATA0

    rts

;******************************************************************************
; Initialize Screen, Layer 1 to 40 x 80 tile mode, leave default memory layout
; Inputs: none
;******************************************************************************
InitScreen:
    lda IEN
    ora #%00000100
    sta IEN                             ; set SPRCOL ON

    lda $9F29
    ora #%01000000
    sta $9F29                           ; set SPRITE ENABLE ON

    lda #$40
    sta $9F2A                           ; Horizontal Scale x2
    sta $9F2B                           ; Vertical Scale x2

    rts

;******************************************************************************
; Prepare Playfield by drawing top, bottom and middle line
; Inputs: none
;******************************************************************************
DisplayPlayfield:
    jsr CLS

    VERA_SET_ADDR $1B000, 1                 ; Draw top line
    lda #$A0
    ldx #$0E
    ldy #40
:   sta VERA_DATA0
    stx VERA_DATA0
    dey
    bne :-

    VERA_SET_ADDR $1CD00, 1              ;  Draw bottom line
    lda #$A0
    ldx #$0E
    ldy #80
:   sta VERA_DATA0
    stx VERA_DATA0
    dey
    bne :-

    VERA_SET_ADDR $1B126, 10            ; Draw Center line
    lda #$6A                            ; Left half
    ldy #14
:   sta VERA_DATA0
    dey
    bne :-
    VERA_SET_ADDR $1B128, 10
    lda #$74                            ; Right half
    ldy #14
:   sta VERA_DATA0
    dey
    bne :-

    rts


;******************************************************************************
; Clear Screen by drawing 40x30 spaces with attribute
; Inputs: none
;******************************************************************************
CLS:
	stz VERA_CTRL
    lda #$11
	sta VERA_HIGH
    lda #$B0
	sta VERA_MID
	stz VERA_LOW

    lda #30
    sta r0L
    lda #$20
    ldx #$B0                            ; Medium Gray on Dark Gray
:   ldy #40
:   sta VERA_DATA0
    stx VERA_DATA0
    dey
    bne :-
    inc VERA_MID
    stz VERA_LOW
    dec r0L
    bne :--
    rts

; X - X position to start display, A digit to display
;******************************************************************************
; Display Digit 0 - 9
; Inputs: A - number to display (should only be 0 - 9)
;         X - Horizontal location of top left corner of digit
;******************************************************************************
DisplayDigit:
    asl 
    asl 
    asl
    asl
    sta Temp1
    lda #$B2
    sta r0H
    txa
    asl 
    sta r0L

    stz VERA_CTRL

    ldy #$BD
    ldx Temp1
    lda #4
    sta Temp2
:   lda #$11
	sta VERA_HIGH
	lda r0H
	sta VERA_MID
	lda r0L
	sta VERA_LOW

    lda Digits,x
    sta VERA_DATA0
    sty VERA_DATA0    
    inx
    lda Digits,x
    sta VERA_DATA0
    sty VERA_DATA0    
    inx
    lda Digits,x
    sta VERA_DATA0
    sty VERA_DATA0    
    inx

    inc r0H
    dec Temp2
    bne :-
 
    rts

;******************************************************************************
; Display Game Over Message
; Inputs: none
;******************************************************************************
DisplayGameOver:

    ldx #$B7
    lda #50
    sta Temp1

start:
    VERA_SET_ADDR $1BE1E,1
    ldy #0
:   lda GameOverMessage,y
    sta VERA_DATA0
    stx VERA_DATA0
    iny
    cpy #10
    bne :-

    stz Temp2
    ldy #0
:   dey
    bne :-
    dec Temp2
    bne :-

    cpx #$B7
    beq :+
    ldx #$B7
    bra :++
:   ldx #$B0

:   dec Temp1
    bne start

    rts


;******************************************************************************
; Display Title Screen
; Inputs: none
;******************************************************************************
DisplayTitle:

    jsr CLS

    lda #<Title
    sta r0L
    lda #>Title
    sta r0H
    lda #$B3
    sta Temp1                           ; Starting rown
    lda #24
    sta Temp2                           ; Row counter
    stz VERA_CTRL
    lda #$11
	sta VERA_HIGH

    ldy #0
:   ldx #44                             ; Column counter  
	lda Temp1
	sta VERA_MID
	lda #16
	sta VERA_LOW
:   lda (r0L),y
    sta VERA_DATA0
    iny
    bne :+
    inc r0H
:   dex
    bne :--
    inc Temp1
    dec Temp2
    bne :---
 
    rts

;******************************************************************************
; Move graphics data from CPU Memory to Video Memory (VRAM)
; Inputs: none
;******************************************************************************
LoadAssets:
    VERA_SET_ADDR $10000, 1
    lda #<SpriteData
    sta r0L
    lda #>SpriteData
    sta r0H

    ldx #2
    ldy #0
:   lda ($02),y
    sta VERA_DATA0
    iny
    bne :-
    inc r0H
    dex
    bne :-

    rts


SpriteData:
; Ball
    .byte $00,$00,$10,$10,$10,$10,$00,$00
    .byte $00,$15,$1D,$1D,$1A,$1A,$10,$00
    .byte $10,$1D,$1F,$1D,$1D,$1A,$18,$10
    .byte $10,$1D,$1D,$1D,$1D,$1A,$18,$10
    .byte $10,$1A,$1D,$1D,$1A,$1A,$18,$10
    .byte $10,$1A,$1A,$1A,$1A,$18,$18,$10
    .byte $00,$10,$18,$18,$18,$18,$10,$00
    .byte $00,$00,$10,$10,$10,$10,$00,$00

; Paddle
    .byte $00,$00,$10,$10,$10,$10,$00,$00
    .byte $00,$10,$2D,$2D,$2D,$3B,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$2D,$3B,$3B,$37,$10,$00
    .byte $00,$10,$37,$37,$37,$37,$10,$00
    .byte $00,$00,$10,$10,$10,$10,$00,$00

Digits:
;0
    .byte $20,$62,$20
    .byte $E1,$20,$61
    .byte $E1,$20,$61
    .byte $7C,$62,$7E
    .byte 0,0,0,0

;1
    .byte $6C,$7B,$20
    .byte $20,$61,$20
    .byte $20,$61,$20
    .byte $20,$61,$20
    .byte 0,0,0,0

;2
    .byte $6C,$62,$20
    .byte $20,$20,$61
    .byte $6C,$E2,$20
    .byte $E1,$62,$7B
    .byte 0,0,0,0

;3
    .byte $6C,$62,$20
    .byte $20,$20,$61
    .byte $20,$E2,$7B
    .byte $6C,$62,$7E
    .byte 0,0,0,0

;4
    .byte $6C,$20,$7B
    .byte $E1,$20,$61
    .byte $7C,$E2,$61
    .byte $20,$20,$61
    .byte 0,0,0,0

;5
    .byte $6C,$62,$7B
    .byte $E1,$20,$20
    .byte $7C,$E2,$7B
    .byte $6C,$62,$7E
    .byte 0,0,0,0

;6
    .byte $20,$62,$20
    .byte $E1,$20,$20
    .byte $E1,$E2,$7B
    .byte $7C,$62,$7E
    .byte 0,0,0,0

;7
    .byte $6C,$62,$7B
    .byte $20,$20,$61
    .byte $20,$E1,$20
    .byte $20,$61,$20
    .byte 0,0,0,0

;8
    .byte $20,$62,$20
    .byte $E1,$20,$61
    .byte $6C,$E2,$7B
    .byte $7C,$62,$7E
    .byte 0,0,0,0

;9
    .byte $20,$62,$20
    .byte $E1,$20,$61
    .byte $20,$E2,$61
    .byte $20,$62,$7E
    .byte 0,0,0,0

GameOverMessage:
    .byte $07,$01,$0D,$05,$20,$20,$0F,$16,$05,$12

Title:
    .byte $20,$B0, $A0,$07, $E2,$07, $61,$B0, $A0,$07, $7F,$07, $7B,$B0, $A0,$07, $FB,$07, $61,$B0, $E2,$07, $A0,$07, $61,$B0, $A0,$07, $61,$B0, $A0,$07, $61,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $A0,$07, $61,$B0, $20,$B0, $A0,$07, $FF,$07, $61,$B0, $A0,$07, $FE,$07, $61,$B0, $FE,$B7, $7E,$07, $7E,$B0, $7C,$07, $A0,$07, $7E,$07, $7E,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $E2,$07, $E2,$07, $61,$B0, $E2,$07, $7C,$07, $61,$B0, $E2,$07, $7C,$07, $61,$B0, $E2,$07, $E2,$07, $61,$B0, $20,$BC, $E2,$07, $61,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC, $20,$BC
    .byte $20,$BC, $EC,$10, $E2,$10, $E2,$10, $E2,$10, $A0,$10, $EC,$10, $E2,$10, $E2,$10, $E2,$10, $A0,$10, $E2,$10, $E2,$10, $FB,$10, $FE,$B0, $E2,$10, $FB,$10, $FE,$B0, $E2,$10, $E2,$10, $E2,$10, $FC,$B0
    .byte $20,$BC, $61,$10, $20,$10, $7B,$10, $20,$10, $E1,$10, $20,$10, $20,$10, $7B,$10, $20,$10, $E1,$10, $20,$10, $20,$10, $7C,$10, $A0,$10, $20,$10, $E1,$10, $20,$10, $20,$10, $20,$10, $20,$10, $E1,$10
    .byte $20,$BC, $61,$70, $20,$70, $20,$00, $20,$70, $E1,$70, $20,$70, $E1,$70, $A0,$70, $20,$70, $E1,$70, $20,$70, $20,$70, $20,$70, $7C,$70, $20,$70, $E1,$70, $20,$70, $E1,$70, $A0,$70, $A0,$70, $A0,$70
    .byte $20,$BC, $61,$70, $20,$70, $7E,$70, $20,$70, $E1,$70, $20,$70, $E1,$70, $A0,$70, $20,$70, $E1,$70, $20,$70, $6C,$70, $20,$70, $20,$70, $20,$70, $E1,$70, $20,$70, $E1,$70, $20,$70, $20,$70, $E1,$70
    .byte $20,$BC, $61,$80, $20,$80, $62,$80, $62,$80, $20,$00, $20,$80, $E1,$80, $A0,$80, $20,$80, $E1,$80, $20,$80, $E1,$80, $7B,$80, $20,$80, $20,$80, $E1,$80, $20,$80, $E1,$80, $A0,$80, $20,$80, $E1,$80
    .byte $62,$B0, $61,$80, $20,$80, $FC,$B0, $7B,$B0, $E1,$B0, $20,$80, $20,$80, $7E,$80, $20,$80, $E1,$80, $20,$80, $E1,$80, $FC,$80, $20,$80, $20,$80, $E1,$80, $20,$80, $20,$80, $E2,$80, $20,$80, $E1,$80
    .byte $FC,$20, $62,$20, $62,$20, $62,$20, $61,$B0, $7C,$B0, $FC,$20, $62,$20, $62,$20, $62,$20, $A0,$20, $62,$20, $FE,$20, $FB,$B0, $62,$20, $62,$20, $FE,$20, $FC,$20, $62,$20, $62,$20, $62,$20, $EC,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $10,$B0, $0C,$B0, $01,$B0, $19,$B0, $05,$B0, $12,$B0, $20,$B0, $31,$B0, $3A,$B0, $20,$B0, $01,$B0, $20,$B0, $2D,$B0, $20,$B0, $15,$B0, $10,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $1A,$B0, $20,$B0, $2D,$B0, $20,$B0, $04,$B0, $0F,$B0, $17,$B0, $0E,$B0, $20,$B0, $20,$B0, $20,$B0 
    .byte $20,$B0, $10,$B0, $0C,$B0, $01,$B0, $19,$B0, $05,$B0, $12,$B0, $20,$B0, $32,$B0, $3A,$B0, $20,$B0, $15,$B0, $10,$B0, $20,$B0, $01,$B0, $12,$B0, $12,$B0, $0F,$B0, $17,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $04,$B0, $0F,$B0, $17,$B0, $0E,$B0, $20,$B0, $01,$B0, $12,$B0, $12,$B0, $0F,$B0, $17,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $10,$B7, $12,$B7, $05,$B7, $13,$B7, $13,$B7, $20,$B7, $01,$B7, $0E,$B7, $19,$B7, $20,$B7, $0B,$B7, $05,$B7, $19,$B7, $20,$B7, $14,$B7, $0F,$B7, $20,$B7, $13,$B7, $14,$B7, $01,$B7, $12,$B7, $14,$B7
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0, $20,$B0
    .byte $04,$B2, $15,$B2, $13,$B2, $01,$B2, $0E,$B2, $20,$B2, $13,$B2, $14,$B2, $12,$B2, $01,$B2, $0B,$B2, $0C,$B2, $3A,$B2, $20,$B2, $0A,$B2, $01,$B2, $0E,$B2, $20,$B2, $32,$B2, $30,$B2, $32,$B2, $31,$B2
