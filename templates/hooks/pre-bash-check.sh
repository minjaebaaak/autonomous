#!/bin/bash
# ==============================================================================
# Pre-Bash Check - 위험 명령어 사전 차단
# ==============================================================================
#
# Hook Type: PreToolUse Bash (프로젝트 .claude/settings.local.json에 등록)
#
# 환경변수:
#   CLAUDE_TOOL_INPUT: 도구 입력 JSON (command 필드 포함)
#
# 설치:
#   cp templates/hooks/pre-bash-check.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/pre-bash-check.sh
#   # settings-local.json 참조하여 PreToolUse Bash 훅 등록
#
# 반환값:
#   0: 허용 (명령어 실행)
#   1: 차단 (명령어 실행 중단)
#
# ==============================================================================

set -e

STATE_DIR="${HOME}/.claude/state"
LOG_FILE="${STATE_DIR}/pre-bash-check.log"

# 위험한 명령어 패턴 (정규식)
DANGEROUS_PATTERNS=(
    'rm[[:space:]]+-rf[[:space:]]+/'
    'rm[[:space:]]+-rf[[:space:]]+~'
    'rm[[:space:]]+-rf[[:space:]]+\$HOME'
    'rm[[:space:]]+-rf[[:space:]]+\*'
    'rm[[:space:]]+-rf[[:space:]]+\.'
    'dd[[:space:]]+if='
    'mkfs'
    '>[[:space:]]*/dev/sd'
    'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
    ':\(\)[[:space:]]*\{[[:space:]]*:|:&[[:space:]]*\};:'
    'git[[:space:]]+push[[:space:]]+--force'
    'git[[:space:]]+push[[:space:]]+-f'
    'git[[:space:]]+reset[[:space:]]+--hard'
    'DROP[[:space:]]+DATABASE'
    'DROP[[:space:]]+TABLE'
    'TRUNCATE[[:space:]]+TABLE'
    'DELETE[[:space:]]+FROM.*WHERE[[:space:]]+1'
    'sudo[[:space:]]+rm[[:space:]]+-rf'
    'sudo[[:space:]]+dd'
    'curl.*\|.*sh'
    'wget.*\|.*sh'
    'curl.*\|.*bash'
    'wget.*\|.*bash'
)

# 상태 디렉토리 생성
mkdir -p "$STATE_DIR"

# 로그 함수
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 명령어 추출 (CLAUDE_TOOL_INPUT에서)
get_command() {
    if [ -n "$CLAUDE_TOOL_INPUT" ]; then
        # jq로 command 필드 추출
        if command -v jq &> /dev/null; then
            echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null
        else
            # jq 없으면 간단한 grep 사용
            echo "$CLAUDE_TOOL_INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/'
        fi
    fi
}

# 위험 명령어 체크
check_dangerous() {
    local cmd="$1"

    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$cmd" | grep -qiE "$pattern"; then
            log "차단: 위험한 명령어 감지 - 패턴: $pattern, 명령어: $cmd"
            echo ""
            echo "========================================"
            echo " 위험 명령어 차단"
            echo "========================================"
            echo " 패턴: $pattern"
            echo " 명령어: ${cmd:0:100}..."
            echo ""
            echo " 이 명령어는 시스템에 심각한 손상을"
            echo " 일으킬 수 있어 차단되었습니다."
            echo "========================================"
            return 1
        fi
    done

    return 0
}

# 메인 로직
main() {
    local command=$(get_command)

    if [ -z "$command" ]; then
        # 명령어 없으면 통과
        exit 0
    fi

    log "검사: $command"

    if ! check_dangerous "$command"; then
        exit 1  # 차단
    fi

    exit 0  # 허용
}

main "$@"
