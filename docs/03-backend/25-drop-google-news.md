# 25. Google News 수집 중단 + 기존 기사 정리

## 문제
홈 위젯/목록에서 기사를 눌렀을 때 "가끔 본문을 못 가져옴". AWS 서버에서 언론사별로 4건씩 `/api/convert/original` 확인:
- 동아일보 4/4, SBS 4/4, 조선일보 4/4 성공
- **Google News 0/4 (전부 502)** — 링크가 `news.google.com/rss/articles/...` 리다이렉트라 기사 본문이 아님
- 수집 기사 중 약 1/5이 Google News라 "가끔" 실패로 보임

## 변경
- `RssNewsCollector` 소스에서 Google News 2개(정치, IT) 제거
- `V9__remove_google_news_articles.sql`: 이미 쌓인 `source_type='google_news'` 기사 삭제 (조회 기록 포함). 변환 캐시·변환 결과가 붙은 기사는 보관함 보호로 남김

## 영향
- IT 카테고리 기사가 동아일보 IT 피드만 남아 적음 → IT 피드 추가는 별도 작업

## 테스트
`RemoveGoogleNewsMigrationTest` — 실제 PostgreSQL에서 마이그레이션 SQL 실행 결과 확인. 백엔드 전체 66개 통과
