# Live Wire — documentation

Version **1.6.2** publiée le 2026-10-27 : portée verticale des câbles configurable (`LinkVerticalRange`, 0–10 étages, défaut 3). Les corrections de la 1.6.1 et les fonctionnalités de la 1.6.0 sont conservées. Dépôt poussé, wiki synchronisé et publication Steam confirmée dans les dix langues. Voir le [changelog](../CHANGELOG.md).

Live Wire (`batman_LiveWire`, Project Zomboid Build 42.21) fait de la compétence Électricité un métier : panneaux solaires, éoliennes et roues à aubes, batteries en powerbank, onduleur qui alimente la maison et pompe à eau.

## Documents

| Document | Rôle |
|---|---|
| [`architecture.md`](architecture.md) | Architecture logicielle : mécanisme d'alimentation (ancres), modules, modèle de données, boucle de simulation, protocole, persistance, risques |
| [`specifications-fonctionnelles.md`](specifications-fonctionnelles.md) | Ce que fait le mod pour le joueur et l'administrateur, fonctionnalités F01 à F32 |
| [`specifications-techniques.md`](specifications-techniques.md) | Contrats précis : objets, appareils, commandes réseau, ModData, options sandbox, traductions, compatibilités |
| [`developpement.md`](developpement.md) | Contraintes de développement du projet : périmètre (deux mods), architecture à préserver, création indépendante, outils, dépôt |
| [`decisions.md`](decisions.md) | Exigences de l'utilisateur et journal des décisions validées (D-n) |
| [`ameliorations-et-idees.md`](ameliorations-et-idees.md) | Améliorations de code et idées de fonctionnalités (propositions et suivi des correctifs autorisés) |
| [`wiki/`](wiki/) | Source du wiki GitHub : [anglais](wiki/en/Home.md), [français](wiki/fr/Home.md) |
| [`images/`](images/) | Images de la documentation, du README, du wiki et de la page Steam |
| [`annexes/`](annexes/) | Références de conception, notes moteur et validation |

## Wiki

| Page | English | Français |
|---|---|---|
| Accueil | [Home](wiki/en/Home.md) | [Accueil](wiki/fr/Home.md) |
| Premiers pas | [Getting started](wiki/en/01-getting-started.md) | [Premiers pas](wiki/fr/01-premiers-pas.md) |
| Équipements | [Equipment](wiki/en/02-equipment.md) | [Équipements](wiki/fr/02-equipements.md) |
| Câblage et réseau | [Wiring](wiki/en/03-wiring.md) | [Raccordement](wiki/fr/03-raccordement.md) |
| Production | [Production and calculations](wiki/en/04-production-and-calculations.md) | [Production et calculs](wiki/fr/04-production-et-calculs.md) |
| Écran et logiciel | [Inverter screen and software](wiki/en/05-inverter-screen-and-software.md) | [Écran et logiciel](wiki/fr/05-ecran-et-logiciel.md) |
| Équipements optionnels | [Optional equipment](wiki/en/06-optional-equipment.md) | [Équipements optionnels](wiki/fr/06-equipements-optionnels.md) |
| Pompe à eau | [Water pump](wiki/en/07-water-pump.md) | [Pompe à eau](wiki/fr/07-pompe-a-eau.md) |
| Recettes | [Recipes](wiki/en/08-recipes.md) | [Recettes](wiki/fr/08-recettes.md) |
| Butin | [Loot tables](wiki/en/09-loot-tables.md) | [Tables de butin](wiki/fr/09-tables-de-butin.md) |
| Compétence Électricité | [Electrical skill and maintenance](wiki/en/10-electrical-skill-and-maintenance.md) | [Compétence Électricité et entretien](wiki/fr/10-competence-electricite-et-entretien.md) |
| Options | [Sandbox options](wiki/en/11-sandbox-options.md) | [Options sandbox](wiki/fr/11-options-sandbox.md) |
| Multijoueur | [Multiplayer](wiki/en/12-multiplayer.md) | [Multijoueur](wiki/fr/12-multijoueur.md) |
| FAQ | [FAQ](wiki/en/13-faq.md) | [FAQ](wiki/fr/13-faq.md) |

`_Sidebar.md` et `_Footer.md` sont les barres latérale et de pied du wiki GitHub. `_tables.md` (par langue) est généré par `tools/make_doc_tables.py` : tableaux de recettes et de butin à recopier dans le README et les pages 08 et 09.

## Images

| Dossier | Contenu | Producteur |
|---|---|---|
| [`images/diagrams/`](images/diagrams/) | Schéma de fonctionnement, planche des équipements, courbes de production, livre de recettes, par langue (`<nom>_<langue>.png`) | `tools/make_doc_images.py` |
| [`images/screenshots/`](images/screenshots/) | Captures en jeu (README, wiki, page Steam) et rendus Project Viewpoint | Manuel |
| [`images/icons/`](images/icons/) | Icônes d'objets ; `tiles/` : sprites des tuiles du mod | Extraites du jeu et du pack du mod |

Les pages Steam (`README.steam*`, `workshop.txt`) et les README de la racine chargent ces images par URL `raw.githubusercontent.com/.../main/docs/images/...` : elles n'apparaissent qu'après la poussée sur `main`.

## Annexes

| Document | Rôle |
|---|---|
| [`annexes/recherches/notes-moteur.md`](annexes/recherches/notes-moteur.md) | 56 notes moteur sourcées (NM-n), avec Build, date et niveau de validation |
| [`annexes/conception/choix-et-extensions.md`](annexes/conception/choix-et-extensions.md) | Motivations de la pompe et du couplage ; propositions et questions ouvertes |
| [`annexes/tests/protocole-tests.md`](annexes/tests/protocole-tests.md) | Préparation, commandes de reproduction et contrôles SP/MP |
| [`annexes/tests/validation.md`](annexes/tests/validation.md) | Bilan des campagnes du 2026-10-24, résultats, conditions et limites |

Campagne IXX locale : [plan par lots](annexes/plans/campagne-ixx.md), [circuits et adaptateurs moteur](annexes/recherches/circuits-42-21.md), [contrats API v1](specifications-techniques.md#api-publique-v1).

Complément d'ergonomie : [clic direct, LCD powerbank, raccordements et teintes](annexes/plans/acces-equipements.md).

Stockage : [powerbanks superposées](annexes/plans/powerbanks-superposees.md).

Butin : [fréquence et lieux des équipements](annexes/plans/butin-equipements.md).

Sources : [fabrication de l’éolienne, composants et pose niveau 2](annexes/plans/fabrication-eolienne-et-composants.md).
