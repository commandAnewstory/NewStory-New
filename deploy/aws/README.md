# AWS 배포 (EC2 t4g.small, Ubuntu 24.04 arm64)

맥에서 `.command` 더블클릭으로 끝나게 만든 스크립트. 서버 IP·비번·키 값은 레포에 안 남는다.

| 파일 | 언제 | 하는 일 |
|---|---|---|
| `aws-setup.command` | 처음 한 번 | SSH 키 등록(서버 비번 1회 입력) → `.env` 앱 키 업로드 → `server-setup.sh` 실행 |
| `aws-deploy.command` | 코드 바뀔 때마다 | 현재 체크아웃 코드로 jar 빌드 → 업로드 → 재시작 → 헬스체크 |
| `aws-logs.command` | 문제 생기면 | 서버 로그 실시간 |
| `server-setup.sh` | (setup이 서버에서 실행) | swap 2GB, Java 21, PostgreSQL, DB 계정, env 파일, systemd |

## 구조

```
앱 ──HTTP:8000──▶ Spring Boot (systemd: newstory, prod 프로필)
                     └─▶ PostgreSQL 16 (localhost:5432, 외부 비공개)
```

- 포트 8000: 받은 보안그룹에 80이 없고 8000이 열려 있어서. 5432는 열지 않는다.
- 접속 정보: 맥 `~/.ssh/config`의 `newstory-aws` 항목 + 키 `~/.ssh/newstory_aws`
- 서버 env: `/etc/newstory/newstory.env` (root 600). DB 비번·JWT 시크릿은 서버에서 자동 생성, 앱 키는 레포 `.env`에서 DB/JWT 줄만 빼고 복사
- 앱 jar: `/opt/newstory/app.jar`, 힙 최대 768MB (+ swap 2GB)

## 자주 쓰는 명령 (서버)

```bash
ssh newstory-aws
sudo systemctl status newstory
sudo journalctl -u newstory -n 200 -f
sudo nano /etc/newstory/newstory.env && sudo systemctl restart newstory   # 키 수정
```

## 앱 연결

APK를 `--dart-define=API_BASE_URL=http://<서버IP>:8000`으로 빌드.
Dart HTTP 클라이언트는 Android cleartext 정책을 안 타서 HTTP 그대로 동작한다.

## HTTPS (나중에)

80번 포트가 막혀 있어서 Let's Encrypt HTTP 인증 불가. 필요하면 도메인 + Cloudflare 프록시(443) 또는 DNS 인증으로.
