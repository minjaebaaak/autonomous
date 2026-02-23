#!/bin/bash
# ==============================================================================
# Safe Stop Hook - Ralph Loop 안전장치 (v4.2 - CONTEXT_WARNING 연동)
# ==============================================================================
#
# 기능:
#   1. 최대 반복 횟수 제한 (기본: 50회)
#   2. 타임아웃 제한 (기본: 60분)
#   3. 긴급 중단 메커니즘 (kill switch)
#   4. 파일 잠금으로 경쟁 조건 방지
#   5. 로그 파일 자동 로테이션
#   6. 디스크 공간 체크
#   7. macOS/Linux 호환
#   8. 완료된/소진된 세션 자동 리셋 (v4.0)
#   9. exit 2로 autonomous 연속 실행 보장
#  10. rapid-fire 감지 (v4.0) — 연속 빠른 트리거 시 자동 종료
#  11. 좀비 방지 (v4.0) — exhausted 상태로 재생성 차단
#  12. TASK_COMPLETE 신호 (v4.1) — Claude 완료 선언 즉시 감지
#  13. no-tracker fallback (v4.1) — 추적기 없을 때 3회 후 완료 간주
#  14. 연속 exit 2 감지 (v4.1) — 시간 무관 최후 안전망
#
# Stop 훅 exit code 규약:
#   exit 0 = 멈춤 허용 (Claude 사용자 입력 대기)
#   exit 2 = 멈춤 차단 (Claude 자동으로 다음 턴 시작)
#
# 설치:
#   cp templates/hooks/safe-stop-hook.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/safe-stop-hook.sh
#   # settings-local.json의 Stop 훅에 등록
#
# 사용법:
#   .claude/hooks/safe-stop-hook.sh [max_iterations] [timeout_minutes]
#
# 긴급 중단:
#   touch ~/.claude/state/EMERGENCY_STOP
#
# ==============================================================================

# 에러 시 종료
set -e

# 설정 변수
STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/stop-hook-state.json"
LOG_FILE="${STATE_DIR}/stop-hook.log"
LOCK_FILE="${STATE_DIR}/stop-hook.lock"
KILL_SWITCH="${STATE_DIR}/EMERGENCY_STOP"
AUTONOMOUS_MODE="${STATE_DIR}/AUTONOMOUS_MODE"
RAPID_FIRE_FILE="${STATE_DIR}/rapid-fire.json"
TASK_COMPLETE_FILE="${STATE_DIR}/TASK_COMPLETE"
CONTEXT_WARNING_FILE="${STATE_DIR}/CONTEXT_WARNING"
MAX_ITERATIONS=${1:-50}
TIMEOUT_MINUTES=${2:-60}
MAX_LOG_SIZE_KB=1024  # 로그 파일 최대 크기 (1MB)
MIN_DISK_SPACE_MB=100 # 최소 디스크 공간 (100MB)

# v4.0: rapid-fire 감지 설정
RAPID_FIRE_THRESHOLD=5      # 연속 N회 빠른 트리거 시 종료
RAPID_FIRE_WINDOW_SECS=60   # N초 이내를 "빠른 트리거"로 간주

# v4.1: 연속 exit 2 감지 설정 (시간 무관 최후 안전망)
CONSECUTIVE_EXIT2_THRESHOLD=8  # exit 2 연속 N회 시 종료

# ==============================================================================
# 유틸리티 함수
# ==============================================================================

# macOS/Linux 호환 날짜 함수
get_iso_date() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -u +"%Y-%m-%dT%H:%M:%SZ"
    else
        date -Iseconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ"
    fi
}

# 상태 디렉토리 생성
mkdir -p "$STATE_DIR"

# 로그 함수
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo "$1"
}

# 에러 핸들링 trap
cleanup() {
    local exit_code=$?
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
    # exit 2 = 정상 (autonomous 연속 실행 신호), exit 0 = 정상 (멈춤 허용)
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 2 ]; then
        log "비정상 종료 (exit code: $exit_code)"
    fi
}
trap cleanup EXIT

# ==============================================================================
# 안전 체크 함수
# ==============================================================================

