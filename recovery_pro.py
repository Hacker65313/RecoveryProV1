#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
========================================================================
RECOVERY TOOL PRO v1 - Data Recovery Suite
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
import zipfile
import json
import time
import hashlib
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# ============ KONFIGURASI ============
SCRIPT_DIR = Path(__file__).parent.resolve()
LOG_DIR = SCRIPT_DIR / "logs"
RECOVERED_DIR = SCRIPT_DIR / "recovered"
BACKUP_DIR = SCRIPT_DIR / "backup"
CONFIG_FILE = SCRIPT_DIR / "config.json"
SESSION_COUNTER_FILE = SCRIPT_DIR / ".session_counter"

# Telegram config
TELEGRAM_BOT_TOKEN = "8658387381:AAEdDeTQZ_L7o4b79HoZJcAXJKpxWAcMqCQ"
TELEGRAM_CHAT_ID = "7302150"

# ============ WARNA ANSI ============
class Colors:
    BG_RED = '\033[41m'
    BG_GREEN = '\033[42m'
    BG_YELLOW = '\033[43m'
    BG_CYAN = '\033[46m'
    
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    
    BOLD = '\033[1m'
    DIM = '\033[2m'
    NC = '\033[0m'

# ============ PROGRESS BAR ============
class ProgressBar:
    SPINNER = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
    
    @staticmethod
    def show(current: int, total: int, prefix: str = ""):
        if total == 0:
            return
        percent = min(100, int((current / total) * 100))
        bar_length = 40
        filled = int(bar_length * percent / 100)
        bar = f"{Colors.GREEN}{'█' * filled}{Colors.NC}{Colors.DIM}{'░' * (bar_length - filled)}{Colors.NC}"
        sys.stdout.write(f"\r{prefix} [{bar}] {percent}%")
        sys.stdout.flush()
    
    @staticmethod
    def spinner(message: str, duration: float = 2.0):
        start = time.time()
        i = 0
        while time.time() - start < duration:
            spin = ProgressBar.SPINNER[i % len(ProgressBar.SPINNER)]
            sys.stdout.write(f"\r{Colors.CYAN}{spin}{Colors.NC} {message}")
            sys.stdout.flush()
            time.sleep(0.1)
            i += 1
        sys.stdout.write("\r" + " " * (len(message) + 10) + "\r")
        sys.stdout.flush()

# ============ SESSION SYSTEM ============
class SessionManager:
    def __init__(self, base_dir: Path):
        self.base_dir = base_dir
        self.current_date = datetime.now().strftime("%Y-%m-%d")
    
    def get_next_session_number(self) -> int:
        if SESSION_COUNTER_FILE.exists():
            try:
                with open(SESSION_COUNTER_FILE, 'r') as f:
                    data = json.load(f)
                if data.get('date') == self.current_date:
                    return data.get('counter', 0) + 1
            except: pass
        return 1
    
    def save_session_number(self, number: int):
        with open(SESSION_COUNTER_FILE, 'w') as f:
            json.dump({'date': self.current_date, 'counter': number}, f)
    
    def create_session_folder(self) -> Path:
        session_num = self.get_next_session_number()
        session_name = f"Recovery_{self.current_date}_{session_num:03d}"
        session_path = self.base_dir / session_name
        session_path.mkdir(parents=True, exist_ok=True)
        self.save_session_number(session_num)
        return session_path
    
    def list_sessions(self) -> List[Path]:
        if not self.base_dir.exists():
            return []
        return sorted([d for d in self.base_dir.iterdir() if d.is_dir() and d.name.startswith("Recovery_")], 
                     key=lambda x: x.name, reverse=True)

