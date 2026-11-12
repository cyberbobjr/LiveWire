# Plan 001 — Dette relevée par l'audit avant publication de la 2.0.0

ADR : [ADR-001](../ADR/001-dette-audit-2-0-0.md) (Proposé). Départ : commit `879b55f`, suite hors jeu verte, `check_mod.py`
OK. Aucune étape ne démarre avant l'acceptation de l'ADR ; P1 attend aussi Q01, P2 attend Q02.

| # | Étape | Statut | Dépend de | Décisions ADR | Taille | Parallélisable avec |
|---|---|---|---|---|---|---|
| P1 | Validation avant mutation, fin du `pcall` d'isolement | À faire | ADR accepté, Q01 | D01 | M | P3, P5 |
| P2 | Constantes métier nommées, unités traduites, portée d'adoption | À faire | ADR accepté, Q02 | D02 | M | P4 |
| P3 | Fenêtre et menu d'Extended découpés, file d'actions préservée | À faire | ADR accepté | D03, D07 | M | P1 |
| P4 | Copies uniques (parcours de chunk, constantes d'Extended, `transmit`), client de `LW_ServiceSync` sous `client/` | À faire | ADR accepté | D04 | S | P2 |
| P5 | `LoadChunk` par `Compat`, gardes des enveloppes vanilla, recherche de bâtiment bornée | À faire | ADR accepté | D05, D06 | S | P1 |
| P6 | Points mineurs de l'ADR et tableau de l'API | À faire | P1 à P5 | D01 à D07 | S | — |

## Fiches

Chaque fiche reçoit, à la clôture : fichiers touchés, commande de la suite hors jeu et sa ligne verte
(`python -m pytest tests -q` : nombre de tests passés, zéro échec), sortie de `tools/check_mod.py`, commit ; pour P1 et
P5, la commande `pzdev` du passage en jeu, son code de sortie, sa ligne `summary` et son dossier `runs/...`.

### P1 — Validation avant mutation

Fichiers : `server/LiveWire/LW_Commands.lua`, `LW_Simulation.lua`, `LW_Pump.lua`, `LW_ChunkSync.lua`. Test rouge : une
commande qui échoue après sa première mutation laisse le registre inchangé.

### P2 — Constantes nommées

Fichiers : `LW_Commands.lua`, `LW_ServiceSync.lua`, `LW_Defs.lua` ou `LW_Config.lua` ; `LWX_Core.lua`, `LWX_Points.lua`,
`LWX_PointsServer.lua`, `LWX_Protection.lua`, `LWX_HousesServer.lua`, `Adapters/LWX_AdapterFa2.lua`,
`LWX_AdapterMtir.lua` ; traductions des unités (11 langues).

### P3 — Fenêtres découpées

Fichiers : `client/LiveWireExtended/LWX_BoardWindow.lua`, `LWX_Menu.lua`. Test rouge pour D07 : actuellement, un
interrupteur actionné depuis le tableau vide les actions déjà en file du joueur.

### P4 — Copies uniques

Fichiers : `LW_ServiceSync.lua`, `LW_Appliances.lua`, nouveau parcours commun ; `LWX_Menu.lua`, `LWX_Terminals.lua`,
`Adapters/LWX_AdapterTerminal.lua`, fichiers serveur d'Extended qui définissent `transmit()`.

### P5 — Enregistrements et recherche bornée

Fichiers : `LW_Appliances.lua`, `LW_ServiceSync.lua`, `LW_PumpView.lua`, `LW_Visuals.lua`, `LW_VanillaGuards.lua`,
`LWX_Buildings.lua`.

### P6 — Points mineurs

Liste de l'ADR, paragraphe « Points mineurs ».
