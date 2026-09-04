# 04. 소셜 로그인 (카카오 / 구글)

> 마스터 기획서 8장 "개발 순서" 5번. 카카오·구글 OAuth 토큰을 받아 자동 계정 생성 + JWT 발급. 기존 이메일 로그인과 동일한 LoginResponse 반환.

## 왜 하는가

마스터 기획서 5장 엔드포인트:
- `POST /api/auth/social/{provider}` — `provider` = `kakao` | `google`
- body: `{ "token": "..." }` (클라이언트가 각 SDK로 발급받은 access token / id token)
- 응답: 기존 `LoginResponse` 동일 (accessToken, refreshToken, user 정보)
- 최초 로그인 시 계정 자동 생성, 이후는 기존 계정 반환

마스터 기획서 6장 DB 스키마 — users 테이블 변경 필요:
- `provider VARCHAR(20) NOT NULL DEFAULT 'email'`
- `provider_id VARCHAR(255) NULL`
- `password` → NULL 허용으로 변경
- `widget_enabled BOOLEAN NOT NULL DEFAULT false`
- UNIQUE `(provider, provider_id)`

## 구체적 변경사항

### 1. DB 스키마 (Flyway V6)

```sql
ALTER TABLE users
    ADD COLUMN provider       VARCHAR(20)  NOT NULL DEFAULT 'email',
    ADD COLUMN provider_id    VARCHAR(255),
    ADD COLUMN widget_enabled BOOLEAN      NOT NULL DEFAULT false;

ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

ALTER TABLE users
    ADD CONSTRAINT users_provider_provider_id_key UNIQUE (provider, provider_id);
```

### 2. 소셜 토큰 검증 방식

**카카오**: 클라이언트가 카카오 SDK로 발급한 access token → 백엔드가 카카오 API(`https://kapi.kakao.com/v2/user/me`) 호출하여 사용자 정보(id, email) 확인.

**구글**: 클라이언트가 Google Sign-In SDK로 발급한 ID token → 백엔드가 Google tokeninfo 엔드포인트(`https://oauth2.googleapis.com/tokeninfo?id_token=...`) 호출하여 검증 + 사용자 정보(sub, email) 확인.

### 3. 신규/변경 파일

**신규:**
- `domain/auth/dto/SocialLoginRequest.java` — `{ String token }`
- `domain/auth/service/KakaoAuthService.java` — 카카오 API 호출, `SocialUserInfo` 반환
- `domain/auth/service/GoogleAuthService.java` — Google tokeninfo 호출, `SocialUserInfo` 반환
- `domain/auth/dto/SocialUserInfo.java` — `{ String provider, String providerId, String email }`

**변경:**
- `domain/user/entity/User.java` — `provider`, `providerId`, `widgetEnabled` 필드 추가, `password` nullable
- `domain/auth/controller/AuthController.java` — `POST /api/auth/social/{provider}` 엔드포인트 추가
- `domain/auth/service/AuthService.java` — `socialLogin(provider, token)` 메서드 추가
- `global/config/SecurityConfig.java` — `/api/auth/social/**` permitAll 추가

### 4. API 변화

```
POST /api/auth/social/kakao
POST /api/auth/social/google
Body: { "token": "<sdk_token>" }
Response: LoginResponse (동일)
```

## 영향 범위

- `V6__social_login_users.sql` 신규
- `SocialLoginRequest`, `SocialUserInfo` DTO 신규
- `KakaoAuthService`, `GoogleAuthService` 신규
- `User` 엔티티 수정 (provider, providerId, widgetEnabled, password nullable)
- `AuthController`, `AuthService` 수정
- `SecurityConfig` 수정
- 기존 이메일 로그인/회원가입 로직 변경 없음

## 시크릿 키

`.env`에 이미 있음 — 추가 발급 불필요:
- `KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET`
- `GOOGLE_CLIENT_ID_ANDROID`, `GOOGLE_CLIENT_ID_IOS`, `GOOGLE_CLIENT_ID_WEB`