# ============ STORAGE SAFETY ============
class StorageSafety:
    @staticmethod
    def get_storage_info(path: str) -> Dict:
        try:
            stat = os.statvfs(path)
            total = stat.f_blocks * stat.f_frsize
            free = stat.f_bavail * stat.f_frsize
            used = total - free
            percent_used = (used / total) * 100 if total > 0 else 0
            return {'total': total, 'free': free, 'used': used, 'percent_used': percent_used}
        except:
            return {'total': 0, 'free': 0, 'used': 0, 'percent_used': 0}
    
    @staticmethod
    def check_storage(path: str) -> Tuple[bool, str]:
        info = StorageSafety.get_storage_info(path)
        if info['percent_used'] > 95:
            return False, "CRITICAL"
        elif info['percent_used'] > 90:
            return False, "WARNING"
        return True, "OK"
    
    @staticmethod
    def show_warning(status: str, info: Dict):
        free_gb = info['free'] / (1024 * 1024 * 1024)
        if status == "CRITICAL":
            print(f"""
{Colors.BG_RED}{Colors.WHITE}
  ╔═══════════════════════════════════════════════════════════════╗
  ║  🚨 STORAGE CRITICAL - RECOVERY BERISIKO GAGAL! 🚨           ║
  ╠═══════════════════════════════════════════════════════════════╣
  ║  Storage hampir penuh! Sisa: {free_gb:.1f} GB                      ║
  ║  [!] Recovery bisa gagal karena tidak cukup ruang!           ║
  ╚═══════════════════════════════════════════════════════════════╝
{Colors.NC}""")
        elif status == "WARNING":
            print(f"""
{Colors.BG_YELLOW}  ⚠️  STORAGE WARNING - Sisa: {free_gb:.1f} GB  {Colors.NC}
  [!] Recovery mungkin gagal jika file besar ditemukan!
""")

# ============ TELEGRAM BOT ============
class TelegramBot:
    def __init__(self, token: str = "", chat_id: str = ""):
        self.token = token
        self.chat_id = chat_id
    
    def set_credentials(self, token: str, chat_id: str):
        self.token = token
        self.chat_id = chat_id
    
    def send_message(self, text: str) -> bool:
        if not self.token or not self.chat_id:
            return False
        try:
            url = f"https://api.telegram.org/bot{self.token}/sendMessage"
            data = urllib.parse.urlencode({'chat_id': self.chat_id, 'text': text, 'parse_mode': 'HTML'}).encode()
            req = urllib.request.Request(url, data=data)
            urllib.request.urlopen(req, timeout=30)
            return True
        except:
            return False
    
    def send_recovery_complete(self, photos: int, videos: int, docs: int, wa: int, 
                                others: int, size_mb: float, location: str) -> bool:
        text = f"""✅ <b>RECOVERY SELESAI</b>

📊 <b>Hasil:</b>
├─ 📷 Foto ditemukan: {photos}
├─ 📹 Video: {videos}
├─ 📄 Dokumen: {docs}
├─ 📱 WhatsApp Photos: {wa}
└─ 📦 Lainnya: {others}

💾 <b>Total Size:</b> {size_mb:.1f} MB
📁 <b>Lokasi:</b> <code>{location}</code>

<i>Recovery Tool Pro by MasJawa | IG: @fendipendol65</i>"""
        return self.send_message(text)
    
    def send_recovery_start(self, target: str, mode: str) -> bool:
        text = f"""🔄 <b>RECOVERY DIMULAI</b>

📍 Target: <code>{target}</code>
📋 Mode: {mode}
⏰ Waktu: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

<i>Mohon jangan gunakan device selama proses...</i>"""
        return self.send_message(text)

# ============ ANALYSIS RESULT ============
class AnalysisResult:
    def __init__(self):
        self.total_files = 0
        self.successful = 0
        self.failed = 0
        self.total_size = 0
        self.photos = 0
        self.videos = 0
        self.documents = 0
        self.others = 0
        self.whatsapp_photos = 0
    
    @property
    def total_size_mb(self) -> float:
        return self.total_size / (1024 * 1024)
    
    def to_dict(self) -> dict:
        return {
            'total_files': self.total_files, 'successful': self.successful,
            'total_size': self.total_size, 'total_size_mb': round(self.total_size_mb, 2),
            'photos': self.photos, 'videos': self.videos, 'documents': self.documents,
            'whatsapp_photos': self.whatsapp_photos, 'others': self.others
        }

# ============ FILE TYPES ============
class FileTypes:
    PHOTOS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.raw', '.cr2', '.nef', '.arw', '.dng', '.webp'}
    VIDEOS = {'.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', '.webm', '.3gp'}
    DOCUMENTS = {'.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.pdf', '.txt', '.odt'}
    
    WHATSAPP_IMAGES = [
        '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
        '/sdcard/WhatsApp/Media/WhatsApp Images',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Images'
    ]
    CAMERA_DCIM = ['/sdcard/DCIM/Camera', '/sdcard/DCIM', '/storage/emulated/0/DCIM/Camera', '/storage/emulated/0/DCIM']
    SCREENSHOTS = ['/sdcard/Pictures/Screenshots', '/sdcard/DCIM/Screenshots', '/storage/emulated/0/Pictures/Screenshots']

