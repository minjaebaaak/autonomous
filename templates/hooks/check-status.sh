#!/bin/bash
# ==============================================================================
# Stop Hook 상태 확인 유틸리티
# ==============================================================================
# 목적: safe-stop-hook 현재 상태 확인 + 디버깅
#
# 설치:
#   cp templates/hooks/check-status.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/check-status.sh
#   # 수동 실행: .claude/hooks/check-status.sh
# ==============================================================================

STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/stop-hook-state.json"
LOG_FILE="${STATE_DIR}/stop-hook.log"
LOCK_FILE="${STATE_DIR}/stop-hook.lock"
KILL_SWITCH="${STATE_DIR}/EMERGENCY_STOP"

echo "========================================"
echo " Stop Hook 안전장치 상태 확인"
echo "========================================"

# 긴급 중단 파일 체크
if [ -f "$KILL_SWITCH" ]; then
    echo ""
    echo " [경고] EMERGENCY_STOP 파일 존재!"
    echo "        다음 실행 시 즉시 중단됩니다."
    echo ""
fi

# 잠금 파일 체크
if [ -f "$LOCK_FILE" ]; then
    echo " [주의] 잠금 파일 존재 (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo "?"))"
fi

# 상태 파일 체크
if [ ! -f "$STATE_FILE" ]; then
    echo ""
    echo " 상태: 세션 없음 (새로운 세션 시작 가능)"
    echo "========================================"
    echo ""
    echo "사용법:"
    echo "  - 새 세션 시작: Claude에게 작업 지시"
    echo "  - 긴급 중단 설정: touch ~/.claude/state/EMERGENCY_STOP"
    echo ""
    exit 0
fi

# 상태 파일 내용 출력
echo ""
echo "현재 세션 상태:"
echo "----------------------------------------"

if command -v jq &> /dev/null; then
    # jq로 예쁘게 출력
    iteration=$(jq -r '.iteration // 0' "$STATE_FILE")
    max_iter=$(jq -r '.max_iterations // 50' "$STATE_FILE")
    start_time=$(jq -r '.start_time // 0' "$STATE_FILE")
    timeout=$(jq -r '.timeout_minutes // 60' "$STATE_FILE")
    status=$(jq -r '.status // "unknown"' "$STATE_FILE")
    version=$(jq -r '.version // "1.0"' "$STATE_FILE")

    current_time=$(date +%s)
    elapsed=$(( (current_time - start_time) / 60 ))
    remaining_iter=$((max_iter - iteration))
    remaining_time=$((timeout - elapsed))

    echo " 버전: v${version}"
    echo " 반복: ${iteration}/${max_iter} (남은 횟수: ${remaining_iter})"
    echo " 시간: ${elapsed}분 경과 (남은 시간: ${remaining_time}분)"
    echo " 상태: ${status}"
else
    cat "$STATE_FILE"
fi

echo "----------------------------------------"
echo ""
echo "최근 로그 (마지막 10줄):"
echo "----------------------------------------"
if [ -f "$LOG_FILE" ]; then
    tail -10 "$LOG_FILE"
else
    echo "(로그 없음)"
fi
echo "----------------------------------------"
echo ""
echo "명령어:"
echo "  - 세션 리셋: .claude/hooks/reset-session.sh"
echo "  - 긴급 중단: touch ~/.claude/state/EMERGENCY_STOP"
echo ""
