#!/usr/bin/env bash
# 서버 백엔드 로그 실시간 보기 (Ctrl+C로 종료)
set -uo pipefail
source "$(dirname "$0")/common.sh"
has_host_config || fail "aws-setup.command 먼저"
ssh -t "$HOST_ALIAS" 'sudo systemctl status newstory --no-pager | head -5; sudo journalctl -u newstory -n 200 -f'
