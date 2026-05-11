10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** screen saver v1.02
30 rem *** graham 7/5/2026
40 rem
50 fori=0to7:readdk(i):next:rem dark/c
60 data1,3,6,7,9,10,12,13
70 fori=0to7:readlt(i):next:rem light/c
80 data2,4,5,8,11,14,15,16
90 fori=0to5:readsh(i):next:rem shapes
100 data36,45,60,72,90,120
110 rem
120 deffnr(x)=int(x*rnd(1)+.5)
130 rem
140 print"screen saver v1.02"
150 print"1. lines"
160 print"2. shapes"
170 print"3. bubbles"
180 print"0. quit"
190 do:ch=0:input"choice";ch
200 loopwhilech<0orch>3
210 ifch=0thenend
220 rem
230 ifrgr(9)=64thenbegin
240 print"{down}color mode"
250 print"1. monochrome"
260 print"2. color"
270 do:cm=0:input"choice  2{left x3}ù";cm
280 loopwhilecm<0orcm>2
290 ifcm=0thenend
300 ifcm=1thencm=0
310 vm=4:rem *** vertical mode
320 bend:elsevm=3:cm=0
330 rem
340 print"{down}background mode"
350 print"1. always black"
360 print"2. random color"
370 do:bm=0:input"choice  1{left x3}ù";bm
380 loopwhilebm<0orbm>2
390 ifbm=0thenend:elsebm=bm-1
400 rem
410 input"{down}screen items  25{left x4}ù";n
420 input"wait seconds  2¬ù¬ù¬ù";s
430 rem
440 trap830:fast
450 graphic6,1,2,vm,cm
460 h=rwindow(3)-1:v=rwindow(4)-1
470 rem
480 rem *** main loop ***
490 do:ifbmthenbegin
500 bc=dk(fnr(7)):fc=lt(fnr(7))
510 bend:elsebc=1:fc=fnr(14)+2
520 color8,bc:color9,fc:scnclr6
530 color6,bc:color7,fc
540 onchgosub570,640,740
550 sleeps:loop
560 rem
570 rem *** lines ***
580 fori=1ton:ifbmthenbegin
590 color9,lt(fnr(7))
600 bend:elsecolor9,fnr(14)+2
610 draw1,fnr(h),fnr(v)tofnr(h),fnr(v)
620 next:return
630 rem
640 rem *** shapes ***
650 fori=1ton:ifbmthenbegin
660 color9,lt(fnr(7))
670 bend:elsecolor9,fnr(14)+2
680 r=fnr(30)+10:rc=fnr(3)
690 rx=r*(2-(rcand1)):ry=r*(1+(rcand1))
700 x=fnr(h-r*4)+r*2:y=fnr(v-r*2)+r
710 circle1,x,y,rx,ry,,,90*rc,sh(fnr(5))
720 next:return
730 rem
740 rem *** bubbles ***
750 fori=1ton:ifbmthenbegin
760 color9,lt(fnr(7))
770 bend:elsecolor9,fnr(14)+2
780 ry=fnr(30)+10:rx=ry*2
790 x=fnr(h-rx*2)+rx:y=fnr(v-ry*2)+ry
800 circle1,x,y,rx,ry,,,,4
810 next:return
820 rem
830 rem *** exit trap ***
840 autofast:printerr$(er)
