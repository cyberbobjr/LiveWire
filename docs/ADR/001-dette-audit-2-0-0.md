# ADR-001 — Dette relevée par l'audit avant publication de la 2.0.0

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-001-DETTE-AUDIT-2-0-0` |
| Date de création et de mise à jour | 2026-11-12 |
| Statut | Proposé (2026-11-12). Le report après la publication est décidé par l'utilisateur (« documente, on corrigera plus tard ») ; les corrections D01 à D07 restent à accepter |
| Avancement | Aucune étape commencée ; voir le [plan 001](../ADR-plans/plan-001-dette-audit-2-0-0.md) |
| Décideur | l'utilisateur |
| Portée | `batman_LiveWire` et `batman_LiveWireExtended` (Lua `shared`, `server`, `client`) |
| Documents liés | [plan 001](../ADR-plans/plan-001-dette-audit-2-0-0.md), [`decisions.md`](../decisions.md) (D-46 à D-52, D-54), [`developpement.md`](../developpement.md), [plan de dette du 2026-11-09](../annexes/plans/dette-technique.md) |
| Références | relectures du 2026-11-12 (code de la base, code d'Extended), commit de départ `879b55f` |
| Origine | audit avant publication du 2026-11-12 |

## Contexte

L'audit du 2026-11-12 a relevé des défauts de structure qui ne bloquent pas la publication. Ceux qui touchaient aux
performances ou à la mémoire ont été corrigés avant la publication :

- fenêtre du tableau d'Extended : texte d'aide découpé, titres mesurés et inventaire compté à chaque image (`de66b74`) ;
- tableau de disjoncteurs envoyé aux clients toutes les dix minutes même sans changement (`de66b74`) ;
- ModData vide créée sur chaque case des bâtiments chargés par la recherche des tableaux de maison (`879b55f`).

Le reste est consigné ici et sera corrigé après la publication. **Impact sur les performances ou la stabilité**,
évalué pour chaque point :

| Point | Performances | Stabilité |
|---|---|---|
| `pcall` généralisé (D01) | aucun | **oui** : une erreur après une mutation partielle laisse le registre incohérent, seulement journalisée (hypothèse, non reproduite) |
| Recherche du bâtiment le plus proche (D06) | **faible** : parcours de tous les bâtiments de la carte, à chaque menu ou clic hors d'un bâtiment, pas à chaque image | aucun |
| Gestionnaires `LoadChunk` hors `Compat.addLoadChunk` (D05) | aucun | **faible** : avec Let Me Drive, retardés (hypothèse) |
| Enveloppes vanilla sans garde de seconde exécution (D05) | aucun | **faible** : empilement en cas de rechargement Lua (mode debug seulement) |
| Constantes en dur (D02), fonctions géantes (D03), duplications (D04), file d'actions vidée (D07) | aucun | aucun (maintenance, ergonomie) |

## Décisions proposées

- **D01 — Fin du `pcall` d'isolement.** `server/LiveWire/LW_Commands.lua:429` (chaque commande réseau),
  `LW_Simulation.lua:800, 851, 861, 873`, `LW_Pump.lua:99`, `LW_ChunkSync.lua:21, 45, 56` : valider toutes les
  conditions avant la première mutation (exemple : `C_UNLINK`, `LW_Commands.lua:264-274`, délie puis rafraîchit) ;
  garder un seul point d'isolement, avec trace complète, au plus haut de la boucle de simulation.
- **D02 — Constantes métier nommées.** Base : XP 5 et 1 (`LW_Commands.lua:356, 371`), portée d'adoption 40 et
  `z > 3` (`:406`, `:411`), 100 cases et 16 services (`shared/LiveWire/LW_ServiceSync.lua:32, 57, 62-63`). Extended :
  niveau 3, XP 5, 24 h, rayon 20, 2 000 cases (`LWX_Core.lua:20`, `LWX_Points.lua:19`, `LWX_PointsServer.lua`,
  `LWX_Protection.lua`, `LWX_HousesServer.lua:19`), estimations 800, 300 et 100 W (`Adapters/LWX_AdapterFa2.lua:12`,
  `LWX_AdapterMtir.lua:13`). Les règles de jeu passent dans `LiveWire.Config` ou `LW_Defs` (ou une table de
  constantes d'Extended), avec leur raison ; aucune nouvelle option sandbox sans accord. Unités « A » et « W » de
  `LWX_Menu.lua:265` et `LWX_BoardWindow.lua` passées par des clés de traduction. La portée d'adoption (40 cases contre 3
  pour toute autre action) est ramenée au rayon d'action ou justifiée dans la doc.
- **D03 — Fenêtres découpées.** `client/LiveWireExtended/LWX_BoardWindow.lua` (environ 600 lignes) et `LWX_Menu.lua`
  (environ 480) se séparent en mise en page, rendu, actions et inscriptions, sans changement visible.
- **D04 — Une seule copie.** Parcours d'un chunk (8 × 8 cases par étage, indices 0..63 en dur) copié dans
  `LW_ServiceSync.lua:160-168` et `LW_Appliances.lua:152-160` → un parcours commun. `RELAY_REACH` et la clé `"t:"`
  dupliqués (`LWX_Menu.lua:123`, `LWX_Terminals.lua:19, 93`, `Adapters/LWX_AdapterTerminal.lua:22`) et `transmit()`
  local dans quatre fichiers serveur d'Extended → un module de constantes et une fonction partagée. Code client de
  `shared/LiveWire/LW_ServiceSync.lua:73-202` (gardé par `isClient()`, sans effet sur un dédié) déplacé sous `client/`.
- **D05 — Enregistrements sûrs.** Les gestionnaires `LoadChunk` de `LW_Appliances.lua:152`, `LW_ServiceSync.lua:160`,
  `LW_PumpView.lua:223` et `LW_Visuals.lua:343` passent par `LiveWire.Compat.addLoadChunk`, ou leur exception est
  documentée ; les trois enveloppes de `shared/LiveWire/LW_VanillaGuards.lua:58-89` reçoivent un drapeau comme celle
  du curseur.
- **D06 — Recherche de bâtiment bornée.** `shared/LiveWireExtended/LWX_Buildings.lua:129-146` (`B.find`) : index par
  chunk ou parcours borné à la portée demandée, au lieu de tous les bâtiments de la carte.
- **D07 — File d'actions préservée.** `ISTimedActionQueue.clear(player)` (`LWX_Menu.lua:193`,
  `LWX_BoardWindow.lua:317`) vide toute la file du joueur pour un simple interrupteur : ne retirer que les actions de
  l'addon.

Points mineurs à reprendre dans les mêmes étapes : `LWUnlinkAction:complete` renvoie vrai même refusé
(`shared/LiveWire/TimedActions/LW_TimedActions.lua:48-53`) ; repli du rattrapage des réfrigérateurs sur le journal
d'ancre sans garde `nil` (`server/LiveWire/LW_FridgeCatchup.lua:56, 165`) ; `getSprite` sans garde
(`LWX_HousesServer.lua`, pose du tableau de maison) ; consommation en deux temps de l'agrandissement
(`LWX_Panels.lua:110`) ; ordre de `pairs()` dans `LWX_Sites.lua:135, 160` ; abonnement à l'onduleur non retiré et
retour de `registerSoftwareLines` ignoré (`LWX_BoardWindow.lua`) ; `require "LiveWire/LW_Core"` d'Extended
(`LWX_Core.lua:9`) hors de la liste autorisée par `developpement.md` ; `gridName`, `subscribeInverter` et
`directClickPlayer` absents du tableau de l'API dans `specifications-techniques.md`.

## Arbitrages ouverts

- **Q01** — D01 : garder un point d'isolement unique (recommandé), ou aucun ?
- **Q02** — D02 : les constantes d'Extended restent internes (recommandé), ou certaines deviennent des options sandbox ?

## Conséquences

- Chaque étape garde les comportements visibles : la suite hors jeu (585 tests verts au départ) et `tools/check_mod.py`
  restent verts, test rouge d'abord pour chaque défaut corrigé.
- D01 et D06 se vérifient aussi en jeu (solo puis MP) avant clôture.
