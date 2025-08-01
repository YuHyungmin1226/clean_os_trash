import os
import sys
import shutil
import logging
import json
import argparse
from pathlib import Path
from typing import List, Tuple, Dict, Any
from logging.handlers import RotatingFileHandler

# 기본 설정
DEFAULT_CONFIG = {
    "trash_files": ['.DS_Store', '._*', '.Spotlight-V100', '.Trashes', '.fseventsd'],
    "logging": {
        "level": "INFO",
        "file": "clean_mac_trash.log",
        "max_size_mb": 10,
        "backup_count": 5
    },
    "safety": {
        "confirm_deletion": True,
        "dry_run_by_default": False,
        "backup_before_delete": False,
        "backup_dir": "backup"
    },
    "exclude_patterns": [
        "System Volume Information",
        "$RECYCLE.BIN",
        "Windows",
        "Program Files",
        "Program Files (x86)"
    ]
}

def load_config(config_path: str = None) -> Dict[str, Any]:
    """설정 파일을 로드합니다."""
    if config_path is None:
        config_path = os.path.join(os.path.dirname(__file__), "config.json")
    
    try:
        if os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                # 기본값과 병합
                merged_config = DEFAULT_CONFIG.copy()
                merged_config.update(config)
                return merged_config
        else:
            print(f"설정 파일을 찾을 수 없습니다: {config_path}")
            print("기본 설정을 사용합니다.")
            return DEFAULT_CONFIG
    except Exception as e:
        print(f"설정 파일 로드 중 오류 발생: {e}")
        print("기본 설정을 사용합니다.")
        return DEFAULT_CONFIG

def setup_logging(config: Dict[str, Any]) -> logging.Logger:
    """로깅을 설정합니다."""
    log_config = config["logging"]
    log_level = getattr(logging, log_config["level"].upper(), logging.INFO)
    
    # 로거 생성
    logger = logging.getLogger(__name__)
    logger.setLevel(log_level)
    
    # 기존 핸들러 제거
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # 파일 핸들러 (로테이션)
    log_file = log_config["file"]
    max_bytes = log_config["max_size_mb"] * 1024 * 1024
    backup_count = log_config["backup_count"]
    
    file_handler = RotatingFileHandler(
        log_file, 
        maxBytes=max_bytes, 
        backupCount=backup_count,
        encoding='utf-8'
    )
    file_handler.setLevel(log_level)
    
    # 콘솔 핸들러
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)
    
    # 포맷터
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    # 핸들러 추가
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

def is_trash(filename: str, trash_patterns: List[str]) -> bool:
    """파일명이 Mac OS 불필요 파일인지 확인"""
    for pattern in trash_patterns:
        if pattern.endswith('*'):
            if filename.startswith(pattern[:-1]):
                return True
        elif filename == pattern:
            return True
    return False

def should_exclude(path: str, exclude_patterns: List[str]) -> bool:
    """경로가 제외 패턴에 해당하는지 확인"""
    path_lower = path.lower()
    for pattern in exclude_patterns:
        if pattern.lower() in path_lower:
            return True
    return False

def validate_path(path: str) -> bool:
    """경로가 존재하고 접근 가능한지 확인"""
    try:
        path_obj = Path(path)
        return path_obj.exists() and path_obj.is_dir()
    except Exception as e:
        return False

def backup_file(file_path: str, backup_dir: str) -> bool:
    """파일을 백업합니다."""
    try:
        # 백업 디렉토리가 없으면 생성
        os.makedirs(backup_dir, exist_ok=True)
        
        # 파일명만 사용하여 백업 파일 경로 생성
        filename = os.path.basename(file_path)
        backup_path = os.path.join(backup_dir, filename)
        
        # 파일이 이미 존재하면 번호를 붙여서 저장
        counter = 1
        original_backup_path = backup_path
        while os.path.exists(backup_path):
            name, ext = os.path.splitext(original_backup_path)
            backup_path = f"{name}_{counter}{ext}"
            counter += 1
        
        # 파일 복사
        shutil.copy2(file_path, backup_path)
        return True
    except Exception as e:
        return False

def get_trash_items(root_dir: str, config: Dict[str, Any]) -> Tuple[List[str], List[str]]:
    """삭제할 파일과 폴더 목록을 수집"""
    files_to_remove = []
    dirs_to_remove = []
    trash_patterns = config["trash_files"]
    exclude_patterns = config["exclude_patterns"]
    
    try:
        for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
            # 제외 패턴 확인
            if should_exclude(dirpath, exclude_patterns):
                continue
            
            # 파일 검사
            for filename in filenames:
                if is_trash(filename, trash_patterns):
                    file_path = os.path.join(dirpath, filename)
                    files_to_remove.append(file_path)
            
            # 폴더 검사 (topdown=False로 하위부터 처리)
            for dirname in dirnames:
                if is_trash(dirname, trash_patterns):
                    dir_path = os.path.join(dirpath, dirname)
                    dirs_to_remove.append(dir_path)
    except Exception as e:
        # logger가 정의되지 않은 경우를 대비해 print 사용
        print(f"파일/폴더 검색 중 오류 발생: {e}")
    
    return files_to_remove, dirs_to_remove

