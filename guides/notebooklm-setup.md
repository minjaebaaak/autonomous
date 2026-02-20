# NotebookLM + Claude Code 통합 가이드

> **프로젝트 지식을 NotebookLM에 외재화하여 Claude Code의 컨텍스트 소비를 최소화하는 범용 세팅 가이드**
>
> autonomous v4.0+ 에서 자동으로 활용됩니다.

---

## 왜 NotebookLM인가?

Claude Code는 매 턴마다 CLAUDE.md + MEMORY.md를 자동 로드합니다 (~22K 토큰). 프로젝트가 커지면 기술문서, 규칙, 경험이 증가하여 컨텍스트 윈도우를 압박합니다.

**NotebookLM 통합 효과**:
- Phase 0에서 기술문서 전체 Read (~50K 토큰) → nlm query (~3K 토큰) = **~94% 절약**
- 코드 변경 후 문서 자동 동기화 → 지식 항상 최신
- 상시 비용 0 (Google NotebookLM 무료)

---

## 사전 요구사항

| 요구사항 | 설명 |
|---------|------|
| Python 3.10+ | nlm CLI 실행 환경 |
| Google 계정 | NotebookLM 접근 |
| Chrome 브라우저 | nlm login이 Chrome DevTools Protocol로 쿠키 추출 |
| Claude Code | `/autonomous` 커맨드 사용을 위해 |

---

## Step 0: nlm CLI 설치

### macOS

```bash
# uv가 없으면 먼저 설치
brew install uv
# 또는
curl -LsSf https://astral.sh/uv/install.sh | sh

# nlm 설치
uv tool install notebooklm-mcp-cli

# PATH 확인 — uv tool은 보통 아래 경로에 설치
# ~/.local/bin/nlm 또는 ~/Library/Python/3.x/bin/nlm
nlm --version
```

**macOS 주의사항**:
- macOS 기본 bash는 3.2 (2007년!) → `declare -A` (연관 배열) 미지원
- nlm-sync.sh에서 `#!/bin/zsh` + `typeset -A` 사용 권장
- 또는 `brew install bash`로 bash 5+ 설치

### Linux (Ubuntu/Debian)

```bash
# Python 설치 (없으면)
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# uv 설치
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # 또는 ~/.zshrc

# nlm 설치
uv tool install notebooklm-mcp-cli

# 설치 확인
nlm --version
```

**Linux 주의사항**:
- headless 서버: Chrome이 GUI 없이 동작 → nlm login 시 `CHROME_PATH` 설정 필요할 수 있음
- Chrome 미설치 시: `sudo apt install -y google-chrome-stable` 또는 Chromium
- bash 4+가 기본이므로 `declare -A` 정상 동작

### Windows

```powershell
# uv 설치
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# nlm 설치
uv tool install notebooklm-mcp-cli

# 설치 확인
nlm --version
```

**Windows 주의사항**:
- nlm-sync.sh 실행: **Git Bash** 또는 **WSL** 사용 권장
- 경로 구분자: 스크립트 내 `/` 사용 (Git Bash/WSL에서 자동 변환)
- PowerShell에서 직접 실행 시 sh 스크립트 호환 문제 → WSL 강력 권장
- WSL 사용 시: `wsl -d Ubuntu` → Linux 가이드 동일하게 따르기

---

## Step 1: Google 인증

```bash
nlm login
```

**동작 원리**:
- Chrome DevTools Protocol로 기존 Chrome 세션의 Google 쿠키를 자동 추출
- 별도 로그인 입력 불필요 (Chrome에서 이미 Google에 로그인되어 있으면)
- 추출된 인증 정보는 로컬에 캐시됨

**인증 만료 시** (규칙 Y):
- `nlm` 명령 실행 시 "Authentication expired" 에러
- 이것은 **로컬 캐시 만료**이지 Google 세션 만료가 아님
- `nlm login` 재실행으로 자동 해결 (사용자 개입 불필요)

---

## Step 2: 노트북 생성

