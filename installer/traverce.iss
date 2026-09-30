#define MyAppName "Traverce"
#ifndef MyAppVersion
#define MyAppVersion "0.3.0"
#endif
#define MyAppPublisher "levvs-one"
#define MyAppExeName "traverce.exe"

[Setup]
; Keep the legacy AppId so 0.3 upgrades the existing 0.1/0.2 installation.
AppId={{4C5B5AC7-5B75-4BE7-B1A6-03BBF8C17E29}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://github.com/levvs-one/traverce
AppSupportURL=https://github.com/levvs-one/traverce/issues
AppUpdatesURL=https://github.com/levvs-one/traverce/releases/latest
DefaultDirName={autopf}\Traverce
DefaultGroupName=Traverce
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=Traverce-{#MyAppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoProductName=Traverce
VersionInfoDescription=Traverce — selective access without a system-wide VPN

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; 0.1/0.2 shipped prosvet.exe. The same AppId upgrades in-place, so remove the
; obsolete binary and old Start Menu group explicitly.
Type: files; Name: "{app}\prosvet.exe"
Type: filesandordirs; Name: "{autoprograms}\Просвет"

[Icons]
Name: "{group}\Traverce"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Удалить Traverce"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить Traverce"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""Traverce"" /F"; Flags: runhidden waituntilterminated
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""Prosvet"" /F"; Flags: runhidden waituntilterminated
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""$ErrorActionPreference='SilentlyContinue'; Get-DnsClientNrptRule | Where-Object {{ $_.Comment -in @('Traverce','Prosvet') } | ForEach-Object {{ Remove-DnsClientNrptRule -Name $_.Name -Force }; Clear-DnsClientCache"""; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\Traverce"
Type: filesandordirs; Name: "{localappdata}\Prosvet"

[Code]
function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'),
       '/IM traverce.exe /T /F',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec(ExpandConstant('{sys}\taskkill.exe'),
       '/IM prosvet.exe /T /F',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;
