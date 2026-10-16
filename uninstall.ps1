#Requires -Version 5.1
<#
.SYNOPSIS
    ModelPing uninstaller — removes the tool installed by install.ps1.

.DESCRIPTION
    Removes ModelPing.bat, its sidecar ModelPing.zkey (if present), and the
    install folder from the user PATH.

    One-line usage (PowerShell):
        irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/uninstall.ps1 | iex
#>
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'ModelPing'),
    [switch]$KeepKeyFile
)

$ErrorActionPreference = 'Stop'
Write-Host "[ModelPing] uninstalling from $InstallDir" -ForegroundColor Cyan

# --- 1. remove files ---
$bat  = Join-Path $InstallDir 'ModelPing.bat'
$zkey = Join-Path $InstallDir 'ModelPing.zkey'

foreach ($f in @($bat)) {
    if (Test-Path -LiteralPath $f) {
        Remove-Item -LiteralPath $f -Force
        Write-Host "[ModelPing] removed $f" -ForegroundColor Green
    }
}
if (-not $KeepKeyFile -and (Test-Path -LiteralPath $zkey)) {
    Remove-Item -LiteralPath $zkey -Force
    Write-Host "[ModelPing] removed $zkey" -ForegroundColor Green
}

# remove the folder if it is now empty
if ((Test-Path -LiteralPath $InstallDir) -and
    -not (Get-ChildItem -LiteralPath $InstallDir -Force | Select-Object -First 1)) {
    Remove-Item -LiteralPath $InstallDir -Force
    Write-Host "[ModelPing] removed folder $InstallDir" -ForegroundColor Green
}

# --- 2. strip the folder from the USER PATH ---
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $parts = $userPath -split ';' | Where-Object { $_ -ne '' -and $_ -ne $InstallDir }
    $newPath = ($parts -join ';')
    if ($newPath -ne $userPath) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host '[ModelPing] removed from user PATH.' -ForegroundColor Green
    }
}

Write-Host '[ModelPing] uninstalled.' -ForegroundColor Green
