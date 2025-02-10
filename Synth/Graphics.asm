;*******************************************************************************
; GRAPHICS
;*******************************************************************************


;*******************************************************************************
InitScreen:
;*******************************************************************************
;       Initialize graphics, load tiles and draw the static screen
;*******************************************************************************
        jsr LoadTiles

        lda #%00010001                          ; Sprites Off, Layer 1 Off, Layer 1 On, VGA Output
        sta $9F29


        lda #$40                                ; Set 320 x 240 visible pixels = 40 x 30 Tiles
        sta $9F2A                               ; Horizontal Scale x1
        sta $9F2B                               ; Vertical Scale x1


        ; Configure Layer 0 -$04000
        lda #%00010011                      ; 64 x 32 tiles, 8 bits per pixel for 256 colors
        sta $9F2D
        lda #$20                            ; $20 points to $4000 in VRAM
        sta $9F2E                           ; Store to Map Base Pointer

        lda #$90                            ; $90 points to $12000, Width and Height 8 pixel
        sta $9F2F                           ; Store to Tile Base Pointer

        jsr DisplayScreen
        jsr DisplayOctave
        jsr DisplayInstrument

        rts



;*******************************************************************************
DisplayScreen:
;*******************************************************************************
;       Redraw the whole screen 40x30 tiles from the embedded data below
;*******************************************************************************
        lda #30
        sta Counter                             ; Save number or rows

        lda #<ScreenData
        sta ZP_PTR_2
        lda #>ScreenData
        sta ZP_PTR_2+1

        VERA_SET_ADDR $04000,1

nextLine:
        ldx #0
        ldy #0
lineLoop:
        lda (ZP_PTR_2),y
        sta VERA_data0
        stx VERA_data0

        iny
        cpy #40
        bne lineLoop

        lda VERA_addr_low                       ; Move VERA to next row
        clc
        adc #48                                 ; 128 - (2*40) = 48
        sta VERA_addr_low
        lda VERA_addr_high
        adc #0
        sta VERA_addr_high

        lda ZP_PTR_2                            ; Move pointer to Screen data to next row (Y counter)
        clc
        adc #40
        sta ZP_PTR_2
        lda ZP_PTR_2+1
        adc #0
        sta ZP_PTR_2+1

        dec Counter
        bne nextLine

        rts

 


;1234567890123456789012345678901234567890
;
;            SYNTH DEMO V1.0
;                  FOR
;             COMMANDER X16
;
;                  XX
;                  XX
;
;            BY DUSAN STRAKL
;             FEBRUARY 2025
;
;      SOURCE CODE AND TUTORIAL AT
;          WWW.8BITCODING.COM
;
ScreenData:     .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$D3,$D9,$CE,$D4,$C8,$5F,$C4,$C5,$CD,$CF,$5F,$D6,$E1,$EE,$E0,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C6,$CF,$D2,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C3,$CF,$CD,$CD,$C1,$CE,$C4,$C5,$D2,$5F,$D8,$E1,$E6,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$3E,$3F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$FE,$FF,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C2,$D9,$5F,$C4,$D5,$D3,$C1,$CE,$5F,$D3,$D4,$D2,$C1,$CB,$CC,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C6,$C5,$C2,$D2,$D5,$C1,$D2,$D9,$5F,$E2,$E0,$E2,$E5,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$D3,$CF,$D5,$D2,$C3,$C5,$5F,$C3,$CF,$C4,$C5,$5F,$C1,$CE,$C4,$5F,$D4,$D5,$D4,$CF,$D2,$C9,$C1,$CC,$5F,$C1,$D4,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$D7,$D7,$D7,$EE,$E8,$C2,$C9,$D4,$C3,$CF,$C4,$C9,$CE,$C7,$EE,$C3,$CF,$CD,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0
                .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$C0

                .byte   $5F,$5F,$47,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$49,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$67,$68,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$A0,$A1,$A2,$A3,$A4,$A5,$A6,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$6D,$6E,$6F,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$77,$78,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$4A,$4A,$4A,$4A,$4A,$7D,$7E,$7F,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$57,$58,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$58,$59,$4A,$4A,$4A,$8D,$8E,$8F,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$4A,$69,$6A,$6B,$6C,$4A,$4A,$4A,$5D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$5E,$4A,$4A,$4A,$9D,$9E,$9F,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$4A,$79,$79,$79,$79,$4A,$4A,$4A,$5D,$0F,$03,$14,$2A,$00,$00,$09,$0E,$13,$2A,$00,$00,$00,$5E,$4A,$4A,$4A,$AD,$AE,$AF,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$5A,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5B,$5C,$4A,$4A,$4A,$BD,$BE,$BF,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$4F,$5F,$5F,$C0

                .byte   $5F,$5F,$4E,$4A,$4A,$40,$41,$42,$43,$42,$44,$45,$41,$42,$43,$42,$43,$42,$44,$45,$41,$42,$43,$42,$44,$45,$41,$42,$43,$42,$43,$42,$44,$46,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$40,$41,$42,$43,$42,$44,$45,$41,$42,$43,$42,$43,$42,$44,$45,$41,$42,$43,$42,$44,$45,$41,$42,$43,$42,$43,$42,$44,$46,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$40,$41,$8B,$43,$8C,$44,$45,$41,$9B,$43,$9C,$43,$A7,$44,$45,$41,$A8,$43,$A9,$44,$45,$41,$AA,$43,$AB,$43,$AC,$44,$46,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$50,$51,$52,$53,$52,$54,$55,$51,$52,$53,$52,$53,$52,$54,$55,$51,$52,$53,$52,$54,$55,$51,$52,$53,$52,$53,$52,$54,$56,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$60,$61,$62,$63,$62,$64,$65,$61,$62,$63,$62,$63,$62,$64,$65,$61,$62,$63,$62,$64,$65,$61,$62,$63,$62,$63,$62,$64,$66,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$60,$61,$62,$63,$62,$64,$65,$61,$62,$63,$62,$63,$62,$64,$65,$61,$62,$63,$62,$64,$65,$61,$62,$63,$62,$63,$62,$64,$66,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4E,$4A,$4A,$60,$30,$62,$31,$62,$32,$65,$33,$62,$34,$62,$35,$62,$36,$65,$37,$62,$38,$62,$39,$65,$3A,$62,$3B,$62,$3C,$62,$3D,$66,$4A,$4A,$4F,$5F,$5F,$C0
                .byte   $5F,$5F,$4B,$4C,$4C,$70,$71,$72,$73,$72,$74,$75,$71,$72,$73,$72,$73,$72,$74,$75,$71,$72,$73,$72,$74,$75,$71,$72,$73,$72,$73,$72,$73,$76,$4A,$4A,$4D,$5F,$5F,$C0



