# ==============================================================================
# Centralized PowerShell Profile - TuQuet Dotfiles
# ==============================================================================

# 1. Prioritize Scoop shims and tools in PATH
$scoopShims = "$HOME\scoop\shims"
$scoopGit = "$HOME\scoop\apps\git\current\cmd"
if (Test-Path $scoopShims) {
    $env:PATH = "$scoopShims;$scoopGit;$env:PATH"
}

# 2. Initialize Fast Node Manager (fnm)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

# 3. Oh-My-Posh Prompt Initialization
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themePath = "$HOME\.posh-themes\jandedobbeleer.omp.json"
    if (-not (Test-Path $themePath)) {
        New-Item -ItemType Directory -Path "$HOME\.posh-themes" -Force | Out-Null
        try {
            Invoke-RestMethod -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json" -OutFile $themePath -TimeoutSec 5
        } catch {
            # Neu mat ket noi mang, dung theme mac dinh
        }
    }
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# 4. Git Freeze Helpers (Hide/Unhide local modified files)
function git-hide {
    git diff --name-only | ForEach-Object { git update-index --skip-worktree $_ }
    Write-Host "✔ Da dong bang toan bo thay doi hien tai!" -ForegroundColor Cyan
}

function git-unhide {
    git ls-files -v | Select-String "^S" | ForEach-Object {
        $file = $_.ToString().Substring(2)
        git update-index --no-skip-worktree $file
    }
    Write-Host "✔ Da ra bang toan bo file!" -ForegroundColor Yellow
}

function git-hidden {
    git ls-files -v | Select-String "^S" | ForEach-Object { $_.ToString().Substring(2) }
}
