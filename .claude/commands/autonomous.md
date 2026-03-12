# Autonomous Mode v5.14 - 범용 프레임워크

> **`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.**
>
> v5.14: nlm 판단 오류 방지(Step 1 컨텍스트 비의존) + 실패 진단 의무. v5.13: 근본 원인 연쇄 분석 강제. v5.12: 🟠 과잉 반응 방지. v5.10: TASK_COMPLETE 즉시 정지. v5.9: 멀티세션 충돌 0. v5.8: 세션 스코핑.

---

## 🛑 Phase 0: MANDATORY PRE-CHECK

> **🔴 이 단계를 건너뛰면 규칙 위반. 모든 작업은 여기서 시작.**
>
> **핵심**: 규칙의 존재 ≠ 규칙 준수. 강제 메커니즘이 필요하다.

### 🔴 실행 순서 (반드시 순서대로 - 건너뛰기 금지)

**Step 1: 기술문서 참조 (모든 작업 — nlm 우선)** (필수 - 생략 금지)

> **🔴 근거**: NotebookLM에 CLAUDE.md, MEMORY.md, 기술표, 규칙화 문서가 모두 포함됨.
> **작업 규모와 무관하게** nlm 질의는 필수.

**🔴 nlm 존재 확인 우선 (v5.14 — 컨텍스트 비의존):**
```bash
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"
command -v nlm &>/dev/null && echo "nlm 사용 가능" || echo "nlm 미설치"
```

**A) nlm이 설치되어 있으면 → 무조건 nlm 시도:**
```bash
# 🔴 반드시 아래 Bash 명령을 실행할 것 (Read 도구로 기술문서 직접 읽기 금지)
# 🔴 출력을 head/tail로 파이프하지 말 것 (Claude Code에서 사용 불가)
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"

