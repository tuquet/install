<#
.SYNOPSIS
    TuQuet Installer - Modern Windows Bootstrap & Synchronization Engine
.DESCRIPTION
    One-line modern installer supporting unattended CLI flags, environment setup,
    Scoop declarative packages, and system utilities.
.PARAMETER Mode
    Installation mode: Full (Apps + CLIs + Config), LinkOnly (Git & PATH setup only), UpdateAll (Update scoop/clis/caches)
.PARAMETER NonInteractive
    Skip interactive prompts and execute silently
.EXAMPLE
    pwsh -File .\install.ps1 -Mode Full -NonInteractive
    pwsh -File .\install.ps1 -Mode LinkOnly
#>

[CmdletBinding()]
param(
    [ValidateSet('Full', 'LinkOnly', 'UpdateAll', 'Interactive')]
    [string]$Mode = 'Interactive',

    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$InstallDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    if ($MyInvocation -and $MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        # Running directly via irm ... | iex in memory
        $InstallDir = "D:\Repository\tuquet\install"
        if (-not (Test-Path $InstallDir)) {
            $InstallDir = "$HOME\install"
        }
        if (-not (Test-Path $InstallDir)) {
            Write-Host "[*] Detected remote execution. Cloning installer repository..." -ForegroundColor Cyan
            & git clone https://github.com/tuquet/install.git $InstallDir
        }
    }
}

function Write-Banner {
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "                TUQUET - MODERN WINDOWS INSTALLER & BOOTSTRAP                 " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host " Root: $InstallDir`n" -ForegroundColor DarkGray
}

function Invoke-ScoopBootstrap {
    Write-Host "`n[1/4] Khởi tạo Scoop và Package Buckets..." -ForegroundColor Yellow
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  [*] Dang cai dat Scoop..." -ForegroundColor Cyan
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    } else {
        Write-Host "  [OK] Scoop da san sang." -ForegroundColor Green
    }

    # Add essential buckets
    $bucketConfigs = @(
        @{ Name = 'extras'; Url = '' },
        @{ Name = 'nerd-fonts'; Url = '' },
        @{ Name = 'tuquet'; Url = 'https://github.com/tuquet/scoop-bucket' }
    )
    foreach ($b in $bucketConfigs) {
        try {
            if ($b.Url) {
                & scoop bucket add $b.Name $b.Url 2>$null | Out-Null
            } else {
                & scoop bucket add $b.Name 2>$null | Out-Null
            }
            Write-Host "  [OK] Bucket '$($b.Name)' active." -ForegroundColor Green
        } catch {
            # Already exists
        }
    }

    Write-Host "`n[2/4] Cai dat danh muc ung dung qua Scoop..." -ForegroundColor Yellow
    $appsFile = Join-Path $InstallDir "packages\scoop-apps.txt"
    if (Test-Path $appsFile) {
        $apps = Get-Content $appsFile | Where-Object { $_ -and -not $_.StartsWith("#") }
        foreach ($app in $apps) {
            $app = $app.Trim()
            Write-Host "  [*] Checking / Installing: $app" -ForegroundColor Cyan
            & scoop install $app
        }
    }
}

function Invoke-NpmBootstrap {
    Write-Host "`n[3/4] Cai dat Cloud CLIs qua NPM..." -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmFile = Join-Path $InstallDir "packages\npm-clis.txt"
        $clis = if (Test-Path $npmFile) {
            Get-Content $npmFile | Where-Object { $_ -and -not $_.StartsWith("#") }
        } else {
            @('vercel', 'wrangler', 'netlify-cli')
        }
        foreach ($pkg in $clis) {
            $pkg = $pkg.Trim()
            Write-Host "  [*] Installing NPM Global: $pkg" -ForegroundColor Cyan
            & npm install -g $pkg
        }
    } else {
        Write-Host "  [!] Node/NPM chua co trong PATH. Bo qua buoc nay." -ForegroundColor Yellow
    }
}

function Invoke-SystemConfig {
    Write-Host "`n[+] Thiet lap cau hinh moi truong (Git Config & User PATH)..." -ForegroundColor Yellow

    # 1. Git Global Config
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitConfigTarget = (Join-Path $InstallDir "git\.gitconfig").Replace("\", "/")
        & git config --global include.path $gitConfigTarget
        Write-Host "  [OK] Git global config included -> $gitConfigTarget" -ForegroundColor Green
    }

    # 2. User PATH (bin/)
    $binDir = Join-Path $InstallDir "bin"
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not ($userPath -split ';').Contains($binDir)) {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir".TrimEnd(';'), 'User')
        Write-Host "  [OK] Added $binDir to User PATH." -ForegroundColor Green
    }

    Write-Host "`n✨ System Configuration Completed Successfully!" -ForegroundColor Green
}

function Invoke-UpdateSystem {
    Write-Host "`n[*] Updating Scoop, Packages & Caches..." -ForegroundColor Cyan
    $updateScript = Join-Path $InstallDir "bin\update-all.ps1"
    if (Test-Path $updateScript) {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $updateScript
    }
}

# --- Execution Entrypoint ---
Write-Banner

if ($Mode -eq 'Interactive' -and -not $NonInteractive) {
    Write-Host "Chon che do cai dat:" -ForegroundColor White
    Write-Host "  [1] Cai dat tron goi (Full Bootstrap: Apps + CLIs + Config)"
    Write-Host "  [2] Chi thiet lap moi truong (Git Config & PATH - 2 giay)"
    Write-Host "  [3] Cap nhat toan bo he thong (Update All)"
    Write-Host "  [0] Thoat`n"

    $choice = Read-Host "Lua chon [1, 2, 3, 0]"
    switch ($choice) {
        '1' { $Mode = 'Full' }
        '2' { $Mode = 'LinkOnly' }
        '3' { $Mode = 'UpdateAll' }
        default { Write-Host "Thoat."; exit 0 }
    }
}

switch ($Mode) {
    'Full' {
        Invoke-ScoopBootstrap
        Invoke-NpmBootstrap
        Invoke-SystemConfig
    }
    'LinkOnly' {
        Invoke-SystemConfig
    }
    'UpdateAll' {
        Invoke-UpdateSystem
    }
}

# Run Doctor check if exists
$doctorScript = Join-Path $InstallDir "bin\doctor.ps1"
if (Test-Path $doctorScript) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $doctorScript
}