def clean_mac_trash(root_dir: str, config: Dict[str, Any], dry_run: bool = False, confirm: bool = True, logger=None) -> List[str]:
    """Mac OS 불필요 파일들을 정리"""
    removed = []
    safety_config = config["safety"]
    
    # logger가 없으면 기본 로거 사용
    if logger is None:
        logger = logging.getLogger(__name__)
        if not logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            logger.setLevel(logging.INFO)
    
    # 경로 검증
    if not validate_path(root_dir):
        logger.error(f"유효하지 않은 경로입니다: {root_dir}")
        return removed
    
    logger.info(f"정리 시작: {root_dir}")
    
    # 삭제할 항목들 수집
    files_to_remove, dirs_to_remove = get_trash_items(root_dir, config)
    
    total_items = len(files_to_remove) + len(dirs_to_remove)
    if total_items == 0:
        logger.info("삭제할 항목이 없습니다.")
        return removed
    
    logger.info(f"발견된 항목: 파일 {len(files_to_remove)}개, 폴더 {len(dirs_to_remove)}개")
    
    # 백업 설정
    backup_enabled = safety_config["backup_before_delete"] and not dry_run
    backup_dir = os.path.abspath(safety_config["backup_dir"])
    
    if backup_enabled:
        logger.info(f"백업 디렉토리: {backup_dir}")
        os.makedirs(backup_dir, exist_ok=True)
    
    # 삭제 전 확인
    if confirm and not dry_run and safety_config["confirm_deletion"]:
        print(f"\n총 {total_items}개의 항목을 삭제하시겠습니까? (y/N): ", end="")
        response = input().strip().lower()
        if response not in ['y', 'yes']:
            logger.info("사용자가 삭제를 취소했습니다.")
            return removed
    
    # 파일 삭제
    for file_path in files_to_remove:
        try:
            if backup_enabled:
                if backup_file(file_path, backup_dir):
                    logger.debug(f"백업 완료: {file_path}")
                else:
                    logger.warning(f"백업 실패: {file_path}")
            
            if not dry_run:
                os.remove(file_path)
                logger.info(f"파일 삭제: {file_path}")
            else:
                logger.info(f"[DRY RUN] 파일 삭제 예정: {file_path}")
            removed.append(file_path)
        except Exception as e:
            logger.error(f"파일 삭제 실패: {file_path} - {e}")
    
    # 폴더 삭제 (하위부터 처리)
    for dir_path in dirs_to_remove:
        try:
            if not dry_run:
                shutil.rmtree(dir_path)
                logger.info(f"폴더 삭제: {dir_path}")
            else:
                logger.info(f"[DRY RUN] 폴더 삭제 예정: {dir_path}")
            removed.append(dir_path)
        except Exception as e:
            logger.error(f"폴더 삭제 실패: {dir_path} - {e}")
    
    logger.info(f"정리 완료: {len(removed)}개 항목 처리됨")
    return removed

def main():
    """메인 함수"""
    parser = argparse.ArgumentParser(description='Mac OS 불필요 파일 정리 도구')
    parser.add_argument('target', help='정리할 대상 폴더 경로')
    parser.add_argument('--config', '-c', help='설정 파일 경로')
    parser.add_argument('--dry-run', action='store_true', help='실제 삭제하지 않고 미리보기만 실행')
    parser.add_argument('--no-confirm', action='store_true', help='삭제 전 확인 메시지 건너뛰기')
    parser.add_argument('--verbose', '-v', action='store_true', help='상세한 로그 출력')
    
    args = parser.parse_args()
    
    # 설정 로드
    config = load_config(args.config)
    
    # 로깅 설정
    logger = setup_logging(config)
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    if args.dry_run:
        logger.info("DRY RUN 모드로 실행됩니다. 실제로는 삭제되지 않습니다.")
    
    removed = clean_mac_trash(
        args.target, 
        config,
        dry_run=args.dry_run, 
        confirm=not args.no_confirm,
        logger=logger
    )
    
    if removed:
        print(f"\n처리된 항목: {len(removed)}개")
        for path in removed:
            print(f"  - {path}")

if __name__ == "__main__":
    main()
