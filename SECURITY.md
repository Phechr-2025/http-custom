# Security review

วันที่ตรวจสอบ: 2026-09-21

## ขอบเขต

ตรวจสอบ `install.sh`, `udp-manager.sh` และ `SOURCES.md` แบบ static review ก่อนเผยแพร่

## ผลการตรวจสอบ

- Bash syntax check ผ่านด้วย `bash -n`
- ไม่พบ `eval`, `base64`, `/dev/tcp`, `nc`, `socat`, `LD_PRELOAD`, persistence ผ่าน cron หรือการแก้ไข `authorized_keys`
- การดาวน์โหลดใช้ HTTPS และ `curl` แบบ fail-on-error พร้อม retry/timeout
- รหัสผ่านถูกแฮชด้วย `openssl passwd -6` ก่อนส่งให้ `useradd`
- การยืนยันตัวตนและการลบระบบมี confirmation prompt
- การรีสตาร์ท VPS ทำผ่าน `systemctl reboot`
- service ใช้ `NoNewPrivileges=true`, จำกัดไฟล์เปิด และทำงานจาก `/opt/http-custom-udp`
- ไม่มีการปิด firewall อัตโนมัติระหว่างติดตั้ง ยกเว้นผู้ใช้เลือกเมนู 5 และยืนยันเอง
- ตรวจสอบ secret scanning ผ่าน GitHub แล้ว แต่ repository นี้ไม่มี GitHub Advanced Security จึงไม่สามารถใช้ GitHub secret-scanning engine ได้

## สิ่งที่ยังรับรองไม่ได้

ไม่สามารถรับรองว่าไบนารี `udp-custom-linux-amd64` ไม่มี malware ได้ 100% เพราะเป็นไฟล์ prebuilt จาก upstream ภายนอกและไม่มี checksum/signature ที่ยืนยันได้ใน repository นี้ การตรวจสอบนี้เป็น static review ของสคริปต์ ไม่ใช่การรับรองความปลอดภัยของไบนารีหรือระบบปฏิบัติการ

ก่อนใช้งาน production ควร:

1. ดาวน์โหลด source และไบนารีจาก upstream ด้วยตนเอง
2. ตรวจสอบ commit, release, checksum หรือ signature ที่ upstream ประกาศ
3. ทดสอบใน VPS ใหม่ที่ไม่มีข้อมูลสำคัญ
4. จำกัดพอร์ตด้วย firewall และไม่ใช้เมนูเปิดทุกพอร์ตถ้าไม่จำเป็น
5. ตรวจสอบ `systemctl status`, `journalctl` และ traffic หลังติดตั้ง

## แหล่งที่มา

ดูรายละเอียด upstream และเอกสารทางการใน [SOURCES.md](SOURCES.md)
