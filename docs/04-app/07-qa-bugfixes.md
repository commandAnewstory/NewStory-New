# 서브플랜: QA 전수 테스트 버그 수정

## 목표
`docs/07-diagnostics/reports/2026-09-09-full-qa-report.md` 에서 발견된 실 버그 2건 수정.

## 변경 파일
- `app/lib/features/article/article_detail_provider.dart`
- `backend/src/main/java/.../domain/user/service/UserService.java`

## 변경 내용

### BUG-01: ConvertResponse 필드명 불일치
- 백엔드 `ConvertResponse`는 `id` 키로 반환
- Flutter가 `data['resultId']` 읽어서 null
- 수정: `ConvertResult`에 `resultId` 필드 추가, `data['id']`로 파싱

### BUG-02: PATCH /api/users/me widgetEnabled 저장 안 됨
- JWT 필터에서 로드된 `User` 엔티티가 `UserService.updateMe()` 트랜잭션 밖에서 detached됨
- dirty-tracking 동작 안 해 DB 미반영
- 수정: `UserRepository` 주입, `findById()`로 managed entity re-fetch 후 업데이트

## 완료 기준
- `POST /api/convert` 응답 `id` → `ConvertResult.resultId`에 정상 파싱
- `PATCH /api/users/me {widgetEnabled:true}` → 재조회 시 true 유지

## 영향 범위
- 보관함 저장 기능 (resultId 사용)
- MY 화면 위젯 토글
