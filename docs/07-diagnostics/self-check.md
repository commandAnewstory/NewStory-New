# 자가진단 체크리스트

> 클로드코드가 "UI 깨짐/잘림", "OAuth 로그인 안 됨", "기능 동작 안 함" 등을 스스로 찾아내고 고칠 때 쓰는 체크리스트. 순서대로 진행하고, 각 항목의 결과를 `docs/07-diagnostics/reports/YYYY-MM-DD-selfcheck.md`에 기록한다 (새 파일, 날짜는 오늘 날짜).

## 0. 사전 확인
- [ ] `flutter doctor -v` 실행 — SDK/툴체인 문제부터 확인 (여기서 에러 나면 아래 항목들 다 무의미하니 이것부터 해결)
- [ ] 백엔드가 로컬에서 떠 있는지 확인 (`curl -i http://localhost:8080/api/news/popular` 등으로 응답 확인). 안 떠 있으면 백엔드부터 기동
- [ ] Flutter 앱의 API base URL 설정이 실제 백엔드 주소(에뮬레이터면 `10.0.2.2`, 실기기면 PC의 로컬 IP)와 맞는지 확인 — 여기 안 맞으면 아래 기능 전부 실패로 보임

## 1. 빌드/정적 분석
- [ ] `flutter analyze` — 경고/에러 전부 나열, 특히 위젯 트리 관련 경고(overflow 가능성 암시하는 것들) 우선 확인
- [ ] `flutter build apk --debug` — 빌드 자체가 되는지 확인. 실패하면 에러 로그 그대로 기록

## 2. UI 깨짐/잘림 (RenderFlex overflow 등)
- [ ] 에뮬레이터/실기기에서 앱 실행 후 화면 7개(홈/기사상세 동화체·소설체/카드요약/변환/로그인/보관함/MY) 전부 순서대로 진입
- [ ] 각 화면 진입 시 콘솔에 `A RenderFlex overflowed by ... pixels` 또는 `Another exception was thrown` 같은 에러가 뜨는지 확인 (`flutter logs` 또는 실행 중인 터미널 출력 grep)
- [ ] 잘리는/깨지는 화면 발견 시 `docs/02-design/screens/<대응 화면>.dc.html`과 비교해서 원인 파악 (고정 height인데 내용이 더 긴 경우, Row/Column에 Expanded/Flexible 안 씌운 경우, 폰트 크기가 커서 넘치는 경우 등 전형적 원인부터 의심)
- [ ] 특히 긴 텍스트(기사 제목, 본문), 사용자 이메일처럼 길이가 가변적인 데이터가 들어가는 위젯은 실제 API 응답값(짧은 더미가 아니라 긴 실데이터)으로도 테스트

## 3. OAuth 로그인 (카카오/구글)
- [ ] `.env`의 `KAKAO_CLIENT_ID`, `KAKAO_CLIENT_SECRET`, `GOOGLE_CLIENT_ID_ANDROID`, `GOOGLE_CLIENT_ID_WEB`, `GOOGLE_CLIENT_SECRET_WEB` 값이 백엔드에 실제로 로드되는지 확인 (`application-local.yml` 또는 spring-dotenv 연동이 실제 값 읽어오는지 로그로 확인)
- [ ] Android 쪽: `android/app/build.gradle` 또는 `AndroidManifest.xml`에 카카오 네이티브 앱 키가 올바르게 등록됐는지 확인 (카카오 SDK는 매니페스트에 `KakaoSdk.init()` 호출 + scheme 등록 필요)
- [ ] 구글: Android 클라이언트의 SHA-1 지문이 **지금 빌드에 실제로 서명하는 키스토어**의 SHA-1과 일치하는지 확인 (`keytool -list -v -keystore <실제 사용 중인 키스토어>`로 재확인 — 디버그 키스토어가 매번 같은 머신에서 생성된 게 맞는지, 다른 PC/CI에서 새로 생성된 키스토어를 쓰고 있진 않은지 의심)
- [ ] `POST /api/auth/social/{provider}` 호출이 실제로 나가는지 네트워크 로그로 확인 (요청 자체가 안 나가면 프론트 버튼 핸들러 문제, 나가는데 4xx/5xx면 백엔드 검증 로직 문제 — 원인을 반드시 이 둘 중 하나로 좁혀서 보고할 것)
- [ ] 실패 시 정확한 에러 메시지/상태 코드를 기록 (예: "카카오 로그인 안 됨" 같은 뭉뚱그린 표현 금지, "POST /api/auth/social/kakao → 401, body: {...}" 식으로)

## 4. 기타 기능 전수 점검
`docs/00-master/master-plan.md` 5장 엔드포인트 설계에 있는 모든 엔드포인트를 하나씩 실제로 호출해보고 결과를 표로 정리:

| 엔드포인트 | 화면에서 정상 호출됨? | 백엔드 응답 정상? | 비고 |
|---|---|---|---|
| POST /api/auth/signup | | | |
| POST /api/auth/login | | | |
| POST /api/auth/social/kakao | | | |
| POST /api/auth/social/google | | | |
| GET /api/users/me | | | |
| PATCH /api/users/me | | | |
| GET /api/news | | | |
| GET /api/news/categories | | | |
| POST /api/convert | | | |
| GET /api/convert/{resultId} | | | |
| GET /api/history | | | |
| GET /api/bookmarks | | | |
| POST/DELETE /api/bookmarks/{resultId} | | | |
| GET /api/widget/today-cards | | | |

## 5. 보고 형식
`docs/07-diagnostics/reports/`에 날짜별 파일로 남긴다. 각 발견 사항은:
- 어느 화면/기능인지
- 재현 방법 (구체적으로 — "로그인 화면에서 카카오 버튼 탭" 수준)
- 실제 에러/증상 (로그 원문 그대로 첨부)
- 추정 원인
- 수정 완료했으면 커밋 해시, 안 했으면 왜 못 했는지(예: 별도 이슈로 분리 필요, 사용자 확인 필요 등)

## 하지 말아야 할 것
- 원인 파악 없이 "일단 이것저것 고쳐보기" 식 수정 금지 — 위 체크리스트로 원인부터 좁힐 것
- 여러 화면/기능 문제를 한 커밋에 뭉쳐서 고치지 말 것 (문제 단위로 커밋 분리, 이슈 규칙은 `docs/06-github/ISSUE_RULES.md` 그대로 따름 — 자잘한 버그 다수는 이슈 하나로 묶어도 되지만 그 안에서도 커밋은 분리)