;*******************************************************************************
UpdateKeys:
;*******************************************************************************
;       Highlight all the pressed keys on the screen. This function is uwrapped
;       for speed.
;       It also displays which of the channels (voices) of AY chip are used
;*******************************************************************************
        ; Display state of keys in the first row - black keys
        VERA_SET_ADDR ($04000+24*128+14),3

        lda #$8B
        ldx State+1
        beq :+
        lda #$B0
:       sta VERA_data0                          ; Key 1

        lda #$8C
        ldx State+3
        beq :+
        lda #$B1
:       sta VERA_data0                          ; Key 2

        lda #$45
        sta VERA_data0                          ; Empty

        lda #$9B
        ldx State+6
        beq :+
        lda #$B2
:       sta VERA_data0                          ; Key 4

        lda #$9C
        ldx State+8
        beq :+
        lda #$B3
:       sta VERA_data0                          ; Key 5

        lda #$A7
        ldx State+10
        beq :+
        lda #$B4
:       sta VERA_data0                          ; Key 6

        lda #$45
        sta VERA_data0                          ; Empty

        lda #$A8
        ldx State+13
        beq :+
        lda #$B5
:       sta VERA_data0                          ; Key 8

        lda #$A9
        ldx State+15
        beq :+
        lda #$B6
:       sta VERA_data0                          ; Key 9

        lda #$45
        sta VERA_data0                          ; Empty

        lda #$AA
        ldx State+18
        beq :+
        lda #$B7
:       sta VERA_data0                          ; Key -

        lda #$AB
        ldx State+20
        beq :+
        lda #$B8
:       sta VERA_data0                          ; Key =

        lda #$AC
        ldx State+22
        beq :+
        lda #$B9
:       sta VERA_data0                          ; Key Backspace

        ; Display state of keys in the second row - White Keys
        VERA_SET_ADDR ($04000+28*128+12),3

        lda #$30
        ldx State
        beq :+
        lda #$F0
:       sta VERA_data0                          ; Key Tab

        lda #$31
        ldx State+2
        beq :+
        lda #$F1
:       sta VERA_data0                          ; Key Q

        lda #$32
        ldx State+4
        beq :+
        lda #$F2
:       sta VERA_data0                          ; Key W

        lda #$33
        ldx State+5
        beq :+
        lda #$F3
:       sta VERA_data0                          ; Key E

        lda #$34
        ldx State+7
        beq :+
        lda #$F4
:       sta VERA_data0                          ; Key R

        lda #$35
        ldx State+9
        beq :+
        lda #$F5
