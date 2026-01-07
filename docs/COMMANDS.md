# AEGIS Protocol - 명령어 레퍼런스

## 기본 명령어

### /commit

변경사항을 분석하여 스마트한 커밋 메시지를 생성합니다.

```
/commit
```

**동작:**
1. `git status`로 변경 파일 확인
2. `git diff`로 변경 내용 분석
3. 변경 내용에 맞는 커밋 메시지 생성
4. `git add` + `git commit` 실행

**예시 출력:**
```
feat(auth): Add OAuth2.0 login support

- Add Google OAuth provider
- Add token refresh logic
- Update user schema for OAuth fields
```

---

### /verify

전체 7-Layer 검증을 실행합니다.

```
/verify [options]
```

**옵션:**
- `--all`: 전체 Layer 검증
- `--build`: Layer 1만 실행 (빌드, 타입체크)
- `--test`: Layer 2만 실행 (유닛 테스트)
- `--api`: Layer 3만 실행 (API 테스트)
- `--e2e`: Layer 4만 실행 (E2E 테스트)
- `--schema <table>`: Layer 0 스키마 검증

**예시:**
```
/verify --build        # 빌드만 검증
/verify --schema users # users 테이블 스키마 검증
/verify --all          # 전체 검증
```

---

### /feedback-loop

빌드/테스트 실패 시 자동으로 수정을 시도합니다.

```
/feedback-loop
```

**동작:**
1. 빌드 실행
2. 실패 시 에러 분석
3. 자동 수정 시도
4. 다시 빌드 (최대 3회 반복)
5. 성공 또는 최대 횟수 도달 시 종료

**설정 (aegis.config.js):**
```javascript
automation: {
  feedbackLoop: {
    enabled: true,
    maxRetries: 3,
    commands: [
      'cd app && pnpm build',
      'cd server && pnpm build',
      'pnpm lint',
      'pnpm test',
    ],
  },
}
```

---

### /infinite-loop

목표를 달성할 때까지 무한 반복합니다 (Ralph Wiggum 모드).

```
/infinite-loop <목표>
```

**예시:**
```
/infinite-loop 모든 타입 에러 수정하기
/infinite-loop 테스트 커버리지 80% 달성
```

**동작:**
1. 목표 설정
2. 현재 상태 분석
3. 문제 해결 시도
4. 목표 달성 여부 확인
5. 미달성 시 2번으로 돌아감 (최대 10회)

**설정 (aegis.config.js):**
```javascript
automation: {
  infiniteLoop: {
    enabled: true,
    maxIterations: 10,
    breakOnSuccess: true,
  },
}
```

---

## 스킬

### verify-app

E2E 검증을 수행합니다 (로그인, 핵심 기능 테스트).

**호출:**
```
verify-app 스킬을 실행해줘
```

**동작:**
1. 브라우저 실행 (Chrome MCP)
2. 로그인 테스트
3. 핵심 기능 테스트
4. 결과 리포트 생성

---

### code-simplifier

코드 정리 및 최적화를 수행합니다.

**호출:**
```
code-simplifier 스킬로 이 파일 정리해줘
```

**동작:**
1. 코드 분석
2. 중복 코드 제거
3. 변수명/함수명 개선 제안
4. 불필요한 코드 삭제

---

## 검증 스크립트

### aegis-validate.sh

커맨드라인에서 직접 검증을 실행할 수 있습니다.

```bash
# 전체 검증
./scripts/aegis-validate.sh --all

# 빌드만
./scripts/aegis-validate.sh --build

# API 테스트
./scripts/aegis-validate.sh --api

# 스키마 검증
./scripts/aegis-validate.sh --schema users email
```

---

## Hook 이벤트

### PermissionRequest

권한 요청 시 알림을 보냅니다.

**트리거:** Claude Code가 권한을 요청할 때
**스크립트:** `.claude/hooks/notify-user.sh`

### Stop

응답 완료 시 알림을 보냅니다.

**트리거:** Claude Code가 응답을 완료했을 때
**스크립트:** `.claude/hooks/notify-user.sh '사용자 입력 필요'`

### PostToolUse

Write/Edit 후 자동 포맷팅을 실행합니다.

**트리거:** 파일 수정 후
**스크립트:** `.claude/hooks/post-tool-format.sh`

---

## 다음 단계

- [INSTALLATION.md](./INSTALLATION.md) - 설치 가이드
- [CONFIGURATION.md](./CONFIGURATION.md) - 설정 가이드
