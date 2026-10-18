# 2026-10-18 위젯을 "관심 카테고리 인기 뉴스"로 교체

## 결정 (사용자)
- 관심 카테고리: MY에서 여러 개 선택, 서버(`users.interest_categories`) 저장, 안 고르면 전체
- 위젯 내용: 관심 카테고리의 **오늘 인기 뉴스 3개 제목** (오늘 조회수순, 모자라면 최신으로 채움)
- 위젯 줄을 누르면 앱이 그 기사 **카드요약 탭으로 열리며 바로 생성** — 서버가 미리 만들지 않음 (AI 비용). 한 번 만든 건 캐시라 다음부턴 즉시
- 기존 위젯(누군가 만든 최근 카드요약 3개)은 교체. `/api/widget/today-cards`는 옛 앱 호환용으로만 남김

## 메모
- 위젯 백그라운드 갱신은 로그인 토큰 없이 돌아서 `/api/widget/popular`는 공개 + 카테고리를 쿼리로 받음
- 서브플랜: `docs/03-backend/18-interest-categories-popular-widget.md`, `docs/04-app/17-interest-widget-card-deeplink.md`
