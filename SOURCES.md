# แหล่งที่มาและการตรวจสอบ

โปรเจกต์นี้แยกส่วนที่เขียนเองออกจากส่วนที่ดาวน์โหลดจาก upstream อย่างชัดเจน

## แหล่งที่มาโดยตรง

1. **UDP Custom core**
   - Repository: https://github.com/http-custom/udp-custom
   - ไฟล์ที่ดาวน์โหลด: `bin/udp-custom-linux-amd64`
   - ใช้สำหรับโปรโตคอล UDP Custom ที่ทำงานร่วมกับ HTTP Custom
   - โปรดตรวจสอบ release และ source เองก่อนใช้งานจริง เพราะไบนารีภายนอกไม่ได้ผ่านการ audit โดยผู้จัดทำ repository นี้

2. **สคริปต์ใน repository นี้**
   - `install.sh` และ `udp-manager.sh` เขียนขึ้นสำหรับ repository `Phechr-2025/http-custom`
   - ใช้ Bash, `curl`, `openssl`, `useradd`, `systemd` และ UFW ที่มากับ Linux distribution

## เอกสารทางการของเครื่องมือระบบ

- GNU Bash: https://www.gnu.org/software/bash/manual/
- systemd service units: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
- Linux shadow utilities (`useradd`, `chage`, `usermod`): https://github.com/shadow-maint/shadow
- UFW documentation: https://launchpad.net/ufw
- curl documentation: https://curl.se/docs/

## หมายเหตุด้านความน่าเชื่อถือ

ไม่มีผู้ใดรับรองความปลอดภัยของไบนารีที่ดาวน์โหลดจากอินเทอร์เน็ตได้ 100% ผู้ดูแล VPS ควรตรวจสอบ source, checksum, สิทธิ์ของ service และ log ก่อนใช้งานจริง เมนู **เปิดพอร์ตทุกพอร์ต** มีคำเตือนและต้องยืนยัน เพราะเพิ่มความเสี่ยงต่อการโจมตี VPS
