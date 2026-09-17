# 서브플랜: RSS 카테고리 정확도 개선

## 목표
현재 모든 언론사 RSS가 `"전체"` 카테고리로 수집됨. 실제 RSS 섹션별 피드 URL 또는 `<category>` 태그를 활용해 정확한 카테고리 할당.

## 현재 상태 조사 결과
- 동아일보: `<category>` 태그 없음. 섹션별 피드 URL 존재
  - `https://rss.donga.com/politics.xml` → 정치
  - `https://rss.donga.com/economy.xml` → 경제
  - `https://rss.donga.com/society.xml` → 사회
  - 등
- Google News: `<category>` 태그 있음 (`<category>정치</category>` 형태)
- 조선일보 RSS: 404 (현재 URL 깨짐, 수정 필요)
- SBS RSS: 404 (현재 URL 깨짐, 수정 필요)
- 중앙일보/MBC: `pubDate` 없음, 추가 조사 필요

## 변경 파일
- `backend/src/main/java/.../news/service/RssNewsCollector.java`
- `backend/src/main/java/.../news/client/RssFeedClient.java`

## 변경 내용
1. **동아일보 RSS**: 현재 단일 피드 → 섹션별 피드 다중 수집으로 교체
   - 정치/경제/사회/IT 등 섹션별 피드 URL 하드코딩
   - 피드 URL 자체로 카테고리 결정 (추정 없음)

2. **Google News**: `<category>` 태그 파싱 추가
   - `RssFeedClient` 에서 `item.getElementsByTag("category").first()` 로 읽음
   - 값 있으면 사용, 없으면 피드 소스에서 지정한 기본 카테고리 사용

3. **조선일보/SBS**: 올바른 RSS URL 조사 후 수정 (또는 제거)
   - 404 나는 소스는 임시 비활성화

4. **RssSource 구조**: `category` 필드를 `String`에서 유지, 피드 수준 카테고리 우선 / `<category>` 태그 오버라이드 지원

## 완료 기준
- 동아일보 정치 섹션 피드 수집 기사 → `category = "정치"` 저장
- Google News `<category>` 태그 있는 기사 → 해당 카테고리 저장
- 404 피드 소스 제거 또는 올바른 URL로 교체
- 홈 카테고리 탭 필터가 실제 분류된 기사 표시

## 영향 범위
- `RssNewsCollector` 소스 목록 및 수집 로직
- `RssFeedClient.parseItem()` 카테고리 파싱 추가
- DB `category` 컬럼 데이터 정확도 향상 (스키마 변경 없음)
