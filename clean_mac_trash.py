import os

# Mac OS에서 생성되는 불필요한 파일 목록
TRASH_FILES = ['.DS_Store', '._*', '.Spotlight-V100', '.Trashes', '.fseventsd']

def is_trash(filename):
    for pattern in TRASH_FILES:
        if pattern.endswith('*'):
            if filename.startswith(pattern[:-1]):
                return True
        elif filename == pattern:
            return True
    return False

def clean_mac_trash(root_dir):
    removed = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # 파일 삭제
        for filename in filenames:
            if is_trash(filename):
                file_path = os.path.join(dirpath, filename)
                try:
                    os.remove(file_path)
                    removed.append(file_path)
                except Exception as e:
                    print(f"Failed to remove {file_path}: {e}")
        # 폴더 삭제
        for dirname in list(dirnames):
            if is_trash(dirname):
                dir_path = os.path.join(dirpath, dirname)
                try:
                    os.rmdir(dir_path)
                    removed.append(dir_path)
                    dirnames.remove(dirname)
                except Exception as e:
                    print(f"Failed to remove {dir_path}: {e}")
    return removed

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("사용법: python clean_mac_trash.py <대상_폴더>")
        sys.exit(1)
    target = sys.argv[1]
    removed = clean_mac_trash(target)
    print(f"삭제된 파일/폴더: {len(removed)}개")
    for path in removed:
        print(path)
