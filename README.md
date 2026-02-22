# /autonomous v5.1

> **Claude Code를 위한 자율 실행 모드 - 범용 프레임워크**
>
> `/autonomous [작업]` 하나로 검증, NotebookLM 통합, 문서 동기화, Agent Teams, 자동 커밋이 모두 적용됩니다.

---

## Quick Start

### 3줄 설치

```bash
mkdir -p ~/.claude/commands
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
curl -o ~/.claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
```

### 사용

```
/autonomous 배포해줘
/autonomous REST API 만들어줘
/autonomous 버그 수정해줘
```

### 새 프로젝트에 적용하기

**A-Z 가이드**: [`guides/quickstart.md`](guides/quickstart.md) — 설치부터 NotebookLM 통합까지 전체 과정

| 단계 | 시간 | 얻는 것 |
|------|------|---------|
| Phase 1: 기본 설치 | 5분 | `/autonomous` 기본 사용 |
| Phase 2: 프로젝트 구조 | 10분 | 프로젝트별 규칙 + Phase 확장 |
| Phase 3: NotebookLM 통합 | 15분 | 토큰 절약 (~94%), 지식 영구 보존 |
| Phase 4: 대화 동기화 | 10분 | 대화 자동 보존, 세션 간 맥락 유지 |
| Phase 5: 훅 설정 | 5분 | 자동 알림, 무한루프 방지 |

---

## 디렉토리 구조

### 전역 (모든 프로젝트 공유)

```
~/.claude/
├── commands/
│   └── autonomous.md          # v5.1 범용 프레임워크 (SSOT)
├── CLAUDE.md                  # 전역 규칙 (한국어, 양방향 동기화)
├── settings.json              # 전역 훅 설정
├── state/
│   ├── AUTONOMOUS_MODE        # 자율 모드 활성 플래그
│   └── EMERGENCY_STOP         # 긴급 중단 (touch로 생성)
├── conversation-index.json    # 대화 동기화 인덱스
└── projects/
    └── <project-hash>/
        ├── *.jsonl            # 세션 대화 기록 (자동 생성)
        └── memory/
            └── MEMORY.md      # 세션 간 기억
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
└── docs/                      # 기술문서
```

### autonomous 레포 (이 저장소)

```
autonomous/
├── .claude/
│   ├── CLAUDE.md              # 전역 CLAUDE.md 원본
│   └── commands/
│       └── autonomous.md      # autonomous.md 원본
├── guides/
│   ├── quickstart.md          # A-Z 온보딩 가이드
│   └── notebooklm-setup.md   # nlm CLI 상세 설치 가이드
├── templates/                 # 프로젝트에 복사하여 사용
│   ├── nlm-sync.sh
│   ├── repomix-sync.sh
│   ├── conversation-sync.sh
│   ├── settings-local.json
│   ├── claude-md-notebooklm-phase.md
│   └── hooks/
│       ├── notify-user.sh
│       └── safe-stop-hook.sh
├── projects/                  # 프로젝트별 교훈 아카이브
│   └── sharemanager/
└── README.md
```

---

## 설치

### 전역 설치 (권장)

```bash
mkdir -p ~/.claude/commands
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

### CLAUDE.md 포함 설치

```bash
curl -o ~/.claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
```

> **CLAUDE.md vs autonomous.md**
> - `CLAUDE.md`: 프로젝트 규칙 (언어, 행동 방식, Phase 확장 가이드)
> - `autonomous.md`: 실행 모드 커맨드 (어떻게 작업할지)

### 프로젝트 Phase 확장 설정

> **주의**: 프로젝트 `.claude/commands/autonomous.md`를 생성하지 마세요.
> 프로젝트 로컬 파일이 전역 범용 autonomous.md를 오버라이드합니다.
> 프로젝트 특화 설정은 반드시 CLAUDE.md "Phase 확장" 섹션에만 추가하세요.

전역 설치 후, 각 프로젝트 CLAUDE.md 하단에 Phase 확장 섹션을 추가하세요:

```markdown
## /autonomous Phase 확장 설정

- **Phase 0 기술문서**: `docs/technical-reference.html`. 섹션 매핑은 #14 참조.
- **Phase 0 NotebookLM**: 노트북 `{NOTEBOOK_UUID}`
  - 질의: `nlm notebook query "{NOTEBOOK_UUID}" "질의 내용"`
  - 기술표 동기화: `bash scripts/nlm-sync.sh docs/technical-reference.html`
  - 전체 동기화: `bash scripts/repomix-sync.sh`
  - 자동 동기화 대상: `docs/technical-reference.html`, `PROJECT_DOCUMENTATION.md`
