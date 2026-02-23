Feedback Loop - 자동 검증 및 수정 루프.

코드 작업 완료 후 자동 검증 및 수정을 수행합니다.

## 동작 흐름

```
[작업 완료] → [검증] → [실패?] → [자동 수정] → [재검증] → (최대 3회)
                ↓
            [성공] → 완료 보고
```

## 실행 단계

### 1. Layer 0-3 검증

> **프로젝트별 수정 영역**: 아래 명령어를 프로젝트에 맞게 교체하세요.
> CLAUDE.md의 자동 검증 섹션에 정의된 명령어를 사용합니다.

```bash
cd <PROJECT_PATH>

# Layer 0: 타입 체크 (예: pnpm typecheck, mypy ., tsc --noEmit)
<TYPECHECK_COMMAND>

# Layer 1: 코드 품질 검사 (예: pnpm lint, ruff check ., eslint .)
<LINT_COMMAND>

# Layer 2: 단위 테스트 (예: pnpm test, pytest tests/, go test ./...)
<TEST_COMMAND>

# Layer 3: 프로덕션 빌드 (예: pnpm build, python -m build, go build ./...)
<BUILD_COMMAND>
```

### 2. 실패 시 자동 수정

**에러 분석:**
1. 에러 메시지에서 파일 경로와 라인 번호 추출
2. 에러 유형 파악 (타입, 린트, 테스트, 빌드)
3. 해당 코드 수정

**수정 전략:**
- TypeScript 에러: 타입 정의 수정
- ESLint 에러: 코드 스타일 수정 (자동 fix 우선)
- 테스트 실패: 테스트 케이스 또는 구현 수정
- 빌드 에러: import/export, 의존성 문제 해결

### 3. 재검증 (최대 3회)

```
시도 1: 검증 실패 → 수정 → 재검증
시도 2: 검증 실패 → 수정 → 재검증
시도 3: 검증 실패 → 사용자 보고 + 중단
```

### 4. 결과 보고

**성공 시:**
```markdown
## 피드백 루프 완료

✅ Layer 0: Type Check - PASS
✅ Layer 1: Lint - PASS
✅ Layer 2: Unit Test - PASS
✅ Layer 3: Build - PASS

총 시도: 1회
```

**실패 시 (3회 초과):**
```markdown
## 피드백 루프 실패

❌ 3회 시도 후에도 해결되지 않음

### 마지막 에러:
[에러 메시지]

### 시도한 수정:
1. [수정 내용 1]
2. [수정 내용 2]
3. [수정 내용 3]

사용자 확인이 필요합니다.
```

## 주의사항

- 자동 수정이 불가능한 복잡한 에러는 사용자에게 즉시 보고
- 빌드 에러 중 환경 설정 문제는 수정 대상에서 제외
- Stop 훅으로 사용자 알림 발송 (3회 실패 시)

## 수동 실행

이 커맨드는 CLAUDE.md 자동 검증 섹션에 따라 자동 실행되지만,
필요 시 `/feedback-loop`로 수동 호출 가능합니다.
