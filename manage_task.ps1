# 작업 스케줄러 관리 스크립트
# Mac OS 불필요 파일 정리 작업을 쉽게 관리할 수 있는 도구

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("status", "start", "stop", "remove", "create")]
    [string]$Action,
    
    [string]$TaskName = "CleanMacTrashOnUSB"
)

# 오류 발생 시 스크립트 중단
$ErrorActionPreference = "Stop"

function Show-TaskStatus {
    """작업 상태를 표시합니다."""
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        Write-Host "=== 작업 상태 ===" -ForegroundColor Cyan
        Write-Host "작업 이름: $($task.TaskName)" -ForegroundColor White
        Write-Host "상태: $($task.State)" -ForegroundColor White
        Write-Host "마지막 실행: $($task.LastRunTime)" -ForegroundColor White
        Write-Host "다음 실행: $($task.NextRunTime)" -ForegroundColor White
        Write-Host "활성화됨: $($task.Settings.Enabled)" -ForegroundColor White
        
        # 트리거 정보
        Write-Host "`n=== 트리거 정보 ===" -ForegroundColor Cyan
        foreach ($trigger in $task.Triggers) {
            Write-Host "트리거: $($trigger.GetType().Name)" -ForegroundColor White
            if ($trigger.Repetition) {
                Write-Host "  반복 간격: $($trigger.Repetition.Interval)" -ForegroundColor Gray
                Write-Host "  지속 시간: $($trigger.Repetition.Duration)" -ForegroundColor Gray
            }
        }
        
        # 액션 정보
        Write-Host "`n=== 액션 정보 ===" -ForegroundColor Cyan
        foreach ($action in $task.Actions) {
            Write-Host "실행: $($action.Execute)" -ForegroundColor White
            Write-Host "인수: $($action.Arguments)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "❌ 작업을 찾을 수 없습니다: $TaskName" -ForegroundColor Red
        Write-Host "작업이 등록되어 있지 않거나 이름이 다릅니다." -ForegroundColor Yellow
    }
}

function Start-Task {
    """작업을 시작합니다."""
    try {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "✅ 작업이 시작되었습니다: $TaskName" -ForegroundColor Green
        Show-TaskStatus
    }
    catch {
        Write-Host "❌ 작업 시작 실패: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-Task {
    """작업을 중지합니다."""
    try {
        Stop-ScheduledTask -TaskName $TaskName
        Write-Host "✅ 작업이 중지되었습니다: $TaskName" -ForegroundColor Green
        Show-TaskStatus
    }
    catch {
        Write-Host "❌ 작업 중지 실패: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-Task {
    """작업을 제거합니다."""
    try {
        Write-Host "작업을 제거하시겠습니까? (y/N): " -ForegroundColor Yellow -NoNewline
        $response = Read-Host
        if ($response -eq 'y' -or $response -eq 'Y') {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "✅ 작업이 제거되었습니다: $TaskName" -ForegroundColor Green
        }
        else {
            Write-Host "작업 제거가 취소되었습니다." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ 작업 제거 실패: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Create-Task {
    """새로운 작업을 생성합니다."""
    try {
        Write-Host "새로운 작업을 생성합니다..." -ForegroundColor Cyan
        
        # 기존 작업이 있는지 확인
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "기존 작업이 발견되었습니다. 제거하시겠습니까? (y/N): " -ForegroundColor Yellow -NoNewline
            $response = Read-Host
            if ($response -eq 'y' -or $response -eq 'Y') {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
                Write-Host "기존 작업이 제거되었습니다." -ForegroundColor Green
            }
            else {
                Write-Host "작업 생성이 취소되었습니다." -ForegroundColor Yellow
                return
            }
        }
        
        # register_usb_clean_task.ps1 스크립트 실행
        $scriptPath = Join-Path $PSScriptRoot "register_usb_clean_task.ps1"
        if (Test-Path $scriptPath) {
            & $scriptPath -TaskName $TaskName
        }
        else {
            Write-Host "❌ register_usb_clean_task.ps1 파일을 찾을 수 없습니다." -ForegroundColor Red
            Write-Host "프로젝트 디렉토리에서 실행하세요." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ 작업 생성 실패: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Help {
    """도움말을 표시합니다."""
    Write-Host "=== Mac OS 불필요 파일 정리 작업 관리 도구 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "사용법:" -ForegroundColor Yellow
    Write-Host "  .\manage_task.ps1 <액션> [-TaskName <작업이름>]" -ForegroundColor White
    Write-Host ""
    Write-Host "액션:" -ForegroundColor Yellow
    Write-Host "  status  - 작업 상태 확인" -ForegroundColor White
    Write-Host "  start   - 작업 시작" -ForegroundColor White
    Write-Host "  stop    - 작업 중지" -ForegroundColor White
    Write-Host "  remove  - 작업 제거" -ForegroundColor White
    Write-Host "  create  - 새 작업 생성" -ForegroundColor White
    Write-Host ""
    Write-Host "예시:" -ForegroundColor Yellow
    Write-Host "  .\manage_task.ps1 status" -ForegroundColor White
    Write-Host "  .\manage_task.ps1 start" -ForegroundColor White
    Write-Host "  .\manage_task.ps1 stop" -ForegroundColor White
    Write-Host "  .\manage_task.ps1 remove" -ForegroundColor White
    Write-Host "  .\manage_task.ps1 create" -ForegroundColor White
    Write-Host ""
    Write-Host "고급 사용법:" -ForegroundColor Yellow
    Write-Host "  .\manage_task.ps1 status -TaskName MyCustomTask" -ForegroundColor White
}

# 메인 실행 부분
switch ($Action.ToLower()) {
    "status" {
        Show-TaskStatus
    }
    "start" {
        Start-Task
    }
    "stop" {
        Stop-Task
    }
    "remove" {
        Remove-Task
    }
    "create" {
        Create-Task
    }
    default {
        Show-Help
    }
} 