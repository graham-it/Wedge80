10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** monoscope v1.06
30 rem *** graham 7/5/2026
40 rem
50 print"monoscope v1.06"
60 print"{down}screen width"
70 print"0. 320","1. 360"
80 print"2. 640","3. 720"
90 print"4. 800","5. 840"
100 do:print"mode "rgr(3)"{left x4}ù";
110 inputxm:loopwhilexm<0orxm>5
120 rem
130 print"{down}screen height"
140 print"0. 128","1. 144"
150 print"2. 176","3. 200"
160 print"4. 240","5. 256"
170 do:print"mode "rgr(4)"{left x4}ù";
180 inputym:loopwhileym<0orym>5
190 rem
200 print"{down}color cells"
210 print"0. mono","1. 8x8"
220 print"2. 8x4","3. 8x2"
230 do:print"mode "rgr(5)"{left x4}ù";
240 inputcm:loopwhilecm<0orcm>3
250 rem
260 color6,1:color7,2
270 color8,1:color9,2
280 graphic6,1,xm,ym,cm
290 xr=rwindow(3):yr=rwindow(4)
300 hx=xr/2:hy=yr/2
310 sc=1-(xm>1)
320 ar=xr/yr:at=atn(sc/ar)
330 cy=hy*(1-sin(at))/(1+sin(at))
340 cx=cy*ar:rx=cy*sc
350 dx=xr-cx:dy=yr-cy
360 rem
370 tm=ti:rem *** start timer
380 box1,0,0,xr-1,yr-1
390 draw1,0,0toxr-1,yr-1
400 draw1,xr-1,0to0,yr-1
410 draw1,cx-rx,0tocx-rx,yr-1
420 draw1,dx+rx,0todx+rx,yr-1
430 draw1,0,cytoxr-1,cy
440 draw1,0,yr-cytoxr-1,yr-cy
450 draw1,cx,0tocx,yr-1
460 draw1,dx,0todx,yr-1
470 draw1,hx,0tohx,yr-1
480 draw1,0,hytoxr-1,hy
490 rem
500 color9,8:a$="c128 wedge80"
510 char1,hx/8-len(a$)/2,cy/8-1,a$
520 color9,16:b$="(c) 2026 graham"
530 char1,hx/8-len(b$)/2,dy/8-1,b$
540 color9,14
550 c$=right$(str$(xr),3)+"x"
560 c$=c$+right$(str$(yr),3)+" "
570 ifcm=0thenc$=c$+"mono":elsebegin
580 bend:c$=c$+"8x"+chr$(48+rwindow(5))
590 char1,hx/8-len(c$)/2,dy/8+1,c$
600 rem
610 color9,4:circle1,hx,hy,hy*sc,hy
620 color9,11:circle1,cx,cy,rx,cy
630 paint1,cx-1,cy-3:paint1,cx+1,cy+3
640 color9,14:circle1,dx,cy,rx,cy
650 paint1,dx+1,cy-3:paint1,dx-1,cy+3
660 color9,15:circle1,dx,dy,rx,cy
670 paint1,dx-1,dy-3:paint1,dx+1,dy+3
680 color9,8:circle1,cx,dy,rx,cy
690 paint1,cx+1,dy-3:paint1,cx-1,dy+3
700 color9,5:circle1,hx,hy,rx,cy
710 paint1,hx-1,hy-3:paint1,hx+1,hy+3
720 rem
730 tm=int((ti-tm)/.6)/100
740 print"{down}elapsed time";tm
