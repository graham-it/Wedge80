@echo off
echo compiling C128 Wedge80 light version
echo.

acme --cpu 6502 -f cbm -l wedge80lt.sym -o wedge80lt wedge80lt.def wedge80.asm

if %errorlevel%==0 goto quit

echo.
pause

:quit
exit
