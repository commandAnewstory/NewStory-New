# 13. 백엔드 통합 테스트 기반 구축

## 목표
지금 백엔드 테스트는 빈 `placeholder()` 하나뿐이라 무엇을 고쳐도 자동으로 확인할 방법이 없다. 이후 작업(14, 15)이 기댈 수 있는 통합 테스트 기반을 먼저 만든다.

## 무엇을 하는가
1. `src/test/resources/application-test.yml` 추가 — 테스트 전용 PostgreSQL DB(`newstory_test`)에 Flyway 마이그레이션을 그대로 적용해서 실제 스키마로 테스트
2. 테스트 공통 기반 클래스 `IntegrationTestSupport` — `@SpringBootTest` + `MockMvc`, 테스트마다 DB 초기화, 회원가입/로그인으로 JWT 받아오는 헬퍼
3. 외부 호출은 전부 가짜(mock)로 대체 — `GemmaApiClient`, `ClaudeApiClient`, `CrawlingService`, RSS 수집. 실제 AI API·언론사 사이트를 부르지 않음 (API 크레딧 소모 없음, 네트워크 상태와 무관하게 결과가 같음)
4. 핵심 흐름 스모크 테스트 작성
   - 회원가입 → 로그인 → `GET /api/users/me`
   - 로그아웃 후 refresh 토큰 재사용 시 실패
   - `POST /api/convert` 정상 응답 (glossary, readingTimeLabel 포함)
   - 보관함 추가/중복 추가 409/삭제, 히스토리 조회/삭제
   - `GET /api/news?category=` 필터
5. 정리: `SecurityConfig`의 `/api/feed` permitAll 규칙 삭제 (해당 컨트롤러가 없는 죽은 규칙)
6. `placeholder()` 테스트 삭제

## 영향 범위
- `backend/src/test/**` (신규 위주)
- `backend/src/main/java/.../global/config/SecurityConfig.java` (`/api/feed` 한 줄 삭제)
- 운영 코드 동작 변경 없음

## 완료 기준
- `./gradlew test` 전부 통과
- `./gradlew spotlessCheck` 통과
- 테스트가 외부 네트워크(Claude/Gemma/언론사) 없이 돌아감
