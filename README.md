# HTTP Custom UDP Manager

สคริปต์ติดตั้งและจัดการ UDP Custom สำหรับแอป **HTTP Custom** บน VPS Linux x86_64/amd64

> ใช้เฉพาะ VPS และบัญชีที่คุณมีสิทธิ์เท่านั้น ระบบ UDP relay อาจใช้แบนด์วิดท์สูง ควรตั้ง firewall และตรวจสอบการใช้งานของ VPS

## ติดตั้งด้วยคำสั่งเดียว

```bash
curl -fsSL https://raw.githubusercontent.com/Phechr-2025/http-custom/main/install.sh | sudo bash
```

หรือแบบที่คง stdin สำหรับเมนูได้ชัดเจน:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/Phechr-2025/http-custom/main/install.sh)
```

หลังติดตั้งเรียกเมนูได้ด้วย:

```bash
sudo udp
```

## เมนูหลัก

1. **อัปเดต** — อัปเดต manager และ UDP core จาก upstream
2. **ถอนการติดตั้ง** — ลบ manager, service และไฟล์ระบบ โดยไม่ลบบัญชีผู้ใช้ในเมนูถอนระบบ UDP
3. **จัดการ user** — เพิ่ม ลบ แสดงรายการ ต่ออายุ และบล็อก/ปลดบล็อกบัญชี
4. **ติดตั้งระบบ UDP** — ดาวน์โหลด UDP Custom core, สร้าง config และ systemd service

## ค่าที่ใช้เริ่มต้น

- พอร์ตเริ่มต้น: `36712/udp` (เปลี่ยนได้ตอนติดตั้ง)
- service: `http-custom-udp.service`
- ไฟล์ core: `/opt/http-custom-udp/udp-custom`
- คำสั่งจัดการ: `/usr/local/bin/udp`

ใน HTTP Custom ให้เลือก **UDP Custom** แล้วใส่ IP ของ VPS, พอร์ตที่เลือก และ username/password ที่สร้างจากเมนูจัดการ user

## ตรวจสอบ service

```bash
systemctl status http-custom-udp --no-pager
journalctl -u http-custom-udp -n 50 --no-pager
ss -lunp | grep 36712
```

## รองรับ

- Ubuntu/Debian ที่มี systemd
- `x86_64` / `amd64`

ARM ยังไม่รองรับในรุ่นนี้ เพราะ core ที่ดาวน์โหลดเป็นไบนารี amd64
