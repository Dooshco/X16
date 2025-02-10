;******************************************************************************
; Keyboard Handler
;******************************************************************************
;       This Interrupt handler get called whenever a key is pressed or released
;       we need to loop through the list of all allowed keyboard keys and set
;       state. 
;******************************************************************************

KBDHandler:
        phx
        pha

        sta KeyStore

        ldx #0
keyCodeScan:
        lda Keys,x
        cmp KeyStore                            ; Check if Key is in the table at location x
        bne notPressed

        lda State,x
        beq :+
        jmp exit                                ; It was already pressed, ignore and exit
:       lda #1                                  ; If it was pressed set states
        sta Pressed,x
        sta State,x
        stz Released,x
        jmp exit

notPressed:
        ora #%10000000                          ; create a key release code by setting bit 7
        cmp KeyStore
        bne notReleased

        lda #1                                  ; If it was released set states
        sta Released,x
        stz Pressed,x
        stz State,x
        jmp exit

notReleased:
        inx
        cpx #24
        bne keyCodeScan

        ldx #0
controlKeys:                                    ; If we got though it means the key was not found in the keyboard table
        lda ControlKeys,x
        cmp KeyStore
        beq :+
        jmp notPressed2

:       cpx #11                                 ; Octave down
        bne :++
        lda Octave
        cmp #0
        bne :+
        jmp exit
:       sec
        sbc #$10
        sta Octave
        inc UpdateDisplay
        jmp exit

:       cpx #10                                 ; Octave up
        bne :++
        lda Octave
        cmp #$50
        bne :+
        jmp exit
:       clc
        adc #$10
        sta Octave
        inc UpdateDisplay
        jmp exit

:       cpx #9                                  ; Instrument down
        bne :++
        lda Instrument
        cmp #0
        bne :+
        lda #79
        sta Instrument
        inc UpdateDisplay
        jmp exit
:       sec
        sbc #1
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #8                                  ; Instrument up
        bne :++
        lda Instrument
        cmp #79
        bne :+
        lda #0
        sta Instrument
        inc UpdateDisplay
        jmp exit
:       clc
        adc #1
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #0                                  ; F1 - Piano
        bne :+
        lda #0
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #1                                  ; F2 - Church Organ
        bne :+
        lda #19
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #2                                  ; F3 - Vibraphone
        bne :+
        lda #11
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #3                                  ; F4 - Harmonica
        bne :+
        lda #22
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #4                                  ; F5 - Jazz Guitar
        bne :+
        lda #26
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #5                                  ; F6 - Flute
        bne :+
        lda #73
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #6                                  ; F7 - Violin
        bne :+
        lda #40
        sta Instrument
        inc UpdateDisplay
        jmp exit

:       cpx #7                                  ; F8 - Trumpet
        bne :+
        lda #56
        sta Instrument
        inc UpdateDisplay
        jmp exit


:
notPressed2:
        inx
        cpx #12
        beq exit
        jmp controlKeys

exit:
        pla
        plx

        rts


KeyStore:       .byte 0
KeyReleased:    .byte 0

;                     TB 1  Q  2  W  E  4  R  5  T  6  Y  U  8  I  9  O  P  -  [  =  ] BS  \
Pressed:        .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0     ; Set 1 when pressed, to trigger play, clear after
State:          .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0     ; Set 1 for the whole duration of press
Channel:        .byte $F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F,$F    ; Set Channel 0-7 that the note is played on, $F means free
Released:       .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0     ; Set 1 when the key is pressed and release the channel

; Index          0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23
; Key                1       2           4       5       6           8       9           -       =      BS
;               TAB      Q       W   E       R       T       Y   U       I       O   P       [       ]       \
Keys:   .byte   $10,$02,$11,$03,$12,$13,$05,$14,$06,$15,$07,$16,$17,$09,$18,$0A,$19,$1A,$0C,$1B,$0D,$1C,$0F,$1D

; Release keys bit7 set  F1  F2  F3  F4  F5  F6  F7  F8  ^   v   >   <
ControlKeys:    .byte   $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$D3,$D4,$D9,$CF
