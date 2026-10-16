@echo off
chcp 65001 >nul
title TuQuet Dotfiles - Windows Bootstrap

:: Lay thu muc dotfiles goc
set "DOTFILES_DIR=%~dp0"
if "%DOTFILES_DIR:~-1%"=="\" set "DOTFILES_DIR=%DOTFILES_DIR:~0,-1%"

:MENU
cls
echo ==============================================================================
echo                 TUQUET DOTFILES - WINDOWS BOOTSTRAP
echo ==============================================================================
echo  Thu muc: %DOTFILES_DIR%
echo.
echo   [1] Cai dat tron goi (Apps + Cloud CLIs + Lien ket Dotfiles)
echo   [2] Chi lien ket dotfiles (SSH, Terminal, Git, VS Code, Profile)
echo   [3] Cap nhat toan bo he thong (Scoop, Cloud CLIs, Caches)
echo   [0] Thoat
echo.
echo ==============================================================================
choice /c 1230 /n /m "Lua chon cua ban [1, 2, 3, 0]: "
if %errorlevel% equ 4 goto EXIT
if %errorlevel% equ 3 goto UPDATE_ALL
if %errorlevel% equ 2 goto DOTFILES_ONLY
if %errorlevel% equ 1 goto FULL_SETUP
goto EXIT

:: ==============================================================================
:: 1. CAI DAT TRON GOI (FULL BOOTSTRAP)
:: ==============================================================================
:FULL_SETUP
cls
echo ==============================================================================
echo   [1/4] KHOI TAO SCOOP VA BUCKETS
echo ==============================================================================
where scoop >nul 2>nul
if %errorlevel% neq 0 (
    echo Dang cai dat Scoop...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
) else (
    echo [OK] Scoop da san sang.
)
call scoop bucket add extras 2>nul
call scoop bucket add nerd-fonts 2>nul
echo [OK] Buckets extras va nerd-fonts da san sang.

echo.
echo ==============================================================================
echo   [2/4] CAI DAT PHAN MEM VA CLOUD CLIs QUA SCOOP
echo ==============================================================================
if exist "%DOTFILES_DIR%\packages\scoop-apps.txt" (
    for /f "usebackq eol=# delims=" %%A in ("%DOTFILES_DIR%\packages\scoop-apps.txt") do (
        echo.
        echo [*] Cai dat / kiem tra: %%A...
        call scoop install %%A
    )
) else (
    for %%A in (7zip git gh pwsh fnm python uv supabase cloudflared powertoys quicklook vscode obsidian telegram bruno wpsoffice cpu-z JetBrainsMono-NF) do (
        echo.
        echo [*] Cai dat / kiem tra: %%A...
        call scoop install %%A
    )
)

echo.
echo ==============================================================================
echo   [3/4] CAI DAT CLOUD CLIs QUA NPM (Vercel, Wrangler, Netlify)
echo ==============================================================================
where npm >nul 2>nul
if %errorlevel% equ 0 (
    if exist "%DOTFILES_DIR%\packages\npm-clis.txt" (
        for /f "usebackq eol=# delims=" %%A in ("%DOTFILES_DIR%\packages\npm-clis.txt") do (
            echo.
            echo [*] Cai dat / cap nhat NPM package: %%A...
            call npm install -g %%A
        )
    ) else (
        call npm install -g vercel wrangler netlify-cli
    )
) else (
    echo [CANH BAO] Khong tim thay npm. Vui long cai Node.js hoac fnm truoc.
)

echo.
echo ==============================================================================
echo   [4/4] THIET LAP LIEN KET DOTFILES
echo ==============================================================================
goto DO_JUNCTIONS

:: ==============================================================================
:: 2. CHI THIET LAP LIEN KET DOTFILES
:: ==============================================================================
:DOTFILES_ONLY
cls
echo ==============================================================================
echo   THIET LAP HE THONG LIEN KET DOTFILES (NTFS JUNCTIONS)
echo ==============================================================================

:DO_JUNCTIONS
echo 1. Lien ket SSH servers va config...
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
if exist "%USERPROFILE%\.ssh\servers" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '$env:USERPROFILE\.ssh\servers'; $item = Get-Item $p; if (-not $item.LinkType) { $bk = \"$p`_backup_\" + (Get-Date -Format 'yyyyMMdd_HHmmss'); Rename-Item $p $bk; Write-Host \"  [BACKUP] Thu muc servers cu da duoc doi ten thanh $bk\" -ForegroundColor Yellow } else { [System.IO.Directory]::Delete($p) }"
)
mklink /J "%USERPROFILE%\.ssh\servers" "%DOTFILES_DIR%\ssh\servers" >nul 2>nul
if exist "%DOTFILES_DIR%\ssh\config" copy /Y "%DOTFILES_DIR%\ssh\config" "%USERPROFILE%\.ssh\config" >nul
echo   [OK] SSH config SSOT va 4 servers da lien ket.

echo 2. Lien ket Windows Terminal...
set "WT_DIR=%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if exist "%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe" (
    if exist "%WT_DIR%" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'; $item = Get-Item $p; if ($item.LinkType) { [System.IO.Directory]::Delete($p) } else { rmdir /s /q $p 2>$null }"
    )
    mklink /J "%WT_DIR%" "%DOTFILES_DIR%\terminal\LocalState" >nul 2>nul
    echo   [OK] Windows Terminal LocalState da lien ket.
)

echo 3. Lien ket Git config toan cuc...
where git >nul 2>nul
if %errorlevel% equ 0 (
    git config --global include.path "~/OneDrive/dotfiles/git/.gitconfig"
    echo   [OK] Git config toan cuc da lien ket.
)

