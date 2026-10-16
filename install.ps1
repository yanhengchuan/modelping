#Requires -Version 5.1
<#
.SYNOPSIS
    ModelPing installer — verifies OpenAI-compatible API keys from the command line.

.DESCRIPTION
    Downloads ModelPing.bat from GitHub and installs it into a per-user folder,
    then adds that folder to your user PATH so you can run `ModelPing` from anywhere.

    One-line usage (PowerShell):
        irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/install.ps1 | iex

.NOTES
    The downloaded file is a GBK-encoded .bat with CRLF line endings; it is
    transferred byte-for-byte (no transcoding) so the Chinese output stays intact.
#>
[CmdletBinding()]
param(
    [string]$Branch     = 'main',
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'ModelPing'),
    [switch]$NoPathUpdate
)

$ErrorActionPreference = 'Stop'
$Repo = 'yanhengchuan/modelping'
$File = 'ModelPing.bat'
$Url  = "https://raw.githubusercontent.com/$Repo/$Branch/$File"

Write-Host "[ModelPing] installing from $Url" -ForegroundColor Cyan

# --- 1. download (byte-for-byte) ---
if (-not (Test-Path -LiteralPath $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
$Target = Join-Path $InstallDir $File

# Use a WebClient so the raw bytes are preserved without any text decoding.
try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add('User-Agent', 'ModelPing-Installer')
    $wc.DownloadFile($Url, $Target)
    $wc.Dispose()
} catch {
    Write-Error "Download failed: $($_.Exception.Message)"
    exit 1
}

if (-not (Test-Path -LiteralPath $Target) -or (Get-Item -LiteralPath $Target).Length -le 0) {
    Write-Error 'Downloaded file is missing or empty.'
    exit 1
}
Write-Host "[ModelPing] saved to $Target" -ForegroundColor Green

# --- 2. add the folder to the USER PATH (idempotent) ---
if (-not $NoPathUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $userPath) { $userPath = '' }
    $parts = $userPath -split ';' | Where-Object { $_ -ne '' }
    if ($parts -notcontains $InstallDir) {
        $newPath = (@($parts) + $InstallDir) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "[ModelPing] added to user PATH: $InstallDir" -ForegroundColor Green
        Write-Host "[ModelPing] open a NEW terminal for the PATH change to take effect." -ForegroundColor Yellow
    } else {
        Write-Host '[ModelPing] already present in user PATH.' -ForegroundColor DarkGray
    }
}

# --- 3. done ---
Write-Host ''
Write-Host '[ModelPing] installed successfully.' -ForegroundColor Green
Write-Host 'Usage:  ModelPing <vendor> <api-key> <model>'
Write-Host '        ModelPing /?      for help'
Write-Host 'Uninstall:'
Write-Host "        irm https://raw.githubusercontent.com/$Repo/$Branch/uninstall.ps1 | iex"
