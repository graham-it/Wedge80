10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** qix v1.05
30 rem *** graham 25/4/2026
40 rem *** adapted from "demo.bas" by
50 rem *** david murray (the 8-bit guy)
60 rem
70 print"qix v1.05"
80 print"{down}screen width"
90 print"0. 320","1. 360"
100 print"2. 640","3. 720"
110 print"4. 800","5. 840"
120 do:print"mode "rgr(3)"{left x4}";
130 inputxm:loopwhilexm<0orxm>5
140 rem
150 print"{down}screen height"
160 print"0. 128","1. 144"
170 print"2. 176","3. 200"
180 print"4. 240","5. 256"
190 do:print"mode "rgr(4)"{left x4}ù";
200 inputym:loopwhileym<0orym>5
210 rem
220 print"{down}color cells"
230 print"0. mono","1. 8x8"
240 print"2. 8x4","3. 8x2"
250 do:print"mode "rgr(5)"{left x4}ù";
260 inputcm:loopwhilecm<0orcm>3
270 rem
280 input"{down}line spacing  6{left x3}ù";s
290 input"tail length  16{left x4}ù";l
300 rem
310 rem *** colors ***
320 n=4:c(0)=15:c(1)=8:c(2)=3:c(3)=6
330 rem
340 rem *** directions ***
350 d1=0:d2=1:d3=0:d4=1
360 rem
370 rem *** vertices ***
380 a1=0:a2=0:a3=100:a4=60
390 rem
400 rem *** init buffers ***
410 dimb1(l),b2(l),b3(l),b4(l)
420 fori=0tol
430 b1(i)=2:b2(i)=0:b3(i)=2:b4(i)=0
440 next
450 rem *** start color ***
460 ifcmthenc=0:elsec=2
470 rem
480 rem *** color repeat ***
490 ifl<nthenm=1:elsem=int(l/n)
500 rem
510 k=0:rem *** color counter
520 p=0:rem *** current line
530 e=0:rem *** line to erase
540 rem
550 trap950:fast:color6,1:color8,1
560 ifcmthencolor9,c(c):elsecolor7,c
570 graphic6,1,xm,ym,cm
580 xr=rwindow(3)-1:yr=rwindow(4)-1
590 rem
600 rem *** main loop ***
610 do:draw1,a1,a2toa3,a4
620 rem
630 rem *** update buffers ***
640 b1(p)=a1:b2(p)=a2:b3(p)=a3:b4(p)=a4
650 p=p+1:ifp>lthenp=0
660 e=e+1:ife>lthene=0
670 rem
680 rem *** update color ***
690 ifcmthenbegin
700 k=k+1:ifk=mthenbegin
710 k=0:c=c+1:ifc=nthenc=0
720 bend:color9,c(c)
730 bend:elsebegin
740 ife=0thenbegin
750 c=c+1:ifc>16thenc=2
760 bend:color7,c
770 bend
780 rem *** erase line ***
790 draw0,b1(e),b2(e)tob3(e),b4(e)
800 rem
810 rem *** update vertices ***
820 ifd1thenbegin
830 a1=a1+s:ifa1>xrthena1=xr:d1=0
840 bend:elsea1=a1-s:ifa1<0thena1=0:d1=1
850 ifd2thenbegin
860 a2=a2+s:ifa2>yrthena2=yr:d2=0
870 bend:elsea2=a2-s:ifa2<0thena2=0:d2=1
880 ifd3thenbegin
890 a3=a3+s:ifa3>xrthena3=xr:d3=0
900 bend:elsea3=a3-s:ifa3<0thena3=0:d3=1
910 ifd4thenbegin
920 a4=a4+s:ifa4>yrthena4=yr:d4=0
930 bend:elsea4=a4-s:ifa4<0thena4=0:d4=1
940 loop
950 rem *** exit trap ***
960 autofast:printerr$(er)
