# 10. 앱 정리 + 빠진 API 연결

## 목표
UI만 있고 동작이 없거나, 백엔드엔 있는데 앱이 안 쓰는 부분을 정리한다. 새 화면은 없고 기존 코드 정리·연결 위주.

## 무엇을 하는가
1. **MY 메뉴 5개 제거** (계정 정보/알림 설정/언어/문의하기/이용약관) — 2026-10-12 사용자 결정. 로그아웃만 남김. 프로필 카드의 화살표(눌러도 아무 동작 없음)도 제거
2. **카테고리 칩에서 '국제' 제거** — 수집 소스가 없어 항상 빈 목록. 나머지 7개 하드코딩 유지 (사용자 결정)
3. **로그아웃 시 서버 호출** — `POST /api/auth/logout`으로 refresh 토큰을 서버에서도 폐기한 뒤 기기 토큰 삭제. 서버 호출이 실패해도(오프라인 등) 기기 로그아웃은 진행
4. **조회수 기록** — 기사 상세 진입 시 `POST /api/news/{id}/view` 1회 호출 (실패해도 화면엔 영향 없음). 지금은 앱이 이걸 안 불러서 인기순 API용 데이터가 안 쌓임
5. **용어 난이도 기본값** — 기사 상세의 레벨 선택 기본값을 항상 `MEDIUM` 대신 사용자의 `lastGlossaryLevel`로 (마스터 기획서 5장 스펙)
6. **안 쓰는 코드 삭제** — `HeroCard`, `ArticleGridCard`, `ThirtySecBadge` (09번 홈 리스트 변경 이후 미사용)
7. **테스트 기반** — 깨져 있는 기존 스모크 테스트(`ProviderScope` 누락) 수정, Dio를 가짜로 바꿔 끼울 수 있는 테스트 헬퍼 추가, 위 3·4·5번 동작에 대한 테스트 작성

## 영향 범위
- `app/lib/features/my/my_screen.dart`, `my_provider.dart`
- `app/lib/core/auth/auth_notifier.dart`
- `app/lib/features/home/widgets/category_chip_bar.dart` (+ 삭제 3개 파일)
- `app/lib/features/article/article_detail_provider.dart`, `article_detail_screen.dart`
- `app/test/**`
- 백엔드 변경 없음

## 완료 기준
- `flutter analyze` 이슈 0개, `flutter test` 전부 통과
- MY 화면에 프로필 카드 / 위젯 카드 / 로그아웃만 남음
- 로그아웃 시 `/api/auth/logout` 호출 확인 (테스트)
- 기사 상세 진입 시 `/view` 1회 호출 확인 (테스트)
