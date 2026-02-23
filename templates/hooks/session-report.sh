#!/bin/bash
# ==============================================================================
# 세션 종료 리포트 (Session Report)
# ==============================================================================
# Hook Type: Stop (전역 ~/.claude/settings.json에 등록)
# 목적: 세션 종료 시 크기/상태 요약 + Phase 0 준수 여부 출력
#
# 설치:
#   cp templates/hooks/session-report.sh ~/.claude/hooks/
#   chmod +x ~/.claude/hooks/session-report.sh
#   # settings-global.json 참조하여 ~/.claude/settings.json에 훅 등록
# ==============================================================================

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
        AUTONOMOUS_FILE="$HOME/.claude/state/AUTONOMOUS_MODE"
        if [ -f "$AUTONOMOUS_FILE" ]; then
            echo "🤖 모드: Autonomous"
            if grep -q "nlm notebook query" "$CURRENT_SESSION" 2>/dev/null; then
                echo "✅ Phase 0 nlm: 실행됨"
            else
                echo "🔴 Phase 0 nlm: 미실행 (규칙 위반)"
            fi
        fi
    fi
fi
