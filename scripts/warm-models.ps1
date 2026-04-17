[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')
$RepoRoot = Get-RepoRoot
Import-DotEnv -Path (Join-Path $RepoRoot '.env')

$ollamaPort = Get-EnvValue -Name 'OLLAMA_PORT' -Default '11434'
$chat = Get-EnvValue -Name 'CHAT_MODEL' -Default 'llama3'
$embedding = Get-EnvValue -Name 'EMBEDDING_MODEL' -Default 'embeddinggemma'

Write-Host "==> Precargando $chat"
$generateBody = @{ model = $chat; prompt = ''; keep_alive = -1 } | ConvertTo-Json -Compress
$null = Invoke-RestMethod -Uri "http://localhost:$ollamaPort/api/generate" -Method Post -ContentType 'application/json' -Body $generateBody -TimeoutSec 60

Write-Host "==> Precargando $embedding"
$embedBody = @{ model = $embedding; input = 'warmup'; keep_alive = '10m' } | ConvertTo-Json -Compress
$null = Invoke-RestMethod -Uri "http://localhost:$ollamaPort/api/embed" -Method Post -ContentType 'application/json' -Body $embedBody -TimeoutSec 60

Write-Host '==> Modelos precargados'
