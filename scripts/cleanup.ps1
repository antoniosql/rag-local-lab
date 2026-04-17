[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$Offline,
    [switch]$Env,
    [switch]$All,
    [switch]$Gpu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')
$RepoRoot = Get-RepoRoot

if ($All) {
    $Full = $true
    $Offline = $true
    $Env = $true
}

Write-Host '>> Parando y eliminando contenedores, red, orphans y volúmenes del taller...'
try {
    Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('down', '-v', '--remove-orphans')
}
catch {
    Write-Warning $_.Exception.Message
}

Write-Host '>> Eliminando cachés Python locales...'
Get-ChildItem -Path $RepoRoot -Recurse -Directory -Filter '__pycache__' -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $RepoRoot -Recurse -File -Include '*.pyc', '*.pyo' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $RepoRoot '.pytest_cache') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $RepoRoot '.mypy_cache') -Recurse -Force -ErrorAction SilentlyContinue

if ($Full) {
    Write-Host '>> Eliminando imágenes Docker del taller...'
    & docker image rm -f 'busybox:1.36.1' 2>$null
    & docker image rm -f 'ollama/ollama' 'qdrant/qdrant' 2>$null
}

if ($Offline) {
    Write-Host '>> Eliminando bundles offline generados...'
    @(
        (Join-Path $RepoRoot 'offline/docker-images.tar'),
        (Join-Path $RepoRoot 'offline/ollama-models.tar.gz'),
        (Join-Path $RepoRoot 'offline/taller-rag-local-bundle.tar.gz')
    ) | ForEach-Object {
        Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue
    }
}

if ($Env) {
    Write-Host '>> Eliminando .env local...'
    Remove-Item -LiteralPath (Join-Path $RepoRoot '.env') -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'Limpieza completada.'
Write-Host ''
Write-Host 'Verificación recomendada:'
Write-Host "  docker ps -a | Select-String 'taller-rag-local'"
Write-Host "  docker volume ls | Select-String 'taller-rag-local'"
if ($Full) {
    Write-Host "  docker images | Select-String 'busybox|ollama/ollama|qdrant/qdrant'"
}
