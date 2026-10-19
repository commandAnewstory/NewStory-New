# 맥에서 쓰는 aws-*.command 공통 부분. 직접 실행하지 말 것.
# 서버 접속 정보는 ~/.ssh/config 의 "newstory-aws" 항목에만 저장한다 (레포에 IP·비번 안 남김).

HOST_ALIAS=newstory-aws
KEY_FILE="$HOME/.ssh/newstory_aws"
APP_PORT=8000
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 스크립트 위치에서 위로 올라가며 레포 루트(backend/gradlew 있는 곳)를 찾는다 → 어느 폴더에 복사해도 동작
REPO_DIR="$SCRIPT_DIR"
while [ "$REPO_DIR" != "/" ] && [ ! -x "$REPO_DIR/backend/gradlew" ]; do REPO_DIR="$(dirname "$REPO_DIR")"; done

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m[실패] %s\033[0m\n' "$*"; pause_exit 1; }
pause_exit() { echo; read -r -p "엔터 누르면 창 닫힘 " _; exit "${1:-0}"; }

server_ip() { ssh -G "$HOST_ALIAS" 2>/dev/null | awk '/^hostname /{print $2}'; }

has_host_config() { [ -f "$HOME/.ssh/config" ] && grep -q "^Host $HOST_ALIAS\$" "$HOME/.ssh/config"; }

# ~/.ssh/config 에 newstory-aws 항목이 없으면 IP를 물어서 추가
ensure_host_config() {
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  if has_host_config; then
    echo "서버: $(server_ip) (~/.ssh/config 의 $HOST_ALIAS)"
    return
  fi
  read -r -p "서버 IP 입력: " ip
  [ -n "$ip" ] || fail "IP 비어있음"
  read -r -p "접속 유저 [ubuntu]: " user
  user="${user:-ubuntu}"
  {
    echo ""
    echo "Host $HOST_ALIAS"
    echo "  HostName $ip"
    echo "  User $user"
    echo "  IdentityFile $KEY_FILE"
    echo "  ServerAliveInterval 30"
  } >> "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  echo "~/.ssh/config 에 $HOST_ALIAS 추가함"
}

# 키 로그인 되는지 확인 (비번 안 물어보게 BatchMode)
key_login_ok() { ssh -o BatchMode=yes -o ConnectTimeout=8 "$HOST_ALIAS" true 2>/dev/null; }

# 서버 헬스체크: 맥에서 공개 포트로 직접 찔러서 보안그룹까지 같이 확인
wait_healthy() {
  local url="http://$(server_ip):$APP_PORT/api/news?size=1"
  printf '서버 뜨는 중'
  for _ in $(seq 1 60); do
    if curl -fsS -m 4 "$url" >/dev/null 2>&1; then
      printf '\n\033[1;32m[OK] %s 응답함\033[0m\n' "$url"
      return 0
    fi
    printf '.'; sleep 3
  done
  echo
  return 1
}
