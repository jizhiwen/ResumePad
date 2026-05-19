# Install ResumePad shortcuts (Desktop + Start Menu).
param(
    [Parameter(Mandatory = $true)][string]$Root
)

$ErrorActionPreference = 'Stop'
$Root = $Root.TrimEnd('\')
$Launcher = Join-Path $Root 'launch-app.bat'
$Icon = Join-Path $Root 'icons\icon-512.png'

if (-not (Test-Path $Launcher)) {
    Write-Error "找不到 launch-app.bat: $Launcher"
}

$shell = New-Object -ComObject WScript.Shell
$targets = @(
    (Join-Path $env:USERPROFILE 'Desktop\ResumePad.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\ResumePad.lnk')
)

foreach ($lnk in $targets) {
    $dir = Split-Path $lnk -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $sc = $shell.CreateShortcut($lnk)
    $sc.TargetPath = $Launcher
    $sc.WorkingDirectory = $Root
    if (Test-Path $Icon) { $sc.IconLocation = $Icon }
    $sc.Description = 'ResumePad — 任务上下文恢复'
    $sc.Save()
    Write-Host "已创建: $lnk"
}

Write-Host ''
Write-Host '请从开始菜单或桌面 ResumePad 快捷方式启动（使用独立 Edge 配置，任务栏与 Edge 分开）。'
