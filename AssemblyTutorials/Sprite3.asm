; Assembly Demo of Sprite Collision Detection
; System: Commander X16
; Version: Emulator R38 - R43
; Author: Dusan Strakl
; Date: December 2020, May 2023
; Compiler: CC65
; Build using:	cl65 -t cx16 Sprite3.asm -o SPRITE3.PRG

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

; Kernal Functions
JOYGET          = $FF56

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

; Interrupt Masks
VSYNC       = $01
SPRCOL      = $04


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
Collision:  .byte   0           ; Flag set when collision is detected
Collided:   .byte   0           ; Flag is set when ships are already in collision

PosX:       .byte   144
PosY:       .byte   208

EnemyX:     .byte   100
EnemyY:     .byte   0

;******************************************************************************
; MAIN PROGRAM
;******************************************************************************
main:
    jsr LoadAssets
    jsr ConfigureSprites
    jsr InitScreen

    ; insert custom IRQ handler
	sei
	lda IRQ_VECTOR
	sta OLD_IRQ_HANDLER
    lda #<IRQHandler
    sta IRQ_VECTOR
    lda IRQ_VECTOR+1
    sta OLD_IRQ_HANDLER+1
    lda #>IRQHandler
    sta IRQ_VECTOR+1
    cli


; MAIN LOOP
;******************************************************************************

loop:
    lda #0
    jsr JOYGET
    eor #$FF
    sta Joy
 
    bra loop
    rts


;******************************************************************************
; IRQ Handler
;******************************************************************************
IRQHandler:

CheckSPRCOL:
	lda $9F27
    and #SPRCOL
    beq checkVSYNC

    ; Collision
    inc Collision                       ; Set Collision flag
 
    lda #SPRCOL
    sta $9F27                           ; Clear SPRCOL

checkVSYNC:
    lda $9F27
    and #VSYNC
    bne ProcessVSYNC
    jmp irq_exit

ProcessVSYNC:
    lda Collision
    beq NoCollision

    inc Collided
    stz Collision

    VERA_SET_ADDR $1FC0F, 1
    lda #%10100111                      ; Sprite 1 Palette offset 7
    sta VERA_DATA0
    jmp MoveAssets

NoCollision:
    lda Collided
    beq MoveAssets

    stz Collided                        ; Clear Collided flag

    VERA_SET_ADDR $1FC0F, 1
    lda #%10100011                      ; Sprite 1 Palette offset 3
    sta VERA_DATA0

MoveAssets:
    lda Joy
    and #JOY_RIGHT
    beq :+
    inc PosX

:   lda Joy
    and #JOY_LEFT
    beq :+
    dec PosX

:   inc EnemyY

    ; Update player
    VERA_SET_ADDR $1FC0A, 1
    lda PosX
    sta VERA_DATA0
    stz VERA_DATA0
    lda PosY
    sta VERA_DATA0

    ; Update Enemy
    VERA_SET_ADDR $1FC12, 1
    lda EnemyX
    sta VERA_DATA0
    stz VERA_DATA0
    lda EnemyY
    sta VERA_DATA0


    lda #VSYNC
    sta $9F27               ; Clear VSYNC Flag

irq_exit:
    jmp (OLD_IRQ_HANDLER)



ConfigureSprites:
    VERA_SET_ADDR $1FC08, 1             ; SPRITE 1 - Player

    lda #$00
    sta VERA_DATA0                      ; Address 12:5
    lda #$08
    sta VERA_DATA0                      ; Mode + Address 16:13

    lda PosX
    sta VERA_DATA0                      ; X Position
    stz VERA_DATA0                      ; X Position

    lda PosY
    sta VERA_DATA0                      ; Y Position
    stz VERA_DATA0                      ; Y Position

    lda #%00111100                      ; Turn on in front, Collision Mask 0011
    sta VERA_DATA0

    lda #%10100011                      ; 32 x 32, Palette offset 7
    sta VERA_DATA0


    VERA_SET_ADDR $1FC10, 1             ; SPRITE 2 - Enemy

    lda #$00
    sta VERA_DATA0                      ; Address 12:5
    lda #$08
    sta VERA_DATA0                      ; Mode + Address 16:13

    lda EnemyX
    sta VERA_DATA0                      ; X Position
    stz VERA_DATA0                      ; X Position

    lda EnemyY
    sta VERA_DATA0                      ; Y Position
    stz VERA_DATA0                      ; Y Position

    lda #%000101110                      ; Turn on in front, V Flip, Collision Mask 0001
    sta VERA_DATA0

    lda #%10101100                      ; 32 x 32, Palette offset 12
    sta VERA_DATA0

    rts


InitScreen:
    lda $9F26
    ora #%00000100
    sta $9F26                           ; set SPRCOL ON

    lda $9F29
    ora #%01000000
    sta $9F29                           ; set SPRITE ENABLE ON

    lda #$40
    sta $9F2A                           ; Horizontal Scale x2
    sta $9F2B                           ; Vertical Scale x2

    ; Clear Layer 1
    VERA_SET_ADDR $1B000, 1
    lda #15
    sta $02
    lda #32                             ; Space
    ldx #06                             ; Blue on Black
    ldy #0
:   sta VERA_DATA0
    stx VERA_DATA0
    iny
    bne :-
    dec $02
    bne :-

    rts

LoadAssets:
    VERA_SET_ADDR $10000, 1

    lda #<SpriteData
    sta $02
    lda #>SpriteData
    sta $03

    ldx #2
    ldy #0
:   lda ($02),y
    sta VERA_DATA0
    iny
    bne :-
    inc $03
    dex
    bne :-

    rts


SpriteData:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,48,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,48,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,48,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,2,50,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,35,67,32,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,2,52,68,50,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,3,68,68,67,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,35,70,102,67,32,0,0,0,0,0
    .byte 0,0,0,0,0,0,52,103,120,100,48,0,0,0,0,0
    .byte 0,0,0,0,0,0,52,103,136,100,48,0,0,0,0,0
    .byte 0,0,0,0,0,0,52,104,136,100,48,0,0,0,0,0
    .byte 0,0,0,0,0,0,52,70,102,68,48,0,0,0,0,0
    .byte 0,0,0,0,0,0,52,68,68,68,48,0,0,0,0,0
    .byte 0,0,0,0,0,0,35,68,68,67,32,0,0,0,0,0
    .byte 0,0,0,0,0,0,35,68,68,67,32,0,0,0,0,0
    .byte 0,0,0,0,0,0,3,68,68,67,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,3,68,68,67,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,2,52,68,50,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,2,52,68,50,0,0,0,0,0,0
    .byte 0,0,0,0,0,2,0,52,68,48,2,0,0,0,0,0
    .byte 0,0,0,0,0,35,68,3,67,4,67,32,0,0,0,0
    .byte 0,0,0,0,2,52,68,3,67,4,68,50,0,0,0,0
    .byte 0,0,0,0,35,68,68,3,67,4,68,67,32,0,0,0
    .byte 0,0,0,2,52,68,67,3,67,3,68,68,50,0,0,0
    .byte 0,0,0,35,68,68,50,0,0,2,52,68,67,32,0,0
    .byte 0,0,2,52,68,67,32,0,0,0,35,68,68,50,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0