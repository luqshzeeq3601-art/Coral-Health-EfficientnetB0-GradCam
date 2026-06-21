@echo off
setlocal
cd /d "%~dp0\.."

set "ANDROID_SDK=%LOCALAPPDATA%\Android\Sdk"
set "EMULATOR_BIN=%ANDROID_SDK%\emulator\emulator.exe"
set "ADB_BIN=%ANDROID_SDK%\platform-tools\adb.exe"
set "FLUTTER_BIN=C:\Users\luqma\flutter\bin\flutter.bat"
set "DART_BIN=C:\Users\luqma\flutter\bin\dart.bat"

echo ====================================================
echo  Starting Flutter App on Android Emulator...
echo ====================================================
echo.

:: We launch the emulator if it's not already running
echo [1/3] Launching Android Emulator...
"%ADB_BIN%" devices 2>nul | findstr /b /c:"emulator-" >nul
if errorlevel 1 (
    start "" "%EMULATOR_BIN%" -avd flutter_emulator
) else (
    echo        Emulator is already running.
)

:: Wait for the emulator to boot and become reachable
echo [2/3] Waiting for emulator to be ready...
:wait_loop
"%ADB_BIN%" devices 2>nul | findstr /b /c:"emulator-" >nul
if errorlevel 1 (
    echo        Still waiting for emulator...
    timeout /t 3 /nobreak >nul
    goto wait_loop
)
echo        Emulator is ready!

set "FLUTTER_DEVICE_ID="
for /f "skip=1 tokens=1" %%D in ('"%ADB_BIN%" devices ^| findstr /b /c:"emulator-"') do (
    set "FLUTTER_DEVICE_ID=%%D"
    goto device_found
)

:device_found
if not defined FLUTTER_DEVICE_ID set "FLUTTER_DEVICE_ID=emulator-5554"

echo        Flutter device id: %FLUTTER_DEVICE_ID%
echo.

:: Run the flutter application with file watcher for auto-restart
echo [3/3] Running the app with auto-restart watcher...
echo.
call "%DART_BIN%" tool\watch_run.dart --device-id %FLUTTER_DEVICE_ID%

:: If something goes wrong, keep the window open
echo.
echo ====================================================
echo  Process ended. Press any key to close.
echo ====================================================
pause >nul
