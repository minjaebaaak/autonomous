#!/bin/bash
# ==============================================================================
# Phase 0 Gate - autonomous 모드에서 nlm 완료 전 도구 차단
# ==============================================================================
#
# Hook Type: PreToolUse (프로젝트 .claude/settings.local.json에 등록)
#
# 조건:
#   AUTONOMOUS_MODE 파일 존재 + PHASE0_COMPLETE 파일 미존재
#   → Read, Glob, Grep, Task, Write, Edit 도구 차단
#
# 상태 파일:
#   ~/.claude/state/AUTONOMOUS_MODE   - UserPromptSubmit에서 /autonomous 감지 시 생성
#   ~/.claude/state/PHASE0_COMPLETE   - nlm 성공 후 STEP 0 bash에서 생성
#
# 설치:
#   cp templates/hooks/phase0-gate.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/phase0-gate.sh
#   # settings-local.json 참조하여 PreToolUse 훅 등록
#
# 반환값:
#   0: 허용 (도구 실행)
#   1: 차단 (도구 실행 중단)
#
# ==============================================================================

STATE_DIR="${HOME}/.claude/state"
AUTONOMOUS_MODE="${STATE_DIR}/AUTONOMOUS_MODE"
PHASE0_COMPLETE="${STATE_DIR}/PHASE0_COMPLETE"

# autonomous 모드가 아니면 즉시 통과
if [ ! -f "$AUTONOMOUS_MODE" ]; then
    exit 0
fi

# Phase 0 완료면 즉시 통과
if [ -f "$PHASE0_COMPLETE" ]; then
    exit 0
fi

# Phase 0 미완료 → 차단
echo ""
echo "========================================"
echo " 🔴 Phase 0 미완료 - 도구 차단"
echo "========================================"
echo " nlm 기술문서 질의를 먼저 실행하세요."
echo ""
echo " Bash에서 아래 명령 실행:"
echo "   nlm notebook query <alias> \"[질의]\""
echo ""
echo " nlm 성공 시 자동으로 게이트가 해제됩니다."
echo " nlm 완전 실패 시:"
echo "   touch ~/.claude/state/PHASE0_COMPLETE"
echo "   실행 후 Read fallback을 사용하세요."
echo "========================================"
exit 1
