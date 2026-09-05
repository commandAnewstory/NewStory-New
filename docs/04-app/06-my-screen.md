# 06. MY 화면

## 목표
프로필 표시, 용어 난이도 설정, 위젯 온오프, 로그아웃.

## API 연동

```
GET  /api/users/me
→ { data: { id, email, nickname, lastGlossaryLevel, widgetEnabled } }

PATCH /api/users/me
body: { nickname?, widgetEnabled? }
→ { data: { id, email, nickname, lastGlossaryLevel, widgetEnabled } }
```

> 용어 난이도(`lastGlossaryLevel`)는 변환 시 자동 갱신되므로 MY에서는 표시만.

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/my/my_provider.dart` | 유저 정보 로드 + 위젯 토글 |
| `lib/features/my/my_screen.dart` | 화면 조립 |
| `lib/features/my/widgets/setting_row.dart` | 설정 행 공통 위젯 |

## 화면 구조

```
MyScreen
├── 프로필 섹션 (이메일, 닉네임)
├── 설정 섹션
│   ├── 용어 난이도: LOW→쉬움 / MEDIUM→보통 / HIGH→어려움 (표시만, 읽기 전용)
│   └── 홈 위젯: Switch (PATCH /api/users/me widgetEnabled)
└── 로그아웃 버튼 → AuthNotifier.logout() → GoRouter /login redirect
```

## 디자인 규칙

- 섹션 간격: 24px
- 설정 행: 흰 배경 Container, 14px 텍스트
- Switch: `AppColors.primary` 활성 색

## 완료 기준

- `flutter analyze` 통과
- 위젯 토글 시 PATCH 즉시 반영
- 로그아웃 시 SecureStorage 삭제 + /login 이동
