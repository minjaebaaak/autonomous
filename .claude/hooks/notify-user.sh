#!/bin/bash
# macOS 시스템 노티피케이션 스크립트
# v1.0 (198차 QA)
#
# 용도: Claude Code에서 사용자 인풋이 필요할 때 알림
# 사용법: .claude/hooks/notify-user.sh "메시지" "제목"

MESSAGE="${1:-Claude Code에서 입력을 기다리고 있습니다}"
TITLE="${2:-Claude Code}"
SOUND="${3:-Ping}"

# macOS 알림
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\"" 2>/dev/null || true
fi

# Linux (notify-send)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v notify-send &> /dev/null; then
        notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
    fi
fi

# 터미널 벨 사운드 (fallback)
echo -e "\a"

# 로그 기록
LOG_FILE="$HOME/.claude/state/notify-user.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $TITLE: $MESSAGE" >> "$LOG_FILE"

# 로그 파일 크기 제한 (50KB)
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat --format=%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [[ $LOG_SIZE -gt 51200 ]]; then
        tail -n 50 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
fi

exit 0
