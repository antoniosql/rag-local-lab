[CmdletBinding()]
param(
    [switch]$Offline,
    [switch]$Gpu,
    [switch]$SkipPullModels,
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')
$RepoRoot = Get-RepoRoot

Assert-Command -Name 'docker'

$envExample = Join-Path $RepoRoot '.env.example'
$envFile = Join-Path $RepoRoot '.env'
if (-not (Test-Path -LiteralPath $envFile) -and (Test-Path -LiteralPath $envExample)) {
    Copy-Item -LiteralPath $envExample -Destination $envFile
    Write-Host '==> Se ha creado .env a partir de .env.example'
}

Import-DotEnv -Path $envFile
$anythingLLMPort = Get-EnvValue -Name 'ANYTHINGLLM_PORT' -Default '3001'

if ($Offline) {
    $bundle = Join-Path $RepoRoot 'offline/docker-images.tar'
    if (Test-Path -LiteralPath $bundle) {
        Write-Host "==> Cargando imágenes desde $bundle"
        & docker load -i $bundle
        if ($LASTEXITCODE -ne 0) { throw 'Falló docker load' }
    }
    else {
        Write-Warning "No existe $bundle. Se asume que las imágenes ya están cargadas."
    }

    $importModelsPs1 = Join-Path $RepoRoot 'offline/import_ollama_models.ps1'
    if (Test-Path -LiteralPath $importModelsPs1) {
        & $importModelsPs1
        if ($LASTEXITCODE -ne 0) { throw 'Falló la importación de modelos de Ollama' }
    }
    else {
        Write-Warning 'No existe offline/import_ollama_models.ps1. Se asume que el volumen de modelos ya está restaurado.'
    }

    Write-Host '==> Levantando stack en modo offline...'
    Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('up', '-d', '--no-build')
}
else {
    Write-Host '==> Levantando Ollama, Qdrant y AnythingLLM...'
    Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('up', '-d')

    if (-not $SkipPullModels) {
        & (Join-Path $ScriptDir 'pull-models.ps1') -Gpu:$Gpu
        if ($LASTEXITCODE -ne 0) { throw 'Falló la carga de modelos en Ollama' }
    }
}

if (-not $SkipVerify) {
    & (Join-Path $ScriptDir 'verify-stack.ps1') -Gpu:$Gpu
    if ($LASTEXITCODE -ne 0) { throw 'Falló la verificación del stack' }
}

Write-Host ''
Write-Host 'Siguientes pasos sugeridos:'
Write-Host '  1) Crear el entorno local de Python e instalar dependencias:'
Write-Host '     python -m venv .venv'
Write-Host '     .\.venv\Scripts\Activate.ps1'
Write-Host '     pip install -r requirements-local.txt'
Write-Host '  2) Abrir AnythingLLM para la demo inicial:'
Write-Host "     http://localhost:$anythingLLMPort"
Write-Host '  3) Lanzar JupyterLab y seguir los notebooks:'
Write-Host '     jupyter lab'
