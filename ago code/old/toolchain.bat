@echo off

set TOOLDIR=C:\TI54xCGT\bin
set INFILE=%1
set NOEXT=%~n1

echo Compiling file %INFILE%...

"%TOOLDIR%\asm500.exe" %INFILE% %NOEXT%.obj
if not %ERRORLEVEL%==0 goto error
"%TOOLDIR%\lnk500.exe" toollink.cmd -w -ar -m %NOEXT%_link.map -o %NOEXT%.out %NOEXT%.obj
if not %ERRORLEVEL%==0 goto error
echo Linking complete.
"%TOOLDIR%\abs500.exe" %NOEXT%.out
if not %ERRORLEVEL%==0 goto error
"%TOOLDIR%\asm500.exe" -x -a %NOEXT%.abs
if not %ERRORLEVEL%==0 goto error
"%TOOLDIR%\hex500.exe" toolhex.cmd -map %NOEXT%_hex.map -o %NOEXT%.hex -i %NOEXT%.out
if not %ERRORLEVEL%==0 goto error

REM del %NOEXT%.map %NOEXT%.obj %NOEXT%.abs %NOEXT%.lst

echo done.

goto end

:error

echo compilation error!

:end

REM pause
