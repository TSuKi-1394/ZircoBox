#!/usr/bin/env bash
# Génère rules-custom/rules_ultimate.json (rules_windows_all de Zircolite + conversions SigmaHQ et mdecrevoisier).
# Usage: ./build-rules.sh [--update]   (--update reconstruit l'image sans cache pour récupérer les dernières règles)
set -euo pipefail
IMAGE="zircolite-rules-builder"
ZIMAGE="${ZIRCOLITE_IMAGE:-zircolite-local}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/rules-custom"

command -v docker >/dev/null 2>&1 || { echo "Docker est introuvable. Installez Docker puis relancez."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker ne répond pas. Démarrez le service Docker."; exit 1; }
mkdir -p "$OUT"

BUILD_ARGS=()
[ "${1:-}" = "--update" ] && BUILD_ARGS+=(--no-cache)
docker build ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} -t "$IMAGE" "$HERE/docker/rules-builder"

docker image inspect "$ZIMAGE" >/dev/null 2>&1 || { echo "[+] Construction de l'image $ZIMAGE..."; docker build -t "$ZIMAGE" "$HERE/docker/zircolite"; }
docker run --rm --entrypoint cp -v "$OUT:/out" "$ZIMAGE" /opt/Zircolite/rules/rules_windows_all.json /out/_zircolite_all.json

docker run --rm -v "$OUT:/out" "$IMAGE"
echo "[+] Rulesets dans : $OUT"
