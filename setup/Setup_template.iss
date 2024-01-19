[Setup]
AppName="SHTRIH-M: OPOS WebPrinter driver"
AppVerName="SHTRIH-M: OPOS WebPrinter driver ${version2}"
AppPublisher=SHTRIH-M
AppCopyright="Copyright, 2024 SHTRIH-M"
VersionInfoCompany="SHTRIH-M"
VersionInfoDescription="OPOS web printer driver"
AppVersion=${version2}
AppPublisherURL=http://www.shtrih-m.ru
AppSupportURL=http://www.shtrih-m.ru
AppUpdatesURL=http://www.shtrih-m.ru
AppContact=т.(495) 787-6090
AppReadmeFile=History.txt
;Версия
VersionInfoTextVersion="${version}"
VersionInfoVersion=${version}
DefaultDirName= {pf}\OPOS\WebPrinter\
DefaultGroupName=OPOS\WebPrinter\
UninstallDisplayIcon= {app}\Uninstall.exe
AllowNoIcons=Yes
OutputDir="."
[Setup]
OutputBaseFilename=Setup
[Components]
Name: "main"; Description: "Driver files"; Types: full compact custom; Flags: fixed
Name: "source"; Description: "Samples and source code"; 
[Files]
; Version history
Source: "History.txt"; DestDir: "{app}"; Flags: ignoreversion; components: main;
; Drivers
Source: "Bin\WebFptrSo.dll"; DestDir: "{app}\Bin"; Flags: ignoreversion regserver; components: main;
Source: "Bin\WebFptrCfg.exe"; DestDir: "{app}\Bin"; Flags: ignoreversion; components: main;
Source: "Bin\WebFptrTst.exe"; DestDir: "{app}\Bin"; Flags: ignoreversion; components: main;
[Icons]
Name: "{group}\Version history"; Filename: "{app}\History.txt"; WorkingDir: "{app}";
Name: "{group}\Opos setup"; Filename: "{app}\Bin\WebFptrCfg.exe"; WorkingDir: "{app}";
Name: "{group}\Opos test"; Filename: "{app}\Bin\WebFptrTst.exe"; WorkingDir: "{app}";
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"
[Registry]
; FiscalPrinter default device
Root: HKLM; Subkey: "SOFTWARE\OLEforRetail\ServiceOPOS\FiscalPrinter\SHTRIH-M-OPOS-1"; ValueType: string; ValueName: ""; ValueData: "OposWebPrinter.FiscalPrinter"; Flags: uninsdeletevalue;
[UninstallDelete]
Type: files; Name: "{app}\*.log"












