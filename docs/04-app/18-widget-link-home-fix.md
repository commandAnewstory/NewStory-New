# 18. 위젯 기사 탭 시 'Page Not Found' + 홈 '다시 시도'만 뜨는 문제

## 배경 (2026-10-18 실기기 확인, 17번 설치 직후)
1. 위젯 줄을 누르면 앱이 열리면서 **Page Not Found**
   - 원인: Android Flutter는 기본으로 앱을 연 링크(`newstory://article/7?style=card`)를 라우터 경로로 그대로 넘김(host 버리고 `/7?style=card`) → go_router에 없는 경로. 17번에서 만든 `home_widget` 클릭 처리와 별개로 기본 딥링크가 먼저 동작한 것
2. 홈이 **"다시 시도"**만 뜸
   - 서버 로그엔 `/api/news` 요청이 정상 처리됨(에러 없음) → 앱 쪽 파싱 실패
   - 원인(유력): 직접 변환 화면에서 변환한 기사는 `news_articles`에 카테고리·발행시각 없이 저장되는데, 앱 `Article.fromJson`이 둘 다 필수(`as String`)라 한 건만 있어도 목록 전체가 실패. 발행시각 null은 최신순 정렬에서 맨 앞에 와서 첫 페이지가 항상 깨짐 (백엔드 19번에서 정렬도 수정)

## 무엇을 하는가
1. `AndroidManifest.xml`: `flutter_deeplinking_enabled=false` — 위젯 링크는 `home_widget` 클릭 처리로만 이동
2. go_router `onException` → 모르는 경로는 홈으로 (Page Not Found 화면 안 띄움)
3. `Article.fromJson`: 제목·URL·카테고리·발행시각 null 허용(빈 문자열) — 한 건 때문에 목록 전체가 실패하지 않게

## 영향 범위
- `app/android/app/src/main/AndroidManifest.xml`, `app/lib/core/router/app_router.dart`, `app/lib/features/home/article.dart`
- `app/test/features/home_robustness_test.dart` (신규)

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과, APK 매니페스트에 플래그 포함
- 테스트: null 필드 기사 파싱 / 섞여 있어도 홈 목록 표시 / 모르는 경로 → 홈 (수정 되돌리면 실패하는 것 확인)
- 실기기 확인(사용자): 위젯 줄 탭 → 카드요약 생성, 홈 목록 정상
