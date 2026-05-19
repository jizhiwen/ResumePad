@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
set "ROOT=%ROOT:\=/%"
set "URL=file:///%ROOT%index.html?standalone=1"
set "PROFILE=%LOCALAPPDATA%\ResumePad\EdgeProfile"
if not exist "%PROFILE%" mkdir "%PROFILE%"
set "ARGS=--app=%URL% --user-data-dir=%PROFILE%"

if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" %ARGS%
  exit /b 0
)
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" %ARGS%
  exit /b 0
)
where msedge >nul 2>&1 && (
  start "" msedge %ARGS%
  exit /b 0
)

echo 未找到 Microsoft Edge。请安装 Edge，或直接双击 index.html。
exit /b 1
