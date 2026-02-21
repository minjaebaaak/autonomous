#!/bin/zsh
# conversation-sync.sh — Claude Code 세션 대화 → NotebookLM 자동 동기화
# autonomous v4.7: "기억하지 말고 기록하라" — 대화까지 보존
#
# 사용법:
#   bash scripts/conversation-sync.sh                          # 최신 세션
#   bash scripts/conversation-sync.sh --title "작업명"          # 타이틀 지정
#   bash scripts/conversation-sync.sh --file <id>.jsonl         # 특정 세션
#   bash scripts/conversation-sync.sh --recent 5               # 최근 N개
#   bash scripts/conversation-sync.sh --latest --if-significant # Stop 훅용

export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"

# ── 프로젝트별 수정 영역 ──────────────────────────
# 1. 노트북 설정 — 대화용 노트북
NOTEBOOK_ALIAS="<PROJECT>-conv"          # 예: sm-conv, taxnavi-conv
NOTEBOOK_ID="<YOUR_CONV_NOTEBOOK_ID>"    # nlm notebook list로 확인

# 2. 세션 디렉토리 — Claude Code가 JSONL을 저장하는 경로
#    `ls ~/.claude/projects/` 에서 프로젝트 해시 확인
JSONL_DIR="$HOME/.claude/projects/<YOUR_PROJECT_HASH>"

# 3. 로컬 인덱스 — 동기화 이력 저장
INDEX_FILE="$HOME/.claude/conversation-index.json"

# 4. 프로젝트명 — 세션 헤더에 표시
PROJECT_NAME="<YOUR_PROJECT_NAME>"       # 예: ShareManager, TaxNavi

# ── 공통 설정 (수정 불필요) ───────────────────────
MAX_WORDS=400000  # NotebookLM 한도 500K의 80%
MIN_TURNS=10      # --if-significant: 최소 턴 수
MIN_SIZE=5120     # --if-significant: 최소 텍스트 크기 (bytes)

# ── 인자 파싱 ─────────────────────────────────────
TITLE=""
FILE=""
RECENT=0
LATEST=false
IF_SIGNIFICANT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    --recent) RECENT="$2"; shift 2 ;;
    --latest) LATEST=true; shift ;;
    --if-significant) IF_SIGNIFICANT=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── 공통 로직 (수정 불필요) ───────────────────────

# 인증 확인
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

