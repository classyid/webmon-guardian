#!/bin/bash

# Load environment variables dari file .env
if [ -f .env ]; then
    source .env
else
    echo "Error: File .env tidak ditemukan"
    echo "Membuat template .env..."
    cat > .env << EOL
# Konfigurasi Telegram
TELEGRAM_TOKEN="your_telegram_token"
CHAT_ID="your_chat_id"

# Konfigurasi WhatsApp
WA_API_KEY="your_wa_api_key"
SENDER="your_sender_number"
NUMBER="your_receiver_number"

# Konfigurasi Pencarian
ENABLE_TELEGRAM=true
ENABLE_WHATSAPP=true
SEARCH_DELAY=30
MAX_RETRIES=3
CONCURRENT_LIMIT=2
EOL
    exit 1
fi

# Fungsi logging
log() {
    local level=$1
    shift
    local message=$@
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "search_script.log"
    echo "[$timestamp] [$level] $message"
}

# Fungsi untuk memeriksa dependensi
check_dependencies() {
    local deps=("lynx" "curl" "jq" "bc")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log "ERROR" "Dependencies tidak ditemukan: ${missing[*]}"
        log "INFO" "Silakan install dengan: sudo apt-get install ${missing[*]}"
        exit 1
    fi
}

# Fungsi untuk membersihkan cache dan cookies Lynx
cleanup_lynx() {
    # Membersihkan cookies
    rm -f ~/.lynx/cookies.txt 2>/dev/null
    rm -f ~/.lynx-cookies 2>/dev/null
    
    # Membersihkan cache
    rm -f ~/.lynx/cache/* 2>/dev/null
    
    # Membersihkan history
    rm -f ~/.lynx/history 2>/dev/null
    rm -f ~/.lynx_history 2>/dev/null
    
    # Membersihkan bookmarks
    rm -f ~/.lynx/bookmarks.html 2>/dev/null
    
    # Membuat direktori jika tidak ada
    mkdir -p ~/.lynx
}

# Fungsi untuk format timestamp
format_timestamp() {
    local timestamp=$1
    local date_part=$(echo $timestamp | cut -d'_' -f1)
    local time_part=$(echo $timestamp | cut -d'_' -f2)
    local formatted_time=$(echo $time_part | sed 's/.\{2\}/&:/g' | sed 's/:$//')
    date -d "$date_part $formatted_time" "+%d %B %Y %H:%M:%S"
}

# Fungsi untuk mengirim ke Telegram dengan retry
send_telegram() {
    local file=$1
    local raw_caption=$2
    local retry_count=0
    
    local caption=$(printf "%b" "$raw_caption")
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if curl --silent --show-error --fail \
            -F "chat_id=$CHAT_ID" \
            -F "caption=$caption" \
            -F "document=@$file" \
            "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" > /dev/null; then
            log "INFO" "Berhasil mengirim file ke Telegram"
            return 0
        else
            retry_count=$((retry_count + 1))
            log "WARNING" "Gagal mengirim ke Telegram. Mencoba ulang ($retry_count/$MAX_RETRIES)..."
            sleep 5
        fi
    done
    
    log "ERROR" "Gagal mengirim ke Telegram setelah $MAX_RETRIES percobaan"
    return 1
}

# Fungsi untuk mengirim ke WhatsApp dengan retry
send_whatsapp() {
    local message=$1
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        local response=$(curl --silent --show-error --fail -X POST \
            "https://url-mpedia/send-message" \
            -H "Content-Type: application/json" \
            -d '{
                "api_key": "'"$WA_API_KEY"'",
                "sender": "'"$SENDER"'",
                "number": "'"$NUMBER"'",
                "message": "'"$message"'"
            }')
        
        if [ $? -eq 0 ]; then
            log "INFO" "Berhasil mengirim pesan WhatsApp"
            return 0
        else
            retry_count=$((retry_count + 1))
            log "WARNING" "Gagal mengirim ke WhatsApp. Mencoba ulang ($retry_count/$MAX_RETRIES)..."
            sleep 5
        fi
    done
    
    log "ERROR" "Gagal mengirim ke WhatsApp setelah $MAX_RETRIES percobaan"
    return 1
}

# Array domain dan keyword
DOMAINS=(
    "blog.classy.id"    
)

KEYWORDS=(
    "Gacor Slot"
)

# Main script
main() {
    local timestamp=$(date '+%Y-%m-%d_%H%M%S')
    
    # Memeriksa dependensi
    check_dependencies
    
    log "INFO" "Memulai script pencarian"
    
    # Membuat direktori untuk hasil
    local results_dir="results"
    mkdir -p "$results_dir"
    
    # Membuat subdirektori dengan timestamp
    local date_dir="$results_dir/$(date '+%Y-%m-%d')"
    mkdir -p "$date_dir"

    # Menjalankan pencarian dengan concurrent limit
    local running=0
    
    for domain in "${DOMAINS[@]}"; do
        for keyword in "${KEYWORDS[@]}"; do
            # Menunggu jika sudah mencapai concurrent limit
            while [ $running -ge ${CONCURRENT_LIMIT:-2} ]; do
                running=$(jobs -p | wc -l)
                sleep 1
            done
            
            # Nama file output
            local output_file="${date_dir}/hasil_pencarian_${domain//./_}_${keyword// /_}_${timestamp}.txt"
            
            # Mengganti spasi dengan '+' pada keyword
            local search_keyword="${keyword// /+}"
            local base_url="https://www.google.com/search?q=site:$domain+$search_keyword"
            
            # Proses pencarian dalam background
            (
                start_time=$(date +%s.%N)
                
                log "INFO" "Memulai pencarian untuk domain: $domain dengan keyword: $keyword"
                
                # Header file
                {
                    echo "============================================="
                    echo "          HASIL PENCARIAN GOOGLE             "
                    echo "============================================="
                    echo "Data diakses pada: $timestamp"
                    echo "Domain: $domain"
                    echo "Kata kunci: $keyword"
                    echo "URL Pencarian: $base_url"
                    echo "Sistem: $(uname -a)"
                    echo "---------------------------------------------"
                    echo ""
                } > "$output_file"
                
                # Membersihkan cache dan cookies sebelum pencarian
                cleanup_lynx
                
                # Melakukan pencarian dengan pengaturan yang lebih ketat
                if ! lynx -accept_all_cookies \
                         -cookie_file=/tmp/cookies.$$ \
                         -cookie_save_file=/tmp/cookies.$$ \
                         -cache=0 \
                         -restrictions=all \
                         -anonymous \
                         -dump "$base_url" >> "$output_file" 2>/dev/null; then
                    log "ERROR" "Gagal melakukan pencarian untuk $domain"
                    # Bersihkan file temporary
                    rm -f /tmp/cookies.$$ 2>/dev/null
                    return 1
                fi
                
                # Bersihkan file temporary
                rm -f /tmp/cookies.$$ 2>/dev/null
                
                echo -e "\n----- Akhir dari Halaman 1 -----\n" >> "$output_file"
                
                # Format timestamp untuk lebih mudah dibaca
                local formatted_date=$(format_timestamp "$timestamp")
                local end_time=$(date +%s.%N)
                local response_time=$(echo "$end_time - $start_time" | bc | awk '{printf "%.2f", $1}')
                
                # Membuat caption untuk Telegram
                local caption=$'🔍 LAPORAN MONITORING WEBSITE\n'
                caption+=$'══════════════════════\n\n'
                caption+=$'📅 Waktu Pemindaian: '"$formatted_date"$'\n'
                caption+=$'🌐 Domain: '"$domain"$'\n'
                caption+=$'🎯 Kata Kunci: '"$keyword"$'\n\n'
                caption+=$'ℹ️ Status: Pemindaian Selesai\n'
                caption+=$'⚡ Powered by: Monitoring System v1.0\n'
                caption+=$'⏱️ Response Time: '"$response_time"$' detik\n\n'
                caption+=$'❗ Laporan lengkap terlampir dalam file\n'
                caption+=$'📌 #Monitoring #Security #'"${domain//./_}"

                # Caption ringkas untuk WhatsApp
                local whatsapp_caption=$'🔍 *MONITORING ALERT*\n\n'
                whatsapp_caption+=$'📅 Waktu: '"$formatted_date"$'\n'
                whatsapp_caption+=$'🌐 Domain: '"$domain"$'\n'
                whatsapp_caption+=$'🎯 Kata Kunci: '"$keyword"$'\n'
                whatsapp_caption+=$'ℹ️ Status: Pemindaian Selesai\n\n'
                whatsapp_caption+=$'📌 Laporan lengkap telah dikirim via Telegram'
                
                # Kirim notifikasi jika diaktifkan
                if [ "$ENABLE_TELEGRAM" = true ]; then
                    send_telegram "$output_file" "$caption"
                fi
                
                if [ "$ENABLE_WHATSAPP" = true ]; then
                    send_whatsapp "${whatsapp_caption//$'\n'/\\n}"
                fi
                
                log "INFO" "Pencarian selesai untuk domain: $domain"
                
                # Delay antar pencarian
                sleep ${SEARCH_DELAY:-30}
            ) &
            
            # Update jumlah proses yang sedang berjalan
            running=$(jobs -p | wc -l)
        done
    done
    
    # Menunggu semua proses selesai
    wait
    
    log "INFO" "Script pencarian selesai"
}

# Trap untuk membersihkan saat script dihentikan
trap 'log "WARNING" "Script dihentikan oleh user"; kill $(jobs -p) 2>/dev/null; exit 1' INT TERM

# Jalankan main script
main
