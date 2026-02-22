# Autonomous Mode v5.1 - 범용 프레임워크

> **`/autonomous [작업]` 하나로 모든 최적화가 자동 적용됩니다.**
>
> v5.1: Phase 9 종료 조건 명시 + Phase 2/6.5 역할 명확화. Phase 0 PreToolUse 훅 강제.

---

## 🛑 Phase 0: MANDATORY PRE-CHECK

> **🔴 이 단계를 건너뛰면 규칙 위반. 모든 작업은 여기서 시작.**
>
> **핵심**: 규칙의 존재 ≠ 규칙 준수. 강제 메커니즘이 필요하다.

### 🔴 실행 순서 (반드시 순서대로 - 건너뛰기 금지)

**Step 1: 기술문서 참조 (모든 작업 — nlm 강제)** (필수 - 생략 금지)

> **🔴 근거**: NotebookLM에 CLAUDE.md, MEMORY.md, 기술표, 규칙화 문서가 모두 포함됨.
> CLAUDE.md "기술표 업데이트 의무"에서 "코드 변경 후 기술표 관련 섹션 업데이트 필수"이므로,
> **작업 규모와 무관하게** nlm 질의는 필수.

CLAUDE.md "Phase 확장 설정"에서 **Phase 0 NotebookLM** 항목을 찾는다:

**A) NotebookLM 설정이 있으면 (alias 또는 노트북 ID):**
```bash
# 🔴 반드시 아래 Bash 명령을 실행할 것 (Read 도구로 기술문서 직접 읽기 금지)
# 🔴 출력을 head/tail로 파이프하지 말 것 (Claude Code에서 사용 불가)
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"
nlm notebook query "<alias 또는 노트북ID>" "<작업 관련 질의>"

# 카테고리별 질의 (CLAUDE.md Phase 확장에서 alias 확인):
# nlm notebook query sm-rules "소유권 감지 규칙은?"     # 규칙/교훈
# nlm notebook query sm-tech "SERP 수집 관련 파일은?"   # 기술/코드
# nlm notebook query sm-conv "지난 세션에서 title 버그 수정은?"  # 대화 이력
# 모르겠으면 여러 노트북 병렬 질의
```
- 질의 결과에서 관련 파일/함수 목록을 추출한다
- 필요 시 grep으로 교차 검증한다
- **🔴 nlm 성공 시 Read 도구로 기술문서 전체를 읽지 않는다** (토큰 낭비)

**B) NotebookLM 설정이 없으면:**
- 기술문서를 Read 도구로 직접 읽는다

**C) nlm 실패 시 — 원인별 분기 (🔴 fallback 전 재인증 필수):**

**C-1) 인증 만료 (Authentication expired):**
1. 🔴 `nlm login` 실행 (필수 — 건너뛰기 금지)
2. 재인증 성공 → nlm query 재시도
3. 재인증 실패 → fallback: 기술문서를 Read 도구로 직접 읽는다

**C-2) command not found / 기타 오류:**
- fallback: 기술문서를 Read 도구로 직접 읽는다

**절대 금지:**
```
❌ 인증 만료 시 `nlm login` 없이 바로 fallback
❌ "nlm 실패 → 직접 비교 진행" (재인증 시도 없이)
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

**Step 1.7: 이전 세션 복원 (nlm 대화 검색)** (선택 — 설정 있을 때)

세션 이월(continuation) 또는 새 세션에서 이전 맥락이 필요하면:

1. 로컬 인덱스 확인 (즉시):
```bash
python3 -c "import json; [print(f'{e[\"date\"]} {e[\"topic\"]}') for e in json.load(open(os.path.expanduser('~/.claude/conversation-index.json')))]" 2>/dev/null
```
2. 관련 주제 발견 시 → 대화 노트북 질의:
```bash
nlm notebook query sm-conv "지난 세션에서 작업하던 [주제] 진행 상황은?"
```
3. 미발견 시 → 전체 노트북 병렬 질의 후 인덱스 보완

대화 동기화 설정이 없으면 이 Step 건너뛰기.

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

### 자가 점검 질문 (매 작업 시작 시)

```
"기술문서 먼저 확인했나?"
  → 아니면 즉시 Phase 0 실행

"Phase 0 완료 메시지 출력했나?"
  → 아니면 아직 시작 안 한 것

"관련 파일 목록 추출했나?"
  → 아니면 Phase 0 미완료

"규칙이 X를 반영한다고 주장하려 하고 있나?"
  → 해당 규칙을 nlm/Read로 확인했나?
  → 아니면 확인 후 주장 (P2 위반 방지)