:       sta VERA_data0                          ; Key T

        lda #$36
        ldx State+11
        beq :+
        lda #$F6
:       sta VERA_data0                          ; Key Y

        lda #$37
        ldx State+12
        beq :+
        lda #$F7
:       sta VERA_data0                          ; Key U

        lda #$38
        ldx State+14
        beq :+
        lda #$F8
:       sta VERA_data0                          ; Key I

        lda #$39
        ldx State+16
        beq :+
        lda #$F9
:       sta VERA_data0                          ; Key O

        lda #$3A
        ldx State+17
        beq :+
        lda #$FA
:       sta VERA_data0                          ; Key P

        lda #$3B
        ldx State+19
        beq :+
        lda #$FB
:       sta VERA_data0                          ; Key [

        lda #$3C
        ldx State+21
        beq :+
        lda #$FC
:       sta VERA_data0                          ; Key ]

        lda #$3D
        ldx State+23
        beq :+
        lda #$FD
:       sta VERA_data0                          ; Key \



        ; Display state of channels
        VERA_SET_ADDR ($04000+19*128+12),2
        lda #0
        ldx Channels
        bne :+
        ora #%00000010
:       ldx Channels+1
        bne :+
        ora #%00000001
:       clc
        adc #$79
        sta VERA_data0

        lda #0
        ldx Channels+2
        bne :+
        ora #%00000010
:       ldx Channels+3
        bne :+
        ora #%00000001
:       clc
        adc #$79
        sta VERA_data0

        lda #0
        ldx Channels+4
        bne :+
        ora #%00000010
:       ldx Channels+5
        bne :+
        ora #%00000001
:       clc
        adc #$79
        sta VERA_data0

        lda #0
        ldx Channels+6
        bne :+
        ora #%00000010
:       ldx Channels+7
        bne :+
        ora #%00000001
:       clc
        adc #$79
        sta VERA_data0

        rts


;*******************************************************************************
DisplayOctave:
;*******************************************************************************
;       Display number of Octave setting to the screen
;*******************************************************************************
        VERA_SET_ADDR ($04000+19*128+36),2
        lda Octave
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$20
        sta VERA_data0
        rts


;*******************************************************************************
DisplayInstrument:
;*******************************************************************************
;       Display description and number ID of Instrumment setting to the screen
;*******************************************************************************
        ; First the name
        VERA_SET_ADDR ($04000+18*128+28),2
        lda #<InstrumentName
        sta ZP_PTR_2
        lda #>InstrumentName
        sta ZP_PTR_2+1

        ; Add multiplication by 13
        ldx Instrument
:       cpx #0
        beq displayName
        clc
        lda ZP_PTR_2
        adc #13
        sta ZP_PTR_2
        lda ZP_PTR_2+1
        adc #0
        sta ZP_PTR_2+1
        dex
        bra :-

displayName:
        ldy #0
:       lda (ZP_PTR_2),y
        sta VERA_data0
        iny
        cpy #13
        bne :-


        ; Next the number ID
        VERA_SET_ADDR ($04000+19*128+48),2

        ; But first translate the Instrument to Decimal
        ; I borrowed this function from Codebase64.org
        ; Author is Andrew Jacobs.
        lda Instrument
        sta BIN
BINBCD8:sed		                        ; Switch to decimal mode
	stz BCD                                 ; Clear the result
	stz BCD+1
	ldx #8		                        ; The number of source bits
		
CNVBIT:	asl BIN		; Shift out one bit
	lda BCD	; And add into result
	adc BCD
	sta BCD
	lda BCD+1	; propagating any carry
	adc BCD+1
	sta BCD+1
	dex		; And repeat for next bit
	bne CNVBIT
	cld		; Back to binary
		
        
        ; Now we are ready to display the number / Instrument ID
        lda BCD
        and #$F0
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$20
        sta VERA_data0
        lda BCD
        and #$0F
        clc
        adc #$20
        sta VERA_data0
        rts
	
BIN:		.byte  0
BCD:		.byte  0,0                     ; Two bytes just in case even though we currently only have values 0-79

