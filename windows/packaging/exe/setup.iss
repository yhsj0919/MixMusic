#ifndef AppVersion
  #error AppVersion is required
#endif
#ifndef AppNumericVersion
  #error AppNumericVersion is required
#endif
#ifndef AppSourceDir
  #define AppSourceDir "..\..\..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId=MixMusic.v2
AppName=MixMusic v2
AppVersion={#AppVersion}
AppPublisher=永恒瞬间
AppPublisherURL=https://github.com/yhsj0919/MixMusic
AppSupportURL=https://github.com/yhsj0919/MixMusic/issues
AppUpdatesURL=https://github.com/yhsj0919/MixMusic/releases
DefaultDirName={autopf}\MixMusic v2
DefaultGroupName=MixMusic v2
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion={#AppNumericVersion}
UninstallDisplayIcon={app}\mix_music.exe
SetupIconFile=..\..\runner\resources\app_icon.ico
OutputDir=..\..\..\dist
OutputBaseFilename=MixMusic-windows-x64-v{#AppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
LanguageDetectionMethod=none
ShowLanguageDialog=yes

[Languages]
Name: "chinesesimplified"; MessagesFile: "ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#AppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\MixMusic v2"; Filename: "{app}\mix_music.exe"
Name: "{autodesktop}\MixMusic v2"; Filename: "{app}\mix_music.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\mix_music.exe"; Description: "{cm:LaunchProgram,MixMusic v2}"; Flags: nowait postinstall skipifsilent unchecked
