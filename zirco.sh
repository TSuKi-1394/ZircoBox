#!/usr/bin/env bash
# Usage: ./zirco.sh -l <fichier.evtx|dossier> -r <ruleset> [-r <autre> ...] [-o <dossier_sortie>] [-p] [-- args zircolite supplémentaires]
set -euo pipefail
IMAGE="${ZIRCOLITE_IMAGE:-zircolite-local}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS=""; OUT="./zircolite-output"; PKG=0; RULES=()

usage() { sed -n '2p' "$0" | sed 's/^# //'; echo "Rulesets: ./zirco.sh --list-rules"; exit 1; }

build_if_needed() {
  docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "[+] Construction de l'image $IMAGE..."; docker build -t "$IMAGE" "$HERE/docker/zircolite"; }
}

command -v docker >/dev/null 2>&1 || { echo "Docker est introuvable. Installez Docker puis relancez."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker ne répond pas. Démarrez le service Docker."; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -l|--logs)  LOGS="$2"; shift 2;;
    -r|--rules) RULES+=("$2"); shift 2;;
    -o|--output) OUT="$2"; shift 2;;
    -p|--package) PKG=1; shift;;
    --rebuild) docker build --no-cache -t "$IMAGE" "$HERE/docker/zircolite"; exit 0;;
    --list-rules) build_if_needed; docker run --rm --entrypoint ls "$IMAGE" /opt/Zircolite/rules; exit 0;;
    --) shift; break;;
    -h|--help) usage;;
    *) echo "Option inconnue: $1"; usage;;
  esac
done

[ -n "$LOGS" ] && [ ${#RULES[@]} -gt 0 ] || usage
[ -e "$LOGS" ] || { echo "Introuvable: $LOGS"; exit 1; }
build_if_needed
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

if [ -d "$LOGS" ]; then MOUNT_DIR="$(cd "$LOGS" && pwd)"; TARGET="/logs"
else MOUNT_DIR="$(cd "$(dirname "$LOGS")" && pwd)"; TARGET="/logs/$(basename "$LOGS")"; fi

# rules_ultimate est généré localement : on le construit à la première utilisation
for r in "${RULES[@]}"; do
  case "$r" in rules_ultimate|rules_ultimate.json)
    [ -e "$HERE/rules-custom/rules_ultimate.json" ] || { echo "[+] rules_ultimate.json absent, génération (quelques minutes)..."; bash "$HERE/build-rules.sh"; };;
  esac
done

ARGS=(--evtx "$TARGET" -o /output/detected_events.json)
for r in "${RULES[@]}"; do
  case "$r" in *.json) ;; *) r="$r.json";; esac
  # Un ruleset de rules-custom est prioritaire sur ceux de l'image
  if [ -e "$HERE/rules-custom/$r" ]; then ARGS+=(-r "/rules-custom/$r"); else ARGS+=(-r "rules/$r"); fi
done
[ "$PKG" -eq 1 ] && ARGS+=(--package --package-dir /output)

mkdir -p "$HERE/rules-custom"
docker run --rm -v "$MOUNT_DIR:/logs:ro" -v "$OUT:/output" -v "$HERE/rules-custom:/rules-custom:ro" "$IMAGE" "${ARGS[@]}" "$@"
echo "[+] Résultats dans: $OUT"
