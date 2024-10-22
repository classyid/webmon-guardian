# Nama Repository
webmon-guardian

# About Description
🔍 WebMon Guardian - Tool monitoring website untuk deteksi konten berbahaya dan judi online. Dibuat dengan bash script, mendukung notifikasi Telegram & WhatsApp.

# README.md
# WebMon Guardian
### Sistem Monitoring Website Otomatis

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Bash](https://img.shields.io/badge/bash-%23121011.svg?logo=gnu-bash&logoColor=white)

## 📑 Deskripsi
WebMon Guardian adalah tool monitoring otomatis yang dirancang untuk membantu administrator sistem dan pengelola website dalam mendeteksi konten berbahaya, khususnya konten judi online yang mungkin menyusup ke website mereka. Tool ini menggunakan teknik crawling cerdas dan sistem notifikasi real-time melalui Telegram dan WhatsApp.

## 🌟 Fitur Utama
- ✅ Monitoring multi-domain secara paralel
- ✅ Deteksi kata kunci judi online dan konten berbahaya
- ✅ Notifikasi real-time via Telegram & WhatsApp
- ✅ Logging aktivitas terstruktur
- ✅ Pembersihan cache & cookies otomatis
- ✅ Mode anonymous untuk keamanan
- ✅ Sistem retry untuk koneksi tidak stabil

## 🛠️ Prasyarat
Sebelum menggunakan WebMon Guardian, pastikan sistem Anda telah memiliki:
```bash
# Install paket yang diperlukan
sudo apt-get update
sudo apt-get install lynx curl jq bc

# Clone repository
git clone https://github.com/username/webmon-guardian.git
cd webmon-guardian

# Set permission
chmod +x monitoring_script.sh
```

## ⚙️ Konfigurasi
1. Salin file `.env.example` ke `.env`
```bash
cp .env.example .env
```

2. Edit file `.env` dan sesuaikan dengan konfigurasi Anda:
```bash
# Konfigurasi Telegram
TELEGRAM_TOKEN="your_telegram_token"
CHAT_ID="your_chat_id"

# Konfigurasi WhatsApp
WA_API_KEY="your_wa_api_key"
SENDER="your_sender_number"
NUMBER="your_receiver_number"
```

## 🚀 Cara Penggunaan
```bash
./monitoring_script.sh
```

## 📊 Output
Tool akan menghasilkan:
- File log aktivitas (`search_script.log`)
- Hasil pencarian dalam folder `results/[tanggal]`
- Notifikasi real-time ke Telegram & WhatsApp

## 📝 Lisensi
MIT License

## 🤝 Kontribusi
Kontribusi selalu disambut baik! Silakan buat pull request atau laporkan issues.
