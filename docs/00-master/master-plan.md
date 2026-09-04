# NewStory 앱 리빌드 — 개발 마스터 기획서

> 이 문서는 마스터 기획서다. 실제 개발 진행 시 매 작업 단위(백엔드 도메인 하나, 화면 하나 등)마다 이 문서를 기준으로 **하위 기획서**를 작성 → 사용자 확인 → 개발하는 방식으로 진행한다. 개발 순서는 **백엔드 먼저, Flutter 앱은 그 다음**.

## 1. 핵심 가치 / 타깃
한 줄 요약: **뉴스를 거부감 없게, 재밌고 가볍게 볼 수 있는 앱.** 사실은 한 글자도 바꾸지 않고 형식만 바꾼다.

- 초등학생·청소년: 동화체 → 시사 진입점, 수업 자료
- 바쁜 직장인: 카드요약 → 30초 안에 핵심 파악
- 뉴스 무관심 10대: 소설체 → 몰입감 있게 읽기

## 2. 전체 아키텍처 방향
- 웹(React, `apps/아카이브`)은 유지, 코드 공유 없이 **Flutter 네이티브 앱을 별도로 새로 빌드**
- 백엔드(Spring Boot)는 기존 코드베이스 위에서 **재사용 + 정리 + 확장**. 전면 재작성 아님
- 백엔드 먼저 개발 완료 후 Flutter 앱 개발 착수
- 뉴스 수집: 네이버 뉴스 검색 API 제거 → 언론사 RSS(조선일보/중앙일보/동아일보/SBS/MBC) + Google News RSS(보조, 정치성향 편중·단일장애점 리스크 완화용) 하이브리드
- **프로젝트 위치**: 신규 개발(백엔드+Flutter 앱 전체)은 `~/Desktop/NewStory` 폴더에서 처음부터 새로 작성한다. 구 프로젝트 폴더(`~/Desktop/프로젝트/newspace/newstory`)는 참고 자료로만 두고 더 이상 수정하지 않는다 — 위 "재사용" 표현은 코드 방향성/설계를 재사용한다는 뜻이며, 실제 코드는 새 폴더에 새로 작성한다.
- **배포**도 새 `NewStory` 폴더 기준으로 다시 세팅한다. 구 폴더의 배포 설정(서버/인프라/CI 등)은 참고만 하고 그대로 재사용하지 않는다.
- **Flutter Bundle ID**: `com.newstory.app` (Android 패키지명 / iOS 번들 ID 공통, Google OAuth 클라이언트에 이미 이 값으로 등록 완료)

## 3. 확정 디자인 요약
방향: **매거진 그리드형(B)**. 캔버스 아티팩트에 핵심 화면 7개 확정 (`newstory-mobile-home-wireframes.html`, claude.ai 아티팩트).

디자인 토큰:
- 배경: `#F7F7F6` (뉴트럴, 웜톤 과다 지양)
- 잉크 텍스트: `#17181C`
- 프라이머리: `#3654F4`
- 스타일 3종 색상 코드 고정 — 동화체: 배경 `#FDECC8` / 텍스트 `#8A5A0F`, 소설체: 배경 `#E6DEFA` / 텍스트 `#5A3A9E`, 카드요약: 배경 `#D7F3EE` / 텍스트 `#0B6E64` (API 응답의 style 값과 매핑, 프론트 전역에서 재사용)
- 디스플레이 타이포: Google Fonts `Do Hyeon` (로고, 화면 타이틀, CTA, 배지 등 짧은 강조 텍스트에만 적용, 본문은 시스템 산세리프 유지)
- 하단 탭 4개 고정: 홈 / 변환 / 보관함 / MY
- 변환 탭 아이콘: 마법봉+반짝이(AI 클리셰) 대신 좌우 스왑 화살표 아이콘 사용

화면 7개와 담당 기능:
1. **홈** — RSS 카테고리 칩, 히어로 카드, 2단 그리드, 카드요약 미리보기 "30초 컷" 배지
2. **기사 상세 (동화체/소설체)** — 원문/동화체/소설체/카드요약 세그먼트, 본문 내 용어 탭-설명
3. **기사 상세 (카드요약)** — bullet 5개 이하 + "30초 컷" 배지
4. **직접 변환** — URL 입력, 지원 언론사 chip, 스타일 3종 선택
5. **로그인** — 카카오/구글 소셜 로그인 우선, 이메일은 보조
6. **보관함** — 보관함/히스토리 세그먼트 통합
7. **MY** — 프로필, 홈스크린 위젯 온오프 토글, 설정 메뉴

