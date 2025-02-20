@set BB=325
@IF "%1" EQU "x64" goto x64
@ECHO Processing x86
@copy binWin32\hfs.exe "binWin32\HFS%BB%_RD.exe"
@upx.exe -9 --lzma "binWin32\HFS%BB%_RD.exe"
exit
:x64
@ECHO Processing x64
@copy binWin64\hfs.exe "binWin64\HFS%BB%_RDx64.exe"
@upx.exe -9 --lzma "binWin64\HFS%BB%_RDx64.exe"
