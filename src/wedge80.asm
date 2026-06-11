;Wedge80
;a C128 BASIC extension for VDC graphics
;Copyright (c) 2026 Graham (Francesco Gramignani)

;Version 2.04
;Revision 9/5/2026

;https://graham-it.itch.io
;https://github.com/graham-it
;https://csdb.dk/scener/?id=40810

;Compilable with ACME 0.97
;the ACME Crossassembler for Multiple Environments
;Copyright (c) 1998-2020 Marco Baye

prgname	= "wedge80"
version	= "2.04"
prgdate	= "2026"
author	= "graham"

!ct pet				;PETSCII text conversion table
!src "c128_map.def"		;Commodore 128 memory map

; --------------------
; - Memory layout
; --------------------

main_ram0 = FREK13	;Main program		Application Program Area ($1300-$lbff = 2304 bytes available)
ext_ram0 = $f500	;Extra modules		RAM from block 0 ($e000-$feff = 7936 bytes available)
Eval80p = FREK3E4	;Evaluation patch	Common RAM ($03e4-$03ef = 12 bytes available)

!if online_guide {
ext_ram1 = $f000	;Online Guide		RAM from block 1 [$0400-$feff = 64256 bytes available]
}

;ROM routines size
DRAWLN_size	= DLOOP-DRAWLN			;DRAWLN	(117 bytes)
DLOOP_size	= DRWINC-DLOOP			;DLOOP	(69 bytes)
BOX_size	= BOX05-BOX			;BOX	(32 bytes)
BOX05_size	= BOXSUB-BOX05			;BOX05	(178 bytes)
CIRCLE_size	= CIRC40-CIRCLE			;CIRCLE	(151 bytes)
CIRC40_size	= CIRSUB-CIRC40			;CIRC40	(43 bytes)
PAINT_size	= BOX-PAINT3			;PAINT	(225 bytes)

;Main memory
BOX_cmd		= main_ram0+main_size		;BOX command
Box80		= BOX_cmd+BOX_size		;BOX entry point
CIRCLE_cmd	= Box80+Box80_size		;CIRCLE command
Circle80	= CIRCLE_cmd+CIRCLE_size	;CIRCLE entry point
main_end	= Circle80+Circle80_size	;end address (must be below $1c00)

;HIGH memory
DrawLn80_ext	= ext_ram0+ext_size		;DRAWLN routine
DrawLn80p	= DrawLn80_ext+DRAWLN_size	;DRAWLN patch
DLoop80		= DrawLn80p+DrawLn80p_size	;DRAWLN loop
Box80_ext	= DLoop80+DLOOP_size		;BOX routine
Circle80_ext	= Box80_ext+BOX05_size		;CIRCLE routine
Paint80p	= Circle80_ext+CIRC40_size	;PAINT patch
Paint80_ext	= Paint80p+Paint80p_size	;PAINT routine
ext_end		= Paint80_ext+PAINT_size	;end address (must be below $ff00)

;PAINT routine
PAINT3 = PAINT2+25				;entry point (excluding Garbage collection)
PtLoop80 = PTLOOP-PAINT3+Paint80_ext		;main loop (not relocatable jump)
TstVal80 = TSTVAL-PAINT3+Paint80_ext		;service routine (test value of position)

; --------------------
; - Consts
; --------------------

test16k = $8000		;test address to detect VDC RAM size (mirror of address $0000)
nodigits = $f7		;decimal point position (with no digits) for right alignment

modex_count = 6		;horizontal modes
modey_count = 6		;vertical modes
modec_count = 4		;color modes
color_count = 16	;color numbers

;MMU configuration
HIRAM = $30		;HIGH memory (same as BANK 15, but with RAM in High space)
			;System RAM	$0000-$3fff	RAM from block 0
			;Low space	$4000-$7fff	BASIC Low ROM
			;Mid space	$8000-$bfff	BASIC High ROM
			;High space	$c000-$cfff	RAM from block 0 (instead of Editor)
			; "		$d000-$dfff	I/O Registers
			; "		$e000-$ffff	RAM from block 0 (instead of Kernal)

;Main start address (ASCII)
	a3 = '0' + main_ram0 DIV 1000
	a2 = '0' + main_ram0 MOD 1000 DIV 100
	a1 = '0' + main_ram0 MOD 100  DIV 10
	a0 = '0' + main_ram0 MOD 10
main_addr = [a3,a2,a1,a0]

;Setup start address (ASCII)
	s3 = '0' + setup_start DIV 1000
	s2 = '0' + setup_start MOD 1000 DIV 100
	s1 = '0' + setup_start MOD 100  DIV 10
	s0 = '0' + setup_start MOD 10
setup_addr = [s3,s2,s1,s0]

; --------------------
; - Defaults
; --------------------

def_autofast = 1	;AUTOFAST mode (0 = disabled, nonzero = enabled)
def_coords = 1		;reset coords (0 = disabled, nonzero = enabled)

;VDC 16k defaults
def_modex_16 = 2	;horizontal mode (640 pixels)
def_modey_16 = 3	;vertical mode (200 pixels)
def_modec_16 = 0	;color mode (monochrome)

;VDC 64k defaults
def_modex_64 = 2	;horizontal mode (640 pixels)
def_modey_64 = 4	;vertical mode (240 pixels)
def_modec_64 = 2	;color mode (8x4 cells)

;VDC monochrome colors
def_bg_mono = 0		;black (RGBI code)
def_fg_mono = 7		;light cyan (RGBI code)

;VDC attribute colors
def_bg_attr = 0		;black (RGBI code)
def_fg_attr = 15	;white (RGBI code)

; --------------------
; - Variables
; --------------------

plotmode = COLSEL	;[$83] plot mode
			;	bits	7	0 = set pixel, 1 = clear pixel
			;	 "	6	0 = normal mode, 1 = XOR mode
			;	 "	5..0	not used
vdcram	= FREKAB0	;[$0ab0] detected VDC RAM (0 = 16k, 1 = 64k)
targscn	= FREKABA	;[$0aba] target screen
			;	bits	7	all graphics commands (0 = VIC-II, 1 = VDC)
			;	 "	6	CHAR command (0 = standard BASIC, 1 = VDC bitmap)
			;	 "	5..0	not used
autofast = FREKABA+1	;[$0abb] AUTOFAST mode
			;	bits	7	0 = disabled, 1 = enabled
			;	 "	6..0	not used
attrsrc	= FREKABA+2	;[$0abc] attribute source
			;	bits	7..4	background color (hi-nibble)
			;	 "	3..0	foreground color (lo-nibble)
modex	= FREKABA+3	;[$0abd] horizontal mode (0..5)
modey	= FREKABA+4	;[$0abe] vertical mode (0..5)
modec	= FREKABA+5	;[$0abf] color mode (0..3)

backptr	= FREK12	;[$12fe] copy of text pointer (backtracking)
tmp	= XSAV		;[$97] temp value
tmp2	= ZPTMP1	;[$77] temp value

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
	!by ':',SYS_tk,setup_addr	;SYS command
	!by 0				;end of line

next_line
	!by 0,0				;end of program

launcher_size = * - prg_start

; --------------------
; - Setup routine
; --------------------

setup_start
	jsr VDCTest		;detect VDC RAM size (16k/64k)

;Reserve space in RAM#0
	lda #<ext_ram0		;set end of BASIC program text area (default = $ff00)
	sta MAXMEM0
	lda #>ext_ram0
	sta MAXMEM0+1		;(no further action is required)

;Install modules in RAM#0
	ldx #mod_count-2	;module number (doubled value)
-	jsr Setup_RAM0
	dex
	dex
	bpl -

;Patch BASIC 7.0 graphics routines
	jsr Patch_ROM
	jsr Patch_PAINT

!if online_guide {
;Reserve space in RAM#1
	lda #<ext_ram1		;set end of BASIC variable storage area (default = $ff00)
	sta MAXMEM1
	lda #>ext_ram1
	sta MAXMEM1+1		;(then a CLR or NEW is required)

;Install Online Guide in RAM#1
	jsr Setup_RAM1
}

;Set Wedge80 installed flag
	lda INITST		;System initialization status flag
	ora #$20		;set flag (bit 5)
	sta INITST

;Start Wedge80
	jsr SCRTCH		;perform NEW (return not allowed)
	jsr StartWedge		;enable BASIC wedging
	jmp READY		;return to BASIC prompt

; --------------------
; - Setup subs
; --------------------

VDCTest
;Detect VDC RAM size (16k/64k)
	ldx #vdc_CB		;[R28] CHARACTER BASE ADDRESS
	jsr READREG		;read register
	pha			;preserve register
	ora #$10		;enable 64k address mode (bit 4)
	jsr WRTREG		;update register

;Read value of address zero
	lda #$00		;set page
	jsr SetAddress
	jsr READ80		;read value
	sta tmp

;Read value of test address
	lda #>test16k		;set page
	jsr SetAddress
	jsr READ80		;read value
	tay			;preserve value

;Invert value of test address
	lda #>test16k		;set page
	jsr SetAddress
	tya			;current value
	eor #$ff		;invert value
	jsr WRITE80		;write value

;Check value of address zero
	lda #$00		;set page
	jsr SetAddress
	jsr READ80		;read value

	ldx #0			;16k (4416 RAM chips)
	cmp tmp			;previous value
	bne +
	inx			;64k (4164 RAM chips)
+	stx vdcram		;save detected VDC RAM

;Restore value of test address
	lda #>test16k		;set page
	jsr SetAddress
	tya			;previous value
	jsr WRITE80		;write value

;Restore VDC RAM address mode
	ldx #vdc_CB		;[R28] CHARACTER BASE ADDRESS
	pla			;restore register
	jmp WRTREG		;write register (then return)

SetAddress
;Set VDC update address
;
;args:	a = page

	ldx #vdc_UAH		;[R18] UPDATE ADDRESS HI
	jsr WRTREG		;update register

	inx			;[R19] UPDATE ADDRESS LO
	lda #0
	jmp WRTREG		;update register (then return)

Setup_RAM0
;Install a module in RAM#0
;
;args:	x = module number (preserved)
;
;used:	INDEX1, INDEX2, VTEMP

	lda mod_src,x		;source address
	sta INDEX1
	lda mod_src+1,x
	sta INDEX1+1

	lda mod_dest,x		;dest address
	sta INDEX2
	lda mod_dest+1,x
	sta INDEX2+1

	lda mod_size,x		;module size
	sta VTEMP
	lda mod_size+1,x
	sta VTEMP+1
	beq +			;within a page

--	ldy #0			;whole page
-	lda (INDEX1),y
	sta (INDEX2),y
	iny
	bne -

	inc INDEX1+1		;source (hi-byte)
	inc INDEX2+1		;dest (hi-byte)
	dec VTEMP+1		;size (hi-byte)
	bne --

+	lda VTEMP		;check size (lo-byte)
	beq +

	ldy #0			;partial page
-	lda (INDEX1),y
	sta (INDEX2),y
	iny
	cpy VTEMP
	bne -
+	rts

Patch_ROM
;Patch BASIC 7.0 graphics routines
	ldx #patch_count-2	;table index
-	lda patch_addr,x	;patch address
	sta INDEX1
	lda patch_addr+1,x
	sta INDEX1+1

	ldy #0
	lda patch_val,x		;lo-byte
	sta (INDEX1),y

	iny
	lda patch_val+1,x	;hi-byte
	sta (INDEX1),y
	dex
	dex			;next patch
	bpl -
	rts

Patch_PAINT
;Patch PAINT routine
	lda #JSR_opc
	sta $62a1-PAINT3+Paint80_ext	;sta $ff04 -> jsr IndStash_RAM1

	lda #BIT1_opc
	sta $62a4-PAINT3+Paint80_ext	;sta ($24),y -> bit $24

	lda #BIT2_opc
	sta $626a-PAINT3+Paint80_ext	;sta $ff03 -> bit $ff03
	sta $62a6-PAINT3+Paint80_ext	;sta $ff03 -> bit $ff03
	rts

!if online_guide {

Setup_RAM1
;Install Online Guide in RAM#1
;
;used:	INDEX1, INDEX2, VTEMP, STAVEC

	lda #<guide_src		;source address
	sta INDEX1
	lda #>guide_src
	sta INDEX1+1

	lda #<ext_ram1		;dest address
	sta INDEX2
	lda #>ext_ram1
	sta INDEX2+1

	lda #INDEX2		;set STASH pointer
	sta STAVEC

	lda #<guide_size	;module size
	sta VTEMP
	lda #>guide_size
	sta VTEMP+1
	beq +			;within a page

--	ldy #0			;whole page
-	lda (INDEX1),y
	ldx #BANKT[1]		;set BANK 1 as target
	jsr STASH		;save char
	iny
	bne -

	inc INDEX1+1		;source (hi-byte)
	inc INDEX2+1		;dest (hi-byte)
	dec VTEMP+1		;size (hi-byte)
	bne --

+	lda VTEMP		;check size (lo-byte)
	beq +

	ldy #0			;partial page
-	lda (INDEX1),y
	ldx #BANKT[1]		;set BANK 1 as target
	jsr STASH		;save char
	iny
	cpy VTEMP
	bne -
+	rts
}
;online_guide

; --------------------
; - Setup tables
; --------------------

;Modules source
mod_src		!wo main_src,ext_src,Eval80p_src
		!wo DRAWLN,DrawLn80p_src,DLOOP
		!wo BOX,Box80_src,BOX05
		!wo CIRCLE,Circle80_src,CIRC40
		!wo Paint80p_src,PAINT3

;Modules address
mod_dest	!wo main_ram0,ext_ram0,Eval80p
		!wo DrawLn80_ext,DrawLn80p,DLoop80
		!wo BOX_cmd,Box80,Box80_ext
		!wo CIRCLE_cmd,Circle80,Circle80_ext
		!wo Paint80p,Paint80_ext

;Modules size
mod_size	!wo main_size,ext_size,Eval80p_size
		!wo DRAWLN_size,DrawLn80p_size,DLOOP_size
		!wo BOX_size,Box80_size,BOX05_size
		!wo CIRCLE_size,Circle80_size,CIRC40_size
		!wo Paint80p_size,PAINT_size
mod_count = * - mod_size

;Patch addresses
patch_addr
	!wo DLoop80+1				;GPLOT
	!wo BOX_cmd+1				;GRPCOL
	!wo $62e7-BOX05+Box80_ext+1		;DRAWLN
	!wo $6327-BOX05+Box80_ext+1		; "
	!wo CIRCLE_cmd+1			;GRPCOL
	!wo $6743-CIRC40+Circle80_ext+1		;DRAWLN
	!wo $674d-CIRC40+Circle80_ext+1		; "
	!wo $61fc-PAINT3+Paint80_ext+1		;READPT
	!wo $620b-PAINT3+Paint80_ext+1		;PLOT01
	!wo $621b-PAINT3+Paint80_ext+1		;TSTVAL
	!wo $6230-PAINT3+Paint80_ext+1		; "
	!wo $6248-PAINT3+Paint80_ext+1		;READPT
	!wo $6267-PAINT3+Paint80_ext+1		;INDIN1
	!wo $6273-PAINT3+Paint80_ext+1		;CHKSTP
	!wo $6276-PAINT3+Paint80_ext+1		;PTLOOP
	!wo $627d-PAINT3+Paint80_ext+1		;READPT
	!wo $62a1-PAINT3+Paint80_ext+1		;LCRD

;Patch values
patch_val
	!wo GPlot80				;DRAWLN
	!wo GrpCol80				;BOX
	!wo DrawLn80_ext,DrawLn80_ext		; "
	!wo GrpCol80				;CIRCLE
	!wo DrawLn80_ext,DrawLn80_ext		; "
	!wo ReadPt80,GPlot80a			;PAINT
	!wo TstVal80,TstVal80			; "
	!wo ReadPt80,IndFetch_RAM1		; "
	!wo ChkStop,PtLoop80			; "
	!wo ReadPt80,IndStash_RAM1		; "
