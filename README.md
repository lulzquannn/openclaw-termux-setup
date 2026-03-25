# 🦞 OpenClaw Termux Auto Setup

Cài đặt **OpenClaw** (Personal AI Assistant) trên Android qua **Termux** chỉ với 1 lệnh duy nhất.

Biến điện thoại cũ thành server AI cá nhân — truy cập Web UI **từ bất kỳ đâu** qua Cloudflare Tunnel.

## ⚡ Cài đặt (1 lệnh)

Mở **Termux** và paste:

```bash
curl -fsSL https://raw.githubusercontent.com/lulzquannn/openclaw-termux-setup/master/setup.sh | bash
```

> ⚠️ **Phải cài Termux từ [F-Droid](https://f-droid.org/)**, KHÔNG dùng Google Play Store (bản cũ, lỗi).

## 📋 Script tự động làm gì?

| Bước | Mô tả |
|------|-------|
| 1 | Update & upgrade Termux packages |
| 2 | Cài Node.js, Git, tmux, cronie, termux-api |
| 3 | Cài OpenClaw (`npm i -g openclaw@latest`) |
| 4 | Cài **Cloudflare Tunnel** (cloudflared) — tạo URL public miễn phí |
| 5 | Bật wake-lock (chống Android kill process) |
| 6 | Tạo auto-start script (Termux:Boot) |
| 7 | Tạo helper scripts (start/stop/status/url/restart) |
| 8 | Tạo config mặc định (bind 0.0.0.0) |

## 🚀 Sau khi cài xong

### Bước 1: Chạy onboard (lần đầu)
```bash
openclaw onboard
```
Nó sẽ hỏi bạn API key (Anthropic/OpenAI) và setup Telegram/WhatsApp bot.

### Bước 2: Start gateway + tunnel
```bash
~/openclaw-start.sh
```

### Bước 3: Lấy URL public
```bash
~/openclaw-url.sh
```

Bạn sẽ nhận được URL dạng:
```
https://random-name.trycloudflare.com
```

**Mở URL này trên bất kỳ trình duyệt nào, ở bất kỳ đâu — không cần chung WiFi!**

## 🌐 Cách truy cập

| Cách | URL | Yêu cầu |
|------|-----|---------|
| **Public (từ bất kỳ đâu)** | `https://xxxxx.trycloudflare.com` | Không cần gì |
| **LAN (cùng WiFi)** | `http://<IP-điện-thoại>:18789` | Cùng mạng WiFi |

## 🎮 Helper Commands

| Lệnh | Chức năng |
|-------|-----------|
| `~/openclaw-start.sh` | Khởi động Gateway + Tunnel |
| `~/openclaw-stop.sh` | Dừng tất cả |
| `~/openclaw-restart.sh` | Restart tất cả |
| `~/openclaw-status.sh` | Xem trạng thái đầy đủ |
| `~/openclaw-url.sh` | Lấy URL public hiện tại |
| `tmux attach -t openclaw` | Xem gateway logs |
| `tmux attach -t tunnel` | Xem tunnel logs |
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

## 💰 Chi phí

| Thành phần | Chi phí |
|------------|---------|
| OpenClaw | **Miễn phí** (open-source) |
| Cloudflare Tunnel | **Miễn phí** |
| API key (Claude Haiku / GPT-4o-mini) | ~$0.01-0.05/ngày |
| Google Gemini Flash | Có **free tier** |

## 📁 Cấu trúc file

```
~/.openclaw/
├── openclaw.json          # Config chính
├── workspace/             # Skills, prompts
└── credentials/           # Channel credentials

~/
├── openclaw-start.sh      # Start gateway + tunnel
├── openclaw-stop.sh       # Stop everything
├── openclaw-restart.sh    # Restart everything
├── openclaw-status.sh     # Check status
├── openclaw-url.sh        # Get public URL
├── tunnel.log             # Tunnel log (auto-created)
├── tunnel-url.txt         # Saved public URL
└── .termux/boot/
    └── start-openclaw.sh  # Auto-start on boot
```

## ⚠️ Lưu ý

- 🔄 **URL public thay đổi** mỗi khi restart tunnel (Cloudflare free tier). Chạy `~/openclaw-url.sh` để lấy URL mới.
- ❌ Không có browser control (Playwright không hỗ trợ Android)
- ⚠️ Nóng máy nếu chạy lâu — để nơi thoáng, cắm sạc
- ✅ Chat, email, calendar, skills, cron jobs hoạt động bình thường
- ✅ Web UI / WebChat hoạt động
- ✅ Telegram, WhatsApp, Discord... hoạt động
- ✅ Truy cập từ bất kỳ đâu qua Cloudflare Tunnel

## 🔗 Links

- [OpenClaw Website](https://openclaw.ai)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [CrawBot Desktop App](https://crawbot.net)
- [ClawHub Skills](https://clawhub.ai)
- [Discord Community](https://discord.gg/clawd)

## 📄 License

MIT — Sử dụng thoải mái!
