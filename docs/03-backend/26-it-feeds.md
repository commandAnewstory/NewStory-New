# 26. IT 카테고리 기사 0건 — 죽은 피드 교체

## 원인 (2026-10-19 AWS 서버 확인)
- 서버 IT 기사 0건 (전체 512건)
- IT 소스는 `rss.donga.com/it.xml` + Google News(IT) 두 개였음
- Google News는 #25에서 제거 (본문 크롤링 100% 실패)
- **동아 `it.xml`은 HTTP 200인데 본문 0바이트** — 피드가 죽어 있음 (`digital.xml`도 동일). 다른 동아 섹션 피드(politics/economy/science)는 정상

## 변경
- 동아 `it.xml` → `science.xml`(IT/의학 섹션, 50건)
- 한국경제 IT·과학 피드 `hankyung.com/feed/it` 추가 (50건)
- 두 피드 모두 AWS 서버에서 본문 크롤링 3/3 성공 확인

## 참고
- 같은 기사가 경제 피드로 먼저 들어와 있으면 URL 중복이라 경제로 남음 (IT 전용 기사만 IT로)
- 후보에서 뺀 것: SBS sectionId=08(문화·날씨), 조선 tech_it(404), 매경(403), 전자신문 Section901(전체 기사)
