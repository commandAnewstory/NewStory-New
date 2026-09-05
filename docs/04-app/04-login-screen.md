# 04. 로그인 화면

## 목표
카카오 / 구글 소셜 로그인 구현. JWT 발급 후 AuthNotifier에 저장 → 홈으로 이동.

## API 연동

```
POST /api/auth/social/{provider}   (provider: kakao | google)
body: { token: "<소셜 SDK 토큰>" }
→ { data: { accessToken, refreshToken } }
```

## SDK 흐름

| 소셜 | SDK | 얻는 값 | 백엔드 전달 |
|------|-----|--------|------------|
| 카카오 | `kakao_flutter_sdk_user` | `UserApi.instance.loginWithKakaoAccount()` → OAuthToken.accessToken | token |
| 구글 | `google_sign_in` | `GoogleSignIn().signIn()` → GoogleSignInAuthentication.idToken | token |

## 구현 파일

| 파일 | 내용 |
|------|------|
| `lib/features/auth/login_provider.dart` | 소셜 로그인 상태 (StateNotifier) |
| `lib/features/auth/login_screen.dart` | 화면 조립 |
| `lib/features/auth/widgets/social_login_button.dart` | 카카오/구글 버튼 공통 위젯 |

## 화면 구조

```
LoginScreen
├── 앱 로고 + 슬로건 (중앙)
├── SocialLoginButton (카카오) — 노란 배경, 카카오 아이콘
└── SocialLoginButton (구글) — 흰 배경, 구글 아이콘
```

## 디자인 규칙

- 배경: `AppColors.background`
- 카카오 버튼: `#FEE500` 배경, 검정 텍스트
- 구글 버튼: 흰 배경, `AppColors.ink` 텍스트, 1px 테두리 `#D1D1D6`
- 버튼 높이 52px, 12px radius
- 로고 타이포: `AppTextStyles.display(32)` "NewStory"
- 슬로건: "뉴스를 거부감 없이, 재밌고 가볍게" (16sp, ink)

## 완료 기준

- `flutter analyze` 통과
- 카카오/구글 로그인 성공 → `AuthNotifier.login()` → GoRouter가 `/home`으로 redirect
- 에러 시 SnackBar 표시
- 로딩 중 버튼 비활성화
