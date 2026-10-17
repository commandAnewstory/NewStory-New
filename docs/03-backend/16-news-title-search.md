# 16. 뉴스 제목 검색 (+ 카테고리 필터)

## 목표
앱 홈의 돋보기 아이콘이 지금은 그림만 있고 동작이 없음. 기사 **제목**에 검색어가 들어간 기사를 찾고, 카테고리로 좁힐 수 있게 한다. (2026-10-16 사용자 결정: 제목 `LIKE %검색어%`, 카테고리별 필터 검색)

## 무엇을 하는가
1. 기존 `GET /api/news`에 `keyword` 파라미터 **추가** (새 엔드포인트 안 만듦, 기존 응답 형식·페이징 그대로)
   - `GET /api/news?keyword=금리&category=경제&page=0&size=20`
   - `keyword`: 앞뒤 공백 제거 후 비어 있으면 무시 → 지금과 동일하게 동작
   - 제목에 검색어가 포함된 기사: `LOWER(title) LIKE LOWER('%검색어%')` (영문 대소문자 무시)
   - 검색어에 `%`, `_`, `\`가 있으면 와일드카드가 아니라 글자 그대로 찾도록 이스케이프
   - `category`와 같이 쓰면 AND 조건. 정렬은 지금처럼 `publishedAt` 최신순
   - 검색어 최대 50자 (넘으면 400)
2. 공개 엔드포인트 그대로 (`/api/news` GET은 이미 permitAll)

## 구현 메모
- `NewsArticleRepository`에 `@Query` 하나: `(:category IS NULL OR a.category = :category) AND LOWER(a.title) LIKE :pattern ESCAPE '\'`
- 이스케이프·패턴 생성은 `NewsService`에서. 인덱스 없는 LIKE라 풀스캔이지만 기사가 한 달치만 유지돼서(매일 3시 정리) 수천 건 수준 — 지금 규모에선 문제없음. 커지면 pg_trgm 인덱스 검토

## 영향 범위
- `NewsController`, `NewsService`, `NewsArticleRepository`
- `backend/src/test/.../news/NewsQueryTest.java` (테스트 추가)
- 응답 형식 변경 없음 — 기존 앱 그대로 동작

## 완료 기준 (테스트)
- 제목 일부로 검색 → 해당 기사만, 최신순
- 영문 대소문자 무시
- 검색어 + 카테고리 → 둘 다 맞는 것만
- `%`, `_` 검색 시 와일드카드로 동작 안 함
- 공백만 있는 검색어 → 전체 목록과 동일
- 50자 초과 → 400
- 기존 13~15번 테스트 전부 통과
