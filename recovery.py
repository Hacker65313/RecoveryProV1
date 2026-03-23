#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
========================================================================
RECOVERY TOOL - Data Recovery Suite
Author: MasJawa
IG: @fendipendol65
Engine: PhotoRec & TestDisk
Platform: Termux & Kali Linux
========================================================================
"""

import os
import sys
import subprocess
import shutil
import platform
from datetime import datetime
from pathlib import Path

# Warna ANSI
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    PURPLE = '\033[0;35m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'
    BOLD = '\033[1m'

# Konfigurasi path
SCRIPT_DIR = Path(__file__).parent.resolve()
LOG_DIR = SCRIPT_DIR / "logs"
RECOVERED_DIR = SCRIPT_DIR / "recovered"
BACKUP_DIR = SCRIPT_DIR / "backup"

# Storage paths dictionary
storage_paths = {}
storage_devices = {}

def clear_screen():
    """Bersihkan layar terminal"""
    os.system('clear' if os.name != 'nt' else 'cls')

def print_banner():
    """Tampilkan banner ASCII art"""
    clear_screen()
    banner = f"""
{Colors.CYAN}    ╔═══════════════════════════════════════════════════════════════╗
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
    ╚═══════════════════════════════════════════════════════════════╝{Colors.NC}
"""
    print(banner)

def is_termux():
    """Deteksi apakah berjalan di Termux"""
    return (
        os.environ.get('TERMUX_VERSION') or 
        os.environ.get('PREFIX', '') == '/data/data/com.termux/files/usr'
    )

def check_dependencies():
    """Cek dependencies yang dibutuhkan"""
    print(f"{Colors.YELLOW}[*] Mengecek dependencies...{Colors.NC}")
    
    missing = []
    tools = ['photorec', 'testdisk', 'fdisk', 'file']
    
    for tool in tools:
        if not shutil.which(tool):
            missing.append(tool)
    
    if missing:
        print(f"{Colors.RED}[!] Dependencies tidak ditemukan: {', '.join(missing)}{Colors.NC}")
        print(f"{Colors.YELLOW}[*] Install dengan command berikut:{Colors.NC}\n")
        
        if is_termux():
            print(f"    {Colors.GREEN}pkg update && pkg install -y testdisk fdisk file{Colors.NC}")
        else:
            print(f"    {Colors.GREEN}sudo apt update && sudo apt install -y testdisk fdisk file{Colors.NC}")
        
        print()
        choice = input("Apakah ingin install sekarang? (y/n): ").strip().lower()
        if choice == 'y':
            install_dependencies()
        else:
            print(f"{Colors.RED}[!] Tool mungkin tidak berfungsi dengan baik tanpa dependencies{Colors.NC}")
            input("Tekan Enter untuk melanjutkan...")
    else:
        print(f"{Colors.GREEN}[✓] Semua dependencies sudah terinstall{Colors.NC}")
        import time
        time.sleep(1)

def install_dependencies():
    """Install dependencies"""
    print(f"{Colors.YELLOW}[*] Menginstall dependencies...{Colors.NC}")
    
    if is_termux():
        subprocess.run("pkg update && pkg install -y testdisk fdisk file", shell=True)
    else:
        subprocess.run("sudo apt update && sudo apt install -y testdisk fdisk file", shell=True)
    
    print(f"{Colors.GREEN}[✓] Dependencies berhasil diinstall{Colors.NC}")
    import time
    time.sleep(2)

def detect_storage():
    """Deteksi storage yang tersedia"""
    global storage_paths, storage_devices
    storage_paths = {}
    storage_devices = {}
    
    print(f"{Colors.YELLOW}[*] Mendeteksi storage/storage media...{Colors.NC}\n")
    
    if is_termux():
        print(f"{Colors.CYAN}═══════════════════════════════════════════{Colors.NC}")
        print(f"{Colors.WHITE}  NO.  |  PATH                    |  TYPE  {Colors.NC}")
        print(f"{Colors.CYAN}═══════════════════════════════════════════{Colors.NC}")
        
        num = 1
        
        # Cek sdcard
        if Path("/sdcard").exists():
            print(f"  {Colors.GREEN}{num}{Colors.NC}    |  /sdcard                |  Internal")
            storage_paths[num] = "/sdcard"
            num += 1
        
        # Cek storage emulated
        if Path("/storage/emulated/0").exists():
            print(f"  {Colors.GREEN}{num}{Colors.NC}    |  /storage/emulated/0    |  Internal")
            storage_paths[num] = "/storage/emulated/0"
            num += 1
        
        # Cek external storage
        storage_path = Path("/storage")
        if storage_path.exists():
            for item in storage_path.iterdir():
                if item.is_dir() and item.name not in ['emulated', 'self']:
                    print(f"  {Colors.GREEN}{num}{Colors.NC}    |  {str(item):<23} |  External")
                    storage_paths[num] = str(item)
                    num += 1
        
        print(f"{Colors.CYAN}═══════════════════════════════════════════{Colors.NC}")
    else:
        # Untuk Kali Linux - gunakan lsblk
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════════{Colors.NC}")
        print(f"{Colors.WHITE}  NO.  |  DEVICE      |  SIZE    |  TYPE  |  MOUNTPOINT     {Colors.NC}")
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════════{Colors.NC}")
        
        try:
            result = subprocess.run(['lsblk', '-o', 'NAME,SIZE,TYPE,MOUNTPOINT'], 
                                  capture_output=True, text=True)
            lines = result.stdout.strip().split('\n')
            
            num = 1
            for line in lines[1:]:  # Skip header
                parts = line.split()
                if len(parts) >= 4 and 'loop' not in parts[0]:
                    dev, size, typ, mount = parts[0], parts[1], parts[2], parts[3] if len(parts) > 3 else ''
                    
                    if mount:
                        print(f"  {Colors.GREEN}{num:<3}{Colors.NC}  |  {dev:<10}  |  {size:<6}  |  {typ:<4}  |  {mount:<15}")
                        storage_paths[num] = mount
                        storage_devices[num] = f"/dev/{dev}"
                        num += 1
        except Exception as e:
            print(f"{Colors.RED}[!] Error: {e}{Colors.NC}")
        
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════════{Colors.NC}")
    
    print()

def scan_storage():
    """Scan storage untuk file yang dihapus"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ SCAN STORAGE ═════════════════{Colors.NC}\n")
    
    detect_storage()
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih storage yang ingin di-scan:{Colors.NC} "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    if choice not in storage_paths:
        print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    target_path = storage_paths[choice]
    
    print(f"\n{Colors.YELLOW}[*] Scanning {target_path} untuk file yang terhapus...{Colors.NC}")
    print(f"{Colors.CYAN}[*] Ini mungkin memakan waktu beberapa menit...{Colors.NC}\n")
    
    # Buat folder logs jika belum ada
    LOG_DIR.mkdir(exist_ok=True)
    
    # Buat file hasil scan
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    scan_result = LOG_DIR / f"scan_result_{timestamp}.txt"
    
    with open(scan_result, 'w') as f:
        f.write("=== HASIL SCAN STORAGE ===\n")
        f.write(f"Tanggal: {datetime.now()}\n")
        f.write(f"Target: {target_path}\n\n")
        
        # Cek trash folders
        trash_locations = [
            f"{target_path}/.Trash",
            f"{target_path}/.trash",
            f"{target_path}/.Trashes",
            f"{target_path}/Trash",
            f"{target_path}/.local/share/Trash"
        ]
        
        print(f"{Colors.YELLOW}[*] Mencari file di hidden folders dan trash...{Colors.NC}")
        
        for trash in trash_locations:
            if Path(trash).exists():
                print(f"{Colors.GREEN}[✓] Ditemukan trash folder: {trash}{Colors.NC}")
                f.write(f"\nTrash folder: {trash}\n")
                
                try:
                    for item in Path(trash).rglob('*'):
                        if item.is_file():
                            f.write(f"{item}\n")
                except PermissionError:
                    f.write("  (Permission denied)\n")
        
        # Cari file yang baru dimodifikasi
        f.write("\n=== File yang baru saja dimodifikasi (7 hari terakhir) ===\n")
        try:
            result = subprocess.run(
                ['find', target_path, '-type', 'f', '-mtime', '-7'],
                capture_output=True, text=True
            )
            f.write(result.stdout[:5000])  # Limit output
        except Exception as e:
            f.write(f"Error: {e}\n")
        
        # Cari file hidden
        f.write("\n=== File Hidden ===\n")
        try:
            result = subprocess.run(
                ['find', target_path, '-name', '.*', '-type', 'f'],
                capture_output=True, text=True
            )
            f.write(result.stdout[:5000])
        except Exception as e:
            f.write(f"Error: {e}\n")
    
    print(f"\n{Colors.GREEN}[✓] Scan selesai!{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Hasil disimpan di: {scan_result}{Colors.NC}\n")
    
    print(f"{Colors.YELLOW}Preview hasil:{Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════{Colors.NC}")
    
    with open(scan_result, 'r') as f:
        lines = f.readlines()[:30]
        for line in lines:
            print(line.rstrip())
    
    print(f"{Colors.CYAN}════════════════════════════════════════{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def recover_photo():
    """Recover foto dengan PhotoRec"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ RECOVER PHOTO ═════════════════{Colors.NC}\n")
    print(f"{Colors.CYAN}Tool ini menggunakan PhotoRec untuk recovery foto{Colors.NC}")
    print(f"{Colors.CYAN}Format yang didukung: JPG, PNG, GIF, RAW, CR2, dll{Colors.NC}\n")
    
    detect_storage()
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih storage/device yang ingin di-recover:{Colors.NC} "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    # Tentukan target
    if is_termux():
        if choice in storage_paths:
            target = storage_paths[choice]
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
            input("Tekan Enter untuk kembali...")
            return
    else:
        if choice in storage_devices:
            target = storage_devices[choice]
        elif choice in storage_paths:
            target = storage_paths[choice]
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
            input("Tekan Enter untuk kembali...")
            return
    
    # Buat folder recovery
    RECOVERED_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    recover_folder = RECOVERED_DIR / f"photos_{timestamp}"
    recover_folder.mkdir(exist_ok=True)
    
    print(f"\n{Colors.YELLOW}[*] Memulai PhotoRec untuk recovery foto...{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Target: {target}{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Output: {recover_folder}{Colors.NC}\n")
    print(f"{Colors.RED}[!] PERINGATAN: Jangan write ke device yang sama dengan yang di-recover!{Colors.NC}\n")
    
    confirm = input("Lanjutkan? (y/n): ").strip().lower()
    if confirm != 'y':
        print(f"{Colors.YELLOW}[!] Dibatalkan oleh user{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    print(f"\n{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Menjalankan PhotoRec...{Colors.NC}")
    print(f"{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}\n")
    
    # Jalankan photorec
    cmd = f'photorec /d "{str(recover_folder)}" /cmd {target} partition_none,options,fileopt,everything,disable,raw,enable,jpg,enable,png,enable,gif,enable,bmp,enable,tiff,enable,cr2,enable,search'
    
    if not is_termux():
        cmd = f'sudo {cmd}'
    
    subprocess.run(cmd, shell=True)
    
    # Hitung hasil
    file_count = sum(1 for _ in recover_folder.rglob('*') if _.is_file())
    
    print(f"\n{Colors.GREEN}[✓] Recovery selesai!{Colors.NC}")
    print(f"{Colors.GREEN}[✓] File disimpan di: {recover_folder}{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Total file yang di-recover: {file_count}{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def recover_all_files():
    """Recover semua jenis file"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ RECOVER ALL FILES ═════════════════{Colors.NC}\n")
    print(f"{Colors.CYAN}Tool ini menggunakan PhotoRec untuk recovery semua jenis file{Colors.NC}")
    print(f"{Colors.CYAN}Format yang didukung: Dokumen, Archive, Video, Audio, dll{Colors.NC}\n")
    
    detect_storage()
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih storage/device yang ingin di-recover:{Colors.NC} "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    # Tentukan target
    if is_termux():
        if choice in storage_paths:
            target = storage_paths[choice]
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
            input("Tekan Enter untuk kembali...")
            return
    else:
        if choice in storage_devices:
            target = storage_devices[choice]
        elif choice in storage_paths:
            target = storage_paths[choice]
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
            input("Tekan Enter untuk kembali...")
            return
    
    print(f"\n{Colors.CYAN}Pilih jenis file yang ingin di-recover:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Semua jenis file")
    print(f"  {Colors.GREEN}2{Colors.NC} - Dokumen (doc, xls, ppt, pdf, dll)")
    print(f"  {Colors.GREEN}3{Colors.NC} - Archive (zip, rar, 7z, tar, dll)")
    print(f"  {Colors.GREEN}4{Colors.NC} - Video (mp4, avi, mov, dll)")
    print(f"  {Colors.GREEN}5{Colors.NC} - Audio (mp3, wav, flac, dll)\n")
    
    try:
        file_type = input("Pilihan: ").strip()
    except:
        file_type = "1"
    
    # Buat folder recovery
    RECOVERED_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    recover_folder = RECOVERED_DIR / f"all_files_{timestamp}"
    recover_folder.mkdir(exist_ok=True)
    
    print(f"\n{Colors.RED}[!] PERINGATAN: Jangan write ke device yang sama dengan yang di-recover!{Colors.NC}\n")
    confirm = input("Lanjutkan? (y/n): ").strip().lower()
    
    if confirm != 'y':
        print(f"{Colors.YELLOW}[!] Dibatalkan oleh user{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    # Map file types
    file_options = {
        '1': 'everything,enable',
        '2': 'everything,disable,doc,enable,xls,enable,ppt,enable,pdf,enable',
        '3': 'everything,disable,zip,enable,rar,enable,7z,enable,tar,enable',
        '4': 'everything,disable,mp4,enable,avi,enable,mov,enable,mkv,enable',
        '5': 'everything,disable,mp3,enable,wav,enable,flac,enable,aac,enable'
    }
    
    opt = file_options.get(file_type, 'everything,enable')
    
    print(f"\n{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Menjalankan PhotoRec...{Colors.NC}")
    print(f"{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}\n")
    
    cmd = f'photorec /d "{str(recover_folder)}" /cmd {target} partition_none,options,fileopt,{opt},search'
    
    if not is_termux():
        cmd = f'sudo {cmd}'
    
    subprocess.run(cmd, shell=True)
    
    # Hitung hasil
    file_count = sum(1 for _ in recover_folder.rglob('*') if _.is_file())
    
    print(f"\n{Colors.GREEN}[✓] Recovery selesai!{Colors.NC}")
    print(f"{Colors.GREEN}[✓] File disimpan di: {recover_folder}{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Total file yang di-recover: {file_count}{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def deep_scan():
    """Deep scan dengan TestDisk"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ DEEP SCAN ═════════════════{Colors.NC}\n")
    print(f"{Colors.CYAN}Deep Scan menggunakan TestDisk untuk mencari partisi hilang{Colors.NC}")
    print(f"{Colors.CYAN}dan file yang tidak terbaca oleh scan biasa{Colors.NC}\n")
    
    detect_storage()
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih device yang ingin di-deep scan:{Colors.NC} "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    if is_termux():
        print(f"{Colors.YELLOW}[*] Untuk Termux, deep scan akan scan folder secara mendalam{Colors.NC}")
        
        if choice in storage_paths:
            target = storage_paths[choice]
            
            print(f"\n{Colors.YELLOW}[*] Memulai deep scan folder: {target}{Colors.NC}")
            print(f"{Colors.YELLOW}[*] Ini mungkin memakan waktu lama...{Colors.NC}\n")
            
            LOG_DIR.mkdir(exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            scan_result = LOG_DIR / f"deep_scan_{timestamp}.txt"
            
            with open(scan_result, 'w') as f:
                f.write("=== DEEP SCAN RESULT ===\n")
                f.write(f"Target: {target}\n")
                f.write(f"Date: {datetime.now()}\n\n")
                
                # Scan files
                target_path = Path(target)
                
                f.write("[*] Semua file dalam folder:\n")
                try:
                    for i, item in enumerate(target_path.rglob('*')):
                        if item.is_file():
                            f.write(f"{item}\n")
                            if i > 1000:
                                break
                except PermissionError:
                    f.write("(Permission denied)\n")
                
                # File dengan ukuran 0
                f.write("\n[*] File dengan ukuran 0 bytes:\n")
                try:
                    for item in target_path.rglob('*'):
                        if item.is_file() and item.stat().st_size == 0:
                            f.write(f"{item}\n")
                except:
                    pass
            
            print(f"{Colors.GREEN}[✓] Deep scan selesai!{Colors.NC}")
            print(f"{Colors.GREEN}[✓] Hasil: {scan_result}{Colors.NC}\n")
            
            with open(scan_result, 'r') as f:
                for line in f.readlines()[:50]:
                    print(line.rstrip())
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
    else:
        # Kali Linux - gunakan testdisk
        if choice in storage_devices:
            target = storage_devices[choice]
            
            print(f"\n{Colors.YELLOW}[*] Memulai TestDisk Deep Scan...{Colors.NC}")
            print(f"{Colors.YELLOW}[*] Target: {target}{Colors.NC}\n")
            print(f"{Colors.CYAN}TestDisk akan membuka interface interaktif{Colors.NC}")
            print(f"{Colors.CYAN}Ikuti petunjuk di layar untuk melakukan deep scan{Colors.NC}\n")
            
            input("Tekan Enter untuk membuka TestDisk...")
            
            subprocess.run(['sudo', 'testdisk', target])
        else:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def backup_data():
    """Backup data"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ DATA BACKUP ═════════════════{Colors.NC}\n")
    
    detect_storage()
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih folder yang ingin di-backup:{Colors.NC} "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    if choice not in storage_paths:
        print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    source_path = Path(storage_paths[choice])
    
    print(f"\n{Colors.YELLOW}[*] Source: {source_path}{Colors.NC}\n")
    print(f"{Colors.CYAN}Pilih jenis backup:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Full Backup (semua file)")
    print(f"  {Colors.GREEN}2{Colors.NC} - Photo Backup (foto saja)")
    print(f"  {Colors.GREEN}3{Colors.NC} - Document Backup (dokumen saja)")
    print(f"  {Colors.GREEN}4{Colors.NC} - Custom (pilih folder)\n")
    
    try:
        backup_type = input("Pilihan: ").strip()
    except:
        backup_type = "1"
    
    BACKUP_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_folder = BACKUP_DIR / f"backup_{timestamp}"
    backup_folder.mkdir(exist_ok=True)
    
    if backup_type == '1':
        print(f"\n{Colors.YELLOW}[*] Memulai full backup...{Colors.NC}")
        print(f"{Colors.YELLOW}[*] Ini mungkin memakan waktu lama...{Colors.NC}")
        
        archive_path = backup_folder / "full_backup.tar.gz"
        subprocess.run(['tar', '-czvf', str(archive_path), '-C', str(source_path), '.'])
        
    elif backup_type == '2':
        print(f"\n{Colors.YELLOW}[*] Memulai photo backup...{Colors.NC}")
        photo_folder = backup_folder / "photos"
        photo_folder.mkdir(exist_ok=True)
        
        photo_exts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.raw', '.cr2', '.nef']
        
        for ext in photo_exts:
            for photo in source_path.rglob(f'*{ext}'):
                try:
                    shutil.copy2(photo, photo_folder / photo.name)
                    print(f"  Copied: {photo.name}")
                except Exception as e:
                    print(f"  Error copying {photo.name}: {e}")
                    
    elif backup_type == '3':
        print(f"\n{Colors.YELLOW}[*] Memulai document backup...{Colors.NC}")
        doc_folder = backup_folder / "documents"
        doc_folder.mkdir(exist_ok=True)
        
        doc_exts = ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.pdf', '.txt', '.odt']
        
        for ext in doc_exts:
            for doc in source_path.rglob(f'*{ext}'):
                try:
                    shutil.copy2(doc, doc_folder / doc.name)
                    print(f"  Copied: {doc.name}")
                except Exception as e:
                    print(f"  Error copying {doc.name}: {e}")
                    
    elif backup_type == '4':
        print(f"\n{Colors.YELLOW}[*] Masukkan path folder yang ingin di-backup:{Colors.NC}")
        print(f"{Colors.CYAN}    Contoh: {source_path}/DCIM/Camera{Colors.NC}")
        
        custom_path = input("Path: ").strip()
        custom_path = Path(custom_path)
        
        if custom_path.exists() and custom_path.is_dir():
            folder_name = custom_path.name
            archive_path = backup_folder / f"{folder_name}_backup.tar.gz"
            subprocess.run(['tar', '-czvf', str(archive_path), '-C', str(custom_path), '.'])
        else:
            print(f"{Colors.RED}[!] Folder tidak ditemukan!{Colors.NC}")
    else:
        print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
    
    # Hitung ukuran
    total_size = sum(f.stat().st_size for f in backup_folder.rglob('*') if f.is_file())
    size_mb = total_size / (1024 * 1024)
    
    print(f"\n{Colors.GREEN}[✓] Backup selesai!{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Lokasi: {backup_folder}{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Ukuran: {size_mb:.2f} MB{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def restore_data():
    """Restore data dari backup"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ RESTORE DATA ═════════════════{Colors.NC}\n")
    
    # List backups
    print(f"{Colors.YELLOW}[*] Backup yang tersedia:{Colors.NC}\n")
    
    if not BACKUP_DIR.exists():
        print(f"{Colors.RED}[!] Tidak ada backup yang ditemukan!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    backups = list(BACKUP_DIR.iterdir())
    
    if not backups:
        print(f"{Colors.RED}[!] Tidak ada backup yang ditemukan!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    backup_list = {}
    for i, backup in enumerate(backups, 1):
        if backup.is_dir():
            total_size = sum(f.stat().st_size for f in backup.rglob('*') if f.is_file())
            size_mb = total_size / (1024 * 1024)
            print(f"  {Colors.GREEN}{i}{Colors.NC} - {backup.name} ({size_mb:.2f} MB)")
            backup_list[i] = backup
    
    print()
    try:
        choice = int(input("Pilih backup yang ingin di-restore: "))
    except ValueError:
        print(f"{Colors.RED}[!] Input tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    if choice not in backup_list:
        print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
        input("Tekan Enter untuk kembali...")
        return
    
    backup_source = backup_list[choice]
    
    print(f"\n{Colors.YELLOW}[*] Backup source: {backup_source}{Colors.NC}\n")
    print(f"{Colors.YELLOW}Pilih lokasi restore:{Colors.NC}")
    
    restore_path = input("Masukkan path tujuan (contoh: /sdcard/Restored): ").strip()
    
    if not restore_path:
        restore_path = f"/sdcard/Restored_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    restore_path = Path(restore_path)
    restore_path.mkdir(parents=True, exist_ok=True)
    
    print(f"\n{Colors.YELLOW}[*] Memulai restore...{Colors.NC}")
    
    # Check for tar.gz files
    tar_files = list(backup_source.glob('*.tar.gz'))
    
    if tar_files:
        for tar_file in tar_files:
            print(f"{Colors.YELLOW}[*] Extracting {tar_file.name}...{Colors.NC}")
            subprocess.run(['tar', '-xzvf', str(tar_file), '-C', str(restore_path)])
    else:
        # Copy files directly
        for item in backup_source.iterdir():
            if item.is_file():
                shutil.copy2(item, restore_path)
                print(f"  Copied: {item.name}")
            elif item.is_dir():
                dest = restore_path / item.name
                shutil.copytree(item, dest, dirs_exist_ok=True)
                print(f"  Copied folder: {item.name}")
    
    print(f"\n{Colors.GREEN}[✓] Restore selesai!{Colors.NC}")
    print(f"{Colors.GREEN}[✓] Lokasi: {restore_path}{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def view_result():
    """Lihat hasil recovery"""
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ VIEW RESULT ═════════════════{Colors.NC}\n")
    
    print(f"{Colors.CYAN}Pilih kategori:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Hasil Recovery")
    print(f"  {Colors.GREEN}2{Colors.NC} - Log Files")
    print(f"  {Colors.GREEN}3{Colors.NC} - Backup Files\n")
    
    try:
        view_choice = input("Pilihan: ").strip()
    except:
        return
    
    if view_choice == '1':
        print(f"\n{Colors.YELLOW}[*] Folder hasil recovery:{Colors.NC}\n")
        
        if not RECOVERED_DIR.exists():
            print(f"{Colors.RED}[!] Tidak ada hasil recovery!{Colors.NC}")
        else:
            for folder in RECOVERED_DIR.iterdir():
                if folder.is_dir():
                    file_count = sum(1 for _ in folder.rglob('*') if _.is_file())
                    print(f"  {Colors.GREEN}•{Colors.NC} {folder.name} - {file_count} files")
        
    elif view_choice == '2':
        print(f"\n{Colors.YELLOW}[*] Log files:{Colors.NC}\n")
        
        if not LOG_DIR.exists():
            print(f"{Colors.RED}[!] Tidak ada log files!{Colors.NC}")
        else:
            for log in LOG_DIR.iterdir():
                if log.is_file():
                    size = log.stat().st_size
                    print(f"  {Colors.GREEN}•{Colors.NC} {log.name} ({size} bytes)")
        
    elif view_choice == '3':
        print(f"\n{Colors.YELLOW}[*] Backup files:{Colors.NC}\n")
        
        if not BACKUP_DIR.exists():
            print(f"{Colors.RED}[!] Tidak ada backup files!{Colors.NC}")
        else:
            for folder in BACKUP_DIR.iterdir():
                if folder.is_dir():
                    total_size = sum(f.stat().st_size for f in folder.rglob('*') if f.is_file())
                    size_mb = total_size / (1024 * 1024)
                    print(f"  {Colors.GREEN}•{Colors.NC} {folder.name} ({size_mb:.2f} MB)")
    
    input("\nTekan Enter untuk kembali...")

def main_menu():
    """Menu utama"""
    while True:
        print_banner()
        
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}")
        print(f"{Colors.WHITE}                    RECOVERY MENU                        {Colors.NC}")
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}")
        print()
        print(f"  {Colors.GREEN}[1]{Colors.NC} 📀  Scan Storage        - Scan storage cari file hilang")
        print(f"  {Colors.GREEN}[2]{Colors.NC} 📷  Recover Photo       - Balikin foto yang kehapus")
        print(f"  {Colors.GREEN}[3]{Colors.NC} 📁  Recover All Files   - Recovery semua jenis file")
        print(f"  {Colors.GREEN}[4]{Colors.NC} 🔍  Deep Scan           - Scan mendalam dengan TestDisk")
        print(f"  {Colors.GREEN}[5]{Colors.NC} 💾  Data Backup         - Backup & restore data")
        print(f"  {Colors.GREEN}[6]{Colors.NC} 📊  View Result         - Lihat hasil recovery")
        print(f"  {Colors.GREEN}[7]{Colors.NC} 🛠️  Install Dependencies - Install tool yang dibutuhkan")
        print(f"  {Colors.RED}[0]{Colors.NC} 🚪  Exit                - Keluar dari program")
        print()
        print(f"{Colors.CYAN}══════════════════════════════════════════════════════════{Colors.NC}")
        print()
        
        try:
            choice = input("  Pilih menu [0-7]: ").strip()
        except EOFError:
            continue
        
        if choice == '1':
            scan_storage()
        elif choice == '2':
            recover_photo()
        elif choice == '3':
            recover_all_files()
        elif choice == '4':
            deep_scan()
        elif choice == '5':
            print_banner()
            print(f"{Colors.YELLOW}═════════════════ DATA BACKUP MENU ═════════════════{Colors.NC}\n")
            print(f"  {Colors.GREEN}[1]{Colors.NC} 💾 Backup Data")
            print(f"  {Colors.GREEN}[2]{Colors.NC} 📂 Restore Data")
            print(f"  {Colors.RED}[0]{Colors.NC} 🔙 Kembali\n")
            
            try:
                backup_choice = input("  Pilih: ").strip()
            except:
                continue
            
            if backup_choice == '1':
                backup_data()
            elif backup_choice == '2':
                restore_data()
        elif choice == '6':
            view_result()
        elif choice == '7':
            install_dependencies()
        elif choice == '0':
            print()
            print(f"{Colors.GREEN}[*] Terima kasih sudah menggunakan Recovery Tool!{Colors.NC}")
            print(f"{Colors.GREEN}[*] Author: MasJawa | IG: @fendipendol65{Colors.NC}")
            print()
            sys.exit(0)

def main():
    """Entry point utama"""
    # Buat folder yang dibutuhkan
    LOG_DIR.mkdir(exist_ok=True)
    RECOVERED_DIR.mkdir(exist_ok=True)
    BACKUP_DIR.mkdir(exist_ok=True)
    
    # Cek dependencies
    check_dependencies()
    
    # Jalankan menu utama
    main_menu()

if __name__ == "__main__":
    main()