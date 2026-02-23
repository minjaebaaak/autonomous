#!/bin/bash
# ==============================================================================
# Code Pattern Check - PostToolUse Edit|Write 안티패턴 자동 검증
# ==============================================================================
#
# Hook Type: PostToolUse Edit|Write (프로젝트 .claude/settings.local.json에 등록)
# 목적: 프로젝트별 안티패턴 자동 경고 (차단하지 않음)
#
# 사용법:
#   1. 이 파일을 프로젝트에 복사
#   2. 아래 PATTERNS 배열에 프로젝트 고유 안티패턴 추가
#   3. settings-local.json에 PostToolUse 훅으로 등록
#
# 패턴 형식:
#   "검색패턴|제외패턴|경고메시지"
#   - 검색패턴: grep -E로 검색할 정규식
#   - 제외패턴: 이 패턴이 있으면 경고 제외 (올바른 사용)
#   - 경고메시지: 위반 시 출력할 메시지
#
# 설치:
#   cp templates/hooks/code-pattern-check.sh <PROJECT>/.claude/hooks/
#   chmod +x <PROJECT>/.claude/hooks/code-pattern-check.sh
#   # settings-local.json 참조하여 PostToolUse Edit|Write 훅 등록
#
# ==============================================================================

# stdin에서 JSON 읽기
INPUT=$(cat)

# file_path 추출 (tool_input에서)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tip = data.get('tool_input', {})
    print(tip.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# 파일 경로가 없으면 즉시 종료
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# ===== 프로젝트별 수정 영역 =====
# 대상 확장자 (이 확장자가 아니면 즉시 종료)
TARGET_EXTENSIONS=".py"

# 안티패턴 정의: "검색패턴|제외패턴|경고메시지"
# 아래는 예시입니다. 프로젝트에 맞게 수정하세요.
PATTERNS=(
    # 예시 1: get_text() 사용 시 clean_link_title 미사용 경고
    # "\.get_text\(|clean_link_title|get_text() 사용 but clean_link_title 미사용 → clean_link_title(link) 필수"

    # 예시 2: .isoformat() 사용 시 utc_to_kst 미사용 경고
    # "\.isoformat\(\)|utc_to_kst|naive_to_kst_aware|.isoformat() 사용 but utc_to_kst() 미사용 → utc_to_kst() 변환 후 .isoformat() 필수"

    # 예시 3: get_text(strip=True) 사용 시 separator 미사용 경고
    # "get_text\(strip=True\)|get_text\(separator=|get_text(strip=True) 사용 but separator 미지정 → separator=' ' 추가 필요"
)
# ===== 수정 영역 끝 =====

# 대상 확장자 체크
match_ext=false
for ext in $TARGET_EXTENSIONS; do
    if [[ "$FILE_PATH" == *"$ext" ]]; then
        match_ext=true
        break
    fi
done

if [ "$match_ext" = false ]; then
    exit 0
fi

# 파일이 존재하지 않으면 즉시 종료
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# 패턴이 비어 있으면 즉시 종료
if [ ${#PATTERNS[@]} -eq 0 ]; then
    exit 0
fi

WARNINGS=""

# 각 패턴 검사
for pattern_def in "${PATTERNS[@]}"; do
    # 빈 줄이나 주석 건너뛰기
    [[ -z "$pattern_def" || "$pattern_def" == \#* ]] && continue

    # 구분자로 분리
    IFS='|' read -r search_pattern exclude_pattern warning_msg <<< "$pattern_def"

    # 검색 패턴 발견 + 제외 패턴 미발견 → 경고
    if grep -qE "$search_pattern" "$FILE_PATH" 2>/dev/null; then
        if ! grep -qE "$exclude_pattern" "$FILE_PATH" 2>/dev/null; then
            WARNINGS="${WARNINGS}
  ⚠️  ${warning_msg}
      → 파일: $FILE_PATH"
        fi
    fi
done

# 경고가 있으면 stderr로 출력
if [ -n "$WARNINGS" ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo " 🔍 Code Pattern Check — 안티패턴 감지" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "$WARNINGS" >&2
    echo "" >&2
    echo "  (경고만 — 작업은 차단되지 않습니다)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
fi

# 항상 exit 0 — 경고만, 차단하지 않음
exit 0
