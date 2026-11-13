# Plan 002 — API publique des équipements consommateurs

ADR : [ADR-002](../ADR/002-api-consommateurs.md) (Accepté le 2026-11-13).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| C1 | `API.registerConsumer`, `API.consumer` : validation, registre par sprite, scellé | Terminée (2026-11-13) | ADR accepté | D01, D04 | S | — |
| C2 | Demande et consommation : objets inscrits listés et facturés, valeur inscrite prioritaire | Terminée (2026-11-13) | C1 | D02 | M | C3 |
| C3 | Famille `consumer`, coupure par circuits et fournisseur, `API.consumerPowered` | Terminée (2026-11-13) | C1 | D03, D04 | M | C2 |
| C4 | Extended : adaptateurs estimés sans double compte | Terminée (2026-11-13) | C1 | D05 | S | C2, C3 |
| C5 | Données de l'appareil dans le logiciel de gestion (écran Live Wire et Computer Mod) | Terminée (2026-11-13) | C2 | D07 | M | C4 |
| C7 | Résumé par réseau (`summary`), onglet Équipements | Terminée (2026-11-13) | C5 | D08 | S | — |
| C6 | Révision 6, spécifications, wiki développeurs EN/FR, D-66, passage en jeu SP et MP | À valider (passage en jeu SP et MP non fait) | C2 à C5 | D06 | S | — |

## Fiches

Chaque fiche reçoit, à la clôture : fichiers touchés, commande de la suite hors jeu et sa ligne verte
(`python -B -m unittest discover -s tests` : nombre de tests passés, zéro échec), sortie de `tools/check_mod.py`, commit.

### C1 — Inscription

Fichiers : `shared/LiveWire/LW_API.lua`, nouveau `shared/LiveWire/LW_Consumers.lua` (registre, une responsabilité).
Tests rouges (`tests/test_api_consumers.py`) : définition valide acceptée ; sprite, `powerConsumption`, catégorie ou circuit
invalides refusés ; doublon d'id et de sprite refusés ; inscription après scellé refusée ; mutation de la définition par
l'appelant sans effet ; `API.consumer` rend l'id ou `nil`, `couldBePowered` respecté.


Preuve du vert (C1, après refactor) : `python -B -m unittest discover -s tests` → `Ran 635 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → 28 tests, `OK` ; `python tools/check_mod.py` → `OK`. Non commité (commit sur demande de l'utilisateur). Tests : classe `Registration` (9).

### C2 — Facturation

Fichiers : `server/LiveWire/LW_Demand.lua` (`collect`), `shared/LiveWire/LW_Consumption.lua`. Tests rouges : un objet
inscrit sans consommation moteur est listé et facturé avec `PowerScale` et le profil ; valeur inscrite prioritaire sur
le moteur ; 0 W à l'arrêt ; réseau public listé non facturé ; catégorie dans la ventilation.


Preuve du vert (C2, après refactor) : `python -B -m unittest discover -s tests` → `Ran 635 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → 28 tests, `OK` ; `python tools/check_mod.py` → `OK`. Non commité (commit sur demande de l'utilisateur). Tests : classe `Billing` (7) ; `test_remaining.py` (double de sprite complété par `getName`).

### C3 — Coupure et état

Fichiers : `shared/LiveWire/LW_ApplianceFamilies.lua`, `LW_Appliances.lua`, `server/LiveWire/LW_Circuits.lua`,
`LW_API.lua`. Tests rouges : circuit `equipment` ouvert ⇒ objet coupé, 0 W, `consumerPowered` faux ; circuit `light`
respecté ; aucune méthode d'état de l'objet appelée ; côté client, état lu depuis la ModData synchronisée.


Preuve du vert (C3, après refactor) : `python -B -m unittest discover -s tests` → `Ran 635 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → 28 tests, `OK` ; `python tools/check_mod.py` → `OK`. Non commité (commit sur demande de l'utilisateur). Tests : classe `CutAndPowerState` (7).

### C4 — Extended

Fichier : `shared/LiveWireExtended/LWX_CircuitProvider.lua`. Test rouge : un point MTIR reconnu par un consommateur
inscrit n'est plus compté dans `extraWatts`.


Preuve du vert (C4, après refactor) : `python -B -m unittest discover -s tests` → `Ran 635 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → 28 tests, `OK` ; `python tools/check_mod.py` → `OK`. Non commité (commit sur demande de l'utilisateur). Test : `test_extended_mod_adapters.py`, `test_registered_consumer_is_not_billed_twice`.

### C5 — Affichage dans le logiciel

Fichiers : `shared/LiveWire/LW_Consumers.lua` (copie bornée de `display`), `server/LiveWire/LW_Demand.lua`
(`Demand.consumers`), `client/LiveWire/LW_SoftwareApp.lua` (onglet « Consommateurs »). Tests rouges : réponse valide
copiée dans la ligne de l'instantané ; réponse trop longue, mal typée ou absente ignorée ; `display` jamais appelée
hors instantané ni pour un objet non inscrit ; le client affiche le nom traduit et les lignes en retrait.


Preuve du vert (C5, après refactor) : `python -B -m unittest discover -s tests` → `Ran 635 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → 28 tests, `OK` ; `python tools/check_mod.py` → `OK`. Non commité (commit sur demande de l'utilisateur). Tests : classe `SoftwareDisplay` (5).

### C7 — Résumé par réseau

Fichiers : `shared/LiveWire/LW_Consumers.lua` (`summaries`, copie bornée commune avec `display`), `server/LiveWire/LW_Demand.lua` (`eachServed`, `eachServedOfGrid`), `LW_Simulation.lua` (`snap.consumerSummaries`), `client/LiveWire/LW_SoftwareApp.lua` (`summaryRows`, cache par instantané, onglet Équipements). Tests : classe `NetworkSummary` (4).

Preuve du vert : `python -B -m unittest discover -s tests` → `Ran 639 tests`, `OK (skipped=4)` ; `python tests/test_api_consumers.py` → `Ran 32 tests`, `OK` ; `python tools/check_mod.py` → `OK`. Non commité.

### C6 — Version, documentation, en jeu

Fichiers : `LW_API.lua` (révision), `docs/specifications-techniques.md`, `docs/wiki/{en,fr}/15-developers.md`,
`docs/decisions.md`. Passage `pzdev sp` puis `mp` avec un consommateur de test (mod de banc DEV-ONLY) : facture,
coupure par le panneau, `consumerPowered` côté client. Preuves : code de sortie, ligne `summary`, dossier `runs/...`.

Fait : `API.revision = 6` ; contrat complet dans l'ADR ; `specifications-techniques.md` (section révision 6) ; wiki `en/15-developers.md` et `fr/15-developpeurs.md` (tableaux et exemple 7) ; D-66. Reste : le passage en jeu, qui demande un petit mod de banc DEV-ONLY déclarant un consommateur.