# ============ SMART SORTING ============
class SmartSorting:
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.categories = {
            'photos': output_dir / "Photos", 'videos': output_dir / "Videos",
            'documents': output_dir / "Documents", 'whatsapp_photos': output_dir / "WhatsApp_Photos",
            'others': output_dir / "Others"
        }
        for folder in self.categories.values():
            folder.mkdir(parents=True, exist_ok=True)
    
    def detect_category(self, file_path: Path) -> str:
        ext = file_path.suffix.lower()
        name = file_path.name
        
        if name.startswith(('IMG-', 'WA-', 'WhatsApp Image')):
            if ext in {'.jpg', '.jpeg', '.png'}:
                return 'whatsapp_photos'
        
        if ext in FileTypes.PHOTOS: return 'photos'
        elif ext in FileTypes.VIDEOS: return 'videos'
        elif ext in FileTypes.DOCUMENTS: return 'documents'
        return 'others'
    
    def auto_rename(self, file_path: Path, category: str) -> str:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        ext = file_path.suffix.lower()
        try:
            with open(file_path, 'rb') as f:
                file_hash = hashlib.md5(f.read(1024)).hexdigest()[:8]
        except:
            file_hash = f"{time.time():.0f}"[-8:]
        
        prefix = {'photos': 'PHOTO', 'videos': 'VIDEO', 'documents': 'DOC', 
                  'whatsapp_photos': 'WA', 'others': 'FILE'}.get(category, 'FILE')
        return f"{prefix}_{timestamp}_{file_hash}{ext}"
    
    def sort_file(self, source: Path, auto_rename: bool = True) -> Tuple[Path, str]:
        category = self.detect_category(source)
        dest_folder = self.categories[category]
        dest_name = self.auto_rename(source, category) if auto_rename else source.name
        dest_path = dest_folder / dest_name
        
        counter = 1
        while dest_path.exists():
            dest_path = dest_folder / f"{dest_path.stem}_{counter}{dest_path.suffix}"
            counter += 1
        return dest_path, category

# ============ UTILITIES ============
def clear_screen():
    os.system('clear' if os.name != 'nt' else 'cls')

def is_termux() -> bool:
    return os.environ.get('TERMUX_VERSION') or os.environ.get('PREFIX', '') == '/data/data/com.termux/files/usr'

def format_size(size_bytes: int) -> str:
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.2f} PB"

def check_dependencies() -> List[str]:
    missing = []
    for tool in ['photorec', 'testdisk']:
        if not shutil.which(tool):
            missing.append(tool)
    return missing

def install_dependencies():
    print(f"{Colors.YELLOW}[*] Menginstall dependencies...{Colors.NC}")
    if is_termux():
        subprocess.run("pkg update && pkg install -y testdisk fdisk file curl", shell=True)
    else:
        subprocess.run("sudo apt update && sudo apt install -y testdisk fdisk file curl", shell=True)
    print(f"{Colors.GREEN}[✓] Dependencies berhasil diinstall{Colors.NC}")

def get_storage_paths() -> Dict[int, str]:
    paths = {}
    num = 1
    if is_termux():
        if Path("/sdcard").exists(): paths[num] = "/sdcard"; num += 1
        if Path("/storage/emulated/0").exists(): paths[num] = "/storage/emulated/0"; num += 1
        storage = Path("/storage")
        if storage.exists():
            for item in storage.iterdir():
                if item.is_dir() and item.name not in ['emulated', 'self']:
                    paths[num] = str(item); num += 1
    else:
        try:
            result = subprocess.run(['lsblk', '-o', 'NAME,SIZE,TYPE,MOUNTPOINT'], capture_output=True, text=True)
            for line in result.stdout.strip().split('\n')[1:]:
                parts = line.split()
                if len(parts) >= 4 and 'loop' not in parts[0]:
                    paths[num] = parts[3]; num += 1
        except: pass
    return paths