# alias는 CLAUDE.md "Phase 0 NotebookLM"에서 확인.
# alias를 모르겠으면 (compaction 후 등):
#   nlm notebook list  → 노트북 목록에서 적절한 것 선택
nlm notebook query "<alias 또는 노트북ID>" "<작업 관련 질의>"
```
- 질의 결과에서 관련 파일/함수 목록을 추출한다
- 필요 시 grep으로 교차 검증한다
- **🔴 nlm 성공 시 Read 도구로 기술문서 전체를 읽지 않는다** (토큰 낭비)

**B) nlm이 설치되어 있지 않으면:**
- 기술문서를 Read 도구로 직접 읽는다

**C) nlm 실패 시 — 원인별 분기 (🔴 fallback 전 재인증 필수):**

**C-1) 인증 만료 (Authentication expired):**
1. 🔴 `nlm login` 실행 (필수 — 건너뛰기 금지)
2. 재인증 성공 → nlm query 재시도
3. 재인증 실패 → fallback: 기술문서를 Read 도구로 직접 읽는다

**C-2) command not found / 기타 오류:**
- fallback: 기술문서를 Read 도구로 직접 읽는다

**C-3) 성공이지만 빈 결과 (동기화 미완료 가능성):**
1. 다른 노트북에 동일 질의 재시도 (예: sm-rules 빈 결과 → sm-tech 시도)
2. 전 노트북 빈 결과 → 동기화 상태 확인:
   ```bash
   cat ~/.claude/state/nlm-sync-status.json 2>/dev/null || echo "상태 파일 없음"
   ```
3. 최근 실패/경고 기록 있음 → `nlm source list <alias>`로 소스 존재 확인
4. 소스 자체가 없음 → CLAUDE.md Phase 확장의 동기화 스크립트 재실행 (nlm-sync.sh / repomix-sync.sh)
5. 소스 있는데 빈 결과 → 질의어 변경 후 재시도 (최대 2회)
6. 재시도 후에도 빈 결과 → fallback: Read 도구로 기술문서 직접 읽기

**절대 금지:**
```
❌ 인증 만료 시 `nlm login` 없이 바로 fallback
❌ "nlm 실패 → 직접 비교 진행" (재인증 시도 없이)
❌ nlm 빈 결과를 "해당 정보 없음"으로 단정 (동기화 미완료 가능성 미진단)
```

**Step 1.5: repomix 세션 스냅샷 (MCP 도구 사용)** (설정 있을 때)

CLAUDE.md "Phase 0 확장: repomix 설정"이 있으면:

**A) 기존 repomix 출력 파일이 있으면 (우선 — 즉시 로드):**
```
mcp__plugin_repomix-mcp_repomix__attach_packed_output({
  path: "<CLAUDE.md에서 지정한 출력 디렉토리>"
})
```
- 반환된 outputId를 세션 내내 재사용
- 파일이 없거나 에러 시 → B) 폴백

**B) 폴백 — 새로 생성:**
```
mcp__plugin_repomix-mcp_repomix__pack_codebase({
  directory: "<프로젝트 루트>",
  includePatterns: "<CLAUDE.md에서 지정한 패턴>",
  ignorePatterns: "<CLAUDE.md에서 지정한 패턴>",
  compress: true
})
```

- 이후 코드 탐색은 `grep_repomix_output(outputId, pattern)`으로 수행
- **🔴 Read 도구로 코드 파일 전체를 읽는 것 금지** (편집 직전 최소 범위만 허용)

repomix 설정이 없으면 이 Step 건너뛰기.

**Step 1.6: 핸드오프 노트 확인** (자동 — 세션 스코핑 v5.8)

```bash
# 세션 ID 결정 (tmux > auto-session > fallback)
PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')  # tmux pane ID (예: 5)
# PANE_ID가 비어있으면 = 단일 세션 환경 → 전체 핸드오프 대상
```

`~/.claude/state/handoffs/` 디렉토리를 스캔:

**필터링** (순서대로):
1. 24시간 초과 → 삭제
2. project 경로 ≠ `$PWD` → 무시 (삭제 안 함)
3. **PANE_ID가 있으면**: 파일명에 `-pane{PANE_ID}` 포함된 것만 매칭
4. `$ARGUMENTS`가 있으면 (새 작업): 매칭된 핸드오프 삭제

**유효 파일 수에 따른 분기**:
- **0건**: 건너뛰기
- **1건+**: 가장 최근 1개 자동 복원 (질문 없이)
  1. 파일 읽기 → 컨텍스트 복원
  2. 소비된 파일 삭제
  3. "이전 세션에서 [task]를 이어갑니다."

**Step 1.7: 이전 세션 복원** (선택 — sm-conv 설정 있을 때)

맥락 필요 시: `nlm notebook query sm-conv "지난 세션에서 [주제] 진행 상황은?"`. 없으면 건너뛰기.

**Step 2: 관련 섹션 식별 및 출력** (필수)
```
작업: [사용자 요청 요약]
관련 섹션: [CLAUDE.md "Phase 0 확장: 섹션 매핑" 참조, 없으면 자체 판단]
관련 파일: [기술문서에서 추출한 파일 목록]
```

**Step 3: Phase 0 완료 선언** (필수)
```
✅ Phase 0 완료 - 기술문서 확인됨
```

**자가 점검**: Phase 0 완료 메시지 출력 전까지 다른 Phase 진행 금지. 규칙 주장 전 nlm/Read로 확인 필수.

---

## 🧠 컨텍스트 절약 규칙 — "기억하지 말고 기록하라"

> **기억** = 컨텍스트에 로드 (시간, 에너지, 토큰 소모 → 압축으로 사라짐)
> **기록** = NotebookLM에 업로드 (영구 보존)
> **검색** = nlm query / grep_repomix_output (간단, 빠름, 저비용)

### 도구 선택 기준

| 목적 | 사용 도구 | 금지 |
|------|---------|------|
| 규칙/문서/설계 결정 확인 | `nlm notebook query` | ❌ Read 기술표/문서 전체 |
| 코드 구조 파악 | `attach_packed_output` / `pack_codebase(compress)` | ❌ Read 여러 파일 순회 |
| 코드 내 패턴 검색 | `grep_repomix_output` / Grep | ❌ Read 후 눈으로 검색 |
| 파일 편집 | Read(offset, limit) → Edit | ❌ Read 전체 파일 |
| 수정 결과 검증 (소형 ~100줄) | Read | ❌ nlm (오버헤드 > 이득) |
| 수정 결과 검증 (대형 100줄+) | `nlm notebook query` | ❌ Read 전체 파일 |
| 과거 구현/설계 확인 | `nlm notebook query` | ❌ git log 전체 조회 |

**Read 사용 조건**: (1) Edit 직전 offset+limit (2) 특수 파일(설정/JSON) (3) 수정 검증(소형만). 그 외 nlm/repomix/grep 사용.

### 세션 전환 전략 (v5.7)

> **Compaction < 새 세션**. nlm이 모든 맥락을 영구 보존하므로,
> 컨텍스트 압축(compaction)보다 새 세션 시작이 항상 낫다.

**🟠 vs 🔴 구분 (v5.12):**
- **🟠 (15-30%)**: 작업 계속. 새로운 대규모 작업(3+ 파일 수정) 시작만 자제.
- **🔴 (≤15%)**: 즉시 핸드오프 (아래 트리거).
- 🔴 **🟠 경고에서 작업 거부 금지** — "컨텍스트 부족으로 새 세션 필요" 판단 금지.

**트리거** (어느 하나라도 해당 시 즉시 핸드오프 — 🔴만):
1. UserPromptSubmit 훅의 🔴 CONTEXT 경고 (컨텍스트 15% 이하 — JSONL 토큰 파싱)
2. 대화에서 `✻ Crunched` 메시지 확인 (auto-compact 발생 = 컨텍스트 80%+ 도달)
3. UserPromptSubmit 훅의 🔴 AUTO-WARN (15MB+ fallback — python3 없을 때)

**Claude의 행동**:
1. 현재 원자적 작업 완료 (진행 중인 Edit/커밋 마무리)
2. 🔴 핸드오프 노트 작성 (세션 스코핑 v5.8):
   ```bash
   mkdir -p ~/.claude/state/handoffs/
   PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')
   # 파일명: handoff-{timestamp}-pane{PANE_ID}-{hex}.md (PANE_ID 없으면 "x")
   ```
   ```
   # Session Handoff
   - pane: [PANE_ID 또는 "x"]
   - project: [프로젝트 경로]
   - task: [현재 작업 요약]
   - completed: [완료된 항목]
   - next_action: [다음 실행할 행동]
   - uncommitted: [yes/no]
   - timestamp: [현재 시각]
   ```
3. 🔴 자동 재시작 신호 (v5.8 세션 스코핑):
   ```bash
   PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')
   SUFFIX="${PANE_ID:+-pane$PANE_ID}"  # tmux면 "-pane5", 아니면 ""
   touch ~/.claude/state/SESSION_RESTART${SUFFIX}
   touch ~/.claude/state/TASK_COMPLETE${SUFFIX}
   ```
   🔴 **v5.10: 이 시점 이후 모든 도구 호출 금지** — PreToolUse 훅(phase0-gate.sh, pre-bash-check.sh)이 TASK_COMPLETE 파일을 감지하여 Read/Edit/Bash 등 모든 도구를 강제 차단. 텍스트 출력만 가능.
4. 사용자에게 안내 (도구 호출 없이 텍스트만 출력):
   ```
   ⚠️ 컨텍스트가 소진되어 이 세션을 마무리합니다.
   auto-session 사용 시 자동 재개됩니다.
   수동 재시작: `/clear` → `/autonomous`
   ```
5. conversation-sync Stop 훅이 자동으로 nlm 업로드

**Post-Compaction Recovery** (압축이 이미 발생한 경우):

> `✻ Conversation compacted` 메시지를 감지했으나 핸드오프 전에 압축이 완료된 경우,
> 같은 세션에서 nlm으로 맥락을 복구한 후 작업을 재개한다.

1. 🔴 nlm 대화 복구 (필수 — 건너뛰기 금지):
   ```bash
   export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"
   nlm notebook query sm-conv "현재 세션에서 작업하던 내용과 진행 상황은?"
   ```
2. 복구된 맥락과 압축 요약을 대조 → 누락된 디테일 보완
3. 이후 핸드오프 판단:
   - 작업이 거의 완료 → 마무리 후 핸드오프
   - 작업이 많이 남음 → 즉시 핸드오프 (압축 상태에서 대규모 작업 금지)

**새 세션**: Step 1.6에서 핸드오프 자동 감지. `/autonomous` = 핸드오프 사용, `/autonomous [작업]` = 무시+삭제.

**절대 금지**: 🔴 CONTEXT 경고 무시 | Crunched 후 새 작업 시작 | 핸드오프 없이 종료 | SESSION_RESTART 없이 수동 재시작 안내 | compacted 후 nlm 복구 없이 작업 계속 | **TASK_COMPLETE 터치 후 도구 호출** (v5.10: PreToolUse 훅이 강제 차단) | **🟠 CONTEXT 경고에서 "새 세션 필요" 판단** (🔴만 핸드오프 트리거)

---

## 📊 문서 동기화 시스템

> **프로젝트 문서는 Single Source of Truth**

### 🔴 핵심 개발 원칙
1. **문서 기반 개발**: 작업 전 프로젝트 기술문서에서 관련 파일/함수 확인
2. **문서 동기화**: 코드 변경 시 관련 문서도 **반드시** 업데이트
3. **커밋 전 확인**: 문서 업데이트 없이 코드 커밋 **금지**
4. **코드와 문서는 한 커밋에**: 코드만 커밋하고 문서는 나중에 = **규칙 위반**

---

## 자동 활성화 기능

| 카테고리 | 포함 기능 | 상태 |
|---------|---------|------|
| **컨텍스트 보존** | nlm 질의, repomix 스냅샷(attach 우선), Read 최소화, **대화 자동 동기화** | ✅ (v4.7) |
| **검증 체계** | 검증 프로토콜, 피드백 루프, Agent 교차 검증, 랄프 루프 | ✅ (v3.3) |
| **문서 동기화** | 기술문서 참조, 문서 업데이트, 커밋 전 확인, 양방향 동기화 | ✅ (v3.0) |
| **자율 실행** | ultrathink, Sequential Thinking, TodoWrite, Teams 필수 판단 | ✅ (v3.3) |
| **커밋 & 배포** | 자동 커밋 & 푸시, autonomous 자동 커밋, NotebookLM 동기화 | ✅ (v4.5) |

---

## 실행 지침

주어진 작업: $ARGUMENTS

### 🔴 STEP 0: nlm 질의 + 초기화 (차단 — nlm 완료 전 다른 도구 자동 차단)

아래 Bash 명령을 실행하세요:
```bash
# v5.9: 세션 스코핑 — 모든 상태 파일에 pane ID 포함
PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')
SUFFIX="${PANE_ID:+-pane$PANE_ID}"
mkdir -p ~/.claude/state && touch ~/.claude/state/AUTONOMOUS_MODE${SUFFIX}
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"
# CLAUDE.md "Phase 확장 설정"에서 nlm alias를 확인하여 아래 질의 실행
# 🔴 출력을 head/tail로 파이프하지 말 것 (Claude Code에서 사용 불가)
# nlm 출력은 보통 10~40행입니다. 파이프 불필요.
nlm notebook query <alias> "[작업 관련 질의]" && touch ~/.claude/state/PHASE0_COMPLETE${SUFFIX}
```

nlm 실패 시: `nlm login` → 재시도. 재시도도 실패 시:
`touch ~/.claude/state/PHASE0_COMPLETE${SUFFIX}` 실행 후 Read 도구로 기술문서 직접 읽기.
(`SUFFIX`는 STEP 0 bash에서 설정된 값 사용)

이 명령의 결과를 확인한 후, 아래 형식을 출력하세요:
```
✅ Phase 0 완료 - 기술문서 확인됨
관련 파일: [nlm 결과에서 추출]
관련 규칙: [해당 규칙 번호]
```

🔴 Phase 0 미완료 시 Read/Glob/Grep/Task 도구가 PreToolUse 훅에 의해 자동 차단됩니다.
🔴 Phase 0 상세 절차는 상단 "Phase 0: MANDATORY PRE-CHECK" 섹션 참조.

### Phase 2: 📝 문서 업데이트 의무 (수정만 — 커밋은 Phase 6.5)

> **🔴 코드 변경 시 관련 문서를 실시간으로 업데이트 - 사용자 요청 불필요**
> 이 단계에서는 커밋하지 않음. 모든 수정 완료 후 Phase 6.5에서 일괄 커밋 & 푸시.

**CLAUDE.md에 "Phase 2 확장: 파일→문서 매핑"이 있으면 해당 매핑에 따라 업데이트.**
**없으면: 수정한 파일과 관련된 프로젝트 문서를 찾아서 업데이트.**

**필수 업데이트 워크플로우**:
```
1. 코드 수정 완료
2. 빌드 검증 통과
3. 🔴 관련 문서 업데이트 (자동 - 사용자 요청 불필요)
4. 커밋 & 푸시
5. 프로덕션 배포
```

**절대 금지**:
```
❌ 코드 수정 후 문서 업데이트 없이 커밋
❌ "문서 업데이트 할까요?" 질문
❌ 사용자가 "문서 업데이트해" 말할 때까지 대기
```

### Phase 3: 🔄 autonomous.md 자동 커밋

> **🔴 autonomous.md 개선 시 자동으로 git 커밋 & 푸시 - 사용자 요청 불필요**

**필수 워크플로우**:
```
1. ~/.claude/commands/autonomous.md 수정 (전역 = 범용)
2. 버전 번호 증가 (예: v4.5 → v4.6)
3. autonomous 레포에 복사 + README.md 업데이트
4. 🔴 자동 커밋 & 푸시
```

**SSOT**: 전역(`~/.claude/commands/autonomous.md`)에서만 수정. 레포는 복사본. 수정 후 반드시 autonomous 레포 커밋 & 푸시 + README 업데이트.

### Phase 3.5: 🔄 양방향 동기화

교훈 발생 시: CLAUDE.md Phase 확장에 기록 → 범용화 가능하면 autonomous.md에 추상화 추가 → autonomous 레포 커밋.

**범용화 판단 기준**:
- "이 교훈은 다른 프로젝트에서도 적용 가능한가?"
- 가능하면 → 프로젝트 특화 용어를 제거하고 원칙만 추출
- 예: "source_type='competitor_info' 값 오류" → "에이전트 보고값은 원본과 반드시 대조"

---

### Phase 4: 심층 분석 — 근본 원인 연쇄 분석 (🔴 강제, v5.13)

> **현상만 가리면 같은 버그가 다른 옷을 입고 돌아온다.**
> 모든 문제에 3단계 인과 추적 필수. 출력 없이 Phase 5 진행 = 규칙 위반.

**🔴 필수 출력** (건너뛰기 금지):
```
🔍 인과 분석:
- 현상: [관찰된 문제 — what]
- 근접 원인: [직접 트리거 — how]
- 근본 원인: [설계/구조 결함 — why]
- 연쇄 영향: [같은 근본 원인이 유발할 수 있는 다른 문제]
- 수정 레벨: [현상 패치 / 근본 수정 / 둘 다]
```

**수정 레벨 판단**:
| 상황 | 수정 레벨 | 예시 |
|------|---------|------|
| 근본 수정 가능 + 영향 범위 제한적 | 근본 수정 | 상태 파일 TTL 도입 |
| 근본 수정 가능 + 영향 범위 광범위 | 근본 수정 + 현상 패치 (방어) | 아키텍처 변경 + 임시 가드 |
| 근본 수정 불가 (외부 제약) | 현상 패치 + 한계 문서화 | Claude 내장 동작 변경 불가 → 규칙으로 우회 |

**자가 점검** (수정 전 반드시):
1. "이 수정은 현상을 가리는가, 원인을 제거하는가?"
2. "같은 근본 원인이 다른 곳에서 다른 현상으로 나타날 수 있는가?"
3. "이 패치를 제거해도 시스템이 정상 작동하는가?" → 아니면 근본 미수정

**절대 금지**:
- ❌ 현상만 패치하고 "수정 완료" 선언 (근본 원인 미분석)
- ❌ 인과 분석 출력 없이 코드 수정 시작
- ❌ "원인 불명" 선언 (최소 3단계 why 추적 후에만 허용)

- ultrathink 모드로 문제 심층 분석
- 복잡한 문제는 Sequential Thinking MCP 사용
- TodoWrite로 작업 계획 수립

### Phase 4.5: Agent Teams 필수 판단 (🔴 강제)

> **매 작업마다 팀원 필요 여부를 판단하고 결과를 출력해야 한다**
>
> Phase 0처럼 건너뛸 수 없는 강제 단계. 출력 없이 Phase 5 진행 = 규칙 위반.

**🔴 필수 출력** (건너뛰기 금지):
```
📋 팀원 판단:
- 독립 파일 수: [N개]
- SSOT 파일 수정: [있음/없음]
- 순차 의존성: [있음/없음]
- 판정: [단독 진행 / 팀원 N명 구성]
- 사유: [1줄 사유]
```

**판단 기준**:

| 단독 진행 | 팀원 구성 (상한 없음, 범위에 비례) |
|----------|-------------------------------|
| 순차 의존 작업 | 독립 파일 3개+, SSOT 미포함 |
| SSOT 파일 수정 필요 | 다관점 분석 (리뷰) |
| 독립 파일 2개 이하 | 독립 기능 동시 개발 |
| 동일 패턴 반복 | 버그 원인 경쟁 조사 |
| 단순 질문/문서 수정 | 대규모 리팩토링 |

**핵심**: 에이전트 수량 제한 없음 (읽기/쓰기 무관). 작업 범위에 비례하여 자율 결정. 단, SSOT 파일 동시 수정 금지 + 팀원별 담당 파일 겹침 금지 원칙은 유지.

**팀원 구성 시 추가 절차**:
```
1. CLAUDE.md "Agent Teams 운영" 체크리스트 실행
2. 팀원별 담당 파일 배정 (겹침 금지)
3. Agent Teams 생성 (delegate mode)
4. 모든 완료 후 리더가 기술표 + 배포
```

**SSOT 파일 목록은 CLAUDE.md "Agent Teams 운영"의 SSOT 파일 참조.**

**자가 점검**:
```
"팀원 판단을 출력했나?"
  → 아니면 Phase 4.5 미완료
  → Phase 5로 진행 금지