# 단일 세션 처리
process_session() {
  local JSONL_PATH="$1"
  local SESSION_TITLE="$2"
  local BASENAME=$(basename "$JSONL_PATH" .jsonl)
  local SHORT_ID="${BASENAME:0:8}"

  echo "=== Conversation Sync ==="
  echo "File: $JSONL_PATH"
  echo "Title: ${SESSION_TITLE:-auto}"
  echo ""

  # 타이틀 결정 (미지정 시 첫 사용자 메시지에서 자동 추출)
  if [ -z "$SESSION_TITLE" ]; then
    SESSION_TITLE=$(python3 -c "
import json, re, sys

SKIP_PATTERNS = [
    r'완료되었습니다', r'continue.*conversation', r'Please continue',
    r'세션.*시작', r'left off', r'previous conversation',
]

def is_meaningful(text):
    for pat in SKIP_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return False
    clean = re.sub(r'<[^>]+>', '', text).strip()
    if len(clean) < 10:
        return False
    return True

def extract_topic(jsonl_path):
    with open(jsonl_path, 'r') as f:
        for line in f:
            try:
                obj = json.loads(line)
            except:
                continue
            if obj.get('type') != 'user':
                continue
            msg = obj.get('message', {})
            content = msg.get('content', '')
            if isinstance(content, list):
                text = ' '.join(c.get('text', '') for c in content if isinstance(c, dict) and c.get('type') == 'text')
            elif isinstance(content, str):
                text = content
            else:
                continue
            if not is_meaningful(text):
                continue
            args_match = re.search(r'<command-args>(.*?)</command-args>', text, re.DOTALL)
            if args_match:
                text = args_match.group(1).strip()
            text = re.sub(r'<[^>]+>', '', text).strip()
            text = re.sub(r'https?://\S+', '', text).strip()
            words = re.findall(r'[가-힣a-zA-Z0-9]{2,}', text)[:5]
            if words:
                topic = '-'.join(words)[:40]
                topic = re.sub(r'-+', '-', topic).strip('-').lower()
                if topic:
                    print(topic)
                    sys.exit(0)
    print('session')

extract_topic('$JSONL_PATH')
" 2>/dev/null)
    SESSION_TITLE="${SESSION_TITLE:-session}"
  fi

  # 추출
  echo "[1/3] Extracting conversation text..."
  RESULT=$(python3 << PYEOF
import json, sys, os, re
from datetime import datetime

JSONL_PATH = "$JSONL_PATH"
OUTPUT_PREFIX = "$SESSION_TITLE"
MAX_WORDS = $MAX_WORDS
PROJECT_NAME = "$PROJECT_NAME"

def extract_text_from_content(content):
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, str):
                parts.append(item.strip())
            elif isinstance(item, dict):
                ct = item.get('type', '')
                if ct == 'text':
                    text = item.get('text', '').strip()
                    if text:
                        parts.append(text)
                elif ct == 'tool_use':
                    tool = item.get('name', 'unknown')
                    inp = item.get('input', {})
                    if isinstance(inp, dict):
                        summary_parts = []
                        for k in ('file_path', 'command', 'pattern', 'query', 'url'):
                            if k in inp:
                                val = str(inp[k])[:100]
                                summary_parts.append(f'{k}={val}')
                        summary = ', '.join(summary_parts) if summary_parts else '...'
                    else:
                        summary = '...'
                    parts.append(f'[Tool: {tool}({summary})]')
        return '\n'.join(parts)
    return ''

messages = []
turn_count = 0
session_id = ''
session_date = ''

with open(JSONL_PATH, 'r') as f:
    for line in f:
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg_type = obj.get('type', '')
        if msg_type == 'user' and not session_id:
            session_id = obj.get('sessionId', '')
            ts = obj.get('timestamp', '')
            if ts:
                try:
                    dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                    session_date = dt.strftime('%Y-%m-%d')
                except:
                    session_date = ''
        if msg_type not in ('user', 'assistant'):
            continue
        msg = obj.get('message', {})
        content = msg.get('content', '')
        text = extract_text_from_content(content)
        if not text:
            continue
        role = 'USER' if msg_type == 'user' else 'ASSISTANT'
        messages.append(f'### {role}\n{text}')
        if msg_type == 'user':
            turn_count += 1

if not session_date:
    session_date = '$(date +%Y-%m-%d)'

header = f"""# Session: {OUTPUT_PREFIX}
- Date: {session_date}
- Session ID: {session_id[:12] if session_id else 'unknown'}
- Turns: {turn_count}
- Project: {PROJECT_NAME}

---

"""

full_text = header + '\n\n'.join(messages)
full_text = re.sub(r'\n{4,}', '\n\n\n', full_text)

words = full_text.split()
total_words = len(words)

files = []
if total_words <= MAX_WORDS:
    output_path = f'/tmp/conversation-{OUTPUT_PREFIX}-1.md'
    with open(output_path, 'w') as f:
        f.write(full_text)
    files.append(output_path)
else:
    part = 1
    start = 0
    while start < total_words:
        end = min(start + MAX_WORDS, total_words)
        chunk = ' '.join(words[start:end])
        if part > 1:
            chunk = f"# Session: {OUTPUT_PREFIX} (Part {part})\n---\n\n{chunk}"
        output_path = f'/tmp/conversation-{OUTPUT_PREFIX}-{part}.md'
        with open(output_path, 'w') as f:
            f.write(chunk)
        files.append(output_path)
        part += 1
        start = end

print(json.dumps({
    'files': files,
    'total_words': total_words,
    'total_chars': len(full_text),
    'turn_count': turn_count,
    'parts': len(files),
    'session_date': session_date
}))
PYEOF
  )

  if [ $? -ne 0 ]; then
    echo "텍스트 추출 실패"
    return 1
  fi

  # 결과 파싱
  TOTAL_WORDS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_words'])")
  TOTAL_CHARS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_chars'])")
  TURN_COUNT=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['turn_count'])")
  PARTS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['parts'])")
  FILES=$(echo "$RESULT" | python3 -c "import json,sys; print('\n'.join(json.load(sys.stdin)['files']))")

  echo "  Words: $TOTAL_WORDS, Chars: $TOTAL_CHARS, Turns: $TURN_COUNT, Parts: $PARTS"

  # --if-significant 체크
  if $IF_SIGNIFICANT; then
    if [ "$TURN_COUNT" -lt "$MIN_TURNS" ]; then
      echo "[SKIP] 턴 수 부족 ($TURN_COUNT < $MIN_TURNS)"
      rm -f /tmp/conversation-${SESSION_TITLE}-*.md
      return 0
    fi
    if [ "$TOTAL_CHARS" -lt "$MIN_SIZE" ]; then
      echo "[SKIP] 텍스트 크기 부족 ($TOTAL_CHARS < $MIN_SIZE bytes)"
      rm -f /tmp/conversation-${SESSION_TITLE}-*.md
      return 0
    fi
  fi

  # 인증 확인
  echo "[2/3] Checking authentication..."
  ensure_auth

  # 업로드
  echo "[3/3] Uploading $PARTS note(s)..."
  local SEQ=1
  local TIME_TAG=$(date +%H%M%S)

  echo "$FILES" | while IFS= read -r FILEPATH; do
    if [ -z "$FILEPATH" ]; then continue; fi
    local NOTE_TITLE="${SESSION_TITLE}-$(date +%Y-%m-%d)-${SEQ}-${TIME_TAG}"

    # 중복 방지: 동일 제목 기존 소스 삭제
    local OLD_ID=$(nlm source list "$NOTEBOOK_ID" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data:
    if s.get('title') == '$NOTE_TITLE':
        print(s['id']); break
" 2>/dev/null)
    if [ -n "$OLD_ID" ]; then
      echo "  → Replacing existing: $NOTE_TITLE ($OLD_ID)"
      nlm source delete "$OLD_ID" --confirm 2>&1
    fi

    echo "  → Uploading: $NOTE_TITLE"
    nlm source add "$NOTEBOOK_ID" --file "$FILEPATH" --wait --title "$NOTE_TITLE" 2>&1
    rm -f "$FILEPATH"
    SEQ=$((SEQ + 1))
  done

  # 로컬 인덱스에 기록
  local SESSION_DATE=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('session_date',''))" 2>/dev/null)
  python3 -c "
