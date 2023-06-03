; Crazy Pong Demo Game
; System: Commander X16
; Version: Emulator R.43
; Author: Dusan Strakl
; Date: January 2021 - June 2023
; Compiler: CC65
; Build using:	cl65 -t cx16 CrazyPong.asm -o CRAZYPONG.PRG

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
IEN             = $9F26
ISR             = $9F27

; Kernal Functions
JOYGET          = $FF56
GETIN           = $FFE4
kbdbuf_peek     = $FEBD

; Memory Locations
IRQ_VECTOR 		= $0314
OLD_IRQ_HANDLER = $30
r0L             = $02
r0H             = $03

; VRAM Locations
SPRITE_GRAPHICS = $4000
SPRITE1         = $FC08

; Joystick masks
JOY_RIGHT   = $01
JOY_LEFT    = $02
JOY_DOWN    = $04
JOY_UP      = $08
JOY_Y       = $40       ; mapped to A Key
JOY_B       = $80       ; mapped to Z Key
JOY_A_KEY   = JOY_Y
JOY_Z_KEY   = JOY_B

; Interrupt Masks
VSYNC       = $01
SPRCOL      = $04

UP          = $FF
DOWN        = $01

; Game settings
BALLX       = 156*16
BALLY       = 116*16
PADDLEY     = 104

.macro VERA_SET_ADDR addr, increment
	.ifnblank increment
      .if increment < 0
         lda #((^addr) | $08 | ((0-increment) << 4))
      .else
         lda #((^addr) | (increment << 4))
      .endif
	.else
		lda #(^addr) | $10
	.endif

	stz VERA_CTRL
	sta VERA_HIGH
	lda #(>addr)
	sta VERA_MID
	lda #(<addr)
	sta VERA_LOW
.endmacro

jmp main

; Variables
Joy:        .byte   0
Score:      .byte   0

BallX:      .word   BALLX
BallY:      .word   BALLY
DirectionX: .byte   $FF                 ; 1 - Right, -1 - Left
DirectionY: .byte   0                   ; 1 - Down, -1 - Up,  0 - Straight
SpeedX:     .word   32
SpeedY:     .word   0
Angle:      .byte   0                   ; values 0 - 4

LPaddleX:   .byte   4
LPaddleY:   .byte   PADDLEY
LMoving:    .byte   0
LScore:     .byte   0

RPaddleX:   .byte   $35
RPaddleY:   .byte   PADDLEY
RMoving:    .byte   0
RScore:     .byte   0

AngleX:     .byte   32,28,23,16,8
AngleY:     .byte   0,8,16,23,28

Temp1:      .byte   0
Temp2:      .byte   0

.include "Graphics.asm"

;******************************************************************************
; MAIN PROGRAM
;******************************************************************************
main:
    jsr LoadAssets
    jsr ConfigureSprites
    jsr InitScreen
 
	sei                                 ; insert custom IRQ handler
	lda IRQ_VECTOR
	sta OLD_IRQ_HANDLER
    lda #<IRQHandler
    sta IRQ_VECTOR
    lda IRQ_VECTOR+1
    sta OLD_IRQ_HANDLER+1
    lda #>IRQHandler
    sta IRQ_VECTOR+1
    cli

;******************************************************************************
; NEW GAME LOOP
;******************************************************************************
NewGame:
    lda #<BALLX                         ; Reset Ball position
    sta BallX
    lda #>BALLX
    sta BallX+1
    lda #<BALLY
    sta BallY
    lda #>BALLY
    sta BallY+1
    lda #$FF
    sta DirectionX
    stz DirectionY
    lda #32
    sta SpeedX
    stz SpeedY

    lda #PADDLEY                        ; Reset Paddle positions
    sta LPaddleY
    sta RPaddleY

:   jsr GETIN                           ; Clear Keyboard buffer
    cmp #0
    bne :-

    jsr DisplayTitle

:   jsr GETIN                           ; Wait for Keypress
    cmp #0
    beq :-

    stz Score
    stz LScore
    stz RScore
    jsr DisplayPlayfield

;******************************************************************************
; NEW BALL LOOP
;******************************************************************************
NewBall:
    lda #$C0
    sta BallX
    lda #$09
    sta BallX+1

    lda #$40
    sta BallY
    lda #$07
    sta BallY+1

    lda LScore
    ldx #15
    jsr DisplayDigit
    lda RScore
    ldx #22
    jsr DisplayDigit
        
