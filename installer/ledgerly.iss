; Inno Setup script. Unsigned for now (SmartScreen shows "More info → Run anyway").
#define AppName "Ledgerly"
#define AppVersion GetEnv("LEDGERLY_VERSION")
#if AppVersion == ""
  #define AppVersion "0.1.0"
#endif
[Setup]
AppId={{7E2B0E1C-3A5C-4F2E-9B7D-LEDGERLY0001}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputBaseFilename=Ledgerly-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
[Files]
Source: "..\app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\ledgerly.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\ledgerly.exe"
[Run]
Filename: "{app}\ledgerly.exe"; Description: "Open Ledgerly"; Flags: nowait postinstall skipifsilent
