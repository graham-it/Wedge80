;Sketch80
;Sketchpad demo for C128 Wedge80
;Copyright (c) 2026 Graham (Francesco Gramignani)

;Version 1.08
;Revision 1/5/2026

prgname	= "sketch80"
version	= "1.08"
prgdate	= "2026"
author	= "graham"

!ct pet				;PETSCII text conversion table
!src "c128_map.def"		;Commodore 128 memory map
!src "wedge80_lib.def"		;Wedge80 library

; --------------------
; - Defaults
; --------------------

def_plotmode = 0		;plot mode (0 = set pixel, 64 = XOR mode, 128 = clear pixel)
def_width = 0			;pixel width (0 = normal, nonzero = double)

;VDC 16k defaults
def_modex_16 = 2		;horizontal mode (640 pixels)
def_modey_16 = 3		;vertical mode (200 pixels)
def_modec_16 = 0		;color mode (monochrome)

;VDC 64k defaults
def_modex_64 = 2		;horizontal mode (640 pixels)
def_modey_64 = 4		;vertical mode (240 pixels)
def_modec_64 = 2		;color mode (8x4 cells)

;VDC monochrome colors
def_bg_mono = 1			;medium gray (RGBI code)
def_fg_mono = 5			;light green (RGBI code)

;VDC attribute colors
def_bg_attr = 0			;black (RGBI code)
def_fg_attr = 5			;light green (RGBI code)

; --------------------
; - BASIC launcher
; --------------------

* = RAMBOT+1			;start of BASIC program text	
basic_line = 2026		;line number

prg_start
	!by <next_line,>next_line	;link address
	!by <basic_line,>basic_line	;line number

	!by GRAPHIC_tk,CLR_tk,':'	;GRAPHIC CLR
	!tx CMD_dtk,BANK_dtk,"15"	;BANK 15
	!by ':',SYS_tk			;SYS command

;M/L code entry point (ASCII)
	!by '0' + ml_start DIV 1000
	!by '0' + ml_start MOD 1000 DIV 100
	!by '0' + ml_start MOD 100  DIV 10
	!by '0' + ml_start MOD 10
	!by 0				;end of line

next_line
	!by 0,0				;end of program

; --------------------
; - Main
; --------------------

ml_start
	lda #<about_txt		;about message
	ldy #>about_txt
	jsr STROUT		;print string

	lda INITST		;detect Wedge80 library
	and #$20		;check flag (bit 5)
	bne StartPrg

	lda #<no_wedge_txt	;not detected
	ldy #>no_wedge_txt
	jmp STROUT		;print string (then exit)

StartPrg
	bit MODE		;check current screen mode (40/80)
	bpl +			;already in 40-column mode
	jsr SWAPPER		;swap to 40-column mode (text or bitmap) 

;Keyboard instructions
+	lda #<keymap_txt
	ldy #>keymap_txt
	jsr STROUT		;print string

;Set defaults
	lda #def_bg_mono	;background mono (and border) color
	jsr SetBgCol80

	lda #def_fg_mono	;foreground mono color
	jsr SetFgCol80

	lda #def_bg_attr	;attribute background color
	asl
	asl
	asl
	asl
	ora #def_fg_attr	;attribute foreground color
	sta attrsrc		;set attribute

	lda #def_plotmode	;plot mode
	sta plotmode

	lda #def_width != 0	;pixel width (bit 0)
	sta WIDTH

;Set default graphics mode
	ldx vdcram		;check detected VDC RAM
	beq +			;16k default mode
	ldx #def_mode_64k	;64k default mode

+	lda def_mode_tbl,x	;horizontal mode
	sta modex

	lda def_mode_tbl+1,x	;vertical mode
	sta modey

	lda def_mode_tbl+2,x	;color mode
	sta modec
	jsr SetBmp80		;set VDC bitmap mode

ClrScreen
	jsr ClrBmp80		;clear screen

