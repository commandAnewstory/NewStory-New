# 21. 홈 기사 설명에 `<img src=...>` HTML이 그대로 보이는 문제

## 배경 (2026-10-18, 실기기 캡처 `docs/04-app/screens/2026-09-25-10.jpeg`에서 확인)
홈 목록 기사 아래 설명 줄에 `<img src='https://dimg.donga.com/...` 같은 HTML이 글자 그대로 나옴. 동아일보 RSS의 `description`이 CDATA 안에 HTML(이미지 태그 + 본문 요약)을 담아 오는데, 수집할 때 그대로 저장하고 그대로 응답함.

## 무엇을 하는가
- `HtmlText.plain()` (신규, `global/common`): HTML 태그 제거 → 순수 텍스트, 이스케이프된 HTML(`&lt;img&gt;`)도 한 번 더 벗김, 연속 공백 정리
- 수집 시(`RssFeedClient`) 설명을 정리해서 저장
- 응답 시(`NewsItem`)에도 정리 — 이미 HTML 그대로 저장된 예전 기사도 바로 고쳐짐 (DB 마이그레이션 없음)

## 영향 범위
- `global/common/HtmlText.java`(신규), `RssFeedClient`, `NewsItem`, `NewsQueryTest`

## 완료 기준
- HTML·이스케이프 HTML 섞인 설명 → 텍스트만, 기존 테스트 통과
