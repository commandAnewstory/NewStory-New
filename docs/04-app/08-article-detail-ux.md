# 서브플랜: 기사 상세 UX 개선

## 목표
기사 상세 화면 실기기 테스트 중 발견된 UX 버그/미구현 항목 수정.

## 변경 파일
- `app/lib/features/article/article_detail_screen.dart`
- `app/lib/features/article/article_detail_provider.dart`
- `app/lib/features/article/widgets/converted_tab.dart`
- `app/lib/features/article/widgets/original_tab.dart`
- `app/lib/features/article/widgets/style_segment.dart`
- `app/lib/core/api/dio_client.dart`

## 변경 내용

### 1. 원문 로딩 상태 개선 (`article_detail_provider.dart`, `article_detail_screen.dart`)
- `ArticleDetailState`에 `originalError` 필드 추가
- 원문 크롤링 실패 시 에러 메시지 + 재시도 버튼 표시
- `_loadArticle()` 완료 즉시 `loadOriginal()` 호출 (기존: postFrameCallback 타이밍 레이스로 url null 상태에서 리턴 후 재호출 안 됨)
- 원문 없을 때 흰화면 대신 스피너 표시

### 2. 스타일 세그먼트 칩 높이 수정 (`style_segment.dart`)
- height 40 → 34, 수직 padding 제거, `alignment: center` 적용 → 텍스트 아래 잘림 해결

### 3. 변환 본문 용어 하이라이트 (`converted_tab.dart`)
- plain `Text` → `RichText` + `TextSpan`
- glossary 용어 위치 regex 매칭 → 파란 밑줄 + `TapGestureRecognizer`
- 탭 시 개별 term/definition 다이얼로그 팝업

### 4. 원문 단락 렌더링 (`original_tab.dart`)
- `\n\n` 기준 단락 분리 → 단락 사이 18px 여백
- 행간 1.75, letterSpacing -0.2

### 5. 변환 타임아웃 수정 (`dio_client.dart`)
- `receiveTimeout` 30s → 120s (novel 변환 최대 52s 소요 → 기존 timeout으로 간헐적 실패)

## 완료 기준
- 기사 열면 스피너 → 원문 로드됨 (흰화면 없음)
- 크롤링 실패 시 에러 메시지 + 재시도 버튼 노출
- 변환 본문에서 용어 파란 밑줄, 탭 시 정의 팝업
- 원문 단락 구분 가독성 개선
- novel 변환 50s+ 케이스 timeout 없이 완료

## 영향 범위
- 기사 상세 화면 전체
- Dio timeout은 전체 API 요청에 영향 (보관함/MY 등)
