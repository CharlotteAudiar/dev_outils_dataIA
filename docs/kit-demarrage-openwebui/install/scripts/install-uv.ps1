# Installe `uv` (gestionnaire d'outils Python requis par les scripts mcp-*), s'il n'est pas
# déjà présent. Méthode retenue : installeur officiel Astral, autonome (ne nécessite pas
# Python/pip pré-installés) : voir docs/guides.md pour les autres méthodes possibles et
# pourquoi celle-ci est recommandée pour ce kit.

$ErrorActionPreference = "Stop"

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "uv est déjà installé : $(uv --version)"
    exit 0
}

Write-Host "uv n'est pas installé : lancement de l'installeur officiel..."
Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "uv installé : $(uv --version)"
} else {
    Write-Warning "Installation terminée, mais 'uv' n'est pas encore reconnu dans cette fenêtre. Fermer ce terminal et en rouvrir un nouveau, puis vérifier avec 'uv --version'."
}
