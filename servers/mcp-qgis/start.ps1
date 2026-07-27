# Lance mcp-qgis exposé via mcpo (proxy MCP -> OpenAPI)
# Équivalent PowerShell de start.sh (même dossier) — pour postes Windows utilisateurs,
# sans dépendance à bash/WSL/Git Bash (cf. échange du 24/07/2026 : `bash` resolvait vers WSL,
# qui ne traduit pas les chemins de lecteurs réseau mappés).

#~# Variable d'environnement requise : MCPO_API_KEY_QGIS (voir config/.env.example)
## Prérequis : plugin "QGIS MCP" démarré dans QGIS Desktop (voir README.md, même dossier)

$ErrorActionPreference = "Stop"

# Charge automatiquement le .env à la racine du repo s'il existe (non versionné, voir .gitignore).
# Sinon, la variable doit déjà être définie dans l'environnement appelant.
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

if (-not $env:MCPO_API_KEY_QGIS) {
    Write-Error "Variable MCPO_API_KEY_QGIS non définie (voir config/.env.example)"
    exit 1
}

uvx mcpo --port 8001 --api-key $env:MCPO_API_KEY_QGIS -- `
    uvx --from git+https://github.com/nkarasiak/qgis-mcp qgis-mcp-server
