#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 자동 토큰 최적화 훅 (Auto Token Optimizer)
# ═══════════════════════════════════════════════════════════════════
# Hook Type: UserPromptSubmit (전역 ~/.claude/settings.json에 등록)
# 목적: 매 사용자 입력마다 자동으로 최적화 가이드 제공
#
# 기능:
#   1. 컨텍스트 사용량 모니터링 (JSONL 토큰 파싱 → 파일 크기 fallback)
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

# === 1. 컨텍스트 사용량 모니터링 (v5.4.3: 토큰 기반) ===
check_context_usage() {
    local session_dir="$HOME/.claude/projects/-$(echo "$PWD" | tr '/' '-' | sed 's/^-//')"
    [ -d "$session_dir" ] || return

    local session_file=$(ls -t "$session_dir"/*.jsonl 2>/dev/null | head -1)
    [ -f "$session_file" ] || return

    # 1순위: JSONL 토큰 파싱 (정확도 ~100%)
    if command -v python3 &>/dev/null; then
        local total_input
        total_input=$(tail -c 200000 "$session_file" | python3 -c "
import sys, json
last_usage = None
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'assistant' and 'message' in obj:
            u = obj['message'].get('usage')
            if u: last_usage = u
    except: pass
if last_usage:
    print(last_usage.get('input_tokens',0) + last_usage.get('cache_creation_input_tokens',0) + last_usage.get('cache_read_input_tokens',0))
else:
    print(0)
" 2>/dev/null)

        if [ -n "$total_input" ] && [ "$total_input" -gt 0 ] 2>/dev/null; then
            local context_window=200000
            local used_pct=$((total_input * 100 / context_window))
            local remaining_pct=$((100 - used_pct))

            if [ "$remaining_pct" -le 15 ]; then
                echo "🔴 [CONTEXT] 컨텍스트 ${remaining_pct}% 남음 (${total_input}/${context_window} tokens) → 즉시 핸드오프!"
                mkdir -p "$HOME/.claude/state"
                echo "$remaining_pct" > "$HOME/.claude/state/CONTEXT_WARNING"
                return
            elif [ "$remaining_pct" -le 30 ]; then
                echo "🟠 [CONTEXT] 컨텍스트 ${remaining_pct}% 남음 (${total_input}/${context_window} tokens) → 대규모 작업 주의"
                return
            fi
            # 정상: 상태 파일 정리
            rm -f "$HOME/.claude/state/CONTEXT_WARNING"
            return
        fi
    fi

    # 2순위 fallback: 파일 크기 기반 (python3 없을 때, 임계값 하향)
    local size_kb=$(du -k "$session_file" | cut -f1)
    local size_mb=$((size_kb / 1024))

    if [ "$size_kb" -gt 15360 ]; then  # 15MB (기존 20MB에서 하향)
        echo "🔴 [AUTO-WARN] 세션 ${size_mb}MB → 현재 작업 마무리 후 세션 종료!"
        mkdir -p "$HOME/.claude/state"
        echo "15" > "$HOME/.claude/state/CONTEXT_WARNING"
    elif [ "$size_kb" -gt 10240 ]; then  # 10MB
        echo "🟠 [AUTO-WARN] 세션 ${size_mb}MB → 대규모 작업 주의."
    fi
}

# === 1.5. 핸드오프 노트 감지 (v5.4.2: 프로젝트 필터링 추가) ===
check_handoff() {
    local handoff_dir="$HOME/.claude/state/handoffs"
    local count=0
    local last_file=""

    if [ -d "$handoff_dir" ]; then
        # 프로젝트 필터링: 현재 $PWD와 일치하는 핸드오프만 카운트
        for f in "$handoff_dir"/handoff-*.md; do
            [ -f "$f" ] || continue
            local proj=$(grep "^- project:" "$f" 2>/dev/null | sed 's/^- project: //')
            if [ -z "$proj" ] || [ "$proj" = "$PWD" ]; then
                count=$((count + 1))
                last_file="$f"
            fi
        done
    fi

    if [ "$count" -eq 1 ]; then
        local task=$(grep "^- task:" "$last_file" 2>/dev/null | sed 's/^- task: //')
        echo "📋 [HANDOFF] 이전 세션 작업 발견: ${task:-알 수 없음}. /autonomous 로 자동 재개 가능."
    elif [ "$count" -gt 1 ]; then
        echo "📋 [HANDOFF] 이전 세션 작업 ${count}건 발견. /autonomous 로 선택 재개 가능."
    fi

    # 레거시 호환: v5.3 싱글톤 파일도 감지 (프로젝트 필터링 불가)
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
check_context_usage
check_handoff
check_deploy_keywords
check_git_keywords
check_verify_keywords
check_autonomous_phase0

exit 0
