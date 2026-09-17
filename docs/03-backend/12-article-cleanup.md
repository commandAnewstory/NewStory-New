# 서브플랜: 오래된 기사 자동 삭제

## 목표
`publishedAt < now() - 1개월` 인 기사를 주기적으로 삭제해 DB 용량 관리.

## FK 연쇄 삭제 경고 ⚠️

삭제 시 연쇄 삭제 발생하는 테이블:
```
news_articles (삭제 대상)
  ↓ article_id FK
  ├── conversion_cache       → 캐시 삭제 (무방)
  ├── article_views          → 조회 기록 삭제 (무방)
  └── converted_results      → 변환 결과 삭제
        ↓ result_id FK
        └── bookmarks        → ★ 사용자 북마크 삭제
```

**사용자 북마크가 같이 삭제된다.** 구현 전 사용자 결정 필요:
- **옵션 A (cascade delete)**: 1개월 이상 기사 + 연관 북마크 전부 삭제. 단순하지만 북마크 데이터 손실.
- **옵션 B (soft delete)**: `news_articles` 에 `deleted_at` 컬럼 추가. 기사는 숨기되 북마크/변환결과 유지. 스키마 변경 + 쿼리 전체에 `deleted_at IS NULL` 조건 추가 필요 — 작업량 큼.
- **옵션 C (기사 삭제, 북마크는 null-safe)**: 삭제 전 `bookmarks.result_id` → `null` 허용으로 스키마 변경 후 고아 북마크 남김. 북마크는 남지만 기사 내용 접근 불가.

**추천: 옵션 A** — 현재 서비스 초기, 북마크 데이터가 중요하지 않은 단계. 단순하고 FK 변경 없음.

## 변경 파일 (옵션 A 기준)
- `backend/src/main/java/.../scheduler/NewsScheduler.java`
- `backend/src/main/java/.../news/service/NewsService.java` (또는 별도 CleanupService)
- `backend/src/main/java/.../news/repository/NewsArticleRepository.java`

## 변경 내용 (옵션 A 기준)
1. `NewsArticleRepository` 에 쿼리 추가:
   ```java
   List<NewsArticle> findByPublishedAtBefore(LocalDateTime cutoff);
   ```

2. `NewsService` 또는 별도 `ArticleCleanupService` 에 삭제 메서드:
   - `cutoff = LocalDateTime.now().minusMonths(1)`
   - 대상 기사 조회
   - 연관 `bookmarks` → `converted_results` → `conversion_cache`, `article_views` 순으로 삭제
   - 마지막에 `news_articles` 삭제
   - 삭제 건수 INFO 로그

3. `NewsScheduler` 에 스케줄 추가:
   - `@Scheduled(cron = "0 0 3 * * *")` — 매일 새벽 3시

## 완료 기준
- 스케줄러 수동 트리거 후 1개월 이상 기사 DB에서 삭제됨
- 연관 북마크/변환결과도 함께 삭제됨 확인
- INFO 로그에 삭제 건수 출력

## 영향 범위
- `NewsScheduler` 크론 추가
- `NewsArticleRepository` 쿼리 추가
- DB 1개월 이상 데이터 영구 삭제 (되돌릴 수 없음)
