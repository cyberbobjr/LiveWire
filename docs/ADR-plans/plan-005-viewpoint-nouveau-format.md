# Plan 005 — Modèles Viewpoint au nouveau format de paquet (Viewpoint 0.1.7)

ADR : [ADR-005](../ADR/005-viewpoint-nouveau-format.md) (Accepté le 2026-11-20).

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| V1 | Test du paquet, déplacement des modèles, descripteur et manifeste unique, suppression de l'inscription Lua, exporteur | À valider (passage en jeu V3) | ADR accepté | D01-D04 | M | — |
| V2 | Spécifications, wiki EN/FR, CHANGELOG, README des ADR | Terminée (2026-11-20) | V1 | D01, D02 | S | — |
| V3 | Passage en jeu : paquet LiveWire listé dans Viewpoint, appareils vus en 3D | Terminée (2026-11-27, remplacée par V4) | V1 | D01-D03 | S | — |
| V4 | Inscription Lua rétablie après les retours des joueurs (modèles invisibles) | Terminée (2026-11-27, version 2.3.1) | V3 | D05 | S | — |

## Fiches

### V1 — Paquet

Statut : Terminée ; l'absence d'inscription Lua (D03) est annulée par V4.

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

Statut : Terminée (2026-11-27, remplacée par V4). Passages automatiques avec ZombieBuddy et Viewpoint 0.1.7, sans
inscription Lua : mods actifs au menu principal, le paquet est découvert (« 1 resource packs ») mais reste éteint
(`runs/20261127-191245-sp-c39746ca3094`) ; mods activés par la sauvegarde seule, « 0 resource packs »
(`runs/20261127-192017-sp-8138d7f1a8a2`, code 1). Le protocole prévu (un seul paquet listé, à activer) ne tient donc
pas pour un mod activé dans une partie ou reçu d'un serveur.

### V4 — Inscription Lua rétablie

Statut : Terminée (2026-11-27, version 2.3.1).

- `common/media/lua/client/LiveWireViewpoint.lua` inscrit le manifeste du paquet (`Viewpoint.ModelPacks.register`,
  arguments littéraux) à `OnGameBoot`, `OnGameStart` et au chargement du fichier.
- Test : `tests/test_viewpoint_pack.py` (un seul appel, identifiant du mod, manifeste existant) ; 6 tests au vert ;
  `python -B tools/check_mod.py` → `OK`.
- En jeu (`autotest/scenarios/viewpoint.json`, objets posés par création directe, captures ouvertes) : mods au menu
  principal, code 0, « 35 models, 124 sprites », modèles visibles (`runs/20261127-193145-sp-54d942bb5c12`) ; mods dans
  la sauvegarde seule (`PZAT_SAVE_ONLY_MODS`), code 0, paquet chargé alors que la découverte donne « 0 resource
  packs » (`runs/20261127-194959-sp-8651d6caeed7` ; capture masquée par l'écran d'accueil de Viewpoint, image probante
  du même cas : `runs/20261127-192800-sp-33b7788b193a`).
- Limites : multijoueur et LiveWire Extended non essayés avec Viewpoint ; deux entrées dans le menu de Viewpoint quand
  le mod est actif au menu principal.
