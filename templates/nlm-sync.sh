#!/bin/zsh
# ============================================================================
# nlm-sync.sh — NotebookLM 소스 동기화 (범용 템플릿)
# ============================================================================
#
# 사용법:
#   zsh scripts/nlm-sync.sh <파일경로> [노트북키]
#   bash scripts/nlm-sync.sh <파일경로> [노트북키]    # Linux (bash 4+)
#
# 예시:
#   zsh scripts/nlm-sync.sh CLAUDE.md
#   zsh scripts/nlm-sync.sh docs/technical-reference.html main
#
# OS별 주의사항:
#   macOS: #!/bin/zsh + typeset -A (기본 bash 3.2는 declare -A 미지원)
#   Linux: #!/bin/bash + declare -A (bash 4+)
#   Windows: Git Bash 또는 WSL에서 실행
#
# 설치: autonomous 레포 templates/에서 프로젝트 scripts/로 복사 후
#       아래 "프로젝트별 수정 영역"만 수정하면 됩니다.
# ============================================================================

# nlm CLI PATH 설정 (환경에 맞게 수정)
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"

# ── 프로젝트별 수정 영역 ──────────────────────────
# >>> 여기만 수정하면 됩니다 <<<

# 1. 노트북 ID 매핑
#    nlm notebook list 명령으로 확인 후 입력하세요.
#
#    macOS (zsh):
typeset -A NOTEBOOKS
#    Linux (bash 4+) — 위 줄을 아래로 교체:
#    declare -A NOTEBOOKS

NOTEBOOKS[main]="<YOUR_NOTEBOOK_ID>"
# 노트북이 여러 개면 추가:
# NOTEBOOKS[docs]="<ANOTHER_NOTEBOOK_ID>"

# 2. 파일명→노트북 자동 매핑
#    키: 파일명 (basename), 값: 위 NOTEBOOKS의 키
#
#    macOS (zsh):
typeset -A FILE_NOTEBOOK_MAP
#    Linux (bash 4+) — 위 줄을 아래로 교체:
#    declare -A FILE_NOTEBOOK_MAP

FILE_NOTEBOOK_MAP[CLAUDE.md]="main"
FILE_NOTEBOOK_MAP[PROJECT_DOCUMENTATION.md]="main"
# 추가 파일 매핑:
# FILE_NOTEBOOK_MAP[technical-reference.html]="main"
# FILE_NOTEBOOK_MAP[API.md]="docs"

# ── 공통 로직 (수정 불필요) ────────────────────────

FILE_PATH="$1"
NOTEBOOK_KEY="$2"

if [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <file-path> [notebook-key]"
  echo "Notebook keys: ${(k)NOTEBOOKS}"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "ERROR: File not found: $FILE_PATH"
  exit 1
fi

FILENAME=$(basename "$FILE_PATH")

# 키 자동 감지
if [ -z "$NOTEBOOK_KEY" ]; then
  NOTEBOOK_KEY="${FILE_NOTEBOOK_MAP[$FILENAME]}"
  if [ -z "$NOTEBOOK_KEY" ]; then
    NOTEBOOK_KEY="main"
    echo "WARN: No mapping for '$FILENAME', defaulting to 'main'"
  fi
fi

NOTEBOOK_ID="${NOTEBOOKS[$NOTEBOOK_KEY]}"
if [ -z "$NOTEBOOK_ID" ]; then
  echo "ERROR: Unknown notebook key: $NOTEBOOK_KEY"
  exit 1
fi

echo "=== NotebookLM Sync ==="
echo "File:     $FILE_PATH ($FILENAME)"
echo "Notebook: $NOTEBOOK_KEY ($NOTEBOOK_ID)"
echo ""

# 0. 인증 확인 (만료 시 자동 재인증)
ensure_auth() {
  if ! nlm source list "$NOTEBOOK_ID" >/dev/null 2>&1; then
    echo "[AUTH] 인증 만료 감지 → 자동 재인증..."
    if nlm login 2>&1 | grep -q "Successfully"; then
      echo "[AUTH] 재인증 성공"
    else
      echo "[AUTH] 재인증 실패 — 수동 nlm login 필요"
      exit 1
    fi
  fi
}
ensure_auth

# 1. 기존 소스 찾기 (HTML은 .txt 확장자로 저장됨)
SEARCH_TITLE="$FILENAME"
if [[ "$FILENAME" == *.html ]]; then
  SEARCH_TITLE="${FILENAME%.html}.txt"
fi
echo "[1/3] Finding existing source '$SEARCH_TITLE'..."
SOURCE_ID=$(nlm source list "$NOTEBOOK_ID" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data:
    if s['title'] in ('$SEARCH_TITLE', '$FILENAME'):
        print(s['id'])
        break
" 2>/dev/null)

# 2. 기존 소스 삭제
if [ -n "$SOURCE_ID" ]; then
  echo "[2/3] Deleting old source: $SOURCE_ID"
  nlm source delete "$SOURCE_ID" --confirm 2>&1
else
  echo "[2/3] No existing source found, skipping delete."
fi

# 3. 새 소스 업로드
echo "[3/3] Uploading new source..."

# HTML 파일은 nlm이 직접 지원하지 않으므로 텍스트 변환 후 업로드
if [[ "$FILENAME" == *.html ]]; then
  TMPFILE="/tmp/nlm-${FILENAME%.html}.txt"
  python3 -c "
from html.parser import HTMLParser
import re

class T(HTMLParser):
    def __init__(self):
        super().__init__()
        self.t = []
        self.skip = False
    def handle_starttag(self, tag, attrs):
        if tag in ('script','style'): self.skip = True
    def handle_endtag(self, tag):
        if tag in ('script','style'): self.skip = False
        if tag in ('h1','h2','h3','h4','h5','h6','p','div','li','tr','br','hr','section'): self.t.append('\n')
    def handle_data(self, data):
        if not self.skip: self.t.append(data)

with open('$FILE_PATH') as f: html = f.read()
p = T(); p.feed(html)
text = re.sub(r'\n{3,}', '\n\n', ''.join(p.t)).strip()
with open('$TMPFILE', 'w') as f: f.write(text)
print(f'Converted {len(html)} -> {len(text)} chars')
" 2>&1
  nlm source add "$NOTEBOOK_ID" --file "$TMPFILE" --wait --title "$FILENAME" 2>&1
  rm -f "$TMPFILE"
else
  nlm source add "$NOTEBOOK_ID" --file "$FILE_PATH" --wait 2>&1
fi

echo ""
echo "=== Sync complete ==="
