<#
.SYNOPSIS
    TuQuet Dotfiles CLI Assistant
.DESCRIPTION
    Quick commands to inspect, sync, update, and manage dotfiles from any terminal.
.EXAMPLE
    dotfiles doctor
    dotfiles link
    dotfiles update
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('doctor', 'link', 'update', 'status', 'help')]
    [string]$Command = 'help'
)

$DotfilesDir = Split-Path -Parent $PSScriptRoot

switch ($Command) {
    'doctor' {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $DotfilesDir "bin\doctor.ps1")
    }
    'link' {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $DotfilesDir "install.ps1") -Mode LinkOnly
    }
    'update' {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $DotfilesDir "bin\update-all.ps1")
    }
    'status' {
        & git -C $DotfilesDir status
    }
    default {
        Write-Host "TuQuet Dotfiles CLI Tools" -ForegroundColor Cyan
        Write-Host "Usage: dotfiles <command>`n"
        Write-Host "Commands:"
        Write-Host "  doctor   Run health check (SSH, Junctions, CLIs)"
        Write-Host "  link     Re-link all NTFS Junctions and profiles (2s)"
        Write-Host "  update   Update Scoop, NPM global packages & clean cache"
        Write-Host "  status   Check git status of dotfiles repository"
    }
}
