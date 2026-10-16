# TuQuet Centralized Dotfiles for Windows

Hệ thống quản lý cấu hình và tự động hóa thiết lập máy trạm Windows tập trung (**Single Source of Truth - SSOT**), đồng bộ tự động qua OneDrive và liên kết bằng **NTFS Junctions**.

---

## 1. Cấu Trúc Thư Mục Tường Minh (Directory Structure)

```text
OneDrive\dotfiles/
├── .gitignore                         # Loại trừ rác hệ thống, file tạm tải về
├── README.md                          # Tài liệu kiến trúc và hướng dẫn sử dụng
├── setup-new-pc.cmd                   # 1-Click Bootstrap cho máy mới (Menu 1-2-3-0)
│
├── bin/                               # Thư mục công cụ CLI (Tự động nạp vào PATH)
│   ├── doctor.cmd                     # Kiểm tra toàn vẹn hệ thống (SSH, Junctions, CLIs)
│   ├── doctor.ps1
│   ├── update-all.cmd                 # Cập nhật toàn bộ Scoop, NPM packages & dọn dẹp cache
│   └── update-all.ps1
│
├── packages/                          # Khai báo danh mục phần mềm (Declarative Packages)
│   ├── scoop-apps.txt                 # Danh sách 18 ứng dụng quản lý qua Scoop
│   └── npm-clis.txt                   # Danh sách Cloud CLIs cài đặt qua NPM
│
├── git/                               # Cấu hình Git toàn cục
│   ├── .gitconfig                     # Git config SSOT, thông tin user và aliases
│   └── ignore                         # Global gitignore (loại trừ rác OS, Editor)
│
├── powershell/                        # Môi trường dòng lệnh PowerShell
│   └── Microsoft.PowerShell_profile.ps1 # Profile chung (fnm, oh-my-posh, git-hide)
│
├── ssh/                               # Hệ thống SSH tập trung (4 Máy chủ)
│   ├── config                         # File cấu hình SSH SSOT (my-pc, my-thinkpad, vps-desk, vps-tattoo)
│   ├── servers.csv                    # Danh sách máy chủ định dạng CSV để import Termius
│   └── servers/                       # Chứa key và artifact riêng biệt từng server
│       ├── my-pc/
│       ├── my-thinkpad/
│       ├── vps-desk/
│       └── vps-tattoo/
│
├── terminal/                          # Cấu hình Windows Terminal
│   └── LocalState/                    # Settings giao diện, font JetBrainsMono & 4 profile SSH
│       ├── settings.json
│       ├── state.json
│       └── elevated-state.json
│
└── vscode/                            # Cấu hình Visual Studio Code
    └── project-manager/               # Cấu hình danh mục dự án cho extension Project Manager
        └── projects.json
```

---

## 2. Bản Đồ Ánh Xạ Hệ Thống (System Linkage Map)

Toàn bộ liên kết sử dụng **NTFS Junction** hoặc cơ chế native của ứng dụng, không nhân bản dữ liệu:

| Thành phần | Đường dẫn gốc trong Dotfiles | Vị trí thực tế trên Windows | Cơ chế liên kết |
| :--- | :--- | :--- | :--- |
| **SSH Keys** | `dotfiles\ssh\servers\` | `%USERPROFILE%\.ssh\servers` | NTFS Junction (`mklink /J`) |
| **SSH Config** | `dotfiles\ssh\config` | `%USERPROFILE%\.ssh\config` | Đồng bộ 1 chiều SSOT |
| **Terminal** | `dotfiles\terminal\LocalState\` | `%LOCALAPPDATA%\Packages\...\LocalState` | NTFS Junction (`mklink /J`) |
| **Git Config** | `dotfiles\git\.gitconfig` | `%USERPROFILE%\.gitconfig` | `include.path` |
| **Git Ignore** | `dotfiles\git\ignore` | N/A | `core.excludesfile` |
| **PowerShell** | `dotfiles\powershell\profile.ps1` | `Documents\PowerShell\` & `WindowsPowerShell\` | Dot-source Loader |
| **VS Code PM** | `dotfiles\vscode\project-manager\` | Scoop Persist & `%APPDATA%\Code\` | NTFS Junction (`mklink /J`) |
| **CLI PATH** | `dotfiles\bin\` | Biến môi trường User `Path` | User Environment Variable |

---

## 3. Hướng Dẫn Cài Đặt & Sử Dụng (Quick Start)

### 3.1. Cài đặt hiện đại qua dòng lệnh (1-Line Command)

Bạn có thể chạy trực tiếp từ PowerShell mà không cần mở giao diện Explorer:

```powershell
# Cách 1: Chạy từ xa trực tiếp trên máy mới qua 1 dòng lệnh (One-Liner Public Bootstrap):
irm https://raw.githubusercontent.com/tuquet/win-dotfiles/main/install.ps1 | iex

# Cách 2: Thiết lập liên kết Dotfiles siêu tốc từ local (2 giây - Khuyên dùng):
pwsh -File d:\Repository\tuquet\dotfiles\install.ps1 -Mode LinkOnly

# Cách 3: Cài đặt trọn gói không cần hỏi (Unattended / Silent Full Bootstrap):
pwsh -File d:\Repository\tuquet\dotfiles\install.ps1 -Mode Full -NonInteractive

# Cách 4: Chạy giao diện tương tác:
pwsh -File d:\Repository\tuquet\dotfiles\install.ps1
```

> [!TIP]
> **Trợ lý dòng lệnh `dotfiles`:** Sau khi cài đặt, bạn có thể gõ trực tiếp từ bất kỳ cửa sổ Terminal nào:
> - `dotfiles doctor`: Chẩn đoán sức khỏe hệ thống.
> - `dotfiles link`: Móc nối lại toàn bộ NTFS Junctions trong 2 giây.
> - `dotfiles update`: Cập nhật Scoop, gói NPM và dọn rác cache.
> - `dotfiles status`: Kiểm tra trạng thái Git repository.

### 3.2. Thiết lập máy mới bằng Batch script cổ điển (`setup-new-pc.cmd`)
Vẫn hỗ trợ mở file `setup-new-pc.cmd` bằng cách click đúp hoặc chạy trong CMD (Menu lựa chọn 1, 2, 3, 0).

---

### 3.2. Kiểm tra sức khỏe hệ thống (`doctor`)
Mở Command Prompt hoặc PowerShell bất kỳ và gõ:
```powershell
doctor
```
Hệ thống sẽ kiểm tra nhanh:
1. Độ phân giải DNS/IP và chứng chỉ của 4 host SSH (`my-pc`, `my-thinkpad`, `vps-desk`, `vps-tattoo`).
2. Trạng thái các NTFS Junctions.
3. Phiên bản và vị trí thực thi của các Cloud CLIs (`cloudflared`, `supabase`, `vercel`, `wrangler`, `netlify`).
4. Các công cụ Dev Core (`git`, `pwsh`, `fnm`, `python`, `uv`).

---

### 3.3. Tùy chỉnh danh mục ứng dụng (`packages/`)
- Muốn thêm/bớt ứng dụng Scoop: Chỉnh sửa file [`packages/scoop-apps.txt`](file:///C:/Users/Admin/OneDrive/dotfiles/packages/scoop-apps.txt).
- Muốn thêm/bớt Cloud CLI qua NPM: Chỉnh sửa file [`packages/npm-clis.txt`](file:///C:/Users/Admin/OneDrive/dotfiles/packages/npm-clis.txt).
- File hỗ trợ ghi chú bằng dấu `#` ở đầu dòng.