```bash
# 프로젝트용 노트북 생성
nlm notebook create "내 프로젝트 이름"

# 생성된 노트북 목록 확인 → ID 복사
nlm notebook list
```

**출력 예시**:
```json
[
  {
    "id": "af7bfaf0-5d0f-48f9-81d9-705cd7c3d1f6",
    "title": "내 프로젝트 이름"
  }
]
```

이 **ID**를 기록해 두세요. 이후 모든 명령에서 사용합니다.

---

## Step 3: 소스 업로드

프로젝트의 핵심 문서를 NotebookLM에 업로드합니다.

```bash
NOTEBOOK_ID="여기에-노트북-ID-붙여넣기"

# 1. CLAUDE.md (프로젝트 규칙)
nlm source add "$NOTEBOOK_ID" --file CLAUDE.md --wait

# 2. 프로젝트 문서 (있으면)
nlm source add "$NOTEBOOK_ID" --file PROJECT_DOCUMENTATION.md --wait

# 3. 기술문서 (HTML인 경우 텍스트 변환 필요 — Step 3-A 참조)
nlm source add "$NOTEBOOK_ID" --file docs/technical-reference.md --wait

# 업로드 확인
nlm source list "$NOTEBOOK_ID"
```

### Step 3-A: HTML 파일 업로드

nlm은 HTML을 직접 지원하지 않으므로, 텍스트로 변환 후 업로드합니다.
(nlm-sync.sh 템플릿에 이 변환 로직이 내장되어 있습니다)

```bash
# HTML → 텍스트 변환 후 업로드
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

with open('docs/technical-reference.html') as f: html = f.read()
p = T(); p.feed(html)
text = re.sub(r'\n{3,}', '\n\n', ''.join(p.t)).strip()
with open('/tmp/nlm-technical-reference.txt', 'w') as f: f.write(text)
print(f'Converted {len(html)} -> {len(text)} chars')
"

nlm source add "$NOTEBOOK_ID" --file /tmp/nlm-technical-reference.txt --wait --title "technical-reference.html"
rm /tmp/nlm-technical-reference.txt
```

---

## Step 4: 동기화 스크립트 설정

### 4-A: nlm-sync.sh 복사 및 커스터마이징

```bash
# autonomous 레포의 템플릿 복사
cp path/to/autonomous/templates/nlm-sync.sh scripts/nlm-sync.sh
chmod +x scripts/nlm-sync.sh
```

**커스터마이징 (파일 상단의 "프로젝트별 수정 영역")**:

```bash
# ── 프로젝트별 수정 영역 ──────────────────────────

# 1. 노트북 ID 매핑 (nlm notebook list로 확인 후 입력)
typeset -A NOTEBOOKS              # macOS (zsh)
# declare -A NOTEBOOKS            # Linux (bash 4+)
NOTEBOOKS[main]="여기에-노트북-ID"

# 2. 파일명→노트북 자동 매핑
typeset -A FILE_NOTEBOOK_MAP      # macOS (zsh)
# declare -A FILE_NOTEBOOK_MAP    # Linux (bash 4+)
FILE_NOTEBOOK_MAP[CLAUDE.md]="main"
FILE_NOTEBOOK_MAP[technical-reference.html]="main"
FILE_NOTEBOOK_MAP[PROJECT_DOCUMENTATION.md]="main"
```

### 4-B: (선택) repomix-sync.sh 복사

코드 묶음도 NotebookLM에 동기화하려면:

```bash
cp path/to/autonomous/templates/repomix-sync.sh scripts/repomix-sync.sh
chmod +x scripts/repomix-sync.sh
```

include 패턴을 프로젝트 구조에 맞게 수정합니다.

---

## Step 5: CLAUDE.md Phase 확장 설정

프로젝트 CLAUDE.md 하단에 아래 섹션을 추가합니다.
(`templates/claude-md-notebooklm-phase.md`를 복사해도 됩니다)

```markdown
### Phase 0 확장: NotebookLM

- **노트북 ID**: `여기에-노트북-ID`
- **질의**: `nlm notebook query "노트북-ID" "질의 내용"`
- **동기화**: `bash scripts/nlm-sync.sh <파일경로>`
- **자동 동기화 대상**: `CLAUDE.md`, `docs/technical-reference.html`, `PROJECT_DOCUMENTATION.md`
```

