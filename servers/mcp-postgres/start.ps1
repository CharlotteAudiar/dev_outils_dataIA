# Lance mcp-postgres exposé via mcpo (proxy MCP -> OpenAPI)
# Équivalent PowerShell de start.sh (même dossier) — pour postes Windows utilisateurs,
# sans dépendance à bash/WSL/Git Bash (cf. échange du 24/07/2026 : `bash` resolvait vers WSL,
# qui ne traduit pas les chemins de lecteurs réseau mappés).

## Variables d'environnement requises : DATABASE_URI, MCPO_API_KEY_POSTGRES (voir config/.env.example)

## Mode restreint (lecture seule) par défaut — voir README.md (même dossier) pour la justification

$ErrorActionPreference = "Stop"

# Charge automatiquement le .env à la racine du repo s'il existe
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$EnvFile = Join-Path $RepoRoot ".env"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $key, $value = $line -split "=", 2
            [System.Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
        }
    }
}

if (-not $env:DATABASE_URI) {
    Write-Error "Variable DATABASE_URI non définie (voir config/.env.example)"
    exit 1
}
if (-not $env:MCPO_API_KEY_POSTGRES) {
    Write-Error "Variable MCPO_API_KEY_POSTGRES non définie (voir config/.env.example)"
    exit 1
}

uvx mcpo --port 8002 --api-key $env:MCPO_API_KEY_POSTGRES -- `
    uvx postgres-mcp --access-mode=restricted
