#!/bin/bash
# ==============================================================================
# Stop Hook 세션 리셋 (v2.3 - CONTEXT_WARNING 정리 추가)
# ==============================================================================
# 새로운 자율 작업 세션을 시작하기 전에 실행
#
# 설치:
#   cp templates/hooks/reset-session.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/reset-session.sh
#   # 수동 실행: .claude/hooks/reset-session.sh
# ==============================================================================

STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/stop-hook-state.json"
LOG_FILE="${STATE_DIR}/stop-hook.log"
LOCK_FILE="${STATE_DIR}/stop-hook.lock"
KILL_SWITCH="${STATE_DIR}/EMERGENCY_STOP"
AUTONOMOUS_MODE="${STATE_DIR}/AUTONOMOUS_MODE"
RAPID_FIRE_FILE="${STATE_DIR}/rapid-fire.json"

echo "========================================"
echo " Stop Hook 세션 리셋 (v2.2)"
echo "========================================"

# 상태 파일 삭제
if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    echo " [OK] 상태 파일 삭제됨"
else
    echo " [--] 상태 파일 없음"
fi

# 잠금 파일 삭제
if [ -f "$LOCK_FILE" ]; then
    rm "$LOCK_FILE"
    echo " [OK] 잠금 파일 삭제됨"
else
    echo " [--] 잠금 파일 없음"
fi

# 긴급 중단 파일 삭제
if [ -f "$KILL_SWITCH" ]; then
    rm "$KILL_SWITCH"
    echo " [OK] 긴급 중단 파일 삭제됨"
else
    echo " [--] 긴급 중단 파일 없음"
fi

# 자율 모드 파일 삭제
if [ -f "$AUTONOMOUS_MODE" ]; then
    rm "$AUTONOMOUS_MODE"
    echo " [OK] 자율 모드 비활성화됨"
else
    echo " [--] 자율 모드 이미 비활성화"
fi

# Rapid-fire 상태 파일 삭제
if [ -f "$RAPID_FIRE_FILE" ]; then
    rm "$RAPID_FIRE_FILE"
    echo " [OK] Rapid-fire 상태 파일 삭제됨"
else
    echo " [--] Rapid-fire 상태 파일 없음"
fi

# 알림 쓰로틀 파일 삭제 (새 세션에서 즉시 알림 가능)
NOTIFY_THROTTLE="${STATE_DIR}/notify-throttle"
if [ -f "$NOTIFY_THROTTLE" ]; then
    rm "$NOTIFY_THROTTLE"
    echo " [OK] 알림 쓰로틀 파일 삭제됨"
else
    echo " [--] 알림 쓰로틀 파일 없음"
fi

# Phase 0 완료 파일 삭제
PHASE0_COMPLETE="${STATE_DIR}/PHASE0_COMPLETE"
if [ -f "$PHASE0_COMPLETE" ]; then
    rm "$PHASE0_COMPLETE"
    echo " [OK] Phase 0 완료 파일 삭제됨"
else
    echo " [--] Phase 0 완료 파일 없음"
fi

# v4.1: No-tracker 카운터 삭제
NO_TRACKER_COUNT="${STATE_DIR}/no-tracker-count"
if [ -f "$NO_TRACKER_COUNT" ]; then
    rm "$NO_TRACKER_COUNT"
    echo " [OK] No-tracker 카운터 삭제됨"
else
    echo " [--] No-tracker 카운터 없음"
fi

# v4.1: TASK_COMPLETE 신호 파일 삭제
TASK_COMPLETE="${STATE_DIR}/TASK_COMPLETE"
if [ -f "$TASK_COMPLETE" ]; then
    rm "$TASK_COMPLETE"
    echo " [OK] TASK_COMPLETE 신호 파일 삭제됨"
else
    echo " [--] TASK_COMPLETE 신호 파일 없음"
fi

# v5.4.3: CONTEXT_WARNING 파일 삭제
CONTEXT_WARNING="${STATE_DIR}/CONTEXT_WARNING"
if [ -f "$CONTEXT_WARNING" ]; then
    rm "$CONTEXT_WARNING"
    echo " [OK] Context 경고 파일 삭제됨"
else
    echo " [--] Context 경고 파일 없음"
fi

# 로그 백업 (최근 500줄만 유지)
if [ -f "$LOG_FILE" ]; then
    tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    echo " [OK] 로그 파일 정리됨 (최근 500줄 유지)"
fi

echo "========================================"
echo ""
echo "세션 리셋 완료!"
echo ""
echo "사용법:"
echo "  - 자율 모드 시작: /autonomous [작업내용]"
echo "  - 긴급 중단: touch ~/.claude/state/EMERGENCY_STOP"
echo "  - 상태 확인: .claude/hooks/check-status.sh"
echo ""