```

### Phase 5: 자율 실행 규칙
- 기술적 판단은 자율 진행 (라이브러리 선택, 코드 구조 등)
- 🔴 단, 사용자 의도가 모호할 때는 반드시 확인 (예: "필요 없다"의 주어 불분명)
- TodoWrite로 모든 진행 상황 추적
- 모든 작업 완료까지 계속 진행
- 배포 전 테스트 포함

### 🔴 실패 = 진단 기회 (v5.14)

> **"안 되네" 선언 금지.** 모든 실패에 원인 파악 → 수정 시도 → 재시도.

**필수 행동**:
1. 실패 발생 → 에러 메시지 분석 (exit code, stderr, 로그)
2. 원인 분류: 인증? PATH? 권한? 네트워크? 설정? 계정?
3. 수정 가능하면 → 수정 후 재시도 (최대 3회)
4. 수정 불가하면 → **원인과 한계를 명시**하고 fallback

**절대 금지**:
- ❌ 에러 메시지 읽지 않고 "실패" 선언
- ❌ 원인 미파악 상태에서 fallback 전환
- ❌ "안 됩니다", "사용할 수 없습니다" 단정 (진단 없이)
- ❌ 1회 실패로 도구/기능 전체를 "사용 불가"로 판단

### Phase 5.5: 🔍 에이전트 결과 검증 (v3.3 강화)

> **에이전트 결과의 코드 값 + 수량 모두 원본 소스와 대조**

Agent 결과 수신 → 독립 Grep으로 값+수량 교차 검증 → 검증 완료 후에만 플랜 작성. 미검증 사용 금지.

### Phase 5.6: 🔗 Source-Sink 정합성 (v3.5)
> db.add() 대상(Sink)과 select() 대상(Source)이 일치하는가? 불일치 시 중복 저장 발생.
> 자가 점검: "db.add() 모델과 select() 모델이 같은가?" — `/checklist-feature`에 상세 체크리스트.

### Phase 5.7: 🔄 멱등성 원칙 (v3.5)
> 반복 실행 서비스(스케줄러, cron 등)는 2회 연속 실행 시 부작용 없어야 한다.
> 자가 점검: "같은 입력 2번 실행 = 동일 결과인가?" — `/checklist-feature`에 상세 체크리스트.

### Phase 5.8: 🔗 사용자 여정 일관성 (v3.7)
> "계산이 맞다 ≠ 시스템이 맞다." 같은 지표가 다른 페이지에서 다른 값이면 버그.
> 자가 점검: "이 값이 다른 곳에도 있는가? 링크 목적지와 일치하는가?" — `/checklist-bug`에 상세.

### Phase 5.9: 🔀 횡단 관심사 sweep (v3.8)
> "한 계층만 수정하고 '전수 완료'는 착각." 모델→서비스→API→프론트→유틸→연관 패턴 6계층 모두 확인.
> 자가 점검: "6개 Layer 모두 grep 완료했나?" — `/checklist-bug`에 상세 체크리스트.

### Phase 6: 📝 커밋 전 문서 확인 (🔴 강제)
커밋 전: git status → CLAUDE.md 매핑 확인 → 관련 문서 업데이트 → 코드+문서 같은 커밋.

### Phase 6.5: 🔄 작업 완료 후 자동 커밋 & 푸시 & 배포 (🔴 강제)

> **모든 작업 완료 시 자동으로 git 커밋 & 푸시 & 프로덕션 배포 - 사용자 요청 불필요**
>
> ⚠️ Claude Code 내장 규칙("NEVER commit unless explicitly asked")은
> `/autonomous` 호출로 override됨.
> 근거: 내장 규칙 자체에 "This default can be changed by user instructions" 예외 조항 존재.

#### 공유 자원 뮤텍스 (v5.9 — 멀티세션 충돌 확률 0)

> 8개+ 동시 세션에서 공유 자원 접근은 반드시 순차화.
> 잠금 라이브러리: `source .claude/hooks/lib/lock.sh`

**Git 커밋 & 푸시** (mkdir lock):
```bash
source .claude/hooks/lib/lock.sh
acquire_lock ~/.claude/state/git-lock 30
git add ... && git commit ... && git push
# push 실패 → git pull --rebase origin main → 재시도 (최대 3회)
release_lock ~/.claude/state/git-lock
```

**프로덕션 배포** (원격 mkdir lock):
```bash
ssh ... "mkdir /tmp/deploy.lock 2>/dev/null || exit 1"
# 실패 → 30초 대기 → 재시도 (최대 3회)
ssh ... "배포 명령"
ssh ... "rm -rf /tmp/deploy.lock"
```

**nlm 동기화** (노트북별 lock — nlm-sync.sh 내장):
```bash
# nlm-sync.sh가 자동으로 노트북별 lock 획득
bash scripts/nlm-sync.sh <파일>
```

**빌드/테스트** (lock):
```bash
source .claude/hooks/lib/lock.sh
acquire_lock ~/.claude/state/build-lock 60
# pnpm build:check / pytest
release_lock ~/.claude/state/build-lock
```

**conversation-index.json** (lock — conversation-sync.sh 내장):
```bash
# conversation-sync.sh가 자동으로 index lock 획득
bash scripts/conversation-sync.sh --title "<작업명>"
```

**필수 워크플로우**:
```
1. Phase 6 문서 확인 완료
2. git add (변경된 코드 + 문서)
3. git commit (의미 있는 메시지)
4. git push
5. 커밋 결과 출력
6. 🔴 프로덕션 배포 (CLAUDE.md에 "프로덕션 = 메인 환경" 또는 "Phase 6.5 확장: 배포" 있을 때):
   - CLAUDE.md 배포 명령어 실행 (프론트엔드 → 백엔드 순)
   - 서버 상태 검증 (pm2 online + HTTP 200)
   - 브라우저 확인 (영향 받는 페이지)
   - 검증 실패 시 로그 확인 → 자동 수정 (최대 3회)
