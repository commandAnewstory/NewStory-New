# 11. 보관함 저장 토글 + 공유

> 선행: 백엔드 15번 머지 (`bookmarked`, `articleUrl` 필드 필요)

## 목표
기사 상세의 "보관함에 저장" 버튼과 공유 버튼이 지금은 "곧 추가될 예정" 스낵바만 띄움. 실제로 동작하게 만든다.

## 무엇을 하는가
1. **보관함 저장 토글** (사용자 결정: 토글)
   - 변환 탭(동화체/소설체/카드요약)에서: 저장 안 됨 → `POST /api/bookmarks/{resultId}` → 버튼이 "저장됨"으로 바뀜. 저장됨 상태에서 누르면 `DELETE` → 다시 "보관함에 저장"
   - 초기 상태는 변환 응답의 `bookmarked` 값
   - 원문 탭에서는 지금처럼 비활성(회색) — 저장할 변환 결과가 없음
   - 연타 방지(요청 중엔 버튼 잠금), 실패 시 원래 상태로 되돌리고 스낵바
   - 보관함 탭 목록은 다음에 열 때 새로 불러오도록 갱신 표시
2. **직접 변환 화면**에도 결과 아래 같은 저장 버튼 추가 (지금 `ConvertResult`에 `resultId`가 안 들어가 있어서 함께 수정)
3. **공유** (사용자 결정: 변환문 + 원문 링크) — `share_plus` 패키지로 시스템 공유 시트
   - 변환 탭: `기사 제목` + 빈 줄 + 변환문 앞부분(최대 200자, 넘치면 `…`) + 빈 줄 + `원문: <URL>`
     - (2026-10-17 변경: 잘리지 않게 변환문 전체 — 앱 16번)
   - 카드요약: 앞부분 대신 bullet 전체(5개 이하라 짧음)
   - 원문 탭: `기사 제목` + `원문: <URL>`
   - 용어 마킹은 이미 서버에서 제거된 순수 텍스트라 그대로 사용

## 구현 메모
- 저장/취소 요청은 `core/bookmark/bookmark_api.dart` 하나로 공통화 (기사 상세·직접 변환 둘 다 사용). 화면 상태가 서버보다 늦은 경우(이미 저장됨 409, 이미 없음 404)는 원하던 결과라 성공으로 처리
- 기사 상세 상단 북마크 아이콘도 같은 토글로 연결 (저장되면 채워진 아이콘)
- 공유 문구 생성은 `core/share/share_text.dart`의 순수 함수로 분리해서 테스트

## 영향 범위
- `app/pubspec.yaml` (`share_plus` 추가)
- `app/lib/features/article/article_detail_screen.dart`, `article_detail_provider.dart`
- `app/lib/features/convert/convert_screen.dart`, `convert_provider.dart`
- `app/lib/features/bookmarks/bookmarks_provider.dart` (갱신 트리거)
- `app/lib/core/bookmark/bookmark_api.dart`, `app/lib/core/share/share_text.dart` (신규)
- `app/lib/core/router/app_router.dart` (`BookmarkSavePainter`에 채움 옵션)
- `app/test/**`

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과
- 테스트: 저장→저장됨 표시, 저장됨→취소, 실패 시 롤백, 원문 탭 비활성, 공유 텍스트 형식
- 실기기 확인 필요(사용자): 실제 공유 시트가 뜨는지