- **Phase 2 파일→문서 매핑**: 매핑 규칙 정의.
- **Phase 7**: 검증/배포 명령어.
```

---

## 가이드

| 가이드 | 경로 | 설명 |
|--------|------|------|
| **A-Z 온보딩** | [`guides/quickstart.md`](guides/quickstart.md) | 새 프로젝트 적용 완전 가이드 (설치~NotebookLM~훅) |
| **NotebookLM 세팅** | [`guides/notebooklm-setup.md`](guides/notebooklm-setup.md) | OS별(macOS/Linux/Windows) nlm CLI 설치 + 인증 |

---

## 템플릿

프로젝트에 복사하여 사용하는 스크립트/설정 템플릿입니다. 상단 "프로젝트별 수정 영역"만 편집하면 됩니다.

| 템플릿 | 경로 | 설명 |
|--------|------|------|
| **nlm-sync.sh** | [`templates/nlm-sync.sh`](templates/nlm-sync.sh) | 문서 → NotebookLM 동기화 (파일별 노트북 자동 라우팅) |
| **repomix-sync.sh** | [`templates/repomix-sync.sh`](templates/repomix-sync.sh) | 코드 묶음 재생성 + NotebookLM 업로드 파이프라인 |
| **conversation-sync.sh** | [`templates/conversation-sync.sh`](templates/conversation-sync.sh) | 세션 대화 → NotebookLM 자동 동기화 (v4.7) |
| **settings-local.json** | [`templates/settings-local.json`](templates/settings-local.json) | 프로젝트 훅 설정 (`<PROJECT_PATH>` 교체) |
| **CLAUDE.md Phase 확장** | [`templates/claude-md-notebooklm-phase.md`](templates/claude-md-notebooklm-phase.md) | CLAUDE.md에 붙이는 Phase 확장 템플릿 |
| **notify-user.sh** | [`templates/hooks/notify-user.sh`](templates/hooks/notify-user.sh) | macOS/Linux 사용자 알림 훅 |
| **safe-stop-hook.sh** | [`templates/hooks/safe-stop-hook.sh`](templates/hooks/safe-stop-hook.sh) | Ralph Loop 무한루프 방지 안전장치 |

### 템플릿 사용법

```bash
# 1. 스크립트 복사 + 실행 권한
cp templates/nlm-sync.sh 내프로젝트/scripts/nlm-sync.sh
chmod +x 내프로젝트/scripts/nlm-sync.sh

# 2. 상단 "프로젝트별 수정 영역"에서 노트북 ID + 파일 매핑 수정

# 3. CLAUDE.md Phase 확장 추가
cat templates/claude-md-notebooklm-phase.md >> 내프로젝트/CLAUDE.md
# → <YOUR_NOTEBOOK_ID> 교체

