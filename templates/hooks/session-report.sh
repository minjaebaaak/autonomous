#!/bin/bash
# 세션 종료 시 세션 크기 리포트
# Hook Type: Stop
# 설정: ~/.claude/settings.json의 hooks 배열에 추가

# 동적 경로: 현재 PWD 기반으로 세션 디렉토리 계산
SESSION_DIR="$HOME/.claude/projects/-$(echo "$PWD" | tr '/' '-' | sed 's/^-//')"

if [ -d "$SESSION_DIR" ]; then
    # 가장 최근 세션 파일 찾기
    CURRENT_SESSION=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)

    if [ -n "$CURRENT_SESSION" ]; then
        SIZE=$(ls -lh "$CURRENT_SESSION" | awk '{print $5}')
        LINES=$(wc -l < "$CURRENT_SESSION" 2>/dev/null || echo "0")

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 세션 리포트"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📁 크기: $SIZE"
        echo "📝 메시지: ~$LINES 개"

        # 크기 경고
        SIZE_MB=$(echo "$SIZE" | sed 's/M$//' | sed 's/K$/0.001/' | sed 's/G$/1000/')
        if (( $(echo "$SIZE_MB > 20" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  상태: 🔴 위험 - 새 세션 권장!"
        elif (( $(echo "$SIZE_MB > 10" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  상태: 🟠 경고 - /compact 권장"
        elif (( $(echo "$SIZE_MB > 5" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  상태: 🟡 주의"
        else
            echo "✅ 상태: 🟢 정상"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Phase 0 준수 여부 (autonomous 모드일 때만)
        PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')
        SUFFIX="${PANE_ID:+-pane$PANE_ID}"
        AUTONOMOUS_FILE="$HOME/.claude/state/AUTONOMOUS_MODE${SUFFIX}"
        if [ -f "$AUTONOMOUS_FILE" ]; then
            echo "🤖 모드: Autonomous"
            if grep -q "nlm notebook query" "$CURRENT_SESSION" 2>/dev/null; then
                echo "✅ Phase 0 nlm: 실행됨"
            else
                echo "🔴 Phase 0 nlm: 미실행 (규칙 위반)"
            fi
        fi

        # --- 자동 핸드오프 (v5.23 — session ID 기반 완전 격리) ---
        # TASK_COMPLETE가 있으면 = 정상 종료 → 핸드오프 불필요
        if [ ! -f "$HOME/.claude/state/TASK_COMPLETE${SUFFIX}" ]; then
            SESSION_ID=$(basename "$CURRENT_SESSION" .jsonl | cut -c1-8)
            HANDOFF_DIR="$HOME/.claude/state/handoffs"
            PROJECT_HASH=$(echo "$PWD" | md5 | cut -c1-8)
            # v5.23: session ID = 유일한 식별자 (tmux/Warp/단일 터미널 무관)
            HANDOFF_FILE="$HANDOFF_DIR/proj-${PROJECT_HASH}-${SESSION_ID}.md"

            # JSONL에서 마지막 user 메시지 + 🎯 작업 추출
            TASK_INFO=$(tail -c 200000 "$CURRENT_SESSION" | python3 -c "
import sys, json
last_user = ''
last_target = ''
for line in sys.stdin:
    try:
        obj = json.loads(line.strip())
        if obj.get('type') == 'human':
            for c in obj.get('message',{}).get('content',[]):
                t = c.get('text','')
                if len(t) > 10 and not t.startswith('{'): last_user = t[:100]
        elif obj.get('type') == 'assistant':
            for c in obj.get('message',{}).get('content',[]):
                t = c.get('text','')
                for l in t.split('\n'):
                    if l.strip().startswith('🎯 작업:'): last_target = l.strip()
    except: pass
if last_user or last_target:
    print(f'user: {last_user}')
    if last_target: print(last_target)
" 2>/dev/null)

            if [ -n "$TASK_INFO" ]; then
                mkdir -p "$HANDOFF_DIR"
                # 같은 프로젝트의 이전 핸드오프 정리 (같은 session 것만 — 다른 세션 건드리지 않음)
                # 24시간 초과 파일 정리
                find "$HANDOFF_DIR" -name "proj-${PROJECT_HASH}-*.md" -mtime +1 -delete 2>/dev/null
                cat > "$HANDOFF_FILE" << HANDOFF_EOF
# Session Handoff (auto — v5.23)
- session: ${SESSION_ID}
- project: $PWD
- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- task: |
$(echo "$TASK_INFO" | sed 's/^/  /')
HANDOFF_EOF
                echo "📋 핸드오프 저장 (proj-${PROJECT_HASH}-${SESSION_ID})"
            fi
        fi
    fi
fi
