@echo off
setlocal enabledelayedexpansion
title CoralAI - Smart Coral Health Assessment
echo ======================================================
echo    Starting CoralAI Web Application...
echo ======================================================
echo.

:: 1. Navigate to Project Root (Relative to this script)
cd /d "%~dp0"

:: 2. Pre-flight checks
set "PYTHON_EXEC="
if exist "%USERPROFILE%\v-coral\Scripts\python.exe" (
    set "PYTHON_EXEC=%USERPROFILE%\v-coral\Scripts\python.exe"
) else if exist "%~dp0.venv\Scripts\python.exe" (
    set "PYTHON_EXEC=%~dp0.venv\Scripts\python.exe"
) else (
    where python >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set "PYTHON_EXEC=python"
    )
)

if "!PYTHON_EXEC!"=="" (
    echo [ERROR] Python not found. Virtual environment missing, and system Python is not in PATH.
    echo Please ensure the virtual environment is set up at %USERPROFILE%\v-coral or .venv\
    pause
    exit /b 1
)

set "MODEL_PATH=02_Modelling\efficientnetb0_coral\models"
if not exist "%MODEL_PATH%" (
    echo [ERROR] Model directory not found: %MODEL_PATH%
    echo Please check the path in app.py and ensure models are downloaded.
    pause
    exit /b 1
)

:: 2b. Pre-flight check: built React frontend must exist
if not exist "04_Web_Application\frontend\index.html" (
    echo [ERROR] Built frontend not found: 04_Web_Application\frontend\index.html
    echo Build it first:
    echo   cd "Landing Page Ideas\Coral Improve Design Landing Page\Coral AI Landing Page"
    echo   npm install ^&^& npm run build
    echo Then copy the generated dist\ contents into 04_Web_Application\frontend\
    pause
    exit /b 1
)

:: 2c. Pre-flight check: curl must be available for health polling
where curl >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] curl.exe is required for server health checks but was not found on PATH.
    pause
    exit /b 1
)

:: 3. All pre-flight checks passed
echo [OK] Starting server with virtual environment Python...
echo [OK] Model: EfficientNet-V4 Robust (ENSEMBLE)
echo [OK] Frontend: Coral AI Landing Page (React build -^> 04_Web_Application\frontend)
echo.

:: 4. Create a temporary polling script to open the browser
echo @echo off > "%TEMP%\coral_poll.bat"
echo setlocal enabledelayedexpansion >> "%TEMP%\coral_poll.bat"
echo set /a TRIES=0 >> "%TEMP%\coral_poll.bat"
echo :WAIT_LOOP >> "%TEMP%\coral_poll.bat"
echo curl -s -o nul http://localhost:5000/api/health >> "%TEMP%\coral_poll.bat"
echo if ^^!ERRORLEVEL^^!==0 ( >> "%TEMP%\coral_poll.bat"
echo     start "" "http://localhost:5000/" >> "%TEMP%\coral_poll.bat"
echo     exit >> "%TEMP%\coral_poll.bat"
echo ) >> "%TEMP%\coral_poll.bat"
echo set /a TRIES+=1 >> "%TEMP%\coral_poll.bat"
echo if ^^!TRIES^^! GEQ 90 ( >> "%TEMP%\coral_poll.bat"
echo     start "" "http://localhost:5000/" >> "%TEMP%\coral_poll.bat"
echo     exit >> "%TEMP%\coral_poll.bat"
echo ) >> "%TEMP%\coral_poll.bat"
echo ping 127.0.0.1 -n 2 ^>nul >> "%TEMP%\coral_poll.bat"
echo goto WAIT_LOOP >> "%TEMP%\coral_poll.bat"

:: Launch the polling script in the background
start "" /B cmd /c "%TEMP%\coral_poll.bat"

:: 5. Run the application in the FOREGROUND
echo.
echo [OK] Server will run in this window.
echo [INFO] Loading ensemble models (this may take up to 20 seconds)...
echo [OK] Press Ctrl+C to gracefully stop the server.
echo.
"!PYTHON_EXEC!" "04_Web_Application\app.py"

echo.
echo [OK] Server stopped. Goodbye.
if exist "%TEMP%\coral_poll.bat" del "%TEMP%\coral_poll.bat"
pause
endlocal
