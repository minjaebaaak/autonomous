# /autonomous v2.2

> **Claude Code를 위한 자율 실행 모드 - AEGIS + Ralph Loop 완전 통합**

`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.

---

## 자동 활성화 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| **AEGIS Protocol** | 7-Layer 검증 프레임워크 | ✅ 자동 |
| **ultrathink** | 심층 분석 모드 | ✅ 자동 |
| **Sequential Thinking** | 복잡한 문제 시 단계별 사고 | ✅ 필요 시 |
| **TodoWrite** | 진행 추적 | ✅ 자동 |
| **피드백 루프** | 완료 후 자동 검증 (3회) | ✅ 자동 |
| **🔄 랄프 루프** | 목표 달성까지 무한 반복 (최대 10회) | ✅ 자동 |

---

## 설치

### 기본 설치 (autonomous.md만)

```bash
# 프로젝트별 설치
mkdir -p .claude/commands
curl -o .claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md

# 전역 설치 (모든 프로젝트에서 사용)
mkdir -p ~/.claude/commands
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

### 전체 설치 (CLAUDE.md 포함 - 권장)

한국어 응답 및 기본 행동 규칙을 포함한 CLAUDE.md도 함께 설치합니다:

```bash
# 프로젝트별 설치 (권장)
mkdir -p .claude/commands
curl -o .claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
curl -o .claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md

# 전역 설치
mkdir -p ~/.claude/commands
curl -o ~/.claude/CLAUDE.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/CLAUDE.md
curl -o ~/.claude/commands/autonomous.md \
  https://raw.githubusercontent.com/minjaebaaak/autonomous/master/.claude/commands/autonomous.md
```

> **CLAUDE.md vs autonomous.md**
> - `CLAUDE.md`: 프로젝트 규칙 (언어, 행동 방식)
> - `autonomous.md`: 실행 모드 커맨드 (어떻게 작업할지)

---

## 사용법

```
/autonomous 배포해줘
/autonomous REST API 만들어줘
/autonomous 버그 수정해줘
```

---

## 🎢 랄프 루프 (Ralph Wiggum Mode)

### 놀이터 철학

> 랄프가 놀이터를 짓고 미끄럼틀에서 뛰어내리다 다칩니다(실패).
> 그러면 '뛰어내리지 마시오' 표지판(테스트)을 세웁니다.
> 다음번에는 표지판을 보고 안전하게 타고 내려옵니다.
> **실패할 때마다 표지판(검증 규칙)을 세워가며 완벽한 놀이터를 완성!**

### 작동 방식

```
Claude will:
1. Work on the task (작업 수행)
2. Try to exit (종료 시도)
3. Stop hook blocks exit (Stop 훅이 종료 차단)
4. Same prompt fed back (초기 프롬프트 재입력)
5. Repeat until RALPH_DONE (RALPH_DONE 출력까지 반복)
```

### 핵심 요소

| 요소 | 설명 |
|------|------|
| **local.md** | 프롬프트/상태 기록으로 컨텍스트 유지 |
| **Stop 훅 연동** | 종료 시도 차단 메커니즘 |
| **RALPH_DONE** | 명시적 종료 조건 |
| **표지판 추가** | 실패 시 새로운 검증 규칙/테스트 추가 |

### 적용 시점

- ✅ **추천**: 테스트 코드 실행, 린트 검사, Playwright 검증
- ❌ **비추천**: A/B/C 선택 등 주관적 판단이 필요한 작업

---

## 비상 정지

```bash
touch ~/.claude/state/EMERGENCY_STOP
```

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| v2.2 | 2026-01-19 | 랄프 루프 완전 통합 (놀이터 철학, local.md, Stop 훅) |
| v2.1 | 2026-01-19 | 랄프 루프 기본 추가 |
| v2.0 | 2026-01-19 | AEGIS Protocol 통합 |

---

## 라이선스

MIT License