StartPos
	ldx modex		;x-coord
	lda resx_lo,x
	ldy resx_hi,x
	sty XPOS+1
	lsr XPOS+1		;divide by 2
	ror
	sta XPOS

	ldx modey		;y-coord
	lda resy_lo,x
	ldy resy_hi,x
	sty YPOS+1
	lsr YPOS+1		;divide by 2
	ror
	sta YPOS

WaitKey
;Wait for key release
	ldx #no_key		;no key pressed
	lda SHFLAG		;SHIFT key
	lsr
	bcs PlotLoop		;do not wait
	cpx SFDX		;get key scan code
	bne WaitKey

PlotLoop	
	jsr GPlot80		;draw a pixel

WaitFrame
	bit RASTERH		;wait for scanline 256
	bpl WaitFrame		;check bit 7

KeyLoop
	lda SFDX		;get key scan code
	cmp #no_key		;no key pressed
	beq KeyLoop

;Home position
	cmp #HOME_key
	bne +
	lda SHFLAG		;SHIFT key (CLR)
	lsr
	bcs ClrScreen		;clear screen
	bcc StartPos		;(forced)

;Cursor horizontal
+	cmp #CRSRH_key
	bne +
	lda SHFLAG		;check SHIFT key
	lsr
	bcs cr_lt		;move left
	bcc cr_rt		;move right (forced)

;Cursor vertical
+	cmp #CRSRV_key
	bne +
	lda SHFLAG		;check SHIFT key
	lsr
	bcs cr_up		;move up
	bcc cr_dw		;move down (forced)

;Cursor left
+	cmp #LEFT_key		;(extended keyboard)
	bne +

cr_lt	lda XPOS
	bne +++
	lda XPOS+1
	bne ++
	ldx modex		;right side
	lda resx_hi,x
	sta XPOS+1
	lda resx_lo,x
	sta XPOS
	bne +++
++	dec XPOS+1
+++	dec XPOS
	jmp PlotLoop

;Cursor right
+	cmp #RIGHT_key		;(extended keyboard)
	bne +
cr_rt	inc XPOS
	bne ++
	inc XPOS+1
++	lda XPOS+1
	ldx modex
	cmp resx_hi,x
	bcc ++
	lda XPOS
	cmp resx_lo,x
	bcc ++
	lda #0			;left side
	sta XPOS
	sta XPOS+1
++	jmp PlotLoop

;Cursor up
+	cmp #UP_key		;(extended keyboard)
	bne +
cr_up	ldy YPOS
	bne ++
	ldx modey		;bottom side
	ldy resy_lo,x
++	dey
	sty YPOS
	jmp PlotLoop

;Cursor down
+	cmp #DOWN_key		;(extended keyboard)
	bne +

cr_dw	ldy YPOS
	iny
	beq ++
	ldx modey
	lda resy_hi,x
	bne ++
	tya
	cmp resy_lo,x
	bcc ++
	ldy #0			;top side
++	sty YPOS
	jmp PlotLoop

;Background color
+	cmp #B_key
	bne +
	lda modec
	beq ++
	lda attrsrc
	tax
	and #$0f
	sta XSAV
	txa
	clc
	adc #$10
	and #$f0
	ora XSAV
	sta attrsrc
	jmp WaitKey	

++	jsr GetBgCol80		;monochrome
	tax
	inx
	txa
	jsr SetBgCol80
	jmp WaitKey

;Foreground color
+	cmp #F_key
	bne +
	lda modec
	beq ++
	lda attrsrc
	tax
	and #$f0
	sta XSAV
	inx
	txa
	and #$0f
	ora XSAV
	sta attrsrc
	jmp WaitKey	

++	jsr GetFgCol80		;monochrome
	tax
	inx
	txa
	jsr SetFgCol80
	jmp WaitKey

;Horizontal mode
+	cmp #H_key
	bne +
	inc modex
	lda modex
	cmp #modex_count
	bcc ++
	lda #0
	sta modex
++	jsr SetBmp80		;set VDC bitmap mode
	jmp WaitKey

