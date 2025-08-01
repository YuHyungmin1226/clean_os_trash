# PowerShell 스크립트: USB 연결 시 clean_mac_trash.py 자동 실행 작업 등록
# 관리자 권한으로 실행 필요

$taskName = "CleanMacTrashOnUSB"
$pythonPath = "python"  # python이 PATH에 등록되어 있어야 함
$scriptPath = "c:\WorkSpace\clean_os_trash\clean_mac_trash.py"

# USB 연결 이벤트: Event ID 2003 (Device Arrival)
$trigger = New-ScheduledTaskTrigger -AtStartup -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration ([TimeSpan]::MaxValue)
$action = New-ScheduledTaskAction -Execute $pythonPath -Argument "\"$scriptPath\" <USB_DRIVE_PATH>"

# 기존 작업 삭제(있다면)
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# 작업 등록 (USB 연결 이벤트를 직접 트리거로 지정하는 것은 복잡하므로, 1분마다 USB 드라이브를 감지하여 새로 연결된 드라이브가 있으면 스크립트 실행)
$script = @"
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
foreach ($drive in $drives) {
    Start-Process $pythonPath -ArgumentList '"$scriptPath"', $drive.DeviceID -NoNewWindow
}
"@

$scriptFile = "$env:TEMP\\usb_clean_temp.ps1"
Set-Content -Path $scriptFile -Value $script -Encoding UTF8

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`""

Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -RunLevel Highest -Force

Write-Host "USB 자동 정리 작업이 등록되었습니다."