# 긴급 중단 체크 (kill switch)
check_kill_switch() {
    if [ -f "$KILL_SWITCH" ]; then
        log "긴급 중단: EMERGENCY_STOP 파일 감지"
        rm -f "$KILL_SWITCH"
        echo ""
        echo "========================================"
        echo " 긴급 중단 (EMERGENCY STOP)"
        echo "========================================"
        echo " EMERGENCY_STOP 파일이 감지되어 중단됩니다."
        echo " 세션을 다시 시작하려면:"
        echo "   .claude/hooks/reset-session.sh"
        echo "========================================"
        exit 0
    fi
}

# 파일 잠금 획득 (경쟁 조건 방지)
acquire_lock() {
    local max_wait=10
    local waited=0

    while [ -f "$LOCK_FILE" ] && [ $waited -lt $max_wait ]; do
        sleep 0.5
        waited=$((waited + 1))
    done

    if [ -f "$LOCK_FILE" ]; then
        log "경고: 잠금 파일 타임아웃, 강제 진행"
        rm -f "$LOCK_FILE"
    fi

    echo $$ > "$LOCK_FILE"
}

# 파일 잠금 해제
release_lock() {
    rm -f "$LOCK_FILE"
}

# 디스크 공간 체크
check_disk_space() {
    local available_mb

    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_mb=$(df -m "$STATE_DIR" | tail -1 | awk '{print $4}')
    else
        available_mb=$(df -m "$STATE_DIR" | tail -1 | awk '{print $4}')
    fi

    if [ "$available_mb" -lt "$MIN_DISK_SPACE_MB" ]; then
        log "경고: 디스크 공간 부족 (${available_mb}MB < ${MIN_DISK_SPACE_MB}MB)"
        return 1
    fi

    return 0
}

# 로그 파일 로테이션
rotate_log_if_needed() {
    if [ -f "$LOG_FILE" ]; then
        local size_kb=$(du -k "$LOG_FILE" | cut -f1)

        if [ "$size_kb" -gt "$MAX_LOG_SIZE_KB" ]; then
            # 마지막 500줄만 유지
            tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp"
            mv "${LOG_FILE}.tmp" "$LOG_FILE"
            log "로그 파일 로테이션 완료"
        fi
    fi
}

# ==============================================================================
# v4.0: Rapid-fire 감지 (연속 빠른 트리거 = 작업 없음 판정)
# ==============================================================================

check_rapid_fire() {
    local current_time=$(date +%s)
    local last_time=0
    local rapid_count=0
    local consecutive_exit2=0

    # rapid-fire 상태 로드
    if [ -f "$RAPID_FIRE_FILE" ]; then
        if command -v jq &> /dev/null; then
            last_time=$(jq -r '.last_trigger_time // 0' "$RAPID_FIRE_FILE" 2>/dev/null || echo "0")
            rapid_count=$(jq -r '.rapid_count // 0' "$RAPID_FIRE_FILE" 2>/dev/null || echo "0")
            consecutive_exit2=$(jq -r '.consecutive_exit2 // 0' "$RAPID_FIRE_FILE" 2>/dev/null || echo "0")
        else
            last_time=$(grep -o '"last_trigger_time": [0-9]*' "$RAPID_FIRE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0")
            rapid_count=$(grep -o '"rapid_count": [0-9]*' "$RAPID_FIRE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0")
            consecutive_exit2=$(grep -o '"consecutive_exit2": [0-9]*' "$RAPID_FIRE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0")
        fi
    fi

    # 시간 기반 rapid-fire 감지
    local elapsed=$((current_time - last_time))

    if [ "$elapsed" -lt "$RAPID_FIRE_WINDOW_SECS" ]; then
        rapid_count=$((rapid_count + 1))
    else
        rapid_count=1
    fi

    # v4.1: 시간 무관 연속 exit 2 감지
    consecutive_exit2=$((consecutive_exit2 + 1))

    # 상태 저장
    cat > "$RAPID_FIRE_FILE" << EOF
{
    "last_trigger_time": $current_time,
    "rapid_count": $rapid_count,
    "consecutive_exit2": $consecutive_exit2,
    "threshold": $RAPID_FIRE_THRESHOLD,
    "exit2_threshold": $CONSECUTIVE_EXIT2_THRESHOLD,
    "window_secs": $RAPID_FIRE_WINDOW_SECS
}
EOF

    # 종료 판정: 시간 기반 OR 연속 exit 2
    if [ "$rapid_count" -ge "$RAPID_FIRE_THRESHOLD" ]; then
        log "rapid-fire 감지: ${rapid_count}회 연속 빠른 트리거 (${RAPID_FIRE_WINDOW_SECS}초 이내) → 작업 없음 판정"
        return 0
    fi

    if [ "$consecutive_exit2" -ge "$CONSECUTIVE_EXIT2_THRESHOLD" ]; then
        log "연속 exit 2 감지: ${consecutive_exit2}회 (시간 무관) → 작업 없음 판정"
        return 0
    fi

    return 1
}

