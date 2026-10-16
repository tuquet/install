# ==============================================================================
# TuQuet System Health Check (Doctor)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                  TUQUET - SYSTEM HEALTH CHECK                                " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# 1. Dev Core Tools
Write-Host "`n[1. Dev Core Tools]" -ForegroundColor Yellow
$coreTools = @("git", "pwsh", "scoop", "fnm", "python", "uv")
foreach ($tool in $coreTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $tool da san sang" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $tool chua co trong PATH" -ForegroundColor Yellow
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
