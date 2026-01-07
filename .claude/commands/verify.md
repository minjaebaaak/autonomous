# Verify Command

전체 AEGIS 검증 - 모든 Layer를 순차적으로 검증합니다.

## 실행 순서

### Layer 0: Schema Validation
```bash
./scripts/aegis-validate.sh --schema
```
- SQLite 스키마 확인
- 필수 테이블 존재 확인

### Layer 1: Static Analysis
```bash
cd app && pnpm build
cd server && pnpm build
pnpm lint
```
- TypeScript 빌드
- ESLint 검사

### Layer 2: Unit Test
```bash
pnpm test
```
- 단위 테스트 실행

### Layer 3: Integration Test
```bash
pnpm test:integration
```
- API 통합 테스트 (있는 경우)

### Layer 4: E2E Test
- Chrome MCP 또는 Playwright MCP로 E2E 테스트
- localhost:3000 접속 테스트
- 주요 사용자 시나리오 검증

## 검증 결과 형식

```
┌─────────────────────────────────────────────────┐
│            AEGIS Verification Report            │
├─────────────────────────────────────────────────┤
│ Layer 0: Schema      │ ✅ PASS                  │
│ Layer 1: Build       │ ✅ PASS                  │
│ Layer 1: Lint        │ ✅ PASS                  │
│ Layer 2: Unit Test   │ ✅ PASS                  │
│ Layer 3: Integration │ ⚠️  SKIP (not configured)│
│ Layer 4: E2E         │ ✅ PASS                  │
├─────────────────────────────────────────────────┤
│ Overall Status       │ ✅ ALL PASS              │
└─────────────────────────────────────────────────┘
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--quick` | Layer 0-1만 실행 |
| `--full` | 모든 Layer 실행 |
| `--e2e` | Layer 4 E2E만 실행 |

## 주의사항

- 실패한 Layer가 있으면 자동으로 Feedback Loop 실행
- 모든 Layer 통과 시 배포 준비 완료
