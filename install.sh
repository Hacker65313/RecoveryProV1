#!/bin/bash

# ============================================
# INSTALLER - Recovery Tool
# Author: MasJawa
# IG: fendipendol65
# ============================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner Installer
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║           ████████╗███████╗██████╗ ███╗   ███╗               ║
    ║           ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║               ║
    ║              ██║   █████╗  ██████╔╝██╔████╔██║               ║
    ║              ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║               ║
    ║              ██║   ███████╗██║  ██║██║ ╚═╝ ██║               ║
    ║              ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝               ║
    ║                                                               ║
    ║               RECOVERY TOOL INSTALLER                        ║
    ║                                                               ║
    ║            Author: MasJawa | IG: @fendipendol65              ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Deteksi OS
detect_os() {
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        echo "termux"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Install dependencies
install_dependencies() {
    local os=$(detect_os)
    
    echo -e "${YELLOW}[*] Mendeteksi sistem: $os${NC}"
    echo ""
    
    case $os in
        termux)
            echo -e "${YELLOW}[*] Menginstall dependencies untuk Termux...${NC}"
            pkg update -y
            pkg install -y wget curl git
            pkg install -y testdisk
            pkg install -y fdisk
            pkg install -y file
            pkg install -y tar
            pkg install -y coreutils
            ;;
        kali|ubuntu|debian)
            echo -e "${YELLOW}[*] Menginstall dependencies untuk $os...${NC}"
            sudo apt update -y
            sudo apt install -y wget curl git
            sudo apt install -y testdisk
            sudo apt install -y fdisk
            sudo apt install -y file
            sudo apt install -y tar
            sudo apt install -y coreutils
            ;;
        *)
            echo -e "${RED}[!] Sistem operasi tidak dikenali: $os${NC}"
            echo -e "${YELLOW}[*] Coba install manual dengan package manager sistem Anda${NC}"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}[✓] Dependencies berhasil diinstall!${NC}"
}

# Setup folder
setup_folders() {
    echo ""
    echo -e "${YELLOW}[*] Membuat struktur folder...${NC}"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/recovered"
    mkdir -p "$SCRIPT_DIR/backup"
    
    echo -e "${GREEN}[✓] Folder berhasil dibuat!${NC}"
    echo -e "    ${CYAN}• logs/ - Untuk menyimpan log${NC}"
    echo -e "    ${CYAN}• recovered/ - Untuk hasil recovery${NC}"
    echo -e "    ${CYAN}• backup/ - Untuk backup data${NC}"
}

# Set permission
set_permission() {
    echo ""
    echo -e "${YELLOW}[*] Mengatur permission...${NC}"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    chmod +x "$SCRIPT_DIR/recovery.sh"
    chmod +x "$SCRIPT_DIR/install.sh"
    
    echo -e "${GREEN}[✓] Permission berhasil diatur!${NC}"
}

# Create alias
create_alias() {
    echo ""
    echo -e "${YELLOW}[*] Membuat command alias...${NC}"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    local shell_rc=""
    
    if [[ -n "$TERMUX_VERSION" ]] || [[ "$PREFIX" == "/data/data/com.termux/files/usr" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        if [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            shell_rc="$HOME/.zshrc"
        fi
    fi
    
    if [ -n "$shell_rc" ]; then
        # Cek apakah alias sudah ada
        if ! grep -q "alias recovery=" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Recovery Tool Alias" >> "$shell_rc"
            echo "alias recovery='bash $SCRIPT_DIR/recovery.sh'" >> "$shell_rc"
            
            echo -e "${GREEN}[✓] Alias 'recovery' berhasil dibuat!${NC}"
            echo -e "    ${CYAN}Jalankan 'source $shell_rc' atau buka terminal baru${NC}"
        else
            echo -e "${YELLOW}[!] Alias sudah ada, skip...${NC}"
        fi
    fi
}

# Verify installation
verify_installation() {
    echo ""
    echo -e "${YELLOW}[*] Memverifikasi instalasi...${NC}"
    echo ""
    
    local all_ok=true
    
    # Cek photorec
    if command -v photorec &> /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} PhotoRec terinstall"
    else
        echo -e "  ${RED}[✗]${NC} PhotoRec tidak ditemukan"
        all_ok=false
    fi
    
    # Cek testdisk
    if command -v testdisk &> /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} TestDisk terinstall"
    else
        echo -e "  ${RED}[✗]${NC} TestDisk tidak ditemukan"
        all_ok=false
    fi
    
    # Cek script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/recovery.sh" ]; then
        echo -e "  ${GREEN}[✓]${NC} recovery.sh tersedia"
    else
        echo -e "  ${RED}[✗]${NC} recovery.sh tidak ditemukan"
        all_ok=false
    fi
    
    if [ "$all_ok" = true ]; then
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}      INSTALASI BERHASIL! 🎉              ${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Cara menjalankan:${NC}"
        echo -e "  ${CYAN}cd $SCRIPT_DIR${NC}"
        echo -e "  ${CYAN}./recovery.sh${NC}"
        echo ""
        echo -e "${YELLOW}Atau gunakan alias:${NC}"
        echo -e "  ${CYAN}recovery${NC}"
        echo ""
    else
        echo ""
        echo -e "${RED}═══════════════════════════════════════════${NC}"
        echo -e "${RED}      INSTALASI SELESAI DENGAN ERROR      ${NC}"
        echo -e "${RED}═══════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Beberapa dependencies mungkin perlu diinstall manual${NC}"
    fi
}

# Main installer
main() {
    show_banner
    
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              MEMULAI INSTALASI                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    
    install_dependencies
    setup_folders
    set_permission
    create_alias
    verify_installation
    
    echo ""
    echo -e "${GREEN}Terima kasih telah menggunakan Recovery Tool!${NC}"
    echo -e "${GREEN}Author: MasJawa | IG: @fendipendol65${NC}"
    echo ""
}

# Run main
main