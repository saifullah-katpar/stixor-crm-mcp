; Inno Setup Script for Stixor CRM MCP Server
; This creates a standard Windows installer (.exe) with a setup wizard

[Setup]
AppName=Stixor CRM MCP Server
AppVersion=1.0.0
AppPublisher=Stixor
DefaultDirName={autopf}\StixorCRM-MCP
DefaultGroupName=Stixor CRM
OutputBaseFilename=StixorCRM-MCP-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
OutputDir=..\dist\installer

[Files]
Source: "..\dist\stixor-crm-win.exe"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{app}\configure.bat"; Parameters: """{app}\stixor-crm-win.exe"""; Flags: runhidden shellexec waituntilterminated; StatusMsg: "Configuring Claude Desktop..."

[Code]
var ApiKeyPage: TInputQueryWizardPage;
var ApiUrlPage: TInputQueryWizardPage;

procedure InitializeWizard;
begin
  ApiKeyPage := CreateInputQueryPage(wpSelectDir,
    'Outline Wiki Credentials',
    'Enter your API key to connect to your Outline wiki.',
    'Please enter your Outline API Key:');
  ApiKeyPage.Add('API Key:', False);

  ApiUrlPage := CreateInputQueryPage(ApiKeyPage.ID,
    'Outline Wiki URL',
    'Enter the URL of your Outline wiki API.',
    'Leave default if using wiki.stixor.com:');
  ApiUrlPage.Add('API URL:', False);
  ApiUrlPage.Values[0] := 'https://wiki.stixor.com/api';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = ApiKeyPage.ID then
  begin
    if ApiKeyPage.Values[0] = '' then
    begin
      MsgBox('API Key is required.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigDir, ConfigFile, ExePath, JsonContent: String;
  ConfigLines: TArrayOfString;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigDir := ExpandConstant('{userappdata}\Claude');
    ConfigFile := ConfigDir + '\claude_desktop_config.json';
    ExePath := ExpandConstant('{app}\stixor-crm-win.exe');

    // Escape backslashes for JSON
    StringChangeEx(ExePath, '\', '\\', True);

    ForceDirectories(ConfigDir);

    JsonContent := '{' + #13#10 +
      '  "mcpServers": {' + #13#10 +
      '    "stixor-crm": {' + #13#10 +
      '      "command": "' + ExePath + '",' + #13#10 +
      '      "args": [],' + #13#10 +
      '      "env": {' + #13#10 +
      '        "OUTLINE_API_KEY": "' + ApiKeyPage.Values[0] + '",' + #13#10 +
      '        "OUTLINE_API_URL": "' + ApiUrlPage.Values[0] + '"' + #13#10 +
      '      }' + #13#10 +
      '    }' + #13#10 +
      '  }' + #13#10 +
      '}';

    // Check if config already exists — merge if possible
    if FileExists(ConfigFile) then
    begin
      // For simplicity, warn the user
      if MsgBox('Claude Desktop config already exists. Overwrite with MCP server config?' + #13#10 +
                 '(Your existing preferences may be reset)', mbConfirmation, MB_YESNO) = IDNO then
        Exit;
    end;

    SaveStringToFile(ConfigFile, JsonContent, False);
  end;
end;

[UninstallDelete]
Type: files; Name: "{app}\stixor-crm-win.exe"

[Messages]
FinishedLabel=Stixor CRM MCP Server has been installed.%n%nPlease restart Claude Desktop to activate the wiki connector.%n%nTry saying: "List all collections on my wiki"
