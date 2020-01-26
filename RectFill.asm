VeraLO .equ $9F20			  // Address bits 7 - 0
VeraMID .equ $9F21			// Address bits 15 - 8
VeraHI .equ $9F22			  // Increment + Address bits 19 - 16
VeraDAT0 .equ $9F23			// Data Port 0
VeraCTRL .equ $9F25			// VERA Control

Xpos .equ $02
Ypos .equ $03
Width .equ $04
Height .equ $05
Char .equ $06
Attr .equ $07
PointerL .equ $08
PointerH .equ $09
Ycounter .equ $0A

* = $0400

		stz VeraCTRL

		lda Xpos
		rol
		sta PointerL
		lda Ypos
		sta PointerH

		ldx Width
		ldy Height
        sty Ycounter

		lda #$10
		sta VeraHI	

row:	lda PointerH
		sta VeraMID
		lda PointerL
		sta VeraLO

    	lda Char
        ldy Attr

col:	sta VeraDAT0
		sty VeraDAT0
		dex
		bne col

		inc PointerH
		ldx Width
		dec Ycounter
		bne row

		rts