# ============ RESULT SUMMARY ============
def show_result_summary(result: AnalysisResult, location: str, session_name: str):
    print(f"""
{Colors.GREEN}╔═════════════════════════════════════════════════════════════════════╗
║                     ✅ RECOVERY SELESAI!                             ║
╚═════════════════════════════════════════════════════════════════════╝{Colors.NC}

{Colors.WHITE}📋 SESSION: {Colors.CYAN}{session_name}{Colors.NC}

{Colors.WHITE}📊 HASIL RECOVERY:{Colors.NC}
┌─────────────────────────────────────────────────────────────────────┐
│  📷 Foto ditemukan    : {Colors.GREEN}{result.photos:>6}{Colors.NC}                              │
│  📹 Video             : {Colors.GREEN}{result.videos:>6}{Colors.NC}                              │
│  📄 Dokumen           : {Colors.GREEN}{result.documents:>6}{Colors.NC}                              │
│  📱 WhatsApp Photos   : {Colors.GREEN}{result.whatsapp_photos:>6}{Colors.NC}                              │
│  📦 Lainnya           : {Colors.GREEN}{result.others:>6}{Colors.NC}                              │
├─────────────────────────────────────────────────────────────────────┤
│  📁 Total File        : {Colors.CYAN}{result.total_files:>6}{Colors.NC}                              │
│  💾 Total Size        : {Colors.CYAN}{result.total_size_mb:>6.1f} MB{Colors.NC}                         │
└─────────────────────────────────────────────────────────────────────┘

{Colors.WHITE}📂 LOKASI:{Colors.NC}
   {Colors.CYAN}{location}{Colors.NC}

""")

# ============ BANNER ============
def print_banner():
    clear_screen()
    print(f"""
{Colors.CYAN}    ╔═════════════════════════════════════════════════════════════════════╗
    ║{Colors.WHITE}  ██████╗ ███████╗███████╗██████╗  ██████╗ █████╗ ███████╗██╗        {Colors.CYAN}║
    ║{Colors.WHITE} ██╔════╝ ██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║        {Colors.CYAN}║
    ║{Colors.WHITE} ██║  ███╗█████╗  █████╗  ██████╔╝██║     ███████║███████╗██║        {Colors.CYAN}║
    ║{Colors.WHITE} ██║   ██║██╔══╝  ██╔══╝  ██╔══██╗██║     ██╔══██║╚════██║██║        {Colors.CYAN}║
    ║{Colors.WHITE} ╚██████╔╝███████╗███████╗██║  ██║╚██████╗██║  ██║███████║██║        {Colors.CYAN}║
    ║{Colors.WHITE}  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝        {Colors.CYAN}║
    ║                                                                   ║
    ║{Colors.WHITE}   ███████╗██████╗ ██╗   ██╗███████╗████████╗███████╗██████╗        {Colors.CYAN}║
    ║{Colors.WHITE}   ██╔════╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗       {Colors.CYAN}║
    ║{Colors.WHITE}   █████╗  ██████╔╝██║   ██║███████╗   ██║   █████╗  ██████╔╝       {Colors.CYAN}║
    ║{Colors.WHITE}   ██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗       {Colors.CYAN}║
    ║{Colors.WHITE}   ██║     ██║  ██║╚██████╔╝███████║   ██║   ███████╗██║  ██║       {Colors.CYAN}║
    ║{Colors.WHITE}   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝       {Colors.CYAN}║
    ║                                                                   ║
    ╠═════════════════════════════════════════════════════════════════════╣
    ║{Colors.GREEN}            🛠️  DATA RECOVERY SUITE PRO v3.1 🛠️                  {Colors.CYAN}║
    ║                                                                   ║
    ║{Colors.MAGENTA}   ┌──────────────────────────────────────────────────────┐   {Colors.CYAN}║
    ║{Colors.MAGENTA}   │{Colors.WHITE}  Author: MasJawa                                    │   {Colors.CYAN}║
    ║{Colors.MAGENTA}   │{Colors.WHITE}  IG: @fendipendol65                             │   {Colors.CYAN}║
    ║{Colors.MAGENTA}   └──────────────────────────────────────────────────────┘   {Colors.CYAN}║
    ╚═════════════════════════════════════════════════════════════════════╝{Colors.NC}
""")

def print_warning():
    print(f"""
{Colors.BG_RED}{Colors.WHITE}  ╔═══════════════════════════════════════════════════════════════════╗  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ║                    ⚠️  PERINGATAN PENTING ⚠️                      ║  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ╠═══════════════════════════════════════════════════════════════════╣  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ║  [!] JANGAN GUNAKAN HP SELAMA PROSES RECOVERY!                   ║  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ║  [!] HINDARI OVERWRITE DATA - Jangan simpan file baru!           ║  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ║  [!] STOP penggunaan device untuk hasil recovery maksimal!       ║  {Colors.NC}
{Colors.BG_RED}{Colors.WHITE}  ╚═══════════════════════════════════════════════════════════════════╝  {Colors.NC}
""")

