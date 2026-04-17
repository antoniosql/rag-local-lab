[CmdletBinding()]
param(
    [switch]$Gpu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')
$RepoRoot = Get-RepoRoot
Import-DotEnv -Path (Join-Path $RepoRoot '.env')

$ollamaPort = Get-EnvValue -Name 'OLLAMA_PORT' -Default '11434'
$qdrantPort = Get-EnvValue -Name 'QDRANT_PORT' -Default '6333'
$anythingLLMPort = Get-EnvValue -Name 'ANYTHINGLLM_PORT' -Default '3001'

Write-Host '==> Estado de contenedores'
Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('ps')

Write-Host '==> Comprobando Ollama...'
Wait-ForUrl -Url "http://localhost:$ollamaPort/api/tags" -Name 'Ollama'

Write-Host '==> Comprobando Qdrant...'
Wait-ForUrl -Url "http://localhost:$qdrantPort/collections" -Name 'Qdrant'

Write-Host '==> Comprobando AnythingLLM...'
Wait-ForUrl -Url "http://localhost:$anythingLLMPort" -Name 'AnythingLLM'

Write-Host '==> Stack verificado'
