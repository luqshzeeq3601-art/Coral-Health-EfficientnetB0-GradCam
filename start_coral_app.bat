@echo off
setlocal

set "APP_URL=http://127.0.0.1:5000"
set "PUBLIC_URL=https://coralhealth.systems"
set "APP_DIR=%~dp004_Web_Application"
set "TUNNEL_CONFIG=%~dp0cloudflared-coral.yml"

REM Detect cloudflared dynamically
set "CLOUDFLARED="
if exist "C:\Program Files\cloudflared\cloudflared.exe" set "CLOUDFLARED=C:\Program Files\cloudflared\cloudflared.exe"
if "%CLOUDFLARED%"=="" if exist "C:\Program Files (x86)\cloudflared\cloudflared.exe" set "CLOUDFLARED=C:\Program Files (x86)\cloudflared\cloudflared.exe"
if "%CLOUDFLARED%"=="" (
    where cloudflared >nul 2>&1
    if not errorlevel 1 set "CLOUDFLARED=cloudflared"
)

REM Detect the python executable path dynamically
set "PYTHON_EXEC="
if exist "%USERPROFILE%\v-coral\Scripts\python.exe" set "PYTHON_EXEC=%USERPROFILE%\v-coral\Scripts\python.exe"
if "%PYTHON_EXEC%"=="" if exist "%~dp0.venv\Scripts\python.exe" set "PYTHON_EXEC=%~dp0.venv\Scripts\python.exe"
if "%PYTHON_EXEC%"=="" (
    where python >nul 2>&1
    if not errorlevel 1 set "PYTHON_EXEC=python"
)

if "%PYTHON_EXEC%"=="" (
    echo [ERROR] Python not found. Virtual environment missing, and system Python is not in PATH.
    pause
    exit /b 1
)

REM Pre-flight: the built React frontend must exist (home page is served from it)
if not exist "%~dp004_Web_Application\frontend\index.html" (
    echo [ERROR] Built frontend not found: 04_Web_Application\frontend\index.html
    echo Build it first ^(see "Coral AI Landing Page": npm install ^&^& npm run build^),
    echo then copy the generated dist\ contents into 04_Web_Application\frontend\
    pause
    exit /b 1
)

REM Start the Flask app
start "Coral App" /D "%APP_DIR%" cmd /k ""%PYTHON_EXEC%" app.py"

REM Start the Cloudflare tunnel for coralhealth.systems.
if not "%CLOUDFLARED%"=="" (
    start "Coral Tunnel" cmd /k ""%CLOUDFLARED%" tunnel --config "%TUNNEL_CONFIG%" run coralapp"
) else (
    echo [WARN] cloudflared not found in standard directories or PATH.
)

REM Wait until Flask is ready, then open the public Cloudflare domain.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$healthUrl = '%APP_URL%'; " ^
  "$publicUrl = '%PUBLIC_URL%'; " ^
  "$deadline = (Get-Date).AddMinutes(3); " ^
  "do { try { Invoke-WebRequest -Uri ($healthUrl + '/api/health') -UseBasicParsing -TimeoutSec 3 | Out-Null; Start-Process $publicUrl; exit 0 } catch { Start-Sleep -Seconds 2 } } while ((Get-Date) -lt $deadline); " ^
  "Start-Process $publicUrl"

echo Started app and tunnel windows.
exit /b 0
