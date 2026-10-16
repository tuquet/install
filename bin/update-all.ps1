# ==============================================================================
# Script: update-all.ps1
# Dong bo va cap nhat toan bo he thong (Scoop, Global NPM packages, Caches)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "System Update & Cleanup"

function Write-Step {
    param([string]$Title)
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Cyan
}

$startTime = Get-Date

Write-Host "========================================================" -ForegroundColor Green
Write-Host "       1-CLICK SYSTEM UPDATE & CLEANUP TOOL            " -ForegroundColor Green
Write-Host "       Host: $env:COMPUTERNAME | User: $env:USERNAME   " -ForegroundColor DarkGray
Write-Host "========================================================" -ForegroundColor Green

# 1. Update Scoop & Packages
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Step "1/3: Cap nhat Scoop manifest"
    try {
        & scoop update
    } catch {
        Write-Host "Canh bao khi cap nhat Scoop: $_" -ForegroundColor Yellow
    }

    Write-Step "2/3: Nang cap cac ung dung Scoop da cai"
    try {
        & scoop update *
    } catch {
        Write-Host "Canh bao khi nang cap ung dung: $_" -ForegroundColor Yellow
    }

    Write-Step "3/3: Don dep phien ban cu & cache bo nho"
    Write-Host "-> Don dep version cu..." -ForegroundColor DarkCyan
    try {
        & scoop cleanup *
    } catch {
        Write-Host "Luu y: Mot so file cua ung dung dang mo (nhu VS Code) chua the xoa ngay. Se don dep khi ung dung dong." -ForegroundColor Yellow
    }

    Write-Host "-> Don dep installer cache..." -ForegroundColor DarkCyan
    try {
        & scoop cache rm *
    } catch {
        Write-Host "Luu y: Khong the xoa toan bo cache installer." -ForegroundColor Yellow
    }
} else {
    Write-Host "Khong tim thay Scoop tren he thong nay!" -ForegroundColor Yellow
}

# 2. Update Global NPM Packages (Cloud CLIs: Vercel, Cloudflare Wrangler, Netlify)
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $installRoot = Split-Path -Parent $PSScriptRoot
    $npmListFile = Join-Path $installRoot "packages\npm-clis.txt"
    $cloudCLIs = if (Test-Path $npmListFile) {
        Get-Content $npmListFile | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() }
    } else {
        @("vercel", "wrangler", "netlify-cli")
    }
    foreach ($pkg in $cloudCLIs) {
        Write-Host "-> Dang cap nhat $pkg..." -ForegroundColor DarkCyan
        try {
            & npm update -g $pkg
        } catch {
            Write-Host "Canh bao khi cap nhat $pkg: $_" -ForegroundColor Yellow
        }
    }
}

# 3. Synchronize Installer Repository & Specter Master CLI
$installRoot = Split-Path -Parent $PSScriptRoot
if (Test-Path (Join-Path $installRoot ".git")) {
    Write-Step "Dong bo cap nhat bo cai dat TuQuet Installer (Git Pull)"
    try {
        & git -C $installRoot pull origin main
    } catch {
        Write-Host "Luu y khi dong bo git installer: $_" -ForegroundColor Yellow
    }
}

if (Get-Command spc -ErrorAction SilentlyContinue) {
    Write-Step "Kiem tra va cap nhat Specter Master CLI (spc upgrade)"
    try {
        & spc upgrade
    } catch {
        Write-Host "Luu y khi cap nhat specter cli: $_" -ForegroundColor Yellow
    }
}

$elapsed = (Get-Date) - $startTime
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "  HOAN TAT TOAN BO TIEN TRINH TRONG $([math]::Round($elapsed.TotalSeconds, 1))s!" -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Green
