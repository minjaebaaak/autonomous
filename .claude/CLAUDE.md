# 프로젝트 규칙

> `/autonomous` 설치 시 함께 복사하여 사용하세요.

---

## 언어
- 한국어로 사고하고, 한국어로 소통할 것

## 행동 원칙
- 질문보다 실행 우선
- 오류 발생 시 자체 해결 시도 (최대 3회)
- TodoWrite로 진행 상황 추적

## 계획 파일 관리

> **완료된 계획은 아카이브하고, 새 작업은 새 계획 파일로 시작**

### 디렉토리 구조
```
~/.claude/plans/
├── archive/                    # 완료된 계획 파일
│   └── YYYY-MM/               # 월별 정리
└── [활성 계획 파일들]          # 진행 중인 계획
```

### 생명주기

1. **새 작업 시작**: 기존 계획 파일이 다른 작업용이면 초기화 또는 새 파일 생성
2. **작업 완료 시**: archive 폴더로 이동
   ```bash
   mkdir -p ~/.claude/plans/archive/$(date +%Y-%m)
   mv ~/.claude/plans/[파일명].md ~/.claude/plans/archive/$(date +%Y-%m)/
   ```
3. **정기 정리 (월 1회)**: 30일 이상 미수정 파일 자동 아카이브
   ```bash
   find ~/.claude/plans -maxdepth 1 -name "*.md" -mtime +30 -exec mv {} ~/.claude/plans/archive/$(date +%Y-%m)/ \;
   ```

### 주의사항
- 완료된 계획 내용을 새 계획에 복사 금지 (혼란 방지)
- 필요 시 아카이브에서 참조만 할 것
- 계획 파일 50KB 초과 시 정리 필요 신호

---

## API 타임존 규칙 🔴 필수

> **모든 datetime API 응답에 타임존 정보 포함 필수**

**배경**:
- DB는 일반적으로 UTC로 저장
- `.isoformat()` 단독 사용 시 타임존 정보 없음 (`"2026-02-05T08:35:01"`)
- 프론트엔드 `new Date()`가 로컬 시간으로 오해석
- 결과: "2시간 전"이 "10시간 전"으로 잘못 표시 (9시간 오차)

**필수 패턴**:
```python
# ❌ 금지 - 타임존 정보 없음
"created_at": obj.created_at.isoformat() if obj.created_at else None

# ✅ 필수 - 타임존 변환 후 반환
from ..utils.timezone import utc_to_local  # 프로젝트별 구현
local_dt = utc_to_local(obj.created_at) if obj.created_at else None
"created_at": local_dt.isoformat() if local_dt else None
```

**적용 대상 필드**:
- created_at, updated_at, deleted_at
- started_at, completed_at, finished_at
- published_at, posted_at, last_used_at
- 사용자에게 "N시간 전" 형태로 표시되는 모든 datetime

**검증 방법**:
```bash
# API 응답에 타임존 오프셋 포함 여부 확인
curl http://localhost:[PORT]/api/[endpoint] | grep -o 'T[0-9:]*[+-][0-9:]*'
```

**코드 리뷰 체크리스트**:
```
[ ] 새 API 엔드포인트에 datetime 필드가 있는가?
[ ] .isoformat() 단독 사용하고 있는가? → 타임존 변환 적용
[ ] API 응답에 타임존 오프셋 포함되는가?
```

---

## 커스터마이징

필요에 따라 프로젝트별 규칙을 추가하세요:

```markdown
## 프로젝트별 규칙

### 기술 스택
- [사용하는 언어/프레임워크]

### 코딩 스타일
- [팀 코딩 컨벤션]

### 배포 환경
- [배포 대상 서버/서비스]
```
