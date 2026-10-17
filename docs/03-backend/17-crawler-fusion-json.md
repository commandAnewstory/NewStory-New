# 17. 조선일보 본문 크롤링 실패 수정 (Fusion JSON)

## 배경 (2026-10-17 실기기 확인 중 발견)
홈에서 조선일보 기사를 누르면 원문 탭이 흰 화면. 백엔드 로그: `모든 셀렉터 실패, body p 태그 fallback`.
- 조선일보(Arc XP/Fusion)는 본문을 HTML `<p>`가 아니라 페이지 스크립트의 `Fusion.globalContent` JSON에 담음 → 셀렉터·`<p>` fallback 모두 실패 → **빈 문자열을 정상 응답(200)으로** 돌려줌
- 오래된 기사만이 아니라 오늘 기사도 동일 (조선일보 전체)
- 변환(`POST /api/convert`)도 같은 크롤러를 써서 빈 본문으로 AI 호출

## 무엇을 하는가 (사용자 승인: "둘 다")
1. `CrawlingService`: HTML 셀렉터가 다 실패하면 `Fusion.globalContent` JSON의 `content_elements` 중 `type=text` 문단을 순서대로 모음 (문단 안 HTML 태그 제거, 기존 잡음 필터 적용). 그다음에 기존 `body p` fallback
2. 그래도 본문이 비면 빈 문자열 대신 `ArticleContentUnavailableException` (502, "기사 본문을 가져오지 못했어요. 원문 사이트에서 확인해 주세요.")
   - `GET /api/convert/original` → 502 + 안내 문구
   - `POST /api/convert` → AI 호출 전에 502 (캐시 히트는 크롤링을 안 하니 영향 없음)

## 영향 범위
- `domain/crawling/service/CrawlingService.java`, `domain/crawling/exception/ArticleContentUnavailableException.java` (신규)
- 테스트: `crawling/CrawlingServiceExtractTest.java` (네트워크 없이 HTML 구조별 추출), `ConvertFlowTest` (502 매핑)
- 응답 형식 변경 없음. 실패 시 상태코드만 200(빈 본문) → 502

## 완료 기준
- Fusion 형태 페이지에서 text 문단만 순서대로, 태그 제거해서 추출
- 일반 HTML 기사는 기존처럼 셀렉터로 추출
- 본문 없는 페이지 / 깨진 JSON → 빈 문자열 (예외 없이), 크롤러는 502로 실패
- 원문 조회·변환 둘 다 502, 변환은 AI 안 부름
- 실제 조선일보 페이지 2개(9/27, 10/17)로 추출 확인 (테스트 픽스처엔 기사 원문을 넣지 않음 — 저작권)
