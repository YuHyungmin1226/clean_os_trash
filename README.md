# Mac OS 불필요 파일 정리 도구

Windows에서 Mac OS 관련 불필요한 파일들을 정리하는 도구입니다.

## 주요 기능

- **Mac OS 관련 파일 정리**:
  - `.DS_Store` (Mac OS 폴더 뷰 설정 파일)
  - `._*` (Mac OS 리소스 포크 파일)
  - `.Spotlight-V100` (Spotlight 검색 인덱스)
  - `.Trashes` (Mac 휴지통)
  - `.fseventsd` (파일 시스템 이벤트)

- **Windows 관련 파일 정리**:
  - `desktop.ini` (Windows 폴더 설정)
  - `Thumbs.db` (Windows 썸네일 캐시)

- **다중 드라이브 지원**: 모든 연결된 외장 드라이브에서 자동 정리
- **안전 기능**: Dry-run 모드, 백업 옵션, 확인 메시지

## 사용법

### 1. 실행 파일 사용 (권장)

#### 기본 사용법
```cmd
# 도움말 보기
CleanMacTrash.exe --help

# 연결된 드라이브 목록 확인
CleanMacTrash.exe --list-drives

# Dry-run으로 미리보기
CleanMacTrash.exe --dry-run --verbose

# 모든 드라이브에서 정리 실행
CleanMacTrash.exe --all-drives

# 확인 없이 모든 드라이브 정리
CleanMacTrash.exe --all-drives --no-confirm
```

#### 특정 폴더 정리
```cmd
# 특정 폴더만 정리
CleanMacTrash.exe "C:\Users\사용자명\Desktop"

# 특정 드라이브만 정리
CleanMacTrash.exe "E:\"
```

### 2. 배치 파일 사용 (더 간단)

```cmd
# 도움말 보기
clean_trash.bat

# 드라이브 목록 확인
clean_trash.bat --list-drives

# Dry-run으로 미리보기
clean_trash.bat --dry-run --verbose

# 모든 드라이브 정리
clean_trash.bat --all-drives --no-confirm
```

## 명령줄 옵션

| 옵션 | 설명 |
|------|------|
| `--help` | 도움말 표시 |
| `--list-drives` | 처리할 드라이브 목록만 표시 |
| `--dry-run` | 실제 삭제하지 않고 미리보기만 실행 |
| `--no-confirm` | 삭제 전 확인 메시지 건너뛰기 |
| `--verbose` | 상세한 로그 출력 |
| `--all-drives` | 모든 연결된 드라이브에서 정리 실행 |
| `--config CONFIG` | 설정 파일 경로 지정 |

## 설정 파일

`config.json` 파일을 통해 정리할 파일 패턴과 안전 설정을 커스터마이즈할 수 있습니다.

```json
{
    "trash_files": [".DS_Store", "._*", ".Spotlight-V100", ".Trashes", ".fseventsd"],
    "exclude_patterns": ["System Volume Information", "$RECYCLE.BIN"],
    "safety": {
        "confirm_deletion": true,
        "backup_before_delete": false
    }
}
```

## 안전 주의사항

1. **Dry-run 먼저 실행**: 실제 삭제 전에 `--dry-run` 옵션으로 확인
2. **중요 파일 백업**: 필요한 경우 `--backup-before-delete` 옵션 사용
3. **시스템 드라이브 주의**: C: 드라이브는 기본적으로 제외됨

## 빌드된 파일

- `CleanMacTrash.exe`: 단일 실행 파일 (Python 설치 불필요)
- `clean_trash.bat`: 사용하기 쉬운 배치 파일

## 시스템 요구사항

- Windows 10/11
- 관리자 권한 (일부 시스템 파일 삭제 시)

## 로그 파일

정리 작업의 로그는 `clean_mac_trash.log` 파일에 저장됩니다.

## 라이선스

이 도구는 개인 및 상업적 용도로 자유롭게 사용할 수 있습니다.
