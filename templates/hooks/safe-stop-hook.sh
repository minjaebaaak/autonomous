#!/bin/bash
# safe-stop-hook.sh — Ralph Loop 안전장치 v3.0 (exit 2 + 자동 리셋)
# autonomous v4.7
#
# 기능:
#   1. 최대 반복 횟수 제한 (기본: 50회)
#   2. 타임아웃 제한 (기본: 60분)
#   3. 긴급 중단 메커니즘 (EMERGENCY_STOP)
#   4. 파일 잠금으로 경쟁 조건 방지
#   5. 로그 파일 자동 로테이션
#   6. 완료된 세션 자동 리셋 (v3.0)
#   7. exit 2로 autonomous 연속 실행 보장 (v3.0)
#
# Stop 훅 exit code 규약:
#   exit 0 = 멈춤 허용 (Claude 사용자 입력 대기)
#   exit 2 = 멈춤 차단 (Claude 자동으로 다음 턴 시작)
#
# 사용법:
#   .claude/hooks/safe-stop-hook.sh [max_iterations] [timeout_minutes]
#
# 긴급 중단:
#   touch ~/.claude/state/EMERGENCY_STOP

set -e

# 설정
STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/stop-hook-state.json"
LOG_FILE="${STATE_DIR}/stop-hook.log"
LOCK_FILE="${STATE_DIR}/stop-hook.lock"
KILL_SWITCH="${STATE_DIR}/EMERGENCY_STOP"
AUTONOMOUS_MODE="${STATE_DIR}/AUTONOMOUS_MODE"
MAX_ITERATIONS=${1:-50}
TIMEOUT_MINUTES=${2:-60}
MAX_LOG_SIZE_KB=1024

mkdir -p "$STATE_DIR"

# macOS/Linux 호환 날짜
get_iso_date() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo "$1"
}

cleanup() {
    local exit_code=$?
    rm -f "$LOCK_FILE"
    # exit 2 = 정상 (autonomous 연속 실행 신호)
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 2 ]; then
        log "비정상 종료 (exit code: $exit_code)"
    fi
}
trap cleanup EXIT

# 긴급 중단 체크
check_kill_switch() {
    if [ -f "$KILL_SWITCH" ]; then
        log "긴급 중단: EMERGENCY_STOP 파일 감지"
        rm -f "$KILL_SWITCH"
        echo ""
        echo "========================================"
        echo " 긴급 중단 (EMERGENCY STOP)"
        echo "========================================"
        exit 0
    fi
}

# 파일 잠금
acquire_lock() {
    local max_wait=10
    local waited=0
    while [ -f "$LOCK_FILE" ] && [ $waited -lt $max_wait ]; do
        sleep 0.5
        waited=$((waited + 1))
    done
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# 로그 로테이션
rotate_log_if_needed() {
    if [ -f "$LOG_FILE" ]; then
        local size_kb=$(du -k "$LOG_FILE" | cut -f1)
        if [ "$size_kb" -gt "$MAX_LOG_SIZE_KB" ]; then
            tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp"
            mv "${LOG_FILE}.tmp" "$LOG_FILE"
        fi
    fi
}

# 상태 초기화/로드 (v3.0: 완료된 세션 자동 리셋)
init_or_load_state() {
    if [ -f "$STATE_FILE" ]; then
        local prev_status
        if command -v jq &> /dev/null; then
            prev_status=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        else
            prev_status=$(grep -o '"status": "[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || echo "unknown")
        fi
        if [ "$prev_status" = "completed" ] || [ "$prev_status" = "errored" ]; then
            log "이전 세션($prev_status) 감지 → 새 세션 초기화"
            rm -f "$STATE_FILE"
        fi
    fi

    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << EOF
{
    "iteration": 0,
    "start_time": $(date +%s),
    "max_iterations": $MAX_ITERATIONS,
    "timeout_minutes": $TIMEOUT_MINUTES,
    "status": "running",
    "last_update": "$(get_iso_date)",
    "version": "3.0"
}
EOF
        log "Stop Hook 세션 시작 (최대 ${MAX_ITERATIONS}회, ${TIMEOUT_MINUTES}분)"
    fi
}

get_iteration() {
    if command -v jq &> /dev/null; then
        jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null || echo "0"
    else
        grep -o '"iteration": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0"
    fi
}

get_start_time() {
    if command -v jq &> /dev/null; then
        jq -r '.start_time // 0' "$STATE_FILE" 2>/dev/null || echo "$(date +%s)"
    else
        grep -o '"start_time": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "$(date +%s)"
    fi
}

increment_iteration() {
    local current=$(get_iteration)
    local new_count=$((current + 1))
    if command -v jq &> /dev/null; then
        local tmp=$(mktemp)
        jq ".iteration = $new_count | .last_update = \"$(get_iso_date)\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/\"iteration\": [0-9]*/\"iteration\": $new_count/" "$STATE_FILE"
        else
            sed -i "s/\"iteration\": [0-9]*/\"iteration\": $new_count/" "$STATE_FILE"
        fi
    fi
    echo "$new_count"
}

check_timeout() {
    local start_time=$(get_start_time)
    local current_time=$(date +%s)
    local elapsed_minutes=$(( (current_time - start_time) / 60 ))
    if [ "$elapsed_minutes" -ge "$TIMEOUT_MINUTES" ]; then
        return 1
    fi
    return 0
}

end_session() {
    local reason="$1"
    if command -v jq &> /dev/null; then
        local tmp=$(mktemp)
        jq ".status = \"completed\" | .end_reason = \"$reason\" | .end_time = \"$(get_iso_date)\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
    rm -f "$AUTONOMOUS_MODE"
    rm -f "${STATE_DIR}/PHASE0_COMPLETE"
    release_lock
    log "세션 종료: $reason"
    echo ""
    echo "========================================"
    echo " 자율 모드 종료: $reason"
    echo "========================================"
    exit 0  # 멈춤 허용 — 세션 종료 시에만
}

# 메인
main() {
    # 자율 모드가 아니면 조용히 종료
    if [ ! -f "$AUTONOMOUS_MODE" ]; then
        exit 0
    fi

    check_kill_switch
    acquire_lock
    rotate_log_if_needed
    init_or_load_state

    local iteration=$(increment_iteration)
    log "반복 #${iteration}/${MAX_ITERATIONS}"

    if [ "$iteration" -ge "$MAX_ITERATIONS" ]; then
        end_session "최대 반복 횟수 도달 (${MAX_ITERATIONS}회)"
    fi

    if ! check_timeout; then
        end_session "타임아웃"
    fi

    release_lock

    # exit 2: Claude의 멈춤을 차단하여 autonomous 연속 실행
    local remaining=$((MAX_ITERATIONS - iteration))
    local start_time=$(get_start_time)
    local elapsed=$(( ($(date +%s) - start_time) / 60 ))
    local time_remaining=$((TIMEOUT_MINUTES - elapsed))

    echo "Stop Hook v3.0 | 반복: ${iteration}/${MAX_ITERATIONS} (남은: ${remaining}) | 시간: ${elapsed}분/${TIMEOUT_MINUTES}분 | 계속 진행해주세요." >&2
    exit 2
}

main "$@"
