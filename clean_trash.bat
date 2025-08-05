@echo off
chcp 65001 >nul
title Mac OS 불필요 파일 정리 도구

echo ========================================
echo    Mac OS 불필요 파일 정리 도구
echo ========================================
echo.

if "%1"=="" (
    echo 사용법:
    echo   clean_trash.bat [옵션]
    echo.
    echo 옵션:
    echo   --help          도움말 표시
    echo   --list-drives   처리할 드라이브 목록 표시
    echo   --dry-run       실제 삭제하지 않고 미리보기만 실행
    echo   --all-drives    모든 드라이브에서 정리 실행
    echo   --no-confirm    확인 없이 실행
    echo   --verbose       상세 로그 출력
    echo.
    echo 예시:
    echo   clean_trash.bat --list-drives
    echo   clean_trash.bat --dry-run --verbose
    echo   clean_trash.bat --all-drives --no-confirm
    echo.
    pause
    exit /b
)

echo 실행 중: CleanMacTrash.exe %*
echo.

CleanMacTrash.exe %*

echo.
echo 작업이 완료되었습니다.
pause 