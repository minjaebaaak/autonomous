# NAVIFACT - autonomous 교훈 아카이브

## 세션 1~3 (2026-02-27): MVP 구축

### 교훈 1: React Flow v12 타입 제약
- **문제**: React Flow v12에서 Node/Edge의 `data` 프로퍼티가 `Record<string, unknown>`을 확장해야 함
- **해결**: EventNodeData 등 커스텀 타입에 `[key: string]: unknown` 인덱스 시그니처 추가
- **범용화 가능**: "라이브러리 타입 제약은 빌드 전에 확인" (autonomous에 이미 존재)

### 교훈 2: JSON import 타입 소실
- **문제**: TypeScript에서 JSON을 직접 import하면 union type이 string으로 추론됨
- **예시**: `status: "verified"` → `status: string`으로 추론되어 컴포넌트 props와 불일치
- **해결**: 명시적 type assertion (`e.status as "verified" | "disputed" | "unverified" | "false"`)
- **범용화 가능**: "JSON import 시 타입 좁히기 필요" → 범용 규칙으로 승격 가능

## 세션 4 (2026-02-27): 백엔드-프론트엔드 연결

### 교훈 3: 프론트엔드-백엔드 모델 불일치 처리
- **문제**: 프론트엔드(한국어 카테고리, 0-100 정수, short ID)와 백엔드(영어 enum, 0.0-1.0 float, UUID)의 데이터 형태 차이
- **해결**: 데이터 접근 레이어(lib/data.ts)에 변환 함수 집중. 컴포넌트는 변환 불필요.
- **범용화 가능**: "FE-BE 모델 차이는 중간 레이어에서 흡수, 컴포넌트에 누출 금지"

### 교훈 4: 정적 폴백의 가치
- **패턴**: API fetch → transform → 반환. try/catch → 정적 JSON 폴백.
- **효과**: 백엔드 없이도 프론트엔드 빌드 + 전체 기능 동작. 개발/데모 모두 유용.
- **범용화 가능**: "데이터 레이어에 항상 정적 폴백을 두면 개발 속도와 안정성 동시 확보"
