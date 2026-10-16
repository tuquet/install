# ==============================================================================
# TuQuet Dotfiles - System Health Check (Doctor)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                TUQUET DOTFILES - SYSTEM HEALTH CHECK                         " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# 1. SSH Profiles & Keys
Write-Host "`n[1. SSH Profiles & Configurations]" -ForegroundColor Yellow
$hosts = @("my-pc", "my-thinkpad", "vps-desk", "vps-tattoo")
foreach ($h in $hosts) {
    $cfg = ssh -G $h 2>$null | Select-String "^hostname "
    $user = ssh -G $h 2>$null | Select-String "^user "
    if ($cfg) {
        $ip = $cfg.ToString().Replace("hostname ", "").Trim()
        $u = if ($user) { $user.ToString().Replace("user ", "").Trim() } else { "root" }
        Write-Host "  [OK] $h ($u@$ip)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $h (Loi cau hinh hoac khong tim thay)" -ForegroundColor Red
    }
}

# 2. NTFS Junctions & Links
Write-Host "`n[2. NTFS Junctions & Dotfiles Links]" -ForegroundColor Yellow
$juncs = @(
    @("SSH Servers", "$HOME\.ssh\servers"),
    @("Windows Terminal", "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"),
    @("VS Code PM (Scoop)", "$HOME\scoop\persist\vscode\data\user-data\User\globalStorage\alefragnani.project-manager"),
    @("VS Code PM (Native)", "$env:APPDATA\Code\User\globalStorage\alefragnani.project-manager")
)
foreach ($j in $juncs) {
    $name = $j[0]
    $path = $j[1]
    if (Test-Path $path) {
        $item = Get-Item $path
        if ($item.LinkType) {
            Write-Host "  [OK] $name -> $($item.LinkType) thanh cong" -ForegroundColor Green
        } else {
            Write-Host "  [OK] $name -> Ton tai (Thu muc thuong)" -ForegroundColor Green
        }
    } else {
        if ($name -match "Native") {
            # Khong bat buoc neu dung Scoop
        } else {
            Write-Host "  [MISSING] $name chua duoc lien ket" -ForegroundColor Yellow
        }
    }
}

# 3. Cloud Ecosystem CLIs
Write-Host "`n[3. Cloud Ecosystem CLIs]" -ForegroundColor Yellow
$clis = @("cloudflared", "supabase", "vercel", "wrangler", "netlify")
foreach ($cli in $clis) {
    $cmd = Get-Command $cli -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  [OK] $cli ($($cmd.Source))" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $cli chua duoc cai dat" -ForegroundColor Yellow
    }
}

# 4. Dev Core Tools
Write-Host "`n[4. Dev Core Tools]" -ForegroundColor Yellow
$coreTools = @("git", "pwsh", "fnm", "python", "uv")
foreach ($t in $coreTools) {
    if (Get-Command $t -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $t da san sang" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $t chua co trong PATH" -ForegroundColor Yellow
    }
}

Write-Host "`n==============================================================================" -ForegroundColor Cyan
