@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Stixor CRM MCP Server - Installer
echo ========================================
echo.

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed.
    echo.
    echo Please install Node.js first:
    echo   https://nodejs.org
    echo.
    echo Download the LTS version, run the installer, then try again.
    pause
    exit /b 1
)

for /f "tokens=1 delims=v" %%a in ('node -v') do set NODE_VER=%%a
echo [OK] Node.js found: %NODE_VER%

:: Check npm
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed. It should come with Node.js.
    pause
    exit /b 1
)
echo [OK] npm found

:: Get script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
echo [OK] Project directory: %SCRIPT_DIR%

echo.
echo ----------------------------------------
echo   Enter your Outline wiki credentials
echo ----------------------------------------
echo.

set /p API_KEY="  Outline API Key: "
if "%API_KEY%"=="" (
    echo [ERROR] API key is required.
    pause
    exit /b 1
)

set /p API_URL="  Outline API URL [https://wiki.stixor.com/api]: "
if "%API_URL%"=="" set "API_URL=https://wiki.stixor.com/api"

echo.

:: Add common Node.js install paths in case PATH is incomplete
set "PATH=%PATH%;%ProgramFiles%\nodejs;%LOCALAPPDATA%\fnm_multishells\default;%APPDATA%\nvm\current"

:: Install dependencies
echo Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] npm install failed.
    echo   Make sure you have internet access and Node.js is installed properly.
    echo   Try running "npm install" manually in this folder.
    pause
    exit /b 1
)
echo [OK] Dependencies installed

:: Build
echo Building...
call npm run build
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed.
    pause
    exit /b 1
)
echo [OK] Build successful

:: Get absolute path to build output
set "BUILD_PATH=%SCRIPT_DIR%build\index.js"

:: Configure Claude Desktop
echo.
echo Configuring Claude Desktop...

set "CONFIG_DIR=%APPDATA%\Claude"
set "CONFIG_FILE=%CONFIG_DIR%\claude_desktop_config.json"

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:: Escape backslashes for JSON
set "BUILD_PATH_JSON=%BUILD_PATH:\=\\%"

:: Write config using Python if available, otherwise write fresh
where python >nul 2>nul
if %errorlevel% equ 0 (
    python -c "import json,os;f='%CONFIG_FILE%'.replace('\\\\','\\');d=json.load(open(f)) if os.path.exists(f) else {};d.setdefault('mcpServers',{});d['mcpServers']['stixor-crm']={'command':'node','args':['%BUILD_PATH_JSON%'],'env':{'OUTLINE_API_KEY':'%API_KEY%','OUTLINE_API_URL':'%API_URL%'}};json.dump(d,open(f,'w'),indent=2);print('Config updated')" 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Claude Desktop config updated
        goto :done
    )
)

where python3 >nul 2>nul
if %errorlevel% equ 0 (
    python3 -c "import json,os;f='%CONFIG_FILE%'.replace('\\\\','\\');d=json.load(open(f)) if os.path.exists(f) else {};d.setdefault('mcpServers',{});d['mcpServers']['stixor-crm']={'command':'node','args':['%BUILD_PATH_JSON%'],'env':{'OUTLINE_API_KEY':'%API_KEY%','OUTLINE_API_URL':'%API_URL%'}};json.dump(d,open(f,'w'),indent=2);print('Config updated')" 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Claude Desktop config updated
        goto :done
    )
)

:: Fallback: write config directly (overwrites existing)
echo {"mcpServers":{"stixor-crm":{"command":"node","args":["%BUILD_PATH_JSON%"],"env":{"OUTLINE_API_KEY":"%API_KEY%","OUTLINE_API_URL":"%API_URL%"}}}} > "%CONFIG_FILE%"
echo [OK] Claude Desktop config created

:done
echo.
echo ========================================
echo   Setup complete!
echo ========================================
echo.
echo   Next steps:
echo   1. Close Claude Desktop completely
echo   2. Reopen Claude Desktop
echo   3. Look for the hammer icon with 8 tools
echo.
echo   Try saying:
echo     "List all collections on my wiki"
echo     "Search for documents about ProjectX"
echo     "Create a client profile for Acme Corp"
echo.
pause
