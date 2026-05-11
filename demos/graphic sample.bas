10 rem *** wedge80 v2.04 demo [64k]
20 rem *** graphic sample v1.03
30 rem *** graham 8/4/2026
40 rem *** edit from c128 system guide
50 rem
60 color6,1:color8,1:color9,2
70 graphic6,1,2,3,2:rem [640x200][8x4]
80 color9,11:fori=70to190step2
90 draw1,i,80toi,140:next
100 color9,15:circle1,320,110,60,30
110 color9,14:fori=81to1step-8
120 circle1,500,120,i,i/2,,,,120:next
130 color9,15:paint1,320,110
140 color9,5
150 draw1,500,0to60,0to80,40to500,0
160 color9,2:draw1,40,188to600,188
170 a$="c128 wedge80 (c) 2026 graham"
180 color9,8:char1,40-len(a$)/2,24,a$
190 color9,5:paint1,200,25
