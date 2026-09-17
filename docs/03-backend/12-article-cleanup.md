# 서브플랜: 오래된 기사 자동 삭제

> 이 문서는 사후 갱신됨 — 최초안(옵션 A: 북마크까지 cascade 삭제)은 반려되고, 최종적으로 "옵션 B(북마크 걸린 기사는 삭제 대상에서 제외)"로 구현됨. 아래는 실구현 기준.

## 목표
`publishedAt < now() - 1개월` 인 기사를 주기적으로 삭제해 DB 용량 관리. 단, **사용자가 북마크한 기사는 아무리 오래돼도 삭제하지 않는다** — 보관함은 "저장해서 나중에 본다"는 기능이므로 원본 기사가 오래됐다는 이유로 사용자가 저장한 걸 지우면 기능 취지와 어긋남.

## FK 연쇄 삭제 구조

```
news_articles (삭제 대상 후보)
  ↓ article_id FK
  ├── conversion_cache       → 삭제 (문제없음, 순수 캐시)
  ├── article_views          → 삭제 (문제없음, 조회 기록)
  └── converted_results      → 삭제
        ↓ result_id FK
        └── bookmarks        → 이 기사를 참조하는 북마크가 있으면 삭제 대상에서 통째로 제외
```

## 채택한 방식 (옵션 B)

최초 검토 시 옵션 A(cascade로 북마크까지 삭제)/B(soft delete)/C(북마크 null-safe)를 놓고 봤으나, 최종적으로는 **네 번째 방식** — "삭제 대상 조회 단계에서 북마크가 걸린 기사를 아예 후보군에서 빼는" 방식으로 구현. 스키마 변경 없이(옵션 B의 `deleted_at` 컬럼 불필요) 북마크 데이터도 100% 보존됨.

- `NewsArticleRepository.findDeletableArticleIds(cutoff)`: `publishedAt < cutoff` AND 해당 기사를 참조하는 `Bookmark`가 하나도 없는(`NOT EXISTS`) 기사 ID만 조회
- 이 ID 목록에 대해서만 `article_views` → `conversion_cache` → `converted_results` → `news_articles` 순서로 삭제
- 북마크가 걸린 기사(및 그 기사의 `converted_results`, 연관 `bookmarks`)는 1개월이 지나도 영구 보존됨

## 변경 파일 (실제)
- `backend/src/main/java/.../domain/scheduler/NewsScheduler.java`
- `backend/src/main/java/.../domain/news/service/ArticleCleanupService.java` (신규)
- `backend/src/main/java/.../domain/news/repository/NewsArticleRepository.java`
- `backend/src/main/java/.../domain/news/repository/ArticleViewRepository.java`
- `backend/src/main/java/.../domain/convert/repository/ConversionCacheRepository.java`
- `backend/src/main/java/.../domain/convert/repository/ConvertedResultRepository.java`
- `backend/src/main/java/.../domain/news/controller/NewsDebugController.java` (수동 트리거 `POST /api/debug/news/cleanup`, local 전용)

## 완료 기준 (달성됨, PR #42 기준)
- 1차 실행: 137건 삭제. 북마크 걸린 81번 기사(발행 7/24, 1개월 초과)는 삭제 대상에서 제외되어 보존됨 확인
- 81번 기사의 북마크 해제 후 재실행 → 그제서야 삭제됨(`{"data":1}`) 확인
- 최종 재실행 시 삭제 대상 0건으로 수렴 확인
- 삭제 건수 INFO 로그 출력
- 매일 새벽 3시 `@Scheduled(cron = "0 0 3 * * *")` 자동 실행

## 영향 범위
- `NewsScheduler` 크론 추가
- 북마크 없는 1개월 이상 기사만 영구 삭제 (되돌릴 수 없음)
- 북마크 걸린 기사는 삭제 로직 대상에서 항상 제외됨 — DB 무한 누적 방지와 사용자 저장 데이터 보존을 동시에 만족
