@echo off

set TOOLDIR=C:\TI54xCGT\bin
set INFILE=%1
set NOEXT=%~n1

echo Compiling file %INFILE%...

"%TOOLDIR%\asm500.exe" %INFILE% %NOEXT%.obj -v 542 -pw 
if not %ERRORLEVEL%==0 goto error

echo done.

goto end

:error

echo compilation error!

:end

REM pause
