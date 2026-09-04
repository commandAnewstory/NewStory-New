# 01. RSS 기반 뉴스 수집 파이프라인

> 마스터 기획서 8장 "개발 순서" 2번. 네이버 뉴스 검색 API 제거 → 언론사 RSS + Google News RSS 하이브리드 수집.

## 왜 하는가

마스터 기획서 2장: 네이버 API는 단일장애점 + 정치성향 편중 리스크. 언론사 RSS를 기본으로, Google News RSS를 보조로 사용하는 하이브리드 구조로 전환.

## 구체적 변경사항

### 1. DB 스키마 (Flyway V2)

`news_articles` 테이블에 컬럼 2개 추가:

```sql
ALTER TABLE news_articles ADD COLUMN category    VARCHAR(30)  NULL;
ALTER TABLE news_articles ADD COLUMN source_type VARCHAR(20)  NOT NULL DEFAULT 'rss';
```

- `category`: RSS 피드 카테고리 (정치/경제/사회/IT/스포츠/연예 등). 레거시 행은 NULL 허용.
- `source_type`: `rss` | `google_news`. 확장 여지 남김.

### 2. 수집 소스 목록 (코드 내 고정)

| 언론사 | RSS URL | 카테고리 |
|---|---|---|
| 조선일보 | `https://www.chosun.com/arc/outboundfeeds/rss/` | 전체 |
| 중앙일보 | `https://rss.joins.com/joins_news_list.xml` | 전체 |
| 동아일보 | `https://rss.donga.com/total.xml` | 전체 |
| SBS | `https://news.sbs.co.kr/news/RSS.xml` | 전체 |
| MBC | `https://imnews.imbc.com/rss/news/news_00.xml` | 전체 |
| Google News (IT/과학) | `https://news.google.com/rss/search?q=기술+IT&hl=ko&gl=KR&ceid=KR:ko` | IT |
| Google News (정치) | `https://news.google.com/rss/search?q=정치&hl=ko&gl=KR&ceid=KR:ko` | 정치 |

> RSS URL은 언론사가 바꿀 수 있음 — 추후 DB나 설정 파일로 옮길 수 있지만 이번엔 코드 내 상수로 관리.

### 3. 신규/변경 파일

**신규:**
- `domain/news/client/RssFeedClient.java` — Jsoup으로 RSS XML 파싱. `<item>` → `RssItem` DTO 변환. User-Agent 헤더 설정.
- `domain/news/dto/RssItem.java` — title, link, description, pubDate, source, category 필드
- `domain/news/service/RssNewsCollector.java` — 소스 목록 순회 → `RssFeedClient` 호출 → 신규 기사만 `news_articles` upsert (url unique 제약으로 중복 방지)

**변경:**
- `domain/news/entity/NewsArticle.java` — `category`, `sourceType` 필드 추가
- `domain/scheduler/NewsScheduler.java` — stub → `RssNewsCollector.collectAll()` 호출. 1시간 간격 유지.
- `domain/news/service/NewsService.java` — `getNews()`에 `category` 파라미터 추가 (null이면 전체)
- `domain/news/controller/NewsController.java` — `GET /api/news`에 `?category=` 파라미터 추가, `GET /api/news/categories` 엔드포인트 추가

### 4. API 변경 (마스터 기획서 5장 반영)

```
GET /api/news?category=IT&page=0&size=20   # category 없으면 전체
GET /api/news/categories                   # ["IT", "정치", "경제", ...] 반환
```

`NewsItem` 응답에 `category`, `sourceType` 필드 추가.

### 5. 이번 범위에서 제외

- 기사 전문 저장 (RSS에 description까지만 저장, 전문은 convert 요청 시 크롤링)
- 카테고리 자동 분류 AI (RSS 피드 카테고리 값 그대로 사용)
- RSS URL을 DB/설정파일로 외부화

## 영향 범위

- `V2__add_news_category_source_type.sql` 신규
- `NewsArticle` 엔티티 필드 2개 추가
- `NewsController`, `NewsService` 시그니처 변경 (하위호환: category 없으면 전체 반환)
- 스케줄러 실제 동작 시작 → 앱 기동 시 초기 1회 수집 + 이후 매시간
- 구 프로젝트의 `NaverNewsClient`, `naver.*` 설정은 신규 프로젝트에 원래 없으므로 제거 불필요