echo 4. Them dotfiles\bin vao PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = [Environment]::GetEnvironmentVariable('Path', 'User'); if (-not ($p -split ';').Contains('%DOTFILES_DIR%\bin')) { [Environment]::SetEnvironmentVariable('Path', $p.TrimEnd(';') + ';%DOTFILES_DIR%\bin', 'User') }"
echo   [OK] dotfiles\bin da co trong PATH.

echo 5. Lien ket VS Code Project Manager...
set "VSCODE_SCOOP=%USERPROFILE%\scoop\persist\vscode\data\user-data\User\globalStorage\alefragnani.project-manager"
if exist "%USERPROFILE%\scoop\persist\vscode" (
    if not exist "%USERPROFILE%\scoop\persist\vscode\data\user-data\User\globalStorage" mkdir "%USERPROFILE%\scoop\persist\vscode\data\user-data\User\globalStorage"
    if exist "%VSCODE_SCOOP%" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '$env:USERPROFILE\scoop\persist\vscode\data\user-data\User\globalStorage\alefragnani.project-manager'; $item = Get-Item $p -ErrorAction SilentlyContinue; if ($item.LinkType) { [System.IO.Directory]::Delete($p) }"
    )
    mklink /J "%VSCODE_SCOOP%" "%DOTFILES_DIR%\vscode\project-manager" >nul 2>nul
    echo   [OK] VS Code (Scoop) Project Manager da lien ket.
)
set "VSCODE_NATIVE=%APPDATA%\Code\User\globalStorage\alefragnani.project-manager"
if exist "%APPDATA%\Code" (
    if not exist "%APPDATA%\Code\User\globalStorage" mkdir "%APPDATA%\Code\User\globalStorage"
    if exist "%VSCODE_NATIVE%" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = '$env:APPDATA\Code\User\globalStorage\alefragnani.project-manager'; $item = Get-Item $p -ErrorAction SilentlyContinue; if ($item.LinkType) { [System.IO.Directory]::Delete($p) }"
    )
    mklink /J "%VSCODE_NATIVE%" "%DOTFILES_DIR%\vscode\project-manager" >nul 2>nul
    echo   [OK] VS Code (Native) Project Manager da lien ket.
)

echo 6. Lien ket PowerShell Profile...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$loader = \"if (Test-Path '%DOTFILES_DIR%\powershell\Microsoft.PowerShell_profile.ps1') { . '%DOTFILES_DIR%\powershell\Microsoft.PowerShell_profile.ps1' }\"; foreach ($p in @(\"$HOME\Documents\PowerShell\", \"$HOME\Documents\WindowsPowerShell\", \"$env:OneDrive\Documents\PowerShell\", \"$env:OneDrive\Documents\WindowsPowerShell\")) { if ($p -and (Test-Path (Split-Path $p -Parent))) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }; Set-Content -Path \"$p\Microsoft.PowerShell_profile.ps1\" -Value $loader -Encoding UTF8 } }"
echo   [OK] PowerShell Profile da kich hoat tren ca pwsh va powershell 5.1.

echo 7. Dang ky Obsidian Vault...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$vPath = [System.IO.Path]::Combine($HOME, 'OneDrive', 'Documents', 'Obsidian Vault'); if (Test-Path $vPath) { $obsDir = \"$env:APPDATA\obsidian\"; if (-not (Test-Path $obsDir)) { New-Item -ItemType Directory -Path $obsDir -Force | Out-Null }; @{ 'vaults' = @{ 'primary-vault' = @{ 'path' = $vPath; 'ts' = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); 'open' = $true } } } | ConvertTo-Json -Depth 5 | Set-Content -Path \"$obsDir\obsidian.json\" -Encoding UTF8; Write-Host '  [OK] Obsidian Vault da dang ky.' -ForegroundColor Green }"

echo 8. Extensions VS Code va khoi dong tien ich...
where code >nul 2>nul
if %errorlevel% equ 0 (
    call code --install-extension alefragnani.project-manager --force >nul 2>nul
    call code --install-extension ms-vscode-remote.remote-ssh --force >nul 2>nul
    echo   [OK] VS Code extensions da kich hoat.
)
if exist "%USERPROFILE%\scoop\apps\quicklook\current\QuickLook.exe" (
    start "" "%USERPROFILE%\scoop\apps\quicklook\current\QuickLook.exe"
    echo   [OK] QuickLook da khoi dong.
)
if exist "%USERPROFILE%\scoop\apps\powertoys\current\PowerToys.exe" (
    start "" "%USERPROFILE%\scoop\apps\powertoys\current\PowerToys.exe"
    echo   [OK] PowerToys da khoi dong.
)

echo.
if exist "%DOTFILES_DIR%\bin\doctor.cmd" (
    call "%DOTFILES_DIR%\bin\doctor.cmd"
)
pause
goto MENU

:: ==============================================================================
:: 3. CAP NHAT TOAN BO HE THONG
:: ==============================================================================
:UPDATE_ALL
cls
echo ==============================================================================
echo   CAP NHAT TOAN BO HE THONG (SCOOP, CLOUD CLIs, CACHES)
echo ==============================================================================
if exist "%DOTFILES_DIR%\bin\update-all.cmd" (
    call "%DOTFILES_DIR%\bin\update-all.cmd"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%DOTFILES_DIR%\bin\update-all.ps1"
)
pause
goto MENU

:EXIT
echo Tam biet!
exit /b 0
