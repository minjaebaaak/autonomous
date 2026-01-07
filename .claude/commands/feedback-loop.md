# Feedback Loop Command

피드백 루프 - 코드 작업 후 자동 검증 및 수정을 수행합니다.

## 실행 순서

1. **Layer 1: 빌드 검증**
   ```bash
   cd app && pnpm build
   cd server && pnpm build
   ```

2. **Layer 1: 린트 검증**
   ```bash
   pnpm lint
   ```

3. **Layer 2: 테스트 실행**
   ```bash
   pnpm test
   ```

4. **실패 시 자동 수정**
   - 에러 메시지 분석
   - 코드 수정
   - 재검증
   - **최대 3회 반복**

5. **결과 보고**
   - 성공: 모든 검증 통과 보고
   - 실패: 상세 에러 보고 및 수정 필요 사항 안내

## 자동 수정 대상

| 에러 유형 | 자동 수정 |
|----------|----------|
| TypeScript 타입 에러 | 가능 |
| ESLint 에러 | 가능 |
| Import 에러 | 가능 |
| 테스트 실패 | 분석 후 시도 |
| 빌드 에러 | 분석 후 시도 |

## 주의사항

- 3회 실패 시 자동으로 중단
- 중단 시 사용자에게 상세 보고
- 복잡한 문제는 Sequential Thinking MCP로 분석
