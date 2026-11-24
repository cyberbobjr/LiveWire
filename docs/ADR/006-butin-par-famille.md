# ADR-006 — Butin configurable par famille d'équipement

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-006-BUTIN-PAR-FAMILLE` |
| Date de création et de mise à jour | 2026-11-24 |
| Statut | Accepté (2026-11-24) |
| Avancement | voir le [plan 006](../ADR-plans/plan-006-butin-par-famille.md) |
| Décideur | l'utilisateur (« ok pour les noms, et passage en 2.3.0 », 2026-11-24), sur demande d'un joueur du Workshop |
| Portée | `batman_LiveWire` : `sandbox-options.txt`, `LW_Config.lua`, `LiveWire_Distributions.lua` ; `batman_LiveWireExtended` : `LWX_Distributions.lua` ; traductions des onze langues ; tests `test_loot.py` ; README, spécifications, wiki, CHANGELOG, `modversion` |
| Documents liés | [Spécifications techniques](../specifications-techniques.md) (§ options sandbox), [Tables de butin](../wiki/fr/09-tables-de-butin.md) |
| Références | `media/sandbox-options.txt`, `media/lua/shared/LiveWire/LW_Config.lua`, `media/lua/server/Items/LiveWire_Distributions.lua`, `LWX_Distributions.lua` |

## Contexte

Un joueur du Workshop demande de réduire fortement, voire de supprimer, les panneaux photovoltaïques, jugés trop
fréquents pour 1993, tout en gardant les éoliennes et les roues à aubes. Le mod expose déjà
`LiveWire.EquipmentLootMultiplier` (défaut 5), mais il porte deux limites :

1. son plancher est **1**, donc le minimum atteignable reste le cinquième du défaut ;
2. c'est un **curseur unique** : baisser les panneaux baisse aussi éoliennes, roues à aubes, batteries, pales et mâts.

Les tables de butin vanilla sont indexées par type de conteneur, pas par position sur la carte : un butin
géographique (roue à aubes près de l'eau) demanderait un mécanisme par tirage, hors de cette décision.

## Décisions

- **D01 — Plancher à 0 sur le multiplicateur global.** `LiveWire.EquipmentLootMultiplier` passe de `1–20` à `0–20` ;
  `0` supprime tout l'équipement LiveWire et LiveWire Extended. Le clamp devient `math.max(0, math.min(20, …))`.
- **D02 — Trois options de butin par famille.** `LiveWire.SolarLootMultiplier`, `LiveWire.WindLootMultiplier` et
  `LiveWire.HydroLootMultiplier`, de type double, bornes `0–10`, défaut `1`. Libellés « Butin solaire »,
  « Butin éolien », « Butin hydraulique ». Elles règlent le **butin**, jamais la production : les options de production
  restent `SolarMultiplier`, `WindMultiplier` et `HydroMultiplier`, dont les noms ne changent pas.
- **D03 — Composition multiplicative.** Poids final = poids de base × multiplicateur global × multiplicateur de
  famille. Les défauts (5 × 1) reproduisent exactement les poids actuels : aucune sauvegarde existante ne change, et les
  tableaux de butin de la documentation restent valides.
- **D04 — `0` retire l'entrée de la liste.** Aucun poids nul n'est laissé dans les tables : l'objet sort des listes
  procédurales et des listes de véhicules, ce qui garde les tables propres et rend le comportement vérifiable en test.
- **D05 — Périmètre des familles.** Solaire : `LiveWire.SolarCell` et `Base.Mov_LiveWire_SolarPanel`. Éolien :
  `Base.Mov_LiveWire_WindTurbine`, `LiveWire.WindTurbineBlades`, `LiveWire.WindTurbineMast`. Hydraulique :
  `Base.Mov_LiveWire_WaterWheel`. L'appareillage universel (testeur de tension, batterie stationnaire, onduleur,
  disjoncteur, powerbank, alarme de batterie faible) et tout LiveWire Extended suivent le seul multiplicateur global.
  Le disque logiciel reste hors multiplieur, comme avant.
- **D06 — Version 2.3.0.** Des réglages joueur nouveaux justifient une montée mineure ; `modversion` des deux mods de
  code passe à `2.3.0`.

## Hors périmètre

- **Coût de fabrication** (mêmes ingrédients, niveaux relevés) : refusé pour cette version. Il casserait les recettes
  connues des sauvegardes en cours, et `SolarMultiplier` règle déjà l'efficacité des panneaux, y compris de fortune.
- **Butin lié au lieu** (roue à aubes près de l'eau, éolienne rurale) : demande un ADR distinct, un crochet par tirage
  et une mesure de performance. La répartition actuelle reste thématique par type de conteneur.
