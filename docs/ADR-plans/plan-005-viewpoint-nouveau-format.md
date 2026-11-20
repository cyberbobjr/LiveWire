# Plan 005 — Modèles Viewpoint au nouveau format de paquet (Viewpoint 0.1.7)

ADR : [ADR-005](../ADR/005-viewpoint-nouveau-format.md) (Accepté le 2026-11-20).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| V1 | Test du paquet, déplacement des modèles, descripteur et manifeste unique, suppression de l'inscription Lua, exporteur | À valider (passage en jeu V3) | ADR accepté | D01-D04 | M | — |
| V2 | Spécifications, wiki EN/FR, CHANGELOG, README des ADR | Terminée (2026-11-20) | V1 | D01, D02 | S | — |
| V3 | Passage en jeu par l'utilisateur : paquet LiveWire listé une seule fois dans Viewpoint, activé, appareils vus en 3D | À faire | V1 | D01-D03 | S | — |

## Fiches

### V1 — Paquet

Statut : À valider (passage en jeu V3).

- `common/media/viewpoint/resourcepacks/batman-livewire/` : `pack.properties` (format 1, `batman-livewire`, 1.0.0,
  `game.min=42.22`, `viewpoint.min=0.1.7`, icône 128 px tirée de `preview.png`) ; `models.properties` (159 lignes :
  les lignes `model.`/`bind.` des deux anciens manifestes, 114 liaisons LiveWire et 10 LiveWire Extended) ; `models/`
  déplacé tel quel (`git mv`, 35 modèles, MTL et deux palettes).
- Supprimés : `common/media/lua/client/LiveWireViewpoint.lua`, `livewire.properties`, `extended.properties` et
  l'ancien dossier `livewire-viewpoint`.
- `source/viewpoint/export_viewpoint.py` : écrit dans le dossier du paquet ; manifeste unique dont chaque export ne
  remplace que les lignes de sa planche (`sheet_lines`). Vérification sur une copie du sous-mod (scratchpad) : export
  complet, `--extended`, export partiel `inverter`, puis complet → mêmes 159 lignes que le manifeste migré, aucun
  doublon ; modèles régénérés identiques aux livrés aux fins de ligne près (42 fichiers CRLF dans le dépôt).
- Tests : `tests/test_viewpoint_pack.py` (6 : aucun Lua ni ancien dossier ; descripteur et identifiant ; fichiers du
  descripteur dans le paquet ; deux planches dans le paquet ; chaque liaison vers un modèle ; chaque modèle lisible
  avec `mtllib` sans `..`, `map_Kd` PNG, volume positif) ; `tests/test_lcd_indicators.py` lit le nouveau chemin.
- Preuves (2026-11-20) : `python -B -m unittest discover -s tests` → `Ran 728 tests` / `OK (skipped=4)` ;
  `python -B tools/check_mod.py` → `OK`.

### V2 — Documentation

Statut : Terminée (2026-11-20).

- `CHANGELOG.md` (Unreleased, Improvements) ; `docs/specifications-techniques.md` (ligne Project Viewpoint) ;
  `docs/specifications-fonctionnelles.md` (§ 10.4) ; `docs/wiki/en/Home.md`, `docs/wiki/fr/Home.md` ;
  `docs/ADR/README.md`.

### V3 — Passage en jeu

Statut : À faire. Protocole : Viewpoint 0.1.7 actif avec LiveWire et « LiveWire - Viewpoint models » ; dans les
réglages de Viewpoint, un seul paquet **LiveWire** listé (aucun `legacy.batman_LiveWireViewpoint`) ; l'activer ;
onduleur, panneau solaire, éolienne et disjoncteur apparaissent en 3D comme avant ; avec LiveWire Extended, la borne
et un tableau aussi.
