#!/usr/bin/env bash
# 서버(Ubuntu 24.04 arm64)에서 sudo로 한 번 실행하는 초기 세팅.
# 여러 번 돌려도 안전하게(idempotent) 짰다. 이미 된 단계는 건너뛴다.
#   - swap 2GB
#   - Java 21, PostgreSQL 16 (localhost만 리슨)
#   - DB 계정/비번 자동 생성 (비번은 서버 밖으로 안 나감)
#   - /etc/newstory/newstory.env (root 전용) + systemd 서비스
set -euo pipefail

APP_PORT="${APP_PORT:-8000}"
ENV_DIR=/etc/newstory
ENV_FILE=$ENV_DIR/newstory.env
APP_DIR=/opt/newstory
UPLOADED_ENV=/tmp/newstory-app.env   # 맥에서 올린 앱 키(.env에서 DB/JWT 줄 뺀 것). 없으면 건너뜀

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "sudo로 실행해야 함"; exit 1; }

log "swap 2GB"
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
swapon --show

log "패키지 설치 (Java 21, PostgreSQL)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq openjdk-21-jre-headless postgresql curl >/dev/null
java -version 2>&1 | head -1
timedatectl set-timezone Asia/Seoul 2>/dev/null || true

log "앱 계정/폴더"
id newstory >/dev/null 2>&1 || useradd --system --home "$APP_DIR" --shell /usr/sbin/nologin newstory
mkdir -p "$APP_DIR" "$ENV_DIR"
chown newstory:newstory "$APP_DIR"
chmod 700 "$ENV_DIR"

log "DB 계정/DB"
systemctl enable --now postgresql >/dev/null
if [ ! -f "$ENV_FILE" ] || ! grep -q '^SPRING_DATASOURCE_PASSWORD=' "$ENV_FILE"; then
  DB_PASS="$(openssl rand -hex 24)"
  JWT="$(openssl rand -hex 48)"
  if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='newstory'" | grep -q 1; then
    sudo -u postgres psql -qc "ALTER ROLE newstory WITH LOGIN PASSWORD '$DB_PASS'"
  else
    sudo -u postgres psql -qc "CREATE ROLE newstory WITH LOGIN PASSWORD '$DB_PASS'"
  fi
  {
    echo "# 자동 생성 — 서버 밖으로 꺼내지 말 것"
    echo "SPRING_PROFILES_ACTIVE=prod"
    echo "SERVER_PORT=$APP_PORT"
    echo "SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/newstory"
    echo "SPRING_DATASOURCE_USERNAME=newstory"
    echo "SPRING_DATASOURCE_PASSWORD=$DB_PASS"
    echo "JWT_SECRET=$JWT"
  } > "$ENV_FILE"
  unset DB_PASS JWT
fi
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='newstory'" | grep -q 1 \
  || sudo -u postgres createdb -O newstory newstory
echo "DB OK"

if [ -f "$UPLOADED_ENV" ]; then
  log "앱 키 반영 (Claude API, 소셜 로그인 등)"
  # 같은 키가 이미 있으면 교체, 없으면 추가. DB/JWT/포트는 위에서 만든 값 유지
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    key="${line%%=*}"
    case "$key" in
      SPRING_DATASOURCE_*|JWT_SECRET|SPRING_PROFILES_ACTIVE|SERVER_PORT) continue ;;
    esac
    grep -v "^${key}=" "$ENV_FILE" > "$ENV_FILE.tmp" || true
    printf '%s\n' "$line" >> "$ENV_FILE.tmp"
    mv "$ENV_FILE.tmp" "$ENV_FILE"
  done < "$UPLOADED_ENV"
  shred -u "$UPLOADED_ENV" 2>/dev/null || rm -f "$UPLOADED_ENV"
fi
chmod 600 "$ENV_FILE"
echo "env 키 목록 (값은 안 보여줌):"
sed 's/=.*//' "$ENV_FILE" | grep -v '^#' | sed 's/^/  - /'

log "systemd 서비스"
cat > /etc/systemd/system/newstory.service <<UNIT
[Unit]
Description=NewStory backend
After=network-online.target postgresql.service
Wants=network-online.target
Requires=postgresql.service

[Service]
User=newstory
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=/usr/bin/java -Xms256m -Xmx768m -XX:+UseSerialGC -jar $APP_DIR/app.jar
SuccessExitStatus=143
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable newstory >/dev/null

if command -v ufw >/dev/null && ufw status | grep -q 'Status: active'; then
  log "ufw 켜져 있음 → $APP_PORT 허용"
  ufw allow "$APP_PORT/tcp" >/dev/null
fi

if [ -f "$APP_DIR/app.jar" ]; then
  systemctl restart newstory
  echo "기존 jar로 재시작"
else
  echo "jar 아직 없음 → aws-deploy 돌리면 올라감"
fi

log "세팅 끝"
