; Synthesizer
; System: Commander X16
; Version: Emulator R.47
; Author: Dusan Strakl
; Date: February 2025
; Compiler: CC65
; Build using:	cl65 -t cx16 Synth.asm -o SYNTH.PRG

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp main

.include "X16.inc"
.include "Keyboard.asm"
.include "Graphics.asm"


Instrument:     .byte   0                       ; Store Instrument ID from the library of predefined Patches 0-127
Counter:        .byte   0                       ; General Purpose counter, to be used locally only
UpdateDisplay:  .byte   0                       ; Flag to indicate we need to update Octave and Instrument


;                        C   C#  D   D#  E   F   F#  G   G#  A   A#  B   C   C#  D   D#  E   F   F#  G   G#  A   A#  B
Notes:          .byte   $0E,$10,$11,$12,$14,$15,$16,$18,$19,$1A,$1C,$1D,$1E,$20,$21,$22,$24,$25,$26,$28,$29,$2A,$2C,$2D
Octave:         .byte   $20

Channels:       .byte   $F,$F,$F,$F,$F,$F,$F,$F         ; 8 YM Channels, $F means unused,


main:
        jsr InitScreen
        jsr YMInit
        jsr SetInstrument

	sei                                     ; Insert custom Keyboard interrupt handler
        lda #<KBDHandler
        sta KEYVec
        lda #>KBDHandler
        sta KEYVec+1
        cli

loop:
        jsr UpdateKeys

        lda UpdateDisplay                       ; Check if Octave or Instrument changed in Keyboard handler
        cmp #0
        beq :+
        jsr DisplayOctave                       ; Yes, update Octave to the screen
        jsr SetInstrument                       ; Yes, update Instrument
        jsr DisplayInstrument                   ; Yes, display new instrument to the screen
        stz UpdateDisplay

        ; Loop through newly pressed keys, find available channel and play the note
:       stz Counter
playLoop:
        ldx Counter
        lda Pressed,x
        cmp #1
        bne :+

        jsr PlayNote                            ; Key was pressed, play note
        ldx Counter
        stz Pressed,x
        bra :++

:       lda Released,x
        cmp #1
        bne :+

        lda Channel,x
        tay
        lda #$F
        sta Channels,y 
        sta Channel,x
        stz Released,x
        sty Ch
        jsr ClearChannel

:       inc Counter
        lda Counter
        cmp #24
        bne playLoop

        jmp loop

        rts




;******************************************************************************
YMInit:
;******************************************************************************
;       Initialize YM chip using Kernal functions and predefined sounds
;******************************************************************************
        lda #10                                 ; Audio bank number
        sta $01                                 ; ROM bank register
        jsr ym_init

;        lda #4                                 ; Not needed if we stay on Audio ROM bank
;        sta $01
        rts


;******************************************************************************
SetInstrument:
;******************************************************************************
;       Load Instrument value to all 8 channels
;******************************************************************************
        stz Counter                             ; Initialize all channels to Piano
:       ldx Instrument                          ; Patch id 0=Piano 19 organ
        lda Counter                             ; Channel 0 -7
        sec                                     ; Use Patch ID and not address
        jsr ym_loadpatch
        inc Counter
        lda Counter
        cmp #8
        bne :-
        rts


;******************************************************************************
PlayNote:
;******************************************************************************
;       Play a note on first available channel
;       X and Counter contains the index of the key pressed
;******************************************************************************        
        ldy #0                                  ; Find available channel, starting with 0
chLoop: lda Channels,y
        cmp #$F                                 ; Is channel free
        beq play                                ; Yes, play the note
        iny
        cpy #8
        bne chLoop                              ; No, keep searching
        rts                                     ; no available channels, ignore the note

play:   sty Ch                                  ; Channel found, store in Ch
        lda #0
        sta Channels,y                          ; Mark channel as used
        tya
        sta Channel,x                           ; Write Channel used to the Key list so we can release later

        ; Find the Note to play
        ldy Counter
        lda Notes,y                             ; KC - Key Code - Note
        clc
        adc Octave
        tax
        ldy #0                                  ; KF - Key Fraction
        lda Ch                                  ; Channel
        clc                                     ; Initiate 
        jsr ym_playnote

        rts



;******************************************************************************
ClearChannel:
;******************************************************************************
;       Clear a channel
;       Ch contains the Channel
;******************************************************************************
        lda Ch
        jsr ym_release
        rts


Ch:     .byte 0
