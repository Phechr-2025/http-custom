#!/usr/bin/env bash
set -Eeuo pipefail

REPO_RAW="https://raw.githubusercontent.com/Phechr-2025/http-custom/main"
MANAGER_PATH="/usr/local/bin/udp"
DATA_DIR="/etc/http-custom-udp"

if [[ $EUID -ne 0 ]]; then
  echo "กรุณารันด้วย root: sudo bash <(curl -fsSL $REPO_RAW/install.sh)" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates openssl
  else
    echo "ไม่พบ curl และระบบนี้ไม่มี apt-get สำหรับติดตั้งอัตโนมัติ" >&2
    exit 1
  fi
fi

mkdir -p "$DATA_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL --retry 3 "$REPO_RAW/udp-manager.sh" -o "$tmp"
if ! grep -q '^#!/usr/bin/env bash' "$tmp"; then
  echo "ไฟล์ manager จาก GitHub ไม่ถูกต้อง" >&2
  exit 1
fi
install -m 0755 "$tmp" "$MANAGER_PATH"

echo "ติดตั้ง UDP Custom Manager เรียบร้อย"
echo "คำสั่งเรียกเมนู: udp"
exec "$MANAGER_PATH"
