<#
.SYNOPSIS  Analyse de journaux .evtx avec Zircolite via Docker.
.EXAMPLE   .\zirco.ps1 -Logs C:\logs\Security.evtx -Rules rules_windows_generic
.EXAMPLE   .\zirco.ps1 -Logs C:\logs -Rules rules_ultimate -Output C:\res -Package
.EXAMPLE   .\zirco.ps1 -ListRules
#>
param(
  [string]$Logs,
  [string[]]$Rules,
  [string]$Output = ".\zircolite-output",
  [switch]$Package,
  [switch]$ListRules,
  [switch]$Rebuild,
  [string[]]$Extra = @()
)
$ErrorActionPreference = "Stop"
$Image = if ($env:ZIRCOLITE_IMAGE) { $env:ZIRCOLITE_IMAGE } else { "zircolite-local" }
$Here  = Split-Path -Parent $MyInvocation.MyCommand.Path

# Sous Windows PowerShell 5.1, rediriger la sortie d'une commande native avec
# $ErrorActionPreference = "Stop" provoque une erreur : on le désactive le temps du test.
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

$BuildDir = Join-Path $Here "docker\zircolite"
if ($Rebuild) { docker build --no-cache -t $Image $BuildDir; exit $LASTEXITCODE }
if (-not (Test-Native { docker image inspect $Image })) {
  Write-Host "[+] Construction de l'image $Image..."
  docker build -t $Image $BuildDir
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

if ($ListRules) { docker run --rm --entrypoint ls $Image /opt/Zircolite/rules; exit $LASTEXITCODE }
if (-not $Logs -or -not $Rules) { Get-Help $MyInvocation.MyCommand.Path -Examples; exit 1 }

if (-not (Test-Path $Logs)) { Write-Host "Introuvable : $Logs"; exit 1 }
$LogsFull = (Resolve-Path $Logs).Path
if (Test-Path $LogsFull -PathType Container) { $MountDir = $LogsFull; $Target = "/logs" }
else { $MountDir = Split-Path $LogsFull -Parent; $Target = "/logs/" + (Split-Path $LogsFull -Leaf) }

New-Item -ItemType Directory -Force -Path $Output | Out-Null
$OutFull = (Resolve-Path $Output).Path

$Custom = Join-Path $Here "rules-custom"
New-Item -ItemType Directory -Force -Path $Custom | Out-Null

# rules_ultimate est généré localement : on le construit à la première utilisation
$wantsUltimate = $Rules | Where-Object { $_ -match '^rules_ultimate(\.json)?$' }
if ($wantsUltimate -and -not (Test-Path (Join-Path $Custom "rules_ultimate.json"))) {
  Write-Host "[+] rules_ultimate.json absent, generation (quelques minutes)..."
  & (Join-Path $Here "build-rules.ps1")
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

$zargs = @("--evtx", $Target, "-o", "/output/detected_events.json")
foreach ($r in $Rules) {
  if (-not $r.EndsWith(".json")) { $r += ".json" }
  # Un ruleset de rules-custom est prioritaire sur ceux de l'image
  if (Test-Path (Join-Path $Custom $r)) { $zargs += @("-r", "/rules-custom/$r") } else { $zargs += @("-r", "rules/$r") }
}
if ($Package) { $zargs += @("--package", "--package-dir", "/output") }
$zargs += $Extra

docker run --rm -v "${MountDir}:/logs:ro" -v "${OutFull}:/output" -v "${Custom}:/rules-custom:ro" $Image @zargs
if ($LASTEXITCODE -eq 0) { Write-Host "[+] Resultats dans : $OutFull" }
exit $LASTEXITCODE
