10 rem *** wedge80 v2.04 demo [64k]
20 rem *** spaceship v1.04
30 rem *** graham 25/4/2026
40 rem *** edit from c128 system guide
50 rem
60 color6,1:color8,1:color9,2
70 graphic6,1,2,4,2:rem [640x240][8x4]
80 rem
90 rem *** stars ***
100 fori=1to80:widthrnd(1)+1.2
110 do:sx=rnd(1)*rwindow(3)
120 sy=rnd(1)*rwindow(4)
130 loopwhilesx<170andsy<45
140 draw1,sx,sy:next
150 width1
160 rem *** planet ***
170 color9,8:circle1,380,90,60,25
180 paint1,380,90
190 rem
200 rem *** xor-ed rings ***
210 fori=0to6step3
220 circle2,380,90+i,130,10,135,225,355
230 circle1,380,90+i,130,10,225,495,355
240 next
250 rem *** draw modules ***
260 color9,16:box1,0,0,160,40
270 draw1,80,0to80,40
280 rem
290 rem *** capsule ***
300 draw1,18,17to30,17to62,10to64,20to62,30to30,23to18,23to18,17
310 draw1,36,24to38,21to52,25to50,28
320 draw1,38,19to38,17to56,13to58,18to54,23to38,19:paint1,24,20
330 rem
340 rem *** rockets ***
350 draw1,98,10to102,20to98,30to120,30to122,20to120,10to98,10
360 draw1,120,10to132,12to144,10to144,17to132,15to122,17
370 draw1,122,22to132,24to144,22to144,29to132,27to120,29
380 paint1,110,15
390 paint1,124,12:paint1,124,26
400 draw0,120,30to122,20to120,10
410 draw0,98,14to118,14:draw0,98,21to118,21:draw0,98,28to118,28
420 rem
430 rem *** join modules ***
440 sshapea$,18,10,64,32
450 sshapeb$,98,10,144,32
460 fori=0to2:readc,x,y
470 color9,c:gshapea$,x,y,2
480 gshapeb$,x+46,y,2:next
490 rem
500 rem *** ships (color,pos) ***
510 data11,100,150,14,400,180
520 data15,500,120
