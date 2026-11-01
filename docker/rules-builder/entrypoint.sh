#!/bin/sh
# Convertit SigmaHQ + mdecrevoisier (variantes générique et Sysmon) puis les fusionne avec rules_windows_all de Zircolite.
# Sortie dans /out : rules_ultimate.json
set -u
OUT=/out
WORK=/tmp/work
mkdir -p "$OUT" "$WORK"

SIGMA=/src/sigma
MDR=/src/mdecrevoisier

# Dossiers Windows de SigmaHQ (détection d'attaques uniquement : pas de rules-compliance)
SIGMA_DIRS=""
for d in rules/windows rules-emerging-threats rules-threat-hunting/windows rules-dfir/windows; do
  [ -d "$SIGMA/$d" ] && SIGMA_DIRS="$SIGMA_DIRS $SIGMA/$d"
done
# mdecrevoisier utilise l'extension .yaml (sigma-cli ne lit que .yml) : copie renommée
MDR_YML=/tmp/mdr
mkdir -p "$MDR_YML"
for d in "$MDR"/windows-*; do
  n=$(basename "$d"); mkdir -p "$MDR_YML/$n"
  for f in "$d"/*.yaml; do
    [ -e "$f" ] && cp "$f" "$MDR_YML/$n/$(basename "$f" .yaml | tr ' ()' '___').yml"
  done
done
MDR_DIRS=$(find "$MDR_YML" -mindepth 1 -maxdepth 1 -type d | tr '\n' ' ')

convert() { # $1=variante $2=source $3..=pipelines/dossiers
  variant=$1; src=$2; shift 2
  echo "[+] $variant / $src"
  # Une règle au YAML invalide fait échouer tout le lot : on l'écarte puis on relance
  i=0
  while [ $i -lt 60 ]; do
    sigma convert -t sqlite -f zircolite -s "$@" -o "$WORK/${variant}_${src}.json" 2>"$WORK/err.txt" && return 0
    bad=$(grep -o '/[^ ]*\.yml' "$WORK/err.txt")
    if [ -n "$bad" ] && grep -q 'Errors found' "$WORK/err.txt"; then
      for b in $bad; do echo "[!] règle invalide écartée : $b"; rm -f "$b"; done
    else
      tail -3 "$WORK/err.txt"; break
    fi
    i=$((i+1))
  done
  # Repli : conversion fichier par fichier (une règle mal formée ne bloque plus les autres)
  echo "[!] lot échoué, repli fichier par fichier : $variant / $src"
  parts="$WORK/parts_${variant}_${src}"; rm -rf "$parts"; mkdir -p "$parts"
  pipes=""; dirs=""
  for a in "$@"; do if [ -d "$a" ]; then dirs="$dirs $a"; else pipes="$pipes $a"; fi; done
  for d in $dirs; do
    find "$d" -name '*.yml' | while read -r f; do
      # shellcheck disable=SC2086
      sigma convert -t sqlite -f zircolite -s $pipes "$f" -o "$parts/$(echo "$f" | md5sum | cut -c1-12).json" >/dev/null 2>&1 \
        || echo "[!] ignorée : $f"
    done
  done
  python3 /build/merge.py "$WORK/${variant}_${src}.json" "$parts"/*.json
}

for variant in generic sysmon; do
  if [ "$variant" = sysmon ]; then P="-p sysmon -p windows-logsources"; else P="-p windows-logsources"; fi
  # shellcheck disable=SC2086
  convert "$variant" sigma $P $SIGMA_DIRS
  # shellcheck disable=SC2086
  convert "$variant" mdr $P $MDR_DIRS
done

# rules_windows_all de Zircolite (copié par build-rules) en premier = prioritaire ;
# nos conversions n'ajoutent que les règles dont l'id est absent.
[ -f "$OUT/_zircolite_all.json" ] || echo "[!] _zircolite_all.json absent : ruleset limité à nos conversions"
python3 /build/merge.py "$OUT/rules_ultimate.json" "$OUT/_zircolite_all.json" \
  "$WORK/sysmon_sigma.json" "$WORK/sysmon_mdr.json" "$WORK/generic_sigma.json" "$WORK/generic_mdr.json"
rm -f "$OUT/_zircolite_all.json" "$OUT/rules_ultimate_sysmon.json" "$OUT/rules_ultimate_generic.json"
ls -l "$OUT"
