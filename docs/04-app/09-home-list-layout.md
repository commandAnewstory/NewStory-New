# 서브플랜: 홈 화면 뉴스 리스트 레이아웃

## 목표
썸네일 없는 모바일 뉴스 앱 형식으로 홈 화면 레이아웃 변경.

## 변경 파일
- `app/lib/features/home/home_screen.dart`
- `app/lib/features/home/widgets/category_chip_bar.dart`
- `app/lib/features/home/widgets/article_list_tile.dart` (신규)

## 변경 내용

### 레이아웃 변경
- 기존: 히어로 카드(224px 플레이스홀더) + 2열 그리드
- 변경: 단일 `ListView.separated` 플랫 리스트

### 각 뉴스 아이템 (`article_list_tile.dart`)
- 카테고리 배지(색상 칩) + 언론사명 + 시간(n분 전/n시간 전/n일 전)
- 제목 2줄 (w600, 15px)
- description 1줄 (있으면, gray)
- 아이템 사이 얇은 구분선(indent 20)

### 카테고리 칩 바 (`category_chip_bar.dart`)
- height 42 → 34, padding 조정, `alignment: center` → 텍스트 잘림 해결

## 완료 기준
- 홈 화면에서 기사 목록이 썸네일 없는 리스트로 표시
- 카테고리/언론사/시간 정보 정상 표시
- 스크롤 끝 페이지 로드 정상 동작

## 영향 범위
- 홈 탭 화면만 영향
- `HeroCard`, `ArticleGridCard` 위젯은 미사용 상태 (삭제 가능하나 이번 PR 범위 밖)
