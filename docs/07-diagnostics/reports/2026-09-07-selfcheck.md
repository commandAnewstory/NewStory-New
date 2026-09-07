# 자가진단 보고서 — 2026-09-07

진단 실시 시각: 2026-09-07 (branch: `app/07-design-fix` — staged 상태, 미커밋)

---

## 0. 사전 확인 결과

| 항목 | 결과 |
|---|---|
| `flutter doctor -v` | ✅ 이상 없음. Xcode 26.6, Android SDK 36.0.0, Flutter 3.44.4 |
| Android 기기 연결 | ❌ `adb devices` 출력 없음 — 실기기 UI 직접 테스트 불가 |
| 백엔드 기동 | ✅ `localhost:8090` 동작 중 (`curl /actuator/health` → 401, Spring Security 정상 응답) |
| API base URL | ⚠️ 직전 세션에서 `localhost:8090` → `172.30.1.7:8090` 으로 변경했으나 기기 없어 미검증 |

---

## 1. 빌드 / 정적 분석

### `flutter analyze`
경고 2건 발견:

```
warning • The declaration '_mathUnused' isn't referenced
         • lib/core/router/app_router.dart:327:7 • unused_element

warning • Unused import: '../../core/router/app_router.dart'
         • lib/features/my/my_screen.dart:4:8 • unused_import
```

**원인:**
- `app_router.dart`: `dart:math` import 후 실제 사용 없어서 `final _mathUnused = math.pi;` 핵으로 경고 억제했으나 그 핵 자체가 unused element 경고 유발
- `my_screen.dart`: 이전 세션에서 라우터를 쓰다 제거하면서 import가 남음

**수정:** 두 파일 모두 수정 완료 → `flutter analyze` 이후 `No issues found`

### `flutter build apk --debug`
✅ 성공 (`build/app/outputs/flutter-apk/app-debug.apk`)

---

## 2. UI 깨짐/잘림

**실기기 직접 테스트 불가** (ADB 기기 없음). 코드 정적 분석으로 대체.

### 공통 — Row overflow 위험 스캔
`grep -rn "Row("` 후 각 Row 내 Expanded/Flexible 존재 여부 확인. 주요 화면 모두 Expanded로 텍스트 영역 감싸고 있음 → 정적 분석상 명백한 overflow 없음.

### 화면별 주요 체크 포인트 (코드 리뷰)

| 화면 | 잠재 위험 | 판단 |
|---|---|---|
| 홈 | hero_card 224px 고정 height | 내부 Column에 Expanded 없음, 고정 영역이므로 OK |
| 기사상세 | `Row` (보관함 저장 버튼 + 공유 버튼) | Expanded로 첫 버튼 감쌈 ✅ |
| 로그인/회원가입 | SingleChildScrollView 사용 | 스크롤 가능 ✅ |
| 보관함 | GridView 2열 childAspectRatio 0.88 | 동적 타이틀에 maxLines 2 + ellipsis ✅ |
| MY | _WidgetPromoCard 내 긴 설명 텍스트 | height 1.5 line-height, 고정 너비 아님 ✅ |
| 변환 | URL 입력 + StylePicker | SingleChildScrollView ✅ |

**실기기 테스트 필요:** 실제 긴 제목(50자 이상)이나 영어 섞인 URL이 들어올 때 잘림 여부 — 기기 연결 후 확인 필요.

---

## 3. OAuth 로그인

### 카카오

| 체크 | 상태 |
|---|---|
| Flutter `_socialLogin()` 필드명 | ✅ `{'token': token}` — 백엔드 `SocialLoginRequest.token` 일치 |
| `KakaoSdk.init(nativeAppKey:)` 호출 | ✅ `main.dart:15` — `defaultValue: 'c4e8a62cbf905af0756f20a522b1b162'` |
| AndroidManifest 카카오 scheme | ✅ `kakaoc4e8a62cbf905af0756f20a522b1b162://oauth` 등록됨 |
| meta-data AppKey | ✅ `c4e8a62cbf905af0756f20a522b1b162` 일치 |
| 실기기 실행 테스트 | ❌ 기기 없어 미실시 |
| 백엔드 `.env` `KAKAO_CLIENT_ID` | ✅ 값 있음 |

**추정:** 코드 레벨은 문제 없음. 실기기 연결 후 재테스트 필요.

### 구글

| 체크 | 상태 |
|---|---|
| Flutter `idToken` → 백엔드 `token` 필드 | ✅ 올바름 |
| SHA-1 지문 검증 | ❌ 기기 없어 미실시 — 디버그 키스토어 SHA-1이 Google Console에 등록됐는지 확인 필요 |
| `GOOGLE_CLIENT_ID_ANDROID` | ✅ .env에 값 있음 |