이 설정이 있으면 autonomous v4.0이 자동으로:
- **Phase 0**: 기술문서 Read 대신 `nlm notebook query` 사용
- **Phase 6.5**: 커밋 후 변경된 문서를 `nlm-sync.sh`로 동기화

---

## Step 6: 검증

```bash
NOTEBOOK_ID="여기에-노트북-ID"

# 1. 소스 목록 확인
nlm source list "$NOTEBOOK_ID"

# 2. 질의 테스트
nlm notebook query "$NOTEBOOK_ID" "이 프로젝트의 기술 스택은?"

# 3. 동기화 스크립트 테스트
bash scripts/nlm-sync.sh CLAUDE.md
# macOS: zsh scripts/nlm-sync.sh CLAUDE.md
```

모든 단계가 에러 없이 완료되면 설정 완료입니다.

---

## Troubleshooting

### 공통

| 증상 | 원인 | 해결 |
|------|------|------|
| `Authentication expired` | nlm 로컬 캐시 만료 (Google 세션은 유효) | `nlm login` 재실행 |
| `NotebookNotFound` | 노트북 ID 오타 | `nlm notebook list`로 재확인 |
| 소스 업로드 후 query 결과 없음 | 인덱싱 지연 | `--wait` 플래그 사용, 1~2분 대기 |
| `nlm: command not found` | PATH에 없음 | `which nlm` 또는 전체 경로 사용 |

### macOS 전용

| 증상 | 원인 | 해결 |
|------|------|------|
| `declare: -A: invalid option` | macOS 기본 bash 3.2 | `#!/bin/zsh` + `typeset -A` 또는 `brew install bash` |
| `zsh: no matches found: *` | glob 패턴 해석 | 패턴을 따옴표로 감싸기 |

### Linux 전용

| 증상 | 원인 | 해결 |
|------|------|------|
| `Could not find Chrome` | Chrome 미설치 | `sudo apt install google-chrome-stable` |
| headless 서버에서 nlm login 실패 | GUI 없음 | 로컬에서 nlm login → `~/.config/nlm/` 복사 |
| 권한 오류 | 스크립트 실행 권한 없음 | `chmod +x scripts/nlm-sync.sh` |

### Windows 전용

| 증상 | 원인 | 해결 |
|------|------|------|
| sh 스크립트 실행 불가 | PowerShell 호환 문제 | Git Bash 또는 WSL 사용 |
| 경로 `\` vs `/` 오류 | Windows 경로 구분자 | Git Bash/WSL에서 실행 |
| WSL에서 Chrome 못 찾음 | Windows Chrome ≠ WSL Chrome | WSL 내 Chromium 설치 또는 `CHROME_PATH` 설정 |

---

## 아키텍처 요약

```
autonomous Phase 0 (작업 시작)
    │
    ├─ CLAUDE.md에 NotebookLM 설정 있음?
    │   ├─ Yes → nlm notebook query (토큰 절약)
    │   │        └─ 실패 시 → fallback: 기술문서 직접 Read
    │   └─ No → 기술문서 직접 Read (기존 방식)
    │
    ▼
autonomous Phase 1~5 (구현)
    │
    ▼
autonomous Phase 6.5 (커밋 & 동기화)
    │
    ├─ git commit & push
    └─ 변경된 문서 중 자동 동기화 대상?
        ├─ Yes → nlm-sync.sh 실행 (NotebookLM 업데이트)
        │        └─ 실패 시 → 경고만 출력 (블로커 아님)
        └─ No → 스킵
```

---

## 참고

- **nlm CLI**: [notebooklm-mcp-cli](https://github.com/nicholasgcoles/notebooklm-mcp-cli) (v0.3.3+)
- **autonomous**: [autonomous 레포](https://github.com/minjaebaaak/autonomous)
- **NotebookLM**: [notebooklm.google.com](https://notebooklm.google.com)