```

### Phase 0 미완료 시 조치

1. **즉시 중단**
2. **Phase 0으로 복귀**
3. **기술문서 읽기부터 다시 시작**

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

### Read 도구 사용 조건 (4가지만 허용)

1. **Edit/Write 직전** — 수정 범위만 (offset + limit 50~100줄)
2. **repomix/grep으로 찾을 수 없는 특수 파일** — 설정 파일, JSON 등
3. **특정 줄 번호를 이미 알 때** — offset + limit 최소 읽기
4. **수정 결과 검증** — 소형 파일(~100줄)은 Read, 대형 파일은 nlm query

### 질의 패턴 (개발 시작 전 반드시 실행)

| 상황 | 질의 예시 |
|------|-----------|
| 새 기능 구현 전 | "XXX 관련 기존 구현이 있나?" |
| 도메인 지식 필요 | "XXX의 요건/스펙은?" |
| 과거 설계 결정 | "XXX를 왜 이렇게 결정했지?" |
| 에러/이슈 해결 | "XXX 처리를 어떻게 했었지?" |
| 세션 이월 (컨텍스트 복원) | "지난 세션에서 작업하던 XXX 진행 상황은?" |

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
mkdir -p ~/.claude/state && touch ~/.claude/state/AUTONOMOUS_MODE
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:$PATH"
# CLAUDE.md "Phase 확장 설정"에서 nlm alias를 확인하여 아래 질의 실행
# 🔴 출력을 head/tail로 파이프하지 말 것 (Claude Code에서 사용 불가)
# nlm 출력은 보통 10~40행입니다. 파이프 불필요.
nlm notebook query <alias> "[작업 관련 질의]" && touch ~/.claude/state/PHASE0_COMPLETE
```

nlm 실패 시: `nlm login` → 재시도. 재시도도 실패 시:
`touch ~/.claude/state/PHASE0_COMPLETE` 실행 후 Read 도구로 기술문서 직접 읽기.

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

**🔴 전역 = 유일한 SSOT (v3.6 교훈)**:
```
- 수정: 반드시 전역(`~/.claude/commands/autonomous.md`)에서만
- 레포: 전역 복사본일 뿐. 직접 수정 절대 금지
- 방향: 전역 → 레포 단방향만 허용
```

**절대 금지**:
```
❌ autonomous.md 수정 후 커밋하지 않음
❌ README.md 업데이트 없이 autonomous.md만 커밋
❌ "커밋할까요?" 질문
❌ autonomous 레포에서 직접 autonomous.md 수정 (전역 우회)
❌ 레포에서 버전 올리고 전역에 미반영
```

---

### Phase 3.5: 🔄 양방향 동기화 규칙 (v3.0 신규)

> **autonomous = 지혜의 집약체. 프로젝트에서 배운 교훈은 범용으로 승격.**

**구조**:
```
autonomous 레포/
├── .claude/commands/autonomous.md     # 범용 (지혜의 집약체)
├── projects/[프로젝트]/
│   ├── CLAUDE-ext.md                  # 프로젝트 Phase 확장 백업
│   └── autonomous-history.md          # 프로젝트 교훈 아카이브
```

**규칙**:
```
1. 범용 autonomous.md 수정 시:
   - ~/.claude/commands/autonomous.md 수정 (전역 = 실제 사용 파일)
   - autonomous 레포에 복사 + README.md 업데이트
   - autonomous 레포에 커밋 & 푸시
   → 모든 프로젝트에 즉시 반영 (전역이므로)

2. 프로젝트 교훈 발생 시:
   - 해당 프로젝트 CLAUDE.md의 Phase 확장에 기록
   - 범용화 가능한 교훈이면 → 프로젝트 특화 세부사항을 추상화
     → 범용 autonomous.md에 추상화 버전 추가
   - autonomous 레포 projects/[프로젝트]/autonomous-history.md에 원본 기록
   - autonomous 레포 projects/[프로젝트]/CLAUDE-ext.md에 Phase 확장 백업
   - autonomous 레포에 커밋 & 푸시

3. CLAUDE.md Phase 확장 수정 시:
   - autonomous 레포 projects/[프로젝트]/CLAUDE-ext.md에 동기화
   - autonomous 레포에 커밋 & 푸시
```

**범용화 판단 기준**:
- "이 교훈은 다른 프로젝트에서도 적용 가능한가?"
- 가능하면 → 프로젝트 특화 용어를 제거하고 원칙만 추출
- 예: "source_type='competitor_info' 값 오류" → "에이전트 보고값은 원본과 반드시 대조"

---

### Phase 4: 심층 분석 레이어 활성화
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
- 오류 발생 시 자체 해결 시도 (최대 3회)
- 배포 전 테스트 포함

### Phase 5.5: 🔍 에이전트 결과 검증 (v3.3 강화)

> **에이전트 결과의 코드 값 + 수량 모두 원본 소스와 대조**

