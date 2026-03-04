#!/bin/bash
# auto-session.sh v1.0 — autonomous 세션 자동 재시작
# 사용: auto-session [task]  |  auto-session --max 5 대규모 리팩토링
#
# 컨텍스트 소진 시 SESSION_RESTART 신호를 감지하여 자동으로 새 Claude 프로세스 시작.
# 핸드오프 노트를 통해 이전 세션의 맥락을 다음 세션으로 전달.

STATE_DIR="$HOME/.claude/state"
MAX_SESSIONS=10
COOLDOWN=5
TASK=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max)   MAX_SESSIONS="$2"; shift 2 ;;
        --max=*) MAX_SESSIONS="${1#*=}"; shift ;;
        --help|-h)
            echo "auto-session v1.0 — autonomous 세션 자동 재시작"
            echo ""
            echo "사용법: auto-session [옵션] [작업]"
            echo ""
            echo "옵션:"
            echo "  --max N    최대 세션 수 (기본: 10)"
            echo "  --help     이 도움말"
            echo ""
            echo "예시:"
            echo "  auto-session 배포해줘"
            echo "  auto-session --max 5 대규모 리팩토링"
            echo "  auto-session                  # 핸드오프에서 자동 복원"
            exit 0
            ;;
        *)       TASK="${TASK:+$TASK }$1"; shift ;;
    esac
done

# Ctrl+C 핸들러
trap 'echo ""; echo "중단됨"; rm -f "$STATE_DIR/SESSION_RESTART"; exit 130' INT TERM

mkdir -p "$STATE_DIR" "$STATE_DIR/handoffs"
unset CLAUDECODE  # 중첩 실행 방지 해제

echo "=== auto-session v1.0 (최대 ${MAX_SESSIONS}세션) ==="
[ -n "$TASK" ] && echo "작업: $TASK"
echo ""

for i in $(seq 1 $MAX_SESSIONS); do
    # 세션 간 정리 (첫 세션 제외)
    if [ $i -gt 1 ]; then
        echo ""
        echo "--- 쿨다운 ${COOLDOWN}초 ---"
        sleep $COOLDOWN

        # reset-session.sh 실행 (프로젝트별 위치 탐색)
        if [ -f ".claude/hooks/reset-session.sh" ]; then
            bash .claude/hooks/reset-session.sh 2>/dev/null || true
        elif [ -f "$HOME/.claude/hooks/reset-session.sh" ]; then
            bash "$HOME/.claude/hooks/reset-session.sh" 2>/dev/null || true
        fi
    fi

    rm -f "$STATE_DIR/SESSION_RESTART" "$STATE_DIR/TASK_COMPLETE"

    # 프롬프트 결정
    if [ $i -eq 1 ] && [ -n "$TASK" ]; then
        PROMPT="/autonomous $TASK"
    else
        PROMPT="/autonomous"
    fi

    echo "=== 세션 #${i}/${MAX_SESSIONS}: $PROMPT ==="
    echo ""

    # Claude 실행 (비대화형 모드)
    claude --dangerously-skip-permissions -p "$PROMPT"
    CLAUDE_RC=$?

    echo ""
    echo "--- 세션 #${i} 종료 (exit: $CLAUDE_RC) ---"

    # 신호 판별
    if [ -f "$STATE_DIR/SESSION_RESTART" ]; then
        rm -f "$STATE_DIR/SESSION_RESTART"
        echo "자동 재시작: 컨텍스트 소진 감지"
        continue
    fi

    # 핸드오프 fallback (SESSION_RESTART 없지만 핸드오프 있으면 재시작)
    if ls "$STATE_DIR/handoffs"/handoff-*.md &>/dev/null 2>&1; then
        echo "핸드오프 감지 -> 재시작"
        continue
    fi

    echo "완료"
    break
done

if [ $i -ge $MAX_SESSIONS ]; then
    echo ""
    echo "최대 세션 수(${MAX_SESSIONS}) 도달"
fi
