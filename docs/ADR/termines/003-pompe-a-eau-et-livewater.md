# ADR-003 — La pompe à eau de Live Wire s'efface devant LiveWater

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-003-POMPE-A-EAU-ET-LIVEWATER` |
| Date de création et de mise à jour | 2026-11-19 |
| Statut | Accepté (2026-11-19) |
| Avancement | Terminé le 2026-11-19 ; voir le [plan 003](../../ADR-plans/termines/plan-003-pompe-a-eau-et-livewater.md) |
| Décideur | l'utilisateur (« solution 2 ok », 2026-11-19) |
| Portée | `batman_LiveWire` : recette `LWMakeWaterPump`, `shared/LiveWire/LW_Compat.lua`, `LW_Recipes.lua` ; descriptions Steam, wiki, CHANGELOG |
| Documents liés | [plan 003](../../ADR-plans/termines/plan-003-pompe-a-eau-et-livewater.md), [ADR-002](../002-api-consommateurs.md) (la pompe de LiveWater tire son courant par l'API), [`specifications-fonctionnelles.md`](../../specifications-fonctionnelles.md) (pompe à eau) |
| Références | `media/scripts/LiveWire_recipes.txt` (`LWMakeWaterPump`, `LWDismantleWaterPump`) ; moteur : `CraftRecipe.java:409-415` (`OnTest`, `OnAddToMenu`), `CraftRecipe.java:1027-1046` (`OnTestItem`), `CraftRecipeManager.java:685` (contrôle des entrées), `ISRecipeScrollingListBox.lua:344-348` et `ISTiledIconPanel.lua:193-197` (filtre du menu), `LuaManager.java:4802-4804` (`callLuaBool` global : nom de fonction global brut, sans point) |
| Origine | question de l'utilisateur du 2026-11-19 : « comment gérer la compatibilité avec la pompe à eau de livewire ? » |

## Contexte

Live Wire a sa propre pompe à eau (`Base.Mov_LiveWire_WaterPump`, recette `LWMakeWaterPump`, Électricité 3) : collée
à huit barils ou récupérateurs au plus, elle alimente les éviers, douches et toilettes raccordés à 15 cases par des
réservoirs relais invisibles. Le mod frère LiveWater (dépôt public, non publié au 2026-11-19) apporte une autre pompe :
elle puise dans un lac, un puits, un baril ou une pompe à essence et pousse l'eau dans des tuyaux visibles jusqu'à
l'arrivée d'eau de la maison et aux arroseurs. LiveWater ne touche jamais aux relais ni aux barils de Live Wire (son
ADR-001, D21).

Les deux mods cohabitent donc sans conflit technique. Le défaut est pour le joueur : avec les deux mods, le menu
d'artisanat propose deux « pompes à eau » qui ne font pas la même chose. Live Wire est publié : des parties en cours
utilisent sa pompe, et sa page Steam annonce déjà que la pompe passera dans son propre mod.

Options présentées à l'utilisateur le 2026-11-19 : cohabitation sans changement ; recette masquée quand LiveWater est
chargé (retenue) ; conversion automatique des pompes posées en pompes LiveWater ; retrait de la pompe dans une version
majeure de Live Wire.

## Décisions

- **D01 — Recette masquée et refusée quand LiveWater est actif.** Si le mod `batman_LiveWater` est activé, la recette
  `LWMakeWaterPump` n'apparaît plus dans le menu d'artisanat (filtre `OnAddToMenu` du jeu, même avec « tout afficher »)
  et ne peut plus être fabriquée (`OnTest` refuse chaque objet d'entrée ; ce contrôle tourne aussi sur le serveur, il
  fait autorité). Sans LiveWater, rien ne change.
- **D02 — Les pompes existantes restent.** Pompes déjà posées ou en inventaire, leurs barils et leurs relais continuent
  de marcher : aucun code de la pompe, des relais ni des barils n'est modifié. Le démontage (`LWDismantleWaterPump`),
  le ramassage et la pose restent possibles. Aucune conversion de sauvegarde.
- **D03 — Détection.** `LiveWire.Compat.liveWater()` répond par la liste des mods activés
  (`Compat.isModActive("batman_LiveWater")`), comme les autres détections de `LW_Compat.lua`. La liste ne change pas
  pendant une partie : la réponse est retenue après le premier appel. Le filtre du menu est une fonction globale à nom
  simple (`LiveWireWaterPumpInMenu`), car le menu la cherche par `rawget` sur l'environnement global, sans résoudre de
  point ; le test d'objet reste dans `LiveWire.Recipes` (résolu par `getFunctionObject`, qui suit les points).
- **D04 — Textes pour le joueur.** Les descriptions Steam (11 langues), le wiki et le CHANGELOG disent que, avec
  LiveWater, la pompe à eau de Live Wire n'est plus fabricable et que les pompes déjà posées continuent de marcher.
  Aucun texte nouveau dans le jeu.

## Conséquences

- Un joueur qui a les deux mods ne voit qu'une pompe à eau : celle de LiveWater.
- Un joueur qui ajoute LiveWater à une partie en cours garde son installation Live Wire.
- Le retrait complet de la pompe de Live Wire (option écartée pour l'instant) fera l'objet d'un autre ADR, une fois
  LiveWater publié et éprouvé.
