#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 자동 토큰 최적화 훅 (Auto Token Optimizer)
# ═══════════════════════════════════════════════════════════════════
# Hook Type: UserPromptSubmit (전역 ~/.claude/settings.json에 등록)
# 목적: 매 사용자 입력마다 자동으로 최적화 가이드 제공
#
# 기능:
#   1. 세션 크기 모니터링 (10MB 경고, 20MB 세션 종료 권고)
#   1.5. 핸드오프 노트 감지 (v5.4 디렉토리 기반)
#   2. 배포 키워드 감지
#   3. Git 키워드 감지
#   4. 검증 키워드 감지
#   5. /autonomous Phase 0 게이팅
#
# 설치:
#   cp templates/hooks/token-optimizer.sh ~/.claude/hooks/
#   chmod +x ~/.claude/hooks/token-optimizer.sh
#   # settings-global.json 참조하여 ~/.claude/settings.json에 훅 등록
# ═══════════════════════════════════════════════════════════════════

PROMPT="${USER_PROMPT:-}"

# === 1. 세션 크기 모니터링 ===
check_session_size() {
    # 동적 경로: 현재 PWD 기반으로 세션 디렉토리 계산
    local session_dir="$HOME/.claude/projects/-$(echo "$PWD" | tr '/' '-' | sed 's/^-//')"

    if [ -d "$session_dir" ]; then
        local session_file=$(ls -t "$session_dir"/*.jsonl 2>/dev/null | head -1)

        if [ -f "$session_file" ]; then
            local size_kb=$(du -k "$session_file" | cut -f1)
            local size_mb=$((size_kb / 1024))

            if [ "$size_kb" -gt 20480 ]; then  # 20MB
                echo "🔴 [AUTO-WARN] 세션 ${size_mb}MB → 현재 작업 마무리 후 세션 종료! (nlm이 맥락 보존, 새 세션에서 Phase 0 복원)"
                return
            elif [ "$size_kb" -gt 10240 ]; then  # 10MB
                echo "🟠 [AUTO-WARN] 세션 ${size_mb}MB → 대규모 작업 주의. 20MB 도달 시 세션 전환 필요."
                return
            fi
        fi
    fi
}

# === 1.5. 핸드오프 노트 감지 (v5.4: 디렉토리 기반) ===
check_handoff() {
    local handoff_dir="$HOME/.claude/state/handoffs"
    local count=0

    if [ -d "$handoff_dir" ]; then
        count=$(ls "$handoff_dir"/handoff-*.md 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [ "$count" -eq 1 ]; then
        local task=$(grep "^- task:" "$handoff_dir"/handoff-*.md 2>/dev/null | head -1 | sed 's/.*- task: //')
        echo "📋 [HANDOFF] 이전 세션 작업 발견: ${task:-알 수 없음}. /autonomous 로 자동 재개 가능."
    elif [ "$count" -gt 1 ]; then
        echo "📋 [HANDOFF] 이전 세션 작업 ${count}건 발견. /autonomous 로 선택 재개 가능."
    fi

    # 레거시 호환: v5.3 싱글톤 파일도 감지
    local legacy="$HOME/.claude/state/session-handoff.md"
    if [ -f "$legacy" ]; then
        local task=$(grep "^- task:" "$legacy" | sed 's/^- task: //')
        echo "📋 [HANDOFF] 이전 세션 작업 발견 (레거시): ${task:-알 수 없음}."
    fi
}

# === 2. 배포 키워드 감지 ===
check_deploy_keywords() {
    if echo "$PROMPT" | grep -qiE "배포해|배포 해|deploy|프로덕션.*push|서버.*반영|production.*deploy"; then
        echo "🚀 [AUTO-GUIDE] 배포 요청 감지 → /deploy-atomic 커맨드 사용 (§7 배포 규칙 자동 준수)"
    fi
}

# === 3. Git 키워드 감지 ===
check_git_keywords() {
    if echo "$PROMPT" | grep -qiE "커밋해|커밋 해|commit.*push|git.*push|푸시해|푸시 해|git add.*commit"; then
        echo "📦 [AUTO-GUIDE] Git 작업 감지 → /git-atomic 커맨드 사용 권장 (개별 명령 대신)"
    fi
}

# === 4. 검증 키워드 감지 ===
check_verify_keywords() {
    if echo "$PROMPT" | grep -qiE "검증해|검증 해|프로덕션.*확인|verify|동작.*확인|헬스.*체크|health.*check"; then
        echo "🔍 [AUTO-GUIDE] 검증 요청 감지 → /verify-quick 커맨드 사용 권장 (브라우저 호출 최소화)"
    fi
}

# === 5. /autonomous 감지 → Phase 0 강제 (v4.9: 상태 파일 기반) ===
check_autonomous_phase0() {
    if echo "$PROMPT" | grep -qiE "^/autonomous"; then
        # Phase 0 강제: 상태 파일로 PreToolUse 훅 활성화
        mkdir -p ~/.claude/state
        touch ~/.claude/state/AUTONOMOUS_MODE
        rm -f ~/.claude/state/PHASE0_COMPLETE
        echo "🔴 [PHASE0-GUARD] /autonomous 감지 → nlm notebook query를 가장 먼저 실행하세요!"
        echo "   Phase 0 미실행 시 Read/Glob/Grep/Task 도구가 훅에 의해 차단됩니다."
    fi
}

# === 실행 ===
check_session_size
check_handoff
check_deploy_keywords
check_git_keywords
check_verify_keywords
check_autonomous_phase0

exit 0
