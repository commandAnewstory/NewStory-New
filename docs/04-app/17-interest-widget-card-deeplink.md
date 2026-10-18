# 17. 관심 카테고리 설정 + 위젯 교체(관심 인기 뉴스) + 누르면 카드요약

> 선행: 백엔드 18번 머지

## 목표
MY에서 관심 카테고리를 고르면, 위젯에 그 카테고리 오늘 인기 뉴스 3개 제목이 뜨고, 하나를 누르면 앱이 그 기사 **카드요약 탭으로 열리며 바로 생성**됨.

## 무엇을 하는가
1. **MY 화면**: 위젯 카드 아래 "관심 카테고리" 칩(정치·경제·사회·문화·IT·스포츠) 여러 개 선택. 누를 때마다 서버 저장(`PATCH /api/users/me`), 실패하면 원래대로 + 스낵바. 안 고르면 "전체"로 안내
2. **위젯 데이터 교체**: `GET /api/widget/today-cards` → `GET /api/widget/popular?categories=…`
   - 관심 카테고리는 위젯 저장소에도 저장해서 백그라운드 갱신(로그인 토큰 없음)이 그대로 씀
   - 갱신 시점은 13번 그대로(앱 시작·MY 프로필 로드·토글·약 3시간) + 관심 카테고리 바꿀 때
   - 위젯 헤더 "오늘의 카드요약" → "관심 뉴스", 줄마다 제목 + 카테고리 배지
   - 비었을 때 문구 "아직 오늘 뉴스가 없어요"
3. **위젯 줄 탭 → 카드요약**: 줄마다 `newstory://article/{id}?style=card` 링크로 앱 열기
   - 앱이 꺼져 있다가 위젯으로 켜졌을 때 / 켜져 있을 때 둘 다 처리 (`home_widget` 클릭 이벤트)
   - 로그인 안 돼 있으면 로그인 화면 (변환은 로그인 필요)
   - 기사 상세가 카드요약 탭으로 열리고 난이도 묻지 않고 기본 난이도로 바로 생성 시작 (16번 동시 생성 구조 그대로)
   - 위젯 빈 공간(헤더 등) 탭은 지금처럼 앱만 열기

## 구현 메모
- 위젯 저장소 키: `categories`(쉼표 구분), `card_{i}_title`, `card_{i}_badge`(카테고리), `card_{i}_id`(기사 id, 문자열). 예전 `card_{i}_time`은 안 씀
- 위젯 줄마다 `HomeWidgetLaunchIntent.getActivity(..., Uri)` — 링크(data)가 달라서 줄마다 별도 PendingIntent
- 앱: `widgetLaunchSourceProvider`(앱이 위젯으로 켜졌을 때 + 켜져 있을 때 클릭 스트림) → `widgetUriToLocation` → `router.go`. 모르는 링크는 무시(앱만 열림)
- 기사 상세 `initialStyle`: 기사 URL·사용자 기본 난이도를 다 불러온 뒤 `openWithStyle`로 변환 시작 (16번 동시 생성 구조 그대로, 이미 만든 건 재요청 안 함)
- 로그인 안 된 상태면 라우터 redirect로 로그인 화면 (로그인 후 그 기사로 자동 이동은 이번 범위 밖)

## 영향 범위
- `app/lib/features/my/**`, `app/lib/core/widget/**`, `app/lib/core/router/app_router.dart`, `app/lib/main.dart`
- `app/lib/features/article/article_detail_screen.dart` (`initialStyle`)
- `app/android/.../TodayCardsWidget.kt`, `res/layout/today_cards_widget.xml`, `res/values/widget_strings.xml`
- `app/test/**`

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과, `flutter build apk` 성공
- 테스트: 관심 칩 선택→PATCH, 실패 시 롤백 / 위젯 갱신이 저장된 카테고리로 popular 호출, id·제목·카테고리 저장 / 위젯 링크 파싱(`newstory://article/7?style=card` → `/home/article/7?style=card`) / 카드요약 탭으로 열리며 바로 변환 요청(style=card), 난이도 화면 안 거침
- 실기기 확인(사용자): 런처 위젯에 관심 뉴스 3개 → 하나 누르면 카드요약 생성
