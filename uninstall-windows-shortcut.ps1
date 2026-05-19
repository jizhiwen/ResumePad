# Remove ResumePad shortcuts.
$paths = @(
    (Join-Path $env:USERPROFILE 'Desktop\ResumePad.lnk'),
    (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\ResumePad.lnk')
)

foreach ($lnk in $paths) {
    if (Test-Path $lnk) {
        Remove-Item -LiteralPath $lnk -Force
        Write-Host "已删除: $lnk"
    } else {
        Write-Host "不存在: $lnk"
    }
}

Write-Host '若已固定到任务栏，请手动取消固定。'
