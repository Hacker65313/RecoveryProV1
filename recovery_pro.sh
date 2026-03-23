#!/bin/bash

# ============================================
# RECOVERY TOOL PRO v3.0 - Data Recovery Suite
# Author: MasJawa
# IG: @fendipendol65
# Engine: PhotoRec & TestDisk
# Platform: Termux & Kali Linux
# Features: Smart Sort, Auto Rename, Compress, Telegram Bot
# ============================================

# ============ WARNA ============
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'

BLACK='\033[30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m'

# ============ KONFIGURASI ============
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
RECOVERED_DIR="$SCRIPT_DIR/recovered"
BACKUP_DIR="$SCRIPT_DIR/backup"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Telegram config (akan diisi user)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Storage paths
declare -A STORAGE_PATHS
declare -A STORAGE_DEVICES

# ============ PROGRESS BAR ============
show_progress() {
    local current=$1
    local total=$2
    local prefix="$3"
    local suffix="$4"
    
    if [ "$total" -eq 0 ]; then
        return
    fi
    
    local percent=$((current * 100 / total))
    local bar_length=40
    local filled=$((bar_length * percent / 100))
    local empty=$((bar_length - filled))
    
    printf "\r${prefix} [${GREEN}"; printf '█%.0s' $(seq 1 $filled); printf "${NC}${DIM}"; printf '░%.0s' $(seq 1 $empty); printf "${NC}] ${percent}%% ${suffix}"
}

