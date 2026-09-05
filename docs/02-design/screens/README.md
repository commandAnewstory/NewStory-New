# 확정 화면 원본 (.dc.html)

클로드코드는 claude.ai 아티팩트 URL을 직접 열어볼 수 없으므로, 확정된 7개 화면의 원본 마크업을 여기 그대로 저장해둔다.
색상/폰트/레이아웃/아이콘(SVG)은 이 파일들이 최종 기준이다. Flutter 위젯 구현 시 픽셀 단위로 똑같이 만들 필요는 없지만, 색상 값·구조·요소 배치는 반드시 이 기준을 따른다.

원본(claude.ai 아티팩트): https://claude.ai/code/artifact/b9110e4a-bad1-4366-b385-d098a71863a2

- Main.dc.html — 홈
- ArticleDetail.dc.html — 기사 상세 (동화체/소설체 공용)
- CardSummary.dc.html — 기사 상세 (카드요약)
- Convert.dc.html — 직접 변환
- Login.dc.html — 로그인
- Archive.dc.html — 보관함
- MySettings.dc.html — MY

**주의**: `Login.dc.html`엔 "회원가입" 텍스트 링크만 있고 실제 회원가입 화면은 디자인되어 있지 않다 (구 스코프에서 논의 안 됨). 회원가입 화면은 로그인 화면과 톤(디자인 토큰)만 맞춰서 클로드코드가 자체적으로 구성하되, 필드 구성이 애매하면 작업 전 확인받을 것.
