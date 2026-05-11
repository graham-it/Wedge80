10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** marble v1.03
30 rem *** graham 7/5/2026
40 rem
50 color6,1:color7,14
60 color8,1:color9,14
70 ifrgr(9)=16thenvm=3:cm=0:cy=100
80 ifrgr(9)=64thenvm=4:cm=1:cy=108
90 graphic6,1,2,vm,cm:graphic6,,,,0
100 fori=5to255step5
110 circle1,320,cy,192,96,,,,i:next
120 ifrgr(9)=16thenend
130 graphic6,,,,1
140 color9,15:draw1,40,220to599,220
150 a$="c128 wedge80 (c) 2026 graham"
160 color9,2:char1,(80-len(a$))/2,28,a$
