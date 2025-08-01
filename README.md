# clean_os_trash

이 프로젝트는 Windows 환경에서 USB 드라이브가 연결될 때 Mac OS에서 생성되는 불필요한 파일(.DS_Store, ._*, .Spotlight-V100, .Trashes, .fseventsd 등)을 자동으로 찾아 삭제하는 도구입니다.

## ✨ 주요 기능

- **자동 USB 감지**: USB 드라이브 연결 시 자동으로 불필요 파일 정리
- **안전한 삭제**: 삭제 전 확인, 백업 기능, 드라이 런 모드 지원
- **설정 가능**: JSON 설정 파일을 통한 세밀한 제어
- **로깅 시스템**: 상세한 로그 기록 및 로테이션
- **제외 패턴**: 시스템 폴더 등 중요 디렉토리 자동 제외
- **중복 실행 방지**: 동일한 드라이브에 대한 중복 처리 방지

## 📁 주요 파일

- `clean_mac_trash.py`: Mac OS 불필요 파일을 찾아 삭제하는 메인 파이썬 스크립트
- `register_usb_clean_task.ps1`: Windows 작업 스케줄러에 자동 실행 작업을 등록하는 PowerShell 스크립트
- `config.json`: 설정 파일 (삭제할 파일 패턴, 로그 설정, 안전 옵션 등)
- `test_clean_mac_trash.py`: 단위 테스트 파일
- `requirements.txt`: 파이썬 의존성 관리 파일

## 🚀 사용 방법

### 1. 수동 실행

#### 기본 사용법
```bash
python clean_mac_trash.py <대상_폴더_경로>
```

#### 고급 옵션
```bash
# 드라이 런 모드 (실제 삭제하지 않고 미리보기만)
python clean_mac_trash.py <경로> --dry-run

# 확인 메시지 건너뛰기
python clean_mac_trash.py <경로> --no-confirm

# 상세한 로그 출력
python clean_mac_trash.py <경로> --verbose

# 사용자 정의 설정 파일 사용
python clean_mac_trash.py <경로> --config my_config.json
```

### 2. USB 연결 시 자동 실행 설정

1. **PowerShell을 "관리자 권한"으로 실행**
2. **프로젝트 디렉토리로 이동**
3. **자동화 스크립트 실행**
```powershell
powershell -ExecutionPolicy Bypass -File register_usb_clean_task.ps1
```

#### 고급 설정 옵션
```powershell
# 사용자 정의 간격으로 설정 (기본값: 1분)
powershell -ExecutionPolicy Bypass -File register_usb_clean_task.ps1 -CheckInterval 5

# 사용자 정의 작업 이름으로 설정
powershell -ExecutionPolicy Bypass -File register_usb_clean_task.ps1 -TaskName "MyUSBCleaner"
```

## ⚙️ 설정 파일 (config.json)

```json
{
    "trash_files": [
        ".DS_Store",
        "._*",
        ".Spotlight-V100",
        ".Trashes",
        ".fseventsd",
        "Thumbs.db",
        "desktop.ini"
    ],
    "logging": {
        "level": "INFO",
        "file": "clean_mac_trash.log",
        "max_size_mb": 10,
        "backup_count": 5
    },
    "safety": {
        "confirm_deletion": true,
        "dry_run_by_default": false,
        "backup_before_delete": false,
        "backup_dir": "backup"
    },
    "exclude_patterns": [
        "System Volume Information",
        "$RECYCLE.BIN",
        "Windows",
        "Program Files"
    ]
}
```

### 설정 옵션 설명

- **trash_files**: 삭제할 파일 패턴 목록
- **logging**: 로그 설정 (레벨, 파일명, 크기 제한 등)
- **safety**: 안전 옵션 (확인 메시지, 백업 등)
- **exclude_patterns**: 제외할 디렉토리 패턴

## 🧪 테스트

단위 테스트를 실행하려면:

```bash
python test_clean_mac_trash.py
```

또는 pytest를 사용:

```bash
pytest test_clean_mac_trash.py -v
```

## 📋 작업 관리 명령어

### 작업 상태 확인
```powershell
Get-ScheduledTask -TaskName "CleanMacTrashOnUSB"
```

### 작업 중지
```powershell
Stop-ScheduledTask -TaskName "CleanMacTrashOnUSB"
```

### 작업 시작
```powershell
Start-ScheduledTask -TaskName "CleanMacTrashOnUSB"
```

### 작업 제거
```powershell
Unregister-ScheduledTask -TaskName "CleanMacTrashOnUSB"
```

## 🔧 고급 기능

### 백업 기능
설정 파일에서 `"backup_before_delete": true`로 설정하면 삭제 전에 파일을 백업합니다.

### 로그 로테이션
로그 파일이 지정된 크기를 초과하면 자동으로 백업되고 새로운 로그 파일이 생성됩니다.

### 중복 실행 방지
동일한 USB 드라이브에 대해 5분 이내에 중복 실행을 방지합니다.

### 제외 패턴
시스템 폴더나 중요한 디렉토리는 자동으로 제외됩니다.

## ⚠️ 주의사항

- **Python이 시스템 PATH에 등록되어 있어야 합니다.**
- **PowerShell 스크립트는 관리자 권한이 필요합니다.**
- **자동화는 기본적으로 1분 간격으로 USB 드라이브를 감지합니다.**
- **삭제 전에 반드시 확인하거나 백업을 활성화하세요.**
- **중요한 파일이 포함된 디렉토리는 제외 패턴에 추가하세요.**

## 🐛 문제 해결

### Python을 찾을 수 없는 경우
```powershell
# Python 설치 확인
python --version

# PATH에 Python이 등록되어 있는지 확인
where python
```

### 권한 오류가 발생하는 경우
- PowerShell을 관리자 권한으로 실행하세요.
- 작업 스케줄러에서 작업이 "최고 수준 권한으로 실행"으로 설정되어 있는지 확인하세요.

### 로그 확인
- 로그 파일: `clean_mac_trash.log`
- USB 정리 로그: `%TEMP%\usb_clean_*.log`

## 📄 라이선스

MIT License

## 🤝 기여하기

1. 이슈를 생성하거나 기존 이슈를 확인하세요.
2. 기능 추가나 버그 수정을 위한 풀 리퀘스트를 보내주세요.
3. 테스트 코드를 포함해주세요.
