# Smart Commit Command

스마트 커밋 - 변경사항을 분석하고 자동으로 커밋 메시지를 생성합니다.

## 실행 순서

1. `git status`로 변경사항 확인
2. `git diff --staged`로 스테이징된 변경사항 분석
3. 변경사항이 없으면 `git add .`로 모든 변경사항 스테이징
4. 변경 타입 분석 (feat, fix, refactor, docs, style, test, chore)
5. 의미있는 커밋 메시지 자동 생성
6. `git commit` 실행
7. 결과 보고

## 커밋 메시지 형식

```
<type>(<scope>): <description>

<body>

🤖 Generated with Claude Code
```

## 타입 가이드

| 타입 | 설명 |
|------|------|
| feat | 새로운 기능 추가 |
| fix | 버그 수정 |
| refactor | 코드 리팩토링 |
| docs | 문서 변경 |
| style | 코드 스타일 변경 (포맷팅 등) |
| test | 테스트 추가/수정 |
| chore | 빌드 설정, 패키지 관리 등 |

## 주의사항

- 민감한 정보(API 키, 비밀번호 등)가 포함된 파일은 커밋하지 않음
- `.env` 파일은 경고 후 사용자 확인 요청
