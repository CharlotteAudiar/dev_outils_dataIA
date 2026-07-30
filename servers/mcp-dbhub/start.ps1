# Lance mcp-dbhub (bytebase/dbhub) via mcpo — phase 1 (poste individuel, identifiants
# personnels), en comparaison avec mcp-postgres (crystaldba/postgres-mcp) — voir README.md et
# docs/architecture/decisions.md, section "Modèle de déploiement de mcp-postgres : plan en
# 3 phases". Statut (24/07/2026) : test en cours, comparaison pas encore tranchée.

## Variables d'environnement requises : DATABASE_URI, MCPO_API_KEY_DBHUB (voir config/.env.example
## — DATABASE_URI est la même variable que pour mcp-postgres, donc le même compte personnel)
## Prérequis : Node.js >= 22.5.0 (vérifier avec node -v) ; uv/uvx déjà installé (pour mcpo,
## comme les autres serveurs MCP du projet). Node.js reste une dépendance nouvelle pour ce
## projet (voir README.md, "Montage technique" et docs/architecture/benchmark-techno.md, section
## mcp-postgres, "dépendance runtime par candidat") — à peser dans la comparaison avec
## mcp-postgres, qui n'en ajoute aucune.

$ErrorActionPreference = "Stop"

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
if (-not $env:MCPO_API_KEY_DBHUB) {
    Write-Error "Variable MCPO_API_KEY_DBHUB non définie (voir config/.env.example)"
    exit 1
}

$ConfigPath = Join-Path $PSScriptRoot "dbhub.toml"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Fichier dbhub.toml manquant (copier dbhub.toml.example, même dossier, puis l'adapter)"
    exit 1
}

# dbhub tourne en --transport stdio (pas son mode HTTP natif) : c'est mcpo qui l'expose en
# OpenAPI et qui permet la connexion "Direct" personnelle attendue par Open WebUI pour ce
# montage par poste (voir README.md, "Pourquoi stdio + mcpo, pas le HTTP natif").
uvx --with "mcp==1.29.0" mcpo@0.0.20 --port 8003 --api-key $env:MCPO_API_KEY_DBHUB -- `
    npx --yes "@bytebase/dbhub@latest" --transport stdio --config $ConfigPath
