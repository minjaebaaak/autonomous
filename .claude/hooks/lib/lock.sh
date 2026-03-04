#!/bin/bash
# ==============================================================================
# lock.sh — mkdir 기반 원자적 잠금 (POSIX 표준, macOS/Linux 호환)
# ==============================================================================
#
# 사용법:
#   source .claude/hooks/lib/lock.sh
#   acquire_lock "/path/to/lock-dir" [timeout_secs]
#   # ... 보호 대상 코드 ...
#   release_lock "/path/to/lock-dir"
#
# mkdir는 POSIX에서 원자적 (atomic) 연산이므로,
# 두 프로세스가 동시에 호출해도 하나만 성공한다.
# flock CLI가 없는 macOS에서도 동작.
#
# ==============================================================================

acquire_lock() {
    local lock_dir="$1"
    local max_wait="${2:-15}"  # 기본 15초
    local waited=0
    local max_attempts=$((max_wait * 2))  # 0.5초 간격

    while ! mkdir "$lock_dir" 2>/dev/null; do
        sleep 0.5
        waited=$((waited + 1))

        if [ $waited -ge $max_attempts ]; then
            # stale lock 감지: 소유 프로세스 확인 + 60초 경과 체크
            if [ -d "$lock_dir" ]; then
                local lock_pid
                lock_pid=$(cat "$lock_dir/pid" 2>/dev/null)

                # PID가 있고 프로세스가 죽었으면 stale
                if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
                    rm -rf "$lock_dir"
                    waited=0
                    continue
                fi

                # 60초 이상 된 lock은 stale로 간주
                local lock_age
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    lock_age=$(( $(date +%s) - $(stat -f %m "$lock_dir") ))
                else
                    lock_age=$(( $(date +%s) - $(stat -c %Y "$lock_dir") ))
                fi

                if [ "$lock_age" -gt 60 ]; then
                    rm -rf "$lock_dir"
                    waited=0
                    continue
                fi
            fi
            return 1  # 진짜 timeout
        fi
    done

    # lock 획득 성공 — PID 기록
    echo $$ > "$lock_dir/pid"
    return 0
}

release_lock() {
    rm -rf "$1"
}