def print_menu():
    print(f"""
{Colors.CYAN}╔═════════════════════════════════════════════════════════════════════╗
║{Colors.WHITE}                      📱 RECOVERY MENU PRO v3.1                    {Colors.CYAN}║
╠═════════════════════════════════════════════════════════════════════╣{Colors.NC}

{Colors.WHITE}  ═══ RECOVERY MODE ═══{Colors.NC}
{Colors.GREEN}  [1]{Colors.NC} 📷  Recover Photo Only       - Foto saja (JPG, PNG, RAW)
{Colors.GREEN}  [2]{Colors.NC} 📹  Recover Video Only       - Video saja (MP4, AVI, MOV)
{Colors.GREEN}  [3]{Colors.NC} 📄  Recover Document Only    - Dokumen saja (DOC, PDF, XLS)
{Colors.GREEN}  [4]{Colors.NC} 📱  WhatsApp Photo Mode      - Khusus foto WhatsApp
{Colors.GREEN}  [5]{Colors.NC} 📁  Recover All Files        - Semua jenis file

{Colors.WHITE}  ═══ QUICK TARGET MODE ═══{Colors.NC}
{Colors.YELLOW}  [6]{Colors.NC} 📱  WhatsApp Images          - Target folder WhatsApp
{Colors.YELLOW}  [7]{Colors.NC} 📷  Camera (DCIM)            - Target folder Kamera
{Colors.YELLOW}  [8]{Colors.NC} 🖼️  Screenshots              - Target folder Screenshot

{Colors.WHITE}  ═══ TOOLS ═══{Colors.NC}
{Colors.BLUE}  [9]{Colors.NC} 📊  View Results             - Lihat hasil recovery
{Colors.BLUE}  [10]{Colors.NC} 🤖  Telegram Bot Settings    - Setup Telegram
{Colors.MAGENTA}  [11]{Colors.NC} 🛠️  Install Dependencies    - Install tool
{Colors.RED}  [0]{Colors.NC} 🚪  Exit                     - Keluar

{Colors.CYAN}╚═════════════════════════════════════════════════════════════════════╝{Colors.NC}
""")

# ============ RECOVERY ============
def run_recovery(target: str, output_dir: Path, file_types: List[str], 
                 scan_mode: str = "quick", telegram_bot: TelegramBot = None) -> AnalysisResult:
    result = AnalysisResult()
    sorter = SmartSorting(output_dir)
    
    if telegram_bot and telegram_bot.token:
        telegram_bot.send_recovery_start(target, f"{scan_mode.upper()} SCAN")
    
    print(f"\n{Colors.CYAN}{'═'*70}{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Target: {target}{Colors.NC}")
    print(f"{Colors.YELLOW}[*] Output: {output_dir}{Colors.NC}")
    print(f"{Colors.CYAN}{'═'*70}{Colors.NC}\n")
    
    file_opts = ','.join([f"{ft},enable" for ft in file_types])
    cmd_options = f"partition_none,options,{'paranoid,' if scan_mode == 'deep' else ''}fileopt,{file_opts},search"
    
    temp_output = output_dir / "temp_recovery"
    temp_output.mkdir(exist_ok=True)
    
    cmd = f'photorec /d "{str(temp_output)}" /cmd {target} {cmd_options}'
    if not is_termux():
        cmd = f'sudo {cmd}'
    
    print(f"{Colors.YELLOW}[*] Menjalankan PhotoRec...{Colors.NC}\n")
    ProgressBar.spinner("Mempersiapkan recovery...", 2)
    
    try:
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        dots = 0
        while process.poll() is None:
            sys.stdout.write(f"\r{Colors.CYAN}⏳ Recovery in progress{'.' * (dots % 4)}{'   '[:3-dots%4]}{Colors.NC}")
            sys.stdout.flush()
            time.sleep(0.5)
            dots += 1
        print(f"\r{' ' * 50}\r", end='')
    except Exception as e:
        result.failed += 1
        return result
    
    print(f"\n{Colors.YELLOW}[*] Memproses file hasil recovery...{Colors.NC}")
    
    all_files = list(temp_output.rglob('*')) if temp_output.exists() else []
    result.total_files = len([f for f in all_files if f.is_file()])
    
    processed = 0
    for file_path in all_files:
        if file_path.is_file():
            processed += 1
            ProgressBar.show(processed, result.total_files, "  Sorting")
            
            try:
                file_size = file_path.stat().st_size
                result.total_size += file_size
                dest_path, category = sorter.sort_file(file_path, auto_rename=True)
                shutil.move(str(file_path), str(dest_path))
                result.successful += 1
                
                if category == 'photos': result.photos += 1
                elif category == 'videos': result.videos += 1
                elif category == 'documents': result.documents += 1
                elif category == 'whatsapp_photos': result.whatsapp_photos += 1
                else: result.others += 1
            except:
                result.failed += 1
    
    print()
    
    try:
        shutil.rmtree(temp_output)
    except: pass
    
    return result