**추정:** SHA-1 불일치 시 `idToken null` 오류 발생. 기기 연결 후 `keytool` 로 확인 필요.

---

## 4. 기능 전수 점검 (엔드포인트)

| 엔드포인트 | 화면에서 정상 호출됨? | 백엔드 응답 정상? | 비고 |
|---|---|---|---|
| POST /api/auth/signup | ✅ UI 있음, curl 201 | ✅ 201 Created | |
| POST /api/auth/login | ✅ 이메일 로그인 구현 | ✅ 200 + 토큰 | |
| POST /api/auth/social/kakao | ✅ `loginWithKakao()` 구현 | ⚠️ 실기기 미테스트 | 카카오 토큰 필요 |
| POST /api/auth/social/google | ✅ `loginWithGoogle()` 구현 | ⚠️ 실기기 미테스트 | |
| GET /api/users/me | ✅ my_provider 호출 | ✅ 200 | |
| PATCH /api/users/me | ✅ my_provider 구현 | ✅ 200 | |
| GET /api/news | ✅ home_provider 호출 | ✅ 200 + 기사 목록 | |
| GET /api/news/categories | ❌ Flutter 미호출 (하드코딩) | ✅ 200 (IT/전체/정치 3개) | Flutter에서 사용 안 함, DB에 3개만 있음 |
| POST /api/convert | ✅ article_detail_provider 호출 | ❌ **500** | **Gemma off + Claude 크레딧 부족** |
| GET /api/convert/{resultId} | ✅ article_detail_provider 구현 | ✅ (결과 있을 때 200, 없으면 404) | |
| GET /api/history | ✅ bookmarks_provider 호출 | ✅ 200 | |
| GET /api/bookmarks | ✅ bookmarks_provider 호출 | ✅ 200 | |
| POST/DELETE /api/bookmarks/{resultId} | ✅ 구현 | 미테스트 (convert 결과 없어서) | |
| GET /api/widget/today-cards | ✅ my_provider 구현 | ✅ 200 | |

---

## 5. 발견 문제 목록

### P0 (기능 불가)

**[BUG-01] POST /api/convert → 500 — AI 백엔드 전체 불가**

- 재현: `POST /api/convert -d '{"url":"<뉴스URL>","style":"fairy_tale"}'`
- 에러: `{"message":"서버 오류가 발생했습니다.","success":false}`
- 원인 추적:
  1. `ConvertService.runConversionPipeline()` → Gemma API (`localhost:8081`) 호출 → Connection refused (Gemma 서버 미기동)
  2. catch → Claude API fallback → `POST https://api.anthropic.com/v1/messages` → **`"Your credit balance is too low to access the Anthropic API"`**
  3. Claude도 실패 → unhandled RuntimeException → GlobalExceptionHandler가 500 리턴
- 수정 방법: **Anthropic 콘솔에서 크레딧 충전 필요** (코드 수정으로 해결 불가)
- 커밋 해시: 없음 (사용자 조치 필요)

---

### P1 (코드 경고)

**[BUG-02] flutter analyze 경고 2건**

- `app_router.dart:327` — `_mathUnused` unused element
- `my_screen.dart:4` — unused import
- **수정 완료** (staged, 미커밋)

---

### P2 (확인 필요)

**[PENDING-01] Android 기기 미연결 — UI 직접 테스트 불가**

- 기기 연결 후 다음 확인 필요:
  - 각 화면 overflow 실제 여부
  - 카카오/구글 OAuth 실제 동작
  - API base URL `172.30.1.7:8090` 연결 성공 여부

**[PENDING-02] API base URL 하드코딩 문제**

- `dio_client.dart` defaultValue: `http://172.30.1.7:8090` — PC IP 바뀌면 앱 재빌드 필요
- 장기 해결: 빌드 스크립트에 `--dart-define=API_BASE_URL=http://...` 로 주입

---

## 수정 완료 목록

| ID | 파일 | 내용 |
|---|---|---|
| BUG-02 | `app/lib/core/router/app_router.dart` | `dart:math` import + `_mathUnused` 제거 |
| BUG-02 | `app/lib/features/my/my_screen.dart` | unused import `app_router.dart` 제거 |

---

## 사용자 조치 필요

1. **Anthropic 크레딧 충전** → POST /api/convert 동작 복구
2. **Android 기기 USB 연결** → OAuth + UI overflow 실기기 검증
