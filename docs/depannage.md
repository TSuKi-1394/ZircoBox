# Dépannage

## Le script .ps1 n'est pas signé numériquement

La stratégie d'exécution de Windows bloque le script. Cela arrive surtout sur un lecteur réseau ou synchronisé. Autorisez-le pour la fenêtre PowerShell en cours, sans changer le réglage de la machine :

    Set-ExecutionPolicy -Scope Process Bypass

## Docker est introuvable ou ne répond pas

Installez Docker Desktop (Windows, macOS) ou Docker Engine (Linux). Sous Windows, lancez Docker Desktop et attendez que l'icône indique qu'il est prêt avant de relancer le script.

## La construction de l'image échoue avec `ResolutionImpossible`

Le message cite `pysigma-pipeline-sysmon` et `pysigma`. C'est un conflit de versions dans Zircolite 4.7.0, déjà contourné dans le Dockerfile de ce dépôt. Si vous le voyez, vous utilisez probablement un Dockerfile modifié ou une autre version de Zircolite. Voir la fin de `docs/fonctionnement.md`.

## `Ruleset path does not exist: rules/rules_windows_sysmon_full.json`

Les noms de rulesets ont changé dans Zircolite 4.x. L'article d'IT-Connect et beaucoup de tutoriels utilisent les anciens noms (`rules_windows_sysmon_full`, `rules_windows_generic_high`). Pour voir les noms actuels :

    .\zirco.ps1 -ListRules

Les plus utiles sont `rules_windows_merged`, `rules_windows_sysmon`, `rules_windows_generic` et `rules_windows_all`.

## Il n'y a pas de zip du rapport web

Vérifiez que vous avez passé `-Package`. Le script ajoute `--package-dir /output` pour que le zip sorte du conteneur. Si vous lancez Zircolite autrement, il faut cette option.

Pour ouvrir le rapport, décompressez le zip et ouvrez `index.html` :

    Expand-Archive .\local\resultats\zircolite-package-*.zip -DestinationPath .\local\resultats\web -Force
    Start-Process (Get-ChildItem .\local\resultats\web -Recurse -Filter index.html | Select-Object -First 1).FullName

## La génération de rules_ultimate affiche des erreurs

Quelques messages comme `règle invalide écartée`, `yaml.scanner.ScannerError` ou `'str' object has no attribute 'get'` sont normaux : certaines règles de mdecrevoisier ne sont pas lisibles par sigma-cli. Le script bascule sur une conversion fichier par fichier et continue. La génération a réussi si la dernière ligne indique le nombre total de règles et que `rules-custom/rules_ultimate.json` existe.

## `14 correlation rule(s) cannot run`

Ce message est attendu. Il concerne 14 règles de corrélation de mdecrevoisier, converties avec sigma-cli : Zircolite les charge sans les exécuter. L'analyse continue normalement avec les autres règles. Voir les limites dans `docs/resultats.md`.

## Le journal Security ne s'exporte pas

`wevtutil epl Security` demande un PowerShell lancé en administrateur.

## Un script .sh échoue avec `bad interpreter` ou `\r`

Le fichier a été converti en fins de ligne Windows. Le dépôt contient un `.gitattributes` qui l'évite. Si cela arrive quand même, lancez `git config core.autocrlf false`, puis supprimez et reclonez le dépôt.

## Les règles ne détectent rien

Zircolite ne détecte que ce que les journaux contiennent. Sans Sysmon, les règles sur la création de processus, les chargements de DLL ou l'accès à LSASS n'ont rien à analyser. Vérifiez aussi que vous passez bien des fichiers .evtx et non des journaux d'un autre format.
