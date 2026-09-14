# 전체 기능 QA 보고서 — 2026-09-09

Claude API 크레딧 충전 후 `full-qa-checklist.md` 0~10번 전수 실행 결과.

---

## 검증 환경

| 항목 | 상태 |
|---|---|
| Claude API | ✅ 200 정상 (크레딧 충전 완료) |
| 백엔드 | ✅ localhost:8090 기동 |
| adb reverse | ❌ 기기 미연결 (USB) — API 직접 curl로 대체 |
| Flutter 앱 | ✅ `172.28.46.135:8090` 빌드로 설치됨 |

---

## 0. 사전 준비

- [x] 백엔드 기동
- [x] Claude API 키 유효 (200 확인)
- [ ] adb reverse — 기기 미연결로 미설정
- [x] QA 테스트 계정 생성 (`qa_1788929924@newstory.test`)

---

## 통과 항목

| 항목 | 결과 |
|---|---|
| 1. 이메일 회원가입 정상 | ✅ 201 |
| 1. 중복 이메일 에러 메시지 | ✅ `"이미 사용 중인 이메일입니다."` |
| 1. 비번 틀림 에러 메시지 | ✅ `"이메일 또는 비밀번호가 올바르지 않습니다."` |
| 2. GET /api/news 기사 목록 | ✅ 20개 반환 |
| 2. GET /api/news?category=정치 필터링 | ✅ 정치 카테고리만 반환 |
| 4. POST /api/convert (fairy_tale/MEDIUM) | ✅ 200, 1.19s, Gemma실패→Claude폴백 |
| 4. 캐시 히트 재요청 | ✅ `cachedResult: true`, 1.1s (AI 재호출 없음) |
| 4. novel/LOW 신규 변환 | ✅ 200, 52s (AI 호출 정상) |
| 4. glossary 파싱 | ✅ 4개 용어 반환, 마킹문법 본문 미노출 |
| 5. POST /api/bookmarks/{resultId} | ✅ 201 |
| 5. GET /api/bookmarks | ✅ 목록 반환, 필드명 일치 |
| 5. DELETE /api/bookmarks/{resultId} | ✅ 200 |
| 5. GET /api/history | ✅ 목록 반환, 필드명 일치 |
| 5. DELETE /api/history/{resultId} | ✅ 200 |
| 6. GET /api/users/me | ✅ `widgetEnabled`, `lastGlossaryLevel` 정상 |
| 6. PATCH /api/users/me nickname | ✅ 200 |
| 7. GET /api/widget/today-cards | ✅ 200 (card feed 기사 없어 0개 — 데이터 이슈) |
| 2. GET /api/news/popular | ✅ 200 |
| 2. POST /api/news/{id}/view | ✅ 200 |
| 3. GET /api/convert/original | ✅ 200, title/content 반환 |
| 3. GET /api/convert/{resultId} | ✅ 200 |

---

## 실패 항목

### [BUG-01] ConvertResponse 필드명 불일치 — Flutter resultId null

- **재현 방법:** Flutter 앱에서 변환 탭 → 기사 상세 → 동화체 변환 완료 후 보관함 저장 시도
- **기대 동작:** `resultId`가 파싱되어 `/api/bookmarks/{resultId}`에 사용됨
- **실제 동작:** Flutter `_convert()` 가 `data['resultId']` 읽음 → backend는 `id` 키로 반환 → null
- **원인:** `ConvertResponse.java` 필드명 `id`, Flutter 파싱 코드 `data['resultId']` 불일치
  ```
  backend: { "id": 2, "cachedResult": true, ... }
  Flutter: data['resultId'] → null
           data['cacheHit'] → 미사용 (큰 문제 없음)
  ```
- **영향:** `ConvertResult` 모델에 resultId 없음 → 보관함 저장 기능 구현 시 broken (현재는 snackbar stub이라 직접 크래시 없음)
- **수정 여부:** 수정 완료 (아래 커밋)

---

### [BUG-02] PATCH /api/users/me widgetEnabled 저장 안 됨

