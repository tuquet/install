# TuQuet Windows Workstation Setup & Installer

Hệ thống tự động hóa thiết lập máy trạm Windows, cài đặt phần mềm và cấu hình môi trường lập trình tập trung.

---

## 1. Cấu Trúc Thư Mục (Directory Structure)

```text
install/
├── .gitignore                         # Loại trừ rác hệ thống, file tạm
├── README.md                          # Tài liệu hướng dẫn sử dụng
├── install.ps1                        # 1-Liner Bootstrap cho máy mới (PowerShell Native)
│
├── bin/                               # Thư mục công cụ CLI (Tự động nạp vào PATH)
│   ├── doctor.cmd                     # Kiểm tra toàn vẹn hệ thống
│   ├── doctor.ps1
│   ├── update-all.cmd                 # Cập nhật toàn bộ Scoop, NPM packages & dọn dẹp cache
│   └── update-all.ps1
│
├── packages/                          # Khai báo danh mục phần mềm (Declarative Packages)
│   ├── scoop-apps.txt                 # Danh sách ứng dụng quản lý qua Scoop
│   └── npm-clis.txt                   # Danh sách Cloud CLIs cài đặt qua NPM
│
└── git/                               # Cấu hình Git toàn cục
    ├── .gitconfig                     # Git config mẫu, thông tin user và aliases
    └── ignore                         # Global gitignore (loại trừ rác OS, Editor)
```

---

## 2. Bản Đồ Ánh Xạ Hệ Thống (System Linkage Map)

| Thành phần | Đường dẫn gốc trong Install | Vị trí thực tế trên Windows | Cơ chế liên kết |
| :--- | :--- | :--- | :--- |
| **Git Config** | `install\git\.gitconfig` | `%USERPROFILE%\.gitconfig` | `include.path` |
| **Git Ignore** | `install\git\ignore` | N/A | `core.excludesfile` |
| **CLI PATH** | `install\bin\` | Biến môi trường User `Path` | User Environment Variable |

---

## 3. Hướng Dẫn Cài Đặt (Quick Start)

### 3.1. Cài đặt trực tiếp từ xa trên máy mới qua 1 dòng lệnh (One-Liner Bootstrap)

Mở PowerShell và dán dòng lệnh sau:

```powershell
irm https://raw.githubusercontent.com/tuquet/install/main/install.ps1 | iex
```

### 3.2. Cài đặt từ thư mục local:

```powershell
# Cách 1: Thiết lập liên kết môi trường siêu tốc (2 giây - Khuyên dùng):
pwsh -File d:\Repository\tuquet\install\install.ps1 -Mode LinkOnly

# Cách 2: Cài đặt trọn gói không cần hỏi (Unattended / Silent Full Bootstrap):
pwsh -File d:\Repository\tuquet\install\install.ps1 -Mode Full -NonInteractive

# Cách 3: Chạy giao diện tương tác:
pwsh -File d:\Repository\tuquet\install\install.ps1
```

> [!TIP]
> **Trợ lý dòng lệnh:** Sau khi cài đặt, bạn có thể gõ trực tiếp từ bất kỳ cửa sổ Terminal nào:
> - `doctor`: Chẩn đoán sức khỏe hệ thống và CLIs.
> - `update-all`: Cập nhật Scoop, gói NPM và dọn rác cache.

---

## 4. Tùy Chỉnh Danh Mục Ứng Dụng (`packages/`)
- Thêm/bớt ứng dụng Scoop: Chỉnh sửa file [`packages/scoop-apps.txt`](packages/scoop-apps.txt).
- Thêm/bớt Cloud CLI qua NPM: Chỉnh sửa file [`packages/npm-clis.txt`](packages/npm-clis.txt).
- Hỗ trợ ghi chú bằng dấu `#` ở đầu dòng.
