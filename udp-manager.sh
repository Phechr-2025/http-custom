#!/usr/bin/env bash
set -Eeuo pipefail

RAW='https://raw.githubusercontent.com/Phechr-2025/http-custom/main'
CORE='https://raw.githubusercontent.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64'
BASE=/opt/http-custom-udp; DATA=/etc/http-custom-udp; BIN=$BASE/udp-custom
CFG=$BASE/config.json; UNIT=/etc/systemd/system/http-custom-udp.service
MGR=/usr/local/bin/udp; DB=$DATA/users.db; PORT=36712

root(){ [[ $EUID == 0 ]] || { echo 'ต้องใช้สิทธิ์ root'; exit 1; }; }
tty(){ printf '%s' "$1" >&2; IFS= read -r REPLY </dev/tty || exit 0; }
pause(){ tty '\nกด Enter เพื่อกลับ... '; }
setup(){ install -d -m755 "$BASE" "$DATA"; touch "$DB"; chmod 600 "$DB"; }
port_ok(){ [[ $1 =~ ^[0-9]+$ ]] && ((10#$1>0 && 10#$1<65536)); }
user_ok(){ [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{2,31}$ && $1 != root ]]; }
managed(){ awk -F'|' -v u="$1" '$1==u{ok=1}END{exit !ok}' "$DB" 2>/dev/null; }
getport(){ [[ -f $CFG ]] && sed -nE 's/.*"listen"[[:space:]]*:[[:space:]]*":([0-9]+)".*/\1/p' "$CFG"|head -1; }

install_udp(){
 setup; local p old tmp
 old="$(getport || true)"; p="${old:-$PORT}"
 while :; do tty "พอร์ต UDP [$p]: "; [[ -n $REPLY ]] && p=$REPLY; port_ok "$p" && break; echo 'พอร์ตต้องเป็น 1-65535'; done
 echo 'กำลังดาวน์โหลด UDP Custom core...'; tmp=$(mktemp)
 if ! curl -fL --retry 3 --connect-timeout 15 "$CORE" -o "$tmp"; then rm -f "$tmp"; echo 'ดาวน์โหลดไม่สำเร็จ'; pause; return; fi
 install -m755 "$tmp" "$BIN"; rm -f "$tmp"
 cat >"$CFG" <<EOF
{
  "listen": ":$p",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": { "mode": "passwords" }
}
EOF
 cat >"$UNIT" <<EOF
[Unit]
Description=HTTP Custom UDP server
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User=root
WorkingDirectory=$BASE
ExecStart=$BIN server
Restart=always
RestartSec=3
LimitNOFILE=1048576
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
 systemctl daemon-reload; systemctl enable --now http-custom-udp.service
 if command -v ufw >/dev/null && ufw status 2>/dev/null|grep -q 'Status: active'; then ufw allow "$p/udp" >/dev/null||true; fi
 if systemctl is-active --quiet http-custom-udp; then echo "ติดตั้งสำเร็จ: UDP $p/udp"; else echo 'service ไม่ทำงาน ดู log ด้วย journalctl -u http-custom-udp'; fi
 pause
}

update(){
 setup; local t; t=$(mktemp)
 if curl -fsSL --retry 3 "$RAW/udp-manager.sh" -o "$t" && grep -q '^#!/usr/bin/env bash' "$t"; then install -m755 "$t" "$MGR"; echo 'อัปเดต manager แล้ว'; else echo 'อัปเดต manager ไม่สำเร็จ'; fi; rm -f "$t"
 if [[ -x $BIN ]]; then local p; p="$(getport||true)"; install_udp_with_port "${p:-$PORT}"; else echo 'ยังไม่ได้ติดตั้งระบบ UDP — ใช้เมนู 4'; pause; fi
}
install_udp_with_port(){
 local p=$1 t; t=$(mktemp); echo 'กำลังอัปเดต UDP core...'
 if curl -fL --retry 3 --connect-timeout 15 "$CORE" -o "$t"; then install -m755 "$t" "$BIN"; rm -f "$t"; sed -i "s/\"listen\": \"[^\"]*\"/\"listen\": \":$p\"/" "$CFG"; systemctl restart http-custom-udp.service; echo 'อัปเดต UDP core แล้ว'; else rm -f "$t"; echo 'อัปเดต core ไม่สำเร็จ'; fi
 pause
}

add(){
 setup; local u pw pw2 d e h; tty 'ชื่อผู้ใช้: '; u=$REPLY
 if ! user_ok "$u" || id "$u" >/dev/null 2>&1 || managed "$u"; then echo 'ชื่อไม่ถูกต้องหรือมีผู้ใช้นี้แล้ว'; pause; return; fi
 tty 'รหัสผ่าน: '; pw=$REPLY; tty 'ยืนยันรหัสผ่าน: '; pw2=$REPLY
 [[ -n $pw && $pw == "$pw2" ]] || { echo 'รหัสผ่านไม่ตรงกัน'; pause; return; }
 tty 'อายุบัญชี (วัน) [30]: '; d=${REPLY:-30}
 [[ $d =~ ^[0-9]+$ && d -ge 1 && d -le 3650 ]] || { echo 'วันต้องอยู่ระหว่าง 1-3650'; pause; return; }
 e=$(date -d "+$d days" +%F); h=$(printf '%s' "$pw"|openssl passwd -6 -stdin)
 if useradd -M -s /usr/sbin/nologin -e "$e" -p "$h" "$u"; then printf '%s|%s|%s\n' "$u" "$e" "$(date +%F)" >>"$DB"; echo "สร้าง $u สำเร็จ หมดอายุ $e"; else echo 'สร้าง user ไม่สำเร็จ'; fi; pause
}
list(){ setup; printf '%-24s %-12s %-10s\n' USERNAME EXPIRES STATUS; while IFS='|' read -r u e _; do [[ -z $u ]]&&continue; local s=ACTIVE; id "$u" >/dev/null 2>&1||s=MISSING; passwd -S "$u" 2>/dev/null|awk '{print $2}'|grep -q '^L'&&s=BLOCKED; [[ $e < $(date +%F) ]]&&s=EXPIRED; printf '%-24s %-12s %-10s\n' "$u" "$e" "$s"; done <"$DB"; pause; }
pick(){ tty 'ชื่อผู้ใช้: '; U=$REPLY; managed "$U" || { echo 'ไม่พบ user ที่จัดการ'; return 1; }; }
remove(){ setup; pick||{ pause;return; }; tty "พิมพ์ REMOVE เพื่อลบ $U: "; [[ $REPLY == REMOVE ]]||{ echo ยกเลิก;pause;return; }; pkill -u "$U" 2>/dev/null||true; userdel "$U" 2>/dev/null||true; awk -F'|' -v u="$U" '$1!=u' "$DB">"$DB.tmp"; mv "$DB.tmp" "$DB"; echo "ลบ $U แล้ว"; pause; }
renew(){ setup; pick||{ pause;return; }; local d e; tty 'ต่ออายุเป็นวัน [30]: '; d=${REPLY:-30}; [[ $d =~ ^[0-9]+$ && $d -le 3650 && $d -gt 0 ]]||{ echo 'จำนวนวันไม่ถูกต้อง';pause;return; }; e=$(date -d "+$d days" +%F); chage -E "$e" "$U"; awk -F'|' -vOFS='|' -v u="$U" -v e="$e" '$1==u{$2=e}{print}' "$DB">"$DB.tmp";mv "$DB.tmp" "$DB";echo "ต่ออายุ $U ถึง $e";pause; }
toggle(){ setup;pick||{pause;return;}; if passwd -S "$U"|awk '{print $2}'|grep -q '^L';then usermod -U "$U";echo 'ปลดบล็อกแล้ว';else pkill -u "$U" 2>/dev/null||true;usermod -L "$U";echo 'บล็อกแล้ว';fi;pause; }
users(){ while :; do clear; echo '=== จัดการ user ==='; echo '1. เพิ่ม user';echo '2. ลบ user';echo '3. แสดงรายการ user';echo '4. ต่ออายุ user';echo '5. บล็อก/ปลดบล็อก user';echo '0. กลับ';tty 'เลือก: ';case $REPLY in 1)add;;2)remove;;3)list;;4)renew;;5)toggle;;0)return;;*)echo 'ไม่ถูกต้อง';sleep 1;;esac;done; }
uninstall(){ local p; tty 'พิมพ์ REMOVE เพื่อถอนทุกอย่าง: '; [[ $REPLY == REMOVE ]]||{ echo ยกเลิก;pause;return; };p="$(getport||true)";systemctl disable --now http-custom-udp.service 2>/dev/null||true;rm -f "$UNIT";systemctl daemon-reload;[[ -n $p ]]&&command -v ufw >/dev/null&&ufw delete allow "$p/udp" >/dev/null||true;rm -rf "$BASE" "$DATA" "$MGR";echo 'ถอนการติดตั้งแล้ว';exit 0;}
main(){ root;setup;while :;do clear;echo '================================';echo ' HTTP Custom UDP Manager';echo '================================';systemctl is-active --quiet http-custom-udp&&echo 'สถานะ: RUNNING'||echo 'สถานะ: STOPPED / ยังไม่ติดตั้ง';echo;echo '1. อัปเดต';echo '2. ถอนการติดตั้ง';echo '3. จัดการ user';echo '4. ติดตั้งระบบ UDP';echo '0. ออก';tty 'เลือกเมนู: ';case $REPLY in 1)update;;2)uninstall;;3)users;;4)install_udp;;0)exit 0;;*)echo 'ไม่ถูกต้อง';sleep 1;;esac;done;}
main
