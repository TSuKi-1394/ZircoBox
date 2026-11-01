# ZircoBox : Zircolite dans Docker, avec un ruleset élargi

Ce dépôt permet de lancer [Zircolite](https://github.com/wagga40/Zircolite) sur des journaux d'événements Windows (.evtx) sans rien installer d'autre que Docker. Il ajoute un ruleset fusionné, `rules_ultimate`, et des échantillons d'attaques pour tester.

Zircolite analyse des journaux avec des règles Sigma et produit la liste des événements suspects. J'ai écrit ce projet en suivant l'article d'IT-Connect sur l'outil, puis j'ai cherché quel ruleset détectait le plus de choses.

## Ce qu'il faut

- Docker (Docker Desktop sous Windows ou macOS, Docker Engine sous Linux)
- PowerShell sous Windows (celui fourni avec Windows suffit), ou bash sous Linux et WSL
- Une connexion Internet au premier lancement, pour construire les images

## Premier essai

Sous Windows :

    git clone https://github.com/TSuKi-1394/ZircoBox.git
    cd ZircoBox
    .\zirco.ps1 -Logs .\samples\EVTX-ATTACK-SAMPLES -Rules rules_ultimate -Output .\local\resultats -Package

Sous Linux ou WSL :

    ./zirco.sh -l ./samples/EVTX-ATTACK-SAMPLES -r rules_ultimate -o ./local/resultats -p

Au premier lancement, deux images Docker sont construites et le ruleset est généré. Comptez quelques minutes. Les lancements suivants prennent de l'ordre de 30 secondes sur les échantillons fournis.

Dans le dossier de sortie, vous trouvez :

- `detected_events.json`, la liste des règles déclenchées avec les événements concernés
- `zircolite-package-XXXX.zip`, un rapport web. Décompressez-le et ouvrez `index.html` dans un navigateur.

## Analyser vos propres journaux

Exportez un journal depuis un PowerShell lancé en administrateur :

    wevtutil epl Security .\local\Security.evtx

Puis :

    .\zirco.ps1 -Logs .\local\Security.evtx -Rules rules_ultimate -Output .\local\resultats -Package

Le dossier `local` est ignoré par git : vos journaux et vos résultats n'y sont jamais publiés.

Les journaux Sysmon donnent les meilleurs résultats. Sans Sysmon, une grande partie des règles ne peut rien détecter.

## Options

| Option | Rôle |
|---|---|
| `-Logs` | Un fichier .evtx ou un dossier de fichiers |
| `-Rules` | Un ou plusieurs rulesets, par exemple `rules_ultimate` ou `rules_windows_all` |
| `-Output` | Dossier de sortie, `.\zircolite-output` par défaut |
| `-Package` | Génère aussi le rapport web |
| `-ListRules` | Liste les rulesets fournis par Zircolite |
| `-Rebuild` | Reconstruit l'image sans cache |
| `-Extra` | Options passées telles quelles à Zircolite |

Sous bash, les options équivalentes sont `-l`, `-r`, `-o`, `-p`, `--list-rules`, `--rebuild`, et tout ce qui suit `--` est transmis à Zircolite.

## Réduire le bruit

Le ruleset est large, donc il fait du bruit. Deux options utiles :

    .\zirco.ps1 -Logs .\local\Security.evtx -Rules rules_ultimate -Extra "--min-level","low"
    .\zirco.ps1 -Logs .\local\Security.evtx -Rules rules_ultimate -Extra "-R","Credential Manager"

La première retire les règles de niveau informationnel, la seconde ignore les règles dont le titre contient le texte donné. Plus de détails dans `docs/resultats.md`.

## Mettre à jour les règles

    .\zirco.ps1 -Rebuild
    .\build-rules.ps1 -Update

Dans cet ordre, car `rules_ultimate` reprend `rules_windows_all` depuis l'image de Zircolite.

## Pour aller plus loin

- `docs/fonctionnement.md` : rôle de chaque fichier et construction du ruleset
- `docs/resultats.md` : mesures faites sur les échantillons et sur un poste sain
- `docs/depannage.md` : les erreurs rencontrées et leur correction
- `NOTICE.md` : crédits et licences

Le dossier `samples/EVTX-ATTACK-SAMPLES` est une copie du dépôt de sbousseaden, sous GPL-3.0.

## Auteur

TSuKi-1394. Code publié sous GPL-3.0, voir `LICENSE` et `NOTICE.md`.
