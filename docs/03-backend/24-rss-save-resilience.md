# 24. RSS 수집 저장 실패 격리 + 긴 URL 건너뛰기

## 문제 (AWS 첫 배포 로그)
`ERROR: index row size 3352 exceeds btree version 4 maximum 2704 for index "news_articles_url_key"`
- URL이 너무 긴 기사 1건 때문에 `news_articles.url` 유니크 인덱스 저장 실패
- `collectAll()`이 전체를 한 트랜잭션으로 묶어서 그 회차 수집이 통째로 롤백 → 기사 0건
- 매시 정각 스케줄러도 같은 피드라 매번 같은 이유로 0건

## 변경
- URL이 UTF-8 기준 2000바이트 넘으면 저장하지 않고 건너뜀 (인덱스 한계 2704)
- 메서드 전체 `@Transactional` 제거 → 기사 1건씩 `save`(건별 트랜잭션), `DataAccessException`은 로그 남기고 건너뜀
- 로그: `신규 N건 저장, M건 건너뜀`
- `backend/gradle/wrapper/gradle-wrapper.jar` 레포에 포함 (`*.jar` 무시 규칙 예외) — 새로 클론하면 `./gradlew`가 안 돌던 문제

## 완료 기준
- 실제 PostgreSQL 통합 테스트: 긴 URL 1건 + 정상 2건 → 2건 저장 / 제목 600자(DB 에러) 1건 + 정상 2건 → 2건 저장 / 재수집 중복 없음
- 기존 코드로 돌리면 위 테스트 2개 실패 확인 (회귀 검증)
