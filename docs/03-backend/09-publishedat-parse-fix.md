# 서브플랜: publishedAt 파싱 버그 수정

## 목표
RSS `<pubDate>` 의 `+0900` 오프셋 형식을 `RFC_822` 포맷터가 처리 못해 `now()` fallback 발생하는 버그 수정.

## 원인
`RssFeedClient.parseDate()` 에서 `"EEE, dd MMM yyyy HH:mm:ss z"` 포맷 사용.
- `z` 패턴: 이름형 타임존(`GMT`) 처리 가능, 숫자형 오프셋(`+0900`) 처리 불가
- 동아일보 실제 형식: `"Thu, 17 Sep 2026 09:29:50 +0900"` → 파싱 실패 → `now()` 저장

## 변경 파일
- `backend/src/main/java/.../news/client/RssFeedClient.java`

## 변경 내용
- `parseDate()` 에 다중 포맷 순차 시도 로직 추가
- 시도 순서:
  1. `"EEE, dd MMM yyyy HH:mm:ss Z"` — `Z` 패턴: `+0900` 처리
  2. `"EEE, dd MMM yyyy HH:mm:ss z"` — 기존 포맷 (GMT 처리)
  3. `"EEE, dd MMM yyyy HH:mm:ss X"` — ISO 오프셋 형식
- 모든 포맷 실패 시: `WARN` 로그 출력 + `null` 반환 (호출부에서 `now()` 처리)
- 현재 silent fallback → `null` 반환으로 변경해 호출부에서 명시적 처리

## 완료 기준
- 동아일보 RSS 수집 후 DB `published_at` 이 실제 기사 발행 시각 저장 (수집 시각 아님)
- 파싱 실패 시 WARN 로그 출력됨 확인
- Google News (`GMT` 형식) 기존 정상 동작 유지

## 영향 범위
- `RssFeedClient.parseDate()` 만 변경
- `RssNewsCollector` 는 이미 `null`-safe하게 처리하도록 확인 필요
