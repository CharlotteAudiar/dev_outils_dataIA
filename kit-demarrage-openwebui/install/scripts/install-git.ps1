# Installe Git (requis par les commandes `uvx --from git+...` qui clonent les serveurs MCP
# tiers hébergés sur GitHub, ex. qgis-mcp), s'il n'est pas déjà présent. Méthode retenue :
# winget (déjà intégré à Windows 10/11) - voir docs/guides.md pour le détail.

$ErrorActionPreference = "Stop"

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git est déjà installé : $(git --version)"
    exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "winget n'est pas disponible sur ce poste. Installer Git manuellement : https://git-scm.com/download/win"
    exit 1
}

Write-Host "Git n'est pas installé : lancement de l'installation via winget..."
winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git installé : $(git --version)"
} else {
    Write-Warning "Installation terminée, mais 'git' n'est pas encore reconnu dans cette fenêtre. Fermer ce terminal et en rouvrir un nouveau, puis vérifier avec 'git --version'."
}
