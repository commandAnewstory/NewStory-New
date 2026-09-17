# 서브플랜: RSS 카테고리 정확도 개선

> 이 문서는 사후 갱신됨 — 최초 조사안과 실제 구현이 갈린 부분(Google News 카테고리 처리)을 실구현 기준으로 정정.

## 목표
현재 모든 언론사 RSS가 `"전체"` 카테고리로 수집됨. 실제 RSS 섹션별 피드 URL을 활용해 정확한 카테고리 할당.

## 조사 결과 (최종)
- 조선일보 RSS: 기존 URL 404 → `?outputType=xml` 붙이면 정상 동작 확인
- 동아일보: `<category>` 태그 없음. 섹션별 피드 URL 존재 (정치/경제/사회/문화/스포츠/IT 6개)
- SBS: 기존 `RSS.xml` 404 → `SectionRssFeed.do?sectionId=XX` 형식으로 섹션별 피드 존재 (정치/경제/사회 3개 적용)
- 중앙일보: RSS 서비스 자체가 종료됨 확인 — 소스 제거
- MBC: RSS 폐지(요청 시 에러 페이지로 리다이렉트) 확인 — 소스 제거
- Google News: `<category>` 태그가 있긴 하나, **최종 구현에서는 태그를 파싱하지 않고 검색 쿼리(소스 정의) 기준으로 카테고리를 고정**함 (아래 "실제 구현" 참고)

## 변경 파일
- `backend/src/main/java/.../news/service/RssNewsCollector.java`
- `backend/src/main/java/.../news/client/RssFeedClient.java`

## 실제 구현 내용
1. **동아일보**: 단일 피드(`total.xml`) → 섹션별 피드 6개로 교체. `RssNewsCollector.SOURCES`에 언론사·URL·카테고리를 한 쌍으로 하드코딩 — 피드 URL 자체가 카테고리를 결정 (추정 없음)
2. **조선일보/SBS**: 위에서 확인한 정상 URL로 교체
3. **중앙일보/MBC**: `SOURCES` 목록에서 제거
4. **Google News**: `<category>` 태그 파싱은 구현하지 않음. `SOURCES`에 검색 쿼리별로 카테고리를 고정 지정(`기술+IT` 쿼리 → `"IT"`, `정치` 쿼리 → `"정치"`)하는 방식으로 대체 — 쿼리 자체가 주제를 특정하므로 태그 파싱 없이도 충분하다고 판단
5. **카테고리 값의 출처는 전부 `RssNewsCollector.SOURCES`의 하드코딩 값 하나뿐** — RSS 아이템 자체의 `<category>` 태그를 읽는 코드는 어디에도 없음 (동아일보도 태그가 아니라 URL 기준)
6. 부수 수정: `RssFeedClient.text()` — `content:encoded`처럼 콜론 포함 태그는 `selectFirst()`가 CSS 셀렉터로 오인해서 실패하던 버그 수정 (`getElementsByTag()`로 분기)

## 완료 기준 (달성됨)
- 동아일보 섹션별 피드 수집 기사 → 해당 섹션명이 `category`로 저장됨 (PR #41에서 실 수집 로그로 확인)
- 조선일보 100건, SBS 섹션별 29건 등 실제 수집 확인
- 404 나던 소스 전부 정상 URL로 교체 또는 제거
- 홈 카테고리 탭 필터가 실제 분류된 기사(정치/경제/사회/문화/스포츠/IT) 표시

## 알려진 한계
- Google News 소스는 태그가 아니라 검색 쿼리 기준 고정 카테고리라서, 쿼리 주제와 실제 기사 내용이 어긋나는 극소수 케이스가 있을 수 있음 (예: "정치" 쿼리 결과에 다른 주제 기사가 섞여 들어와도 여전히 `category="정치"`로 저장됨). 현재는 감수하고 넘어간 상태.

## 영향 범위
- `RssNewsCollector` 소스 목록 및 수집 로직
- `RssFeedClient` 콜론 태그 파싱 버그 수정
- DB `category` 컬럼 데이터 정확도 향상 (스키마 변경 없음)
