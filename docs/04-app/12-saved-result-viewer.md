# 12. 보관함·히스토리 항목 다시 보기

> 선행: 백엔드 15번 머지 (`GET /api/convert/{resultId}`가 glossary 포함해서 응답)

## 목표
지금 보관함/히스토리 목록의 항목은 삭제만 되고 눌러도 아무 일이 없다. 눌러서 저장된 변환 결과를 다시 볼 수 있게 한다.

## 무엇을 하는가
1. 새 라우트 `/bookmarks/result/:resultId` — "저장된 변환" 화면
   - 상단: 뒤로가기, 기사 제목, 스타일 칩(동화체/소설체/카드요약 색상 토큰)
   - 본문: 기존 위젯 재사용 — 동화체/소설체는 `ConvertedTab`(용어 하이라이트 + 뜻풀이 팝업 포함), 카드요약은 `CardSummaryView`
   - 하단: 11번과 같은 저장 토글 + 공유 버튼, "원문 보기" (원문 URL로 기존 기사 상세 원문 탭 대신 외부 브라우저 열기 — `url_launcher`)
   - 로딩/에러(다시 시도) 상태
2. 보관함 카드·히스토리 항목에 탭 동작 연결 (삭제 버튼은 그대로)
3. 이 화면에서 저장 취소 후 뒤로 가면 보관함 목록에서 빠져 있어야 함

## 구현 메모
- 변환 결과 단건 API(`GET /api/convert/{resultId}`)엔 기사 제목·URL이 없어서, 목록 응답(`articleTitle`, `articleUrl`, `style`)을 화면 이동 시 함께 넘긴다 (`SavedResultArgs`). 그래서 이 화면에 링크로 바로 들어오면 제목·원문 링크 없이 본문만 보인다 — 지금 앱엔 그런 진입 경로가 없음
- 하단: 저장 토글 / "원문"(외부 브라우저) / 공유. 저장 취소하면 보관함 목록 갱신 신호를 보내서 뒤로 가면 목록에서 빠져 있음

## 영향 범위
- `app/lib/core/router/app_router.dart`
- `app/lib/features/bookmarks/**` (신규 `saved_result_screen.dart`, `saved_result_provider.dart`, 카드 탭 연결, 목록 모델에 `articleUrl`)
- `app/lib/core/launch/url_opener.dart` (신규)
- `app/lib/features/article/widgets/*` (재사용 — 수정 최소화)
- `app/pubspec.yaml` (`url_launcher` 추가)
- `app/test/**`

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과
- 테스트: 항목 탭 → 화면 진입 → glossary 하이라이트 표시, 카드요약은 bullet 뷰, 에러 시 다시 시도
