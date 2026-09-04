# 00. Flutter 앱 스캐폴딩

> 마스터 기획서 8장 "개발 순서" 7번 시작. 화면 구현 전에 앱 뼈대(프로젝트 구조, 테마, 네비게이션, 네트워크, 인증 상태)를 잡는다.

## 왜 하는가

화면 7개를 구현하기 전에 전체에서 공유하는 레이어가 먼저 있어야 한다:
- 디자인 토큰(색상, 타이포) → Flutter ThemeData
- 하단 탭 4개 + 라우팅 → 모든 화면의 진입점
- JWT 저장 + 인증 상태 관리 → 로그인 여부에 따라 화면 분기
- API 클라이언트 → 모든 화면에서 재사용

## 프로젝트 위치

`~/Desktop/NewStory/app/` — `flutter create` 로 신규 생성.  
Bundle ID: `com.newstory.app` (iOS/Android 공통)

## 구체적 변경사항

### 1. 패키지 구조

```
app/lib/
  main.dart
  core/
    api/         — Dio 클라이언트, interceptor (JWT 자동 첨부, 401 refresh)
    auth/        — AuthNotifier (Riverpod), SecureStorage 래퍼
    router/      — GoRouter 설정 (탭 셸, 라우트 정의)
    theme/       — AppTheme (ThemeData), 색상·타이포 토큰
  features/
    home/        — (다음 기획서)
    convert/     — (다음 기획서)
    bookmarks/   — (다음 기획서)
    my/          — (다음 기획서)
    auth/        — (다음 기획서)
```

### 2. 주요 의존성 (pubspec.yaml)

| 패키지 | 용도 |
|---|---|
| `flutter_riverpod` | 상태 관리 |
| `go_router` | 선언형 라우팅 + 탭 셸 |
| `dio` | HTTP 클라이언트 |
| `flutter_secure_storage` | JWT 토큰 안전 저장 |
| `google_fonts` | Do Hyeon 폰트 |
| `kakao_flutter_sdk_user` | 카카오 로그인 SDK |
| `google_sign_in` | 구글 로그인 SDK |

### 3. 테마 (AppTheme)

디자인 토큰 그대로:
- `backgroundColor`: `#F7F7F6`
- `onSurface` (ink): `#17181C`
- `primary`: `#3654F4`
- 스타일 색상 상수: `StyleColors.fairyTale`, `StyleColors.novel`, `StyleColors.card`
- `displayFont`: Google Fonts `Do Hyeon` (짧은 강조 텍스트 전용)
- 본문: `TextTheme` 전체 `fontFamily` = 시스템 산세리프

### 4. 라우팅 (GoRouter + StatefulShellRoute)

하단 탭 4개 ShellRoute:
- `/home` → HomeScreen
- `/convert` → ConvertScreen
- `/bookmarks` → BookmarksScreen
- `/my` → MyScreen

탭 외 라우트:
- `/login` → LoginScreen
- `/article/:id` → ArticleDetailScreen
- `/article/:id/converted/:resultId` → ConvertedDetailScreen

인증 리다이렉트: 로그인 필요 라우트 접근 시 `/login`으로.

### 5. 인증 상태 (AuthNotifier)

`flutter_secure_storage`에 accessToken / refreshToken 저장.  
앱 시작 시 토큰 존재 여부 확인 → 인증 상태 초기화.  
401 응답 시 Dio interceptor에서 자동 refresh → 실패 시 로그아웃.

### 6. API 클라이언트

`DioClient` — baseUrl: `${API_BASE_URL}` (`.env` 또는 `--dart-define`으로 주입).  
Interceptor:
- 요청마다 `Authorization: Bearer <accessToken>` 자동 첨부
- 401 → refresh token으로 재발급 시도 → 성공 시 원 요청 재시도 → 실패 시 로그아웃

## 영향 범위

- `app/` 폴더 전체 신규
- 화면 구현 없음 — 각 feature 폴더는 빈 placeholder screen만 둠
- Backend API 호출은 다음 기획서부터

## 완료 조건

- `flutter run`으로 앱 실행 시 하단 탭 4개와 각 탭의 placeholder 화면이 보이면 완료
- 테마 색상이 `#F7F7F6` 배경 / `#3654F4` primary로 적용됨
- `flutter analyze` 에러 없음