**A. 값 검증** (기존):
1. 에이전트 보고서의 코드 블록에서 핵심 값(변수명, 상수, 함수명) 추출
2. Grep/Read로 원본 파일에서 실제 값 확인
3. 불일치 시 **원본 파일의 값**을 사용

**B. 수량 교차 검증** (v3.3 신규 - 🔴 필수):
1. 에이전트가 "N곳 발견" 보고 시, 독립적 Grep으로 실제 수량 확인
2. 불일치 시 누락분 식별 및 분석
3. **수량 일치 확인 출력 (필수)**:
   ```
   ✅ 수량 교차 검증:
   - 파일: [파일명]
   - Agent 보고: N곳
   - Grep 실제: M곳
   - 불일치: [있음/없음]
   ```

**C. 교차 검증 완료 후에만 플랜 작성 가능** (v3.3 신규):
- Agent 결과 수신 → **반드시** 독립 Grep → 불일치 보고 → 그 후에 플랜 작성
- 이 순서를 건너뛰면 **규칙 위반**

**절대 금지**:
```
❌ 에이전트 보고서의 코드 블록을 검증 없이 그대로 사용
❌ 에이전트가 보고한 변수명/상수값을 확인 없이 코드에 적용
❌ 에이전트 보고 수량을 "전수"로 간주 (독립 Grep 없이)
❌ Agent 결과 수신 → 바로 플랜 작성 (교차 검증 생략)
```

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

> **코드 커밋 전에 반드시 관련 문서 업데이트 확인**

**필수 체크리스트** (커밋 전 매번 확인):
```
[ ] 1. 수정한 파일 목록 확인 (git status)
[ ] 2. CLAUDE.md "Phase 2 확장" 매핑에 해당하는 파일인지 확인
[ ] 3. 해당하면 관련 문서 먼저 업데이트
[ ] 4. git add에 문서 파일 포함
[ ] 5. 코드와 문서를 같은 커밋에 포함
```

**자가 점검 질문** (커밋 직전에 자문):
- "문서 업데이트 없이 커밋하려 하고 있나?"
- "수정한 코드가 프로젝트 문서에 반영되어 있나?"
- → **아니면 즉시 문서 업데이트 후 커밋**

### Phase 6.5: 🔄 작업 완료 후 자동 커밋 & 푸시 (🔴 강제)

> **모든 작업 완료 시 자동으로 git 커밋 & 푸시 - 사용자 요청 불필요**
>
> ⚠️ Claude Code 내장 규칙("NEVER commit unless explicitly asked")은
> `/autonomous` 호출로 override됨.
> 근거: 내장 규칙 자체에 "This default can be changed by user instructions" 예외 조항 존재.

**필수 워크플로우**:
```
1. Phase 6 문서 확인 완료
2. git add (변경된 코드 + 문서)
3. git commit (의미 있는 메시지)
4. git push
5. 커밋 결과 출력
6. 🔴 NotebookLM 동기화 (CLAUDE.md Phase 확장에 NotebookLM 설정 있을 때):
   - **문서 동기화**: 커밋에 포함된 문서 중 NotebookLM 소스 해당 파일 → `nlm-sync.sh <파일>` 실행
   - **코드 동기화**: 코드 변경이 있으면 → `repomix-sync.sh` 실행 (코드 스냅샷 재생성 + 업로드)
   - nlm 실패 시 경고만 출력 (커밋 완료됨, 블로커 아님)
7. 🔴 대화 동기화 (Stop 훅이 자동 처리 — 수동 불필요)
   - 세션 종료 시 Stop 훅이 conversation-sync.sh 자동 실행
   - 수동 필요 시: `bash scripts/conversation-sync.sh --title "<작업명>"`
```

**절대 금지**:
```
❌ "커밋할까요?" / "커밋이 필요하시면 말씀해 주세요" 질문
❌ 작업 완료 후 커밋 없이 종료
❌ 커밋만 하고 푸시 생략
```

**자가 점검** (RALPH_DONE 출력 전):
```
"커밋 & 푸시를 완료했나?"
  → 아니면 Phase 6.5 미완료
  → RALPH_DONE 출력 금지
```

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

## 사용 예시

**Before (기존):**
```
/autonomous ultrathink Sequential Thinking MCP 기반으로 배포해줘
```

**After (v3.0+):**
```
/autonomous 배포해줘
```
→ 모든 최적화 자동 적용!

---

**즉시 실행을 시작합니다.**

🔴 **첫 번째 행동**: 위 "STEP 0: nlm 질의 + 초기화"의 Bash 명령을 실행하세요.
🔴 Phase 0 완료 전에는 Read/Glob/Grep/Task 도구가 훅에 의해 차단됩니다.
🔴 nlm 성공 시 자동으로 게이트가 해제되며, 그 후 Explore/Read 사용 가능합니다.