7. 🔴 NotebookLM 동기화 (CLAUDE.md Phase 확장에 NotebookLM 설정 있을 때):
   - **문서 동기화**: 커밋에 포함된 문서 중 NotebookLM 소스 해당 파일 → `nlm-sync.sh <파일>` 실행
   - **코드 동기화**: 코드 변경이 있으면 → `repomix-sync.sh` 실행 (코드 스냅샷 재생성 + 업로드)
   - **동기화 검증**: 스크립트 exit code 확인. 실패 시:
     (a) 1회 재시도 (인증 만료 자동 복구 포함)
     (b) 재시도 실패 → 경고 출력 + `~/.claude/state/nlm-sync-status.json`에 기록 (다음 Phase 0 C-3에서 진단)
   - 커밋 롤백 사유 아님. 단, 실패를 삼키지 않고 기록.
8. 🔴 대화 동기화 (Stop 훅이 자동 처리 — 수동 불필요)
   - 세션 종료 시 Stop 훅이 conversation-sync.sh 자동 실행
   - 수동 필요 시: `bash scripts/conversation-sync.sh --title "<작업명>"`
9. 🔴 완료 신호 (세션 스코핑):
   ```bash
   PANE_ID=$(echo "$TMUX_PANE" | tr -d '%')
   SUFFIX="${PANE_ID:+-pane$PANE_ID}"
   touch ~/.claude/state/TASK_COMPLETE${SUFFIX}
   ```
   - TASK_COMPLETE 터치 시 SESSION_RESTART는 터치하지 않음
   - SESSION_RESTART = 컨텍스트 소진 핸드오프 전용 (세션 전환 전략 참조)
   - 🔴 **v5.10: TASK_COMPLETE 터치 후 모든 도구 호출 금지** — PreToolUse 훅이 자동 차단. 텍스트 출력만 가능.
