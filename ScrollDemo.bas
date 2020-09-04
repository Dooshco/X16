1 REM ===== SCROLL DEMO =====
2 REM AUTHOR      : DUSAN STRAKL
3 REM MORE INFO   : 8BITCODING.COM
4 REM EMULATOR    : V.37+
9 PRINT "PREPARING BACKGROUND, JUST A SEC..."
10 GOSUB 5000:GOSUB 6000:GOSUB 7000:GOSUB 8000
20 POKE $9F29,%00110001: REM TURN ON LAYER 1 AND 0
30 POKE $9F2A,64 :REM HORIZONTAL SCALE 2
40 POKE $9F2B,64 :REM HORIZONTAL SCALE 2
50 COLOR 13,0:PRINT CHR$(147)+"SCROLL DEMO";
60 COLOR 6,0:PRINT TAB(14):PRINT "CONTROLS: LEFT,RIGHT,SPACE"
70 GOSUB 9000
80 HS=0:VS=0
90 VA=0
100 REM ===== DEMO LOOP =====
110 A=JOY(1)
120 IF A AND 2 THEN VPOKE 0,3618,90:HS=HS+1:IF HS>63 THEN HS=0
130 IF A AND 1 THEN VPOKE 0,3626,83:HS=HS-1:IF HS<0 THEN HS=63
140 IF A AND $20 THEN VPOKE 0,4390,65:VA=VA-0.05:IF VA<-2 THEN VA=-2
170 VA=VA+0.004:IF VA>2 THEN VA=2
180 VS=VS+VA:IF VS>63 THEN VS=0
181 IF VS>63 THEN VS=0
182 IF VS<0 THEN VS=63
190 POKE $9F30,HS:POKE $9F32,VS
199 VPOKE 0,3618,32:VPOKE 0,3626,32:VPOKE 0,4390,32
200 GOTO 110
5000 REM ===== SETUP LAYER 0 =====
5010 POKE $9F2D,%00010001 :REM 32X64 TILES, 2 BPP
5020 POKE $9F2E,$20 :REM MAP BASE AT $4000
5030 POKE $9F2F,%00110000 :REM TILES AT $05000, SIZE 8X8
5100 RETURN
6000 REM ===== DEFINE CUSTOM CHARACTERS =====
6010 FOR N=0 TO 63
6020 VPOKE 0,$6000+N,0
6030 NEXT N
6040 VPOKE 0,$6000+1*16+6,3 :REM CHARACTER 1
6050 VPOKE 0,$6000+2*16+4,3 :REM CHARACTER 2
6060 VPOKE 0,$6000+2*16+6,14
6070 VPOKE 0,$6000+2*16+7,192
6080 VPOKE 0,$6000+2*16+8,3
6090 VPOKE 0,$6000+3*16+2,3 :REM CHARACTER 3
6100 VPOKE 0,$6000+3*16+4,14
6110 VPOKE 0,$6000+3*16+5,192
6120 VPOKE 0,$6000+3*16+6,57
6130 VPOKE 0,$6000+3*16+7,176
6140 VPOKE 0,$6000+3*16+8,14
6150 VPOKE 0,$6000+3*16+9,192
6160 VPOKE 0,$6000+3*16+10,3
6200 REM ===== REDEFINE THRUSTER CHARS =====
6210 VPOKE 0,$F800+90*8+0,$00
6220 VPOKE 0,$F800+90*8+1,$40
6230 VPOKE 0,$F800+90*8+2,$88
6240 VPOKE 0,$F800+90*8+3,$25
6250 VPOKE 0,$F800+90*8+4,$4B
6260 VPOKE 0,$F800+90*8+5,$10
6270 VPOKE 0,$F800+90*8+6,$80
6280 VPOKE 0,$F800+90*8+7,$00
6290 VPOKE 0,$F800+83*8+0,$00
6300 VPOKE 0,$F800+83*8+1,$02
6310 VPOKE 0,$F800+83*8+2,$11
6320 VPOKE 0,$F800+83*8+3,$A4
6330 VPOKE 0,$F800+83*8+4,$D2
6340 VPOKE 0,$F800+83*8+5,$08
6350 VPOKE 0,$F800+83*8+6,$01
6360 VPOKE 0,$F800+83*8+7,$00
6370 VPOKE 0,$F800+65*8+0,$7E
6380 VPOKE 0,$F800+65*8+1,$FF
6390 VPOKE 0,$F800+65*8+2,$FF
6400 VPOKE 0,$F800+65*8+3,$5F
6410 VPOKE 0,$F800+65*8+4,$7A
6420 VPOKE 0,$F800+65*8+5,$2E
6430 VPOKE 0,$F800+65*8+6,$35
6440 VPOKE 0,$F800+65*8+7,$48
6450 RETURN
7000 REM ===== DEFINE CUSTOM COLORS =====
7010 VPOKE 1,$FA00+66,$FF
7020 VPOKE 1,$FA00+67,$FF
7030 VPOKE 1,$FA00+68,$AA
7040 VPOKE 1,$FA00+69,$AA
7050 VPOKE 1,$FA00+70,$55
7060 VPOKE 1,$FA00+71,$55
7100 RETURN
8000 REM ===== FILL LAYER 0 WITH STARS =====
8010 FOR OY=0 TO 4:FOR OX=0 TO 5
8020 FOR IY=0 TO 7:FOR IX=0 TO 7
8030 VPOKE 0,$4000+(OY*8+IY)*128+(IX+OX*8)*2,0
8035 VPOKE 0,$4000+(OY*8+IY)*128+(IX+OX*8)*2+1,32
8040 NEXT:NEXT
8050 VPOKE 0,$4000+(OY*8+2)*128+(OX*8+5)*2,1
8060 VPOKE 0,$4000+(OY*8+5)*128+(OX*8+1)*2,2
8070 VPOKE 0,$4000+(OY*8+0)*128+(OX*8+7)*2,3
8080 VPOKE 0,$4000+(OY*8+7)*128+(OX*8+3)*2,1
8090 VPOKE 0,$4000+(OY*8+1)*128+(OX*8+1)*2,1
8100 NEXT:NEXT
8110 RETURN
9000 REM ===== DRAW LANDER =====
9010 FOR Y=0 TO 3:FOR X=0 TO 4
9020 READ D,C
9030 VPOKE 0,3362+Y*256+X*2,D
9040 VPOKE 0,3362+Y*256+X*2+1,C
9050 NEXT:NEXT
9060 VPOKE 0,4391,$08
9070 RETURN
10000 REM ===== LANDER GRAPHICS =====
10010 DATA 32,$00,105,$10,32,$F0,95,$C0,32,$00
10020 DATA 32,$0E,81,$1B,102,$FC,81,$CB,32,$0E
10030 DATA 32,$00,32,$10,32,$FC,32,$C0,32,$00
10040 DATA 78,$07,32,$00,117,$C1,32,$00,77,$07
