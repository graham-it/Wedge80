10 rem *** wedge80 v2.04 demo [16/64k]
20 rem *** easy graph v1.04
30 rem *** graham 5/5/2026
40 rem
50 autofast:trap570:graphic0,1
60 print"easy graph v1.04"
70 print"{down}edit function and parameters"
80 print"directly into basic lines"
90 print"then run program again"
100 list130-170
110 rem
120 rem *** user function ***
130 deffnf(x)=sin(x)+sin(2*x)+sin(3*x)
140 cx=0     :cy=0     :rem axis offset
150 sx=80    :sy=40    :rem dots/unit
160 ax=-ÿ    :bx=ÿ     :rem interval
170 dx=ÿ/40            :rem increment
180 rem
190 rem *** viewport ***
200 deffnpx(x)=tx+sx*x
210 deffnpy(x)=ty-sy*fnf(x)
220 rem
230 rem *** set graphics ***
240 color6,1:color7,14
250 color8,1:color9,2
260 ifrgr(9)=64thenbegin
270 hm=4:cm=2:bend:elsehm=3:cm=0
280 graphic6,1,2,hm,cm
290 rem
300 rem *** calc offset ***
310 rx=rwindow(3):tx=rx/2+sx*cx
320 ry=rwindow(4):ty=ry/2-sy*cy
330 rem
340 rem *** draw axes ***
350 draw1,0,tytorx-2,ty
360 drawtorx-5,ty-2torx-5,ty+2torx-1,ty
370 draw1,tx,ry-1totx,0
380 drawtotx-4,2totx+4,2totx,1
390 rem
400 rem *** draw graph ***
410 color9,14:lp=0:tm=ti
420 forx=axtobxstepdx
430 iflpthenbegin
440 drawtofnpx(x),fnpy(x)
450 bend:elselp=1:draw1,fnpx(x),fnpy(x)
460 next
470 iflpthenbegin
480 drawtofnpx(bx),fnpy(bx)
490 bend:elsedraw1,fnpx(bx),fnpy(bx)
500 rem
510 rem *** completed ***
520 tm=int((ti-tm)/.6)/100
530 print"elapsed time";tm
540 print"{down}run{up x3}�"
550 trap:end
560 rem
570 rem *** error trap ***
580 printerr$(er),"x=";x
590 ifer=14orer=20thenlp=0:resumenext
600 ifer=30thenbegin
610 tp=ti-tm:print"{down}cont{up x3}":end
620 tm=ti-tp:resume:bend
