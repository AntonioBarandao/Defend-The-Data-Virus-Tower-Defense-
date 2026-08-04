@echo off
setlocal

set "GODOT_47=%USERPROFILE%\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
set "PROJECT_DIR=%~dp0"

if not exist "%GODOT_47%" (
    echo Godot 4.7 was not found at:
    echo %GODOT_47%
    echo.
    echo Reinstall Godot 4.7 or update GODOT_47 in this launcher.
    pause
    exit /b 1
)

start "" "%GODOT_47%" --editor --path "%PROJECT_DIR%"
