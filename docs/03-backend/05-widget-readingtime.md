# 05. 위젯 API + 카드요약 읽기시간 배지

> 마스터 기획서 8장 "개발 순서" 6번. 오늘의 카드요약 3개를 위젯 전용 경량 payload로 반환하는 API, 카드요약 변환 응답에 readingTimeLabel 추가, users.widget_enabled ON/OFF.

## 왜 하는가

마스터 기획서 5장 엔드포인트:
- `GET /api/widget/today-cards` — 홈스크린 위젯 전용. 오늘 수집된 기사 중 card 스타일 캐시가 있는 것 3개, 경량 payload
- `POST /api/convert` 응답에 `readingTimeLabel` 추가 — card 스타일일 때만, 예: "약 30초", "1분"
- `PATCH /api/users/me` — `widgetEnabled` 필드 추가 (이미 users.widget_enabled 컬럼은 V6에서 추가됨)
- `GET /api/users/me` 응답 — `lastGlossaryLevel`, `widgetEnabled` 필드 추가

## 구체적 변경사항

### 1. DB 스키마

추가 마이그레이션 없음 — `users.widget_enabled`는 V6에서 이미 추가됨.

### 2. readingTimeLabel 계산 로직

카드요약 본문 글자 수 기준 (한국어 기준 분당 약 500자):

| 글자 수 | label |
|---|---|
| ~250자 | "약 30초" |
| 251~500자 | "약 1분" |
| 501자~ | "약 N분" (올림) |

`global/common/ReadingTimeCalculator.java` 유틸로 분리.

### 3. 신규/변경 파일

**신규:**
- `domain/widget/` 패키지 신규
  - `controller/WidgetController.java` — `GET /api/widget/today-cards`
  - `dto/TodayCardResponse.java` — `{ Long articleId, String title, String convertedText, String readingTimeLabel }`
  - `service/WidgetService.java`
- `global/common/ReadingTimeCalculator.java` — 글자 수 → label 변환 유틸

**변경:**
- `domain/convert/dto/ConvertResponse.java` — `readingTimeLabel` 필드 추가 (card 외 스타일은 null)
- `domain/convert/service/ConvertService.java` — convert() 응답 생성 시 readingTimeLabel 계산
- `domain/user/dto/UserResponse.java` — `lastGlossaryLevel`, `widgetEnabled` 추가
- `domain/user/dto/UpdateUserRequest.java` — `widgetEnabled` 필드 추가
- `domain/user/service/UserService.java` — `updateMe()` 에서 widgetEnabled 처리
- `global/config/SecurityConfig.java` — `GET /api/widget/today-cards` permitAll (위젯은 비로그인도 접근 가능)

### 4. 위젯 API 상세

```
GET /api/widget/today-cards
인증: 불필요 (위젯은 잠금화면에서도 동작)
응답:
[
  {
    "articleId": 1,
    "title": "기사 제목",
    "convertedText": "• 핵심 내용 1\n• 핵심 내용 2...",
    "readingTimeLabel": "약 30초"
  },
  ...
]
```

조회 기준: `conversion_cache`에서 `style='card'`이고 `created_at >= 오늘 00:00` 인 것 최대 3개. 없으면 최근 3개로 fallback.

### 5. API 변화

`POST /api/convert` 응답 추가:
```json
{
  "readingTimeLabel": "약 30초"  // card 스타일만, 나머지는 null
}
```

`GET /api/users/me` 응답 추가:
```json
{
  "lastGlossaryLevel": "MEDIUM",
  "widgetEnabled": false
}
```

`PATCH /api/users/me` 요청 추가:
```json
{
  "widgetEnabled": true
}
```

## 영향 범위

- `domain/widget` 패키지 전체 신규
- `ReadingTimeCalculator` 유틸 신규
- `ConvertResponse`, `ConvertService` 수정 (readingTimeLabel)
- `UserResponse`, `UpdateUserRequest`, `UserService` 수정 (widgetEnabled)
- `SecurityConfig` 수정 (/api/widget/today-cards permitAll)
- DB 변경 없음 (V6에서 이미 완료)