# 4. 동기화 테스트
zsh 내프로젝트/scripts/nlm-sync.sh CLAUDE.md
```

상세 절차: [`guides/quickstart.md`](guides/quickstart.md) 참조

---

## Phase 구조

| Phase | 이름 | 설명 |
|-------|------|------|
| **Phase 0** | 사전 점검 | 기술문서 참조 — nlm query 우선, fallback Read (CLAUDE.md Phase 확장 참조) |
| **Phase 1** | 초기화 | 상태 파일 생성 |
| **Phase 2** | 문서 업데이트 | 코드 변경 후 기술문서 업데이트 (CLAUDE.md 매핑 참조) |
| **Phase 3** | autonomous 동기화 | autonomous.md 변경 시 전역 + 레포 동기화 |
| **Phase 3.5** | 양방향 동기화 | 프로젝트 교훈 범용화, CLAUDE.md Phase 확장 백업 |
| **Phase 4** | 심층 분석 레이어 | ultrathink, Sequential Thinking, TodoWrite |
| **Phase 4.5** | Agent Teams 필수 판단 | 매 작업마다 팀원 필요 여부 판단 + 출력 의무 |
| **Phase 5** | 자율 실행 | 사용자 의도 확인, 모호성 즉시 확인 |
| **Phase 5.5** | 에이전트 검증 | 에이전트 결과 원본 대조 |
| **Phase 5.6~5.9** | 정합성 검증 | Source-Sink, 멱등성, 사용자 여정, 횡단 관심사 |
| **Phase 6** | 커밋 전 문서 확인 | 문서 업데이트 없이 커밋 금지 |
| **Phase 6.5** | 자동 커밋 & 동기화 | commit & push + NotebookLM 자동 동기화 |
| **Phase 7** | 검증 | 빌드 검증, 배포, 프로덕션 확인 |
| **Phase 8** | 피드백 루프 | 검증 실패 시 자동 수정 (최대 3회) |
| **Phase 9** | 랄프 루프 | 목표 달성까지 무한 반복 (최대 10회) |

---

## 📚 규칙/경험/기억 관리 체계

autonomous 생태계는 4계층으로 지식을 관리합니다. 각 계층은 접근 속도, 용량, 지속성이 다릅니다.

### 아키텍처 개요

```
┌──────────────────────────────────────────────────────────────┐
│                    지식 관리 4계층 아키텍처                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  L1: autonomous.md (범용 원칙)                                │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: ~/.claude/commands/ (전역)  │  매 /autonomous 호출 시 │
│  │ 크기: ~520줄, ~15K 토큰          │  자동 로드             │
│  │ 수명: 영구 (전 프로젝트 공유)     │                        │
│  │ 내용: Phase 체계, 검증 원칙,     │                        │
│  │       자가 점검, 에이전트 규칙    │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 양방향 동기화 (교훈 범용화)                            │
│  L2: CLAUDE.md (프로젝트 규칙)                                │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: 프로젝트 루트              │  매 턴 자동 로드        │
│  │ 크기: ~1100줄, ~18K 토큰         │  (항상 컨텍스트에)     │
│  │ 수명: 프로젝트 생애주기          │                        │
│  │ 내용: Tier 1 원칙, Tier 2 체크,  │                        │
│  │       Tier 3 도메인, Phase 확장  │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 세션 간 학습 전이                                     │
│  L3: MEMORY.md (세션 간 기억)                                 │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: ~/.claude/projects/...     │  매 턴 자동 로드        │
│  │ 크기: ~80줄, ~4.5K 토큰          │  (200줄 초과 시 잘림)  │
│  │ 수명: 프로젝트 생애주기          │                        │
│  │ 내용: 핵심 정보 요약, 교훈 색인, │                        │
│  │       운영 가이드, 패턴 기록      │                        │
│  └──────────────────────────────────┘                        │
│       ↕ 외재화 (무제한 저장)                                   │
│  L4: NotebookLM (외부 지식 저장소)                             │
│  ┌──────────────────────────────────┐                        │
│  │ 위치: Google NotebookLM (클라우드)│  nlm query 시에만 접근  │
│  │ 크기: 무제한                      │  (상시 비용 0)         │
│  │ 수명: 영구                       │                        │
│  │ 내용: 기술표 전문, 프로젝트 문서, │                        │
│  │       교훈 원본, 코드 묶음        │                        │
│  └──────────────────────────────────┘                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 계층별 상세

| 계층 | 위치 | 로드 시점 | 내용 | 핵심 |
|------|------|----------|------|------|
| **L1** | `~/.claude/commands/autonomous.md` | `/autonomous` 호출 | Phase 체계, 검증 원칙, 에이전트 규칙 | 범용 원칙만 (프로젝트 특화 X) |
| **L2** | 프로젝트 루트 `CLAUDE.md` | 매 턴 자동 | Tier 1~3 규칙 + Phase 확장 | 프로젝트별 규칙 |
| **L3** | `~/.claude/projects/.../MEMORY.md` | 매 턴 자동 | 핵심 요약, 교훈 색인 | 200줄 제한, 정기 압축 필요 |
| **L4** | Google NotebookLM | nlm query 시 | 기술표, 문서, 교훈, 코드, 대화 | 무제한, 상시 비용 0 |

### 지식 흐름도

```
실수/경험 발생
    │
    ▼
교훈 추출 (세션 내)
    │
    ├─→ MEMORY.md에 요약 기록 (L3)
    │
    ├─→ CLAUDE.md에 규칙 추가 (L2)
    │       │
    │       └─→ 범용화 가능? ──Yes──→ autonomous.md에 추상화 추가 (L1)
    │                                       │
    │                                       └─→ autonomous 레포 커밋
    │
    └─→ docs/claude-rules-lessons.md에 원본 보존
            │
            └─→ NotebookLM에 동기화 (L4, v4.0 자동)
```

---

## 🧠 컨텍스트 관리 전략

### 토큰 예산 구조

| 소스 | 크기 | 로드 시점 | 비고 |
|------|------|----------|------|
| CLAUDE.md | ~18K 토큰 | 매 턴 | 압축 후 |
| MEMORY.md | ~4.5K 토큰 | 매 턴 | 압축 후 |
| autonomous.md | ~15K 토큰 | /autonomous 시 | Phase 전체 |
| **합계** | **~37.5K 토큰/턴** | | /autonomous 세션 기준 |

