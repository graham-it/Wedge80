10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** racing cars v1.04
30 rem *** graham 6/5/2026
40 rem *** edit from c128 system guide
50 rem
60 color6,1:color7,2:color8,1:color9,16
70 ifrgr(9)=64thencm=2:elsecm=0
80 graphic6,1,2,3,cm:rem [640x200]
90 box1,0,0,90,45
100 draw1,34,10to56,10to52,30to38,30to34,10:draw1,38,28to52,28
110 box1,22,10,30,18:box1,60,10,68,18
120 box1,22,20,30,28:box1,60,20,68,28
130 box1,41,13,49,19,,1
140 color9,2:box1,330,35,375,45,90,1
150 box1,330,135,375,145,90,1
160 box1,100,180,600,195
170 char1,32,23,"{checkers x3}   f i n i s h   {checkers x3}"
180 sshapea$,22,10,68,30
190 color9,11:gshapea$,215,110
200 color9,15:gshapea$,455,50
