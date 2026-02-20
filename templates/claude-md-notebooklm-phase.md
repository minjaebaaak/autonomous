# CLAUDE.md NotebookLM Phase 확장 템플릿

> 이 파일의 내용을 프로젝트 CLAUDE.md 하단에 복사하세요.
> `<PLACEHOLDER>` 부분만 실제 값으로 교체하면 됩니다.

---

아래를 복사:

```markdown
### Phase 0 확장: NotebookLM

> autonomous v4.0+에서 자동 활용됩니다.

- **노트북 ID**: `<YOUR_NOTEBOOK_ID>`
- **질의**: `nlm notebook query "<YOUR_NOTEBOOK_ID>" "질의 내용"`
- **기술표 동기화**: `zsh scripts/nlm-sync.sh <기술문서경로>`
- **전체 동기화**: `bash scripts/repomix-sync.sh`
- **자동 동기화 대상**: `CLAUDE.md`, `PROJECT_DOCUMENTATION.md`

<!-- 추가 동기화 대상이 있으면 위 목록에 추가 -->
<!-- 예: `docs/technical-reference.html`, `docs/api-spec.md` -->
```

---

## 활용 방식

이 설정이 CLAUDE.md에 있으면 autonomous가 자동으로:

1. **Phase 0 (작업 시작)**: 기술문서를 직접 Read하는 대신 `nlm notebook query`로 필요한 부분만 질의 → 컨텍스트 토큰 절약

2. **Phase 6.5 (커밋 후)**: 변경된 문서 중 "자동 동기화 대상"에 해당하는 파일을 `nlm-sync.sh`로 NotebookLM에 자동 동기화

## 커스터마이징 포인트

| 항목 | 설명 | 예시 |
|------|------|------|
| 노트북 ID | `nlm notebook list`로 확인 | `af7bfaf0-5d0f-...` |
| 동기화 대상 | NotebookLM에 최신 유지할 파일 | `CLAUDE.md`, 기술문서 |
| nlm-sync 호출 | macOS: `zsh`, Linux: `bash` | `zsh scripts/nlm-sync.sh` |
