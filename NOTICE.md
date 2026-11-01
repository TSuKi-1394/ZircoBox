# Crédits et licences

Copyright (C) 2026 TSuKi-1394

Le code de ce dépôt (scripts, Dockerfiles, documentation) est publié sous GPL-3.0, voir le fichier LICENSE.

Il s'appuie sur des travaux d'autres personnes, qui gardent leur propre licence.

| Composant | Auteur | Licence | Utilisation ici |
|---|---|---|---|
| Zircolite | wagga40 | LGPL-3.0 | Cloné dans l'image Docker au moment de la construction, rien n'est copié dans le dépôt |
| Zircolite-Rules-v2 | wagga40 | selon la source de chaque règle | Fournit rules_windows_all.json, récupéré dans l'image Docker |
| Règles Sigma | SigmaHQ | DRL 1.1 | Clonées et converties localement par build-rules |
| SIGMA-detection-rules | mdecrevoisier | CC0 1.0 | Clonées et converties localement par build-rules |
| EVTX-ATTACK-SAMPLES | sbousseaden | GPL-3.0 | Copiés dans samples/EVTX-ATTACK-SAMPLES avec leur fichier LICENSE.GPL |
| python-evtx | Willi Ballenthin | Apache 2.0 | Inclus dans les échantillons, dossier EVTX_ATT&CK_Metadata/Evtx |

Les sources intégrées dans rules_windows_all sont sous licences DRL 1.1, GPL-3.0, Apache 2.0, MIT ou CC0 1.0. La liste complète se trouve dans le dépôt Zircolite-Rules-v2 (docs/sources.md).

Le fichier rules_ultimate.json n'est pas versionné : chacun le génère sur sa machine avec build-rules, ce qui évite de redistribuer ces règles.
