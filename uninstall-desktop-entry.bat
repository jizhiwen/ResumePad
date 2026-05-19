@echo off
setlocal EnableExtensions

where powershell >nul 2>&1 || (
  echo 需要 PowerShell。
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall-windows-shortcut.ps1"
if errorlevel 1 exit /b 1
echo.
pause
