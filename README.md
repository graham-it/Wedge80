# Wedge80

C128 BASIC extension for VDC graphics\
Copyright (c) 2026 Graham (Francesco Gramignani)

Version 2.04\
Revision 9/5/2026

https://graham-it.itch.io \
https://github.com/graham-it \
https://csdb.dk/scener/?id=40810


### Introduction
Wedge80 is a program that extends the Commodore 128's BASIC 7.0 to take advantage of the graphics capabilities offered by the MOS 8563 VDC (Video Display Controller) chip, which is normally used only in 80-column text mode.

Wedge80 is compatible with the PAL versions of the C128/C128D, equipped with 16k or 64k bytes of video RAM dedicated to the VDC chip, and with the official BASIC 7.0 ROM revisions released between 1985 and 1986.


### Extended BASIC

To access the VDC chip's graphics capabilities, Wedge80 uses the same instruction set as BASIC 7.0, extending the number and range of supported parameters.

Thus, Wedge80 can handle both VDC and VIC-II graphics, ensuring full compatibility with existing software.

A complete list of Wedge80 commands and extended functions is available in the docs files included.
    
Extended commands:\
GRAPHIC	Selects the current screen mode\
COLOR	Sets a color for the selected source\
SCNCLR	Clears the selected screen mode\
LOCATE	Places the pixel cursor to a specified position\
DRAW	Draws dots, lines, and shapes\
BOX	Draws a BOX on the screen\
CIRCLE	Draws circles, ellipses or arcs\
PAINT	Fills an area starting from a specified position\
SSHAPE	Saves an area of the the screen into a BASIC string variable\
GSHAPE	Draws a shape stored in a BASIC string variable\
CHAR	Displays a string of characters on current bitmap/text screen\
AUTOFAST	Enables the AUTOFAST mode (FAST/SLOW to disable)\
HELP	Displays system status or Online Gude\
QUIT	Returns to BASIC V7.0


Extended functions:\
POS	Returns the cursor position within the current text screen window\
RCLR	Returns the value of the color source specified\
RDOT	Returns the current bitmap coordinates or pixel status\
RGR	Returns the value of the current screen mode\
RWINDOW	Returns dimension information about the current screen or window


### Installation

Wedge80 is available in two versions:

-    WEDGE80         full version
-    WEDGE80LT    light version (without the  'Online Guide')

To install Wedge80, after inserting the disk containing the program, simply load and run one of the two versions with the following commands:

-    DLOAD "file name"    (equivalent to LOAD "file name",8)
-    RUN

or:

-    RUN "file name"        (loads and runs)

During installation, the amount of memory available on the VDC chip (16k or 64k bytes) is automatically detected to adapt the program to the machine in use.


### Utilization

Wedge80 offers 144 theoretical combinations for configuring bitmap graphics using the VDC chip, allowing you to separately select the horizontal and vertical resolutions (up to 840 x 256 pixels) and the size of the color cells (down to 8x2 pixels).

VDC graphics can be activated using the command:

-    GRAPHIC mode[,clear][,h/res][,v/res][,color]

Once the VDC bitmap mode is activated, you can use the following command to draw a point or line on the screen:

-    DRAW [mode][,x0,y0][<TO|,> xn,yn][...]

The 'mode' option (as with the 'BOX' and 'CIRCLE' commands) specifies how pixels are drawn and replaces the 'source' option in BASIC 7.0 commands:
- 0	= erase
- 1	= draw (default)
- 2	= XOR with the pixels already on the screen


### Online Guide

The full version of Wedge80 comes with an 'Online Guide', which is installed in the upper part of the RAM block 1, normally used for storing BASIC variables.

To view the complete list of Wedge80 commands and extended functions, simply enter the following command at the BASIC prompt:

-    HELP +        (with or without space)

Additionally, you can get detailed information about a specific command or function using the following syntax:

-    HELP keyword

Where 'keyword' is the word used to identify the command or function you're requesting information about.


### AUTOFAST mode

When Wedge80 is started, AUTOFAST mode is enabled by default. This allows extended Wedge80 commands to be executed in FAST mode (2 MHz), then automatically reverts to SLOW mode (1 MHz) upon completion.


### ESCAPE sequences

The 'ESC X' sequence allows you to quickly switch between 40-column and 80-column text mode. When the 'ESC X' sequence is detected and the VDC is in bitmap mode, the 80-column text mode is automatically restored, transparently to the user.


### Wedge80 Library

Once installed, Wedge80 offers a function library that allows you to use some of its graphics routines directly from a machine language program (like the included demo, Sketch80).

This is done via a Jump Table, which ensures compatibility with any programs developed with this library, even if an updated version of  Wedge80 is released.


Wedge80 v2.04 (c) 2026 Graham

https://graham-it.itch.io \
https://github.com/graham-it \
https://csdb.dk/scener/?id=40810
