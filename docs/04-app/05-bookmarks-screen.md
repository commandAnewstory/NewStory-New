# 05. 보관함 화면

## 목표
보관함 / 히스토리 세그먼트 탭. 두 목록 모두 변환 결과 단위로 표시.

## API 연동

```
GET /api/bookmarks
→ { data: [{ bookmarkId, resultId, style, articleTitle, bookmarkedAt }] }

DELETE /api/bookmarks/{resultId}

GET /api/history
→ { data: [{ resultId, style, articleTitle, createdAt }] }

DELETE /api/history/{resultId}
```

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/bookmarks/bookmarks_provider.dart` | 보관함 + 히스토리 상태, 삭제 |
| `lib/features/bookmarks/bookmarks_screen.dart` | 화면 조립, 세그먼트 전환 |
| `lib/features/bookmarks/widgets/result_list_item.dart` | 공통 목록 아이템 (제목, 스타일 뱃지, 날짜, 삭제) |

## 화면 구조

```
BookmarksScreen
├── 세그먼트 컨트롤 (보관함 | 히스토리)
└── [보관함 탭]
    └── ListView — BookmarkItem (articleTitle, 스타일, bookmarkedAt, 삭제)
└── [히스토리 탭]
    └── ListView — HistoryItem (articleTitle, 스타일, createdAt, 삭제)
```

## 스타일 뱃지 색상

| style | 배경 | 텍스트 | 레이블 |
|-------|------|--------|--------|
| fairy_tale | fairyTaleBg | fairyTaleText | 동화체 |
| novel | novelBg | novelText | 소설체 |
| card | cardBg | cardText | 카드요약 |

## 완료 기준

- `flutter analyze` 통과
- pull-to-refresh
- 스와이프 or 삭제 버튼으로 항목 제거
- 빈 목록 안내 문구 표시
