@echo off
echo compiling C128 Wedge80
echo.

acme --cpu 6502 -f cbm -l wedge80.sym -o wedge80 wedge80.def wedge80.asm

if %errorlevel%==0 goto quit

echo.
pause

:quit
exit