;Vertical mode
+	cmp #V_key
	bne +
	inc modey
	lda modey
	cmp #modey_count
	bcc ++
	lda #0
	sta modey
++	jsr SetBmp80		;set VDC bitmap mode
	jmp WaitKey

;Color mode
+	cmp #C_key
	bne +
	lda #def_modec_64
	ldx modec
	beq ++
	lda #0
++	sta modec
	jsr SetBmp80		;set VDC bitmap mode
	jmp WaitKey

;Reverse mode
+	cmp #R_key
	bne +
	ldx #vdc_VSS		;[R24] VERTICAL SMOOTH SCROLL
	jsr READREG
	eor #$40		;reverse mode (flip bit 6)
	jsr WRTREG
	jmp WaitKey

;Erase mode
+	cmp #E_key
	bne +
	lda plotmode
	eor #$80		;on/off (flip bit 7)
	and #$80		;clear other bits
	sta plotmode
	jmp WaitKey

;XOR mode
+	cmp #X_key
	bne +
	lda plotmode
	eor #$40		;on/off (flip bit 6)
	and #$40		;clear other bits
	sta plotmode
	jmp WaitKey

;Pixel width
+	cmp #W_key		
	bne +
	lda WIDTH
	eor #$01		;single/double (flip bit 0)
	sta WIDTH
	jmp WaitKey

;Clock speed
+	cmp #S_key
	bne +
	lda CLKRT		;current clock rate
	and #1
	bne ++
	jsr FAST		;set FAST mode
	jmp WaitKey
++	jsr SLOW		;set SLOW mode
	jmp WaitKey

;Exit program
+	cmp #ESC_key
	bne +
	lda #0			;clear
	sta NDX			;keyboard buffer
	sta KYNDX		;pending chars from programmable key string

	jsr SLOW		;set SLOW mode

	lda #<exit_txt
	ldy #>exit_txt
	jmp STROUT		;print string (then exit)

+	jsr CHKSTP		;check STOP key and break if it is depressed
	jmp KeyLoop

; --------------------
; - Tables
; --------------------

;VDC bitmap resolution
resx_lo		!by <320,<360,<640,<720,<800,<840
resx_hi		!by >320,>360,>640,>720,>800,>840
resy_lo		!by <128,<144,<176,<200,<240,<256
resy_hi		!by >128,>144,>176,>200,>240,>256

;VDC default modes
def_mode_tbl
	!by def_modex_16,def_modey_16,def_modec_16	;VDC 16k defaults
	!by def_modex_64,def_modey_64,def_modec_64	;VDC 64k defaults
def_mode_64k = (* - def_mode_tbl)/2

; --------------------
; - Strings
; --------------------

about_txt
	!tx CR,prgname," v",version
	!tx " (c) ",prgdate," ",author
	!by CR,0

no_wedge_txt
	!tx "wedge80 not detected"
	!by CR,0

exit_txt
	!tx CR,"back to basic"
	!by CR,0

keymap_txt
	!tx CR,"crsr keys",TAB,"move cursor"
	!tx CR,"home",TAB,TAB,"center position"
	!tx CR,"clr",TAB,TAB,"clear screen"
	!tx CR,"b",TAB,TAB,"background color"
	!tx CR,"f",TAB,TAB,"foreground color"
	!tx CR,"h",TAB,TAB,"horizontal mode"
	!tx CR,"v",TAB,TAB,"vertical mode"
	!tx CR,"c",TAB,TAB,"color mode"
	!tx CR,"r",TAB,TAB,"reverse mode"
	!tx CR,"e",TAB,TAB,"erase mode"
	!tx CR,"x",TAB,TAB,"xor mode"
	!tx CR,"w",TAB,TAB,"pixel width"
	!tx CR,"s",TAB,TAB,"clock speed"
	!tx CR,"esc",TAB,TAB,"exit"
	!tx CR,"run/stop",TAB,"break"
	!by CR,0
keymap_size = * - keymap_txt

ml_size = * - ml_start		;M/L code size
prg_size = * - prg_start	;program size
prg_end
