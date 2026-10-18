# 18. 관심 카테고리 + 위젯용 관심 인기 뉴스 API

> 짝: 앱 17번 (MY 관심 카테고리 설정 + 위젯 교체 + 탭하면 카드요약)

## 목표 (2026-10-18 사용자 요청)
관심 카테고리를 설정해두면, 그 카테고리의 **오늘자 인기 뉴스 3개** 제목이 앱을 안 켜도 홈스크린 위젯에 뜨고, 누르면 그 기사 카드요약이 바로 생성돼 보이게.

## 결정 (사용자)
- 관심 카테고리: MY에서 설정, **서버(users)에 저장** — 재설치·다른 기기에도 유지. 아무것도 안 고르면 전체
- 인기 기준: **오늘(서버 시각 00:00 이후) 올라온 기사 중 오늘 조회수 많은 순**. 조회 없으면 최신순, 3개 미만이면 해당 카테고리 최신 기사로 채움 (오늘 기사가 없어도 위젯이 비지 않게)
- 카드요약은 **누르면 그때 생성** (서버 미리 생성 안 함 — AI 비용). 한 번 만들어진 건 캐시라 다음부턴 즉시
- 기존 위젯(누군가 만든 최근 카드요약 3개)은 이걸로 **교체**

## 무엇을 하는가
1. 마이그레이션 `V8__users_interest_categories.sql`: `users.interest_categories VARCHAR(100) NOT NULL DEFAULT ''` (쉼표 구분)
2. `PATCH /api/users/me`에 `interestCategories: string[]` 추가 — 허용값 `정치·경제·사회·문화·IT·스포츠`(앱 칩과 동일), 그 외 값이 있으면 400, 중복 제거. `GET /api/users/me` 응답에 `interestCategories` 추가
3. 신규 `GET /api/widget/popular?categories=정치,IT` (로그인 불필요 — 위젯 백그라운드 갱신은 토큰 없이 돌기 때문에 카테고리를 쿼리로 받음)
   - 응답: 최대 3개 `[{ articleId, title, category }]`
   - 빈 값/생략 → 전체 카테고리. 허용값 아닌 건 무시
4. 기존 `GET /api/widget/today-cards`는 그대로 둠 (새 앱은 안 씀, 옛 앱 호환)

## 영향 범위
- `db/migration/V8__users_interest_categories.sql` (신규)
- `User`, `UpdateUserRequest`, `UserResponse`, `UserService`
- `domain/widget/**` (`PopularNewsResponse` 신규, `WidgetService`, `WidgetController`), `NewsArticleRepository` (쿼리 추가), `SecurityConfig` (`/api/widget/popular` 공개)
- 마스터 기획서: 백로그 7번 위젯 설명, 엔드포인트 표, users 스키마

## 완료 기준 (테스트)
- 관심 카테고리 저장 → 조회 시 그대로, 잘못된 값 400, 빈 배열로 초기화
- 인기: 오늘 기사 중 오늘 조회수순 / 조회 같으면 최신순 / 어제 기사는 오늘 기사보다 뒤 / 3개 미만이면 최신으로 채움 / 카테고리 필터 / 생략 시 전체 / 로그인 불필요
- 기존 테스트 전부 통과
