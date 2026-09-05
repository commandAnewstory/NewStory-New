# 03. 직접 변환 화면

## 목표
URL 입력 → 스타일 선택 → 변환 결과 표시. 변환 탭의 핵심 기능.

## API 연동

```
POST /api/convert
body: { url, style, level? }          // url 직접 입력 방식
→ { data: { convertedText, style, cachedResult, glossary, readingTimeLabel } }
```

> 백엔드 `/api/convert`가 `url` 필드도 받는지 확인 필요. articleId 방식만 지원하면 추가 구현 필요.

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/convert/convert_provider.dart` | 변환 상태 (StateNotifier) |
| `lib/features/convert/convert_screen.dart` | 화면 조립 |
| `lib/features/convert/widgets/url_input_field.dart` | URL 입력 + 붙여넣기 버튼 |
| `lib/features/convert/widgets/style_picker.dart` | 스타일 선택 카드 (동화체/소설체/카드요약) |
| `lib/features/convert/widgets/convert_result_view.dart` | 변환 결과 + 용어 보기 버튼 |

## 화면 구조

```
ConvertScreen
├── URL 입력 필드 (붙여넣기 버튼, 유효성 표시)
├── StylePicker (동화체 | 소설체 | 카드요약 카드 선택)
├── 변환하기 버튼 (URL + 스타일 선택 시 활성화)
└── [결과 영역]
    ├── 로딩 스피너
    ├── 에러 + 재시도
    └── ConvertResultView (변환 텍스트, 용어 보기)
```

## 상태 흐름

- 초기: URL 비어있음, 스타일 미선택
- URL 입력 + 스타일 선택 → 변환하기 버튼 활성화
- 변환하기 탭 → POST /api/convert → 로딩
- 성공 → 결과 표시 (기사 상세와 동일한 ConvertedTab / CardSummaryView 재사용)
- 에러 → 메시지 + 재시도

## 디자인 규칙

- URL 입력 필드: 배경 흰색, 12px radius, 테두리 없음
- StylePicker: 3개 카드 수평 배치, 선택 시 스타일 배경색으로 강조
- 변환하기 버튼: `AppColors.primary`, 비활성 시 opacity 0.4
- 결과 영역: 기사 상세와 동일한 ConvertedTab / CardSummaryView 위젯 재사용

## 완료 기준

- `flutter analyze` 통과
- URL 미입력 / 스타일 미선택 시 버튼 비활성
- 붙여넣기 버튼으로 클립보드 URL 자동 입력
- 변환 결과에서 용어 GlossarySheet 표시
