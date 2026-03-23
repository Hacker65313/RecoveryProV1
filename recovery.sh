#!/bin/bash

# ============================================
# RECOVERY TOOL - Data Recovery Suite
# Author: MasJawa
# IG: fendipendol65
# Tools: PhotoRec, TestDisk Engine
# For: Termux & Kali Linux
# ============================================

# Warna untuk tampilan
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Path konfigurasi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
RECOVERED_DIR="$SCRIPT_DIR/recovered"
BACKUP_DIR="$SCRIPT_DIR/backup"

# Buat folder jika belum ada
mkdir -p "$LOG_DIR" "$RECOVERED_DIR" "$BACKUP_DIR"

# Fungsi Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██████╗ ███████╗███████╗██████╗  ██████╗ █████╗ ███████╗██╗  ║
    ║  ██╔════╝ ██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ║
    ║  ██║  ███╗█████╗  █████╗  ██████╔╝██║     ███████║███████╗██║  ║
    ║  ██║   ██║██╔══╝  ██╔══╝  ██╔══██╗██║     ██╔══██║╚════██║██║  ║
    ║  ╚██████╔╝███████╗███████╗██║  ██║╚██████╗██║  ██║███████║██║  ║
    ║   ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ║
    ║                                                               ║
    ║   ███████╗██████╗ ██╗   ██╗███████╗████████╗███████╗██████╗   ║
    ║   ██╔════╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗  ║
    ║   █████╗  ██████╔╝██║   ██║███████╗   ██║   █████╗  ██████╔╝  ║
    ║   ██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗  ║
    ║   ██║     ██║  ██║╚██████╔╝███████║   ██║   ███████╗██║  ██║  ║
    ║   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝  ║
    ║                                                               ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║            🛠️  DATA RECOVERY SUITE v2.0 🛠️                   ║
    ║                                                               ║
    ║   Engine: PhotoRec & TestDisk                                ║
    ║   Platform: Termux & Kali Linux                              ║
    ║                                                               ║
    ║   ┌─────────────────────────────────────────────────────┐    ║
    ║   │  Author: MasJawa                                    │    ║
    ║   │  IG: @fendipendol65                                 │    ║
    ║   └─────────────────────────────────────────────────────┘    ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Fungsi cek dependencies
check_dependencies() {
    local missing=()
    
    echo -e "${YELLOW}[*] Mengecek dependencies...${NC}"
    
    # Cek photorec
    if ! command -v photorec &> /dev/null; then
        missing+=("photorec")
    fi
    
    # Cek testdisk
    if ! command -v testdisk &> /dev/null; then
        missing+=("testdisk")
    fi
    
    # Cek tools lainnya
    for tool in fdisk lsblk file; do
        if ! command -v $tool &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}[!] Dependencies tidak ditemukan: ${missing[*]}${NC}"
        echo -e "${YELLOW}[*] Install dengan command berikut:${NC}"
        echo ""
        
        # Deteksi OS
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$ID" == "kali" ]] || [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
                echo -e "${GREEN}    sudo apt update && sudo apt install -y testdisk fdisk file${NC}"
            elif [[ "$ID" == "termux" ]] || [[ -n "$TERMUX_VERSION" ]]; then
                echo -e "${GREEN}    pkg update && pkg install -y testdisk fdisk file${NC}"
            else
                echo -e "${GREEN}    sudo apt update && sudo apt install -y testdisk fdisk file${NC}"
            fi
        else
            echo -e "${GREEN}    pkg update && pkg install -y testdisk fdisk file  (Termux)${NC}"
            echo -e "${GREEN}    sudo apt update && sudo apt install -y testdisk fdisk file  (Kali/Debian)${NC}"
        fi
        echo ""
        read -p "Apakah ingin install sekarang? (y/n): " install_choice
        if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
            install_dependencies
        else
            echo -e "${RED}[!] Tool mungkin tidak berfungsi dengan baik tanpa dependencies${NC}"
            read -p "Tekan Enter untuk melanjutkan..."
        fi
    else
        echo -e "${GREEN}[✓] Semua dependencies sudah terinstall${NC}"
        sleep 1
    fi
}

# Fungsi install dependencies
install_dependencies() {
    echo -e "${YELLOW}[*] Menginstall dependencies...${NC}"
    
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        pkg update && pkg install -y testdisk fdisk file
    else
        sudo apt update && sudo apt install -y testdisk fdisk file
    fi
    
    echo -e "${GREEN}[✓] Dependencies berhasil diinstall${NC}"
    sleep 2
}

