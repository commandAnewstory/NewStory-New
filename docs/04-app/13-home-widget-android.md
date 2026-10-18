# 13. 홈스크린 위젯 — 오늘의 카드요약 3개 (Android)

## 목표
마스터 기획서 백로그 7번. 지금은 MY 화면 토글이 서버에 값만 저장하고, 실제 홈스크린 위젯 코드는 없다 (2026-10-12 사용자 결정: 이번에 구현). 1차 목표가 Android APK라서 **Android만** 만든다. iOS 위젯은 범위 밖.

## 무엇을 하는가
1. 패키지: `home_widget` (Flutter ↔ 네이티브 위젯 데이터 공유), `workmanager` (주기적 갱신)
2. Android 네이티브
   - `AppWidgetProvider` (Kotlin) + 레이아웃 XML: 상단 "오늘의 카드요약", 카드 3줄(기사 제목 2줄 + "30초 컷" 배지), 색상은 카드요약 토큰(`#D7F3EE`/`#0B6E64`)
   - 위젯 정보 XML: 4x2 기본, 리사이즈 가능
   - 매니페스트에 receiver 등록
3. 데이터: 앱이 `GET /api/widget/today-cards`(로그인 불필요) 호출 → 결과를 `home_widget`에 저장 → 위젯 갱신
   - 갱신 시점: 앱 실행 시, MY에서 토글 켤 때, 그리고 `workmanager`로 약 3시간마다 (Android 최소 주기 15분, 배터리 고려)
   - 서버에 카드요약 변환 결과가 하나도 없으면 "아직 카드요약이 없어요" 표시 (현재 서버는 오늘 것이 3개 미만이면 날짜 상관없이 최근 3개로 채움)
4. 토글 연동: MY 토글이 꺼져 있으면 위젯에 "MY에서 위젯을 켜주세요" 표시하고 주기 갱신 중단, 켜면 즉시 갱신 + 주기 갱신 재개
5. 위젯 탭 → 앱 열기 (특정 기사로 바로 이동은 이번 범위 밖 — 위젯 응답에 변환 결과 id가 없어서 별도 작업 필요)

## 구현 메모
- 위젯 갱신 로직은 `HomeWidgetService`(순수 Dart)로 분리 — 저장소(`home_widget`)·주기 예약(`workmanager`)은 인터페이스로 받아서 테스트에선 메모리 구현으로 바꿔 끼움. Android가 아닌 환경(테스트 포함)에선 아무것도 안 하는 구현이 들어감
- 위젯과 공유하는 키: `enabled`, `state`(`ok`/`empty`/`disabled`), `card_count`, `card_{0..2}_title`, `card_{0..2}_time`. Kotlin `TodayCardsWidget`이 같은 이름으로 읽음
- 토글 반영 시점: MY에서 프로필 불러올 때(서버 값 동기화), 토글 **서버 저장이 성공했을 때만**, 앱 시작 시(로그인 상태면 `/api/users/me`로 서버 값 먼저 맞춤 — 재설치·다른 기기 대비, 실패하거나 로그아웃 상태면 마지막으로 반영된 값 사용)
- 불러오기 실패 시 위젯의 기존 카드는 지우지 않음. 주기 작업은 실패를 돌려줘서 workmanager가 나중에 재시도
- 배지 문구는 서버 `readingTimeLabel`(예: "약 30초") 그대로 사용
- 한 번도 데이터를 못 받은 상태에서 켜져 있으면 "앱을 열면 카드요약을 불러와요" 표시
- 시스템 주기 갱신(`updatePeriodMillis`)은 0 — 갱신은 앱의 workmanager(3시간, 네트워크 연결 시)가 담당
- 로그아웃해도 위젯은 그대로 둠 (위젯 데이터는 로그인 불필요한 공개 카드라서)

## 영향 범위
- `app/pubspec.yaml`
- `app/android/app/src/main/AndroidManifest.xml`, `.../kotlin/com/newstory/app/TodayCardsWidget.kt` (신규), `res/layout/`, `res/xml/` (신규)
- `app/lib/core/widget/home_widget_service.dart`, `home_widget_platform.dart`, `home_widget_sync.dart` (신규), `app/lib/main.dart`, `app/lib/features/my/my_provider.dart`
- `app/android/app/src/main/res/values/widget_strings.xml`, `res/drawable/widget_*.xml` (신규)
- 백엔드 변경 없음

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과 (데이터 변환·토글 로직 단위 테스트)
- `flutter build apk --debug` 성공
- **실기기 확인 필요(사용자)**: 런처에서 위젯 추가 → 카드 3개 표시 → 토글 끄면 안내 문구 → 탭하면 앱 열림
