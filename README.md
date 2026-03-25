# 🦞 OpenClaw Termux Auto Setup

Cài đặt **OpenClaw** (Personal AI Assistant) trên Android qua **Termux** chỉ với 1 lệnh duy nhất.

Biến điện thoại cũ thành server AI cá nhân — truy cập Web UI từ trình duyệt bất kỳ.

## ⚡ Cài đặt (1 lệnh)

Mở **Termux** và paste:

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB>/openclaw-termux-setup/main/setup.sh | bash
```

> ⚠️ **Phải cài Termux từ [F-Droid](https://f-droid.org/)**, KHÔNG dùng Google Play Store (bản cũ, lỗi).

## 📋 Script tự động làm gì?

| Bước | Mô tả |
|------|-------|
| 1 | Update & upgrade Termux packages |
| 2 | Cài Node.js, Git, tmux, cronie, termux-api |
| 3 | Cài OpenClaw (`npm i -g openclaw@latest`) |
| 4 | Bật wake-lock (chống Android kill process) |
| 5 | Tạo auto-start script (Termux:Boot) |
| 6 | Tạo helper scripts (start/stop/status) |
| 7 | Tạo config mặc định (bind 0.0.0.0 cho LAN) |

## 🚀 Sau khi cài xong

### Bước 1: Chạy onboard (lần đầu)
```bash
openclaw onboard
```
Nó sẽ hỏi bạn API key (Anthropic/OpenAI) và setup Telegram/WhatsApp bot.

### Bước 2: Start gateway
```bash
~/openclaw-start.sh
```

### Bước 3: Mở Web UI
Từ máy tính/điện thoại khác **cùng WiFi**, mở trình duyệt:
```
http://<IP-điện-thoại>:18789
```

Kiểm tra IP bằng:
```bash
~/openclaw-status.sh
```

## 🎮 Helper Commands

| Lệnh | Chức năng |
|-------|-----------|
| `~/openclaw-start.sh` | Khởi động OpenClaw Gateway |
| `~/openclaw-stop.sh` | Dừng OpenClaw |
| `~/openclaw-status.sh` | Xem trạng thái + IP + URL |
| `tmux attach -t openclaw` | Xem logs realtime |
| `Ctrl+B` rồi `D` | Thoát tmux (giữ chạy nền) |

## 📱 Cấu hình MIUI / Android để chạy 24/7

### Tắt Battery Optimization
- `Cài đặt` → `Ứng dụng` → `Termux` → `Pin` → **Không hạn chế**

### Khóa Termux trong Recent Apps
- Mở Recent Apps → Vuốt xuống trên Termux → Nhấn icon 🔒

### Giữ WiFi luôn bật
- `Cài đặt` → `WiFi` → `Nâng cao` → **Luôn bật WiFi khi ngủ**

### Auto-start khi reboot
- Cài **Termux:Boot** từ F-Droid
- Script auto-start đã được tạo sẵn tại `~/.termux/boot/`

## 💰 Chi phí API

OpenClaw miễn phí, nhưng cần API key để gọi model AI:

| Model | Chi phí ước tính |
|-------|-----------------|
| Claude 3.5 Haiku | ~$0.01-0.05/ngày |
| GPT-4o-mini | ~$0.01-0.05/ngày |
| Google Gemini Flash | Có free tier |

## 📁 Cấu trúc file

```
~/.openclaw/
├── openclaw.json          # Config chính
├── workspace/             # Skills, prompts
│   ├── AGENTS.md
│   ├── SOUL.md
│   └── skills/
└── credentials/           # Channel credentials

~/
├── openclaw-start.sh      # Start script
├── openclaw-stop.sh       # Stop script
├── openclaw-status.sh     # Status script
└── .termux/boot/
    └── start-openclaw.sh  # Auto-start on boot
```

## ⚠️ Hạn chế khi chạy trên Android

- ❌ Không có browser control (Playwright không hỗ trợ Android)
- ❌ Android có thể kill process nếu không config đúng
- ⚠️ Nóng máy nếu chạy lâu — để nơi thoáng, cắm sạc
- ✅ Chat, email, calendar, skills, cron jobs hoạt động bình thường
- ✅ Web UI / WebChat hoạt động
- ✅ Telegram, WhatsApp, Discord... hoạt động

## 🔗 Links

- [OpenClaw Website](https://openclaw.ai)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [CrawBot Desktop App](https://crawbot.net)
- [ClawHub Skills](https://clawhub.ai)
- [Discord Community](https://discord.gg/clawd)

## 📄 License

MIT — Sử dụng thoải mái!
