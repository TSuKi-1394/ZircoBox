# Résultats

Mesures faites avec Zircolite 4.7.0.

## Couverture sur les échantillons d'attaques

Jeu de test : 278 fichiers .evtx du dépôt EVTX-ATTACK-SAMPLES, lancés avec `-Package`. Le tableau donne le nombre de règles distinctes qui se sont déclenchées.

| Ruleset | Règles déclenchées |
|---|---|
| `rules_windows_merged` (défaut de Zircolite) | 385 |
| Ma première conversion SigmaHQ et mdecrevoisier | 406 |
| `rules_windows_all` | 671 |
| `rules_ultimate` | 686 |

Une analyse complète prend environ 23 secondes.

Ma première conversion ne faisait qu'à peine mieux que le défaut. `rules_windows_all` apporte beaucoup plus, parce qu'il réunit treize sources. `rules_ultimate` ajoute 15 règles à `rules_windows_all`, soit 10 titres différents, toutes issues de mdecrevoisier :

- mouvement latéral avec Impacket (DCOMexec via MMC, WMIexec, accès au partage administratif SMB)
- vol d'identifiants (Procdump renommé qui dumpe LSASS, dump des identifiants d'un pool d'applications IIS)
- persistance par détournement de Sticky Keys, en trois variantes
- activation du shadow RDP par le registre
- module WMI chargé par un processus suspect

Le gain est modeste. Si vous préférez ne rien reconstruire, `rules_windows_all` convient très bien.

## Faux positifs sur un poste sain

Les échantillons ne contiennent que des attaques, ils ne disent rien sur le bruit. J'ai donc exporté le journal Security d'un poste de travail ordinaire et lancé `rules_ultimate` dessus : 35 règles se sont déclenchées.

| Catégorie | Règles | Remarque |
|---|---|---|
| Niveau informationnel | 21 | Règles de chronologie venant de Hayabusa (ouvertures et fermetures de session, tâches planifiées). Ce sont des repères, pas des alertes |
| Network or RDP Logon Outside Service and Admin Accounts | 1 | Plusieurs milliers d'événements |
| Credential Manager Accessed et Enumerated | 2 | Plusieurs milliers d'événements |
| LAPSUS$ T1199 | 1 | Règle très large |
| Le reste | 10 | À regarder une par une |

Pour une chasse aux menaces, je retire les règles informationnelles et les trois sources de bruit :

    .\zirco.ps1 -Logs .\local\Security.evtx -Rules rules_ultimate -Extra "--min-level","low","-R","Network or RDP Logon Outside Service","-R","Credential Manager","-R","LAPSUS"

Pour reconstituer l'historique d'une machine après un incident, gardez au contraire les règles informationnelles, elles donnent la chronologie des connexions.

Ces choix valent pour mon poste. Chez vous, d'autres règles feront du bruit. L'option `--profile-rules` de Zircolite indique les règles les plus lentes, et le rapport web permet de voir lesquelles reviennent le plus.

## Limites

- Les règles qui se déclenchent sur les échantillons ne prouvent pas qu'elles détecteront la même attaque sur votre réseau.
- Je n'ai testé que le journal Security d'un poste sain. Les règles Sysmon n'ont pas été éprouvées sur un poste sans attaque.
- Les sources lolrmm et hatchepsoute sont signalées comme bruyantes par leurs auteurs.
- 14 règles de corrélation de mdecrevoisier ne s'exécutent pas, notamment des détections de force brute et d'énumération par comptage (Kerbrute, Kerberoast, SharpHound). Elles ne comptent pas dans les résultats ci-dessus.
