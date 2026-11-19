# Plan 003 — La pompe à eau de Live Wire s'efface devant LiveWater

ADR : [ADR-003](../../ADR/termines/003-pompe-a-eau-et-livewater.md) (Accepté le 2026-11-19).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| P1 | `Compat.liveWater`, `Recipes.waterPumpAvailable`, `OnTest` et `OnAddToMenu` de `LWMakeWaterPump`, tests | Terminée (2026-11-19) | ADR accepté | D01, D02, D03 | S | — |
| P2 | Descriptions Steam (11 langues), wiki, spécifications, CHANGELOG | Terminée (2026-11-19) | P1 | D04 | S | — |
| P3 | Passage en jeu par l'utilisateur : avec et sans LiveWater | Terminée (2026-11-19) | P1 | D01, D02 | S | — |

## Fiches

### P1 — Code

Fichiers : `shared/LiveWire/LW_Compat.lua`, `shared/LiveWire/LW_Recipes.lua`, `scripts/LiveWire_recipes.txt`,
nouveau `tests/test_water_pump_livewater.py` (8 tests : sans LiveWater la recette est proposée et fabricable ; avec
LiveWater elle est masquée, « tout afficher » compris, et refusée ; liste des mods lue une fois ; identifiant voisin
ignoré ; crochets présents dans le script, filtre du menu à nom global simple ; démontage inchangé).

Preuve du vert : `python -B tests/test_water_pump_livewater.py` → `Ran 8 tests`, `OK` ;
`python -B -m unittest discover -s tests` → `Ran 676 tests`, `OK (skipped=4)` ; `python -B tools/check_mod.py` → `OK`.
Non commité (commit sur demande de l'utilisateur).

### P2 — Documentation

Descriptions Steam (11 langues, phrase « passera bientôt dans son propre mod » remplacée) et `workshop.txt` ; tailles
avec le bloc d'identifiants sous 8 000 octets (anglais 7 885 pour 7 886 permis : plus aucune marge) ; wiki EN/FR
07 (section « With LiveWater » / « Avec LiveWater »), `specifications-fonctionnelles.md` § 10.1, CHANGELOG
(Unreleased), note moteur 69 (`OnAddToMenu`).

Preuve du vert : `pz_workshop_project.validate` → `[]` ; suite complète ci-dessus.

### P3 — Passage en jeu

Protocole court, par l'utilisateur :
1. Partie avec Live Wire seul : la recette « pompe à eau » est dans le menu d'artisanat et se fabrique.
2. Même partie avec LiveWater ajouté : la recette a disparu (aussi avec « tout afficher ») ; une pompe Live Wire déjà
   posée continue de remplir les éviers ; elle se ramasse et se démonte.

Résultat : confirmé en jeu par l'utilisateur le 2026-11-19 (« j'ai testé, ça fonctionne ») ; passage manuel, sans
dossier `runs/`.
