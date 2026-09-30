#define MyAppName "Traverce"
#ifndef MyAppVersion
#define MyAppVersion "0.3.1"
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
; deleted after its scheduled task has been retargeted in [Code]
function PsQuote(const Value: String): String;
begin
  Result := '''' + StringChangeEx(Value, '''', '''''', True) + '''';
end;

procedure MigrateLegacyAutostart();
var
  ResultCode: Integer;
  LegacyExe, NewExe, Script, Args: String;
  Started: Boolean;
begin
  LegacyExe := ExpandConstant('{app}\prosvet.exe');
  NewExe := ExpandConstant('{app}\{#MyAppExeName}');

  { Use the ScheduledTasks PowerShell API instead of schtasks /Change.
    /Change may request credentials for an existing task and can hang a silent
    installer. Set-ScheduledTask updates only the action and preserves the
    existing trigger, principal, enabled state and settings. }
  Script :=
    '$ErrorActionPreference = ''Stop''; ' +
    '$task = Get-ScheduledTask -TaskName ''Prosvet'' -ErrorAction SilentlyContinue; ' +
    'if ($null -ne $task) { ' +
      '$action = New-ScheduledTaskAction -Execute ' + PsQuote(NewExe) +
        ' -Argument ''--background''; ' +
      'Set-ScheduledTask -TaskName ''Prosvet'' -Action $action -ErrorAction Stop | Out-Null; ' +
    '}';

  Args :=
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' +
    StringChangeEx(Script, '"', '\"', True) + '"';

  Started :=
    Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
         Args,
         '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  if Started and (ResultCode = 0) then
  begin
    if FileExists(LegacyExe) and not DeleteFile(LegacyExe) then
      Log('Could not delete legacy executable after autostart migration: ' + LegacyExe);
  end
  else
  begin
    Log('Legacy autostart migration failed; keeping legacy executable for safe fallback.');
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