## 4. 확정 기능 백로그 (우선순위 순)
1. 백엔드 버그/보안 선행 정리
2. RSS 기반 뉴스 수집 전환
3. 용어 탭-설명 (전 스타일 공통) — 난이도 레벨 3단계(LOW/MEDIUM/HIGH) 포함. 낮을수록 마킹되는 용어 수 많아짐. 요청마다 선택 가능하되 기본값은 사용자의 최근 선택 레벨
4. 변환 결과 캐싱
5. 카드요약 예상 읽기 시간 배지
6. 소셜 로그인 (카카오/구글)
7. 홈스크린 위젯 (오늘의 카드요약 3개, 사용자 온오프)

**보류**: 연속 이슈 "다음화" 형식 이어보기 (구현 난이도 높음, 이번 범위 제외)

## 5. 엔드포인트 설계

표기: 🟢 기존 유지 · 🟡 기존 확장(파라미터/응답 필드 추가) · 🔵 신규 · 🔴 제거

### 인증
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| POST `/api/auth/signup` | 🟢 | 이메일 회원가입 |
| POST `/api/auth/login` | 🟢 | 이메일 로그인 |
| POST `/api/auth/logout` | 🟢 | 로그아웃 |
| POST `/api/auth/refresh` | 🟢 | 토큰 재발급 |
| POST `/api/auth/social/{provider}` | 🔵 | 소셜 로그인. `provider`=`kakao`\|`google`. body: `{ token }`. 응답은 기존 `LoginResponse`와 동일 — 최초 로그인 시 계정 자동 생성 |

### 회원
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| GET `/api/users/me` | 🟢 | 내 정보 조회 |
| PATCH `/api/users/me` | 🟡 | `UpdateUserRequest`에 `widgetEnabled`(boolean) 필드 추가 |
| GET `/api/users/me` 응답 | 🟡 | `lastGlossaryLevel`(`LOW`\|`MEDIUM`\|`HIGH`) 필드 추가 — 변환 화면 기본 선택값으로 사용 |

### 뉴스
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| GET `/api/news` | 🟡 | `category` 쿼리 파라미터 추가 (RSS 실카테고리 기준). 프론트 키워드매칭 방식 제거 |
| GET `/api/news/categories` | 🔵 | 홈 화면 카테고리 칩 목록 반환 |
| GET `/api/news/popular` | 🟢 | 기존 유지 (스펙엔 없었지만 실제 구현되어 있던 것 정식 반영) |
| POST `/api/news/{id}/view` | 🟢 | 조회수 기록, 기존 유지 |
| `/api/test/**` | 🔴 | 프로덕션 노출 제거 |

### 변환
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| GET `/api/convert/original` | 🟢 | 원본 크롤링, 인증 불필요 |
| POST `/api/convert` | 🟡 | 요청에 `level`(`LOW`\|`MEDIUM`\|`HIGH`, 생략 시 사용자의 `lastGlossaryLevel` 사용) 추가. 응답 확장: `glossary`(용어-뜻풀이 배열), `readingTimeLabel`(카드요약일 때만). 요청 처리 시 `users.last_glossary_level`을 이번 `level`로 갱신. 내부적으로 캐시 확인 로직 추가 |
| GET `/api/convert/{resultId}` | 🟢 | 변환 결과 단건 조회 |

`glossary` 설계: Agent A가 어려운 용어를 `{{term:용어|뜻풀이}}` 형태로 본문에 인라인 마킹. 백엔드가 파싱해 순수 텍스트 + 용어-뜻풀이 매핑 배열로 분리 응답. 오프셋 계산 없이 안정적으로 처리.

**난이도 레벨(`level`)**: LOW/MEDIUM/HIGH. 낮을수록 마킹 개수 많음(설명 필요한 용어 수가 많은 사용자 대상). Agent A 프롬프트에 레벨별 마킹 개수 가이드라인 포함. 사용자의 마지막 선택 레벨은 `users.last_glossary_level`에 저장되어 다음 요청 기본값으로 쓰임.