# Fungsi deteksi storage
detect_storage() {
    echo -e "${YELLOW}[*] Mendeteksi storage/storage media...${NC}"
    echo ""
    
    # Untuk Termux - gunakan /sdcard atau /storage
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        echo -e "${WHITE}  NO.  |  PATH                    |  TYPE  ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        
        local num=1
        # Cek sdcard
        if [ -d "/sdcard" ]; then
            echo -e "  ${GREEN}$num${NC}    |  /sdcard                |  Internal"
            storage_paths[$num]="/sdcard"
            ((num++))
        fi
        
        # Cek storage emulated
        if [ -d "/storage/emulated/0" ]; then
            echo -e "  ${GREEN}$num${NC}    |  /storage/emulated/0    |  Internal"
            storage_paths[$num]="/storage/emulated/0"
            ((num++))
        fi
        
        # Cek external storage
        for dir in /storage/*; do
            if [ -d "$dir" ] && [[ "$dir" != "/storage/emulated" ]] && [[ "$dir" != "/storage/self" ]]; then
                echo -e "  ${GREEN}$num${NC}    |  $dir    |  External"
                storage_paths[$num]="$dir"
                ((num++))
            fi
        done
        
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    else
        # Untuk Kali Linux - gunakan lsblk
        echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}  NO.  |  DEVICE      |  SIZE    |  TYPE  |  MOUNTPOINT     ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
        
        local num=1
        while read -r line; do
            local dev=$(echo "$line" | awk '{print $1}')
            local size=$(echo "$line" | awk '{print $2}')
            local type=$(echo "$line" | awk '{print $3}')
            local mount=$(echo "$line" | awk '{print $4}')
            
            if [ -n "$mount" ] && [ "$mount" != "MOUNTPOINT" ]; then
                printf "  ${GREEN}%-3s${NC}  |  %-10s  |  %-6s  |  %-4s  |  %-15s\n" "$num" "$dev" "$size" "$type" "$mount"
                storage_paths[$num]="$mount"
                storage_devices[$num]="/dev/$dev"
                ((num++))
            fi
        done < <(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v "loop" | grep -v "NAME")
        
        echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    fi
    
    echo ""
}

# Fungsi scan storage untuk file yang dihapus
scan_storage() {
    show_banner
    echo -e "${YELLOW}═════════════════ SCAN STORAGE ═════════════════${NC}"
    echo ""
    
    detect_storage
    
    echo -e "${YELLOW}Pilih storage yang ingin di-scan:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [ -z "${storage_paths[$choice]}" ]; then
        echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    local target_path="${storage_paths[$choice]}"
    
    echo ""
    echo -e "${YELLOW}[*] Scanning $target_path untuk file yang terhapus...${NC}"
    echo -e "${CYAN}[*] Ini mungkin memakan waktu beberapa menit...${NC}"
    echo ""
    
    # Buat folder hasil scan
    local scan_result="$LOG_DIR/scan_result_$(date +%Y%m%d_%H%M%S).txt"
    
    # Scan dengan find untuk file yang mungkin tersembunyi atau di folder .trash
    echo -e "${YELLOW}[*] Mencari file di hidden folders dan trash...${NC}"
    
    # Cek berbagai lokasi trash
    local trash_locations=(
        "$target_path/.Trash"
        "$target_path/.trash"
        "$target_path/.Trashes"
        "$target_path/Trash"
        "$target_path/.local/share/Trash"
    )
    
    echo "=== HASIL SCAN STORAGE ===" > "$scan_result"
    echo "Tanggal: $(date)" >> "$scan_result"
    echo "Target: $target_path" >> "$scan_result"
    echo "" >> "$scan_result"
    
    local found=0
    
    for trash in "${trash_locations[@]}"; do
        if [ -d "$trash" ]; then
            echo -e "${GREEN}[✓] Ditemukan trash folder: $trash${NC}"
            echo "Trash folder: $trash" >> "$scan_result"
            find "$trash" -type f 2>/dev/null | head -50 >> "$scan_result"
            found=1
        fi
    done
    
    # Cari file yang baru saja dimodifikasi (potensi file yang bisa di-recover)
    echo "" >> "$scan_result"
    echo "=== File yang baru saja dimodifikasi (7 hari terakhir) ===" >> "$scan_result"
    find "$target_path" -type f -mtime -7 2>/dev/null | head -100 >> "$scan_result"
    
    # Cari file hidden
    echo "" >> "$scan_result"
    echo "=== File Hidden ===" >> "$scan_result"
    find "$target_path" -name ".*" -type f 2>/dev/null | head -50 >> "$scan_result"
    
    if [ -f "$scan_result" ]; then
        echo ""
        echo -e "${GREEN}[✓] Scan selesai!${NC}"
        echo -e "${GREEN}[✓] Hasil disimpan di: $scan_result${NC}"
        echo ""
        echo -e "${YELLOW}Preview hasil:${NC}"
        echo -e "${CYAN}════════════════════════════════════════${NC}"
        head -30 "$scan_result"
        echo -e "${CYAN}════════════════════════════════════════${NC}"
    fi
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi recover foto dengan PhotoRec
recover_photo() {
    show_banner
    echo -e "${YELLOW}═════════════════ RECOVER PHOTO ═════════════════${NC}"
    echo ""
    echo -e "${CYAN}Tool ini menggunakan PhotoRec untuk recovery foto${NC}"
    echo -e "${CYAN}Format yang didukung: JPG, PNG, GIF, RAW, CR2, dll${NC}"
    echo ""
    
    detect_storage
    
    echo -e "${YELLOW}Pilih storage/device yang ingin di-recover:${NC}"
    read -p "Masukkan nomor: " choice
    
    local target=""
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        if [ -n "${storage_paths[$choice]}" ]; then
            target="${storage_paths[$choice]}"
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    else
        if [ -n "${storage_devices[$choice]}" ]; then
            target="${storage_devices[$choice]}"
        elif [ -n "${storage_paths[$choice]}" ]; then
            target="${storage_paths[$choice]}"
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    fi
    
    # Buat folder recovery dengan timestamp
    local recover_folder="$RECOVERED_DIR/photos_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$recover_folder"
    
    echo ""
    echo -e "${YELLOW}[*] Memulai PhotoRec untuk recovery foto...${NC}"
    echo -e "${YELLOW}[*] Target: $target${NC}"
    echo -e "${YELLOW}[*] Output: $recover_folder${NC}"
    echo ""
    echo -e "${RED}[!] PERINGATAN: Jangan write ke device yang sama dengan yang di-recover!${NC}"
    echo ""
    read -p "Lanjutkan? (y/n): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}[!] Dibatalkan oleh user${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}[*] Menjalankan PhotoRec...${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Jalankan photorec dengan opsi file gambar saja
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        # Untuk Termux - gunakan sudo jika bisa, atau langsung
        photorec /d "$recover_folder" /cmd $target partition_none,options,fileopt,everything,disable,raw,enable,jpg,enable,png,enable,gif,enable,bmp,enable,tiff,enable,cr2,enable,nef,enable,orf,enable,arw,enable,rw2,enable,dng,enable,search 2>&1 | tee "$LOG_DIR/photorec_$(date +%Y%m%d_%H%M%S).log"
    else
        # Untuk Kali Linux
        sudo photorec /d "$recover_folder" /cmd $target partition_none,options,fileopt,everything,disable,raw,enable,jpg,enable,png,enable,gif,enable,bmp,enable,tiff,enable,cr2,enable,nef,enable,orf,enable,arw,enable,rw2,enable,dng,enable,search 2>&1 | tee "$LOG_DIR/photorec_$(date +%Y%m%d_%H%M%S).log"
    fi
    
    echo ""
    echo -e "${GREEN}[✓] Recovery selesai!${NC}"
    echo -e "${GREEN}[✓] File disimpan di: $recover_folder${NC}"
    
    # Hitung file yang berhasil di-recover
    local count=$(find "$recover_folder" -type f 2>/dev/null | wc -l)
    echo -e "${GREEN}[✓] Total file yang di-recover: $count${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi recover semua file
recover_all_files() {
    show_banner
    echo -e "${YELLOW}═════════════════ RECOVER ALL FILES ═════════════════${NC}"
    echo ""
    echo -e "${CYAN}Tool ini menggunakan PhotoRec untuk recovery semua jenis file${NC}"
    echo -e "${CYAN}Format yang didukung: Dokumen, Archive, Video, Audio, dll${NC}"
    echo ""
    
    detect_storage
    
    echo -e "${YELLOW}Pilih storage/device yang ingin di-recover:${NC}"
    read -p "Masukkan nomor: " choice
    
    local target=""
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        if [ -n "${storage_paths[$choice]}" ]; then
            target="${storage_paths[$choice]}"
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    else
        if [ -n "${storage_devices[$choice]}" ]; then
            target="${storage_devices[$choice]}"
        elif [ -n "${storage_paths[$choice]}" ]; then
            target="${storage_paths[$choice]}"
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    fi
    
    # Buat folder recovery dengan timestamp
    local recover_folder="$RECOVERED_DIR/all_files_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$recover_folder"
    
    echo ""
    echo -e "${YELLOW}[*] Memulai PhotoRec untuk recovery semua file...${NC}"
    echo -e "${YELLOW}[*] Target: $target${NC}"
    echo -e "${YELLOW}[*] Output: $recover_folder${NC}"
    echo ""
    
    echo -e "${CYAN}Pilih jenis file yang ingin di-recover:${NC}"
    echo -e "  ${GREEN}1${NC} - Semua jenis file"
    echo -e "  ${GREEN}2${NC} - Dokumen (doc, xls, ppt, pdf, dll)"
    echo -e "  ${GREEN}3${NC} - Archive (zip, rar, 7z, tar, dll)"
    echo -e "  ${GREEN}4${NC} - Video (mp4, avi, mov, dll)"
    echo -e "  ${GREEN}5${NC} - Audio (mp3, wav, flac, dll)"
    echo ""
    read -p "Pilihan: " file_type
    
    local file_options=""
    case $file_type in
        1) file_options="everything,enable" ;;
        2) file_options="everything,disable,doc,enable,xls,enable,ppt,enable,pdf,enable,odt,enable,ods,enable,odp,enable,txt,enable" ;;
        3) file_options="everything,disable,zip,enable,rar,enable,7z,enable,tar,enable,gz,enable,bz2,enable" ;;
        4) file_options="everything,disable,mp4,enable,avi,enable,mov,enable,mkv,enable,wmv,enable,flv,enable" ;;
        5) file_options="everything,disable,mp3,enable,wav,enable,flac,enable,aac,enable,ogg,enable,wma,enable" ;;
        *) file_options="everything,enable" ;;
    esac
    
    echo ""
    echo -e "${RED}[!] PERINGATAN: Jangan write ke device yang sama dengan yang di-recover!${NC}"
    echo ""
    read -p "Lanjutkan? (y/n): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}[!] Dibatalkan oleh user${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}[*] Menjalankan PhotoRec...${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Jalankan photorec
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        photorec /d "$recover_folder" /cmd $target partition_none,options,fileopt,$file_options,search 2>&1 | tee "$LOG_DIR/photorec_all_$(date +%Y%m%d_%H%M%S).log"
    else
        sudo photorec /d "$recover_folder" /cmd $target partition_none,options,fileopt,$file_options,search 2>&1 | tee "$LOG_DIR/photorec_all_$(date +%Y%m%d_%H%M%S).log"
    fi
    
    echo ""
    echo -e "${GREEN}[✓] Recovery selesai!${NC}"
    echo -e "${GREEN}[✓] File disimpan di: $recover_folder${NC}"
    
    # Hitung file yang berhasil di-recover
    local count=$(find "$recover_folder" -type f 2>/dev/null | wc -l)
    echo -e "${GREEN}[✓] Total file yang di-recover: $count${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi deep scan dengan TestDisk
deep_scan() {
    show_banner
    echo -e "${YELLOW}═════════════════ DEEP SCAN ═════════════════${NC}"
    echo ""
    echo -e "${CYAN}Deep Scan menggunakan TestDisk untuk mencari partisi hilang${NC}"
    echo -e "${CYAN}dan file yang tidak terbaca oleh scan biasa${NC}"
    echo ""
    
    detect_storage
    
    echo -e "${YELLOW}Pilih device yang ingin di-deep scan:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        echo -e "${YELLOW}[*] Untuk Termux, deep scan akan scan folder secara mendalam${NC}"
        
        if [ -n "${storage_paths[$choice]}" ]; then
            local target="${storage_paths[$choice]}"
            
            echo ""
            echo -e "${YELLOW}[*] Memulai deep scan folder: $target${NC}"
            echo -e "${YELLOW}[*] Ini mungkin memakan waktu lama...${NC}"
            echo ""
            
            local scan_result="$LOG_DIR/deep_scan_$(date +%Y%m%d_%H%M%S).txt"
            
            echo "=== DEEP SCAN RESULT ===" > "$scan_result"
            echo "Target: $target" >> "$scan_result"
            echo "Date: $(date)" >> "$scan_result"
            echo "" >> "$scan_result"
            
            # Cari file dengan berbagai kondisi
            echo "[*] Mencari file dengan permission aneh..." >> "$scan_result"
            find "$target" -type f -perm -0000 2>/dev/null >> "$scan_result"
            
            echo "" >> "$scan_result"
            echo "[*] Mencari file yang dihapus baru-baru ini..." >> "$scan_result"
            find "$target" -type f -mmin -1440 2>/dev/null >> "$scan_result"  # 24 jam terakhir
            
            echo "" >> "$scan_result"
            echo "[*] Mencari file di semua subfolder..." >> "$scan_result"
            find "$target" -type f -name "*" 2>/dev/null | head -500 >> "$scan_result"
            
            # Cari file yang mungkin corrupt
            echo "" >> "$scan_result"
            echo "[*] File dengan ukuran 0 bytes (mungkin corrupt):" >> "$scan_result"
            find "$target" -type f -size 0 2>/dev/null >> "$scan_result"
            
            # Cari file temporary
            echo "" >> "$scan_result"
            echo "[*] File temporary:" >> "$scan_result"
            find "$target" -name "*.tmp" -o -name "*.temp" -o -name "~*" 2>/dev/null >> "$scan_result"
            
            echo -e "${GREEN}[✓] Deep scan selesai!${NC}"
            echo -e "${GREEN}[✓] Hasil: $scan_result${NC}"
            
            echo ""
            echo -e "${YELLOW}Preview hasil:${NC}"
            head -50 "$scan_result"
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        fi
    else
        # Untuk Kali Linux - gunakan testdisk
        if [ -n "${storage_devices[$choice]}" ]; then
            local target="${storage_devices[$choice]}"
            
            echo ""
            echo -e "${YELLOW}[*] Memulai TestDisk Deep Scan...${NC}"
            echo -e "${YELLOW}[*] Target: $target${NC}"
            echo ""
            echo -e "${CYAN}TestDisk akan membuka interface interaktif${NC}"
            echo -e "${CYAN}Ikuti petunjuk di layar untuk melakukan deep scan${NC}"
            echo ""
            read -p "Tekan Enter untuk membuka TestDisk..."
            
            sudo testdisk $target
        else
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        fi
    fi
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi backup data
backup_data() {
    show_banner
    echo -e "${YELLOW}═════════════════ DATA BACKUP ═════════════════${NC}"
    echo ""
    
    detect_storage
    
    echo -e "${YELLOW}Pilih folder yang ingin di-backup:${NC}"
    read -p "Masukkan nomor: " choice
    
    if [ -z "${storage_paths[$choice]}" ]; then
        echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    local source_path="${storage_paths[$choice]}"
    
    echo ""
    echo -e "${YELLOW}[*] Source: $source_path${NC}"
    echo ""
    echo -e "${CYAN}Pilih jenis backup:${NC}"
    echo -e "  ${GREEN}1${NC} - Full Backup (semua file)"
    echo -e "  ${GREEN}2${NC} - Photo Backup (foto saja)"
    echo -e "  ${GREEN}3${NC} - Document Backup (dokumen saja)"
    echo -e "  ${GREEN}4${NC} - Custom (pilih folder)"
    echo ""
    read -p "Pilihan: " backup_type
    
    local backup_folder="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_folder"
    
    case $backup_type in
        1)
            echo ""
            echo -e "${YELLOW}[*] Memulai full backup...${NC}"
            echo -e "${YELLOW}[*] Ini mungkin memakan waktu lama...${NC}"
            
            tar -czvf "$backup_folder/full_backup.tar.gz" -C "$source_path" . 2>&1 | tee "$LOG_DIR/backup_$(date +%Y%m%d_%H%M%S).log"
            ;;
        2)
            echo ""
            echo -e "${YELLOW}[*] Memulai photo backup...${NC}"
            mkdir -p "$backup_folder/photos"
            
            find "$source_path" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.raw" -o -iname "*.cr2" -o -iname "*.nef" \) -exec cp -v {} "$backup_folder/photos/" \; 2>/dev/null
            ;;
        3)
            echo ""
            echo -e "${YELLOW}[*] Memulai document backup...${NC}"
            mkdir -p "$backup_folder/documents"
            
            find "$source_path" -type f \( -iname "*.doc" -o -iname "*.docx" -o -iname "*.xls" -o -iname "*.xlsx" -o -iname "*.ppt" -o -iname "*.pptx" -o -iname "*.pdf" -o -iname "*.txt" -o -iname "*.odt" \) -exec cp -v {} "$backup_folder/documents/" \; 2>/dev/null
            ;;
        4)
            echo ""
            echo -e "${YELLOW}[*] Masukkan path folder yang ingin di-backup:${NC}"
            echo -e "${CYAN}    Contoh: $source_path/DCIM/Camera${NC}"
            read -p "Path: " custom_path
            
            if [ -d "$custom_path" ]; then
                folder_name=$(basename "$custom_path")
                tar -czvf "$backup_folder/${folder_name}_backup.tar.gz" -C "$custom_path" . 2>&1 | tee "$LOG_DIR/backup_$(date +%Y%m%d_%H%M%S).log"
            else
                echo -e "${RED}[!] Folder tidak ditemukan!${NC}"
            fi
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            ;;
    esac
    
    local size=$(du -sh "$backup_folder" 2>/dev/null | cut -f1)
    echo ""
    echo -e "${GREEN}[✓] Backup selesai!${NC}"
    echo -e "${GREEN}[✓] Lokasi: $backup_folder${NC}"
    echo -e "${GREEN}[✓] Ukuran: $size${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi restore data
restore_data() {
    show_banner
    echo -e "${YELLOW}═════════════════ RESTORE DATA ═════════════════${NC}"
    echo ""
    
    # List available backups
    echo -e "${YELLOW}[*] Backup yang tersedia:${NC}"
    echo ""
    
    local num=1
    declare -A backup_paths
    
    for dir in "$BACKUP_DIR"/*; do
        if [ -d "$dir" ]; then
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            local name=$(basename "$dir")
            echo -e "  ${GREEN}$num${NC} - $name ($size)"
            backup_paths[$num]="$dir"
            ((num++))
        fi
    done
    
    if [ ${#backup_paths[@]} -eq 0 ]; then
        echo -e "${RED}[!] Tidak ada backup yang ditemukan!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo ""
    read -p "Pilih backup yang ingin di-restore: " backup_choice
    
    if [ -z "${backup_paths[$backup_choice]}" ]; then
        echo -e "${RED}[!] Pilihan tidak valid!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    local backup_source="${backup_paths[$backup_choice]}"
    
    echo ""
    echo -e "${YELLOW}[*] Backup source: $backup_source${NC}"
    echo ""
    echo -e "${YELLOW}Pilih lokasi restore:${NC}"
    read -p "Masukkan path tujuan (contoh: /sdcard/Restored): " restore_path
    
    if [ -z "$restore_path" ]; then
        restore_path="/sdcard/Restored_$(date +%Y%m%d_%H%M%S)"
    fi
    
    mkdir -p "$restore_path"
    
    echo ""
    echo -e "${YELLOW}[*] Memulai restore...${NC}"
    
    # Check if it's a tar.gz file
    if ls "$backup_source"/*.tar.gz 1> /dev/null 2>&1; then
        for tarfile in "$backup_source"/*.tar.gz; do
            echo -e "${YELLOW}[*] Extracting $tarfile...${NC}"
            tar -xzvf "$tarfile" -C "$restore_path" 2>&1
        done
    else
        # Copy files directly
        cp -rv "$backup_source"/* "$restore_path/" 2>&1
    fi
    
    echo ""
    echo -e "${GREEN}[✓] Restore selesai!${NC}"
    echo -e "${GREEN}[✓] Lokasi: $restore_path${NC}"
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi view result
view_result() {
    show_banner
    echo -e "${YELLOW}═════════════════ VIEW RESULT ═════════════════${NC}"
    echo ""
    
    echo -e "${CYAN}Pilih kategori:${NC}"
    echo -e "  ${GREEN}1${NC} - Hasil Recovery"
    echo -e "  ${GREEN}2${NC} - Log Files"
    echo -e "  ${GREEN}3${NC} - Backup Files"
    echo ""
    read -p "Pilihan: " view_choice
    
    case $view_choice in
        1)
            echo ""
            echo -e "${YELLOW}[*] Folder hasil recovery:${NC}"
            echo ""
            
            for dir in "$RECOVERED_DIR"/*; do
                if [ -d "$dir" ]; then
                    local count=$(find "$dir" -type f 2>/dev/null | wc -l)
                    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                    local name=$(basename "$dir")
                    echo -e "  ${GREEN}•${NC} $name - $count files ($size)"
                fi
            done
            
            echo ""
            echo -e "${YELLOW}[*] Masukkan nama folder untuk melihat detail (atau Enter untuk kembali):${NC}"
            read -p "Nama: " folder_name
            
            if [ -n "$folder_name" ] && [ -d "$RECOVERED_DIR/$folder_name" ]; then
                echo ""
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                echo -e "${YELLOW}Isi folder $folder_name:${NC}"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                ls -la "$RECOVERED_DIR/$folder_name"
            fi
            ;;
        2)
            echo ""
            echo -e "${YELLOW}[*] Log files:${NC}"
            echo ""
            
            for log in "$LOG_DIR"/*; do
                if [ -f "$log" ]; then
                    local name=$(basename "$log")
                    local size=$(ls -lh "$log" | awk '{print $5}')
                    echo -e "  ${GREEN}•${NC} $name ($size)"
                fi
            done
            
            echo ""
            echo -e "${YELLOW}[*] Masukkan nama log untuk melihat isi (atau Enter untuk kembali):${NC}"
            read -p "Nama: " log_name
            
            if [ -n "$log_name" ] && [ -f "$LOG_DIR/$log_name" ]; then
                echo ""
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                cat "$LOG_DIR/$log_name"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            ;;
        3)
            echo ""
            echo -e "${YELLOW}[*] Backup files:${NC}"
            echo ""
            
            for dir in "$BACKUP_DIR"/*; do
                if [ -d "$dir" ]; then
                    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                    local name=$(basename "$dir")
                    echo -e "  ${GREEN}•${NC} $name ($size)"
                fi
            done
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            ;;
    esac
    
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi menu utama
main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                    RECOVERY MENU                        ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} 📀  Scan Storage        - Scan storage cari file hilang"
        echo -e "  ${GREEN}[2]${NC} 📷  Recover Photo       - Balikin foto yang kehapus"
        echo -e "  ${GREEN}[3]${NC} 📁  Recover All Files   - Recovery semua jenis file"
        echo -e "  ${GREEN}[4]${NC} 🔍  Deep Scan           - Scan mendalam dengan TestDisk"
        echo -e "  ${GREEN}[5]${NC} 💾  Data Backup         - Backup & restore data"
        echo -e "  ${GREEN}[6]${NC} 📊  View Result         - Lihat hasil recovery"
        echo -e "  ${GREEN}[7]${NC} 🛠️  Install Dependencies - Install tool yang dibutuhkan"
        echo -e "  ${RED}[0]${NC} 🚪  Exit                - Keluar dari program"
        echo ""
        echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
        echo ""
        read -p "  Pilih menu [0-7]: " choice
        
        case $choice in
            1) scan_storage ;;
            2) recover_photo ;;
            3) recover_all_files ;;
            4) deep_scan ;;
            5)
                # Submenu backup
                show_banner
                echo -e "${YELLOW}═════════════════ DATA BACKUP MENU ═════════════════${NC}"
                echo ""
                echo -e "  ${GREEN}[1]${NC} 💾 Backup Data"
                echo -e "  ${GREEN}[2]${NC} 📂 Restore Data"
                echo -e "  ${RED}[0]${NC} 🔙 Kembali"
                echo ""
                read -p "  Pilih: " backup_choice
                case $backup_choice in
                    1) backup_data ;;
                    2) restore_data ;;
                esac
                ;;
            6) view_result ;;
            7) install_dependencies ;;
            0)
                echo ""
                echo -e "${GREEN}[*] Terima kasih sudah menggunakan Recovery Tool!${NC}"
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

# Main entry point
main() {
    # Cek apakah script dijalankan sebagai root (untuk Kali Linux)
    if [[ "$EUID" -ne 0 ]] && [[ -z "$TERMUX_VERSION" ]] && [[ "$PREFIX" != "/data/data/com.termux/files/usr" ]]; then
        echo -e "${YELLOW}[!] Beberapa fitur membutuhkan akses root${NC}"
        echo -e "${YELLOW}[!] Jalankan dengan: sudo bash $0${NC}"
        echo ""
    fi
    
    # Cek dependencies
    check_dependencies
    
    # Jalankan menu utama
    main_menu
}

# Jalankan main function
main