# rapid-fire 상태 리셋
reset_rapid_fire() {
    rm -f "$RAPID_FIRE_FILE"
}

# ==============================================================================
# 상태 관리
# ==============================================================================

# 상태 파일 초기화 또는 로드
init_or_load_state() {
    if [ -f "$STATE_FILE" ]; then
        local prev_status
        if command -v jq &> /dev/null; then
            prev_status=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
        else
            prev_status=$(grep -o '"status": "[^"]*"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || echo "unknown")
        fi

        # v4.0: completed, errored, exhausted 모두 새 세션 초기화
        if [ "$prev_status" = "completed" ] || [ "$prev_status" = "errored" ] || [ "$prev_status" = "exhausted" ]; then
            log "이전 세션($prev_status) 감지 → 새 세션 초기화"
            rm -f "$STATE_FILE"
            # 이전 세션 잔류 상태 정리 (새 세션이므로)
            reset_rapid_fire
            rm -f "$AUTONOMOUS_MODE"
            # PHASE0_COMPLETE는 유지 — 현 세션에서 이미 완료했을 수 있음
            # 새 세션 시작 시 reset-session.sh에서 삭제됨
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
    "warnings": [],
    "version": "4.1"
}
EOF
        log "새로운 Stop Hook 세션 시작 (최대 ${MAX_ITERATIONS}회, ${TIMEOUT_MINUTES}분)"
    fi
}

# 현재 반복 횟수 가져오기
get_iteration() {
    if command -v jq &> /dev/null; then
        jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null || echo "0"
    else
        grep -o '"iteration": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0"
    fi
}

# 시작 시간 가져오기
get_start_time() {
    if command -v jq &> /dev/null; then
        jq -r '.start_time // 0' "$STATE_FILE" 2>/dev/null || echo "$(date +%s)"
    else
        grep -o '"start_time": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "$(date +%s)"
    fi
}

# 반복 횟수 증가
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

# 타임아웃 체크
check_timeout() {
    local start_time=$(get_start_time)
    local current_time=$(date +%s)

    # 안전 검증: start_time이 비정상이면 리셋 + STATE_FILE에 영속화
    if [ "$start_time" -le 0 ] || [ "$start_time" -gt "$current_time" ]; then
        log "경고: 비정상 start_time(${start_time}) 감지 → 현재 시간으로 리셋"
        start_time=$current_time
        # M2: 리셋된 start_time을 STATE_FILE에 저장 (재경고 방지)
        if command -v jq &> /dev/null; then
            local tmp=$(mktemp)
            jq ".start_time = $current_time" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
        else
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/\"start_time\": [0-9]*/\"start_time\": $current_time/" "$STATE_FILE"
            else
                sed -i "s/\"start_time\": [0-9]*/\"start_time\": $current_time/" "$STATE_FILE"
            fi
        fi
    fi

    local elapsed_seconds=$((current_time - start_time))
    local elapsed_minutes=$((elapsed_seconds / 60))

    if [ "$elapsed_minutes" -ge "$TIMEOUT_MINUTES" ]; then
        log "타임아웃: ${elapsed_minutes}분 경과 (제한: ${TIMEOUT_MINUTES}분)"
        return 1
    fi

    return 0
}