patch_count = * - patch_val

setup_size = * - setup_start

; --------------------
; - Patch sources
; --------------------

Eval80p_src
;Evaluation routine patch (required for BASIC user functions to work)
;(to be installed into common RAM)

	sta LCRC			;switch to BANK 14 (enable RAM#0)
	jmp Eval80			;function evaluation wedge

Eval80p_size = * - Eval80p_src		;size (6 bytes)

DrawLn80p_src
;DrawLn80 patch for XOR-ed polygonal lines
;(to be installed in HIGH memory, between DrawLn80_ext and DLoop80)

	bit plotmode		;check plot mode
	bvs DLoop80a		;XOR mode (bit 6)

DLoop80a = * + 3		;avoid drawing first point of line (skip GPlot80)
DrawLn80p_size = * - DrawLn80p_src	;size (4 bytes)

Box80_src
;Draw a box
;(to be installed in Main memory, after BOX_cmd)

	stx X_REG		;fill flag
	ldx #<Box80_ext-1
	ldy #>Box80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

Box80_size = * - Box80_src		;size (9 bytes)

Circle80_src
;Draw a circle
;(to be installed in Main memory, after CIRCLE_cmd)

	stx X_REG		;degrees per segment
	ldx #<Circle80_ext-1
	ldy #>Circle80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

Circle80_size = * - Circle80_src	;size (9 bytes)

Paint80p_src
;PAINT routine patch 
;(to be installed in HIGH memory, before Paint80_ext)

	jsr ReadPt80		;test pixel at current pos
	bcs +			;out of range (then exit)
	bne ++			;not the same (then start)
+	rts			;exit (no changes)

++	ldx #<GARBA2		;perform a Garbage collection
	ldy #>GARBA2		;(could return with RAM#1 enabled, so JSRFAR is required)
	jsr JsrFar_BNK15	;call subroutine (then continue with Paint80_ext)

Paint80p_size = * - Paint80p_src	;size (15 bytes)

; --------------------
; - Module sources
; --------------------

ext_src
!pseudopc ext_ram0 {

SetTxt80_ext
;Activate VDC text mode
	lda #0			;restore standard target screen
	sta targscn		;for graphics and CHAR command (bits 7:6)

;Set VDC screen mode
	ldx #vdc_HSS		;[R25] HORIZONTAL SMOOTH SCROLL
	jsr ReadReg		;read register

	and #$0f		;clear flags (hi-nibble)
	ora #$40		;enable attributes (bit 6)
	jsr WrtReg		;update register

;Set display memory
	ldx #vdc_DAH		;[R12] DISPLAY START ADDRESS HI
	lda #>VDCSCN		;(default address = $0000)
	jsr WrtReg		;update register

	inx			;[R13] DISPLAY START ADDRESS LO
	lda #<VDCSCN
	jsr WrtReg		;update register

;Set attribute memory
	ldx #vdc_AAH		;[R20] ATTRIBUTE START ADDRESS HI
	lda #>VDCATT		;(default address = $0800)
	jsr WrtReg		;update register

	inx			;[R21] ATTRIBUTE START ADDRESS LO
	lda #<VDCATT
	jsr WrtReg		;update register

;Set horizontal resolution
	lda #<vdc640h		;get parameters
	ldy #>vdc640h
	jsr SetRegsX		;set horizontal registers

;Set vertical resolution
	lda #<vdc200c8		;get parameters (8x8 color cell)
	ldy #>vdc200c8
	jmp SetRegsY		;set vertical registers (then return)

SetBmp80_ext
;Activate VDC bitmap mode
	lda #$c0		;set VDC as target screen
	sta targscn		;for graphics and CHAR command (bits 7:6)

;Set VDC screen mode
	ldx #vdc_HSS		;[R25] HORIZONTAL SMOOTH SCROLL
	jsr ReadReg		;read register

	and #$0f		;clear flags (hi-nibble)
	ora #$80		;set bitmap mode (bit 7)

	ldy modec		;check color mode
	beq +			;monochrome
	ora #$40		;enable attribute mode (bit 6)

+	ldy modex		;check horizontal mode
	cpy #2			;(320h or 360h)
	bcs +
	ora #$10		;set double pixel mode (bit 4)
+	jsr WrtReg		;update register

;Set display memory
	ldx vdcram		;detected VDC RAM
	lda bmp_page,x

	ldx #vdc_DAH		;[R12] DISPLAY START ADDRESS HI
	jsr WrtReg		;update register

	inx			;[R13] DISPLAY START ADDRESS LO
	lda #0
	jsr WrtReg		;update register

;Set attribute memory
	ldx vdcram		;detected VDC RAM
	lda att_page,x

	ldx #vdc_AAH		;[R20] ATTRIBUTE START ADDRESS HI
	jsr WrtReg		;update register

	inx			;[R21] ATTRIBUTE START ADDRESS LO
	lda #0
	jsr WrtReg		;update register

;Set horizontal resolution
	ldx modex		;horizontal mode
	lda vdcmodex_lo,x	;get parameters
	ldy vdcmodex_hi,x
	jsr SetRegsX		;set horizontal registers

;Set vertical resolution
	ldx modey		;vertical mode
	lda vdcmodey_lo,x	;get parameters (8x8 color cell)
	ldy vdcmodey_hi,x

;Set color mode
	ldx modec		;color mode
	beq SetRegsY		;set vertical registers (monochrome)

;Set cell size
-	dex
	beq SetRegsY		;set vertical registers (with attributes)
	clc
	adc #vdcregsy_count	;next parameters
	bcc -
	iny
	bne -			;(forced)

SetRegsX
;Set VDC internal registers related to horizontal resolution
	sta INDEX1
	sty INDEX1+1

	ldy #vdcregsx_count-1
-	lda (INDEX1),y
	ldx vdcregsx,y
	jsr WrtReg		;update register
	dey
	bpl -
	rts

SetRegsY
;Set VDC internal registers related to vertical resolution
	sta INDEX1
	sty INDEX1+1

	ldy #vdcregsy_count-1
-	lda (INDEX1),y
	ldx vdcregsy,y
	jsr WrtReg		;update register
	dey
	bpl -
	rts

ClrBmp80_ext
;Clear VDC bitmap screen and reset coords
	jsr CLRPOS		;top left position (XPOS,YPOS -> 0,0)

;Clear VDC bitmap screen
	ldx vdc_VSS		;[R24] VERTICAL SMOOTH SCROLL
	jsr ReadReg		;read register
	and #$7f		;set fill mode (clear bit 7)
	jsr WrtReg		;update register

;Clear bitmap memory
	ldx vdcram		;detected VDC RAM
	lda bmp_page,x		;bitmap start address (hi-byte)
	ldy bmp_size,x		;number of blocks (pages)
	ldx #0			;fill value (clear)
	jsr FillMem		;clear display memory

	lda modec
	beq +			;no attributes (exit)

;Init attribute memory
	ldx vdcram		;detected VDC RAM
	lda att_page,x		;attribute start address (hi-byte)
	ldy att_size,x		;number of blocks (pages)
	ldx attrsrc		;fill value (attribute source) (then continue)

FillMem
;Fill VDC memory
;
;args:	a = start page
;	x = fill value
;	y = number of blocks

	sta GRAPNT+1		;start address
	lda #0
	sta GRAPNT		;lo-byte

	txa			;fill value
	pha

	jsr SetMem80		;set start address
	pla			;fill value
	jsr Write80		;write value
	jsr SetMem80		;restore start address

	ldx #vdc_COUNT		;[R30] WORD COUNT
	lda #0			;block size (256 bytes)
-	jsr WrtReg		;fill block
	dey			;remaining blocks
	bne -
+	rts

; --------------------
; - COLOR routine
; --------------------

Color80_ext
;Set VDC screen color
;
;args:	a = source (7..9)
;	x = color (1..16)

	dex			;set color range (0..15)
	cpx #color_count	;check max value (+1)
	bcc +
-	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

+	lda VIC2RGB,x		;get RGBI color code
	ldx A_REG		;restore source value

	cpx #7			;check source
	bne +
	jmp SetFgCol80		;set VDC mono foreground color (then exit)

+	cpx #8			;check source
	bne +

	asl			;shift to hi-nibble
	asl
	asl
	asl
	sta tmp			;save background color

	lda attrsrc		;current attribute source
	and #$0f		;clear hi-nibble
	bpl ++			;(forced)

+	cpx #9			;check source value
	bne -			;'ILLEGAL QUANTITY'

	sta tmp			;save foreground color
	lda attrsrc		;current attribute source
	and #$f0		;clear lo-nibble

++	ora tmp			;merge nibbles
	sta attrsrc		;update attribute source
	rts

Color80_size = * - Color80_ext

; --------------------
; - CHAR routine
; --------------------

Char80_ext
;Print a BASIC string to VDC bitmap screen
;
;args:	a = string length
;	x/y -> string pointer
;	COLCNT = start column
;	ROWCNT = start row
;	CHRREV = reverse flag
;	CHRLO = lowercase charset page
;	CHRUP = uppercase charset page
;
;used:	NUMCNT = string length
;	INDEX1 -> string pointer	
;	STRCNT = string counter
;	CHRPAG = charset page

;Save string data
	sta NUMCNT		;string length
	stx INDEX1		;string address
	sty INDEX1+1

;Check string length
	tax			;check length
	beq chr_exit		;nothing to print (exit)

;Start printing
	lda CHRUP		;uppercase charset page (default)
	sta CHRPAG		;set page
	ldy #0			;clear string counter

chr_loop
	sty STRCNT		;update string counter
	jsr IndFetch_RAM1	;get a char from the string in RAM#1

	cmp #CASE_lo		;check for lowercase
	bne +
	lda CHRLO		;lowercase charset page
	bne ++			;(forced)
+	cmp #CASE_up		;check for uppercase
	bne chr_out
	lda CHRUP		;uppercase charset page
++	sta CHRPAG		;set page
	bne chr_next		;do not print (forced)

chr_out
	jsr ChrDsp80		;print char
	inc COLCNT		;next column
	lda COLCNT
	ldx modex		;horizontal mode
	cmp txt_cols,x		;check right margin
	bcc chr_next

	lda #0			;reset column
	sta COLCNT
	inc ROWCNT		;next row
	lda ROWCNT
	ldx modey		;vertical mode
	cmp txt_rows,x		;check bottom margin
	bcs chr_exit		;stop printing (exit)

chr_next
	ldy STRCNT		;string counter
	iny			;next char
	cpy NUMCNT		;check length
	bne chr_loop

chr_exit
	rts			;done

ChrDsp80
;Display a character to VDC bitmap screen
;
;args:	a = char to print
;	plotmode = plot mode
;	COLCNT = column position
;	ROWCNT = row position
;	CHRREV = reverse flag
;	CHRPAG = charset page
;
;used:	INDEX2 -> char shape pointer

;Char pointer
	ldy #0			;clear hi-byte
	sty INDEX2+1
	asl			;multiply by 8
	rol INDEX2+1
	asl
	asl			;discard bit 6
	rol INDEX2+1
	sta INDEX2		;lo-byte

	lda INDEX2+1
	adc CHRPAG		;add charset page
	sta INDEX2+1		;hi-byte

;Get attribute address
	ldx modec		;color mode
	beq ++			;monochrome

	lda ROWCNT		;current row
	dex
	beq +			;8x8 color cell

	asl			;8x4 color cell (multiply by 2)
	dex
	beq +
	asl			;8x2 color cell (multiply by 4)

+	ldx vdcram		;detected VDC RAM
	ldy att_page,x		;attribute start page
	jsr YComp		;add vertical component

	lda COLCNT		;current column
	jsr UpdAddr80		;add horizontal component

;Update char color
	jsr ColrChar		;8x8 color cell

	ldy modec		;color mode
	dey
	beq ++

	jsr ColrNext		;8x4 color cell
	dey
	beq ++

	jsr ColrNext		;8x2 color cell
	jsr ColrNext

;Get bitmap address
++	lda ROWCNT		;current row
	asl
	asl
	asl			;multiply by 8

	ldx vdcram		;detected VDC RAM
	ldy bmp_page,x		;bitmap start page
	jsr YComp		;add vertical component

	lda COLCNT		;current column
	jsr UpdAddr80		;add horizontal component

;Draw char shape
	ldy #0			;index to char line
	lda #INDEX2		;char shape pointer
	sta FETVEC		;set FETCH pointer

-	ldx #BANKT[14]		;set BANK 14 as target (character ROM enabled)
	jsr FETCH		;get a line of the char (then return to current BANK)

	ldx CHRREV		;reverse flag
	beq +
	eor #$ff		;flip bits

+	ldx plotmode		;check plot mode
	beq ++			;draw solid char (default)

	sta tmp			;save char line
	jsr SetMem80		;set address
	jsr Read80		;read cell

	bit plotmode		;check plot mode
	bpl +
	ora tmp			;OR mode
	bvs ++			;else clear (OR then XOR)
+	eor tmp			;XOR mode

++	pha
	jsr SetMem80		;set address
	pla
	jsr Write80		;draw char line

	ldx modex		;horizontal mode
	lda txt_cols,x		;screen columns
	jsr UpdAddr80		;next screen line

	iny			;next char line
	cpy #8			;char height
	bne -
	rts

ColrNext
;Move to the cell below
	ldx modex		;horizontal mode
	lda txt_cols,x		;screen columns
	jsr UpdAddr80		;next screen line (then continue)

ColrChar
;Update cell color
	jsr SetMem80		;set address
	lda attrsrc		;attribute source (background/foreground)
	jmp Write80		;write attribute (then return)

Char80_size = * - Char80_ext

; --------------------
; - GSHAPE routine
; --------------------

GShape80_ext
;Draw a shape
;
;args:	a = string length
;	x/y -> string pointer
;	GETTYP = replace mode
;	XDEST, YDEST = dest coords
;
;used:	INDEX1 -> string pointer
;	STRPTR = string counter
;	BITCNT = bit counter
;	NEWBYT = byte to draw
;	XSIZE = shape width
;	YSIZE = shape height
;	VTEMP = temp width

;Save string data
	stx INDEX1		;string address
	sty INDEX1+1		;(INDEX1 may have been overwritten by FRMEVL)
	tay			;string length

;Check string length
	cpy #5			;check min length
	bcc gs_exit		;string too small (exit without error)

;Get shape sizes
	ldx #4			;(last 4 bytes of string)
-	dey			;index (string length)
	jsr IndFetch_RAM1	;get a byte from the string in RAM#1
	sta XSIZE-1,x		;save size (XSIZE, YSIZE)
	dex
	bne -

;Start drawing
	stx STRPTR		;clear string counter
	jsr DSTPOS		;move dest coords to current

gs_row_loop
	lda XSIZE		;restore x-size (copy)
	sta VTEMP
	lda XSIZE+1
	sta VTEMP+1

gs_byte_loop
	lda #8			;init bit counter
	sta BITCNT

	ldy STRPTR		;string counter
	jsr IndFetch_RAM1	;get a byte from the string in RAM#1
	inc STRPTR		;next char
	sta NEWBYT		;byte to draw

gs_bit_loop
	jsr gs_plot		;plot a pixel of the shape

	lda VTEMP		;decrement x-size (copy)
	bne +
	dec VTEMP+1
+	dec VTEMP

	bit VTEMP+1		;check x-size (underflow)
	bmi gs_next_row

	inc XPOS		;increment x-coord
	bne +
	inc XPOS+1

+	dec BITCNT		;decrement bit counter
	bne gs_bit_loop		;next bit
	beq gs_byte_loop	;next byte (forced)

gs_next_row
	ldy #XPOS-VWORK		;XDEST -> XPOS (0)
	jsr DSTMOV		;restore x-coord

	inc YPOS		;increment y-coord
	bne +
	inc YPOS+1

+	lda YSIZE		;decrement y-size
	bne +
	dec YSIZE+1
+	dec YSIZE

	bit YSIZE+1		;check y-size (underflow)
	bpl gs_row_loop

gs_exit
	rts			;done

gs_plot
;Plot a pixel of the shape according to replace mode
;
;args:	plotmode = plot mode
;	GETTYP = replace mode
;	NEWBYT = byte to draw

	lda #0			;plot mode (set pixel)
	sta plotmode
	jsr ReadPt80		;test pixel

	asl NEWBYT		;leftmost bit on carry
	ldx GETTYP		;replace mode
	bne +

gs_draw
	bcs gs_set		;draw as is (0)
	bcc gs_clear		;clear pixel (forced)
+	dex
	bne +

gs_invert
	bcs gs_clear		;invert (1)
	bcc gs_set		;set pixel (forced)
+	dex
	bne +

	bcs gs_set		;OR (2)
	bcc ++			;skip (forced)
+	dex
	bne +

	tax			;AND (3)
	bne ++			;off -> skip
	beq gs_draw		;on -> draw as is (forced)

+	tax			;XOR (4)
	bne gs_draw		;off -> draw as is
	beq gs_invert		;on -> invert (forced)

gs_clear
	lda #$80		;plot mode (clear pixel)
	sta plotmode

gs_set
	jsr GPlot80a		;draw a pixel (ignoring width mode)
++	rts

GShape80_size = * - GShape80_ext

; --------------------
; - SSHAPE routine
; --------------------

SShape80_ext
;Save a shape
;
;args:	a/y -> string descriptor
;	XDEST, YDEST = dest coords
;	XABS, YABS = opposite coords
;
;used:	plotmode = plot mode
;	STRADR -> string descriptor
;	INDEX1 -> string pointer
;	DSCTMP = string length
;	STRPTR = string counter
;	FACMO -> pointer to the temp string descriptor
;	FORPNT -> pointer to the new string descriptor
;	BITCNT = bit counter
;	NEWBYT = byte to save
;	XSIZE = shape width
;	YSIZE = shape height
;	VTEMP = temp width
;	INDEX2 = temp height

;Save string data
	sta STRADR		;address of string descriptor
	sty STRADR+1

;Allocate space in memory for a temp string
	lda #$ff		;set string length to the maximum (255 bytes)
	sta A_REG		;put it in accumulator storage

	ldx #<STRSPA		;get space for string (length -> a, address -> x/y, descriptor -> DSCTMP)
	ldy #>STRSPA		;(always returns with RAM#1 enabled, JSRFAR required)
	jsr JsrFar_BNK15	;call subroutine

	stx INDEX1		;make a copy of string pointer in RAM#1
	sty INDEX1+1

;Set shape sizes
	ldx #XDEST-VWORK	;offset to dest x-coord ($04)
	ldy #XABS-VWORK		;offset to opposite x-coord ($08)
	jsr ABSTWO		;get the absolute difference
	sta XSIZE		;save x-size
	sty XSIZE+1
	bcs +			;check the biggest coord (XABS >= XDEST)

	ldy #XDEST-VWORK	;XABS -> XDEST ($04)
	jsr DSTMOV		;change dest x-coord with opposite

+	ldx #YDEST-VWORK	;offset to dest y-coord ($06)
	ldy #YABS-VWORK		;offset to opposite y-coord ($0a)
	jsr ABSTWO		;get the absolute difference
	sta YSIZE		;save y-size
	sty YSIZE+1
	sta INDEX2		;make a copy of y-size
	sty INDEX2+1
	bcs +			;check the biggest coord (YABS >= YDEST)

	ldy #YDEST-VWORK	;YABS -> YDEST ($06)
	jsr DSTMOV		;change dest y-coord with opposite

;Start saving
+	lda #0			;set plot mode (set pixel)
	sta plotmode
	sta STRPTR		;clear string counter
	jsr DSTPOS		;move dest coords to current

ss_row_loop
	ldy #XPOS-VWORK		;XDEST -> XPOS (0)
	jsr DSTMOV		;restore x-coord

	lda XSIZE		;restore x-size (copy)
	sta VTEMP
	lda XSIZE+1
	sta VTEMP+1

ss_byte_loop
	lda #8			;init bit counter
	sta BITCNT

ss_bit_loop
	bit VTEMP+1		;check x-size (underflow)
	bmi +			;out of shape

	jsr ReadPt80		;get pixel value at current coords
	bcs +			;out of range
	bne +			;empty pixel

	sec			;pixel is on
	!by BIT1_opc		;mask the next byte

+	clc			;pixel is off
	rol NEWBYT		;align bits to the left (carry -> bit 0)

	inc XPOS		;increment x-coord
	bne +
	inc XPOS+1

+	lda VTEMP		;decrement x-size (copy)
	bne +
	dec VTEMP+1
+	dec VTEMP

	dec BITCNT		;decrement bit counter
	bne ss_bit_loop		;next bit

;Save a byte
	lda NEWBYT		;byte to save
	ldy STRPTR		;string counter
	jsr IndStash_RAM1	;save a byte into the string in RAM#1
	inc STRPTR		;next char

	ldy STRPTR		;check string length
	cpy #$fc		;less than 252
	bcc +
	jmp ERRLEN		;generate a 'STRING TOO LONG' error (then exit)

+	bit VTEMP+1		;check x-size (underflow)
	bpl ss_byte_loop	;next byte

ss_next_row
	inc YPOS		;increment y-coord
	bne +
	inc YPOS+1

+	lda INDEX2		;decrement y-size (copy)
	bne +
	dec INDEX2+1
+	dec INDEX2

	bit INDEX2+1		;check y-size (underflow)
	bpl ss_row_loop		;next row

;Save shape sizes
	ldy STRPTR		;string counter
	ldx #0
-	lda XSIZE,x		;shape size (XSIZE, YSIZE)
	jsr IndStash_RAM1	;save a byte into the string in RAM#1
	iny
	inx
	cpx #4			;(last 4 bytes of string)
	bne -

	sty DSCTMP		;update string length

;Set FACMO as pointer to the temp string descriptor
	jsr PUTNEW		;put temp string descriptor in the temp descriptor stack (DSCTMP -> TEMPST)

;Set FORPNT as pointer to the new string descriptor
	lda STRADR
	sta FORPNT
	lda STRADR+1
	sta FORPNT+1

;Create a copy of temp string descriptor (FACMO -> FORPNT)
;and remove its descriptor from the temp descriptor stack (TEMPST)

	ldx #<COPY		;routine address
	ldy #>COPY		;(always returns with RAM#1 enabled, JSRFAR required)
	jmp JsrFar_BNK15	;call subroutine (then return)

SShape80_size = * - SShape80_ext

; --------------------
; - RGR routine
; --------------------

RGR_ext
	clc			;clear carry

;Scale mode
	dex			;check argument (1)
	bne +
	ldy SCALEM		;current scale mode (0 = off, 1 = on)
	bcc rt_y		;return value (forced)

;Pixel width
+	dex			;check argument (2)
	bne +
	ldy WIDTH		;current pixel width (0 = single, 1 = double)
	iny			;set range (1..2)
	bne rt_y		;return value (forced)

;VDC horizontal mode
+	dex			;check argument (3)
	bne +
	ldy modex		;current horizontal mode
	bcc rt_y		;return value (forced)

;VDC vertical mode
+	dex			;check argument (4)
	bne +
	ldy modey		;current vertical mode
	bcc rt_y		;return value (forced)

;VDC color mode
+	dex			;check argument (5)
	bne +
	ldy modec		;current color mode
	bcc rt_y		;return value (forced)

;VDC screen mode
+	dex			;check argument (6)
	bne +
	jsr GetMode80		;get VDC screen mode (bit 7)
--	asl			;(bit 7 -> carry)
	rol			;(carry -> bit 0)
	tay
	bcc rt_y		;return value (forced)

;Graphics target screen
+	lda targscn		;current target screen
	dex			;check argument (7)
	bne +
	and #$80		;mask bit 7
	bcc --			;return value (forced)

;CHAR target screen
+	dex			;check argument (8)
	bne +
	asl			;(bit 6 -> bit 7)
	clc
	bcc --			;return value (forced)

;VDC RAM size
+	dex			;check argument (9)
	bne rt_iq		;'ILLEGAL QUANTITY'
	ldx vdcram		;detected VDC RAM (0 = 16k, 1 = 64k)
	ldy vdcram_tbl,x
	bcc rt_y		;return value (forced)

RGR_size = * - RGR_ext

; --------------------
; - RCLR routine
; --------------------

RCLR_ext
	cpx #7			;check argument
	bne +
	jsr GetFgCol80		;get VDC mono foreground color

rt_col	and #$0f		;clear hi-nibble
	tax
	ldy RGB2VIC,x		;get VIC-II color code (0..15)
rt_iny	iny			;set range (1..16)
rt_y	jmp SNGFLT		;return value (y -> FAC#1)

+	lda attrsrc		;current VDC attribute source
	cpx #9			;check argument
	beq rt_col		;return foreground color
	lsr			;shift to lo-nibble
	lsr
	lsr
	lsr
	cpx #8			;check argument
	beq rt_col		;return background color
rt_iq	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

RCLR_size = * - RCLR_ext

; --------------------
; - RDOT routine
; --------------------

RDOT_ext
	cpx #6			;check max value (+1)
	bcs rt_iq		;'ILLEGAL QUANTITY'

;Pixel status
	cpx #3			;check argument
	bne +

	lda #0			;plot mode (set)
	sta plotmode

	jsr ReadPt80		;test pixel
	ldy #0			;clear result
	bcs rt_y		;coords out of range (0)

	tax
	beq rt_iny		;pixel is on (1)
	bne rt_y		;pixel is off (0)

;Cell color
+	ldy modec		;check color mode
	beq rt_y		;no color (0)

	stx X_REG		;save argument
	jsr GetAtt80		;get cell color
	ldy #0			;clear result
	bcs rt_y		;coords out of range (0)

	ldx X_REG
	cpx #5			;check argument
	beq rt_col		;return foreground color

	lsr			;shift to lo-nibble
	lsr
	lsr
	lsr
	bpl rt_col		;return background color (forced)

RDOT_size = * - RDOT_ext

; --------------------
; - RWINDOW routine
; --------------------

RWINDOW_ext
;VDC bitmap width
	cpx #3			;check argument
	bne +
	ldx modex		;horizontal mode
	lda resx_hi,x
	ldy resx_lo,x
	bcs ++			;return value (forced)

;VDC bitmap height
+	cpx #4			;check argument
	bne +
	ldx modey		;vertical mode
	lda resy_hi,x
	ldy resy_lo,x
++	jmp GIVAYF		;return value (a/y -> FAC#1)

;VDC color cell height
+	cpx #5			;check argument
	bne +
	ldx modec		;color mode
	ldy cell_ht,x		;cell height
	bcs ++			;return value (forced)

;VDC bitmap columns
+	cpx #6			;check argument
	bne +
	ldx modex		;horizontal mode
	ldy txt_cols,x
	bcs ++			;return value (forced)

;VDC bitmap rows
+	cpx #7			;check argument
	bne rt_iq		;'ILLEGAL QUANTITY'
	ldx modey		;vertical mode
	ldy txt_rows,x
++	jmp SNGFLT		;return value (y -> FAC#1)

RWINDOW_size = * - RWINDOW_ext

; --------------------
; - Service routines
; --------------------

HelpMsg_ext
;Display HELP message
	jsr AboutPrg		;program info
	jsr VDCInfo		;VDC device info
	jsr AvailMem		;available memory

!if online_guide {
	jsr AutoFast_ext	;display AUTOFAST mode

	lda #<online_hlp	;Online Guide available
	ldy #>online_hlp
	jmp TextView_RAM1	;print message (then return)

} else {
	jmp AutoFast_ext	;display AUTOFAST mode (then return)
}

VDCInfo
;Display VDC current mode
	lda #<vdc_txt
	ldy #>vdc_txt
	jsr JsrFar_STROUT	;print string

;Screen width
	ldy modex		;horizontal mode
	lda resx_hi,y
	ldx resx_lo,y
	jsr JsrFar_LINPRT	;print int

;Screen height
	lda #'x'
	jsr JsrFar_CHROUT	;print char

	ldy modey		;horizontal mode
	lda resy_hi,y
	ldx resy_lo,y
	jsr JsrFar_LINPRT	;print int

;Color mode
	inc PNTR		;move cursor right
	lda #<mono_txt		;monochrome
	ldy #>mono_txt
	ldx modec		;color mode
	beq +

	lda #<cell_txt		;cell width
	ldy #>cell_txt
+	jsr JsrFar_STROUT	;print string

	ldy modec		;color mode
	beq ++			;monochrome

	ldx cell_ht,y		;cell height
	lda #0			;hi-byte
	jsr JsrFar_LINPRT	;print int

;Display detected VDC RAM
++	inc PNTR		;move cursor right
	ldy vdcram		;detected VDC RAM
	ldx vdcram_tbl,y
	lda #0			;hi-byte
	jsr JsrFar_LINPRT	;print int

	lda #'k'
	jsr JsrFar_CHROUT	;print char
	jmp Print_CR		;carriage return (then return)

AvailMem
;Display available system memory
	lda #<avail_txt
	ldy #>avail_txt
	jsr JsrFar_STROUT	;print string

	jsr FRE0		;FRE(0) -> FAC#1
	jsr MOVAF		;FAC#1 -> FAC#2
	jsr JsrFar_FRE1		;FRE(1) -> FAC#1

	jsr FADD2		;FAC#l = FAC#l + FAC#2
	jsr Print_FP		;print value

;BASIC program text area
	lda #<ram0_txt
	ldy #>ram0_txt
	jsr JsrFar_STROUT	;print string

	jsr FRE0		;FRE(0) -> FAC#1
	jsr Print_FP		;print value

;BASIC variable storage area
	lda #<ram1_txt
	ldy #>ram1_txt
	jsr JsrFar_STROUT	;print string

	jsr JsrFar_FRE1		;FRE(1) -> FAC#1 (then continue)

Print_FP
;Print a floating point value
	lda #avail_pos		;start column
	sta PNTR

	ldx #nodigits+1		;set decimal point position (1 digit) 
	stx DECCNT		;(required in case of zero)
	ldy #0			;FBUFFR index
	jsr FOUTC		;FAC#1 -> ASCII (then a/y -> FBUFFR)

;Right align output
	ldx DECCNT		;decimal point position
-	cpx #nodigits+6		;6 digits
	beq +
	inc PNTR		;move cursor right
	inx
	bne -			;(forced)
+	jsr JsrFar_STROUT	;print value (then continue)

Print_CR
;Print a carriage return
	lda #CR			;carriage return (then continue)

JsrFar_CHROUT
;Print a char to the current text screen
	sta A_REG		;char

	ldx #<CHROUT		;print char
	ldy #>CHROUT		;(JSRFAR required to enable Kernal ROM)
	jmp JsrFar_BNK15	;call subroutine (then return)

AutoFast_ext
;Display AUTOFAST mode
	lda #<autofast_txt
	ldy #>autofast_txt
	jsr JsrFar_STROUT	;print string

	lda #<enabled_txt
	ldy #>enabled_txt

	bit autofast		;check AUTOFAST mode (bit 7)
	bmi +

	lda #<disabled_txt
	ldy #>disabled_txt
+	jmp JsrFar_STROUT	;print string (then return)

AboutPrg
;Display program info
	lda #<about_txt
	ldy #>about_txt		;(then continue)

JsrFar_STROUT
;Print a string in RAM#0
	sta A_REG		;string address
	sty Y_REG

	ldx #<STROUT		;print string
	ldy #>STROUT		;(JSRFAR required to enable Editor ROM)
	jmp JsrFar_BNK15	;call subroutine (then return)

JsrFar_LINPRT
;Print a 16-bit unsigned integer
	sta A_REG		;hi-byte
	stx X_REG		;lo-byte

	ldx #<LINPRT		;print int
	ldy #>LINPRT		;(JSRFAR required to enable Editor ROM)
	jmp JsrFar_BNK15	;call subroutine (then return)

JsrFar_FRE1
;Get free memory in variable storage area
	ldx #<FRE1		;FRE(1) -> FAC#1
	ldy #>FRE1		;(could return with RAM#1 enabled, JSRFAR required)
	jmp JsrFar_BNK15	;call subroutine (then return)

ChkStop
;Test for RUN/STOP keypress
	ldx #<CHKSTP		;check STOP
	ldy #>CHKSTP		;(JSRFAR required to enable Kernal ROM)
	jmp JsrFar_BNK15	;call subroutine (then return)

; --------------------
; - HELP routines
; --------------------

!if online_guide {

GetHelp
;Display HELP for a specified command/function
;
;args:	a = token

;Special cases
	cmp #ADD_tk		;HELP+
	bne +
	jsr AboutPrg		;program info

	lda #<cmd_list_hlp	;command list
	ldy #>cmd_list_hlp
	jsr TextView_RAM1

	lda #<HELP_cmd_hlp	;command details
	ldy #>HELP_cmd_hlp
	bne help_view		;(forced)

+	cmp #AUTO_tk		;AUTOFAST
	bne +
	jsr JsrFar_CHRGET	;get next char
	cmp #CMD_dtk		;dual token command prefix
	bne help_err
	jsr JsrFar_CHRGET	;get next char
	cmp #FAST_dtk		;FAST token
	bne help_err

	lda #<AUTOFAST_hlp
	ldy #>AUTOFAST_hlp
	bne help_view		;(forced)

+	cmp #CMD_dtk		;dual token command prefix
	bne +
	jsr JsrFar_CHRGET	;get next char
	cmp #QUIT_dtk		;QUIT token
	bne help_err

	lda #<QUIT_hlp
	ldy #>QUIT_hlp
	bne help_view		;(forced)

+	cmp #FN_dtk		;dual token function prefix
	bne +
	jsr JsrFar_CHRGET	;get next char
	cmp #RWINDOW_dtk	;RWINDOW token
	bne help_err

	lda #<RWINDOW_hlp
	ldy #>RWINDOW_hlp
	bne help_view		;(forced)

;Search for single token
+	ldx #0
-	cmp help_tk_tbl,x
	beq +			;token found
	inx
	cpx #help_count
	bne -

help_err
	ldx #SYNTAX_err		;'SYNTAX ERROR'
	jmp ERROR		;generate error message (then exit)

;Get text address
+	txa			;table index
	asl			;multiply by 2
	tax
	lda help_txt_tbl,x
	ldy help_txt_tbl+1,x

help_view
	jsr TextView_RAM1

help_exit

JsrFar_CHRGET
;Get the next BASIC text character
	ldx #<CHRGET
	ldy #>CHRGET		;(JSRFAR required to preserve current BANK)
	jmp JsrFar_BNK15	;call subroutine (then return)

TextView_RAM1
;Display text data stored in RAM#1
;
;args:	a/y -> text pointer

	sta INDEX1		;text pointer
	sty INDEX1+1

--	ldy #0
-	jsr IndFetch_RAM1	;get a char from RAM#1
	tax
	beq +			;end of text

	sty Y_REG		;preserve index
	jsr JsrFar_CHROUT	;print char
	jsr ChkStop		;check STOP

	iny			;next char
	bne -

	inc INDEX1+1		;next page
	bne --			;(forced)
+	rts

; --------------------
; - HELP tables
; --------------------

help_tk_tbl
	!by GRAPHIC_tk,COLOR_tk,SCNCLR_tk,LOCATE_tk
	!by DRAW_tk,BOX_tk,CIRCLE_tk,PAINT_tk
	!by CHAR_tk,GSHAPE_tk,SSHAPE_tk,HELP_tk
	!by RGR_tk,RCLR_tk,RDOT_tk,POS_tk
help_count = * - help_tk_tbl

help_txt_tbl
	!wo GRAPHIC_hlp,COLOR_hlp,SCNCLR_hlp,LOCATE_hlp
	!wo DRAW_hlp,BOX_hlp,CIRCLE_hlp,PAINT_hlp
	!wo CHAR_hlp,GSHAPE_hlp,SSHAPE_hlp,HELP_hlp
	!wo RGR_hlp,RCLR_hlp,RDOT_hlp,POS_hlp
}
;online_guide

; --------------------
; - Strings
; --------------------

strings_start

about_txt
	!tx CR,prgname," v",version
	!tx " (c) ",prgdate," ",author
	!by CR,0

vdc_txt
	!tx "vdc "
	!by 0

mono_txt
	!tx "mono"
	!by 0

cell_txt
	!tx "8x"
	!by 0

avail_txt
	!tx CR,"available memory"
	!by 0

avail_pos = * - avail_txt - 1

ram0_txt
	!tx "basic text area"
	!by 0

ram1_txt
	!tx "variable storage"
	!by 0

autofast_txt
	!tx CR,"autofast "
	!by 0

enabled_txt
	!tx "enabled"
	!by CR,0

disabled_txt
	!tx "disabled"
	!by CR,0

quit_txt
	!tx CR,prgname," disabled"
	!tx CR,"sys",main_addr,":rem restart"
	!by CR,0

strings_size = * - strings_start
ext_size = * - ext_ram0
}
;pseudopc

; --------------------
; - Online Guide
; --------------------

!if online_guide {

guide_src
!pseudopc ext_ram1 {

online_hlp
	!tx "help+ online guide"
	!by CR,0

cmd_list_hlp
	!tx CR,"extended commands:"
	!tx CR,"graphic",TAB,"color",TAB,"scnclr",TAB,"locate"
	!tx CR,"draw",TAB,"box",TAB,"circle",TAB,"paint"
	!tx CR,"char",TAB,"gshape",TAB,"sshape",TAB,"autofast"
	!tx CR,"help",TAB,"quit"
	!by CR
	!tx CR,"extended functions:"
	!tx CR,"rgr",TAB,"rclr",TAB,"rwindow"
	!tx CR,"rdot",TAB,"pos"
	!by CR,0

GRAPHIC_hlp
	!tx CR,"graphic mode[,clr][,h/res][,v/res][,col]"
	!by CR
	!tx CR,"mode",TAB,"0. vic text 40",TAB,"1. vic bitmap"
	!tx CR,TAB,"2. vic b/split",TAB,"3. vic multicol"
	!tx CR,TAB,"4. vic m/split",TAB,"5. vdc text 80"
	!tx CR,TAB,"6. vdc bitmap"
	!by CR
	!tx CR,"clr",TAB,"1. clear screen (default = 0)"
	!by CR
	!tx CR,"h/res",TAB,"vdc horizontal mode"
	!tx CR,TAB,"0. 320 pixels",TAB,"1. 360 pixels"
	!tx CR,TAB,"2. 640  ",QT,ESC,ESC,TAB,"3. 720  ",QT
	!tx CR,TAB,"4. 800  ",QT,ESC,ESC,TAB,"5. 840  ",QT
	!by CR
	!tx CR,"v/res",TAB,"vdc vertical mode"
	!tx CR,TAB,"0. 128 pixels",TAB,"1. 144 pixels"
	!tx CR,TAB,"2. 176  ",QT,ESC,ESC,TAB,"3. 200  ",QT
	!tx CR,TAB,"4. 240  ",QT,ESC,ESC,TAB,"5. 256  ",QT
	!by CR
	!tx CR,"col",TAB,"vdc color mode"
	!tx CR,TAB,"0. monochrome",TAB,"1. 8x8 cells"
	!tx CR,TAB,"2. 8x4 cells",TAB,"3. 8x2  ",QT
	!tx CR,0

COLOR_hlp
	!tx CR,"color source,value"
	!by CR
	!tx CR,"source",TAB,"0. vic backgnd"
	!tx CR,TAB,"1. vic foregnd"
	!tx CR,TAB,"2. vic multicolor 1"
	!tx CR,TAB,"3. vic multicolor 2"
	!tx CR,TAB,"4. vic border"
	!tx CR,TAB,"5. text color (40/80)"
	!tx CR,TAB,"6. vdc text/mono backgnd/border"
	!tx CR,TAB,"7. vdc mono foregnd"
	!tx CR,TAB,"8. vdc attribute backgnd"
	!tx CR,TAB,"9. vdc attribute foregnd"
	!by CR
	!tx CR,"value",TAB,"1..16 color code"
	!by CR,0

SCNCLR_hlp
	!tx CR,"scnclr [mode]"
	!by CR
	!tx CR,"mode",TAB,"0. vic 40-column text"
	!tx CR,TAB,"1. vic bitmap"
	!tx CR,TAB,"2. vic bitmap split"
	!tx CR,TAB,"3. vic multicolor"
	!tx CR,TAB,"4. vic multicolor split"
	!tx CR,TAB,"5. vdc 80-column text"
	!tx CR,TAB,"6. vdc bitmap"
	!by CR
	!tx CR,"no args: clear current active screens"
	!by CR,0

LOCATE_hlp
	!tx CR,"locate x,y"
	!by CR
	!tx CR,"x,y",TAB,"pixel cursor position"
	!by CR,0

DRAW_hlp
	!tx CR,"draw [mode][,x0,y0][<to/,> xn,yn][...]"
	!by CR
	!tx CR,"mode",TAB,"0. clear"
	!tx CR,TAB,"1. set (default)"
	!tx CR,TAB,"2. xor"
	!by CR
	!tx CR,"x0,y0",TAB,"start point (current)"
	!tx CR,"xn,yn",TAB,"end of line/next point"
	!by CR,0

BOX_hlp
	!tx CR,"box [mode],x0,y0[,x1,y1][,rot][,fill]"
	!by CR
	!tx CR,"mode",TAB,"0. clear"
	!tx CR,TAB,"1. set (default)"
	!tx CR,TAB,"2. xor"
	!by CR
	!tx CR,"x0,y0",TAB,"start corner"
	!tx CR,"x1,y1",TAB,"opposite corner (current)"
	!tx CR,"rot",TAB,"rotation angle (0)"
	!by CR
	!tx CR,"fill",TAB,"0. outline (default)"
	!tx CR,TAB,"1. filled (no xor mode)"
	!by CR,0

CIRCLE_hlp
	!tx CR,"circle [mode][,xc,yc][,xr][,yr]"
	!tx CR,TAB,TAB,"[,sa][,ea][,rot][,inc]"
	!by CR
	!tx CR,"mode",TAB,"0. clear"
	!tx CR,TAB,"1. set (default)"
	!tx CR,TAB,"2. xor"
	!by CR
	!tx CR,"xc,yc",TAB,"center coords (current)"
	!tx CR,"xr",TAB,"x-radius (0)"
	!tx CR,"yr",TAB,"y-radius (xr)"
	!tx CR,"sa",TAB,"start arc angle (0)"
	!tx CR,"ea",TAB,"end arc angle (360)"
	!tx CR,"rot",TAB,"rotation angle (0)"
	!tx CR,"inc",TAB,"degrees between segments (2)"
	!by CR,0

PAINT_hlp
	!tx CR,"paint [mode][,x,y]"
	!by CR
	!tx CR,"mode",TAB,"0. clear area"
	!tx CR,TAB,"1. fill area (default)"
	!by CR
	!tx CR,"x,y",TAB,"start position (current)"
	!by CR
	!tx CR,"note: <run/stop> break operation"
	!by CR,0

CHAR_hlp
	!tx CR,"char [mode],col,row[,str][,rev]"
	!by CR
	!tx CR,"mode",TAB,"0. clear"
	!tx CR,TAB,"1. solid (default)"
	!tx CR,TAB,"2. xor"
	!tx CR,TAB,"3. or"
	!by CR
	!tx CR,"col",TAB,"start column"
	!tx CR,"row",TAB,"start row"
	!tx CR,"str",TAB,"string to print"
	!by CR
	!tx CR,"rev",TAB,"0. normal (default)"
	!tx CR,TAB,"1. reverse"
	!by CR,0

GSHAPE_hlp
	!tx CR,"gshape str[,x,y][,mode]"
	!by CR
	!tx CR,"str",TAB,"source string variable"
	!tx CR,"x,y",TAB,"top/left corner (current)"
	!by CR
	!tx CR,"mode",TAB,"0. plot as is (default)"
	!tx CR,TAB,"1. invert"
	!tx CR,TAB,"2. or"
	!tx CR,TAB,"3. and"
	!tx CR,TAB,"4. xor"
	!by CR,0

SSHAPE_hlp
	!tx CR,"sshape str,x0,y0[,x1,y1]"
	!by CR
	!tx CR,"str",TAB,"target string variable"
	!by CR
	!tx CR,"x0,y0",TAB,"start corner"
	!tx CR,"x1,y1",TAB,"opposite corner (current)"
	!by CR,0

AUTOFAST_hlp
	!tx CR,"autofast"
	!tx CR,"- enable autofast"
	!by CR
	!tx CR,"fast/slow"
	!tx CR,"- disable autofast"
	!tx CR,"- set the specified cpu speed"
	!by CR,0

HELP_hlp
	!tx CR,"help"
	!tx CR,"- about ",prgname
	!tx CR,"- current vdc mode"
	!tx CR,"- detected vdc ram"
	!tx CR,"- available memory"
	!tx CR,"- autofast mode"
	!tx CR,"- online guide availability"
	!tx CR,"- last program error (if any)"
	!by CR
	!tx CR,"help+"
	!tx CR,"- command/function list"
	!by CR

HELP_cmd_hlp
	!tx CR,"help keyword"
	!tx CR,"- command/function details"
	!by CR,0

QUIT_hlp
	!tx CR,"quit"
	!tx CR,"- return to basic v7.0"
	!by CR
	!tx CR,"sys",main_addr
	!tx CR,"- restart ",prgname
	!by CR,0

RGR_hlp
	!tx CR,"rgr(n)"
	!by CR
	!tx CR,"n = 0",TAB,"screen mode (standard)"
	!tx CR,"    1",TAB,"scale mode"
	!tx CR,"    2",TAB,"pixel width"
	!tx CR,"    3",TAB,"vdc horizontal mode"
	!tx CR,"    4",TAB,"vdc vertical mode"
	!tx CR,"    5",TAB,"vdc color mode"
	!tx CR,"    6",TAB,"vdc screen mode"
	!tx CR,TAB,"(0 = text, 1 = bitmap)"
	!tx CR,"    7",TAB,"graphics target screen"
	!tx CR,TAB,"(0 = vic, 1 = vdc)"
	!tx CR,"    8",TAB,"char target screen"
	!tx CR,TAB,"(0 = standard, 1 = vdc)"
	!tx CR,"    9",TAB,"vdc ram size (16/64)"
	!by CR,0

RCLR_hlp
	!tx CR,"rclr(n)"
	!by CR
	!tx CR,"n = 0",TAB,"vic backgnd"
	!tx CR,"    1",TAB,"vic foregnd"
	!tx CR,"    2",TAB,"vic multicolor 1"
	!tx CR,"    3",TAB,"vic multicolor 2"
	!tx CR,"    4",TAB,"vic border"
	!tx CR,"    5",TAB,"text color (40/80)"
	!tx CR,"    6",TAB,"vdc text/mono backgnd/border"
	!tx CR,"    7",TAB,"vdc mono foregnd"
	!tx CR,"    8",TAB,"vdc attribute backgnd"
	!tx CR,"    9",TAB,"vdc attribute foregnd"
	!by CR,0

RDOT_hlp
	!tx CR,"rdot(n)"
	!by CR
	!tx CR,"n = 0",TAB,"pixel cursor x position"
	!tx CR,"    1",TAB,"pixel cursor y  ",QT
	!tx CR,"    2",TAB,"vic pixel color source"
	!tx CR,"    3",TAB,"vdc pixel status"
	!tx CR,"    4",TAB,"vdc cell backgnd color"
	!tx CR,"    5",TAB,"vdc cell foregnd  ",QT
	!by CR,0

POS_hlp
	!tx CR,"pos(n)"
	!by CR
	!tx CR,"n = 0",TAB,"text cursor column"
	!tx CR,"    1",TAB,"text cursor row"
	!by CR,0

RWINDOW_hlp
	!tx CR,"rwindow(n)"
	!by CR
	!tx CR,"n = 0",TAB,"text window rows (-1)"
	!tx CR,"    1",TAB,"text window columns (-1)"
	!tx CR,"    2",TAB,"text screen mode (40/80)"
	!tx CR,"    3",TAB,"vdc bitmap width"
	!tx CR,"    4",TAB,"vdc bitmap height"
	!tx CR,"    5",TAB,"vdc color cell size"
	!tx CR,"    6",TAB,"vdc bitmap columns"
	!tx CR,"    7",TAB,"vdc bitmap rows"
	!by CR,0

guide_size = * - ext_ram1
guide_end
}
;pseudopc
}
;online_guide

; --------------------
; - Main program
; --------------------

main_src
!pseudopc main_ram0 {

; --------------------
; - Jump table
; --------------------

JumpTable
;Wedge80 Jump table

StartWedge_JT
	!by JMP_abs_opc		;Enable Wedge80
	!wo StartWedge

QuitWedge_JT
	!by JMP_abs_opc		;Disable Wedge80
	!wo QuitWedge

SetMem80_JT
	!by JMP_abs_opc		;Set VDC bitmap address (GRAPNT -> VDC R18/R19)
	!wo SetMem80

GetMode80_JT
	!by JMP_abs_opc		;Get VDC screen mode (VDC R25 bit 7 -> a)
	!wo GetMode80

SetTxt80_JT
	!by JMP_abs_opc		;Activate VDC text mode
	!wo SetTxt80

SetBmp80_JT
	!by JMP_abs_opc		;Activate VDC bitmap mode
	!wo SetBmp80

ClrBmp80_JT
	!by JMP_abs_opc		;Clear VDC bitmap screen and reset coords
	!wo ClrBmp80

GetBgCol80_JT
	!by JMP_abs_opc		;Get VDC mono background and border color (RGBI -> a)
	!wo GetBgCol80

SetBgCol80_JT
	!by JMP_abs_opc		;Set VDC mono background and border color (a -> RGBI)
	!wo SetBgCol80

GetFgCol80_JT
	!by JMP_abs_opc		;Get VDC mono foreground color (RGBI -> a)
	!wo GetFgCol80

SetFgCol80_JT
	!by JMP_abs_opc		;Set VDC mono foreground color (a -> RGBI)
	!wo SetFgCol80

GPlot80_JT
	!by JMP_abs_opc		;Draw a pixel (plotmode, XPOS, YPOS) (considering WIDTH and FILFLG)
	!wo GPlot80

ReadPt80_JT
	!by JMP_abs_opc		;Test a pixel (plotmode, XPOS, YPOS)
	!wo ReadPt80		;(cell mask -> a, pixel status -> zero bit, out of range -> carry)

DrawLn80_JT
	!by JMP_abs_opc		;Draw a line (plotmode, XPOS, YPOS, XDEST, YDEST)
	!wo DrawLn80

Box80_JT
	!by JMP_abs_opc		;Draw a box (plotmode, XCORDl, YCORDl, XCORD2, YCORD2, BOXANG, x = fill flag)
	!wo Box80

Circle80_JT
	!by JMP_abs_opc		;Draw a circle (plotmode, XCIRCL, YCIRCL, XRCOS, YRCOS, YRSIN, XRSIN, ANGBEG, ANGEND)
	!wo Circle80		;(CIRSUB and DSTPOS to get 1st point on circle) (x = degrees per segment)

Paint80_JT
	!by JMP_abs_opc		;Fill a graphics area (plotmode, XPOS, YPOS)
	!wo Paint80

Char80_JT
	!by JMP_abs_opc		;Print a BASIC string to VDC bitmap screen (Note: string must be in RAM#1)
	!wo Char80		;(plotmode, a = length, x/y = address, COLCNT/ROWCNT = position, CHRREV = reverse)

JumpTable_size = * - JumpTable

; --------------------
; - Start Wedge80
; --------------------

StartWedge
;Enable BASIC wedging
	lda #BANKT[15]		;enable BANK 15
	sta MMUCR

;Set custom indirect vectors
	lda #<Main80		;Main BASIC loop vector (default = $4dc6)
	sta IMAIN
	lda #>Main80
	sta IMAIN+1

	lda #<Gone80		;BASIC execution routine vector (default = $4aa2)
	sta IGONE
	lda #>Gone80
	sta IGONE+1

	lda #<Eval80p		;BASIC evaluation routine vector (default = $78da)
	sta IEVAL
	lda #>Eval80p
	sta IEVAL+1

	lda #<NMI_patch		;BASIC restart vector (default = $4003)
	sta SYSVEC
	lda #>NMI_patch
	sta SYSVEC+1

	jsr SetEscVec		;ESC sequence handler vector (default = $c9c1)

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

;Set default colors
!ifdef def_bg_mono {
	lda #def_bg_mono	;VDC mono background color
	jsr SetBgCol80
}

!ifdef def_fg_mono {
	lda #def_fg_mono	;VDC mono foreground color
	jsr SetFgCol80
}

!ifdef def_bg_attr {
!ifdef def_fg_attr {
	lda #(def_bg_attr << 4) OR (def_fg_attr & $0f)
	sta attrsrc		;VDC attribute source colors
}
}

;Set default AUTOFAST mode
	lda #(def_autofast != 0) << 7
	sta autofast

;Reset graphics coords
!if def_coords {
	jsr CLRPOS		;top left position (XPOS,YPOS -> 0,0)
}

;Set target screen
	jsr GetMode80		;get VDC screen mode (bit 7)
	beq +
	lda #$c0		;set VDC as target screen
+	sta targscn		;for graphics and CHAR command (bits 7:6)

;Set VDC memory type
	lda vdcram		;check detected VDC RAM
	beq +			;16k bytes

;Init VDC screen (64k bytes)
	ldx #vdc_CB		;[R28] CHARACTER BASE ADDRESS
	jsr ReadReg		;read register
	tay
	and #$10		;check VDC memory type (bit 4)
	bne +			;already 64k

	tya
	ora #$10		;enable 64k address mode (bit 4)
	jsr WrtReg		;update register

	jsr CLEAR80		;clear 80-column text screen
	jsr INIT80		;restore VDC character set

+	jmp HelpMsg		;display HELP message (then return to BASIC)

; --------------------
; - Quit Wedge80
; --------------------

QuitWedge
;Disable BASIC wedging
	lda #BANKT[15]		;enable BANK 15
	sta MMUCR

;Restore default indirect vectors
	lda #<WARMST		;restore BASIC restart vector
	sta SYSVEC
	lda #>WARMST
	sta SYSVEC+1

	jsr DefEscVec		;restore ESC sequence handler vector
	jsr INIVEC		;restore BASIC indirect vectors

;Restore system defaults
	jsr SetTxt80		;activate VDC text mode

	bit autofast		;check AUTOFAST mode (bit 7)
	bpl +
	jsr SLOW		;set SLOW mode

+	lda #<quit_txt
	ldy #>quit_txt
	jmp STROUT		;display quit message (then return to BASIC)

; --------------------
; - MAIN wedge
; --------------------

Main80
;DIRECT mode wedge
	bit autofast		;check AUTOFAST mode (bit 7)
	bpl +
	jsr SLOW		;set SLOW mode

+	ldx #$ff		;set DIRECT mode line number
	stx CURLIN+1		;current BASIC line number (hi-byte)

;Get input line
-	jsr INLIN		;get a line into input buffer
	stx TXTPTR		;set text pointer one char before input buffer ($01ff)
	sty TXTPTR+1

;Check input buffer
	jsr CHRGET		;get first char
	tax			;(required to detect end of line)
	beq -			;empty line (get another)
	bcs +			;not a digit (0-9)
	jmp MAIN1		;enter a BASIC program line (then return to the MAIN loop)

;Execute statement
+	jsr CRUNCH		;tokenize input line
	lda #<BUF-1		;restore text pointer one char before input buffer ($01ff)
	sta TXTPTR
	dec TXTPTR+1		;(then fall through to GONE wedge)

Main80_size = * - Main80

; --------------------
; - GONE wedge
; --------------------

Gone80
;Program mode wedge
	bit autofast		;check AUTOFAST mode (bit 7)
	bpl +
	jsr SLOW		;set SLOW mode

+	lda TXTPTR		;preserve text pointer
	sta backptr
	lda TXTPTR+1
	sta backptr+1

;Get next statement
	jsr CHRGET		;get next char (then y = 0)
	beq +
	cmp #IF_tk		;check IF token
	beq IF_stt
	jsr ParseTok		;parse token

;Return from statement
+	jmp NEWSTT		;set up next statement

ParseTok
;Parse single token
-	cmp cmd_tk_tbl,y	;single token table
	beq ExeCmd		;token found
	iny
	cpy #cmd_tk_count
	bne -

;Parse dual token
	cmp #CMD_dtk		;command prefix
	bne StdBasic
	jsr CHRGET		;get next char

	ldy #cmd_tk_count	;start of dual token table
-	cmp cmd_tk_tbl,y
	beq ExeCmd		;token found
	iny
	cpy #cmd_dual_count
	bne -

StdBasic
;Execute with standard BASIC
	pla			;drop return address (to ParseTok)
	pla

	lda backptr		;restore text pointer (backtracking)
	sta TXTPTR
	lda backptr+1
	sta TXTPTR+1
	jmp NGONE		;continue with standard GONE routine

ExeCmd
;Execute command (overloading)
	lda cmd_addr_hi,y	;get command address (-1)
	pha
	lda cmd_addr_lo,y
	pha

	bit autofast		;check AUTOFAST mode (bit 7)
	bpl +
	jsr FAST		;set FAST mode

+	jmp CHRGET		;get next char (then execute the command whose address is on the stack)

Gone80_size = * - Gone80

;After executing a command the following cases may occur:
;
;a)	The command completed successfully, so it returns
;	to the address following 'jsr ParseTok' to execute
;	the next statement.
;
;b)	The command cannot be handled by Wedge80, so it
;	continues to the 'StdBasic' label, where TXTPTR is
;	restored and control is returned to the standard
;	BASIC interpreter.
;
;c)	An error occurred, and after displaying the
;	corresponding error message, the system returns
;	to the MAIN loop in DIRECT mode.

; --------------------
; - IF patch
; --------------------

IF_stt
;IF statement patch
;
;The original IF statement executes a clause starting from the current text pointer,
;through the XEQCM3 routine, so only standard commands could be executed.
;
;This patched version keeps the pointer to the character before the clause to be executed,
;allowing extended commands to be executed via the Gone80 routine.
;
;Syntax:
;	IF expression	{GOTO line# | THEN {line# | statement(s) | b-block}}
;			[:ELSE {line# | statement(s) | b-block}]
;
;	b-block = BEGIN [statement(s) on one or more lines]:BEND

	jsr CHRGET		;get next char
	ldx #<FRMEVL		;evaluate the conditional expression (result -> FACEXP)
	ldy #>FRMEVL		;(could return with RAM#1 enabled, so JSRFAR is required)
	jsr JsrFar_BNK15	;call subroutine

	jsr CHRGOT		;get last char
	cmp #GOTO_tk		;check GOTO token
	beq +
	cmp #THEN_tk		;check THEN token
	bne if_error		;'SYNTAX ERROR'

+	ldx FACEXP		;check result
	bne ++			;is true

;False condition
	jsr CHRGET		;get next char
	cmp #CMD_dtk		;check for a BEGIN/BEND block
	bne +
	iny
	jsr INDTXT		;get next char (keeping current text pointer)

	cmp #BEGIN_dtk		;check BEGIN token
	bne +
	jsr FNBEND		;skip block

+:-	jsr DATA		;skip current statement
	jsr CHRGOT		;get last char
	tax			;check end of line
	beq if_exit		;end of line (then exit)

	jsr CHRGET		;get next char
	cmp #ELSE_tk		;check ELSE token
	bne -			;(then execute ELSE clause)

;True condition
++	cmp #GOTO_tk		;check GOTO token
	bne +

	jsr CHRGET		;get next char
	bcc ++			;is a number

if_error
	ldx #SYNTAX_err		;'SYNTAX ERROR'
	jmp ERROR		;generate error message (then exit)

+	lda TXTPTR		;preserve text pointer
	sta backptr
	lda TXTPTR+1
	sta backptr+1

	jsr CHRGET		;get next char
	beq if_exec		;end of statement
	bcs +			;not a number
++	jsr GOTO		;jump to line number (a = first digit)

if_exit
	jmp NEWSTT		;set up next statement (then exit)

+	cmp #CMD_dtk		;check for a BEGIN/BEND block
	bne if_exec
	jsr CHRGET		;get next char
	cmp #BEGIN_dtk		;check BEGIN token
	beq +			;execute block

if_exec
	lda backptr		;restore text pointer
	sta TXTPTR
	lda backptr+1
	sta TXTPTR+1
+	jmp Gone80		;execute next statement

IF_size = * - IF_stt

; --------------------
; - EVAL wedge
; --------------------

Eval80
;Function evaluation wedge
	jsr CHRGET		;get next char (then y = 0)
	sty VALTYP		;set numeric type
	tax			;check accumulator
	bpl StdEval		;not a token (skip parsing)

;Parse single token
-	cmp fn_tk_tbl,y		;function token table
	beq EvalFn		;token found
	iny
	cpy #fn_tk_count
	bne -

;Parse dual token
	cmp #FN_dtk		;function prefix
	bne StdEval

	ldy #1
	jsr INDTXT		;get next char (keeping current text pointer)
	cmp #RWINDOW_dtk	;RWINDOW token
	beq +

StdEval
;Evaluate with standard BASIC
	jsr CHRGOT		;get last char (restore status register)
	jmp EVAL+10		;continue with standard EVAL routine (after CHRGET)

;Evaluate RWINDOW function
+	jsr CHRGET		;get next char
	ldy #fn_tk_count	;RWINDOW index

EvalFn
;Evaluate function (overloading)
	lda fn_addr_hi,y	;get function address (-1)
	pha
	lda fn_addr_lo,y
	pha

	jsr CHRGET		;get next char
	jsr PARCHK		;get argument in parentheses into FAC#1
	jmp CONINT		;convert into a one-byte argument in x register (FAC#1 -> x)
				;(then evaluate the function whose address is on the stack)

Eval80_size = * - Eval80

; --------------------
; - ESCAPE patch
; --------------------

Escape80
;ESC sequence handler patch
	cmp #'x'		;catch 'ESC X' sequence (swap 40/80 column display output device)
	bne +

	jsr SetTxt80		;activate VDC text mode
	lda #'x'		;restore 'ESC X' sequence

+	jmp ESCAPE		;continue with standard ESC sequence handler

Escape80_size = * - Escape80

; --------------------
; - NMI patch
; --------------------

NMI_patch
;BASIC warm start patch
	lda #0			;restore standard target screen
	sta targscn		;for graphics and CHAR command (bits 7:6)

	jsr SetEscVec		;restore custom ESC vector
	lda vdcram		;check detected VDC RAM
	bne +			;64k bytes

;Init VDC screen (16k bytes)
	jsr INIT80		;restore VDC character set
	jmp WARMST		;BASIC warm start

;Init VDC screen (64k bytes)
+	ldx #vdc_CB		;[R28] CHARACTER BASE ADDRESS
	jsr ReadReg		;read register
	ora #$10		;enable 64k address mode (bit 4)
	jsr WrtReg		;update register

	jsr CLEAR80		;clear 80-column text screen
	jmp WARMST		;BASIC warm start

; --------------------
; - Low-level VDC
; --------------------

Write80
;Write one byte to VDC chip memory (a = value)
;(Note: I/O Registers must be enabled)

	ldx #vdc_DATA		;[R31] DATA (then continue)

WrtReg
;Write one byte to a VDC chip register (a = value, x = register)
	stx VDCADR		;transmit register
-	bit VDCADR		;test status
	bpl -			;not done yet, wait
	sta VDCDAT		;store value in register
	rts

Read80
;Read one byte from VDC chip memory (value -> a)
;(Note: I/O Registers must be enabled)

	ldx #vdc_DATA		;[R31] DATA (then continue)

ReadReg
;Read one byte from a VDC chip register (x = register, value -> a)
	stx VDCADR		;transmit register
-	bit VDCADR		;test status
	bpl -			;not done yet, wait
	lda VDCDAT		;get value of the register
	rts

SetMem80
;Set VDC bitmap address
;(Note: I/O Registers must be enabled)

	ldx #vdc_UAH		;[R18] UPDATE ADDRESS HI
	lda GRAPNT+1
	jsr WrtReg		;update register

	inx			;[R19] UPDATE ADDRESS LO
	lda GRAPNT
	jmp WrtReg		;update register (then return)

GetMode80
;Get VDC screen mode (VDC R25 bit 7 -> a)
	lda MMUCR		;enable I/O Registers
	and #$fe		;(clear bit 0)
	sta MMUCR

	ldx #vdc_HSS		;[R25] HORIZONTAL SMOOTH SCROLL
	jsr ReadReg		;read register
	and #$80		;mask bitmap mode (bit 7)
-	rts

SetTxt80
;Activate VDC text mode
	jsr GetMode80		;check VDC screen mode (bit 7)
	bpl -			;already in text mode (then return)

	ldx #<SetTxt80_ext-1
	ldy #>SetTxt80_ext-1
	jsr JsrFar_HIRAM	;execute in HIGH memory

	lda vdcram		;check detected VDC RAM
	bne -			;64k bytes (then return)

;Init text screen (16k bytes)
	jsr CLEAR80		;clear 80-column text screen
	jmp INIT80		;restore VDC character set (then return)

SetBmp80
;Activate VDC bitmap mode
	ldx #<SetBmp80_ext-1
	ldy #>SetBmp80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

ClrBmp80
;Clear VDC bitmap screen and reset coords
	ldx #<ClrBmp80_ext-1
	ldy #>ClrBmp80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

GetCol80
;Get VDC mono color (FOREGND/BACKGND -> a)
	lda MMUCR		;enable I/O Registers
	and #$fe		;(clear bit 0)
	sta MMUCR

	ldx #vdc_COLOR		;[R26] FOREGND/BACKGND COLOR
	jmp ReadReg		;get color (then return)

GetBgCol80
;Get VDC mono background and border color (RGBI -> a)
	jsr GetCol80		;get VDC mono color
	and #$0f		;clear hi-nibble
	rts

SetBgCol80
;Set VDC mono background and border color (a -> RGBI)
	and #$0f		;clear hi-nibble
	sta tmp			;background

	jsr GetCol80		;get VDC mono color
	and #$f0		;clear lo-nibble
	ora tmp			;merge nibbles
	jmp WrtReg		;set color (then return)

GetFgCol80
;Get VDC mono foreground color (RGBI -> a)
	jsr GetCol80		;get VDC mono color
	lsr			;shift to lo-nibble
	lsr
	lsr
	lsr
	rts

SetFgCol80
;Set VDC mono foreground color (a -> RGBI)
	asl			;shift to hi-nibble
	asl
	asl
	asl
	sta tmp			;foreground

	jsr GetBgCol80		;get background (lo-nibble)
	ora tmp			;merge nibbles
	jmp WrtReg		;set color (then return)

; --------------------
; - Mid-level VDC
; --------------------

GPlot80r
;Draw a pixel at current coords (enabling I/O Registers)

	lda MMUCR		;enable I/O Registers
	and #$fe		;(clear bit 0)
	sta MMUCR		;(then continue)

GPlot80
;Draw a pixel at current coords (considering WIDTH and FILFLG)

	lda FILFLG		;box fill flag
	ora WIDTH		;width mode
	beq GPlot80a		;single width

	inc XPOS		;move one pixel to the right
	bne +
	inc XPOS+1
+	jsr GPlot80a		;double width

	lda XPOS		;restore original position
	bne +
	dec XPOS+1
+	dec XPOS		;(then continue)

GPlot80a
;Draw a pixel at current coords (plotmode, XPOS, YPOS)

	jsr GetPos80		;get bitmap address
	bcs +++			;out of range (then return with carry set)

;Update cell
	jsr SetMem80		;set address
	jsr Read80		;read cell

	bit plotmode		;check XOR mode
	bvs +
	ora MSKTBL,y		;set pixel

	bit plotmode		;check clear mode (OR then XOR)
	bpl ++
+	eor MSKTBL,y		;XOR pixel

++	tay
	jsr SetMem80		;restore address
	tya
	jsr Write80		;write cell

	ldy modec		;check color mode
	beq +++
	jmp DoColr80		;apply color (then return)

ReadPt80
;Test a pixel at current coords (plotmode, XPOS, YPOS)
;(Note: I/O Registers must be enabled)
;
;results:
;	zero set   =	pixel is on and plotmode is set
;			pixel is off and plotmode is clear
;
;	zero clear =	pixel is on and plotmode is clear
;			pixel is off and plotmode is set

	jsr GetPos80		;get bitmap address
	bcs +++			;out of range (then return with carry set)

;Read cell
	jsr SetMem80		;set address
	jsr Read80		;read cell

	bit plotmode		;plot mode
	bmi +			;clear
	eor #$ff		;set (flip bits)
+	and MSKTBL,y		;test pixel (then return with carry clear)
+++	rts

GetPos80
;Get VDC bitmap address of current coords (XPOS, YPOS)
;
;results:
;	GRAPNT -> bitmap address
;	y = bit position (0..7)

	jsr DivPos80		;check range
	bcs +			;out of range (then return with carry set)

	lda YPOS		;y-coord (lo-byte)
	ldx vdcram		;detected VDC RAM
	ldy bmp_page,x		;bitmap start page
	jsr YComp		;add vertical component
	jsr XComp		;add horizontal component

;Bit position
	lda XPOS		;lo-byte
	and #$07		;mask position (bits 2:0)
	tay
	clc			;(then return with carry clear)
+	rts

DoColr80
;Apply color to cell
;
;args:	y = color mode
;	plotmode = plot mode
;	attrsrc = attribute source

	jsr GetAttPos		;get attribute address
	jsr SetMem80		;set address

	lda attrsrc		;attribute source
	bit plotmode		;check plot mode
	bpl +

;Update background only (clear mode)
	and #$f0		;mask background (hi-nibble)
	sta tmp

	jsr Read80		;read attribute
	and #$0f		;mask foreground (lo-nibble)
	ora tmp			;merge nibbles

	tay
	jsr SetMem80		;restore address
	tya
+	jmp Write80		;write attribute (then return)

GetAtt80
;Get cell attribute at current coords (XPOS, YPOS)
;
;args:	y = color mode
;
;results:
;	a = attribute (background/foreground)

	jsr DivPos80		;check range (y = preserved)
	bcs +			;out of range (then return with carry set)

	jsr GetAttPos		;get attribute address
	jsr SetMem80		;set address
	jsr Read80		;read attribute
	clc			;(then return with carry clear)
+	rts

GetAttPos
;Get attribute address
;
;args:	y = color mode
;
;results:
;	GRAPNT -> attribute address

	lda YPOS		;get y-coord (lo-byte)
-	lsr			;divide by 2
	iny
	cpy #4			;max value (+1)
	bne -

	ldx vdcram		;detected VDC RAM
	ldy att_page,x		;attribute start page
	jsr YComp		;add vertical component (then continue)

XComp
;Add horizontal component to start address
;
;args:	XPOS = x-coord
;
;used:	tmp
;
;results:
;	GRAPNT -> cell address

	lda XPOS+1		;hi-byte
	sta tmp
	lda XPOS		;lo-byte

	lsr tmp			;divide by 8
	ror
	lsr tmp			;(then zero, XPOS < 840)
	ror
	lsr			;(then continue)

UpdAddr80
;Update cell address
	clc
	adc GRAPNT		;lo-byte
	sta GRAPNT
	bcc +
	inc GRAPNT+1		;hi-byte
+	rts

YComp
;Add vertical component to start address
;
;args:	a = y-coord (lo-byte)
;	y = start page
;	modex = horizontal mode
;
;used:	tmp, tmp2
;
;results:
;	GRAPNT -> cell address

	sty GRAPNT+1		;save page

	ldx #0			;clear
	stx GRAPNT		;lo-byte
	stx tmp			;hi-byte

	ldx modex		;horizontal mode
	ldy txt_cols,x		;chars per row
	sty tmp2		;set multiplier

;Multiply y-coord by chars per row
	lsr tmp2		;shift multiplier (bit 0)
	bcc +
	sta GRAPNT		;save factor (lo-byte)

+	ldy #6			;(chars per row < 128)
-	asl			;multiply by 2
	rol tmp

	lsr tmp2		;shift multiplier (bits 1..6)
	bcc +

	tax			;preserve lo-byte
	clc
	adc GRAPNT		;add factor
	sta GRAPNT
	lda tmp
	adc GRAPNT+1
	sta GRAPNT+1
	txa			;restore lo-byte

+	dey
	bne -
	rts

DivPos80
;Check the range of current coords (XPOS, YPOS)
;and set the carry if they are out of range

	ldx modex		;horizontal mode
	lda XPOS+1		;hi-byte
	cmp resx_hi,x
	bcc +
	bne ++
	lda XPOS		;lo-byte
	cmp resx_lo,x
	bcs ++

+	ldx modey		;vertical mode
	lda YPOS+1		;hi-byte
	cmp resy_hi,x
	bcc ++
	bne ++
	lda YPOS		;lo-byte
	cmp resy_lo,x
++	rts

; --------------------
; - High-level VDC
; --------------------

GrpCol80
;Check if VDC is the current graphics target screen
;(then get optional plot mode)
	bit targscn		;check graphics target screen (bit 7)
	bpl ++			;not VDC (else continue)

InColr80
;Get optional plot mode
	lda #3			;set range (0..2)

InColr80a
;(PAINT and CHAR entry point)
	sta tmp			;set max value (+1)

	ldx #1			;default plot mode
	jsr CHRGOT		;get last char
	beq +			;no value
	cmp #','		;comma
	beq +

	jsr GETBYT		;get plot mode
	cpx tmp			;check max value (+1)
	bcc +
	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

+	lda plot_tbl,x		;get flag bits
	sta plotmode		;set plot mode
-	rts

ChkGrp80
;Check if VDC is the current graphics target screen
;(else execute with standard BASIC)
	bit targscn		;check graphics target screen (bit 7)
	bmi -			;VDC bitmap (then return)

++	pla			;drop return address (to the caller of this subroutine)
	pla
	jmp StdBasic		;execute with standard BASIC

DrawLn80
;Draw a line (plotmode, XPOS, YPOS, XDEST, YDEST)
	ldx #<DrawLn80_ext-1
	ldy #>DrawLn80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - BASIC commands
; --------------------

; --------------------
; - GRAPHIC command
; --------------------

GRAPHIC_cmd
;Selects the screen mode and changes
;the current graphics screen.
;
;Command syntax:
;
;	GRAPHIC mode[,clear][,h/res][,v/res][,color]
;
;mode	= 0	VIC-II 40-column text
;	  1	VIC-II bitmap (320 x 200)
;	  2	VIC-II split screen bitmap
;	  3	VIC-II multicolor bitmap (160 x 200)
;	  4	VIC-II split screen multicolor bitmap
;	  5	VDC 80-column text
;	  6	VDC bitmap (*)
;
;clear	= 0	do not clear screen (default)
;	  1	clear screen
;
;h/res	=	screen width (horizontal resolution) (*)
;			0 = 320 pixels		1 = 360 pixels
;			2 = 640  "		3 = 720  "
;			4 = 800  "		5 = 840  "
;
;v/res	=	screen height (vertical resolution) (*)
;			0 = 128 pixels		1 = 144 pixels
;			2 = 176  "		3 = 200  "
;			4 = 240  "		5 = 256  "
;
;color	=	color mode (attribute memory) (*)
;			0 = monochrome		1 = 8x8 cell size
;			2 = 8x4 cell size	3 = 8x2  "
;
;Alternate syntax:
;
;	GRAPHIC cmd
;
;cmd =	CLR	deallocates the VIC-II bitmap screen
;
;	OFF	switches the VDC display to 80-column
;		text mode, without changing the current
;		screen (*)
;
;	(*) new options
;
;Note:	With 16k of VDC RAM, when switching from bitmap
;	mode to text mode ,screen is always cleared.

;Check CLR option
	jsr CHRGOT		;get last char
	cmp #CLR_tk		;check CLR token (deallocate VIC-II bitmap screen memory)
	beq gp_std		;execute with standard BASIC

;Check OFF option
	cmp #CMD_dtk		;check for dual token command prefix
	bne +

	jsr CHRGET		;get next char
	cmp #OFF_dtk		;check OFF token (deactivate VDC bitmap mode)
	bne gp_std		;execute with standard BASIC (SYNTAX ERROR)

	jsr SetTxt80		;activate VDC text mode (keeping current screen mode)
	jmp CHRGET		;get next char (then return)

;Select graphics mode
+	jsr GETBYT		;get graphics mode
	txa			;check zero (VIC-II 40-column text)
	bne +

	lda targscn		;restore standard CHAR command (bit 6)
	and #$80		;keep current graphics target screen (bit 7)
	sta targscn
	jmp StdBasic		;execute with standard BASIC

+	cpx #7			;check max value (+1)
	bcc +
gp_iq	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

+	cpx #6			;VDC bitmap mode
	beq +

	lda #0			;restore standard target screen
	sta targscn		;for graphics and CHAR command (bits 7:6)

	cpx #5			;VDC 80-column text mode
	bcc gp_std		;execute with standard BASIC (mode = 1..4)

	jsr SetTxt80		;activate VDC text mode (then swap to 80-column text mode)
gp_std	jmp StdBasic		;execute with standard BASIC

;VDC bitmap mode
+	jsr OPTZER		;get optional clear flag (default = 0)
	cpx #2			;check max value (+1)
	bcs gp_iq		;'ILLEGAL QUANTITY'

	txa
	pha			;push clear flag

	ldx modex		;current horizontal mode
	jsr OPTBYT		;get optional value
	cpx #modex_count	;check max value (+1)
	bcs gp_iq		;'ILLEGAL QUANTITY'
	txa
	pha			;push horizontal mode

	ldx modey		;current vertical mode
	jsr OPTBYT		;get optional value
	cpx #modey_count	;check max value (+1)
	bcs gp_iq		;'ILLEGAL QUANTITY'
	txa
	pha			;push vertical mode

	ldx modec		;current color mode
	jsr OPTBYT		;get optional value
	cpx #modec_count	;check max value (+1)
	bcs gp_iq		;'ILLEGAL QUANTITY'
	stx modec		;set color mode

	pla
	sta modey		;set vertical mode

	pla
	sta modex		;set horizontal mode

	jsr SetBmp80		;activate VDC bitmap mode
	lda #0
	sta SCALEM		;clear scale mode flag

;Swap to 40-column mode
	bit MODE		;check current screen mode
	bpl +			;already in 40-column mode
	jsr SWAPPER		;swap to 40-column mode

+	pla			;check clear flag
	beq +

	jsr ClrBmp80		;clear VDC bitmap screen and reset coords
+	rts

GRAPHIC_size = * - GRAPHIC_cmd

; --------------------
; - COLOR command
; --------------------

COLOR_cmd
;Sets a color for the selected source.
;
;Command syntax:
;
;	COLOR source,value
;
;source	= 0	VIC-II text/bitmap background color
;	  1	VIC-II bitmap foreground color
;	  2	VIC-II multicolor 1
;	  3	VIC-II multicolor 2
;	  4	VIC-II border color
;	  5	VIC-II/VDC text color (40/80 column)
;	  6	VDC text/bitmap mono background and border color
;	  7	VDC bitmap mono foreground color (*)
;	  8	VDC bitmap attribute background color (*)
;	  9	VDC bitmap attribute foreground color (*)
;
;value	=	the code of the color to be used (1..16)
;
;	(*) new options

	jsr GETBYT		;get source value
	cpx #7			;standard max value (+1)
	bcc gp_std		;execute with standard BASIC
	stx A_REG		;save it

	jsr COMBYT		;get color code
	stx X_REG		;save it

;Set VDC screen color
	ldx #<Color80_ext-1
	ldy #>Color80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

COLOR_size = * - COLOR_cmd

; --------------------
; - SCNCLR command
; --------------------

SCNCLR_cmd
;Clears the selected screen mode, without changing
;the current graphics screen.
;
;Command syntax:
;
;	SCNCLR [mode]
;
;mode	= 0	VIC-II 40-column text
;	  1	VIC-II bitmap (320 x 200)
;	  2	VIC-II split screen bitmap
;	  3	VIC-II multicolor bitmap (160 x 200)
;	  4	VIC-II split screen multicolor bitmap
;	  5	VDC 80-column text
;	  6	VDC bitmap (*)
;
;	(*) new option
;
;Note:	Without arguments, both the current text screen and
;	the current active graphics screen will be cleared.

	jsr CHRGOT		;get last char
	bne ++			;check argument

;No arguments -> clear current active text/bitmap screens
	jsr GetMode80		;check VDC screen mode (bit 7)
	bpl +			;text mode

	jsr ClrBmp80		;clear VDC bitmap screen and reset coords
+	jmp StdBasic		;execute with standard BASIC

;Select screen mode
++	jsr GETBYT		;get screen mode
	cpx #6			;VDC bitmap mode
	beq ++
	cpx #5			;VDC text mode
	bne +			;execute with standard BASIC

;VDC text mode
	jsr SetTxt80		;activate VDC text mode
+	jmp StdBasic		;execute with standard BASIC

;VDC bitmap mode
++	jsr GetMode80		;check VDC screen mode (bit 7)
	bpl +			;text mode
	jmp ClrBmp80		;clear VDC bitmap screen and reset coords (then return)

+	ldx #NOGFX_err		;'NO GRAPHICS AREA'
	jmp ERROR		;generate error message (then exit)

SCNCLR_size = * - SCNCLR_cmd

; --------------------
; - DRAW command
; --------------------

DRAW_cmd
;Draws dots, lines, and shapes at the positions
;specified by the coordinates.
;
;Command syntax:
;
;	DRAW [mode][,x0,y0][<TO|,> xn,yn][...]
;
;mode	= 0	clear pixel
;	  1	set pixel (default)
;	  2	XOR with foreground
;
;x0,y0	=	starting coordinates
;		(default = current coords)
;
;xn,yn	=	next coordinates, preceded by:
;		- keyword 'TO'	= end of line
;		- a comma ','	= next point
;
;Note:	Without parameters, a point is drawn
;	at the current coordinates.

	jsr ChkGrp80		;check if VDC is the current graphics target screen
	lda #0			;set default plot mode (set pixel)
	sta plotmode

	jsr CHRGOT		;get last char
	cmp #TO_tk		;check TO token
	beq DrawNext

	jsr InColr80		;get optional plot mode (0..2)
	jsr CHRGOT		;get next char
	bne DrawNext		;more parameters

	jmp GPlot80r		;draw a pixel at current coords (enabling I/O Registers) (then exit)

DrawNext
	jsr CHRGOT		;get last char
	cmp #','		;comma
	beq DrawGet		;get starting coordinates

	cmp #TO_tk		;check TO token
	beq DrawGet		;get ending coordinates
	rts			;done

DrawGet
	pha			;preserve char
	jsr CHRGET		;get next char
	ldx #XDEST-VWORK	;offset to dest coords ($04)
	jsr INCORD		;get non-optional coords
	pla			;restore char
	bpl DrawDot		;draw a pixel
	jsr DrawLn80		;draw a line
	jmp DrawNext		;check next char

DrawDot
	jsr DSTPOS		;copy dest coords to current
	jsr GPlot80r		;draw a pixel (enabling I/O Registers)
	jmp DrawNext		;next parameters

DRAW_size = * - DRAW_cmd

; --------------------
; - BOX command
; --------------------

;Draws a BOX on the screen as specified by the parameters
;that follow the command.
;
;Command syntax:
;
;	BOX [mode],x0,y0[,x1,y1][,rot][,fill]
;
;mode	= 0	clear pixels
;	  1	set pixels (default)
;	  2	XOR with foreground
;
;x0,y0	=	the top left corner coordinates
;
;x1,y1	=	the opposite corner
;		(default = current position)
;
;rot	=	the rotation in clockwise degrees
;		(default = 0)
;
;fill	= 0	do not fill the shape (default)
;	  1	fill the shape
;
;Note:	The fill option does not work in XOR mode.

; --------------------
; - CIRCLE command
; --------------------

;Draws circles, ellipses or arcs depending on the parameters
;specified after the command.
;
;Command syntax:
;
;	CIRCLE [mode][,xc,yc][,xr][,yr][,sa][,ea][,rot][,inc]
;
;mode	= 0	clear pixels
;	  1	set pixels (default)
;	  2	XOR with foreground
;
;xc,yc	=	center of the circle (default = current position)
;xr	=	horizontal radius (default = 0)
;yr	=	vertical radius (default = xr) (*)
;sa	=	starting arc angle (default = 0)
;ea	=	ending arc angle (default = 360)
;rot	=	rotation angle in degrees (default = 0)
;inc	=	degrees between each segment (default = 2) (**)
;
;   (*)	Due to the aspect ratio of the VDC screen, to get a proper
;	circle it is recommended to specify: yr = int(xr/2)
;
;  (**)	By varying the number of degrees between each segment, a
;	polygon can be drawn, where: inc = int(360/number of sides)
;	To draw a regular polygon, use the following values:
;
;	       120 = equilateral triangle
;		90 = square
;		72 = pentagon
;		60 = hexagon
;		45 = octagon
;		44 = nonagon
;		36 = decagon
;		30 = dodecagon (etc...)

; --------------------
; - PAINT command
; --------------------

PAINT_cmd
;Fills an area starting from a specified position.
;
;Command syntax:
;
;	PAINT [mode][,x,y][,stop]
;
;mode	= 0	clear a filled area
;	  1	fill an empty area (default)
;
;x,y	=	the starting coordinates
;		(default = current coords)
;
;stop	= 0	fill an area that is defined by
;		the color source specified (default) (*)
;	  1	fill an area that is defined by any
;		non-background source (*)
;
;	(*) not available in VDC mode
;
;Note:	The RUN/STOP key breaks the operation at any time.

	jsr ChkGrp80		;check if VDC is the current graphics target screen
	lda #2			;set range (0..1)
	jsr InColr80a		;get optional plot mode

	ldx #XDEST-VWORK	;offset to dest coords ($04)
	jsr INCOR2		;get optional coords preceded by a comma (default = current)
	jsr DSTPOS		;copy dest coords to current
	jsr OPTBYT		;skip 'stop flag' option

Paint80
;Fill a graphics area (plotmode, XPOS, YPOS)
	ldx #<Paint80p-1
	ldy #>Paint80p-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - CHAR command
; --------------------

CHAR_cmd
;Displays a string of characters to the current screen
;(bitmap or text) at the position specified.
;
;Command syntax:
;
;	CHAR [mode],col,row[,string][,rev]
;
;mode	= 0	clear using char shape (*)
;	  1	draw solid char (default)
;	  2	XOR with foreground (*)
;	  3	OR with foreground (*)
;
;col	=	column to start printing at
;row	=	row to start printing at
;string	=	string of characters to be printed
;
;rev	= 0	normal mode (default)
;	  1	reverse mode
;
;	(*) new options

	bit targscn		;check CHAR target screen (bit 6)
	bvs +			;VDC bitmap
	jmp StdBasic		;execute with standard BASIC

+	lda #4			;set range (0..3)
	jsr InColr80a		;get optional plot mode

	jsr COMBYT		;get start column
	txa
	ldx modex		;horizontal mode
	cmp txt_cols,x		;screen columns
	bcs ++			;'ILLEGAL QUANTITY'
	sta COLCNT		;save start column

	jsr COMBYT		;get start row
	txa
	ldx modey		;vertical mode
	cmp txt_rows,x		;screen rows
	bcs ++			;'ILLEGAL QUANTITY'
	sta ROWCNT		;save start row

	jsr CHRGOT		;get last char
	bne +
	rts			;nothing to print (exit)

+	jsr CHKCOM		;check for a comma (if not found, exit with SYNTAX error)

	ldx #<FRESTR		;get string parameter (length -> a, address -> x/y and INDEX1)
	ldy #>FRESTR		;(always returns with RAM#1 enabled, JSRFAR required)
	jsr JsrFar_BNK15	;call subroutine

	jsr OPTZER		;get optional reverse flag (default = 0)
	stx CHRREV		;save reverse flag
	cpx #2			;check max value (+1)
	bcc +
++	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)


Char80
;Print a BASIC string to VDC bitmap screen
;
;args:	a = string length
;	x/y -> string pointer
;	COLCNT = start column
;	ROWCNT = start row
;	CHRREV = reverse flag
;	CHRLO = lowercase charset page
;	CHRUP = uppercase charset page

	sta A_REG		;string length
	stx X_REG		;string address
	sty Y_REG

+	ldx #<Char80_ext-1
	ldy #>Char80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

CHAR_size = * - CHAR_cmd

; --------------------
; - GSHAPE command
; --------------------

GSHAPE_cmd
;Draws a shape stored in a BASIC string variable.
;
;Command syntax:
;
;	GSHAPE string[,x,y][,mode]
;
;string	=	string variable, where the
;		shape to be drawn is stored
;
;x,y	=	top/left corner coordinates,
;		where the shape is to be drawn
;		(default = current coords)
;
;mode	= 0	draw the shape as is (default)
;	  1	invert the shape
;	  2	OR the shape with foreground
;	  3	AND the shape with foreground
;	  4	XOR the shape with foreground

	jsr ChkGrp80		;check if VDC is the current graphics target screen

	ldx #<FRESTR		;get string parameter (length -> a, address -> x/y and INDEX1)
	ldy #>FRESTR		;(always returns with RAM#1 enabled, JSRFAR required)
	jsr JsrFar_BNK15	;call subroutine

	ldx #XDEST-VWORK	;offset to dest coords ($04)
	jsr INCOR2		;get optional coords preceded by a comma (default = current)

	jsr OPTZER		;get 'mode' option (default = 0)
	stx GETTYP		;save replace mode
	cpx #5			;check max value (+1)
	bcc GShape80
	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

GShape80
;Draw a shape
;
;args:	A_REG = string length
;	X_REG/Y_REG -> string pointer
;	GETTYP = replace mode
;	XDEST, YDEST = dest coords

	ldx #<GShape80_ext-1
	ldy #>GShape80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

GSHAPE_size = * - GSHAPE_cmd

; --------------------
; - SSHAPE command
; --------------------

SSHAPE_cmd
;Saves an area of the the screen
;into a BASIC string variable.
;
;Command syntax:
;
;	SSHAPE string,x0,y0[,x1,y1]
;
;string	=	the string variable to which you
;		wish to save the area of screen
;		(max 251 bytes = 2008 pixels)
;		the remaining 4 bytes are used
;		for the shape size (x,y)
;
;x0,y0	=	the starting corner
;		coordinates for the save
;
;x1,y1	=	the opposite corner
;		(default = current coords)

	jsr ChkGrp80		;check if VDC is the current graphics target screen

	ldx #<PTRGET		;find or create a variable (type -> VALTYP, descriptor -> a/y and VARPNT)
	ldy #>PTRGET		;(always returns with RAM#1 enabled, so a JSRFAR is required)
	jsr JsrFar_BNK15	;call subroutine

	bit VALTYP		;check for string type (bit 7)
	bmi +
	jmp TMERR		;generate a 'TYPE MISMATCH' error (then exit)

+	ldx #XDEST-VWORK	;offset to dest coords ($04)
	jsr INCOR3		;get non-optional coords preceded by a comma

	ldx #XABS-VWORK		;offset to opposite coords ($08)
	jsr INCOR2		;get optional coords preceded by a comma (default = current)

SShape80
;Save a shape
;
;args:	A_REG/Y_REG -> string descriptor
;	XDEST, YDEST = dest coords
;	XABS, YABS = opposite coords

	ldx #<SShape80_ext-1
	ldy #>SShape80_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

SSHAPE_size = * - SSHAPE_cmd

; --------------------
; - LOCATE command
; --------------------

LOCATE_cmd
;Places the pixel cursor to a specified
;position on the bitmap screen.
;
;Command syntax:
;
;	LOCATE x,y
;
;x,y	=	the position to move the
;		bitmap pixel cursor to

	jsr ChkGrp80		;check if VDC is the current graphics target screen
	jmp LOCATE+3		;continue with standard LOCATE command (after CHKGRP)

; --------------------
; - AUTO command
; --------------------

AUTO_cmd
;Followed by the FAST keyword, it enables the AUTOFAST mode,
;otherwise it operates as the standard AUTO command.
;
;Command syntax:
;
;	AUTO FAST
;
;Note:	The space between keywords can be omitted.

	cmp #CMD_dtk		;check for dual token command prefix
	bne +			;execute with standard BASIC

	jsr CHRGET		;get next char
	cmp #FAST_dtk		;check FAST token
	bne +			;execute with standard BASIC

	jsr AutoFast_on		;enable AUTOFAST
	jmp CHRGET		;get next char (then return)

; --------------------
; - FAST command
; --------------------

FAST_cmd
;Disables the AUTOFAST mode, then
;sets the clock speed to 2 MHz.
;
;Command syntax:
;
;	FAST

; --------------------
; - SLOW command
; --------------------

SLOW_cmd
;Disables the AUTOFAST mode, then
;sets the clock speed to 1 MHz.
;
;Command syntax:
;
;	SLOW

	jsr AutoFast_off	;disable AUTOFAST
+:-	jmp StdBasic		;execute with standard BASIC

; --------------------
; - HELP command
; --------------------

HELP_cmd
;Displays system info or the content of the Online Guide,
;then operates as the standard HELP command.
;
;Command syntax:
;
;	HELP (no args)	display system info:
;			- about Wedge80
;			- current VDC mode
;			- detected VDC RAM
;			- available memory
;			- AUTOFAST mode
;			- Online Guide availability (*)
;			- last program error (if any)
;
;	HELP +		view command/function list (*)
;	HELP keyword	view command/function details (*)
;
;	(*) not available in the 'light' version

	bit autofast		;check AUTOFAST mode (bit 7)
	bpl +
	jsr SLOW		;set SLOW mode

!if online_guide {
+	jsr CHRGOT		;get last char
	beq +

;Display HELP for a specified command/function
	sta A_REG		;save token
	ldx #<GetHelp-1
	ldy #>GetHelp-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)
}

+	jsr HelpMsg		;display HELP message

	ldx ERRLIN+1		;line number where the most recent error occurred (hi-byte)
	inx			;check value ($ff)
	bne -			;execute with standard BASIC
	rts			;(no errors, avoid double CR)

; --------------------
; - BASIC functions
; --------------------

; --------------------
; - RGR function
; --------------------

RGR_fn
;Returns the value of the current screen mode.
;
;Function syntax:
;
;	return = RGR(n)
;
;   n =	0	screen mode (standard BASIC)
;			0 = VIC-II 40-column text
;			1 = VIC-II standard bitmap
;			2 = VIC-II split screen bitmap
;			3 = VIC-II multicolor bitmap
;			4 = VIC-II split screen multicolor bitmap
;			5 = VDC 80-column text
;
;	1	scale mode (*)
;			0 = off		1 = on
;
;	2	pixel width (*)
;			1 = single	2 = double
;
;	3	VDC horizontal mode (*)
;	4	VDC vertical mode (*)
;	5	VDC color mode (*)
;
;	6	VDC screen mode (*)
;			0 = text	1 = bitmap
;
;	7	graphics target screen (the screen to which
;		the next graphics command will be applied) (*)
;			0 = VIC-II	1 = VDC
;
;	8	CHAR target screen (the screen to which
;		the next CHAR command will be applied) (*)
;			0 = standard	1 = VDC bitmap
;
;	9	VDC RAM size (16k/64k) (*)
;
;	(*) new options

	txa			;check zero
	bne +
	jmp RGR			;evaluate with standard RGR function

+	stx X_REG		;save argument
	ldx #<RGR_ext-1
	ldy #>RGR_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - RCLR function
; --------------------

RCLR_fn
;Returns the current color value (1..16)
;of the color source specified.
;
;Function syntax:
;
;	return = RCLR(n)
;
;   n =	0	VIC-II text/bitmap background color
;	1	VIC-II bitmap foreground color
;	2	VIC-II multicolor 1
;	3	VIC-II multicolor 2
;	4	VIC-II border color
;	5	VIC-II/VDC text color (40/80 column)
;	6	VDC text/bitmap mono background and border color
;	7	VDC bitmap mono foreground color (*)
;	8	VDC bitmap attribute background color (*)
;	9	VDC bitmap attribute foreground color (*)
;
;	(*) new options

	cpx #7			;check standard max value (+1)
	bcs +
	jmp RCLR+3		;evaluate with standard RCLR function (after CONINT)

+	stx X_REG		;save argument
	ldx #<RCLR_ext-1
	ldy #>RCLR_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - RDOT function
; --------------------

RDOT_fn
;Returns the current pixel cursor coordinates
;or the pixel status at current position
;depending on the value specified.
;
;Function syntax:
;
;	return = RDOT(n)
;
;   n =	0	x-coord of the pixel cursor
;	1	y-coord of the pixel cursor
;	2	VIC-II color source of the pixel
;		at current position (0..3)
;	3	VDC pixel status at current position (*)
;		(0 = off, 1 = on)
;	4	VDC background color of current cell (*)
;	5	VDC foreground color of current cell (*)
;
;	(*) new options

	cpx #3			;check standard max value (+1)
	bcs +
	jmp RDOT+3		;evaluate with standard RDOT function (after CONINT)

+	stx X_REG		;save argument
	ldx #<RDOT_ext-1
	ldy #>RDOT_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - RWINDOW function
; --------------------

RWINDOW_fn
;Returns dimension information about
;the current screen or window.
;
;Function syntax:
;
;	return = RWINDOW(n)
;
;   n =	0	current text window rows (-1)
;	1	current text window columns (-1)
;	2	current text screen mode (40/80)
;	3	VDC bitmap width (pixels) (*)
;	4	VDC bitmap height (pixels) (*)
;	5	VDC color cell size (pixels) (*)
;	6	VDC bitmap columns (chars) (*)
;	7	VDC bitmap rows (chars) (*)
;
;	(*) new options

	cpx #3			;check standard max value (+1)
	bcs +
	jmp RWINDOW+6		;evaluate with standard RDOT function (after CONINT)

+	stx X_REG		;save argument
	ldx #<RWINDOW_ext-1
	ldy #>RWINDOW_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

; --------------------
; - POS function
; --------------------

POS_fn
;Returns a value that indicates where the cursor is within
;the current text screen window (40/80 column).
;
;Function syntax:
;
;	return = POS(n)
;
;   n =	0	text cursor column
;	1	text cursor row (*)
;
;	(*) new option

	txa			;check argument (n = 0)
	bne +
	jmp POS			;evaluate with standard POS function

+	dex			;check argument (n = 1)
	beq +
	jmp IQERR		;generate an 'ILLEGAL QUANTITY' error (then exit)

+	sec			;set carry to
	jsr PLOT		;get cursor position
	txa			;cursor row
	tay
	jmp SNGFLT		;return value (y -> FAC#1)

; --------------------
; - Service routines
; --------------------

AutoFast_on
;Enable AUTOFAST
	lda #$80		;set flag (bit 7)
	!by BIT2_opc		;mask the next two bytes

AutoFast_off
;Disable AUTOFAST
	lda #0			;clear flag (bit 7)
	sta autofast

	bit RUNMOD		;check RUN mode
	bmi +			;(else continue in DIRECT mode)

;Display AUTOFAST mode
	ldx #<AutoFast_ext-1
	ldy #>AutoFast_ext-1
	jmp JsrFar_HIRAM	;execute in HIGH memory (then return)

HelpMsg
;Display HELP message
	ldx #<HelpMsg_ext-1
	ldy #>HelpMsg_ext-1	;(then continue)

JsrFar_HIRAM
;Call a subroutine in HIGH memory, then return to caller BANK
;
;args:	x/y = target address (-1)
;	A_REG, X_REG, Y_REG = input registers
;
;used:	a, MMUCR

	lda MMUCR		;save current BANK config
	pha

	lda #HIRAM		;enable HIGH memory
	sta MMUCR

	jsr JmpFar_HIRAM	;call subroutine

	pla			;restore BANK of the caller
	sta MMUCR
+	rts

JmpFar_HIRAM
;Push target address (-1) into stack, then jump to subroutine
	tya			;hi-byte
	pha
	txa			;lo-byte
	pha
	jmp LoadRegs		;load registers

JsrFar_BNK15
;Call a subroutine in BANK 15, then return to caller BANK
;and get results into registers
;
;args:	x/y = target address
;	A_REG, X_REG, Y_REG = input registers
;
;used:	MMUCR, BANK, PC_LO, PC_HI
;
;results:
;	a, x, y = output registers

	lda MMUCR		;save current BANK config
	pha

	lda #BANKT[15]		;enable BANK 15
	sta MMUCR

	lda #15			;set BANK 15 as target
	sta BANK
	stx PC_LO		;target address
	sty PC_HI
	jsr JSRFAR		;call subroutine (then return with BANK 15 enabled)

	pla			;restore BANK of the caller
	sta MMUCR

LoadRegs
	lda A_REG		;load registers
	ldx X_REG
	ldy Y_REG
	rts

IndFetch_RAM1
;Read a character from RAM#1, then return to caller BANK
;
;args:	x = preserved
;	y = offset (preserved)
;	INDEX1 -> base address
;
;used:	FETVEC, tmp
;
;results:
;	a = char

	stx tmp
	ldx #INDEX1		;set FETCH pointer
	stx FETVEC
	ldx #BANKT[1]		;set BANK 1 as target
	jsr FETCH		;load char
	ldx tmp
	rts

IndStash_RAM1
;Write a character to RAM#1, then return to caller BANK
;
;args:	a, x = preserved
;	y = offset (preserved)
;	INDEX1 -> base address
;
;used:	STAVEC, tmp

	stx tmp
	ldx #INDEX1		;set STASH pointer
	stx STAVEC
	ldx #BANKT[1]		;set BANK 1 as target
	jsr STASH		;save char
	ldx tmp
	rts

DefEscVec
;Set default ESC vector
	lda #<ESCAPE
	ldy #>ESCAPE
	bne +			;(forced)

SetEscVec
;Set custom ESC vector
	lda #<Escape80
	ldy #>Escape80

+	sta ESCVEC
	sty ESCVEC+1
	rts

; --------------------
; - Main tables
; --------------------

tables_start

;Plot mode flag bits
plot_tbl
	!by $80			;0 = clear pixel (bit 7)
	!by $00			;1 = set pixel (CHAR = solid) (default)
	!by $40			;2 = XOR with foreground (bit 6)
	!by $c0			;3 = OR with foreground (CHAR only) (bits 7:6)

;VDC default modes
def_mode_tbl
	!by def_modex_16,def_modey_16,def_modec_16	;VDC 16k defaults
	!by def_modex_64,def_modey_64,def_modec_64	;VDC 64k defaults
def_mode_64k = (* - def_mode_tbl)/2

; --------------------
; - BASIC tokens
; --------------------

;Single token keywords
cmd_tk_tbl	!by GRAPHIC_tk,COLOR_tk,SCNCLR_tk,DRAW_tk,BOX_tk
		!by CIRCLE_tk,PAINT_tk,CHAR_tk,GSHAPE_tk,SSHAPE_tk
		!by LOCATE_tk,AUTO_tk,HELP_tk
cmd_tk_count = * - cmd_tk_tbl

;Dual token keywords
		!by FAST_dtk,SLOW_dtk,QUIT_dtk
cmd_dual_count = * - cmd_tk_tbl

;Command addresses (lo-byte)
cmd_addr_lo	!by <GRAPHIC_cmd-1,<COLOR_cmd-1,<SCNCLR_cmd-1,<DRAW_cmd-1,<BOX_cmd-1
		!by <CIRCLE_cmd-1,<PAINT_cmd-1,<CHAR_cmd-1,<GSHAPE_cmd-1,<SSHAPE_cmd-1
		!by <LOCATE_cmd-1,<AUTO_cmd-1,<HELP_cmd-1

;Dual token commands
		!by <FAST_cmd-1,<SLOW_cmd-1,<QuitWedge-1

;Command addresses (hi-byte)
cmd_addr_hi	!by >GRAPHIC_cmd-1,>COLOR_cmd-1,>SCNCLR_cmd-1,>DRAW_cmd-1,>BOX_cmd-1
		!by >CIRCLE_cmd-1,>PAINT_cmd-1,>CHAR_cmd-1,>GSHAPE_cmd-1,>SSHAPE_cmd-1
		!by >LOCATE_cmd-1,>AUTO_cmd-1,>HELP_cmd-1

;Dual token commands
		!by >FAST_cmd-1,>SLOW_cmd-1,>QuitWedge-1

;Function tokens
fn_tk_tbl	!by RGR_tk,RCLR_tk,RDOT_tk,POS_tk
fn_tk_count = * - fn_tk_tbl

;Function addresses
fn_addr_lo	!by <RGR_fn-1,<RCLR_fn-1,<RDOT_fn-1,<POS_fn-1,<RWINDOW_fn-1
fn_addr_hi	!by >RGR_fn-1,>RCLR_fn-1,>RDOT_fn-1,>POS_fn-1,>RWINDOW_fn-1

; --------------------
; - VDC parameters
; --------------------

vdcregsx
;Horizontal registers
	!by vdc_HT		;[R00] HORIZONTAL TOTAL
	!by vdc_HD		;[R01] HORIZONTAL DISPLAYED
	!by vdc_HSP		;[R02] HORIZONTAL SYNC POSITION
	!by vdc_SW		;[R03] VERTICAL/HORIZONTAL SYNC WIDTH
	!by vdc_CTH		;[R22] CHARACTER TOTAL/DISPLAYED HORIZONTAL
	!by vdc_DEB		;[R34] DISPLAY ENABLE BEGIN
	!by vdc_DEE		;[R35] DISPLAY ENABLE END
vdcregsx_count = * - vdcregsx

vdcregsy
;Vertical registers
	!by vdc_VT		;[R04] VERTICAL TOTAL
	!by vdc_VD		;[R06] VERTICAL DISPLAYED
	!by vdc_VSP		;[R07] VERTICAL SYNC POSITION
	!by vdc_CTV		;[R09] CHARACTER TOTAL VERTICAL
vdcregsy_count = * - vdcregsy

;Horizontal parameters
vdc320h		!by 63,40,55,$44,$89,62,54
vdc360h		!by 63,45,57,$44,$89,62,56
vdc640h		!by 127,80,102,$49,$78,125,100		;standard 80-column text
vdc720h		!by 127,90,107,$49,$78,125,105
vdc800h		!by 127,100,112,$49,$78,125,110
vdc840h		!by 127,105,114,$49,$78,125,112

;Vertical parameters
vdc128c8	!by 38,16,27,7
vdc128c4	!by 77,32,53,3
vdc128c2	!by 155,64,105,1

vdc144c8	!by 38,18,28,7
vdc144c4	!by 77,36,55,3
vdc144c2	!by 155,72,109,1

vdc176c8	!by 38,22,30,7
vdc176c4	!by 77,44,59,3
vdc176c2	!by 155,88,117,1

vdc200c8	!by 38,25,32,7				;standard 80-column text
vdc200c4	!by 77,50,63,3
vdc200c2	!by 155,100,125,1

vdc240c8	!by 38,30,34,7
vdc240c4	!by 77,60,67,3
vdc240c2	!by 155,120,133,1

vdc256c8	!by 38,32,35,7
vdc256c4	!by 77,64,69,3
vdc256c2	!by 155,128,137,1

;Horizontal modes
vdcmodex_lo	!by <vdc320h,<vdc360h,<vdc640h,<vdc720h,<vdc800h,<vdc840h
vdcmodex_hi	!by >vdc320h,>vdc360h,>vdc640h,>vdc720h,>vdc800h,>vdc840h

;Vertical modes
vdcmodey_lo	!by <vdc128c8,<vdc144c8,<vdc176c8,<vdc200c8,<vdc240c8,<vdc256c8
vdcmodey_hi	!by >vdc128c8,>vdc144c8,>vdc176c8,>vdc200c8,>vdc240c8,>vdc256c8

;VDC bitmap resolution
resx_lo		!by <320,<360,<640,<720,<800,<840
resx_hi		!by >320,>360,>640,>720,>800,>840
resy_lo		!by <128,<144,<176,<200,<240,<256
resy_hi		!by >128,>144,>176,>200,>240,>256

;VDC color cell height
cell_ht		!by 0,8,4,2

;VDC text grid
txt_cols	!by 40,45,80,90,100,105
txt_rows	!by 16,18,22,25,30,32

;VDC memory config
vdcram_tbl	!by 16,64	;RAM size
bmp_page	!by $00,$40	;display memory
bmp_size	!by $40,$80

att_page	!by $2d,$c0	;attribute memory
att_size	!by $13,$40

tables_size = * - tables_start
main_size = * - main_ram0
}
;pseudopc

prg_size = * - prg_start	;program size
file_size = prg_size+2		;file size (including load address)
prg_end
