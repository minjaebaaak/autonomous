#!/bin/bash
# PostToolUse Hook - Write/Edit 후 자동 포맷팅
# v1.0 (198차 QA)
#
# 용도: 코드 작성 후 자동으로 prettier + eslint 실행
# 효과: 일관된 코드 스타일 유지, 잠재적 문제 자동 수정

set -e

# 파라미터
TOOL_NAME="$1"
FILE_PATH="$2"

# 로그 파일
LOG_FILE="$HOME/.claude/state/post-tool-format.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Write 또는 Edit 도구일 때만 실행
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# 파일 경로가 없으면 종료
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# 파일이 존재하지 않으면 종료
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# TypeScript/JavaScript 파일만 처리
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx|mjs|cjs)$ ]]; then
    log "포맷팅 시작: $FILE_PATH"

    # Prettier 실행 (설치되어 있는 경우)
    if command -v npx &> /dev/null; then
        if npx prettier --check "$FILE_PATH" 2>/dev/null; then
            log "Prettier: 이미 포맷됨"
        else
            npx prettier --write "$FILE_PATH" 2>/dev/null && log "Prettier: 포맷 완료"
        fi

        # ESLint 실행 (fix 모드)
        npx eslint --fix "$FILE_PATH" 2>/dev/null && log "ESLint: 수정 완료" || true
    fi

    log "포맷팅 완료: $FILE_PATH"
fi

# CSS/SCSS 파일 처리
if [[ "$FILE_PATH" =~ \.(css|scss|sass|less)$ ]]; then
    log "CSS 포맷팅 시작: $FILE_PATH"

    if command -v npx &> /dev/null; then
        npx prettier --write "$FILE_PATH" 2>/dev/null && log "Prettier (CSS): 포맷 완료" || true
    fi
fi

# JSON/YAML 파일 처리
if [[ "$FILE_PATH" =~ \.(json|yaml|yml)$ ]]; then
    log "JSON/YAML 포맷팅 시작: $FILE_PATH"

    if command -v npx &> /dev/null; then
        npx prettier --write "$FILE_PATH" 2>/dev/null && log "Prettier (JSON/YAML): 포맷 완료" || true
    fi
fi

# 로그 파일 크기 제한 (100KB)
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat --format=%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [[ $LOG_SIZE -gt 102400 ]]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

exit 0
