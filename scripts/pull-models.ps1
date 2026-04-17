[CmdletBinding()]
param(
    [string]$ChatModel,
    [string]$EmbeddingModel,
    [switch]$Gpu
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')
$RepoRoot = Get-RepoRoot
Import-DotEnv -Path (Join-Path $RepoRoot '.env')

$chat = if ($ChatModel) { $ChatModel } else { Get-EnvValue -Name 'CHAT_MODEL' -Default 'llama3' }
$embedding = if ($EmbeddingModel) { $EmbeddingModel } else { Get-EnvValue -Name 'EMBEDDING_MODEL' -Default 'embeddinggemma' }

Write-Host "==> Cargando modelo de chat: $chat"
Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('exec', 'ollama', 'ollama', 'pull', $chat)

Write-Host "==> Cargando modelo de embeddings: $embedding"
Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('exec', 'ollama', 'ollama', 'pull', $embedding)

Write-Host '==> Modelos disponibles:'
Invoke-Compose -RepoRoot $RepoRoot -Gpu:$Gpu -Args @('exec', 'ollama', 'ollama', 'list')
