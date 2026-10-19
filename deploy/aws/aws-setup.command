#!/usr/bin/env bash
# [처음 한 번] 맥에서 더블클릭. 서버 비번은 이 터미널에 네가 직접 입력.
#  1) SSH 키 만들고 서버에 등록 → 이후엔 비번 없이 키로 접속
#  2) 레포 .env 의 앱 키(Claude API, 소셜 로그인)를 서버로 복사 (DB/JWT 줄은 빼고, 서버가 새로 생성)
#  3) 서버 초기 세팅 (swap, Java 21, PostgreSQL, systemd)
set -uo pipefail
source "$(dirname "$0")/common.sh"
[ -x "$REPO_DIR/backend/gradlew" ] || fail "레포 루트 못 찾음"

log "1/4 서버 접속 정보"
ensure_host_config

log "2/4 SSH 키"
if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "newstory-deploy" -q
  echo "키 생성: $KEY_FILE"
fi
if key_login_ok; then
  echo "이미 키로 접속됨"
else
  echo "서버 비번 한 번만 입력 (키 등록용)"
  ssh -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new "$HOST_ALIAS" \
    'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys' < "$KEY_FILE.pub" \
    || fail "키 등록 실패 (IP/비번/22번 포트 확인)"
  key_login_ok || fail "키 등록했는데 키 로그인 안 됨"
  echo "키 등록 완료. 이제 비번 없이 접속됨"
fi

log "3/4 앱 키 업로드"
if [ -f "$REPO_DIR/.env" ]; then
  # 값은 화면에 안 찍음. 서버 /tmp 에 600 권한으로 올리고, 세팅 스크립트가 반영 후 지움
  grep -Ev '^(SPRING_DATASOURCE_|JWT_SECRET|SPRING_PROFILES_ACTIVE|SERVER_PORT)' "$REPO_DIR/.env" \
    | ssh "$HOST_ALIAS" 'umask 077; cat > /tmp/newstory-app.env' || fail ".env 업로드 실패"
  echo "올린 키: $(grep -Ev '^(#|$|SPRING_DATASOURCE_|JWT_SECRET|SPRING_PROFILES_ACTIVE|SERVER_PORT)' "$REPO_DIR/.env" | sed 's/=.*//' | tr '\n' ' ')"
else
  echo "레포에 .env 없음 → 건너뜀. 나중에 서버에서 sudo nano /etc/newstory/newstory.env 로 직접 넣기"
fi

log "4/4 서버 세팅 (sudo 비번 물어보면 서버 비번 입력)"
scp -q "$SCRIPT_DIR/server-setup.sh" "$HOST_ALIAS:/tmp/newstory-server-setup.sh" || fail "스크립트 업로드 실패"
ssh -t "$HOST_ALIAS" "sudo APP_PORT=$APP_PORT bash /tmp/newstory-server-setup.sh; rm -f /tmp/newstory-server-setup.sh" \
  || fail "서버 세팅 실패 (위 로그 확인)"

log "끝. 다음: aws-deploy.command"
pause_exit 0
