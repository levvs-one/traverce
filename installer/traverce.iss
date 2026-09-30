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
; Remove only the obsolete Start Menu group here. The legacy executable is
; deleted after its scheduled task has been retargeted in [Code].
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
procedure MigrateLegacyAutostart();
var
  QueryCode, ChangeCode: Integer;
  LegacyExe, NewExe, ChangeArgs: String;
  HasLegacyTask: Boolean;
begin
  LegacyExe := ExpandConstant('{app}\prosvet.exe');
  NewExe := ExpandConstant('{app}\{#MyAppExeName}');

  HasLegacyTask :=
    Exec(ExpandConstant('{sys}\schtasks.exe'),
         '/Query /TN "Prosvet"',
         '', SW_HIDE, ewWaitUntilTerminated, QueryCode) and
    (QueryCode = 0);

  if HasLegacyTask then
  begin
    ChangeArgs :=
      '/Change /TN "Prosvet" /TR "\"' + NewExe + '\" --background"';

    if Exec(ExpandConstant('{sys}\schtasks.exe'),
            ChangeArgs,
            '', SW_HIDE, ewWaitUntilTerminated, ChangeCode) and
       (ChangeCode = 0) then
    begin
      Log('Retargeted legacy autostart task to Traverce.');
      if FileExists(LegacyExe) and not DeleteFile(LegacyExe) then
        Log('Could not delete legacy executable after task migration: ' + LegacyExe);
    end
    else
    begin
      Log('Legacy autostart task could not be retargeted; keeping legacy executable.');
    end;
  end
  else
  begin
    if FileExists(LegacyExe) and not DeleteFile(LegacyExe) then
      Log('Could not delete unused legacy executable: ' + LegacyExe);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    MigrateLegacyAutostart();
end;

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