InstrumentName: .byte   "GRAND",0,"PIANO",0,0
                .byte   "BRIGHT",0,"PIANO",0
                .byte   "EL.",0,"PIANO",0,0,0,0
                .byte   "HONKY",0,"PIANO",0,0
                .byte   "EL.",0,"PIANO",0,$21,0,0
                .byte   "EL.",0,"PIANO",0,$22,0,0
                .byte   "HARPSICORD",0,0,0
                .byte   "CLAVINET",0,0,0,0,0
                .byte   "CELESTA",0,0,0,0,0,0
                .byte   "GLOCKENSPIEL",0
                .byte   "MUSIC",0,"BOX",0,0,0,0
                .byte   "VIBRAPHONE",0,0,0
                .byte   "MARIMBA",0,0,0,0,0,0
                .byte   "XYLOPHONE",0,0,0,0
                .byte   "TUBULAR",0,"BELLS"
                .byte   "DULCIMER",0,0,0,0,0
                .byte   "DRAW.",0,"ORGAN",0,0
                .byte   "PERC.",0,"ORGAN",0,0
                .byte   "ROCK",0,"ORGAN",0,0,0
                .byte   "CHURCH",0,"ORGAN",0
                .byte   "REED",0,"ORGAN",0,0,0
                .byte   "ACCORDION",0,0,0,0
                .byte   "HARMONICA",0,0,0,0
                .byte   "BANDONEON",0,0,0,0
                .byte   "NYLON",0,"GUITAR",0
                .byte   "STEEL",0,"GUITAR",0
                .byte   "JAZZ",0,"GUITAR",0,0
                .byte   "ELECT.",0,"GUITAR"
                .byte   "MUTED",0,"GUITAR",0
                .byte   "OVERDR.GUITAR"
                .byte   "DISTOR.GUITAR"
                .byte   "HARMON.GUITAR"
                .byte   "ACOUSTIC",0,"BASS"
                .byte   "FINGER",0,"BASS",0,0
                .byte   "PICKED",0,"BASS",0,0
                .byte   "FRETLESS",0,"BASS"
                .byte   "SLAP",0,"BASS",0,$21,0,0
                .byte   "SLAP",0,"BASS",0,$22,0,0
                .byte   "SYNTH",0,"BASS",0,$21,0
                .byte   "SYNTH",0,"BASS",0,$22,0
                .byte   "VIOLIN",0,0,0,0,0,0,0
                .byte   "VIOLA",0,0,0,0,0,0,0,0
                .byte   "CELLO",0,0,0,0,0,0,0,0
                .byte   "CONTRABASS",0,0,0
                .byte   "TREMOLO",0,"STR.",0
                .byte   "PIZZICATO",0,"ST."
                .byte   "HARP",0,0,0,0,0,0,0,0,0
                .byte   "TIMPANI",0,0,0,0,0,0
                .byte   "STRING",0,$21,0,0,0,0,0
                .byte   "STRING",0,$22,0,0,0,0,0
                .byte   "SYNTH",0,"STRING",$21
                .byte   "SYNTH",0,"STRING",$22
                .byte   "CHOIR",0,"AAHS",0,0,0
                .byte   "VOICE",0,"DOOS",0,0,0
                .byte   "SYNTH",0,"VOICE",0,0
                .byte   "ORCHESTRA",0,0,0,0
                .byte   "TRUMPET",0,0,0,0,0,0
                .byte   "TROMBONE",0,0,0,0,0
                .byte   "TUBA",0,0,0,0,0,0,0,0,0
                .byte   "MUT.TRUMPET",0,0
                .byte   "FRENCH",0,"HORN",0,0
                .byte   "BRASS",0,"SECTION"
                .byte   "SYNTH",0,"BRASS",$21,0
                .byte   "SYNTH",0,"BRASS",$21,0
                .byte   "SOPRANO",0,"SAX",0,0
                .byte   "ALTO",0,"SAX",0,0,0,0,0
                .byte   "TENOR",0,"SAX",0,0,0,0
                .byte   "BARITONE",0,"SAX",0
                .byte   "OBOE",0,0,0,0,0,0,0,0,0
                .byte   "ENGLISH",0,"HORN",0
                .byte   "BASSOON",0,0,0,0,0,0
                .byte   "CLARINET",0,0,0,0,0
                .byte   "PICCOLO",0,0,0,0,0,0
                .byte   "FLUTE",0,0,0,0,0,0,0,0
                .byte   "RECORDER",0,0,0,0,0
                .byte   "PAN",0,"FLUTE",0,0,0,0
                .byte   "BLOWN",0,"BOTTLE",0
                .byte   "SHAKUHACHI",0,0,0
                .byte   "WHISTLE",0,0,0,0,0,0
                .byte   "OCARINA",0,0,0,0,0,0



;*******************************************************************************
LoadTiles:
;*******************************************************************************
;       Load Tiles directly into VRAM address $12000
;*******************************************************************************

        lda #11
        ldx #<tilefile
        ldy #>tilefile
        jsr SETNAM

        lda #$01
        ldx #$08      ; default to device 8
        ldy #$00      ; not $01 means: load to address stored in file
        jsr SETLFS

        lda #$03      ; $02 load directly to VRAM bank 1
        ldx #$00
        ldy #$20      ; load to $12000

        jsr LOAD

        rts


tilefile:       .byte "tileset.bin"
