# 02. 기사 상세 화면

## 목표
기사 상세 화면 구현. 동화체/소설체 + 카드요약 스타일별 뷰 + 용어 설명 탭.

## API 연동

```
GET /api/articles/{id}
→ { data: { id, title, category, publishedAt, originalContent, ... } }

POST /api/convert
body: { articleId, style, level? }
→ { data: { convertedText, style, cachedResult, glossary: [{term, definition}], readingTimeLabel } }
```

## 라우팅

홈 카드 탭 → `/article/:id` push

```dart
GoRoute(path: '/article/:id', builder: ...)  // HomeScreen 하위
```

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/article/article_detail_screen.dart` | 화면 진입점, 스타일 세그먼트 컨트롤 |
| `lib/features/article/article_detail_provider.dart` | 변환 요청 상태 (AsyncNotifier) |
| `lib/features/article/widgets/style_segment.dart` | 동화체/소설체/카드요약 세그먼트 컨트롤 |
| `lib/features/article/widgets/original_tab.dart` | 원문 텍스트 뷰 |
| `lib/features/article/widgets/converted_tab.dart` | 변환 텍스트 뷰 (동화체/소설체) |
| `lib/features/article/widgets/card_summary_view.dart` | 카드 요약 뷰 + 30초 컷 배지 |
| `lib/features/article/widgets/glossary_sheet.dart` | 용어 설명 BottomSheet |

## 화면 구조

```
ArticleDetailScreen
├── AppBar (기사 제목, 공유 버튼)
├── StyleSegment (동화체 | 소설체 | 카드요약)
├── [동화체/소설체 선택 시]
│   ├── SegmentedControl (원문 | 변환)
│   ├── OriginalTab or ConvertedTab
│   └── 용어 보기 버튼 → GlossarySheet (BottomSheet)
└── [카드요약 선택 시]
    └── CardSummaryView (readingTimeLabel + bullet 요약)
```

## 변환 상태 머신

- 초기: 원문만 표시
- 스타일 선택 시 → POST /api/convert 호출 → 로딩 스피너
- 성공 → 변환 텍스트 표시, glossary 있으면 "용어 보기" 버튼 활성화
- 에러 → 재시도 버튼
- 스타일 결과 캐시: 같은 스타일 재선택 시 API 재호출 없음

## 디자인 규칙

- 원문/변환 세그먼트: `CupertinoSlidingSegmentedControl` 스타일
- 동화체: `fairyTaleBg` 배경, `fairyTaleText` 텍스트
- 소설체: `novelBg` 배경, `novelText` 텍스트
- 카드요약: `cardBg` 배경, `cardText` 텍스트, 30초 컷 배지 상단
- 본문 폰트 18sp, 행간 1.7

## 완료 기준

- `flutter analyze` 통과
- 스타일 전환 시 변환 결과 로컬 캐시 (재선택 → API 재호출 없음)
- 용어 GlossarySheet term/definition 표시
- `/article/:id` 라우트 등록 및 홈 카드에서 진입 가능