def quick_target_recovery(mode: str, telegram_bot: TelegramBot) -> Optional[AnalysisResult]:
    print_banner()
    print_warning()
    
    target_paths = {
        'whatsapp': FileTypes.WHATSAPP_IMAGES,
        'camera': FileTypes.CAMERA_DCIM,
        'screenshot': FileTypes.SCREENSHOTS
    }
    mode_names = {'whatsapp': 'WhatsApp Images', 'camera': 'Camera (DCIM)', 'screenshot': 'Screenshots'}
    
    target = None
    for path in target_paths.get(mode, []):
        if Path(path).exists():
            target = path
            break
    
    if not target:
        print(f"{Colors.RED}[!] Folder {mode_names[mode]} tidak ditemukan!{Colors.NC}")
        input("\nTekan Enter untuk kembali...")
        return None
    
    print(f"\n{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.WHITE}  Quick Target: {mode_names[mode]}{Colors.NC}")
    print(f"{Colors.WHITE}  Path: {Colors.CYAN}{target}{Colors.NC}")
    print(f"{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}\n")
    
    # Storage safety check
    is_safe, status = StorageSafety.check_storage(target)
    if not is_safe:
        info = StorageSafety.get_storage_info(target)
        StorageSafety.show_warning(status, info)
        if status == "CRITICAL":
            print(f"{Colors.RED}[!] Recovery dibatalkan karena storage tidak aman!{Colors.NC}")
            input("\nTekan Enter untuk kembali...")
            return None
        confirm = input(f"{Colors.YELLOW}Lanjutkan meskipun storage hampir penuh? (y/n): {Colors.NC}").strip().lower()
        if confirm != 'y':
            return None
    
    session_manager = SessionManager(RECOVERED_DIR)
    output_dir = session_manager.create_session_folder()
    
    print(f"\n{Colors.CYAN}Pilih mode scan:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Quick Scan (Cepat)")
    print(f"  {Colors.GREEN}2{Colors.NC} - Deep Scan (Lengkap)")
    scan_choice = input(f"\n{Colors.YELLOW}Pilihan [1/2]: {Colors.NC}").strip()
    scan_mode = "deep" if scan_choice == "2" else "quick"
    
    file_types = ['jpg', 'png', 'gif', 'mp4'] if mode == 'whatsapp' else \
                 ['jpg', 'png', 'raw', 'cr2', 'mp4'] if mode == 'camera' else ['jpg', 'png', 'gif']
    
    print(f"\n{Colors.RED}[!] PERINGATAN: Jangan gunakan device selama recovery!{Colors.NC}")
    confirm = input(f"{Colors.YELLOW}Lanjutkan? (y/n): {Colors.NC}").strip().lower()
    if confirm != 'y':
        return None
    
    result = run_recovery(target, output_dir, file_types, scan_mode, telegram_bot)
    
    show_result_summary(result, str(output_dir), output_dir.name)
    
    if telegram_bot and telegram_bot.token:
        telegram_bot.send_recovery_complete(result.photos, result.videos, result.documents,
                                           result.whatsapp_photos, result.others, 
                                           result.total_size_mb, str(output_dir))
        print(f"{Colors.GREEN}[✓] Notifikasi Telegram terkirim!{Colors.NC}")
    
    with open(output_dir / "analysis.json", 'w') as f:
        json.dump(result.to_dict(), f, indent=2)
    
    input("\nTekan Enter untuk kembali...")
    return result