;******************************************************************************
; MAIN LOOP
;******************************************************************************
MainLoop:
    lda #0
    jsr JOYGET
    eor #$FF
    sta Joy

    lda Score                           ; Check Score
    beq MainLoop
    cmp #1
    bne :+
    inc LScore
    bra IsGameOver
:   inc RScore

IsGameOver:
    lda LScore
    cmp #9
    beq :+
    lda RScore
    cmp #9
    beq :+
    stz Score
    jmp NewBall

:   lda LScore                          ; Display final score
    ldx #15
    jsr DisplayDigit
    lda RScore
    ldx #22
    jsr DisplayDigit

    jsr DisplayGameOver                 ; Game over message
    jmp NewGame

    rts

;******************************************************************************
; IRQ Handler
;******************************************************************************
IRQHandler:
    pha                                 ; Save CPU Regsiters
    phx
    phy

 	lda $9F20                           ; Save VERA registers
    pha
	lda $9F21
    pha
	lda $9F22
    pha
	lda $9F25
    pha

CheckSPRCOL:
	lda ISR
    and #SPRCOL
    bne SPRCOLHandler
    jmp CheckVSYNC

;*************************************************************************
; SPRCOL Handler - Process collision = bounce from paddle
;*************************************************************************
SPRCOLHandler:
    lda DirectionX                      ; Flip X Direction
    eor #$FF
    inc
    sta DirectionX

    lda ISR                             ; Left or Right paddle
    and #$F0
    cmp #$20
    bne RCollision
    jmp LCollision


RCollision:
    lda #$D0                            ; Put ball out of collision
    sta BallX
    lda #$12
    sta BallX+1

isRMoving: 
    lda RMoving
    bne RPMov

    jmp exit_sprcol                     ; Paddle is not moving, exit

RPMov:                                  ; Right Paddle is moving
    lda DirectionY
    bne :+

    ldx RMoving                         ; Paddle is moving, Ball is not moving
    stx DirectionY                      ; now ball is moving in same direction
    ldx #1
    stx Angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x 
    sta SpeedY
    jmp exit_sprcol


:   cmp RMoving
    bne :++

    ldx Angle                           ; Paddle and Ball are moving in same direction
    inx                                 ; Increase angle
    cpx #5
    bne :+
    jmp exit_sprcol                     ; maximum angle was reached

:   stx Angle                           ; Increase angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x
    sta SpeedY
    jmp exit_sprcol

:   ldx Angle                           ; Paddle and Ball are moving in opposite directions
    dex                                 ; Decrease the angle
    cpx #$FF
    bne :+                              ; Zero angle is reached (we should never get here though)
    jmp exit_sprcol

:   stx Angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x
    sta SpeedY

    cpx #0
    bne :+
    stz DirectionY
:   jmp exit_sprcol


LCollision:
    lda #208                            ; Put ball out of collision
    sta BallX

isLMoving: 
    lda LMoving
    bne LPMov

    jmp exit_sprcol                     ; Paddle is not moving, exit

LPMov:                                  ; Left Paddle is moving
    lda DirectionY
    bne :+

    ldx LMoving                         ; Paddle is moving, Ball is not moving
    stx DirectionY                      ; now ball is movin in same direction
    ldx #1
    stx Angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x 
    sta SpeedY
    jmp exit_sprcol


:   cmp LMoving
    bne :++

    ldx Angle                           ; Paddle and Ball are moving in same direction
    inx                                 ; Increase angle
    cpx #5
    bne :+
    jmp exit_sprcol                     ; maximum angle was reached

:   stx Angle                           ; Increase angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x
    sta SpeedY
    jmp exit_sprcol

:   ldx Angle                           ; Paddle and Ball are moving in opposite directions
    dex                                 ; Decrease the angle
    cpx #$FF
    beq exit_sprcol                     ; Zero angle is reached (we should never get here though)

    stx Angle
    lda AngleX,x
    sta SpeedX
    lda AngleY,x
    sta SpeedY

    cpx #0
    bne :+
    stz DirectionY
:   jmp exit_sprcol
 
exit_sprcol:
    lda #SPRCOL
    sta ISR                             ; Clear SPRCOL

CheckVSYNC:
    lda ISR
    and #VSYNC
    bne VSYNCHandler
    jmp irq_exit

