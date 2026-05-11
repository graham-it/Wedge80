@echo off
echo compiling: C128 Sketch80
echo.

acme --cpu 6502 -f cbm -l sketch80.sym -o sketch80 sketch80.asm

if %errorlevel%==0 goto quit

echo.
pause

:quit
exit
