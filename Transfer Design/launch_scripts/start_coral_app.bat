@echo off
REM Detect the python executable path dynamically
set "PYTHON_EXEC=python"
if exist "%USERPROFILE%\v-coral\Scripts\python.exe" (
    set "PYTHON_EXEC=%USERPROFILE%\v-coral\Scripts\python.exe"
) else if exist "%~dp0.venv\Scripts\python.exe" (
    set "PYTHON_EXEC=%~dp0.venv\Scripts\python.exe"
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
start "Coral App" cmd /k "cd /d "%~dp004_Web_Application" && "%PYTHON_EXEC%" app.py"

REM Start the Cloudflare tunnel
start "Coral Tunnel" cmd /k ""C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --protocol http2 --url http://localhost:5000 run coralapp"

echo Started app and tunnel windows.
