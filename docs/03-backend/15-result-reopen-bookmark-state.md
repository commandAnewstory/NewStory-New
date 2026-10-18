# 15. 저장된 변환 결과 다시 보기 + 보관함 저장 상태 표시

## 목표
앱에서 (1) 보관함/히스토리 항목을 눌러 변환 결과를 다시 열고, (2) 기사 상세의 "보관함에 저장" 버튼을 토글(저장 ↔ 저장 취소)로 만들려면 백엔드가 다음 두 가지를 줘야 한다.
- `GET /api/convert/{resultId}`가 지금은 용어 풀이(glossary)를 항상 빈 배열로 줌 → 다시 열면 용어 하이라이트가 사라짐
- 변환 응답에 "이미 보관함에 있는지"가 없음 → 버튼 초기 상태를 알 수 없음

## 결정 — 같은 기사를 다시 변환할 때 (2026-10-12, A안 확정)
지금은 같은 사용자가 같은 기사·스타일·레벨을 다시 열 때마다 `converted_results`에 **새 행이 생김** (캐시 히트여도). 그래서
- 히스토리에 같은 항목이 중복으로 쌓이고
- 보관함 저장 여부가 매번 새 `resultId` 기준이라 "저장됨" 상태가 유지가 안 됨

- **A안 (채택)**: 같은 사용자 + 같은 기사·스타일·레벨이면 기존 행을 재사용 (새 행 안 만듦). 히스토리 중복 없어지고 저장 상태도 자연스럽게 유지됨. 히스토리 정렬은 "마지막으로 본 시간" 기준이 되도록 `viewed_at` 갱신
- B안 (미채택): 지금처럼 매번 새 행. 저장 여부는 "같은 기사·스타일·레벨로 저장한 게 하나라도 있으면 저장됨"으로 계산, 저장 취소 시 그 항목을 지움. 히스토리 중복은 그대로

## 결정 — 보관함에 있는 항목을 히스토리에서 지울 때 (2026-10-12)
작업 중 발견: 지금은 보관함에 저장된 항목을 히스토리에서 지우면 FK 제약 때문에 **500 에러** (테스트로 재현). 사용자 결정: **히스토리에서만 숨긴다** — 보관함엔 그대로 남고, 같은 기사를 다시 보면 히스토리에 다시 나타남. 보관함에 없는 항목은 지금처럼 실제 삭제.

## 무엇을 하는가 (A안 기준)
1. 마이그레이션 `V7__converted_results_level_viewed_hidden.sql`: `converted_results`에 `level VARCHAR(10)` 추가 (기존 행은 `MEDIUM`), `viewed_at TIMESTAMP` 추가 (기존 행은 `created_at` 값), `hidden_from_history BOOLEAN` 추가, 조회용 인덱스
2. `ConvertService.convert()`: 사용자의 기존 결과(기사·스타일·레벨 일치)가 있으면 재사용 + `viewed_at` 갱신 + 히스토리 숨김 해제, 없으면 새로 생성. V7 이전에 쌓인 중복 행이 있으면 보관함에 든 행을 우선 재사용
3. `GET /api/convert/{resultId}`: 저장된 레벨로 `conversion_cache`를 찾아 glossary·readingTimeLabel까지 채워서 반환 (캐시가 이미 삭제된 경우엔 빈 glossary)
4. `ConvertResponse`에 `bookmarked: boolean` 추가 — `POST /api/convert`, `GET /api/convert/{resultId}` 둘 다
5. 히스토리 정렬을 `viewed_at` 내림차순으로 변경
6. 히스토리/보관함 응답에 `articleUrl`, `level` 추가 (히스토리는 `viewedAt`도) — 앱의 공유 기능(원문 링크)과 다시 보기 화면에서 사용. 변환 응답에도 `level` 추가
7. 히스토리 삭제: 보관함에 있으면 `hidden_from_history = true`, 없으면 행 삭제. 히스토리 목록은 숨긴 행 제외

## 영향 범위
- `backend/src/main/resources/db/migration/V7__converted_results_level_viewed_hidden.sql` (실제 파일명)
- `ConvertedResult`, `ConvertResponse`, `ConvertService`, `ConvertPersister`, `ConvertedResultRepository`, `HistoryService`/`HistoryResponse`, `BookmarkResponse`
- API 응답에 필드 **추가만** 함 — 기존 앱은 그대로 동작 (모르는 필드는 무시함)

## 완료 기준 (테스트로 확인)
- 같은 사용자가 같은 요청 2번 → `converted_results` 행 1개, 응답 `id` 동일
- 보관함에 추가한 뒤 같은 기사 다시 변환 → `bookmarked: true`
- `GET /api/convert/{resultId}` 응답에 glossary가 원래 변환 때와 동일하게 들어있음
- 다른 사용자의 resultId 조회 시 기존과 같이 접근 거부 (401 — 기존 `UnauthorizedException` 동작 유지)
- 보관함에 있는 항목을 히스토리에서 지우면 500 대신 히스토리에서만 빠지고 보관함엔 남음
- 13·14번 테스트 전부 통과
