# Plan 004 — Consommateurs d'autres mods reliés par fil à un onduleur

ADR : [ADR-004](../ADR/004-consommateurs-relies-par-fil.md) (Accepté le 2026-11-20).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| L1 | Contrat `link`, révision 9, table des sortes de lien dans `LW_Install`, `checkLink` et `objectsInRange` | À valider (passage en jeu L6) | ADR accepté | D01, D02, D06 | M | — |
| L2 | Registre (rôle `consumer`, tables de membres et d'oubli), action de branchement et commande de débranchement, ramassage qui rend les fils | À valider (passage en jeu L6) | L1 | D02, D03, D06 | M | — |
| L3 | Simulation : courant, facturation chargé/déchargé, pas de double facturation, circuits de l'onduleur relié, état synchronisé | À valider (passage en jeu L6) | L2 | D04 | M | — |
| L4 | API `consumerPowered`, `consumerLink`, `consumerLinkPowered` | À valider (passage en jeu L6) | L3 | D05 | S | — |
| L5 | Client : menus, fenêtre « Connexions », noms | À valider (passage en jeu L6) | L2 | D02 | S | L3, L4 |
| L6 | Spécifications techniques, wiki développeurs EN/FR, CHANGELOG ; passage en jeu par l'utilisateur avec LiveWater | À faire | L1 à L5 | toutes | S | — |

## Fiches

Chaque fiche reçoit, à la clôture : fichiers touchés, `python -B -m unittest discover -s tests` (nombre de tests
passés, zéro échec), `python -B tools/check_mod.py` → `OK`.

### L1 — Contrat et sortes de lien

Fichiers : `shared/LiveWire/LW_Consumers.lua` (champ `link` validé, `Consumers.get`, `Consumers.linkable`,
`Consumers.displayName`), `LW_Defs.lua` (`Defs.LINK_KEY = "LiveWireLink"`), `LW_Install.lua` (table
`Install.LINK_KINDS` remplie par `Install.addLinkKind` : `backup`, `computer`, `consumer` ; `linkKind`, `markOf`,
`vanillaMark`, `linkName`, niveau de `checkLink` lus dans la table ; `objectsInRange` inchangé), `LW_API.lua`
(révision 9, champ `link` documenté). Tests : classe `Contract` (7) ; `test_api_consumers.py` et `test_api_submods.py`
(révision 9).

Preuve du vert (L1 à L5, après refactor, 2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 708 tests`, `OK (skipped=4)` ; `python -B -m unittest discover -s tests -p test_linked_consumers.py` → `Ran 32 tests`, `OK` ; `python -B tools/check_mod.py` → `OK`. Tests rouges d'abord : les 32 tests de `tests/test_linked_consumers.py` échouaient tous sur le code d'avant (7 échecs, 25 erreurs). Non commité (commit sur demande de l'utilisateur). Aucun passage en jeu : L6.

### L2 — Registre, branchement, ramassage

Fichiers : nouveau `server/LiveWire/LW_LinkedConsumers.lua` (`register`, `forget`, `find`, `deviceOf`, `gridOf`,
`onPickedUp`, `clearStale`), `LW_Registry.lua` (`MEMBER_ROLES` avec `consumer`, `forgetVanilla` et `dropGrid` par la
table des sortes, `nameKey` pour le journal), `TimedActions/LW_TimedActions.lua` (`linkVanilla` par la table : `single`,
`service`), `LW_Placement.lua` (ramassage hors rotation → `LINKED_PICKED_UP`), `LW_EventBus.lua` (événement
`LINKED_PICKED_UP`, abonné `SQUARE_CHANGED`), `LW_Events.lua` (`Registry.nameKey`). Commande `unlink` inchangée.
Tests : classe `Linking` (8).

Preuve du vert (L1 à L5, après refactor, 2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 708 tests`, `OK (skipped=4)` ; `python -B -m unittest discover -s tests -p test_linked_consumers.py` → `Ran 32 tests`, `OK` ; `python -B tools/check_mod.py` → `OK`. Tests rouges d'abord : les 32 tests de `tests/test_linked_consumers.py` échouaient tous sur le code d'avant (7 échecs, 25 erreurs). Non commité (commit sur demande de l'utilisateur). Aucun passage en jeu : L6.

### L3 — Simulation

Fichiers : `server/LiveWire/LW_Inverters.lua` (`Inverters.supplies`, règle unique des appareils reliés),
`LW_Pump.lua`, `LW_Devices.lua`, `LW_DeviceView.lua` (même règle, sans copie), `LW_LinkedConsumers.lua` (`powered`,
`demandW`, `refreshMarks`, `eachLoaded`), `LW_Simulation.lua` (`syncLinkedVanilla` par la table des sortes,
`addLinkedDemand`, `refreshMarks`, `snapshot.demand`, `appliances` et autonomie avec `grid.linkedW`/`linkedApps`),
`LW_Demand.lua` (objet relié ignoré par `measure`, listé par `consumers`, donné à `eachServedOfGrid`),
`LW_Circuits.lua` (`owner` : réseau relié), `LW_Commands.lua` (test de surcharge du réarmement avec `linkedW`).
Tests : classe `Simulation` (10).

Preuve du vert (L1 à L5, après refactor, 2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 708 tests`, `OK (skipped=4)` ; `python -B -m unittest discover -s tests -p test_linked_consumers.py` → `Ran 32 tests`, `OK` ; `python -B tools/check_mod.py` → `OK`. Tests rouges d'abord : les 32 tests de `tests/test_linked_consumers.py` échouaient tous sur le code d'avant (7 échecs, 25 erreurs). Non commité (commit sur demande de l'utilisateur). Aucun passage en jeu : L6.

### L4 — API

Fichier : `shared/LiveWire/LW_API.lua` (`consumerPowered` suit le lien : registre sur l'autorité, `pw` sur un client ;
`consumerLink`, `consumerLinkPowered`). Tests : classe `Api` (4).

Preuve du vert (L1 à L5, après refactor, 2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 708 tests`, `OK (skipped=4)` ; `python -B -m unittest discover -s tests -p test_linked_consumers.py` → `Ran 32 tests`, `OK` ; `python -B tools/check_mod.py` → `OK`. Tests rouges d'abord : les 32 tests de `tests/test_linked_consumers.py` échouaient tous sur le code d'avant (7 échecs, 25 erreurs). Non commité (commit sur demande de l'utilisateur). Aucun passage en jeu : L6.

### L5 — Client

Fichiers : `client/LiveWire/LW_ContextMenu.lua` (`objectName` et titre du sous-menu par `Install.linkName`),
`LW_ConnectionPanel.lua` (nom par `Install.linkName`) ; menus et fenêtre déjà génériques sur les sortes de lien
(`linkKind`, `vanillaMark`). Aucune clé de traduction nouvelle. Tests : classe `ClientNames` (3) ; menus non testés
hors jeu.

Preuve du vert (L1 à L5, après refactor, 2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 708 tests`, `OK (skipped=4)` ; `python -B -m unittest discover -s tests -p test_linked_consumers.py` → `Ran 32 tests`, `OK` ; `python -B tools/check_mod.py` → `OK`. Tests rouges d'abord : les 32 tests de `tests/test_linked_consumers.py` échouaient tous sur le code d'avant (7 échecs, 25 erreurs). Non commité (commit sur demande de l'utilisateur). Aucun passage en jeu : L6.

### L6 — Documentation et passage en jeu

Documentation faite le 2026-11-20 : `docs/specifications-techniques.md` (clé `LiveWireLink`, rôle `consumer`, révision 9, section « Consommateurs reliés par fil »), `docs/wiki/en/15-developers.md` et `docs/wiki/fr/15-developpeurs.md` (champ `link`, `consumerLink`, `consumerLinkPowered`), `CHANGELOG.md` (« Unreleased »). Reste : passage en jeu SP et MP avec LiveWater.