import json, os
index_path = '$INDEX_FILE'
entry = {
    'date': '${SESSION_DATE:-$(date +%Y-%m-%d)}',
    'topic': '$SESSION_TITLE',
    'notebook': '$NOTEBOOK_ALIAS',
    'source_title': '${SESSION_TITLE}-$(date +%Y-%m-%d)-1-$(date +%H%M%S)',
    'session_id': '$SHORT_ID',
    'words': $TOTAL_WORDS,
    'turns': $TURN_COUNT
}
data = []
if os.path.exists(index_path):
    try:
        with open(index_path) as f:
            data = json.load(f)
    except:
        data = []
data.append(entry)
with open(index_path, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f'  → Index updated: {len(data)} entries')
" 2>/dev/null

  echo ""
  echo "=== Sync complete ($PARTS note(s)) ==="
}

# ── 메인 ──────────────────────────────────────────

get_latest_jsonl() {
  ls -t "$JSONL_DIR"/*.jsonl 2>/dev/null | head -1
}

get_recent_jsonls() {
  local N="$1"
  ls -t "$JSONL_DIR"/*.jsonl 2>/dev/null | head -"$N"
}

if [ -n "$FILE" ]; then
  if [[ "$FILE" != /* ]]; then
    FILE="$JSONL_DIR/$FILE"
  fi
  if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    exit 1
  fi
  process_session "$FILE" "$TITLE"

elif [ "$RECENT" -gt 0 ]; then
  get_recent_jsonls "$RECENT" | while IFS= read -r JSONL_PATH; do
    SHORT_ID=$(basename "$JSONL_PATH" .jsonl)
    SHORT_ID="${SHORT_ID:0:8}"
    process_session "$JSONL_PATH" "${TITLE:-session-${SHORT_ID}}"
    echo ""
  done

else
  LATEST_FILE=$(get_latest_jsonl)
  if [ -z "$LATEST_FILE" ]; then
    echo "ERROR: No JSONL files found in $JSONL_DIR"
    exit 1
  fi
  process_session "$LATEST_FILE" "$TITLE"
fi
