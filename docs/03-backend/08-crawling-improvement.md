# 서브플랜: 크롤링 품질 개선

## 목표
마스터 기획서 크롤링 항목(INFO-03) 대응. 기사 본문 외 광고/공유버튼/관련기사 노이즈 제거 및 실패 케이스 감소.

## 변경 파일
- `backend/src/main/java/.../crawling/service/CrawlingService.java`

## 변경 내용
- **User-Agent 설정**: 모바일 Safari로 위장 → 언론사 봇 차단 우회
- **셀렉터 전략 변경**: 단일 `selectFirst()` → 우선순위 순서로 후보 순회, 첫 번째로 충분한 콘텐츠(`p` 태그 합계 150자 이상) 있는 것 선택
- **셀렉터 목록 확장**: `.reporter_body`(동아일보), `.newsct_article`(네이버뉴스), `.view_body` 등 추가
- **노이즈 DOM 제거**: `script, style, figure, iframe, .ad, .sns, .share, .related, [class*='comment']` 등
- **텍스트 노이즈 필터**: `ⓒ`, `무단전재`, `공유하기`, `구독하기`, `googletag` 등 포함 줄 제거
- **p 태그 없는 사이트 대응**: 요소 전체 텍스트를 한국어 문장 종결 패턴으로 쪼개 단락 재구성
- **타임아웃**: 10s → 20s

## 완료 기준
- 동아일보 기사 크롤링 시 실제 본문만 반환 (노이즈 없음)
- 기사 내용 없이 광고문구/공유버튼 텍스트만 반환되는 경우 없음

## 영향 범위
- `CrawlingService.crawl()` 변경 — `GET /api/convert/original`, `POST /api/convert` 모두 영향
- 외부 의존성 변경 없음
