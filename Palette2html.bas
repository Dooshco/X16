10 DIM HX$(16)
11 HX$(0)="00"
12 HX$(1)="11"
13 HX$(2)="22"
14 HX$(3)="33"
15 HX$(4)="44"
16 HX$(5)="55"
17 HX$(6)="66"
18 HX$(7)="77"
19 HX$(8)="88"
20 HX$(9)="99"
21 HX$(10)="AA"
22 HX$(11)="BB"
23 HX$(12)="CC"
24 HX$(13)="DD"
25 HX$(14)="EE"
26 HX$(15)="FF"
100 FOR N=0 TO 255
110 R=VPEEK($F,$1000+N*2+1)
120 B=VPEEK($F,$1000+N*2)AND15
130 G=INT(VPEEK($F,$1000+N*2)/16)
140 PRINT "<TR>"
150 PRINT "<TD STYLE='BACKGROUND-COLOR:#";
160 PRINT HX$(R)+HX$(G)+HX$(B)+";'>";
170 PRINT N;:PRINT "</TD>"
180 PRINT "<TD>";:PRINT R;:PRINT "</TD>"
190 PRINT "<TD>";:PRINT G;:PRINT "</TD>"
200 PRINT "<TD>";:PRINT B;:PRINT "</TD>"
210 PRINT "</TR>"
220 NEXT N