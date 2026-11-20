# ADR-005 — Modèles Viewpoint au nouveau format de paquet (Viewpoint 0.1.7)

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-005-VIEWPOINT-NOUVEAU-FORMAT` |
| Date de création et de mise à jour | 2026-11-20 |
| Statut | Accepté (2026-11-20) |
| Avancement | voir le [plan 005](../ADR-plans/plan-005-viewpoint-nouveau-format.md) |
| Décideur | l'utilisateur (« migre LiveWire Viewpoint sur le nouveau format de ViewPoint », 2026-11-20) ; options recommandées appliquées par défaut |
| Portée | `batman_LiveWireViewpoint` : emplacement des modèles, descripteur de paquet, manifeste, suppression de l'inscription Lua ; exporteur `source/viewpoint/export_viewpoint.py` ; tests ; spécifications, wiki, CHANGELOG |
| Documents liés | ADR-019 de LiveWater (même format pour `batman_LiveWaterViewpoint`), D-32 de [`decisions.md`](../decisions.md) |
| Références | Viewpoint 0.1.7 (2026-11-15, Workshop 3809306528), `Viewpoint.jar` décompilé : `viewpoint.addons.Kind`, `ModScan`, `Descriptor`, `DescriptorCheck`, `Ids`, `PackContent`, `LegacyPacks`, `LegacyPack` ; `viewpoint.packs.ModelPacks`, `PackManifest`, `PackLoads` |

## Contexte

Le sous-mod inscrit ses deux manifestes en Lua (`LiveWireViewpoint.lua`, `Viewpoint.ModelPacks.register`), celui de
LiveWire Extended seulement quand Extended est actif. Depuis la 0.1.7, Viewpoint découvre lui-même les paquets dans
`media/viewpoint/resourcepacks/<id>/pack.properties` de chaque mod chargé ; l'inscription Lua est un chemin « hérité »
(paquet `legacy.<mod>`), retrouvé en lisant les fichiers Lua du mod et rangé à part dans son menu.

Règles relevées (identiques à l'ADR-019 de LiveWater) : descripteur `format=1`, `id` (`a-z 0-9 - .`, nom du dossier,
pas de préfixe `legacy`), `name`, `version` `MMM.NNN.PPP`, `game.min` à deux nombres ; `models` = chemin du manifeste
dans le dossier du paquet, sans `..` ; les modèles et leurs textures se résolvent à l'intérieur du dossier du paquet.

## Décisions

- **D01 — Un paquet au nouveau format.** `common/media/viewpoint/resourcepacks/batman-livewire/pack.properties`
  (`id=batman-livewire`, `name=LiveWire`, `version=1.0.0`, `game.min=42.22`, `viewpoint.min=0.1.7`, `icon`),
  manifeste `models.properties`, modèles, MTL et palettes déplacés tels quels dans `models/` du paquet.
- **D02 — Un seul paquet pour LiveWire et LiveWire Extended.** Le manifeste réunit les modèles et liaisons des deux
  planches : un seul interrupteur dans Viewpoint. Sans LiveWire Extended, ses sprites n'existent pas et ses liaisons
  ne servent à rien. L'exporteur met à jour, dans ce manifeste unique, les seules lignes de la planche qu'il exporte.
- **D03 — Plus d'inscription Lua.** `LiveWireViewpoint.lua` est supprimé, avec l'ancien dossier `livewire-viewpoint` :
  sans cela, Viewpoint listerait aussi le paquet hérité `legacy.batman_LiveWireViewpoint`.
- **D04 — Géométrie inchangée.** Aucun modèle n'est régénéré ; les angles des orientations (0, -90, 180, 90) restent.
