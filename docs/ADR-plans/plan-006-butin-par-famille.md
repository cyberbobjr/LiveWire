# Plan 006 — Butin configurable par famille d'équipement

ADR : [ADR-006](../ADR/006-butin-par-famille.md) (Accepté le 2026-11-24).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| B1 | Options sandbox, configuration et distributions, tests hors jeu | Terminée (2026-11-24) | ADR accepté | D01-D05 | M | — |
| B2 | Traductions des onze langues | Terminée (2026-11-24) | B1 | D02, D06 | S | — |
| B3 | Documentation, CHANGELOG et `modversion` 2.3.0 | Terminée (2026-11-24) | B1, B2 | D03, D06 | S | — |
| B4 | Passage en jeu par l'utilisateur | À faire | B1 | D01-D04 | S | — |

## Fiches

### B1 — Options, configuration et distributions

Statut : Terminée (2026-11-24).

- `batman_LiveWire/42.21/media/sandbox-options.txt` : `EquipmentLootMultiplier` à `min = 0.0`, puis
  `SolarLootMultiplier`, `WindLootMultiplier` et `HydroLootMultiplier` (`double`, 0-10, défaut 1.0).
- `media/lua/shared/LiveWire/LW_Config.lua` : `Config.equipmentLoot()` (global borné 0-20, défaut 5),
  `Config.LOOT_CATEGORIES`, `Config.lootCategory(famille)` (borné 0-10, défaut 1, famille inconnue = 1),
  `DEFAULTS` complétés. Un seul endroit borne et rejette NaN.
- `media/lua/server/Items/LiveWire_Distributions.lua` : table `CATEGORY`, `equipment(multiplier, categories)` qui
  applique le multiplicateur de famille ; `add()` retire l'entrée quand la cible est nulle.
- `batman_LiveWireExtended/.../LWX_Distributions.lua` : multiplicateur global via `Config.equipmentLoot()`, `put()`
  retire l'entrée quand la cible est nulle.
- Tests : `tests/test_loot.py` (5 cas ajoutés, un cas de bornes mis à jour : −10 et 0 retirent l'entrée) et
  `tests/test_loot_extended.py` (3 cas : multiplicateur global, zéro, remontée sans doublon).
- Preuves (2026-11-24) : `python -B -m unittest discover -s tests` → `Ran 738 tests` / `OK (skipped=4)`.

### B2 — Traductions

Statut : Terminée (2026-11-24).

- `tools/translations_ixx.py` : six lignes nouvelles (trois libellés, trois infobulles) dans l'ordre
  `EN FR DE ES PT PTBR RU CN JP KO TR` ; infobulle du multiplicateur global réécrite (0-20, 0 = aucun, renvoi aux
  trois options).
- Dette d'outillage corrigée au passage : `IGUI_CraftingCategories_LiveWire` manquait dans les sources du générateur
  (il aurait disparu des fichiers EN et FR) ; il est désormais dans `tools/translations_src.py` et
  `OTHER_ROWS`. L'infobulle du profil de consommation annonçait encore un sèche-linge à 5 000 W au lieu de 3 500 W
  (2.1.7) dans les sources : corrigée en EN et FR.
- Régénération : `python -I tools/translations_src.py` → `wrote 8 files per language` ; les onze `Sandbox.json` portent
  les nouvelles clés.
- Preuve (2026-11-24) : `python -B tools/check_mod.py` → `OK` (chaque clé sandbox existe en EN et FR).

### B3 — Documentation

Statut : Terminée (2026-11-24).

- `README.md`, `README_fr.md` : trois lignes d'options, borne 0-20 et 0 = aucun sur le multiplicateur global.
- `docs/specifications-techniques.md` (tableau des options, paragraphe des clés de traduction) et
  `docs/specifications-fonctionnelles.md` (F31, § 14).
- `docs/wiki/{en,fr}/11-sandbox-options.md`, `docs/wiki/{en,fr}/09-loot-tables.md` ; `tools/make_doc_tables.py`
  (intro) puis `python tools/make_doc_tables.py` → seules les deux phrases d'intro changent dans `_tables.md`, les poids
  restant identiques.
- `CHANGELOG.md` (2.3.0) ; `modversion=2.3.0` dans les trois `mod.info` ; `LiveWire.VERSION = "2.3.0"` ;
  `docs/ADR/README.md`.
- Preuves (2026-11-24) : `python -B tools/make_doc_tables.py` → `en/_tables.md` et `fr/_tables.md` réécrits, une seule
  ligne de diff chacun (l'intro) ; suite complète verte après documentation (738 tests, voir B1) ; `check_mod.py` → `OK`.

### B4 — Passage en jeu

Statut : À faire. Protocole : nouvelle partie, « Butin solaire » = 0 puis redémarrage → aucune cellule ni panneau,
aucune entrée résiduelle ; éoliennes et roues inchangées ; « Fréquence des équipements et pièces LiveWire » = 0 → plus
aucun équipement LiveWire ni Extended, disque logiciel toujours présent avec le Computer Mod ; une sauvegarde existante
aux valeurs par défaut garde ses poids.
