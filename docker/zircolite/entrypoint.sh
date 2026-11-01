#!/bin/sh
# Lance Zircolite depuis son répertoire d'installation puis récupère les sorties dans /output.
set -e
cd /opt/Zircolite
mkdir -p /output
python3 zircolite.py "$@"
rc=$?
# Les rapports --package sont créés dans le répertoire courant : on les copie vers /output
for f in zircogui-output-*.zip; do
  [ -e "$f" ] && mv "$f" /output/
done
exit $rc
