#define MyAppName "Traverce"
#ifndef MyAppVersion
#define MyAppVersion "0.3.1"
#endif
#define MyAppPublisher "levvs-one"
#define MyAppExeName "traverce.exe"

[Setup]
; Keep the stable AppId so patch/minor releases upgrade in place.
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
; Remove the obsolete Start Menu group. The legacy executable is deleted only
; after autostart migration succeeds (or when no legacy task exists).
Type: filesandordirs; Name: "{autoprograms}\Просвет"

[Icons]
Name: "{group}\Traverce"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Удалить Traverce"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить Traverce"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""Traverce"" /F"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveTraverceTask"
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""Prosvet"" /F"; Flags: runhidden waituntilterminated; RunOnceId: "RemoveLegacyTask"
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ""$ErrorActionPreference='SilentlyContinue'; Get-DnsClientNrptRule | Where-Object {{ $_.Comment -in @('Traverce','Prosvet') } | ForEach-Object {{ Remove-DnsClientNrptRule -Name $_.Name -Force }; Clear-DnsClientCache"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveTraverceNrpt"

[UninstallDelete]
Type: files; Name: "{app}\prosvet.exe"
Type: filesandordirs; Name: "{localappdata}\Traverce"
Type: filesandordirs; Name: "{localappdata}\Prosvet"

[Code]
procedure MigrateLegacyAutostart();
var
  ScriptPath, Script, LegacyExe, NewExe, Args: String;
  ResultCode: Integer;
  Started: Boolean;
begin
  LegacyExe := ExpandConstant('{app}\prosvet.exe');
  NewExe := ExpandConstant('{app}\{#MyAppExeName}');
  ScriptPath := ExpandConstant('{tmp}\traverce-migrate-autostart.ps1');

  Script :=
    'param([Parameter(Mandatory=$true)][string]$ExePath)' + #13#10 +
    '$ErrorActionPreference = ''Stop''' + #13#10 +
    '$task = Get-ScheduledTask -TaskName ''Prosvet'' -ErrorAction SilentlyContinue' + #13#10 +
    'if ($null -ne $task) {' + #13#10 +
    '  $action = New-ScheduledTaskAction -Execute $ExePath -Argument ''--background''' + #13#10 +
    '  Set-ScheduledTask -TaskName ''Prosvet'' -Action $action -ErrorAction Stop | Out-Null' + #13#10 +
    '}' + #13#10;

  if not SaveStringToFile(ScriptPath, Script, False) then
  begin
    Log('Could not write autostart migration helper; keeping legacy executable.');
    exit;
  end;

  Args :=
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' +
    AddQuotes(ScriptPath) + ' -ExePath ' + AddQuotes(NewExe);

  Started :=
    Exec(
      ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
      Args,
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode
    );

  DeleteFile(ScriptPath);

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
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/IM traverce.exe /T /F',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/IM prosvet.exe /T /F',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
  Result := True;
end;
