set TOOLDIR=C:\Program Files\Texas Instruments\ccsv5\tools\compiler\c5400\bin
set INFILE=dartm11

"%TOOLDIR%\asm500.exe" %INFILE%.asm
"%TOOLDIR%\lnk500.exe" -o %INFILE%.out -m %INFILE%.map %INFILE%.obj
"%TOOLDIR%\abs500.exe" %INFILE%.out
"%TOOLDIR%\asm500.exe" -a %INFILE%.abs
"%TOOLDIR%\hex500.exe" -i -memwidth 8 -romwidth 8 -bootorg 0x000 -o %INFILE%.hex %INFILE%.out