### 최적화 결과

| 최적화 | 절약량 | 방법 |
|--------|--------|------|
| CLAUDE.md 압축 | ~5K 토큰/턴 | 교훈 블록 → 1줄 요약 + 원본 외부 파일 |
| MEMORY.md 압축 | ~2.5K 토큰/턴 | 중복 제거, 핵심만 유지 |
| Phase 0 nlm query | ~47K 토큰/세션 | 기술표 319KB Read → nlm query 3K 응답 |
| **총 절약** | **~7.5K/턴 + ~47K/세션** | |

---

## 동기화 규칙 (전역 → 레포 단방향)

> **전역 파일(`~/.claude/commands/autonomous.md`)이 유일한 원본.**

### 범용 autonomous.md 수정 시
```
1. ~/.claude/commands/autonomous.md 수정
2. autonomous_temp/.claude/commands/에 복사
3. README.md 업데이트
4. autonomous 레포 커밋 & 푸시
→ 모든 프로젝트에 즉시 반영 (전역)
```

### 프로젝트 교훈 → 범용화
```
1. 프로젝트 CLAUDE.md Phase 확장에 기록
2. 범용화 가능 → autonomous.md에 추상화 반영
3. autonomous_temp/projects/[프로젝트]/에 원본 백업
4. autonomous 레포 커밋 & 푸시
```

---

## 자동 활성화 기능

| 카테고리 | 포함 기능 | 상태 |
|---------|---------|------|
| **컨텍스트 보존** | nlm 질의, repomix 스냅샷, Read 최소화, 대화 자동 동기화 | ✅ v4.7 |
| **검증 체계** | 검증 프로토콜, 피드백 루프, Agent 교차 검증, 랄프 루프 | ✅ v3.3 |
| **문서 동기화** | 기술문서 참조, 문서 업데이트, 커밋 전 확인, 양방향 동기화 | ✅ v3.0 |
| **자율 실행** | ultrathink, Sequential Thinking, TodoWrite, Teams 필수 판단 | ✅ v3.3 |
| **커밋 & 배포** | 자동 커밋 & 푸시, NotebookLM 동기화 | ✅ v4.5 |

---

## 랄프 루프 (Ralph Wiggum Mode)

> 랄프가 놀이터를 짓고 미끄럼틀에서 뛰어내리다 다칩니다(실패).
> 그러면 '뛰어내리지 마시오' 표지판(테스트)을 세웁니다.
> **실패할 때마다 표지판(검증 규칙)을 세워가며 완벽한 놀이터를 완성!**

```
1. Work on the task (작업 수행)
2. Try to exit (종료 시도)
3. Stop hook blocks exit (Stop 훅이 종료 차단)
4. Same prompt fed back (초기 프롬프트 재입력)
5. Repeat until RALPH_DONE (RALPH_DONE 출력까지 반복)
```

---

## 비상 정지

```bash
touch ~/.claude/state/EMERGENCY_STOP
```

---

## 프로젝트 디렉토리

| 프로젝트 | 디렉토리 | 설명 |
|---------|---------|------|
| ShareManager | `projects/sharemanager/` | SERP 모니터링 서비스 — autonomous 탄생 프로젝트 |

---

## 🔭 미래 방향

### 축 1: 지식 외재화 — "컨텍스트 윈도우 밖으로"

```
Phase 1 (완료): CLAUDE.md/MEMORY.md 압축 → ~2,900 토큰/턴 절약
Phase 2 (완료): NotebookLM에 지식 외재화 → Phase 0에서 ~47K 토큰 절약
Phase 3 (계획): 규칙/교훈의 자동 분류 → 빈번한 것만 CLAUDE.md에 유지
Phase 4 (구상): MCP 서버 없이 외부 지식 접근 → CLI 기반 질의로 상시 비용 0
```

### 축 2: 자율 학습 루프 — "실수에서 규칙으로"

- 교훈의 "빈도 기반 승격/강등" — 3회 이상 참조된 교훈은 자동으로 CLAUDE.md Tier 1 후보
- 6개월간 미참조 규칙은 MEMORY.md → NotebookLM으로 아카이브 제안
- 프로젝트 간 교훈 교차 검증 — 2개+ 프로젝트에서 동일 패턴 발견 시 자동 범용화 후보

### 축 3: 다중 프로젝트 확장 — "하나의 지혜, 여러 프로젝트"