show_spinner() {
    local message="$1"
    local duration="${2:-2}"
    local spinner=('⠋' '⠙' '⠹' '⠸' '⼼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        printf "\r${CYAN}${spinner[$((i % 10))]}${NC} ${message}"
        sleep 0.1
        ((i++))
    done
    printf "\r%*s\r" $(( ${#message} + 10 )) ""
}

show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local dots=0
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local dot_str=""
        for ((j=0; j<dots%4; j++)); do dot_str+="."; done
        printf "\r${YELLOW}${message}${dot_str}   ${NC}"
        sleep 0.3
        ((dots++))
    done
    printf "\r%*s\r" $(( ${#message} + 10 )) ""
}

# ============ BANNER ============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═════════════════════════════════════════════════════════════════════╗
    ║  ██████╗ ███████╗███████╗██████╗  ██████╗ █████╗ ███████╗██╗        ║
    ║ ██╔════╝ ██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║        ║
    ║ ██║  ███╗█████╗  █████╗  ██████╔╝██║     ███████║███████╗██║        ║
    ║ ██║   ██║██╔══╝  ██╔══╝  ██╔══██╗██║     ██╔══██║╚════██║██║        ║
    ║ ╚██████╔╝███████╗███████╗██║  ██║╚██████╗██║  ██║███████║██║        ║
    ║  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝        ║
    ║                                                                   ║
    ║   ███████╗██████╗ ██╗   ██╗███████╗████████╗███████╗██████╗        ║
    ║   ██╔════╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗       ║
    ║   █████╗  ██████╔╝██║   ██║███████╗   ██║   █████╗  ██████╔╝       ║
    ║   ██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗       ║
    ║   ██║     ██║  ██║╚██████╔╝███████║   ██║   ███████╗██║  ██║       ║
    ║   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝       ║
    ║                                                                   ║
    ╠═════════════════════════════════════════════════════════════════════╣
    ║            🛠️  DATA RECOVERY SUITE PRO v3.0 🛠️                      ║
    ║                                                                   ║
    ║   Engine: PhotoRec & TestDisk                                     ║
    ║   Platform: Termux & Kali Linux                                   ║
    ║   Features: Smart Sort, Auto Rename, Compress, Telegram Bot       ║
    ║                                                                   ║
    ║   ┌──────────────────────────────────────────────────────┐        ║
    ║   │  Author: MasJawa                                    │        ║
    ║   │  IG: @fendipendol65                                 │        ║
    ║   └──────────────────────────────────────────────────────┘        ║
    ║                                                                   ║
    ╚═════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_warning() {
    echo -e "${BG_RED}${WHITE}"
    echo "  ╔═══════════════════════════════════════════════════════════════════╗  "
    echo "  ║                    ⚠️  PERINGATAN PENTING ⚠️                      ║  "
    echo "  ╠═══════════════════════════════════════════════════════════════════╣  "
    echo "  ║  [!] JANGAN GUNAKAN HP SELAMA PROSES RECOVERY!                   ║  "
    echo "  ║  [!] HINDARI OVERWRITE DATA - Jangan simpan file baru!           ║  "
    echo "  ║  [!] STOP penggunaan device untuk hasil recovery maksimal!       ║  "
    echo "  ║  [!] Proses ini mungkin memakan waktu lama!                      ║  "
    echo "  ╚═══════════════════════════════════════════════════════════════════╝  "
    echo -e "${NC}"
}

show_menu() {
    echo -e "${CYAN}╔═════════════════════════════════════════════════════════════════════╗"
    echo -e "║${WHITE}                      📱 RECOVERY MENU PRO                        ${CYAN}║"
    echo -e "╠═════════════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} 📷  Recover Photo Only       - Foto saja (JPG, PNG, RAW)"
    echo -e "  ${GREEN}[2]${NC} 📹  Recover Video Only       - Video saja (MP4, AVI, MOV)"
    echo -e "  ${GREEN}[3]${NC} 📄  Recover Document Only    - Dokumen saja (DOC, PDF, XLS)"
    echo -e "  ${GREEN}[4]${NC} 📱  WhatsApp Photo Mode      - Khusus foto WhatsApp"
    echo -e "  ${GREEN}[5]${NC} 📁  Recover All Files        - Semua jenis file"
    echo ""
    echo -e "  ${YELLOW}[6]${NC} 🔍  Quick Scan              - Scan cepat (disarankan)"
    echo -e "  ${YELLOW}[7]${NC} 🕵️  Deep Scan               - Scan mendalam (lengkap)"
    echo ""
    echo -e "  ${BLUE}[8]${NC} 📊  View Results             - Lihat hasil recovery"
    echo -e "  ${BLUE}[9]${NC} 📦  Compress to ZIP          - Kompres hasil recovery"
    echo -e "  ${BLUE}[10]${NC} 🤖  Telegram Bot Settings    - Kirim hasil ke Telegram"
    echo ""
    echo -e "  ${MAGENTA}[11]${NC} 🛠️  Install Dependencies    - Install tool yang dibutuhkan"
    echo ""
    echo -e "  ${RED}[0]${NC} 🚪  Exit                     - Keluar dari program"
    echo ""
    echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============ UTILITY FUNCTIONS ============
is_termux() {
    [ -n "$TERMUX_VERSION" ] || [ "$PREFIX" = "/data/data/com.termux/files/usr" ]
}

format_size() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    local size=$bytes
    
    while [ $(echo "$size >= 1024" | bc -l 2>/dev/null || echo 0) -eq 1 ] && [ $unit -lt 4 ]; do
        size=$(echo "scale=2; $size / 1024" | bc 2>/dev/null || echo "$size")
        ((unit++))
    done
    
    printf "%.2f %s" "$size" "${units[$unit]}"
}

check_dependencies() {
    local missing=()
    
    for tool in photorec testdisk; do
        if ! command -v $tool &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}[!] Dependencies tidak lengkap: ${missing[*]}${NC}"
        echo -e "${YELLOW}[*] Pilih menu [11] untuk install dependencies${NC}"
        return 1
    fi
    return 0
}

install_dependencies() {
    echo -e "${YELLOW}[*] Menginstall dependencies...${NC}"
    
    if is_termux; then
        pkg update && pkg install -y testdisk fdisk file bc
    else
        sudo apt update && sudo apt install -y testdisk fdisk file bc
    fi
    
    echo -e "${GREEN}[✓] Dependencies berhasil diinstall${NC}"
}

detect_storage() {
    local num=1
    STORAGE_PATHS=()
    STORAGE_DEVICES=()
    
    echo -e "${YELLOW}[*] Mendeteksi storage...${NC}\n"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  NO.  |  PATH                            |  TYPE     ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    if is_termux; then
        # Termux storage detection
        if [ -d "/sdcard" ]; then
            echo -e "  ${GREEN}$num${NC}    |  /sdcard                        |  Internal"
            STORAGE_PATHS[$num]="/sdcard"
            ((num++))
        fi
        
        if [ -d "/storage/emulated/0" ]; then
            echo -e "  ${GREEN}$num${NC}    |  /storage/emulated/0            |  Internal"
            STORAGE_PATHS[$num]="/storage/emulated/0"
            ((num++))
        fi
        
        for dir in /storage/*; do
            if [ -d "$dir" ] && [[ "$dir" != "/storage/emulated" ]] && [[ "$dir" != "/storage/self" ]]; then
                echo -e "  ${GREEN}$num${NC}    |  $dir    |  External"
                STORAGE_PATHS[$num]="$dir"
                ((num++))
            fi
        done
    else
        # Kali Linux storage detection
        while IFS= read -r line; do
            local dev=$(echo "$line" | awk '{print $1}')
            local size=$(echo "$line" | awk '{print $2}')
            local type=$(echo "$line" | awk '{print $3}')
            local mount=$(echo "$line" | awk '{print $4}')
            
            if [ -n "$mount" ] && [ "$mount" != "MOUNTPOINT" ]; then
                printf "  ${GREEN}%-3s${NC}  |  %-30s  |  %-8s\n" "$num" "$mount" "$type"
                STORAGE_PATHS[$num]="$mount"
                STORAGE_DEVICES[$num]="/dev/$dev"
                ((num++))
            fi
        done < <(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v "loop" | grep -v "NAME")
    fi
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
}

# ============ SMART SORTING ============
detect_category() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    local name=$(basename "$file")
    
    # WhatsApp photo detection
    case "$name" in
        IMG-*|WA-*|WhatsApp*)
            if [[ "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "png" ]]; then
                echo "whatsapp_photos"
                return
            fi
            ;;
    esac
    
    # Photo extensions
    case "$ext" in
        jpg|jpeg|jpe|jfif|png|gif|bmp|tiff|tif|webp|raw|cr2|crw|nef|nrw|arw|dng|orf|rw2|raf)
            echo "photos"
            ;;
        # Video extensions
        mp4|avi|mov|wmv|flv|mkv|webm|m4v|3gp|3g2|mpg|mpeg|ts|mts|m2ts)
            echo "videos"
            ;;
        # Document extensions
        doc|docx|xls|xlsx|ppt|pptx|pdf|txt|odt|ods|odp|rtf|csv)
            echo "documents"
            ;;
        # Archive extensions
        zip|rar|7z|tar|gz|bz2|tgz)
            echo "archives"
            ;;
        # Audio extensions
        mp3|wav|flac|aac|ogg|wma|m4a)
            echo "audio"
            ;;
        *)
            echo "others"
            ;;
    esac
}

auto_rename() {
    local file="$1"
    local category="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local ext="${file##*.}"
    local prefix=""
    
    case "$category" in
        photos) prefix="PHOTO" ;;
        videos) prefix="VIDEO" ;;
        documents) prefix="DOC" ;;
        whatsapp_photos) prefix="WA_PHOTO" ;;
        archives) prefix="ARCHIVE" ;;
        audio) prefix="AUDIO" ;;
        *) prefix="FILE" ;;
    esac
    
    local hash=$(md5sum "$file" 2>/dev/null | cut -c1-8)
    [ -z "$hash" ] && hash=$(date +%s | tail -c 8)
    
    echo "${prefix}_${timestamp}_${hash}.${ext}"
}

smart_sort_files() {
    local source_dir="$1"
    local output_dir="$2"
    local auto_rename_flag="${3:-true}"
    
    # Create category folders
    mkdir -p "$output_dir"/{Photos,Videos,Documents,WhatsApp_Photos,Archives,Audio,Others}
    
    local total_files=$(find "$source_dir" -type f | wc -l)
    local processed=0
    local photos=0 videos=0 documents=0 whatsapp=0 others=0
    
    echo -e "${YELLOW}[*] Memproses $total_files file...${NC}\n"
    
    while IFS= read -r file; do
        [ ! -f "$file" ] && continue
        
        ((processed++))
        show_progress $processed $total_files "  Sorting"
        
        local category=$(detect_category "$file")
        local dest_folder="$output_dir"
        local new_name=""
        
        case "$category" in
            photos)
                dest_folder="$output_dir/Photos"
                ((photos++))
                ;;
            videos)
                dest_folder="$output_dir/Videos"
                ((videos++))
                ;;
            documents)
                dest_folder="$output_dir/Documents"
                ((documents++))
                ;;
            whatsapp_photos)
                dest_folder="$output_dir/WhatsApp_Photos"
                ((whatsapp++))
                ;;
            *)
                dest_folder="$output_dir/Others"
                ((others++))
                ;;
        esac
        
        if [ "$auto_rename_flag" = "true" ]; then
            new_name=$(auto_rename "$file" "$category")
        else
            new_name=$(basename "$file")
        fi
        
        # Handle duplicates
        local dest_file="$dest_folder/$new_name"
        local counter=1
        while [ -f "$dest_file" ]; do
            local base="${new_name%.*}"
            local ext="${new_name##*.}"
            dest_file="$dest_folder/${base}_${counter}.${ext}"
            ((counter++))
        done
        
        mv "$file" "$dest_file" 2>/dev/null
    done < <(find "$source_dir" -type f)
    
    echo ""
    echo -e "${GREEN}[✓] Smart Sorting selesai!${NC}"
    echo -e "    ${CYAN}Photos: $photos${NC}"
    echo -e "    ${CYAN}Videos: $videos${NC}"
    echo -e "    ${CYAN}Documents: $documents${NC}"
    echo -e "    ${CYAN}WhatsApp Photos: $whatsapp${NC}"
    echo -e "    ${CYAN}Others: $others${NC}"
}

# ============ ANALYSIS ============
show_analysis() {
    local dir="$1"
    local total_files=$(find "$dir" -type f 2>/dev/null | wc -l)
    local total_size=$(du -sb "$dir" 2>/dev/null | cut -f1)
    
    local photos=$(find "$dir/Photos" -type f 2>/dev/null | wc -l)
    local videos=$(find "$dir/Videos" -type f 2>/dev/null | wc -l)
    local docs=$(find "$dir/Documents" -type f 2>/dev/null | wc -l)
    local wa=$(find "$dir/WhatsApp_Photos" -type f 2>/dev/null | wc -l)
    local others=$(find "$dir/Others" -type f 2>/dev/null | wc -l)
    
    local size_formatted=$(format_size $total_size)
    
    echo -e "${CYAN}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}                    📊 ANALYSIS RESULTS                          ${CYAN}${NC}"
    echo -e "${CYAN}╠═════════════════════════════════════════════════════════════════════╣${NC}"
    echo ""
    echo -e "${WHITE}  📁 STATISTIK FILE:${NC}"
    echo -e "  ├── Total Files Found:    ${GREEN}$total_files${NC}"
    echo -e "  └── Successfully Sorted:  ${GREEN}$((photos + videos + docs + wa + others))${NC}"
    echo ""
    echo -e "${WHITE}  💾 UKURAN:${NC}"
    echo -e "  └── Total Size: ${CYAN}$size_formatted${NC}"
    echo ""
    echo -e "${WHITE}  📂 KATEGORI:${NC}"
    echo -e "  ├── 📷 Photos:          ${GREEN}$photos${NC}"
    echo -e "  ├── 📹 Videos:          ${GREEN}$videos${NC}"
    echo -e "  ├── 📄 Documents:       ${GREEN}$docs${NC}"
    echo -e "  ├── 📱 WhatsApp Photos: ${GREEN}$wa${NC}"
    echo -e "  └── 📦 Others:          ${GREEN}$others${NC}"
    echo ""
    echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============ COMPRESS ============
compress_to_zip() {
    local source_dir="$1"
    local output_name="${2:-recovery_$(date +%Y%m%d_%H%M%S).zip}"
    local output_path="$RECOVERED_DIR/$output_name"
    
    echo -e "${YELLOW}[*] Mengompres hasil recovery...${NC}\n"
    
    local total_files=$(find "$source_dir" -type f | wc -l)
    local processed=0
    
    cd "$source_dir"
    zip -r "$output_path" . > /dev/null 2>&1
    
    local zip_size=$(format_size $(stat -c%s "$output_path" 2>/dev/null || echo 0))
    
    echo -e "${GREEN}[✓] Berhasil dikompres: $output_path${NC}"
    echo -e "${GREEN}[✓] Ukuran: $zip_size${NC}"
    
    echo "$output_path"
}

# ============ TELEGRAM BOT ============
load_telegram_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        TELEGRAM_BOT_TOKEN="$TELEGRAM_TOKEN"
        TELEGRAM_CHAT_ID="$CHAT_ID"
    fi
}

save_telegram_config() {
    echo "TELEGRAM_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$CONFIG_FILE"
}

send_telegram_message() {
    local message="$1"
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${RED}[!] Telegram Bot belum dikonfigurasi!${NC}"
        return 1
    fi
    
    local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    
    curl -s -X POST "$url" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=HTML" > /dev/null
    
    return $?
}

send_telegram_document() {
    local file_path="$1"
    local caption="${2:-}"
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        return 1
    fi
    
    local url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument"
    
    curl -s -X POST "$url" \
        -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "document=@$file_path" \
        -F "caption=$caption" > /dev/null
    
    return $?
}

send_telegram_result() {
    local dir="$1"
    local zip_path="${2:-}"
    
    local total_files=$(find "$dir" -type f 2>/dev/null | wc -l)
    local total_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    local photos=$(find "$dir/Photos" -type f 2>/dev/null | wc -l)
    local videos=$(find "$dir/Videos" -type f 2>/dev/null | wc -l)
    local docs=$(find "$dir/Documents" -type f 2>/dev/null | wc -l)
    local wa=$(find "$dir/WhatsApp_Photos" -type f 2>/dev/null | wc -l)
    
    local message="<b>🔧 RECOVERY TOOL PRO - HASIL</b>

<b>📊 Statistik:</b>
├─ Total File: $total_files
└─ Total Size: $total_size

<b>📁 Kategori:</b>
├─ 📷 Photos: $photos
├─ 📹 Videos: $videos
├─ 📄 Documents: $docs
├─ 📱 WhatsApp Photos: $wa

<i>Author: MasJawa | IG: @fendipendol65</i>"
    
    send_telegram_message "$message"
    
    if [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
        send_telegram_document "$zip_path" "📦 Hasil Recovery"
    fi
}

telegram_settings() {
    show_banner
    echo -e "${YELLOW}═════════════════ TELEGRAM BOT SETTINGS ═════════════════${NC}\n"
    
    echo -e "${CYAN}Cara mendapatkan Bot Token:${NC}"
    echo "  1. Buka Telegram, cari @BotFather"
    echo "  2. Ketik /newbot dan ikuti instruksi"
    echo "  3. Copy token yang diberikan"
    echo ""
    echo -e "${CYAN}Cara mendapatkan Chat ID:${NC}"
    echo "  1. Buka Telegram, cari @userinfobot"
    echo "  2. Ketik /start"
    echo "  3. Copy ID yang ditampilkan"
    echo ""
    
    echo -e "${WHITE}Current Settings:${NC}"
    echo -e "  Bot Token: ${YELLOW}${TELEGRAM_BOT_TOKEN:-Belum diset}${NC}"
    echo -e "  Chat ID:   ${YELLOW}${TELEGRAM_CHAT_ID:-Belum diset}${NC}"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Masukkan Bot Token baru (Enter untuk skip): ${NC}")" new_token
    read -p "$(echo -e "${YELLOW}Masukkan Chat ID baru (Enter untuk skip): ${NC}")" new_chat
    
    [ -n "$new_token" ] && TELEGRAM_BOT_TOKEN="$new_token"
    [ -n "$new_chat" ] && TELEGRAM_CHAT_ID="$new_chat"
    
    save_telegram_config
    
    echo -e "${GREEN}[✓] Pengaturan Telegram berhasil disimpan!${NC}"
    
    read -p "$(echo -e "${YELLOW}Kirim test message? (y/n): ${NC}")" test_msg
    if [ "$test_msg" = "y" ]; then
        if send_telegram_message "✅ Recovery Tool Pro - Test Message Berhasil!\n\n<i>Author: MasJawa | IG: @fendipendol65</i>"; then
            echo -e "${GREEN}[✓] Test message berhasil dikirim!${NC}"
        else
            echo -e "${RED}[✗] Gagal mengirim test message!${NC}"
        fi
    fi
    
    read -p "Tekan Enter untuk kembali..."
}

# ============ RECOVERY FUNCTIONS ============
run_recovery() {
    local target="$1"
    local output_dir="$2"
    local file_types="$3"
    local scan_mode="${4:-quick}"
    
    local temp_output="$output_dir/temp_recovery"
    mkdir -p "$temp_output"
    
    echo -e "${CYAN}${NC}"
    echo -e "${YELLOW}[*] Target: $target${NC}"
    echo -e "${YELLOW}[*] Output: $output_dir${NC}"
    echo -e "${YELLOW}[*] Mode: ${scan_mode^^} SCAN${NC}"
    echo -e "${CYAN}${NC}\n"
    
    # Build options
    local cmd_options=""
    if [ "$scan_mode" = "deep" ]; then
        cmd_options="partition_none,options,paranoid,fileopt,$file_types,search"
    else
        cmd_options="partition_none,options,fileopt,$file_types,search"
    fi
    
    local cmd="photorec /d \"$temp_output\" /cmd $target $cmd_options"
    if ! is_termux; then
        cmd="sudo $cmd"
    fi
    
    echo -e "${YELLOW}[*] Menjalankan PhotoRec...${NC}"
    echo -e "${CYAN}[*] Harap tunggu, proses ini mungkin memakan waktu...${NC}\n"
    
    show_spinner "Mempersiapkan recovery..." 2
    
    eval "$cmd" 2>&1 | tee "$LOG_DIR/photorec_$(date +%Y%m%d_%H%M%S).log"
    
    # Smart sort
    if [ -d "$temp_output" ]; then
        smart_sort_files "$temp_output" "$output_dir" "true"
        rm -rf "$temp_output"
    fi
}

recover_menu() {
    local mode="$1"
    
    show_banner
    show_warning
    
    detect_storage
    
    read -p "$(echo -e "${YELLOW}Pilih storage [nomor]: ${NC}")" choice
    
    if [ -z "${STORAGE_PATHS[$choice]}" ]; then
        echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    local target="${STORAGE_PATHS[$choice]}"
    
    # Select scan mode
    echo -e "\n${CYAN}Pilih mode scan:${NC}"
    echo -e "  ${GREEN}1${NC} - Quick Scan (Cepat, disarankan)"
    echo -e "  ${GREEN}2${NC} - Deep Scan (Lengkap, lebih lama)"
    
    read -p "$(echo -e "\n${YELLOW}Pilihan [1/2]: ${NC}")" scan_choice
    local scan_mode="quick"
    [ "$scan_choice" = "2" ] && scan_mode="deep"
    
    # File types based on mode
    local file_types=""
    case "$mode" in
        photo)
            file_types="everything,disable,jpg,enable,png,enable,gif,enable,bmp,enable,raw,enable,cr2,enable,nef,enable"
            ;;
        video)
            file_types="everything,disable,mp4,enable,avi,enable,mov,enable,mkv,enable,wmv,enable,flv,enable"
            ;;
        document)
            file_types="everything,disable,doc,enable,docx,enable,xls,enable,xlsx,enable,pdf,enable,ppt,enable,txt,enable"
            ;;
        whatsapp)
            file_types="everything,disable,jpg,enable,png,enable,mp4,enable"
            ;;
        all)
            file_types="everything,enable"
            ;;
    esac
    
    # Create output directory
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local mode_name=""
    case "$mode" in
        photo) mode_name="photos" ;;
        video) mode_name="videos" ;;
        document) mode_name="documents" ;;
        whatsapp) mode_name="whatsapp" ;;
        all) mode_name="all_files" ;;
    esac
    
    local output_dir="$RECOVERED_DIR/${mode_name}_${timestamp}"
    mkdir -p "$output_dir"
    
    # Confirmation
    echo -e "\n${RED}[!] PERINGATAN TERAKHIR!${NC}"
    echo -e "${YELLOW}    Pastikan device TIDAK DIGUNAKAN selama recovery!${NC}"
    
    read -p "$(echo -e "\n${YELLOW}Lanjutkan? (y/n): ${NC}")" confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${YELLOW}[!] Dibatalkan oleh user${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    # Run recovery
    run_recovery "$target" "$output_dir" "$file_types" "$scan_mode"
    
    # Show analysis
    show_analysis "$output_dir"
    
    # Compress option
    read -p "$(echo -e "${YELLOW}Kompres hasil ke ZIP? (y/n): ${NC}")" compress_choice
    local zip_path=""
    
    if [ "$compress_choice" = "y" ]; then
        zip_path=$(compress_to_zip "$output_dir")
    fi
    
    # Telegram option
    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        read -p "$(echo -e "${YELLOW}Kirim hasil ke Telegram? (y/n): ${NC}")" send_telegram
        if [ "$send_telegram" = "y" ]; then
            show_spinner "Mengirim ke Telegram..." 2
            send_telegram_result "$output_dir" "$zip_path"
            echo -e "${GREEN}[✓] Hasil dikirim ke Telegram!${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}[✓] Recovery selesai!${NC}"
    echo -e "${GREEN}[✓] Lokasi: $output_dir${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

view_results() {
    show_banner
    echo -e "${YELLOW}═════════════════ VIEW RESULTS ═════════════════${NC}\n"
    
    if [ ! -d "$RECOVERED_DIR" ]; then
        echo -e "${RED}[!] Tidak ada hasil recovery!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  NO.  |  SESSION                           |  SIZE      ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    
    local num=1
    declare -A sessions
    
    for dir in "$RECOVERED_DIR"/*/; do
        [ ! -d "$dir" ] && continue
        local name=$(basename "$dir")
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}$num${NC}    |  ${name:0:34}  |  $size"
        sessions[$num]="$dir"
        ((num++))
    done
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    
    read -p "$(echo -e "${YELLOW}Pilih session untuk detail [nomor/0=kembali]: ${NC}")" choice
    
    if [ "$choice" = "0" ] || [ -z "${sessions[$choice]}" ]; then
        return
    fi
    
    show_analysis "${sessions[$choice]}"
    read -p "Tekan Enter untuk kembali..."
}

# ============ MAIN ============
main() {
    # Create directories
    mkdir -p "$LOG_DIR" "$RECOVERED_DIR" "$BACKUP_DIR"
    
    # Load config
    load_telegram_config
    
    # Check dependencies
    check_dependencies
    
    while true; do
        show_banner
        show_menu
        
        read -p "$(echo -e "${WHITE}  Pilih menu [0-11]: ${NC}")" choice
        
        case $choice in
            1) recover_menu "photo" ;;
            2) recover_menu "video" ;;
            3) recover_menu "document" ;;
            4) recover_menu "whatsapp" ;;
            5) recover_menu "all" ;;
            6) recover_menu "all" ;;  # Quick scan
            7) recover_menu "all" ;;  # Deep scan
            8) view_results ;;
            9)
                show_banner
                echo -e "${YELLOW}═════════════════ COMPRESS RESULTS ═════════════════${NC}\n"
                
                local num=1
                declare -A sessions
                
                for dir in "$RECOVERED_DIR"/*/; do
                    [ ! -d "$dir" ] && continue
                    local name=$(basename "$dir")
                    echo -e "  ${GREEN}$num${NC} - $name"
                    sessions[$num]="$dir"
                    ((num++))
                done
                
                read -p "$(echo -e "\n${YELLOW}Pilih session: ${NC}")" sel
                if [ -n "${sessions[$sel]}" ]; then
                    compress_to_zip "${sessions[$sel]}"
                fi
                read -p "Tekan Enter untuk kembali..."
                ;;
            10) telegram_settings ;;
            11) install_dependencies ;;
            0)
                echo ""
                echo -e "${GREEN}[*] Terima kasih sudah menggunakan Recovery Tool Pro!${NC}"
                echo -e "${GREEN}[*] Author: MasJawa | IG: @fendipendol65${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Pilihan tidak valid!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run main
main