- **재현 방법:** `PATCH /api/users/me {"widgetEnabled":true}` → 응답 `widgetEnabled: true` → 이후 `GET /api/users/me` → `widgetEnabled: false`
- **기대 동작:** 토글 값이 DB에 저장되어 재조회 시 유지됨
- **실제 동작:** 메모리에서만 값 변경, DB 미반영
- **원인:** `UserService.updateMe()` 가 `@Transactional` 이지만, `authUtil.currentUser()` 가 반환하는 `User` 는 JWT 필터에서 로드된 뒤 영속성 컨텍스트 밖으로 나온 **detached entity**. `user.updateWidgetEnabled()` 호출 시 JPA dirty-tracking 없음 → flush 없음
- **수정 여부:** 수정 완료 (아래 커밋)

---

### [INFO-01] GET /api/news/categories 3개만 반환

- **원인:** RSS 수집이 IT/전체/정치 카테고리만 DB에 있음. 버그 아님, 데이터 이슈
- **Flutter 처리:** 하드코딩 8개 카테고리 사용 → API 미호출 → 실제로는 데이터 없는 카테고리 선택 시 빈 목록 표시
- **수정 여부:** 미수정 (데이터 수집 확대 필요 시 RSS 소스 추가 별도 이슈)

---

### [INFO-02] GET /api/widget/today-cards 0개

- **원인:** card style feed 변환 기사 없음. 버그 아님
- **수정 여부:** 미수정

---

### [INFO-03] 원문 content에 크롤링 노이즈

- **재현:** `GET /api/convert/original?url=<동아일보URL>` → content 앞부분에 "공유하기 SNS 퍼가기..." 등 UI 텍스트 포함
- **원인:** `CrawlingService` Jsoup 셀렉터 (`article, .article-body` 등)가 해당 언론사 DOM에 맞지 않아 `body.html()` fallback 사용
- **수정 여부:** 미수정 (크롤러 개선 별도 이슈)

---

## 8. 프론트-백엔드 필드 대조 결과

| 엔드포인트 | 백엔드 필드 | Flutter 필드 | 일치? |
|---|---|---|---|
| POST /api/convert | `id` | `resultId` | ❌ BUG-01 |
| POST /api/convert | `cachedResult` | (미사용) | ⚠️ 경미 |
| POST /api/convert | `convertedText` | `convertedText` | ✅ |
| POST /api/convert | `glossary[].term/definition` | `GlossaryItem.term/definition` | ✅ |
| POST /api/convert | `readingTimeLabel` | `readingTimeLabel` | ✅ (null when !card) |
| POST /api/convert | `verificationPassed` | (미사용) | ✅ |
| GET /api/news | `id/title/url/category/source/publishedAt` | 동일 | ✅ |
| GET /api/news | `publishedAt` LocalDateTime | String ISO8601 파싱 | ✅ (Jackson 직렬화 확인) |
| GET /api/bookmarks | `bookmarkId/resultId/articleTitle/bookmarkedAt/style` | 동일 fromJson | ✅ |
| GET /api/history | `resultId/articleTitle/createdAt/style` | 동일 fromJson | ✅ |
| GET /api/users/me | `widgetEnabled/lastGlossaryLevel/nickname/email` | 동일 | ✅ |

---

## 수정 내역

### BUG-01 수정: Flutter ConvertResult에 resultId 추가
`article_detail_provider.dart` — `data['id']` 로 파싱, `ConvertResult`에 `resultId` 필드 추가

### BUG-02 수정: UserService detached entity 문제
`UserService.java` — `UserRepository` 주입, `findById()` 로 managed entity re-fetch 후 업데이트

---

## 미검증 (기기 연결 필요)

- 카카오/구글 소셜 로그인 실기기 동작
- 앱 내 토큰 자동 재발급 interceptor 동작
- 다크모드 UI 깨짐
- 네트워크 끊김 에러 UI
- 스타일 전환 캐시/로딩 UX (앱에서 실제 눌러보기)