;*************************************************************************
; VSYNC Handler - Game tick, process padles and move ball
;*************************************************************************
VSYNCHandler:

    jsr updatePaddles

    lda DirectionX
    bmi goingLeft

    lda BallX                           ; X direction is positive, going right
    clc 
    adc SpeedX
    sta BallX
    lda BallX+1
    adc SpeedX+1
    sta BallX+1

    lda BallX+1                         ; Check for right edge and score
    cmp #$14
    bne Vertical
    lda #1
    sta Score
    jmp Vertical

goingLeft:                              ; X direction is negative, going left
    lda BallX
    sec 
    sbc SpeedX
    sta BallX
    lda BallX+1
    sbc SpeedX+1
    sta BallX+1

    lda BallX+1                         ; Check for left edge and score
    bpl Vertical
    lda #2
    sta Score

 
Vertical:
    lda DirectionY
    bmi goingUp

 goingDown:                             ; Y direction is positive, going down
    lda BallY
    clc
    adc SpeedY
    sta BallY
    lda BallY+1
    adc #0
    sta BallY+1

    lda BallY+1                         ; Check bottom edge
    cmp #$0E
    bne updateVera
    lda BallY
    sec
    sbc #$00
    bvs updateVera

    sta r0L                             ; Bounce from the bottom
    lda BallY
    sec
    sbc r0L
    sta BallY
    lda #$FF
    sta DirectionY
    jmp updateVera

goingUp:                                ; Y direction is negative, going up
    lda BallY
    sec
    sbc SpeedY
    sta BallY
    lda BallY+1
    sbc #0
    sta BallY+1

    lda BallY+1                         ; Check top edge
    bne updateVera
    lda BallY
    sec
    sbc #128
    bvc updateVera

    sta r0L                             ; Bounce from the top
    lda BallY
    sec
    sbc r0L
    sta BallY

    lda #1
    sta DirectionY

updateVera:
    lda BallX                           ; Calculate X
    sta r0L
    lda BallX+1
    sta r0H

    lsr r0H                             ; Divide X by 16
    ror r0L
    lsr r0H
    ror r0L
    lsr r0H
    ror r0L
    lsr r0H
    ror r0L

    VERA_SET_ADDR $1FC0A, 1
    lda r0L
    sta VERA_DATA0
    lda r0H
    sta VERA_DATA0

    lda BallY                           ; Calculate Y
    sta r0L
    lda BallY+1
    sta r0H

    lsr r0H                             ; Divide Y by 16
    ror r0L
    lsr r0H
    ror r0L
    lsr r0H
    ror r0L
    lsr r0H
    ror r0L

    VERA_SET_ADDR $1FC0C, 1
    lda r0L
    sta VERA_DATA0
    lda r0H
    sta VERA_DATA0

    lda #VSYNC
    sta ISR                             ; Clear VSYNC Flag

irq_exit:
    pla
	sta $9F25                           ; Restore VERA registers
    pla
	sta $9F22
    pla
	sta $9F21
    pla
	sta $9F20

    ply                                 ; Restore CPU Registers
    plx
    pla

    jmp (OLD_IRQ_HANDLER)


;*************************************************************************
; Update Paddles
;*************************************************************************
updatePaddles:
updateRight:
    lda Joy
    and #JOY_DOWN
    beq :++
    lda RPaddleY
    inc
    inc
    cmp #202
    bne :+
    lda #200
:   sta RPaddleY
    lda #1
    sta RMoving
    bra updateLeft

:   lda Joy
    and #JOY_UP
    beq :++
    lda RPaddleY
    dec
    dec
    cmp #6
    bne :+
    lda #8
:   sta RPaddleY
    lda #255
    sta RMoving
    bra updateLeft

:   stz RMoving

updateLeft:
    lda Joy
    and #JOY_Z_KEY
    beq :++
    lda LPaddleY
    inc
    inc
    cmp #202
    bne :+
    lda #200
:   sta LPaddleY
    lda #1
    sta LMoving
    bra paddlesToVera

:   lda Joy
    and #JOY_A_KEY
    beq :++
    lda LPaddleY
    dec
    dec
    cmp #6
    bne :+
    lda #8
:   sta LPaddleY
    lda #255
    sta LMoving
    bra paddlesToVera

:   stz LMoving         ; Not moving


    ; Send new positions to VERA
paddlesToVera:
    VERA_SET_ADDR $1FC14, 1
    lda LPaddleY
    sta VERA_DATA0

    VERA_SET_ADDR $1FC1C, 1
    lda RPaddleY
    sta VERA_DATA0

   rts



