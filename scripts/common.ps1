Set-StrictMode -Version Latest

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Import-DotEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
            continue
        }

        $parts = $line -split '=', 2
        if ($parts.Count -ne 2) {
            continue
        }

        $name = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

function Get-EnvValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Default
    )

    $value = [System.Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value
}

function Assert-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontró el comando requerido: $Name"
    }
}

function Get-ComposeFileArgs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$Gpu
    )

    $baseCompose = Join-Path $RepoRoot 'docker-compose.yml'
    if (-not (Test-Path -LiteralPath $baseCompose)) {
        throw "No existe $baseCompose"
    }

    $args = @('-f', $baseCompose)

    if ($Gpu) {
        $gpuCompose = Join-Path $RepoRoot 'docker-compose.gpu.yml'
        if (-not (Test-Path -LiteralPath $gpuCompose)) {
            throw "Se ha pedido -Gpu pero no existe $gpuCompose"
        }
        $args += @('-f', $gpuCompose)
    }

    return $args
}

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$Gpu,
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    $composeArgs = @('compose') + (Get-ComposeFileArgs -RepoRoot $RepoRoot -Gpu:$Gpu) + $Args
    Push-Location $RepoRoot
    try {
        & docker @composeArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Falló docker compose $($Args -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Wait-ForUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [int]$Retries = 20,
        [int]$DelaySeconds = 2
    )

    for ($i = 1; $i -le $Retries; $i++) {
        try {
            $null = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
            Write-Host "$Name OK"
            return
        }
        catch {
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw "$Name no responde tras $Retries intentos: $Url"
}
