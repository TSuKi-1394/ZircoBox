# Fonctionnement

## Les fichiers

| Fichier | Rôle |
|---|---|
| `zirco.ps1`, `zirco.sh` | Lancent une analyse : montent les journaux en lecture seule, le dossier de sortie et le dossier `rules-custom` |
| `build-rules.ps1`, `build-rules.sh` | Lancent la fabrication du ruleset depuis votre machine |
| `docker/zircolite/` | Image `zircolite-local` : Dockerfile (Python, Zircolite 4.7.0 par défaut et ses dépendances) et `entrypoint.sh` qui lance Zircolite |
| `docker/rules-builder/` | Image `zircolite-rules-builder` : Dockerfile, `entrypoint.sh` (convertit les règles et fusionne) et `merge.py` (fusion, suppression des doublons) |
| `samples/EVTX-ATTACK-SAMPLES/` | Échantillons d'attaques pour tester |
| `rules-custom/` | Contient `rules_ultimate.json` une fois généré. Ignoré par git |
| `local/` | Vos journaux et vos résultats. Ignoré par git, jamais publié |
| `docs/` | Cette documentation |

Les scripts à la racine s'exécutent sur votre machine, ceux de `docker/` s'exécutent dans les conteneurs.

## Une analyse

1. `zirco` vérifie que Docker répond et construit l'image `zircolite-local` si elle manque.
2. Si le ruleset demandé est `rules_ultimate` et qu'il n'existe pas encore, `build-rules` est lancé.
3. Le dossier de journaux est monté sur `/logs` en lecture seule, la sortie sur `/output`, et `rules-custom` sur `/rules-custom`.
4. Zircolite écrit `detected_events.json` et, avec `-Package`, le zip du rapport web dans `/output`. L'option `--package-dir /output` est nécessaire : sans elle, Zircolite écrit le zip dans le conteneur et il disparaît à la fin.

Un ruleset présent dans `rules-custom` est prioritaire sur un ruleset de l'image portant le même nom.

## Construction de rules_ultimate

Pourquoi ne pas se contenter de `rules_windows_all` ? Parce que mes premiers essais avec une conversion maison de SigmaHQ donnaient peu de plus que le ruleset par défaut, alors que `rules_windows_all` réunit treize sources. J'ai donc gardé `rules_windows_all` comme base et ajouté ce que ma conversion apporte en plus.

Étapes de `docker/rules-builder/entrypoint.sh` :

1. Conversion des règles Windows de SigmaHQ (dossiers `rules/windows`, `rules-emerging-threats`, `rules-threat-hunting/windows`, `rules-dfir/windows`) avec `sigma convert` et le backend SQLite, en deux variantes : Sysmon et journaux Windows natifs.
2. Même chose pour les règles de mdecrevoisier. Ses fichiers ont l'extension `.yaml` que sigma-cli ne lit pas, ils sont donc copiés en `.yml` avant la conversion.
3. Quand un lot de règles échoue à cause d'une règle mal formée, le script retire cette règle et recommence. Si le lot échoue encore, il convertit les fichiers un par un.
4. `merge.py` fusionne le tout. `rules_windows_all` passe en premier et reste intact. Une règle issue d'une conversion n'est ajoutée que si son identifiant n'existe pas déjà.

Résultat chez moi : 7362 règles dans `rules_windows_all`, 502 ajoutées, 7864 au total.

Au lancement, Zircolite en charge un peu moins (7542), car 324 entrées ont le même SQL qu'une autre et ne détectent rien de plus.

## Pourquoi un conflit de dépendances dans le Dockerfile

Zircolite 4.7.0 demande `pysigma` version 2 ou plus, alors que `pysigma-pipeline-sysmon` 2.0.0 déclare `pysigma` inférieur à 2. pip refuse d'installer l'ensemble. Le Dockerfile installe donc d'abord les dépendances sans ces deux paquets, puis les ajoute avec `--no-deps`. Ils ne servent qu'à convertir des règles Sigma, ce que ce projet ne fait pas à l'exécution.
