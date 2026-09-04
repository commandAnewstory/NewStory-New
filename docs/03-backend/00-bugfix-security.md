# 00. 백엔드 프로젝트 초기 세팅 + 알려진 버그/보안 이슈 선반영

> 마스터 기획서 8장 "개발 순서" 1번. 이 프로젝트는 구 폴더 코드를 옮기는 게 아니라 `~/Desktop/NewStory`에 새로 작성하므로, "버그 수정"이 아니라 **구 코드에서 발견된 문제를 애초에 만들지 않도록 올바르게 구현**하는 작업이다.

## 무엇을 하는가

1. **백엔드 프로젝트 스캐폴딩**
   - 위치: `~/Desktop/NewStory/backend/`
   - Java 21, Spring Boot 3.x, Gradle(Groovy DSL) 기준으로 신규 생성
   - 구 코드(`~/Desktop/프로젝트/newspace/newstory/apps/backend/newstorybackend`)의 `build.gradle` 의존성 구성을 참고해 그대로 가져옴 (JPA, Web, Security, Flyway+PostgreSQL, JWT(jjwt), Jsoup 크롤링, Lombok, Validation)
   - 패키지 루트: `com.newstory.newstorybackend` 유지, 도메인 구조(`domain/{auth,user,news,convert,history,bookmark,crawling,ai,scheduler}`)도 동일하게 유지 — 검증된 설계라 굳이 바꿀 이유 없음
   - `.env` 연동: 루트 `~/Desktop/NewStory/.env`를 백엔드가 읽도록 설정 (Spring이 기본으로 보는 `application.yml`이 아니라 `.env` 파일 → 환경변수로 로드하는 방식. `spring-dotenv` 또는 실행 스크립트에서 `export $(cat .env)` 방식 중 택 1, 개발 편의상 `spring-dotenv` 라이브러리 추가 권장)

2. **버그 선반영 — `ConvertService.verificationPassed` 로직**
   - 구 코드 문제: Gemma 검증에 실제로 실패해서 Claude로 폴백한 경우도, 애초에 Gemma가 한 번에 통과한 경우도 결과 저장 시 무조건 `.verificationPassed(true)`로 하드코딩되어 있었음 (`ConvertService.java` 88~98번째 줄 부근). Gemma 예외로 Claude 폴백한 경우도 검증 자체를 안 했는데 `true`로 저장됨.
   - 새 구현 방침:
     - `verificationPassed` 필드는 **실제로 Claude 검증(`verify()`)을 통과한 경우에만 `true`**
     - Gemma 예외로 Claude 변환으로 폴백한 경우 → `verificationPassed = false`, `verificationMethod` 같은 필드를 추가해 `gemma_verified` / `claude_fallback_unverified` 등으로 구분 (프론트/운영에서 "이건 검증 없이 나간 결과다"를 구분할 수 있어야 함)
     - `MAX_RETRY`(3회) 다 소진하고도 검증 실패 → Claude로 최종 폴백하되 이것도 `verificationPassed = false`로 저장 (검증을 통과한 게 아니라 그냥 마지막 수단으로 내보낸 것이므로)
     - 엔티티 `ConvertedResult`에 `verificationMethod VARCHAR(30)` 컬럼 추가 (`gemma_verified` | `claude_fallback` 값)

3. **보안 선반영 — 디버그 엔드포인트 프로덕션 노출 차단**
   - 구 코드 문제: `SecurityConfig`에서 `/api/test/**`가 `permitAll()`로 열려 있었고, `NewsDebugController`/`GemmaTestController` 등이 인증 없이 프로덕션에서도 호출 가능한 상태였음
   - 새 구현 방침:
     - 디버그/테스트 성격 컨트롤러는 `@Profile("local")` 또는 `@Profile("dev")`로 묶어서 프로덕션 프로파일에서는 빈 자체가 생성되지 않도록 함 (permitAll 여부와 무관하게 원천 차단)
     - `SecurityConfig`에는 `/api/test/**` 룰 자체를 두지 않음 (더 이상 프로덕션 코드 경로에 존재하지 않으므로)
     - `/api/news/popular`, `/api/news/*/view`, `/api/feed`는 기존처럼 `permitAll` 유지 (의도된 공개 엔드포인트, 마스터 기획서 5장에 이미 반영됨)

4. **application 설정 분리**
   - `application.yml` (공통) + `application-local.yml` (로컬 개발, 디버그 컨트롤러 활성화) + `application-prod.yml` (배포용) 구조로 분리
   - 기본 활성 프로파일은 `local`로 두고, 배포 시에만 `prod` 지정

## 영향 범위
- 신규 파일: 백엔드 프로젝트 전체 스캐폴딩 (`~/Desktop/NewStory/backend/` 하위)
- 구 폴더는 읽기 참고만, 수정 없음
- 이 작업 이후 DB는 아직 안 만들거나 로컬 PostgreSQL 필요 (Flyway 초기 마이그레이션은 이 작업에서 최소 스키마만 — `users`, `news_articles`, `converted_results` 세 테이블. `conversion_cache`, 소셜 로그인 컬럼 등은 각 해당 하위 기획서(02, 04)에서 추가)

## 확인 필요 사항
- 위 방침대로 진행해도 되는지
- 백엔드 프로젝트 폴더명 `~/Desktop/NewStory/backend/` 로 할지, 다른 이름 원하는지
