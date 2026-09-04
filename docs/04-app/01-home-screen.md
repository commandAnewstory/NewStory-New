# 01. 홈 화면

## 목표
홈 탭 뉴스 카드 피드 구현. RSS 카테고리 칩 필터 + 히어로 카드 + 2단 그리드.

## API 연동

```
GET /api/articles?page=0&size=20&category={category}
→ { data: { content: [...], totalPages } }
```

Article 필드: `id, title, summary, category, publishedAt, thumbnailUrl`

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/home/article.dart` | Article 모델 (fromJson) |
| `lib/features/home/article_repository.dart` | Dio 호출 + Provider |
| `lib/features/home/home_provider.dart` | StateNotifier: 카테고리/페이지/리스트 상태 |
| `lib/features/home/home_screen.dart` | 화면 조립 |
| `lib/features/home/widgets/category_chip_bar.dart` | 카테고리 수평 스크롤 칩 |
| `lib/features/home/widgets/hero_card.dart` | 첫 번째 기사 히어로 카드 |
| `lib/features/home/widgets/article_grid_card.dart` | 2단 그리드 카드 |
| `lib/features/home/widgets/thirty_sec_badge.dart` | "30초 컷" 배지 |

## 화면 구조

```
HomeScreen
├── CategoryChipBar (수평 스크롤, 전체/정치/경제/사회/문화/IT)
├── HeroCard (첫 기사, 전체 너비, 썸네일+제목+30초컷 배지)
└── GridView.builder (2열, ArticleGridCard)
    └── ArticleGridCard (썸네일, 제목, 카테고리, 시간)
```

## 카테고리 목록

`전체, 정치, 경제, 사회, 문화, IT`

## 디자인 규칙

- 배경: `AppColors.background`
- HeroCard: 16px margin, 12px radius, 섀도우 없음
- GridCard: 8px gap, aspect ratio 3:4
- 30초 컷 배지: `AppColors.cardBg` + `AppColors.cardText`, 카드 요약 있는 기사만 표시
- 카테고리 칩: selected → `AppColors.primary` + white text

## 완료 기준

- `flutter analyze` 통과
- 카테고리 선택 시 리스트 필터링
- 스크롤 끝 도달 시 다음 페이지 로드 (페이지네이션)
- 카드 탭 → 기사 상세 route push (상세 화면은 다음 태스크)
