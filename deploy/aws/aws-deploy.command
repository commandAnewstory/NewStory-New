#!/usr/bin/env bash
# [코드 바뀔 때마다] 맥에서 더블클릭. 지금 체크아웃된 코드로 jar 빌드 → 서버 업로드 → 재시작 → 헬스체크
set -uo pipefail
source "$(dirname "$0")/common.sh"

has_host_config && key_login_ok || fail "서버 키 접속 안 됨. aws-setup.command 먼저"
echo "서버: $(server_ip)"

log "1/3 jar 빌드 ($(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD) @ $(git -C "$REPO_DIR" rev-parse --short HEAD))"
cd "$REPO_DIR/backend" || fail "backend 폴더 없음"
rm -f build/libs/*.jar
./gradlew -q bootJar -x test || fail "빌드 실패"
JAR="$(ls build/libs/*.jar 2>/dev/null | grep -v -- '-plain' | head -1)"
[ -n "$JAR" ] || fail "jar 못 찾음"
echo "$JAR ($(du -h "$JAR" | cut -f1))"

log "2/3 업로드 + 재시작 (sudo 비번 물어보면 서버 비번 입력)"
scp -q "$JAR" "$HOST_ALIAS:/tmp/newstory.jar" || fail "업로드 실패"
ssh -t "$HOST_ALIAS" 'sudo install -o newstory -g newstory -m 644 /tmp/newstory.jar /opt/newstory/app.jar \
  && rm -f /tmp/newstory.jar && sudo systemctl restart newstory' || fail "재시작 실패"

log "3/3 헬스체크"
if wait_healthy; then
  log "배포 완료 → 앱 API 주소: http://$(server_ip):$APP_PORT"
  pause_exit 0
fi
echo "응답 없음. 서버 로그 마지막 80줄:"
ssh -t "$HOST_ALIAS" 'sudo journalctl -u newstory -n 80 --no-pager'
fail "서버는 떴는데 응답 없으면 → AWS 보안그룹에 $APP_PORT 열렸는지 확인"