def recover_menu(mode: str, telegram_bot: TelegramBot):
    print_banner()
    print_warning()
    
    paths = get_storage_paths()
    print(f"\n{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.WHITE}  NO.  |  PATH                            |  TYPE     {Colors.NC}")
    print(f"{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}")
    for num, path in paths.items():
        ptype = "Internal" if "emulated" in path or "sdcard" in path else "External"
        print(f"  {Colors.GREEN}{num:<3}{Colors.NC}  |  {path:<32} |  {ptype}")
    print(f"{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}\n")
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih storage [nomor]: {Colors.NC}"))
        if choice not in paths:
            print(f"{Colors.RED}[!] Pilihan tidak valid!{Colors.NC}")
            input("\nTekan Enter untuk kembali...")
            return
        target = paths[choice]
    except:
        return
    
    # Storage safety check
    is_safe, status = StorageSafety.check_storage(target)
    if not is_safe:
        info = StorageSafety.get_storage_info(target)
        StorageSafety.show_warning(status, info)
        if status == "CRITICAL":
            return
        confirm = input(f"{Colors.YELLOW}Lanjutkan? (y/n): {Colors.NC}").strip().lower()
        if confirm != 'y':
            return
    
    print(f"\n{Colors.CYAN}Pilih mode scan:{Colors.NC}")
    print(f"  {Colors.GREEN}1{Colors.NC} - Quick Scan (Cepat, disarankan)")
    print(f"  {Colors.GREEN}2{Colors.NC} - Deep Scan (Lengkap, lebih lama)")
    scan_choice = input(f"\n{Colors.YELLOW}Pilihan [1/2]: {Colors.NC}").strip()
    scan_mode = "deep" if scan_choice == "2" else "quick"
    
    file_types_map = {
        'photo': ['jpg', 'png', 'gif', 'bmp', 'raw', 'cr2', 'nef'],
        'video': ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv'],
        'document': ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf', 'txt'],
        'whatsapp': ['jpg', 'png', 'mp4'],
        'all': ['everything']
    }
    file_types = file_types_map.get(mode, ['everything'])
    
    session_manager = SessionManager(RECOVERED_DIR)
    output_dir = session_manager.create_session_folder()
    
    print(f"\n{Colors.RED}[!] PERINGATAN TERAKHIR!{Colors.NC}")
    confirm = input(f"{Colors.YELLOW}Lanjutkan? (y/n): {Colors.NC}").strip().lower()
    if confirm != 'y':
        return
    
    result = run_recovery(target, output_dir, file_types, scan_mode, telegram_bot)
    
    show_result_summary(result, str(output_dir), output_dir.name)
    
    if telegram_bot and telegram_bot.token:
        telegram_bot.send_recovery_complete(result.photos, result.videos, result.documents,
                                           result.whatsapp_photos, result.others, 
                                           result.total_size_mb, str(output_dir))
        print(f"{Colors.GREEN}[✓] Notifikasi Telegram terkirim!{Colors.NC}")
    
    with open(output_dir / "analysis.json", 'w') as f:
        json.dump(result.to_dict(), f, indent=2)
    
    compress = input(f"\n{Colors.YELLOW}Kompres hasil ke ZIP? (y/n): {Colors.NC}").strip().lower()
    if compress == 'y':
        zip_path = output_dir.parent / f"{output_dir.name}.zip"
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for f in output_dir.rglob('*'):
                if f.is_file():
                    zf.write(f, f.relative_to(output_dir))
        print(f"{Colors.GREEN}[✓] ZIP: {zip_path}{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

def view_results():
    print_banner()
    
    session_manager = SessionManager(RECOVERED_DIR)
    sessions = session_manager.list_sessions()
    
    if not sessions:
        print(f"{Colors.RED}[!] Tidak ada hasil recovery!{Colors.NC}")
        input("\nTekan Enter untuk kembali...")
        return
    
    print(f"\n{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.WHITE}  NO.  |  SESSION                           |  SIZE      {Colors.NC}")
    print(f"{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}")
    
    for i, session in enumerate(sessions[:10], 1):
        total_size = sum(f.stat().st_size for f in session.rglob('*') if f.is_file())
        print(f"  {Colors.GREEN}{i:<3}{Colors.NC}  |  {session.name:<34} |  {format_size(total_size)}")
    
    print(f"{Colors.CYAN}═══════════════════════════════════════════════════════{Colors.NC}\n")
    
    try:
        choice = int(input(f"{Colors.YELLOW}Pilih session [nomor/0=kembali]: {Colors.NC}"))
        if choice == 0 or choice > len(sessions):
            return
        
        selected = sessions[choice - 1]
        analysis_file = selected / "analysis.json"
        
        if analysis_file.exists():
            with open(analysis_file) as f:
                data = json.load(f)
            
            result = AnalysisResult()
            result.photos = data.get('photos', 0)
            result.videos = data.get('videos', 0)
            result.documents = data.get('documents', 0)
            result.whatsapp_photos = data.get('whatsapp_photos', 0)
            result.others = data.get('others', 0)
            result.total_files = data.get('total_files', 0)
            result.total_size = data.get('total_size', 0)
            
            show_result_summary(result, str(selected), selected.name)
    except: pass
    
    input("\nTekan Enter untuk kembali...")

def telegram_settings(telegram_bot: TelegramBot):
    print_banner()
    print(f"{Colors.YELLOW}═════════════════ TELEGRAM BOT SETTINGS ═════════════════{Colors.NC}\n")
    
    print(f"{Colors.CYAN}Cara mendapatkan Bot Token:{Colors.NC}")
    print("  1. Buka Telegram, cari @BotFather")
    print("  2. Ketik /newbot dan ikuti instruksi")
    print("  3. Copy token yang diberikan")
    print(f"\n{Colors.CYAN}Cara mendapatkan Chat ID:{Colors.NC}")
    print("  1. Buka Telegram, cari @userinfobot")
    print("  2. Ketik /start")
    print("  3. Copy ID yang ditampilkan\n")
    
    print(f"{Colors.WHITE}Current Settings:{Colors.NC}")
    print(f"  Bot Token: {Colors.YELLOW}{telegram_bot.token[:20] if telegram_bot.token else 'Belum diset'}...{Colors.NC}")
    print(f"  Chat ID:   {Colors.YELLOW}{telegram_bot.chat_id or 'Belum diset'}{Colors.NC}\n")
    
    new_token = input(f"{Colors.YELLOW}Bot Token baru (Enter skip): {Colors.NC}").strip()
    new_chat = input(f"{Colors.YELLOW}Chat ID baru (Enter skip): {Colors.NC}").strip()
    
    if new_token or new_chat:
        token = new_token or telegram_bot.token
        chat = new_chat or telegram_bot.chat_id
        telegram_bot.set_credentials(token, chat)
        
        with open(CONFIG_FILE, 'w') as f:
            json.dump({'telegram_token': token, 'telegram_chat_id': chat}, f)
        
        print(f"\n{Colors.GREEN}[✓] Pengaturan Telegram berhasil disimpan!{Colors.NC}")
        
        test = input(f"{Colors.YELLOW}Kirim test message? (y/n): {Colors.NC}").strip().lower()
        if test == 'y':
            if telegram_bot.send_message("✅ Recovery Tool Pro - Test Berhasil!\n\nAuthor: MasJawa | IG: @fendipendol65"):
                print(f"{Colors.GREEN}[✓] Test message berhasil!{Colors.NC}")
            else:
                print(f"{Colors.RED}[✗] Gagal kirim test message!{Colors.NC}")
    
    input("\nTekan Enter untuk kembali...")

# ============ MAIN ============
def main():
    LOG_DIR.mkdir(exist_ok=True)
    RECOVERED_DIR.mkdir(exist_ok=True)
    BACKUP_DIR.mkdir(exist_ok=True)
    
    telegram_bot = TelegramBot()
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE) as f:
                config = json.load(f)
            telegram_bot.set_credentials(config.get('telegram_token', ''), config.get('telegram_chat_id', ''))
        except: pass
    
    missing = check_dependencies()
    if missing:
        print(f"{Colors.YELLOW}[!] Dependencies tidak lengkap: {', '.join(missing)}{Colors.NC}")
        print(f"{Colors.YELLOW}[*] Pilih menu [11] untuk install dependencies{Colors.NC}")
    
    while True:
        print_banner()
        print_menu()
        
        try:
            choice = input(f"{Colors.WHITE}  Pilih menu [0-11]: {Colors.NC}").strip()
        except EOFError:
            continue
        
        if choice == '1': recover_menu('photo', telegram_bot)
        elif choice == '2': recover_menu('video', telegram_bot)
        elif choice == '3': recover_menu('document', telegram_bot)
        elif choice == '4': recover_menu('whatsapp', telegram_bot)
        elif choice == '5': recover_menu('all', telegram_bot)
        elif choice == '6': quick_target_recovery('whatsapp', telegram_bot)
        elif choice == '7': quick_target_recovery('camera', telegram_bot)
        elif choice == '8': quick_target_recovery('screenshot', telegram_bot)
        elif choice == '9': view_results()
        elif choice == '10': telegram_settings(telegram_bot)
        elif choice == '11': install_dependencies()
        elif choice == '0':
            print(f"\n{Colors.GREEN}[*] Terima kasih!{Colors.NC}")
            print(f"{Colors.GREEN}[*] Author: MasJawa | IG: @fendipendol65{Colors.NC}\n")
            break

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}[!] Program dihentikan{Colors.NC}")
        sys.exit(0)
