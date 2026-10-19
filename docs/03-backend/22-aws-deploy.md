# 22. AWS EC2 배포 스크립트

## 목표
EC2(t4g.small, Ubuntu 24.04 arm64)에 백엔드를 올리고, 이후 재배포를 맥에서 더블클릭 한 번으로.

## 전제 (받은 서버)
- 접속: `ubuntu` + 비밀번호
- 보안그룹 열린 포트: 22, 443, 3000, 3001, 3003, 3306, 3478, 4000, 5173, 5349, 8000, 8081, 8443, 8545, 8546, 8888 (80 없음)

## 결정
- 앱 포트 **8000** HTTP 직결 (80 막혀 있어 Let's Encrypt HTTP 인증 불가 → HTTPS는 도메인 생기면 별도)
- Nginx 생략 — 사용자 10명 이하 시연용, 구성 요소 최소화
- PostgreSQL은 Docker 대신 apt 설치 (메모리 절약, localhost만 리슨)
- 비밀번호 로그인은 키 등록 1회에만 사용. 이후 전부 SSH 키
- 시크릿: DB 비번·JWT는 서버에서 생성, 앱 키는 맥 `.env`를 스크립트가 직접 복사 (화면 출력 없음)

## 구현 파일
- `deploy/aws/common.sh`, `aws-setup.command`, `aws-deploy.command`, `aws-logs.command`
- `deploy/aws/server-setup.sh`
- `deploy/aws/README.md`

## 완료 기준
- `server-setup.sh` 두 번 돌려도 안전 (idempotent)
- 세팅 후 jar 실행 → Flyway 마이그레이션 → `GET /api/news` 200
- Ubuntu 24.04 컨테이너에서 위 흐름 검증 (systemd/swap만 shim)