# 완료 조건 체크 (TASK_COMPLETE + todo.md + TaskList + no-tracker fallback)
check_completion() {
    local NO_TRACKER_FILE="${STATE_DIR}/no-tracker-count"

    # 0. v4.1: 명시적 완료 신호 (Claude가 touch한 TASK_COMPLETE 파일)
    if [ -f "$TASK_COMPLETE_FILE" ]; then
        log "완료: TASK_COMPLETE 신호 감지"
        rm -f "$TASK_COMPLETE_FILE"  # 1회 소비 후 삭제
        rm -f "$NO_TRACKER_FILE"
        return 0
    fi

    local has_tracker=false

    # 1. todo.md 체크 (기존 호환)
    local todo_file="${PWD}/todo.md"
    if [ -f "$todo_file" ]; then
        has_tracker=true
        if ! grep -q '\[ \]' "$todo_file"; then
            log "완료: todo.md의 모든 항목 완료"
            rm -f "$NO_TRACKER_FILE"
            return 0
        fi
    fi

    # 2. .claude/tasks/ 디렉토리 체크 (TaskList 도구 호환)
    local tasks_dir="${HOME}/.claude/tasks"
    if [ -d "$tasks_dir" ]; then
        local has_pending=false
        local has_task_files=false
        for task_file in "$tasks_dir"/*.json "$tasks_dir"/*/*.json; do
            [ -f "$task_file" ] || continue
            has_task_files=true
            has_tracker=true
            if command -v jq &> /dev/null; then
                local status
                status=$(jq -r '.status // "unknown"' "$task_file" 2>/dev/null || echo "unknown")
                if [ "$status" = "pending" ] || [ "$status" = "in_progress" ]; then
                    has_pending=true
                    break
                fi
            else
                # B3: grep -E 사용 (macOS 호환 — \| 대신 ERE)
                if grep -E -q '"status": "(pending|in_progress)"' "$task_file" 2>/dev/null; then
                    has_pending=true
                    break
                fi
            fi
        done

        if [ "$has_task_files" = true ] && [ "$has_pending" = false ]; then
            log "완료: 모든 TaskList 작업 완료"
            rm -f "$NO_TRACKER_FILE"
            return 0
        fi
    fi

    # 3. v4.1: 추적기 없음 감지 (todo.md 없음 + TaskList 미사용 → N회 후 완료 간주)
    if [ "$has_tracker" = false ]; then
        local count=0
        if [ -f "$NO_TRACKER_FILE" ]; then
            count=$(cat "$NO_TRACKER_FILE" 2>/dev/null || echo "0")
            # 방어 코딩: 비숫자 값이면 0으로 리셋 (set -e crash 방지)
            [[ "$count" =~ ^[0-9]+$ ]] || count=0
        fi
        count=$((count + 1))
        echo "$count" > "$NO_TRACKER_FILE"

        if [ "$count" -ge 3 ]; then
            log "완료: 작업 추적기 없음 + ${count}회 연속 → 완료 간주"
            return 0
        fi
        log "추적기 없음 ${count}/3 (todo.md 없음, TaskList 미사용)"
    else
        # 추적기 있으면 카운터 리셋
        rm -f "$NO_TRACKER_FILE"
    fi

    return 1  # 미완료
}

