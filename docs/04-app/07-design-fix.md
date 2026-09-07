# 07-design-fix — UI 디자인 기준 맞추기

**브랜치**: `app/07-design-fix` (dev에서 분기)  
**이슈 라벨**: `area:app`, `type:refactor`

---

## 목표

`docs/02-design/screens/*.dc.html` 기준으로 전체 화면 UI를 맞춘다.  
기능 로직(API 호출, 상태관리, 라우팅, provider)은 건드리지 않음.

---

## 화면별 차이 목록 및 수정 계획

### 공통 — Bottom Nav Bar
| 현재 | 디자인 기준 |
|------|------------|
| Material Icons (Icons.home_outlined 등) | 커스텀 SVG 아이콘 (디자인과 동일한 path) |
| BottomNavigationBar 기본 스타일 | 66px 고정, bg #fff, border-top #ECEAE4, label 10px |
| 탭 라벨 아래 배치 | 아이콘 + 라벨 column, gap 3px |

→ `_ScaffoldWithNavBar`에서 BottomNavigationBar → 커스텀 SVG 위젯으로 교체

---

### 홈 화면 (Main.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| System AppBar, w800 폰트 | 커스텀 헤더: "NewStory" Do Hyeon 21px + 돋보기·벨 SVG 아이콘 (색 #6B6E76) |
| 검색/알림 아이콘 없음 | 우측에 search + bell SVG |
| CategoryChipBar: Material ChoiceChip | pill 형태 (br 18px), 선택=bg#3654F4·흰글씨, 미선택=bg#fff·border#E7E4DE |
| HeroCard: 흰 카드 + 텍스트 구조 | 224px 이미지 플레이스홀더 + 하단 그라디언트 오버레이 + 카테고리 뱃지 + 제목 스켈레톤 + 스타일 뱃지(동화체/소설체/카드요약) |
| "최신 뉴스" 섹션헤더 없음 | HeroCard 아래에 "최신 뉴스" (Do Hyeon 16px) + "더보기" (12px #9A9CA3) 행 추가 |
| ArticleGridCard: 텍스트만 | 104px 이미지 영역(placholder) + 카테고리 컬러 뱃지 top-left + 제목 2줄 |

---

### 로그인 화면 (Login.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| "NewStory" 텍스트 로고 | 52×52 #3654F4 rounded(16px) 아이콘 안에 "NS" Do Hyeon 흰색 |
| 타이틀: "뉴스를 거부감 없이, 재밌고 가볍게" | "뉴스를 가볍게,\n재밌게 볼 시간" Do Hyeon 26px |
| 소셜 버튼만 있음 | OR 구분선 ("또는 이메일로 계속하기") 추가 |
| 이메일/비밀번호 필드 없음 | height 48px, br 12px, border #ECEAE4, placeholder 13px #9CA0A8 |
| 로그인 버튼 없음 | height 52px, bg #17181C, br 14px, "로그인" 흰글씨 |
| 회원가입 링크 없음 | 하단 "아직 계정이 없으신가요?" + "회원가입" (#3654F4 bold) |
| 카카오 버튼 텍스트: "카카오로 시작하기" (맞음) | 높이 52px, br 14px 확인·수정 |
| 구글 버튼 텍스트: "구글로 시작하기" | "Google로 시작하기" |

추가: 이메일 로그인 기능 연결 (`POST /api/auth/login`)

---

### 회원가입 화면 (신규 생성)
디자인 없음 → 로그인과 동일 토큰 사용. 백엔드 필드: email, password(min8), nickname.

레이아웃:
- 로고(52×52) + "계정 만들기" Do Hyeon 26px
- 닉네임, 이메일, 비밀번호(min8자 안내), 비밀번호 확인 입력 필드 (48px, 동일 스타일)
- "가입하기" 버튼 (#3654F4 bg, 52px, Do Hyeon)
- 하단 "이미 계정이 있으신가요?" + "로그인" 링크

라우팅: `/signup` 추가, 로그인 화면 "회원가입" 탭에서 push

---

### 기사 상세 (ArticleDetail.dc.html + CardSummary.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| AppBar with title text | AppBar 제거, 커스텀 헤더: 좌측 back chevron + 우측 share·bookmark SVG |
| StyleSegment: iOS pill 세그먼트 | pill 탭 (원문/동화체/소설체/카드요약), 선택=bg#3654F4·Do Hyeon, 미선택=border#ECEAE4 |
| _OriginalConvertedToggle 별도 행 | 제거: "원문"을 탭 안으로 통합 |
| 출처/시간 표시 없음 | "연합뉴스 · N분 전" 스타일 메타 (11px #9A9CA3), 탭 아래 |
| 하단 액션바 없음 | "보관함에 저장" (#3654F4 btn, flex 1) + 공유 버튼 (50×50, border) fixed bottom |
| CardSummary: bullet + circle icon | 번호 뱃지 (26×26, br 8px, bg #D7F3EE, 숫자 #0B6E64) + 텍스트 행 |
| CardSummary 저장 버튼 색: #3654F4 | 카드요약 저장 버튼 = #14B8A6 (teal) |

---

### 직접 변환 (Convert.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| System AppBar | AppBar 제거, 상단 인라인 헤더: "직접 변환" Do Hyeon 21px + 서브타이틀 |
| URL input: 아이콘 없음 (확인 필요) | link SVG 아이콘 내장, bg #fff, border #E7E4DE 1.6px, br 14px |
| 지원 언론사 없음 | "지원 언론사" 레이블 + 칩 리스트 (네이버뉴스, 조선일보, 중앙일보, 동아일보, SBS, MBC) |
| StylePicker: 3칼럼 가로 배치 | 세로 카드 리스트, 각 항목: 아이콘(42×42 컬러bg) + 제목/설명 + 라디오 |
| CTA: "변환하기" 일반 버튼 | "변환 시작하기" Do Hyeon 15px, bg #3654F4, 52px, br 14px |
| 면책 문구 없음 | "유튜브·SNS·페이월 기사는 지원하지 않아요" 11px #9CA0A8 하단 |
| 결과가 화면 내 inline | 변환 완료 시 article detail 화면으로 push (기존 로직 유지) |

---

### 보관함 (Archive.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| System AppBar | 인라인 헤더 "보관함" Do Hyeon 21px |
| _SegmentControl: iOS pill | flat 2탭: 선택=bg#17181C·white·br12, 미선택=text only #9A9CA3 |
| ResultListItem: 1칼럼 리스트 | 2칼럼 그리드, 카드 구조: 88px 이미지 영역+컬러 태그+제목 스켈레톤+날짜 |
| 컬러 카테고리 태그 없음 | 변환 스타일 태그 (동화체=FDECC8/#8A5A0F, 소설체=E6DEFA/#5A3A9E, 카드요약=D7F3EE/#0B6E64) |

---

### MY (MySettings.dc.html)
| 현재 | 디자인 기준 |
|------|------------|
| System AppBar | 인라인 헤더 "MY" Do Hyeon 21px |
| 섹션헤더 + SettingRow 구조 | 프로필 카드 (avatar circle+이름+이메일+chevron) 전체 카드 1개 |
| 위젯 프로모 카드 없음 | 파란 테두리 카드 (아이콘 + "오늘의 카드요약 위젯" + 설명 + 토글) 추가 |
| 메뉴 항목 다름 | 계정정보/알림설정/언어/문의하기/이용약관 + 로그아웃(red text) 단일 리스트 |
| 로그아웃 별도 OutlinedButton | 메뉴 리스트 마지막 항목에 red text로 포함 |

---

## 구현 파일 목록

```
app/lib/
  core/router/app_router.dart          # /signup 라우트 추가
  features/auth/
    login_screen.dart                  # 전면 재작성 (이메일 로그인 포함)
    login_provider.dart                # 이메일 로그인 메서드 추가
    signup_screen.dart                 # 신규 생성
    signup_provider.dart               # 신규 생성
  features/home/
    home_screen.dart                   # 커스텀 헤더, 섹션헤더
    widgets/category_chip_bar.dart     # pill 스타일 재작성
    widgets/hero_card.dart             # 이미지 플레이스홀더 + 오버레이
    widgets/article_grid_card.dart     # 이미지 플레이스홀더 + 컬러 뱃지
  features/article/
    article_detail_screen.dart         # 커스텀 헤더, 탭, 하단 액션바
    widgets/style_segment.dart         # pill 탭 재작성 (원문 포함)
    widgets/card_summary_view.dart     # 번호 뱃지 구조
  features/convert/
    convert_screen.dart               # AppBar 제거, 인라인 헤더, 지원언론사, 면책문구
    widgets/style_picker.dart          # 세로 카드 리스트
    widgets/url_input_field.dart       # link SVG 아이콘 추가 (확인 후)
  features/bookmarks/
    bookmarks_screen.dart              # 인라인 헤더, flat 탭, 2칼럼 그리드
    widgets/result_list_item.dart      # 카드형으로 재작성
  features/my/
    my_screen.dart                     # 인라인 헤더, 프로필 카드, 위젯 카드, 메뉴 리스트
  core/router/app_router.dart          # 하단 내비 SVG 교체, /signup 라우트
```

---

## 완료 기준

- 7개 화면 모두 디자인 HTML과 색상/레이아웃/아이콘 일치
- 회원가입 화면 신규 동작 (이메일+비밀번호+닉네임, POST /api/auth/signup)
- 이메일 로그인 동작 (POST /api/auth/login)
- 기존 소셜 로그인, 기사 조회, 변환, 보관함, MY 기능 이상 없음
- 빌드 통과 (`flutter build apk --debug`)
