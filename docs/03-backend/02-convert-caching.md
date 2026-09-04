# 02. 변환 캐싱 (conversion_cache)

> 마스터 기획서 8장 "개발 순서" 3번. 동일 기사+스타일 조합에 대해 AI 재호출 없이 캐시 결과 반환.

## 왜 하는가

마스터 기획서 6장 DB 스키마: 캐시(`conversion_cache`)와 히스토리(`converted_results`)는 의미가 다름.
- `conversion_cache`: 기사+스타일 단위 전역 공유 캐시 (AI 비용 절감)
- `converted_results`: 사용자별 요청 기록 (히스토리/보관함 기준)

`POST /api/convert` 흐름: **캐시 확인 → 있으면 AI 호출 없이 `converted_results`만 생성 → 없으면 파이프라인 실행 후 둘 다 저장**

## 구체적 변경사항

### 1. DB 스키마 (Flyway V3)

신규 테이블:

```sql
CREATE TABLE conversion_cache (
    id                  BIGSERIAL PRIMARY KEY,
    article_id          BIGINT       NOT NULL REFERENCES news_articles(id),
    style               VARCHAR(20)  NOT NULL,
    converted_text      TEXT         NOT NULL,
    verification_passed BOOLEAN      NOT NULL DEFAULT FALSE,
    verification_method VARCHAR(30),
    retry_count         INTEGER      NOT NULL DEFAULT 0,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (article_id, style)
);
```

### 2. 신규/변경 파일

**신규:**
- `domain/convert/entity/ConversionCache.java`
- `domain/convert/repository/ConversionCacheRepository.java` — `findByArticleIdAndStyle()`, `existsByArticleIdAndStyle()`

**변경:**
- `domain/convert/service/ConvertService.java`
  - `convert()` 메서드에 캐시 조회 로직 추가
  - 캐시 히트: `ConversionCache` 조회 → `ConvertedResult` 생성(AI 호출 없음) → 반환
  - 캐시 미스: 기존 파이프라인 실행 → `ConversionCache` + `ConvertedResult` 둘 다 저장
  - `runConversionPipeline()` 반환값(`ConversionOutcome`)을 캐시 저장에도 재사용

### 3. API 변화

- `POST /api/convert` 응답에 `cachedResult: true/false` 필드 추가 (캐시 히트 여부 프론트에 알림)
- 그 외 응답 구조 동일

## 영향 범위

- `V3__create_conversion_cache.sql` 신규
- `ConversionCache` 엔티티 신규
- `ConvertService.convert()` 수정 (캐시 로직 추가)
- `ConvertResponse` 수정 (`cachedResult` 필드 추가)
- 나머지 코드 변경 없음