# 세션 종료
end_session() {
    local reason="$1"
    local status="${2:-completed}"

    # B1: jq fallback 추가 — jq 없어도 상태 저장 보장
    if command -v jq &> /dev/null; then
        local tmp=$(mktemp)
        jq ".status = \"$status\" | .end_reason = \"$reason\" | .end_time = \"$(get_iso_date)\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    else
        # jq fallback: 기존 값 읽어서 printf로 전체 JSON 재작성
        local iter start_t max_iter timeout_m iso_date
        iter=$(grep -o '"iteration": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "0")
        start_t=$(grep -o '"start_time": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "0")
        max_iter=$(grep -o '"max_iterations": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "$MAX_ITERATIONS")
        timeout_m=$(grep -o '"timeout_minutes": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "$TIMEOUT_MINUTES")
        iso_date=$(get_iso_date)
        printf '{\n    "iteration": %s,\n    "start_time": %s,\n    "max_iterations": %s,\n    "timeout_minutes": %s,\n    "status": "%s",\n    "last_update": "%s",\n    "warnings": [],\n    "version": "4.1",\n    "end_reason": "%s",\n    "end_time": "%s"\n}\n' \
            "$iter" "$start_t" "$max_iter" "$timeout_m" "$status" "$iso_date" "$reason" "$iso_date" \
            > "$STATE_FILE"
    fi

    # 자율 모드 비활성화
    rm -f "$AUTONOMOUS_MODE"
    # v4.1: 상태 파일 일관성 보장 (비정상 종료 시에도 정리)
    rm -f "$TASK_COMPLETE_FILE"
    rm -f "${STATE_DIR}/no-tracker-count"
    # PHASE0_COMPLETE는 유지 — 세션 재개 시 Phase 0 재실행 방지
    # 새 세션 시작 시 reset-session.sh에서 삭제됨

    # rapid-fire 상태 리셋
    reset_rapid_fire

    release_lock
    log "세션 종료: $reason (status: $status)"

    echo ""
    echo "========================================"
    echo " 자율 모드 종료"
    echo "========================================"
    echo " 종료 사유: $reason"
    echo " 자율 모드가 비활성화되었습니다."
    echo " 다시 시작: /autonomous [작업내용]"
    echo "========================================"

    exit 0
}

# ==============================================================================
# 메인 로직
# ==============================================================================

main() {
    # 0. 자율 모드 체크 (AUTONOMOUS_MODE 파일이 없으면 조용히 종료)
    if [ ! -f "$AUTONOMOUS_MODE" ]; then
        exit 0
    fi

    # 0.5. v4.2: CONTEXT_WARNING 연동 (컨텍스트 부족 시 반복 제한 단축)
    if [ -f "$CONTEXT_WARNING_FILE" ]; then
        local ctx_remaining
        ctx_remaining=$(cat "$CONTEXT_WARNING_FILE" 2>/dev/null || echo "99")
        # 방어 코딩: 비숫자 값이면 무시
        if [[ "$ctx_remaining" =~ ^[0-9]+$ ]] && [ "$ctx_remaining" -le 15 ]; then
            MAX_ITERATIONS=20  # 50 → 20
            log "CONTEXT_WARNING: ${ctx_remaining}% 남음 → MAX_ITERATIONS=${MAX_ITERATIONS}"
        fi
    fi

    # 1. 긴급 중단 체크 (최우선)
    check_kill_switch

    # 2. v4.0: rapid-fire 감지 (최대 반복 도달 전에도 빠른 종료)
    if check_rapid_fire; then
        end_session "rapid-fire 감지 (작업 없음 판정)" "completed"
    fi

    # 3. 파일 잠금 획득
    acquire_lock

    # 4. 로그 로테이션
    rotate_log_if_needed

    # 5. 디스크 공간 체크
    if ! check_disk_space; then
        end_session "디스크 공간 부족"
    fi

    # 6. 상태 초기화
    init_or_load_state

    # 7. 반복 횟수 체크
    local iteration=$(increment_iteration)
    log "반복 #${iteration}/${MAX_ITERATIONS}"

    if [ "$iteration" -ge "$MAX_ITERATIONS" ]; then
        # v4.0: exhausted 상태로 좀비 방지
        end_session "최대 반복 횟수 도달 (${MAX_ITERATIONS}회)" "exhausted"
    fi

    # 8. 타임아웃 체크
    if ! check_timeout; then
        end_session "타임아웃"
    fi

    # 9. 완료 조건 체크
    if check_completion; then
        end_session "모든 작업 완료"
    fi

    # 10. 파일 잠금 해제
    release_lock

    # 11. 상태 출력 + exit 2로 autonomous 연속 실행 보장
    local remaining=$((MAX_ITERATIONS - iteration))
    local start_time=$(get_start_time)
    local current_time=$(date +%s)
    local elapsed=$(( (current_time - start_time) / 60 ))
    local time_remaining=$((TIMEOUT_MINUTES - elapsed))

    # stderr로 메시지 전달 (exit 2 시 Claude에게 전달됨)
    echo "Stop Hook v4.1 | 반복: ${iteration}/${MAX_ITERATIONS} (남은: ${remaining}) | 시간: ${elapsed}분/${TIMEOUT_MINUTES}분 | 계속 진행해주세요." >&2
    exit 2
}

main "$@"
