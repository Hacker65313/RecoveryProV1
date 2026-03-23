# ╔══════════════════════════════════════════════════════════════════════════╗
# ║                     RECOVERY TOOL PRO v3.1                              ║
# ║              Data Recovery Suite for Termux & Kali Linux                ║
# ║                                                                         ║
# ║                     Author: MasJawa                                     ║
# ║                     IG: @fendipendol65                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

## 📋 DEPENDENCIES

### Required Tools:
- **PhotoRec** - File recovery engine
- **TestDisk** - Partition recovery
- **Python 3** - Runtime environment

### Install Dependencies:

#### Termux:
```bash
pkg update && pkg upgrade
pkg install python photorec testdisk
```

#### Kali Linux:
```bash
sudo apt update
sudo apt install python3 photorec testdisk
```

---

## 🚀 INSTALLATION

```bash
cd recovery-tools
chmod +x install.sh
./install.sh
```

---

## ⚡ FITUR UTAMA

### 🔧 Core Recovery Modules:
| Module | Fungsi |
|--------|--------|
| **PhotoRecover** | Kembalikan foto yang terhapus |
| **FileRescue** | Recovery semua jenis file |
| **DeepScan** | Scan mendalam storage |
| **DataBackup** | Backup & restore data |

### 🆕 Fitur v3.0:
- ✅ **Smart Sorting Pro** - Pisah otomatis foto, video, dokumen
- ✅ **Analysis Result** - Jumlah file, estimasi failed, total size
- ✅ **Auto Rename** - Rename file dengan timestamp
- ✅ **Compress ZIP** - Kompres hasil recovery
- ✅ **Warning System** - Peringatan jangan gunakan HP
- ✅ **Recovery Options** - Foto/Video/Document/All Files
- ✅ **Quick Scan & Deep Scan** - Mode scan cepat/lengkap
- ✅ **Telegram Bot** - Kirim hasil ke Telegram
- ✅ **Progress Bar & Animation** - UI modern
- ✅ **WhatsApp Photo Mode** - Khusus foto WhatsApp

### 🆕 Fitur v3.1:
- ✅ **Session System** - Folder otomatis `Recovery_YYYY-MM-DD_XXX`
- ✅ **Auto Telegram Sender** - Kirim notifikasi otomatis
- ✅ **Quick Target Mode** - Target cepat WhatsApp/Camera/Screenshot
- ✅ **Storage Safety Check** - Cek storage sebelum scan
- ✅ **Result Summary** - Ringkasan hasil recovery

---

## 📱 MENU UTAMA

```
╔════════════════════════════════════════════════════════╗
║              RECOVERY TOOL PRO v3.1                    ║
╠════════════════════════════════════════════════════════╣
║  1. 📁 Scan Storage                                    ║
║  2. 📷 Recover Photo                                   ║
║  3. 🎬 Recover Video                                   ║
║  4. 📄 Recover Document                                ║
║  5. 💾 Recover All Files                               ║
║  6. 💬 Quick Target: WhatsApp Images                   ║
║  7. 📷 Quick Target: Camera (DCIM)                     ║
║  8. 🖼️ Quick Target: Screenshot                        ║
║  9. 📦 Compress Results (ZIP)                          ║
║  10. 🤖 Setup Telegram Bot                             ║
║  11. 📊 View Result Summary                            ║
║  12. ❌ Exit                                           ║
╚════════════════════════════════════════════════════════╝
```

---

## 🎯 CARA PENGGUNAAN

### 1. Scan Storage:
Pilih menu `1` untuk scan storage dan melihat partisi yang tersedia.

### 2. Recovery:
- Pilih menu `2-5` untuk recovery berdasarkan tipe file
- Pilih menu `6-8` untuk Quick Target Mode
- Pilih mode: Quick Scan atau Deep Scan

### 3. Session System:
Hasil recovery otomatis disimpan di folder:
```
Recovery_2026-03-23_001/
Recovery_2026-03-23_002/
├── photos/
├── videos/
├── documents/
├── whatsapp/
└── others/
```

### 4. Telegram Bot:
```bash
# Setup di menu 10
Masukkan Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
Masukkan Chat ID: 123456789
```

### 5. Result Summary:
Setelah recovery selesai, akan muncul:
```
╔══════════════════════════════════════════╗
║          📊 RESULT SUMMARY               ║
╠══════════════════════════════════════════╣
║  📷 Foto ditemukan  : 120               ║
║  🎬 Video           : 10                ║
║  📄 Dokumen         : 5                 ║
║  💬 WhatsApp        : 50                ║
║  📁 Lainnya         : 15                ║
║  📦 Total Size      : 500 MB            ║
║  📂 Lokasi          : /Recovery_xxx/    ║
╚══════════════════════════════════════════╝
```

---

## ⚠️ PENTING!

```
[!] JANGAN gunakan HP selama proses recovery!
[!] HINDARI overwrite data!
[!] Pastikan storage cukup sebelum recovery!
[!] Gunakan Deep Scan untuk hasil maksimal!
```

---

## 📞 KONTAK

- **Author:** MasJawa
- **Instagram:** @fendipendol65

---

## 📜 LICENSE

Free to use for educational purposes.

**© 2024 MasJawa - Recovery Tool Pro v3.1**