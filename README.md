# /autonomous v2.6

> **Claude Code를 위한 자율 실행 모드 - AEGIS + Ralph Loop + 문서 동기화 완전 통합**

`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.

---

## 자동 활성화 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| **📚 기술표 참조** | 작업 전 기술표에서 파일/함수 확인 | ✅ 자동 |
| **📝 기술표 업데이트** | 코드 변경 후 기술표 자동 업데이트 | ✅ 자동 |
| **🔄 autonomous 자동 커밋** | autonomous.md 개선 시 자동 git 반영 | ✅ 자동 (v2.5) |
| **📋 커밋 전 문서 확인** | 기술표 업데이트 강제 확인 | ✅ 자동 (v2.6) |
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

## v2.6 신규 기능: 📊 문서 동기화 시스템

### 핵심 개발 원칙

1. **기술표 기반 개발**: 작업 전 기술표에서 관련 파일/함수 확인
2. **기술표 동기화**: 코드 변경 시 기술표도 **반드시** 업데이트
3. **커밋 전 확인**: 기술표 업데이트 없이 코드 커밋 **금지**
4. **코드와 문서는 한 커밋에**: 코드만 커밋하고 문서는 나중에 = **규칙 위반**

### Phase 3.5: 커밋 전 문서 확인 (강제)

```
커밋 전 체크리스트:
[ ] 1. 수정한 파일 목록 확인 (git status)
[ ] 2. 기술표 업데이트 필요한 파일인지 확인
[ ] 3. 해당하면 기술표 먼저 업데이트
[ ] 4. git add에 기술표 파일 포함
[ ] 5. 코드와 기술표를 같은 커밋에 포함
```

**위반 시**:
- 기술표 없이 코드만 커밋 = **규칙 위반**
- 반드시 기술표 업데이트 커밋 추가

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

### 랄프 루프 vs 피드백 루프

| 구분 | 피드백 루프 | 랄프 루프 |
|------|------------|----------|
| 최대 시도 | 3회 | 10회 |
| 접근법 | 동일 방식 재시도 | **표지판 추가 후** 재시도 |
| 상태 유지 | 메모리 내 | **local.md 파일** |
| 종료 조건 | 성공 또는 3회 실패 | **RALPH_DONE 출력** |
| Stop 훅 | 미사용 | **종료 시도 차단** |

---

## 비상 정지

```bash
touch ~/.claude/state/EMERGENCY_STOP
```

---

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| v2.6 | 2026-02-05 | 문서 동기화 시스템 (기술표/상태페이지 SSOT), Phase 3.5 커밋 전 문서 확인 강제 |
| v2.5 | 2026-02-04 | autonomous.md 자동 커밋 & 푸시 |
| v2.2 | 2026-01-19 | 랄프 루프 완전 통합 (놀이터 철학, local.md, Stop 훅) |
| v2.1 | 2026-01-19 | 랄프 루프 기본 추가 |
| v2.0 | 2026-01-19 | AEGIS Protocol 통합 |

---

## 라이선스

MIT License
