@ECHO OFF
BuiltTime.exe
@REM Copy rsvars.bat from Delphi bin directory
@ECHO SET variable D_COMPONENTS with path for components
@call rsvars.bat
@ECHO compiling
%BDS%\bin\brcc32 res\data.rc -fodata.res

%BDS%\bin\dcc32.exe hfs.dpr -$W+ --no-config -M -Q -TX.exe -AForms=VCL.Forms;Generics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE -DDEBUG  -DUSE_SYMCRYPTO -I"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";%USERPROFILE%\Documents\Embarcadero\Studio\20.0\Imports;"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";srv;..\RnQ\For.RnQ;%D_COMPONENTS%\other\compiled;%D_COMPONENTS%\fastmm4;%D_COMPONENTS%\kdl;%D_COMPONENTS%\ICSv8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common -LEC:\Users\Public\Documents\Embarcadero\Studio\20.0\Bpl -LNC:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp -NSData.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win; -O"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;srv;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;..\RnQ\for.RnQ\External\mORMot2\src\crypt;%D_COMPONENTS%\ICSv8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common -R"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;srv;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;..\RnQ\for.RnQ\External\mORMot2\src\crypt;%D_COMPONENTS%\ICSSv8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common -U"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;srv;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;..\RnQ\for.RnQ\External\mORMot2\src\crypt;%D_COMPONENTS%\ICSv8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common -K00400000   --description:"HFS ~ HTTP File Server - www.rejetto.com/hfs" -GD -NBC:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp  -NOUnits -NUUnits -NHC:\Users\Public\Documents\Embarcadero\Studio\20.0\hpp\Win32

exit;
%BDS%\bin\dcc32.exe hfs.dpr -$W+ --no-config -M -Q -TX.exe -AForms=VCL.Forms;Generics.Collections=System.Generics.Collections;Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE
 -DDEBUG  -DUSE_SYMCRYPTO
 -I"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";%USERPROFILE%\Documents\Embarcadero\Studio\20.0\Imports;"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";..\RnQ\For.RnQ;%D_COMPONENTS%\other\compiled;%D_COMPONENTS%\fastmm4;%D_COMPONENTS%\kdl;%D_COMPONENTS%\ics8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common
 -LEC:\Users\Public\Documents\Embarcadero\Studio\20.0\Bpl
 -LNC:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp
 -NSData.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;
 -O"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;%D_COMPONENTS%\ics8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common
 -R"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;%D_COMPONENTS%\ics8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common
 -U"%BDS%\Lib\Debug";"%BDS%\lib\Win32\release";"%BDS%\Imports";C:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp;"%BDS%\include";jcl;..\RnQ\For.RnQ;..\RnQ\For.RnQ\zip;..\RnQ\For.RnQ\RTL;..\RnQ\for.RnQ\External\mORMot2\src\core;%D_COMPONENTS%\ics8\source;%D_COMPONENTS%\jcl\source\windows;%D_COMPONENTS%\jcl\source\include;%D_COMPONENTS%\jcl\source\common
 -K00400000   --description:"HFS ~ HTTP File Server - www.rejetto.com/hfs" -GD -NBC:\Users\Public\Documents\Embarcadero\Studio\20.0\Dcp  -NOUnits -NUUnits
 -NHC:\Users\Public\Documents\Embarcadero\Studio\20.0\hpp\Win32
