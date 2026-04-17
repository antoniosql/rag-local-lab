[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

Write-Host '==> Comprobando Docker...'
Assert-Command -Name 'docker'
& docker --version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker no está disponible' }

Write-Host '==> Comprobando Docker Compose v2...'
& docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose v2 no está disponible' }

Write-Host '==> Comprobando PowerShell...'
Write-Host "PowerShell $($PSVersionTable.PSVersion)"

Write-Host '==> Comprobando Python...'
Assert-Command -Name 'python'
& python --version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Python no está disponible' }

Write-Host '==> Comprobación básica OK'
