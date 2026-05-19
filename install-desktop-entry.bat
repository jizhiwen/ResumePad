@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

where powershell >nul 2>&1 || (
  echo 需要 PowerShell 以创建快捷方式。
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows-shortcut.ps1" -Root "%ROOT%"
if errorlevel 1 exit /b 1
echo.
pause
