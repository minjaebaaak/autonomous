# 새 프로젝트에 autonomous 적용하기 (A-Z 가이드)

> autonomous v4.7을 새 프로젝트에 처음부터 끝까지 설정하는 완전 가이드입니다.
> 기본 설치(Phase 1~2)만으로도 autonomous 핵심 기능을 사용할 수 있습니다.
> Phase 3~5는 선택사항이며 NotebookLM 통합, 대화 동기화, 훅 등 고급 기능을 추가합니다.

---

## Prerequisites (사전 준비)

### 필수

| 도구 | 용도 | 설치 |
|------|------|------|
| **Claude Code CLI** | autonomous 실행 환경 | [공식 문서](https://docs.anthropic.com/en/docs/claude-code) |
| **Python 3.x** | 동기화 스크립트 실행 | `brew install python3` / `apt install python3` |

### 선택 (Phase 3~5 사용 시)

| 도구 | 용도 | 설치 |
|------|------|------|
| **nlm CLI** | NotebookLM 연동 | [`guides/notebooklm-setup.md`](notebooklm-setup.md) Step 0 참조 |
| **repomix MCP** | 코드 묶음 + 토큰 절약 | Claude Code 설정에서 플러그인 활성화 |
| **jq** | 훅 스크립트에서 JSON 처리 | `brew install jq` / `apt install jq` |

---

## Phase 1: 기본 설치 (5분)

### 1-1. autonomous.md 전역 설치

```bash
mkdir -p ~/.claude/commands
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

이것만으로 모든 프로젝트에서 `/autonomous [작업]` 사용 가능.

### 1-2. 전역 CLAUDE.md 설치 (권장)

```bash
curl -o ~/.claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
```

전역 CLAUDE.md는 한국어 응답, autonomous.md 관리 규칙, 양방향 동기화 워크플로우를 포함합니다.

### 1-3. 설치 확인

```bash
# autonomous.md 존재 확인
ls -la ~/.claude/commands/autonomous.md

# Claude Code에서 테스트
claude
> /autonomous 현재 상태 확인해줘
```

---

## Phase 2: 프로젝트 구조 생성 (10분)

### 2-1. 디렉토리 구조 생성

```bash
cd /path/to/your/project

# 프로젝트 구조 생성
mkdir -p scripts
mkdir -p docs
mkdir -p .claude/hooks
mkdir -p ~/.claude/state
```

### 2-2. 프로젝트 CLAUDE.md 작성

프로젝트 루트에 `CLAUDE.md`를 생성합니다. 이것이 프로젝트별 규칙의 Single Source of Truth입니다.

**최소 템플릿:**

```markdown
# Claude Code Instructions

## 필수 준수 사항

### 1. 한국어 사용
- 한국어로 사고하고, 한국어로 소통할 것

### 2. 프로젝트 정보

| 분류 | 기술 |
|------|------|
| Backend | (예: FastAPI, Django, Express) |
| Frontend | (예: Next.js, Vue, React) |
| Database | (예: PostgreSQL, SQLite, MongoDB) |

### 3. 자동 검증 의무

모든 코드 작업 완료 후:
1. 빌드 검증 실행
2. 실패 시 자동 수정 (최대 3회)

---

## /autonomous Phase 확장 설정

> autonomous.md의 Phase에서 "CLAUDE.md Phase 확장 참조"라고 나오면 여기를 봅니다.

- **Phase 0 기술문서**: `(기술문서 경로, 없으면 생략)`
- **Phase 2 파일→문서 매핑**: `(코드↔문서 매핑, 없으면 생략)`
- **Phase 7**: 검증 명령어:
  ```bash
  # (프로젝트별 빌드/테스트 명령)
  ```
```

### 2-3. 설정 확인

```bash
# 구조 확인
ls -la CLAUDE.md
ls -la scripts/
ls -la .claude/hooks/

# Claude Code 실행
claude
> /autonomous 프로젝트 구조를 확인해줘
```

**여기까지 완료하면 autonomous 핵심 기능(Phase 0~9) 사용 가능.**

---

## Phase 3: NotebookLM 통합 (15분) [선택]

> NotebookLM = 무료 외부 지식 저장소. 기술문서, 규칙, 코드를 영구 보존하고 질의할 수 있습니다.
> 토큰 절약 효과: 기술문서 Read(~47K 토큰) → nlm query(~3K 토큰)

### 3-1. nlm CLI 설치

상세 절차: [`guides/notebooklm-setup.md`](notebooklm-setup.md) Step 0 참조

```bash
# macOS
pip install --user nlm
# 또는
uv tool install nlm

# 인증
nlm login
# → Chrome이 열리고 Google 계정으로 자동 인증
```

### 3-2. 노트북 생성 (카테고리별 권장)

```bash
# 단일 노트북 (심플)
nlm notebook create "my-project"

# 카테고리별 분리 (권장 — v4.7)
nlm notebook create "myproject-rules"   # 규칙/교훈
nlm notebook create "myproject-tech"    # 기술/코드
nlm notebook create "myproject-conv"    # 대화 기록
```

생성된 노트북 ID를 메모합니다:
```bash
nlm notebook list
# → ID: af7bfaf0-5d0f-... (rules)
# → ID: 8502add4-4166-... (tech)
# → ID: 65e68fc7-a8ff-... (conv)
```

### 3-3. nlm-sync.sh 설정

```bash
# 템플릿 복사
cp /path/to/autonomous/templates/nlm-sync.sh scripts/nlm-sync.sh
chmod +x scripts/nlm-sync.sh
```

`scripts/nlm-sync.sh` 상단의 "프로젝트별 수정 영역"을 편집:

```bash
# 1. 노트북 ID 매핑
typeset -A NOTEBOOKS
NOTEBOOKS[rules]="<YOUR_RULES_NOTEBOOK_ID>"
NOTEBOOKS[tech]="<YOUR_TECH_NOTEBOOK_ID>"
NOTEBOOKS[conv]="<YOUR_CONV_NOTEBOOK_ID>"

# 2. 파일→노트북 자동 매핑
typeset -A FILE_NOTEBOOK_MAP
FILE_NOTEBOOK_MAP[CLAUDE.md]="rules"
FILE_NOTEBOOK_MAP[PROJECT_DOCUMENTATION.md]="tech"
# 필요에 따라 추가
```

### 3-4. repomix-sync.sh 설정

```bash
# 템플릿 복사
cp /path/to/autonomous/templates/repomix-sync.sh scripts/repomix-sync.sh
chmod +x scripts/repomix-sync.sh
```

상단 설정 수정:
```bash
# Repomix 대상 — 코드 스냅샷으로 NotebookLM에 업로드
REPOMIX_TARGETS=(
  "backend/app/**/*.py"
  "frontend/src/**/*.tsx"
)
```

### 3-5. CLAUDE.md Phase 확장 업데이트

CLAUDE.md 하단의 Phase 확장 섹션에 NotebookLM 설정 추가:

```markdown
- **Phase 0 NotebookLM**: 카테고리별 노트북 (v4.7)
  - 규칙: `nlm notebook query <RULES_ID> "..."`
  - 기술: `nlm notebook query <TECH_ID> "..."`
  - 대화: `nlm notebook query <CONV_ID> "..."`
  - 기술표 동기화: `bash scripts/nlm-sync.sh docs/technical-reference.html`
  - 전체 동기화: `bash scripts/repomix-sync.sh`
  - 자동 동기화 대상: `CLAUDE.md`, `PROJECT_DOCUMENTATION.md`
```

### 3-6. 초기 소스 업로드

```bash
# CLAUDE.md → rules 노트북
bash scripts/nlm-sync.sh CLAUDE.md

# 기술문서 → tech 노트북 (있는 경우)
bash scripts/nlm-sync.sh docs/technical-reference.html

# 확인
nlm source list "<RULES_NOTEBOOK_ID>"
```

### 3-7. 동기화 테스트

```bash
# nlm query 테스트
nlm notebook query "<RULES_NOTEBOOK_ID>" "이 프로젝트의 빌드 검증 명령은?"
```

---

## Phase 4: 대화 동기화 설정 (10분) [선택]

> 세션 대화를 NotebookLM에 자동 보존. 컨텍스트 압축으로 사라지는 논의를 영구 보존합니다.
> Phase 3 완료 필수 (대화 노트북 필요).

### 4-1. conversation-sync.sh 설정

```bash
# 템플릿 복사
cp /path/to/autonomous/templates/conversation-sync.sh scripts/conversation-sync.sh
chmod +x scripts/conversation-sync.sh
```

상단 "프로젝트별 수정 영역" 편집:

```bash
# 1. 대화용 노트북
NOTEBOOK_ALIAS="myproject-conv"
NOTEBOOK_ID="<YOUR_CONV_NOTEBOOK_ID>"

# 2. 세션 디렉토리 (Claude Code JSONL 저장 경로)
#    확인: ls ~/.claude/projects/
JSONL_DIR="$HOME/.claude/projects/<YOUR_PROJECT_HASH>"

# 3. 프로젝트명
PROJECT_NAME="MyProject"
```

**프로젝트 해시 확인 방법:**
```bash
ls ~/.claude/projects/
# → -Users-username-path-to-project  (경로를 '-'로 연결)
```

### 4-2. 수동 동기화 테스트

```bash
# 최신 세션 동기화
bash scripts/conversation-sync.sh

# 타이틀 지정
bash scripts/conversation-sync.sh --title "initial-setup"
```

### 4-3. CLAUDE.md Phase 확장 업데이트

```markdown
- **Phase 0 대화 동기화** (v4.7):
  - 세션 JSONL: `~/.claude/projects/<PROJECT_HASH>/*.jsonl`
  - 수동 동기화: `bash scripts/conversation-sync.sh --title "<작업명>"`
```

---

## Phase 5: 훅 설정 (5분) [선택]

> 훅 = Claude Code의 이벤트(세션 종료, 도구 사용 등)에 자동 반응하는 스크립트.
> 세션 종료 시 자동 대화 동기화, 알림, 무한루프 방지를 담당합니다.

### 5-1. 훅 스크립트 복사

```bash
# 알림 훅
cp /path/to/autonomous/templates/hooks/notify-user.sh .claude/hooks/notify-user.sh
chmod +x .claude/hooks/notify-user.sh

# 안전 정지 훅 (Ralph Loop용)
cp /path/to/autonomous/templates/hooks/safe-stop-hook.sh .claude/hooks/safe-stop-hook.sh
chmod +x .claude/hooks/safe-stop-hook.sh
```

### 5-2. settings.local.json 설정

```bash
# 템플릿 복사
cp /path/to/autonomous/templates/settings-local.json .claude/settings.local.json
```

`<PROJECT_PATH>`를 실제 프로젝트 절대 경로로 교체:

```bash
# macOS
sed -i '' "s|<PROJECT_PATH>|$(pwd)|g" .claude/settings.local.json

# Linux
sed -i "s|<PROJECT_PATH>|$(pwd)|g" .claude/settings.local.json
```

### 5-3. 전역 settings.json에 Stop 훅 추가 (대화 동기화용)

```bash
# ~/.claude/settings.json의 Stop 훅에 추가:
# "bash /path/to/project/scripts/conversation-sync.sh --latest --if-significant 2>/dev/null &"
```

> **참고**: settings.local.json은 프로젝트별 설정, settings.json은 전역 설정입니다.
> Stop 훅은 settings.local.json에 넣으면 해당 프로젝트에서만 동작합니다.

### 5-4. 훅 테스트

```bash
# 알림 테스트
.claude/hooks/notify-user.sh "테스트 알림" "My Project"

# 안전 정지 초기화
rm -f ~/.claude/state/stop-hook-state.json
```

---

## Phase 6: 검증

### 6-1. 기본 검증 (Phase 1~2)

```bash
claude
> /autonomous 프로젝트 구조를 확인하고 CLAUDE.md 규칙을 요약해줘
```

- Phase 0이 실행되는지 확인
- CLAUDE.md가 정상 로드되는지 확인

### 6-2. NotebookLM 검증 (Phase 3)

```bash
# nlm query 작동 확인
nlm notebook query "<NOTEBOOK_ID>" "이 프로젝트의 기술 스택은?"

# 동기화 테스트
bash scripts/nlm-sync.sh CLAUDE.md
```

### 6-3. 대화 동기화 검증 (Phase 4)

```bash
# 수동 동기화
bash scripts/conversation-sync.sh --latest

# 인덱스 확인
cat ~/.claude/conversation-index.json | python3 -m json.tool | tail -20
```

### 6-4. 훅 검증 (Phase 5)

```bash
# 알림
.claude/hooks/notify-user.sh "테스트" "Test"

# Claude Code 세션 종료 후 대화가 자동 동기화되는지 확인
```

---

## 최종 디렉토리 구조 레퍼런스

### 전역 (모든 프로젝트 공유)

```
~/.claude/
├── commands/
│   └── autonomous.md          # v4.7 범용 프레임워크 (SSOT)
├── CLAUDE.md                  # 전역 규칙 (한국어, 양방향 동기화 등)
├── settings.json              # 전역 훅 설정
├── state/
│   ├── AUTONOMOUS_MODE        # 자율 모드 활성 플래그
│   ├── EMERGENCY_STOP         # 긴급 중단 (touch로 생성)
│   ├── stop-hook-state.json   # 안전 정지 상태
│   └── notify-user.log        # 알림 로그
├── conversation-index.json    # 대화 동기화 인덱스
└── projects/
    └── <project-hash>/
        ├── *.jsonl            # 세션 대화 기록 (Claude Code 자동 생성)
        └── memory/
            └── MEMORY.md      # 세션 간 기억 (auto memory)
```

### 프로젝트 (각 프로젝트별)

```
your-project/
├── CLAUDE.md                  # 프로젝트 규칙 + Phase 확장 설정
├── .claude/
│   ├── settings.local.json    # 프로젝트별 훅 설정
│   └── hooks/
│       ├── notify-user.sh     # 사용자 알림
│       └── safe-stop-hook.sh  # 무한루프 방지
├── scripts/
│   ├── nlm-sync.sh            # 문서 → NotebookLM 동기화
│   ├── repomix-sync.sh        # 코드 → NotebookLM 동기화
│   └── conversation-sync.sh   # 대화 → NotebookLM 동기화
├── docs/
│   └── (기술문서)
└── (프로젝트 코드)
```

### autonomous 레포 (버전 관리용)

```
autonomous/
├── .claude/
│   ├── CLAUDE.md              # 전역 CLAUDE.md 원본
│   └── commands/
│       └── autonomous.md      # autonomous.md 원본 (전역 복사본)
├── guides/
│   ├── quickstart.md          # 이 가이드
│   └── notebooklm-setup.md   # nlm CLI 상세 설치 가이드
├── templates/
│   ├── nlm-sync.sh            # 문서 동기화 템플릿
│   ├── repomix-sync.sh        # 코드 동기화 템플릿
│   ├── conversation-sync.sh   # 대화 동기화 템플릿
│   ├── settings-local.json    # 훅 설정 템플릿
│   ├── claude-md-notebooklm-phase.md  # Phase 확장 템플릿
│   └── hooks/
│       ├── notify-user.sh     # 알림 훅 템플릿
│       └── safe-stop-hook.sh  # 안전 정지 훅 템플릿
├── projects/
│   └── <project>/
│       ├── README.md          # 프로젝트 소개
│       ├── CLAUDE-ext.md      # Phase 확장 백업
│       └── autonomous-history.md  # 교훈 아카이브
└── README.md
```

---

## 단계별 적용 범위 요약

| 단계 | 시간 | 얻는 것 | 필요 도구 |
|------|------|---------|----------|
| **Phase 1** | 5분 | `/autonomous` 기본 사용 | Claude Code |
| **Phase 2** | 10분 | 프로젝트별 규칙 + Phase 확장 | - |
| **Phase 3** | 15분 | 토큰 절약 (~94%), 지식 영구 보존 | nlm CLI |
| **Phase 4** | 10분 | 대화 자동 보존, 세션 간 맥락 유지 | nlm CLI |
| **Phase 5** | 5분 | 자동 알림, 무한루프 방지 | - |

**권장 경로:**
- **빠른 시작**: Phase 1 → Phase 2 → 바로 사용
- **풀 스택**: Phase 1 → 2 → 3 → 4 → 5 순서대로

---

## 트러블슈팅

### nlm 관련

| 문제 | 해결 |
|------|------|
| `nlm: command not found` | `pip install --user nlm` 후 PATH 확인 |
| `Authentication expired` | `nlm login` 실행 (Chrome 쿠키 자동 추출) |
| `Notebook not found` | `nlm notebook list`로 ID 재확인 |
| HTML 파일 업로드 실패 | nlm-sync.sh가 자동으로 텍스트 변환 처리 |

### 훅 관련

| 문제 | 해결 |
|------|------|
| 훅이 실행 안 됨 | `chmod +x .claude/hooks/*.sh` |
| 알림이 안 뜸 (macOS) | 시스템 설정 → 알림 → 터미널 허용 |
| safe-stop 상태 꼬임 | `rm ~/.claude/state/stop-hook-state.json` |

### 대화 동기화 관련

| 문제 | 해결 |
|------|------|
| JSONL 디렉토리 못 찾음 | `ls ~/.claude/projects/` → 프로젝트 해시 확인 |
| 동기화 안 됨 (Stop 훅) | settings.local.json에 Stop 훅 경로 확인 |
| 인덱스 파일 깨짐 | `rm ~/.claude/conversation-index.json` 후 재동기화 |

---

## 다음 단계

설정이 완료되면:

1. **규칙 축적**: 버그/실수 발생 시 `docs/claude-rules-lessons.md`에 기록 → CLAUDE.md 규칙화
2. **교훈 범용화**: 다른 프로젝트에서도 적용 가능한 교훈 → autonomous.md에 추상화 추가
3. **autonomous 레포 기록**: `projects/<your-project>/`에 Phase 확장 백업 + 교훈 아카이브
