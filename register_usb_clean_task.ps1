# PowerShell 스크립트: USB 연결 시 clean_mac_trash.py 자동 실행 작업 등록
# 관리자 권한으로 실행 필요

param(
    [string]$ScriptPath = $PSScriptRoot,
    [string]$TaskName = "CleanMacTrashOnUSB",
    [int]$CheckInterval = 1  # 분 단위
)

# 오류 발생 시 스크립트 중단
$ErrorActionPreference = "Stop"

function Test-PythonInstallation {
    """Python이 설치되어 있는지 확인"""
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Python 설치 확인됨: $pythonVersion" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Python이 설치되지 않았거나 PATH에 등록되지 않았습니다." -ForegroundColor Red
        Write-Host "Python을 설치하고 PATH에 등록한 후 다시 실행하세요." -ForegroundColor Yellow
        return $false
    }
    return $false
}

function Get-ScriptPath {
    """스크립트 경로를 동적으로 결정"""
    $scriptFile = Join-Path $ScriptPath "clean_mac_trash.py"
    
    if (Test-Path $scriptFile) {
        Write-Host "스크립트 경로: $scriptFile" -ForegroundColor Green
        return $scriptFile
    }
    else {
        Write-Host "clean_mac_trash.py 파일을 찾을 수 없습니다: $scriptFile" -ForegroundColor Red
        Write-Host "스크립트가 올바른 위치에 있는지 확인하세요." -ForegroundColor Yellow
        exit 1
    }
}

function Remove-ExistingTask {
    """기존 작업이 있다면 제거"""
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "기존 작업을 제거합니다: $TaskName" -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Host "기존 작업 제거 중 오류 발생: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function New-USBDetectionScript {
    """USB 감지 및 정리 스크립트 생성"""
    $scriptContent = @"
# USB 드라이브 감지 및 Mac OS 불필요 파일 정리
`$ErrorActionPreference = "Continue"

# 로그 파일 경로
`$logFile = Join-Path `$env:TEMP "usb_clean_`$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param(`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "`$timestamp - `$Message"
    Add-Content -Path `$logFile -Value `$logMessage
}

Write-Log "USB 정리 작업 시작"

# Python 경로 확인
try {
    `$pythonPath = (Get-Command python -ErrorAction Stop).Source
    Write-Log "Python 경로: `$pythonPath"
}
catch {
    Write-Log "오류: Python을 찾을 수 없습니다"
    exit 1
}

# 스크립트 경로
`$scriptPath = "$(Get-ScriptPath)"
Write-Log "정리 스크립트 경로: `$scriptPath"

# USB 드라이브 감지
`$usbDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { `$_.DriveType -eq 2 }
Write-Log "발견된 USB 드라이브: `$(`$usbDrives.Count)개"

if (`$usbDrives.Count -eq 0) {
    Write-Log "USB 드라이브가 연결되지 않았습니다."
    exit 0
}

# 각 USB 드라이브에 대해 정리 실행
foreach (`$drive in `$usbDrives) {
    `$driveLetter = `$drive.DeviceID.TrimEnd('\')
    Write-Log "USB 드라이브 처리 중: `$driveLetter"
    
    try {
        # 드라이브가 실제로 접근 가능한지 확인
        if (Test-Path `$drive.DeviceID) {
            # 중복 실행 방지를 위한 락 파일 확인
            `$lockFile = Join-Path `$env:TEMP "usb_clean_lock_`$(`$driveLetter.Replace(':', '')).lock"
            
            if (Test-Path `$lockFile) {
                `$lockTime = Get-ItemProperty `$lockFile | Select-Object -ExpandProperty LastWriteTime
                `$timeDiff = (Get-Date) - `$lockTime
                
                # 5분 이상 된 락 파일은 제거
                if (`$timeDiff.TotalMinutes -gt 5) {
                    Remove-Item `$lockFile -Force
                    Write-Log "오래된 락 파일 제거: `$lockFile"
                }
                else {
                    Write-Log "이미 처리 중인 드라이브 건너뛰기: `$driveLetter"
                    continue
                }
            }
            
            # 락 파일 생성
            New-Item -Path `$lockFile -ItemType File -Force | Out-Null
            
            # 정리 스크립트 실행
            `$arguments = @(
                "`"`$scriptPath`"",
                "`"`$(`$drive.DeviceID)`"",
                "--no-confirm"
            )
            
            Write-Log "정리 스크립트 실행: `$pythonPath `$(`$arguments -join ' ')"
            
            `$process = Start-Process -FilePath `$pythonPath -ArgumentList `$arguments -NoNewWindow -PassThru -Wait
            
            if (`$process.ExitCode -eq 0) {
                Write-Log "정리 완료: `$driveLetter"
            }
            else {
                Write-Log "정리 실패: `$driveLetter (종료 코드: `$(`$process.ExitCode))"
            }
            
            # 락 파일 제거
            if (Test-Path `$lockFile) {
                Remove-Item `$lockFile -Force
            }
        }
        else {
            Write-Log "드라이브에 접근할 수 없음: `$driveLetter"
        }
    }
    catch {
        Write-Log "드라이브 처리 중 오류 발생: `$driveLetter - `$(`$_.Exception.Message)"
    }
}

Write-Log "USB 정리 작업 완료"
"@

    $tempScriptPath = Join-Path $env:TEMP "usb_clean_detection.ps1"
    Set-Content -Path $tempScriptPath -Value $scriptContent -Encoding UTF8
    return $tempScriptPath
}

# 메인 실행 부분
Write-Host "=== Mac OS 불필요 파일 자동 정리 작업 등록 ===" -ForegroundColor Cyan
Write-Host ""

# Python 설치 확인
if (-not (Test-PythonInstallation)) {
    exit 1
}

# 스크립트 경로 확인
$scriptPath = Get-ScriptPath

# 기존 작업 제거
Remove-ExistingTask

# USB 감지 스크립트 생성
$detectionScriptPath = New-USBDetectionScript

# 작업 스케줄러 트리거 생성
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $CheckInterval) -RepetitionDuration ([TimeSpan]::MaxValue)

# 작업 액션 생성
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$detectionScriptPath`""

# 작업 설정
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 작업 등록
try {
    Register-ScheduledTask -TaskName $TaskName -Trigger $trigger -Action $action -Settings $settings -RunLevel Highest -Force
    Write-Host "✅ USB 자동 정리 작업이 성공적으로 등록되었습니다!" -ForegroundColor Green
    Write-Host ""
    Write-Host "작업 세부사항:" -ForegroundColor Yellow
    Write-Host "  - 작업 이름: $TaskName" -ForegroundColor White
    Write-Host "  - 실행 간격: $CheckInterval분마다" -ForegroundColor White
    Write-Host "  - 스크립트 경로: $scriptPath" -ForegroundColor White
    Write-Host "  - 로그 파일: %TEMP%\usb_clean_*.log" -ForegroundColor White
    Write-Host ""
    Write-Host "작업 관리 명령어:" -ForegroundColor Yellow
    Write-Host "  - 작업 상태 확인: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  - 작업 중지: Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  - 작업 시작: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  - 작업 제거: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
}
catch {
    Write-Host "❌ 작업 등록 실패: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
