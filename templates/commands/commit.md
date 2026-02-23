Smart commit with auto-generated message.

변경사항을 분석하여 커밋 메시지를 자동 생성하고 커밋합니다.

## 실행 단계

### 1. 변경사항 분석
```bash
git status
git diff --staged
git diff
```

### 2. 커밋 메시지 생성 규칙

**형식**: `<type>: <description>`

**타입**:
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 포맷팅
- `refactor`: 리팩토링
- `test`: 테스트 추가/수정
- `chore`: 빌드, 설정 등

**예시**:
- `feat: 크롤링 결과 페이지네이션 추가`
- `fix: 로그인 세션 만료 버그 수정`
- `refactor: DNA 서비스 코드 정리`

### 3. 커밋 실행
```bash
git add .
git commit -m "메시지"
```

### 4. Push 여부 확인
- 사용자에게 push 여부 확인
- 승인 시: `git push origin <branch>`

## 주의사항

- 민감한 파일 (.env, credentials 등) 커밋 금지
- 커밋 전 변경사항 요약을 사용자에게 보여줄 것
- 커밋 메시지는 한국어로 작성

## 실행

위 단계를 순서대로 실행하세요. 커밋 메시지는 변경 내용을 분석하여 자동 생성하되, 커밋 전 사용자 확인을 받으세요.
