# 19. 발행시각 없는 기사가 홈 맨 위에 오는 문제

> 짝: 앱 18번 (홈 '다시 시도'만 뜨던 문제)

## 배경 (2026-10-18)
직접 변환 화면에서 변환한 기사는 `news_articles`에 카테고리·발행시각 없이 저장된다. `GET /api/news`는 `publishedAt DESC`로 정렬하는데 PostgreSQL은 DESC에서 NULL이 맨 앞(NULLS FIRST)이라, 이런 기사가 홈 첫 줄을 차지했고 앱 파싱 실패와 겹쳐 홈 전체가 "다시 시도"가 됐다.

## 무엇을 하는가
- `NewsService.getNews` 정렬을 `publishedAt DESC NULLS LAST`로 (목록·검색 둘 다 같은 정렬 사용)
- 직접 변환 기사를 홈에서 빼는 건 이번 범위 밖 (정렬만 바로잡음)

## 영향 범위
- `NewsService`, `NewsQueryTest`

## 완료 기준
- 발행시각 없는 기사가 목록·검색 결과 맨 뒤 (nullsLast 빼면 실패하는 것 확인), 기존 테스트 통과