```

**금지**: 커밋/배포 질문 | 커밋 없이 종료 | 푸시/배포 생략 | TASK_COMPLETE 없이 "완료" 선언 | **TASK_COMPLETE 후 도구 호출**
**점검**: 커밋&푸시 완료? 배포 완료? TASK_COMPLETE 전송?

### Phase 7: 검증 (완료 후 자동)

CLAUDE.md에 정의된 프로젝트별 검증 명령 사용. 없으면 기본:
```
[ ] Layer 0: 스키마 검증 (DB 변경 시)
[ ] Layer 1: 빌드 검증
[ ] Layer 2: 단위 테스트
[ ] Layer 3: API/통합 테스트
```

### Phase 8: 피드백 루프
- 검증 실패 시 자동 수정 시도 (최대 3회)
- 3회 실패 시 Phase 9로 전환

### Phase 9: 🔄 랄프 루프
> Phase 8 피드백 루프 3회 실패 시 `/infinite-loop` 커맨드로 전환 (최대 10회, 표지판 추가 방식).
> 10회 실패 시 → 사용자에게 명시적 보고 + 수동 개입 요청. 자동 종료 금지.

---

## 비상 정지
```bash
touch ~/.claude/state/EMERGENCY_STOP
```

---

🔴 **즉시 실행**: STEP 0 Bash 명령 실행 → Phase 0 완료까지 Read/Glob/Grep 훅 차단 → nlm 성공 시 게이트 해제.
