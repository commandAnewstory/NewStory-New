# 15. 원문 본문 없을 때 흰 화면 → 안내 + 원문 사이트 버튼

> 짝: 백엔드 17번 (조선일보 Fusion JSON 크롤링, 빈 본문은 502)

## 배경 (2026-10-17 실기기 확인 중 발견)
조선일보 기사 원문 탭이 흰 화면. 서버가 본문을 못 뽑고 빈 문자열을 200으로 줬고, 앱은 빈 본문을 그대로 그려서 아무것도 안 보였음.

## 무엇을 하는가 (사용자 승인: "둘 다")
1. 원문 조회 결과가 빈 본문이면 흰 화면 대신 "기사 본문을 가져오지 못했어요. 원문 사이트에서 확인해 주세요." (예전 서버 대비)
2. 서버가 502로 실패하면 서버 안내 문구를 그대로 표시 (원문·변환 둘 다). 그 밖의 실패는 기존 문구 유지
3. 원문·변환 실패 화면 공통: "다시 시도" + "원문 사이트에서 보기"(외부 브라우저, 12번에서 만든 `urlOpenerProvider`)

## 영향 범위
- `app/lib/features/article/article_detail_provider.dart`, `article_detail_screen.dart`
- `app/test/support/fake_api.dart` (`FakeError`에 서버 메시지), `app/test/features/original_unavailable_test.dart` (신규)

## 완료 기준
- `flutter analyze` 0개, `flutter test` 통과
- 테스트: 502 → 서버 문구 + 원문 사이트 버튼(누르면 기사 URL로 열림) / 빈 본문 200 → 안내 / 그 밖 실패 → 기존 문구 + 다시 시도로 복구 / 변환 502 → 서버 문구 + 버튼
