# 03. 용어 글로서리 (glossary)

> 마스터 기획서 8장 "개발 순서" 4번. AI가 변환 본문 안에 `{{term:용어|뜻풀이}}` 마커를 심고, 백엔드가 파싱해 순수 텍스트 + 용어 배열을 분리 응답.

## 왜 하는가

마스터 기획서 5장 API 설계:
- `POST /api/convert` 응답에 `glossary` 필드 추가 (용어-뜻풀이 배열)
- 기사 상세 화면에서 본문 내 어려운 용어를 탭하면 뜻풀이 표시
- 오프셋/좌표 계산 없이 서버 파싱으로 처리 (마스터 기획서 5장 glossary 설계 명시)

## 구체적 변경사항

### 1. DB 스키마 (Flyway V4)

`conversion_cache`에 컬럼 추가:

```sql
ALTER TABLE conversion_cache ADD COLUMN glossary JSONB;
```

### 2. AI 프롬프트 수정

`ClaudeApiClient.convert()` 프롬프트에 지시 추가:
- 변환 본문 내 어려운 용어에 `{{term:용어|뜻풀이}}` 형식으로 인라인 마킹
- 한 기사당 3~7개 목표, 중요도 높은 순
- 마커가 없어도 파싱이 실패하지 않도록(graceful) 처리

### 3. 신규 파일

**`domain/convert/dto/GlossaryItem.java`**
```java
public record GlossaryItem(String term, String definition) {}
```

**`global/common/GlossaryParser.java`**
- `{{term:용어|뜻풀이}}` 패턴을 정규식으로 파싱
- 반환: `ParsedContent { String plainText, List<GlossaryItem> glossary }`
- 마커 없는 텍스트 → 빈 glossary 리스트 반환 (예외 없음)

### 4. 변경 파일

**`ConversionCache` 엔티티**
- `glossary` 필드 추가 (`@JdbcTypeCode(SqlTypes.JSON)` — JSONB 매핑)
- 타입: `List<GlossaryItem>` (Jackson 직렬화)

**`ConvertService.convert()`**
- 파이프라인 완료 후 `GlossaryParser.parse(outcome.convertedText)` 호출
- `ConversionCache` 저장 시 `glossary` 포함
- 캐시 히트 시 `cache.getGlossary()` 그대로 사용

**`ConvertResponse`**
- `glossary: List<GlossaryItem>` 필드 추가
- 생성자에서 캐시 또는 신규 파싱 결과를 받아 세팅

### 5. API 변화

`POST /api/convert` 응답 (기존 필드 유지, 추가만):

```json
{
  "id": 1,
  "style": "fairy_tale",
  "convertedText": "옛날에 한 나라가 있었어요...",
  "verificationPassed": true,
  "verificationMethod": "gemma_verified",
  "retryCount": 0,
  "cachedResult": false,
  "glossary": [
    { "term": "물가", "definition": "상품이나 서비스의 평균 가격 수준" }
  ]
}
```

## 영향 범위

- `V4__add_glossary_to_conversion_cache.sql` 신규
- `GlossaryItem` 레코드 신규
- `GlossaryParser` 유틸 신규
- `ConversionCache` 엔티티 수정 (glossary 필드 추가)
- `ClaudeApiClient.convert()` 프롬프트 수정
- `ConvertService.convert()` 수정 (파서 호출 + 캐시에 glossary 저장)
- `ConvertResponse` 수정 (glossary 필드 추가)
- `ConvertedResult` 변경 없음 (glossary는 캐시에만 저장)
