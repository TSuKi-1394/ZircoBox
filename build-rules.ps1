<#
.SYNOPSIS  Genere rules-custom\rules_ultimate.json (rules_windows_all de Zircolite + conversions SigmaHQ et mdecrevoisier) via Docker.
.EXAMPLE   .\build-rules.ps1            # construction et generation
.EXAMPLE   .\build-rules.ps1 -Update    # reconstruit l'image sans cache (dernieres regles SigmaHQ)
#>
param([switch]$Update)
$ErrorActionPreference = "Stop"
$Image = "zircolite-rules-builder"
$Here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out   = Join-Path $Here "rules-custom"

# Voir zirco.ps1 : la redirection d'une commande native pose probleme en PowerShell 5.1 avec "Stop"
function Test-Native([scriptblock]$Cmd) {
  $old = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  & $Cmd *> $null
  $ok = ($LASTEXITCODE -eq 0)
  $ErrorActionPreference = $old
  return $ok
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Host "Docker est introuvable. Installez Docker Desktop (ou Docker Engine) puis relancez." ; exit 1
}
if (-not (Test-Native { docker info })) {
  Write-Host "Docker est installe mais ne repond pas. Lancez Docker Desktop et attendez qu'il soit pret." ; exit 1
}
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$bargs = @("build", "-t", $Image)
if ($Update) { $bargs += "--no-cache" }
docker @bargs (Join-Path $Here "docker\rules-builder")
if ($LASTEXITCODE) { exit $LASTEXITCODE }

# rules_windows_all.json est pris dans l'image Zircolite (construite ici si besoin)
$ZImage = if ($env:ZIRCOLITE_IMAGE) { $env:ZIRCOLITE_IMAGE } else { "zircolite-local" }
if (-not (Test-Native { docker image inspect $ZImage })) {
  Write-Host "[+] Construction de l'image $ZImage..."
  docker build -t $ZImage (Join-Path $Here "docker\zircolite")
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
docker run --rm --entrypoint cp -v "${Out}:/out" $ZImage /opt/Zircolite/rules/rules_windows_all.json /out/_zircolite_all.json
if ($LASTEXITCODE) { exit $LASTEXITCODE }

docker run --rm -v "${Out}:/out" $Image
if ($LASTEXITCODE -eq 0) { Write-Host "[+] Rulesets dans : $Out" }
exit $LASTEXITCODE
