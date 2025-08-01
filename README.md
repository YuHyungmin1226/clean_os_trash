# clean_os_trash

이 프로젝트는 Windows 환경에서 USB 드라이브가 연결될 때 Mac OS에서 생성되는 불필요한 파일(.DS_Store, ._*, .Spotlight-V100, .Trashes, .fseventsd 등)을 자동으로 찾아 삭제하는 도구입니다.

## 주요 파일
- `clean_mac_trash.py`: 지정한 폴더(USB 포함)에서 Mac OS 불필요 파일을 찾아 삭제하는 파이썬 스크립트
- `register_usb_clean_task.ps1`: Windows 작업 스케줄러에 등록하여 USB 연결 시 자동으로 정리 스크립트가 실행되도록 하는 PowerShell 스크립트
- `requirements.txt`: (필요시) 파이썬 의존성 관리 파일

## 사용 방법

### 1. 파이썬 스크립트 수동 실행
```
python clean_mac_trash.py <USB_드라이브_경로>
```


### 2. USB 연결 시 자동 실행 설정
1. PowerShell을 "관리자 권한"으로 실행
2. 아래 명령어 실행
```
powershell -ExecutionPolicy Bypass -File register_usb_clean_task.ps1
```
3. 1분마다 USB 드라이브를 자동 감지하여 정리 스크립트가 실행됩니다.
   (Windows 작업 스케줄러에 등록되어 백그라운드로 동작)

## 참고 사항
- Python이 시스템 PATH에 등록되어 있어야 합니다.
- PowerShell 스크립트는 관리자 권한이 필요합니다.
- 자동화는 1분 간격으로 USB 드라이브를 감지하여 동작합니다.
- PowerShell 스크립트는 Windows 10/11에서 정상 동작하도록 수정되었습니다.

## 라이선스
MIT License
