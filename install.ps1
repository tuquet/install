<#
.SYNOPSIS
    TuQuet Dotfiles - Modern Windows Bootstrap & Synchronization Engine
.DESCRIPTION
    One-line modern installer supporting unattended CLI flags, NTFS Junction linkage,
    Scoop declarative packages, SSH SSOT, and Windows Terminal sync.
.PARAMETER Mode
    Installation mode: Full (Apps + CLIs + Links), LinkOnly (Dotfiles only), UpdateAll (Update scoop/clis/caches)
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

$DotfilesDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($DotfilesDir)) {
    if ($MyInvocation -and $MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        # Running directly via irm ... | iex in memory
        $DotfilesDir = "D:\Repository\tuquet\install"
        if (-not (Test-Path $DotfilesDir)) {
            $DotfilesDir = "$HOME\install"
        }
        if (-not (Test-Path $DotfilesDir)) {
            Write-Host "[*] Detected remote execution. Cloning installer repository..." -ForegroundColor Cyan
            & git clone https://github.com/tuquet/install.git $DotfilesDir
        }
    }
}

function Write-Banner {
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "             TUQUET DOTFILES - MODERN WINDOWS BOOTSTRAP                       " -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host " Root: $DotfilesDir`n" -ForegroundColor DarkGray
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
    $buckets = @('extras', 'nerd-fonts')
    foreach ($b in $buckets) {
        try {
            & scoop bucket add $b 2>$null | Out-Null
            Write-Host "  [OK] Bucket '$b' active." -ForegroundColor Green
        } catch {
            # Already exists
        }
    }

    Write-Host "`n[2/4] Cai dat danh muc ung dung qua Scoop..." -ForegroundColor Yellow
    $appsFile = Join-Path $DotfilesDir "packages\scoop-apps.txt"
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
        $npmFile = Join-Path $DotfilesDir "packages\npm-clis.txt"
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

function Invoke-DotfilesLinkage {
    Write-Host "`n[+] Thiet lap he thong lien ket Dotfiles (NTFS Junctions & SSOT)..." -ForegroundColor Yellow

    # 1. Windows Terminal LocalState
    $wtPkg = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $wtTarget = Join-Path $DotfilesDir "terminal\LocalState"
    if (Test-Path (Split-Path $wtPkg -Parent)) {
        if (Test-Path $wtPkg) {
            $item = Get-Item $wtPkg
            if ($item.LinkType) {
                [System.IO.Directory]::Delete($wtPkg)
            } else {
                Remove-Item -Path $wtPkg -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        New-Item -ItemType Junction -Path $wtPkg -Target $wtTarget -Force | Out-Null
        Write-Host "  [OK] Windows Terminal LocalState Junction active." -ForegroundColor Green
    }

    # 3. Git Global Config
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitConfigTarget = (Join-Path $DotfilesDir "git\.gitconfig").Replace("\", "/")
        & git config --global include.path $gitConfigTarget
        Write-Host "  [OK] Git global config included -> $gitConfigTarget" -ForegroundColor Green
    }

    # 4. User PATH (bin/)
    $binDir = Join-Path $DotfilesDir "bin"
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not ($userPath -split ';').Contains($binDir)) {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir".TrimEnd(';'), 'User')
        Write-Host "  [OK] Added $binDir to User PATH." -ForegroundColor Green
    }



    # 7. Obsidian Vault Registration
    $obsVault = Join-Path $HOME "OneDrive\Documents\Obsidian Vault"
    if (Test-Path $obsVault) {
        $obsDir = Join-Path $env:APPDATA "obsidian"
        if (-not (Test-Path $obsDir)) { New-Item -ItemType Directory -Path $obsDir -Force | Out-Null }
        $vaultConfig = @{
            'vaults' = @{
                'primary-vault' = @{
                    'path' = $obsVault
                    'ts' = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    'open' = $true
                }
            }
        }
        $vaultConfig | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $obsDir "obsidian.json") -Encoding UTF8
        Write-Host "  [OK] Obsidian Primary Vault registered." -ForegroundColor Green
    }

    Write-Host "`n✨ Dotfiles Linkage Completed Successfully!" -ForegroundColor Green
}

function Invoke-UpdateSystem {
    Write-Host "`n[*] Updating Scoop, Packages & Caches..." -ForegroundColor Cyan
    $updateScript = Join-Path $DotfilesDir "bin\update-all.ps1"
    if (Test-Path $updateScript) {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $updateScript
    }
}

# --- Execution Entrypoint ---
Write-Banner

if ($Mode -eq 'Interactive' -and -not $NonInteractive) {
    Write-Host "Chon che do cai dat:" -ForegroundColor White
    Write-Host "  [1] Cai dat tron goi (Full Bootstrap: Apps + CLIs + Links)"
    Write-Host "  [2] Chi thiet lap lien ket Dotfiles (Link Only - 2 giay)"
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
        Invoke-DotfilesLinkage
    }
    'LinkOnly' {
        Invoke-DotfilesLinkage
    }
    'UpdateAll' {
        Invoke-UpdateSystem
    }
}

# Run Doctor check if exists
$doctorScript = Join-Path $DotfilesDir "bin\doctor.ps1"
if (Test-Path $doctorScript) {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $doctorScript
}