### 위젯 (신규 도메인)
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| GET `/api/widget/today-cards` | 🔵 | 오늘의 카드요약 3개, 위젯 전용 경량 payload |

### 히스토리 / 보관함
| 메서드/경로 | 상태 | 설명 |
|---|---|---|
| GET `/api/history` | 🟢 | 유지 |
| DELETE `/api/history/{resultId}` | 🟢 | 유지 |
| GET `/api/bookmarks` | 🟢 | 유지 |
| POST `/api/bookmarks/{resultId}` | 🟢 | 유지 |
| DELETE `/api/bookmarks/{resultId}` | 🟢 | 유지 |

## 6. DB 스키마 변경안

**news_articles**
- `category VARCHAR(30) NULL` 추가 — RSS/Google News 수집 시점에 채움. 레거시(네이버 API) 행은 NULL 허용
- `source_type VARCHAR(20) DEFAULT 'rss'` 추가 — `rss` | `google_news` | `legacy_naver`

**users**
- `provider VARCHAR(20) NOT NULL DEFAULT 'email'` 추가
- `provider_id VARCHAR(255) NULL` 추가
- `password` 컬럼 `NULL` 허용으로 변경 (소셜 로그인 계정은 비밀번호 없음)
- `widget_enabled BOOLEAN NOT NULL DEFAULT false` 추가
- `last_glossary_level VARCHAR(10) NOT NULL DEFAULT 'MEDIUM'` 추가 — 용어 글로서리 난이도 마지막 선택값
- UNIQUE 제약 `(provider, provider_id)` 추가

**신규 테이블: conversion_cache**
```
id BIGSERIAL PK
article_id BIGINT FK -> news_articles
style VARCHAR(20)  -- fairy_tale | novel | card
level VARCHAR(10)  -- LOW | MEDIUM | HIGH
converted_text TEXT
glossary JSONB
verification_passed BOOLEAN
retry_count INTEGER
created_at TIMESTAMP
UNIQUE (article_id, style, level)
```
캐시 키가 `(article_id, style)`에서 `(article_id, style, level)`로 바뀜 — 레벨마다 glossary 마킹 개수가 달라 같은 기사+스타일이어도 레벨별로 변환 결과가 다르기 때문. 이미 존재하던 `(article_id, style)` UNIQUE 제약은 마이그레이션에서 드롭 후 새 3-컬럼 UNIQUE로 교체.

`converted_results`(사용자별 히스토리 로그)와는 별도 — 캐시는 기사+스타일+레벨 단위 전역 공유, 히스토리는 사용자별 요청 기록. `POST /api/convert`: 캐시 먼저 조회 → 있으면 AI 재호출 없이 `converted_results`에 사용자별 행만 생성 → 없으면 파이프라인 실행 후 둘 다 저장.

## 7. 알려진 버그/보안 이슈 (선행 정리 대상)
- `ConvertService`: `verificationPassed`가 실제 검증 결과와 무관하게 항상 `true`로 저장되는 로직 오류 수정
- `/api/test/**`, `NewsDebugController`, `GemmaTestController` 등 디버그 엔드포인트가 `SecurityConfig`에서 `permitAll` — 프로덕션 profile에서 비활성화/제거

## 8. 개발 순서 (백엔드 우선)
1. 버그/보안 선행 정리
2. RSS 수집 파이프라인 (news_articles 스키마 변경 포함)
3. 변환 캐싱 (conversion_cache 테이블)
4. 용어 글로서리 (Agent A 프롬프트 + ConvertResponse 확장)
5. 소셜 로그인 (users 스키마 변경 포함)
6. 위젯 API + 카드요약 읽기시간 배지
7. (백엔드 완료 후) Flutter 앱 개발 착수 — 화면 7개 순서대로

## 9. 진행 방식
- 각 항목 착수 전, 이 마스터 기획서를 참고해 `03-backend/`(또는 `04-app/`)에 하위 기획서 작성
- 하위 기획서를 사용자에게 확인받은 뒤 실제 코드 작업 진행
- 마스터 기획서 자체가 바뀌는 결정이 생기면 이 문서를 갱신 (claude.ai 프로젝트의 동일 문서도 함께 갱신)