```
autonomous.md (범용, 전역)
  └─ CLAUDE.md Phase 확장 (프로젝트별)
       ├─ ShareManager: SERP 모니터링 (탄생 프로젝트)
       └─ (미래 프로젝트들)
```

---

## 최신 변경사항

### v5.1 (2026-02-23)
Phase 9 종료 조건 명시 (10회 실패 → 사용자 보고) + Phase 2/6.5 역할 명확화 (문서 수정 vs 커밋).

### v5.0 (2026-02-23)
검증 용어 정규화 + CLAUDE.md 참조 정규화. AEGIS 용어 완전 제거, 깨진 번호 참조 → 섹션명/스킬 경로로 교체.

### v4.7 (2026-02-21)
대화 → NotebookLM 자동 동기화 + 카테고리별 노트북 분리. conversation-sync.sh 신규, 3분류(rules/conv/tech), 로컬 인덱스, Stop 훅 자동 트리거.

### v4.5~v4.6 (2026-02-21)
"기억하지 말고 기록하라" nlm+repomix 통합. 구조 다이어트(-22%), nlm alias 도입, 스마트 로딩.

### v4.0~v4.4 (2026-02-20~21)
NotebookLM 자동 동기화(v4.0), Phase 0 nlm 강제(v4.1~v4.3), 인증 만료 재인증(v4.4).

### v3.0~v3.9 (2026-02-06~20)
범용화 완료(v3.0), Agent Teams(v3.1~v3.4), Source-Sink/멱등성(v3.5), 자동 커밋(v3.6), 사용자 여정(v3.7), 횡단 관심사(v3.8), NotebookLM 질의(v3.9).

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| **v5.1** | **2026-02-23** | **로직 개선**: Phase 9 종료 조건 명시 + Phase 2/6.5 역할 명확화 |
| v5.0 | 2026-02-23 | 검증 용어 정규화: AEGIS 완전 제거, CLAUDE.md 번호 참조 → 섹션명/스킬 경로 교체 |
| v4.7 | 2026-02-21 | 대화 자동 동기화 + 카테고리별 노트북: conversation-sync.sh + 3분류(rules/conv/tech) + 로컬 인덱스 |
| v4.6 | 2026-02-21 | AI 관점 최적화: 다이어트(-22%) + alias + 스마트 로딩 |
| v4.5 | 2026-02-21 | "기억하지 말고 기록하라": nlm + repomix 통합 |
| v4.4 | 2026-02-21 | nlm 인증 만료 시 재인증 강제 |
| v4.3 | 2026-02-20 | Phase 0 nlm 전 작업 강제 |
| v4.2 | 2026-02-20 | Phase 0 복잡도 기반 분기 (v4.3에서 폐지) |
| v4.1 | 2026-02-20 | Phase 0 nlm query 강제 실행 |
| **v4.0** | **2026-02-20** | **NotebookLM 자동 동기화** |
| **v3.9** | **2026-02-20** | **Phase 0 NotebookLM 질의** |
| v3.8 | 2026-02-19 | 횡단 관심사 계층별 sweep |
| v3.7 | 2026-02-15 | 사용자 여정 일관성 |
| v3.6 | 2026-02-12 | 작업 완료 자동 commit & push |
| v3.5 | 2026-02-12 | Source-Sink 정합성 + 멱등성 원칙 |
| v3.4 | 2026-02-12 | 에이전트 수량 제한 전면 해제 |
| v3.3 | 2026-02-12 | Agent 결과 교차 검증 강화 |
| v3.2 | 2026-02-07 | Agent Teams 필수 판단 강제화 |
| v3.1 | 2026-02-07 | Agent Teams 통합 |
| v3.0 | 2026-02-06 | 범용화 완료 — 프로젝트 특화 분리, Phase 확장 체계 |
| v2.9 | 2026-02-06 | Phase 5.5 에이전트 결과 검증 |
| v2.8 | 2026-02-06 | Phase 0 강제 도입 |
| v2.7 | 2026-02-05 | CLAUDE.md 타임존 규칙 |
| v2.6 | 2026-02-05 | 문서 동기화 시스템 |
| v2.5 | 2026-02-04 | autonomous.md 자동 커밋 & 푸시 |
| v2.2 | 2026-01-19 | 랄프 루프 완전 통합 |
| v2.1 | 2026-01-19 | 랄프 루프 기본 추가 |
| v2.0 | 2026-01-19 | 검증 프로토콜 통합 |

---

## 라이선스

MIT License
