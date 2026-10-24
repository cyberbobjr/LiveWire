# Live Wire — améliorations de code et idées de fonctionnalités

| | |
|---|---|
| Mod | **Live Wire** (`id=batman_LiveWire`, sous-mod facultatif `batman_LiveWireViewpoint`) |
| Version analysée | Constats initiaux : **1.3.1** ; campagne du 2026-10-24 fondée sur **1.4.0** (`modversion=1.4.0`), correctifs locaux non publiés |
| Build cible | Project Zomboid 42.21 (sources de référence : Java décompilé 42.21.0, `media/` vanilla installé) |
| Date | 2026-10-21 ; **avancement mis à jour le 2026-10-24** (version publiée : 1.4.0 ; corrections C01, C02, C03 et C10 publiées depuis la 1.3.2) |
| Périmètre lu | Tout le Lua de `Contents/mods/batman_LiveWire/42.21/media/lua` (shared, server, client, actions chronométrées, butin), scripts (`LiveWire_*.txt`), `sandbox-options.txt`, traductions (contrôlées par `tools/check_mod.py`), sous-mod Viewpoint, `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `docs/` (décisions, idées retenues et écartées, spécifications, architecture, protocole de tests), `tests/`, `tools/`, `autotest/`, base moteur `.claude/pz-knowledge` |
| Vérifications faites | `python tools/check_mod.py` : OK ; `python tests/test_physics.py` et `tests/test_simulation.py` : OK. Constats initiaux sans test en jeu ; campagne du 2026-10-24 : SP complet 36/36, ciblé 13/13 ; MP ciblé 14/14 serveur et 7/7 client ; C25 : trois phases SP et trois phases MP, deux clients (voir la validation C25) |

**Note sur les chemins.** `docs/` est en cours de réorganisation. Les renvois ci-dessous utilisent les nouveaux noms : `docs/decisions.md` (ancien `decisions-ouvertes.md`), `docs/annexes/recherches/idees-initiales.md` (ancien `IDEES.md`), `docs/specifications-fonctionnelles.md` (ancien `fonctionnel.md`), `docs/annexes/tests/protocole-tests.md`. Les numéros de ligne des problèmes décrivent l’analyse initiale en 1.3.1 ; les avancements du 2026-10-24 renvoient au plan de campagne pour les nouvelles preuves. Ces anciens numéros renvoient aux fichiers Lua de `Contents/mods/batman_LiveWire/42.21/media/lua/`, sauf mention contraire. Les identifiants `C..` (améliorations) et `I..` (idées) de ce document sont propres aux propositions ; les `F..` désignent les fonctionnalités de `specifications-fonctionnelles.md`.

**Statuts.**
- *Confirmé statiquement* : établi par la lecture du code du mod et du jeu.
- *À vérifier en jeu* : déduit du code, mais l'effet réel dépend du moteur ou de la machine.

## Tableau de bord — ce qui est fait et ce qui reste

**Légende** : ✅ fait · 🟡 fait en partie · ⬜ pas commencé · ⏸ différé après décision utilisateur. « Publié » = présent dans une version du Workshop (première version qui le contient) ; « non publié » = sur `main` mais pas encore publié. Les corrections C04, C05, C06, C07, C09, C16 et C22 sont maintenant réalisées localement, **non publiées** ; la partie mémoire de C23 est réalisée. Les corrections C01, C02, C03 et C10 restent publiées en 1.3.2. Preuves et limites : [campagne du 2026-10-24](annexes/plans/correctifs-blocages-performances.md). Détail de chaque point dans les parties 1 et 2 ; tests en jeu automatiques décrits dans `docs/annexes/tests/protocole-tests.md`.

**Bilan** : améliorations de code **16 faites, 1 en partie, 8 à faire, 1 différée** (sur 26) ; idées de fonctionnalités **0 faite, 2 en partie, 18 à faire** (sur 20).

### Améliorations de code

| ID | Sujet | État | Testé | Publié | Commit | Ce qui reste |
|---|---|---|---|---|---|---|
| C01 | « Retirer tous les relais d'eau » sans effet durable | ✅ Corrigé | SP + MP, retrait chargé/déchargé et redémarrage (2026-10-24) | 1.3.2 | `dc553a5` | Validation C25 terminée |
| C02 | Logiciel : commandes depuis l'ordinateur raccordé, autre étage | ✅ Corrigé | MP (pz-autotest 2026-10-21, même étage et étage voisin) | 1.3.2 | `dc553a5` | Ordinateur du Computer Mod non raccordé par câble : ancienne règle |
| C03 | Synchro des relais à chaque minute (éclairage recalculé) | ✅ Corrigé | — (coût à mesurer en jeu) | 1.3.2 | `dc553a5` | Mesurer en MP près d'une pompe |
| C04 | Balayages synchrones de la pompe et de sa vue | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Mesure des FPS en charge réelle à compléter |
| C05 | Balayage complet du disque à chaque bascule d'ancre | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Mesure des FPS en charge réelle à compléter |
| C06 | Chargement de chunk qui parcourt tout le registre | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Mesure des FPS en charge réelle à compléter |
| C07 | Baril déplacé : marque orpheline | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Suivi dans le plan de campagne |
| C08 | Deux pompes : « la plus proche dessert » non codée | ⬜ À faire | — | — | — | Tout |
| C09 | Secours qui annule la marche ou l'arrêt manuel | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Suivi dans le plan de campagne |
| C10 | Écran LCD illisible en CN, JP, KO | ✅ Corrigé | — (rendu à vérifier en jeu) | 1.3.2 | `dc553a5` | Vérifier l'écran en CN, JP, KO |
| C11 | Table publique des ancres (positions et journal) | ⏸ Différé | Coût modélisé ; état stable vérifié SP/MP | — | — | Diffusion conservée ; réexaminer sur gros serveur si coût constaté |
| C12 | Journal d'alimentation trop court | ⬜ À faire | — | — | — | Tout |
| C13 | Erreur de `Pump.maintain` avalée | ✅ Corrigé | Injection d’erreur hors jeu ; SP/MP de non-régression | Non publié | `bca619e` | — |
| C14 | Constante `LiveWire.VERSION` périmée | ✅ Corrigé | Contrôle automatique ; journal de démarrage SP/MP | Non publié | `c222136` | — |
| C15 | Commandes réseau mortes (`C_RENAME`…) | ✅ Corrigé | Dialogue réel SP/MP ; ordinateur raccordé vérifié en MP | Non publié | `47410e5` | Compléments de I05 distincts |
| C16 | Instantané recalculé à chaque image en solo | ✅ Corrigé | SP + régressions hors jeu | Non publié | Travail local | Mesure des FPS en charge réelle à compléter |
| C17 | Seuils du générateur de secours non contrôlés | ⬜ À faire | — | — | — | Tout |
| C18 | Débit de la pompe : réserve accumulée à vide | ⬜ À faire | — | — | — | Tout |
| C19 | Nettoyage des relais limité aux étages −1 à 7 | ⬜ À faire | — | — | — | Tout |
| C20 | Bruit pour les zombies : une impulsion par pas | ⬜ À faire | — | — | — | Tout |
| C21 | Pas « tout ou rien » quand le stock manque | ⬜ À faire | — | — | — | Tout |
| C22 | Inspecter et déneiger sans safehouse ; frein définitif | ✅ Corrigé | SP + MP ciblés (2026-10-24) | Non publié | Travail local | Suivi dans le plan de campagne |
| C23 | Tables jamais purgées ; XP du testeur | 🟡 En partie | Régressions hors jeu + SP/MP | Non publié (purge) | Travail local | Plafond global d'XP du testeur (purge mémoire faite) |
| C24 | Adoption de tuiles et marques réécrites par un client | ⬜ À faire | — | — | — | Tout |
| C25 | Tests pompe, relais, couplage et MP | ✅ Terminé | SP 3/3 phases ; MP 3/3 phases, 2 clients ; droits ordinaires couverts séparément | Outil hors mod | `b242a36` | — |
| C26 | README : limite des frigos dépassée par la 1.0.1 | ✅ Corrigé | README EN et FR relus | Non publié | `21cc584` | — |

### Idées de fonctionnalités

| ID | Idée | État | Remarque |
|---|---|---|---|
| I01 | Afficher les consommateurs | ⬜ Proposée | Dépend de C04 |
| I02 | Afficher les raccordements | ⬜ Proposée |  |
| I03 | Prévision de production sur trois jours | ⬜ Proposée |  |
| I04 | Journal des événements du réseau | ⬜ Proposée |  |
| I05 | Nommer son réseau | 🟡 En partie, non publié | Menu et logiciel réalisés avec C15 ; affichages LCD, inspection et alarme restent proposés |
| I06 | Compteurs cumulés et carburant économisé | ⬜ Proposée |  |
| I07 | Orientation des panneaux solaires | ⬜ Proposée |  |
| I08 | Ombre des arbres et des bâtiments | ⬜ Proposée | I07 conseillé |
| I09 | Encrassement et nettoyage des panneaux | ⬜ Proposée |  |
| I10 | Batteries et froid | ⬜ Proposée |  |
| I11 | Tester une batterie au testeur | ⬜ Proposée |  |
| I12 | Recycler les batteries mortes | ⬜ Proposée |  |
| I13 | Démonter un équipement hors service | ⬜ Proposée |  |
| I14 | Frein manuel de l’éolienne | 🟡 En partie, non publié | Cœur réalisé avec C22 ; alerte d’orage et voyant clignotant restent proposés |
| I15 | Intervention sous tension | ⬜ Proposée |  |
| I16 | Arroseur de potager sur la pompe | ⬜ Proposée | Après C03 (fait) et C04 |
| I17 | Approvisionnement en fil électrique | ⬜ Proposée | Dépend de I15 si le danger est retenu |
| I18 | Petite API pour les mods d'extension | ⬜ Proposée | Garde de version : C14 |
| I19 | Bascule avec un générateur vanilla | ⬜ Proposée |  |
| I20 | Couper l'alarme au tableau électrique | ⬜ Proposée |  |

---

## Partie 1 — Améliorations de code

### C01 — « Retirer tous les relais d'eau » ne retire rien de durable
- **Problème.**
  - La commande de debug retire les relais chargés (`server/LiveWire/LW_DebugCommands.lua:130-146`). Mais chaque pompe encore raccordée les reconstruit au pas suivant : `Sim.stepGrid` appelle `Pump.maintain` pour chaque pompe (`server/LiveWire/LW_Simulation.lua:549-551`), et `maintain` repose tous les relais voulus (`server/LiveWire/LW_Pump.lua:165-187`).
  - Sur une case non chargée, `Pump.removeRelay` garde l'entrée (`LW_Pump.lua:86-94`). Au rechargement, `Pump.onLoadChunk` conserve tout relais encore listé par sa pompe (`LW_Pump.lua:410`) : il n'est donc jamais retiré.
  - Le README promet pourtant cette procédure avant la désinstallation (`README.md:205`).
- **Risque.** Persistance et désinstallation. Le mod retiré, des `IsoThumpable` à `FluidContainer` restent dans la sauvegarde, sous une tuile qui n'existe plus, et la plomberie vanilla continue de les voir comme une source d'eau.
- **Correction proposée.**
  - Ajouter un drapeau de registre `pumpsDisabled`, posé par la commande. Tant qu'il est posé, `Pump.maintain` et `Pump.step` ne font rien.
  - La commande vide `dev.relays` des pompes après avoir noté les positions. Ces positions vont dans une liste `pendingRelayRemoval`, que `Pump.onLoadChunk` purge au chargement.
  - Le journal donne le nombre de relais restant hors zone chargée. Un drapeau « Réactiver les pompes » lève le blocage.
- **Statut.** Confirmé statiquement. **Priorité haute, effort S.**
- **Avancement : ✅ corrigé, publié en 1.3.2 (commit dc553a5), à vérifier en jeu** — drapeau `pumpsDisabled` ; les entrées `dev.relays` sont vidées, ce qui suffit à `onLoadChunk` sans liste `pendingRelayRemoval` ; action de debug `enablePumps`. Retrait non couvert par pz-autotest.

### C02 — Le logiciel de gestion ne commande l'onduleur que de très près (et reste muet en MP depuis un autre étage)
- **Problème.**
  - Les boutons Allumer, Éteindre et Réarmer du logiciel envoient `C_SET_INVERTER` et `C_RESET` avec l'identifiant de l'onduleur (`client/LiveWire/LW_SoftwareApp.lua:499-508`).
  - Le serveur exige que le joueur soit à **3 cases au plus de l'onduleur, au même étage** (`server/LiveWire/LW_Commands.lua:41-45`, `:48-61`, `:156-186`). Or l'ordinateur peut être raccordé jusqu'à `LinkRange` (12 cases) et à ±1 étage (`shared/LiveWire/LW_Install.lua:118-158`). Les boutons échouent donc avec « trop loin » dans la plupart des installations, en solo comme en MP.
  - L'abonnement `C_SUBSCRIBE` exige aussi le même étage (`LW_Commands.lua:85-94`). En MP, un ordinateur posé à l'étage d'au-dessus ne reçoit **jamais** d'instantané : le logiciel reste sur « en attente ». En solo, l'affichage marche, car le client lit le registre directement (`client/LiveWire/LW_ClientState.lua:37-44`), ce qui masque le défaut pendant les essais.
  - Même limite pour le Laptop Mod, si le portable est ailleurs que sur le bureau raccordé.
- **Risque.** Bug fonctionnel visible et MP.
- **Correction proposée.** Ajouter aux commandes du logiciel un argument `via` : la position de l'ordinateur. Le serveur l'accepte si trois conditions sont remplies :
  - un appareil `computer` du réseau se trouve à cette position ;
  - le joueur est à `ACT_RANGE` de l'ordinateur ;
  - l'ordinateur est alimenté (`Computer.powered`).

  L'abonnement accepte un écart d'étage jusqu'à `verticalRange()`.
- **Statut.** Confirmé statiquement ; à vérifier en jeu (cas réel : ordinateur à 6 cases, puis à l'étage). **Priorité haute, effort S-M.**
- **Avancement : ✅ corrigé, publié en 1.3.2 (commit dc553a5)** — argument `via` ; distance à l'ordinateur 6 cases, celle de fermeture de l'écran, au lieu de `ACT_RANGE` ; un ordinateur du Computer Mod non raccordé par câble reste soumis à l'ancienne règle. Testé en MP par pz-autotest le 2026-10-21 (commandes et abonnement depuis l'ordinateur, même étage et étage voisin ; refus sans `via` ou avec une fausse position).

### C03 — Synchronisation des relais à chaque minute de jeu : recalcul de l'éclairage chez tous les clients
- **Problème.**
  - `Pump.step` appelle `obj:sync()` sur chaque relais et chaque baril touchés, à chaque minute de jeu de pompage (`LW_Pump.lua:323`).
  - Côté client, `IsoThumpable.syncIsoObjectReceive` invalide les chemins de la case, vide le cache de ligne de vue, force `setRecalcLightTime(-1)` et `lightSourceUpdate = 100` (`java/zombie/iso/objects/IsoThumpable.java:1689-1696`).
  - Avec un jour de 1 h, une minute de jeu dure environ 2,5 s réelles. Une maison à 4 relais déclenche donc un recalcul d'éclairage environ toutes les secondes, chez chaque client proche.
- **Risque.** Performance côté client (saccades), surtout en MP.
- **Correction proposée.**
  - Ne synchroniser un relais que lorsqu'il franchit un seuil : vide ou non vide, plein, ou tous les 5 L déplacés depuis la dernière synchro (compteur dans `dev.relays[key]`).
  - Synchroniser les barils au plus une fois par pas de 10 minutes.
  - La plomberie du client n'a besoin que de savoir s'il reste de l'eau.
- **Statut.** Confirmé statiquement (chemin Java) ; coût à mesurer en jeu. **Priorité moyenne, effort S.**
- **Avancement : ✅ corrigé, publié en 1.3.2 (commit dc553a5), à vérifier en jeu** — mémoire de session, pas de compteur sauvegardé dans `dev.relays` ; gain réel à mesurer en MP.

### C04 — Balayages synchrones de la pompe et de sa vue
- **Problème.**
  - `wantedRelays` parcourt (2r+1)² × (2V+1) cases en une seule image (`LW_Pump.lua:109-162`) : 6 727 cases avec `PumpRange = 15`, environ 26 000 au maximum (30).
  - Il est appelé à chaque pas, pour chaque pompe (`LW_Simulation.lua:549-551`), et à chaque raccordement.
  - Côté client, `PumpView.collect` refait le même balayage toutes les 2 s tant que la vue est ouverte (`client/LiveWire/LW_PumpView.lua:42-89`, `:173-176`), avec un appel à `IsoObject.FindExternalWaterSource` par point d'eau.
- **Risque.** Performance : pic d'image sur le serveur, saccade régulière chez le client.
- **Correction proposée.**
  - Garder par pompe une liste des points d'eau (`waterPiped`). Elle est construite par un travail étalé sur plusieurs ticks, comme `Demand` (`server/LiveWire/LW_Demand.lua`), et invalidée par la pose de meubles et par `LoadChunk`.
  - Côté client, construire la liste une fois à l'ouverture de la vue, puis ne revérifier que les cases des relais.
- **Statut.** Confirmé statiquement ; coût à mesurer. **Priorité moyenne, effort M.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Inventaires de positions et file globale bornée à 250 positions/tick sur le serveur ; découverte de la vue client également étalée, puis réévaluation des meubles connus. Tests SP/MP réels et budgets hors jeu ; aucun gain de FPS chiffré annoncé.

### C05 — Balayage complet du disque à chaque changement d'état d'une ancre
- **Problème.**
  - `Anchor.ageFridges` (autorité, `shared/LiveWire/LW_Anchor.lua:91-124`) et `Anchor.refreshVisuals` (chaque client, `:60-83`) parcourent jusqu'à π × 20² × 7, soit environ 8 800 cases, dans la même image, à chaque bascule de l'ancre (`:129-137`).
  - Une maison dont la batterie se vide la nuit bascule au moins deux fois par jour.
- **Risque.** Performance, avec un pic ponctuel.
- **Correction proposée.**
  - Sur l'autorité, réutiliser la liste d'objets déjà construite par `Demand.inventories[inv.id].objects` (frigos compris) au lieu de rebalayer.
  - Côté client, étaler `refreshVisuals` sur quelques ticks (file de cases), ou ne traiter que les objets `couldBePoweredByGenerator`, retenus par un balayage étalé.
- **Statut.** Confirmé statiquement. **Priorité basse à moyenne, effort M.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Index des frigos chargés alimenté par chunks et pose de mobilier ; vieillissement avant bascule ; file visuelle bornée à 250 positions/tick pour toutes les ancres. Vrai aliment vérifié en SP/MP ; parcours hors jeu borné.

### C06 — Chaque chargement de chunk parcourt tout le registre
- **Problème.** `LW_ChunkSync.onLoadChunk` copie **tous** les appareils du registre dans une liste, à chaque `LoadChunk` (`server/LiveWire/LW_ChunkSync.lua:29-44`). Un joueur qui se déplace charge des dizaines de chunks par seconde. Le coût vaut donc chunks × appareils de tout le serveur.
- **Risque.** Performance sur un serveur qui compte beaucoup de bases.
- **Correction proposée.** Indexer le registre par chunk (`byChunk["cx,cy"]`), en le tenant à jour dans `addDevice`, `moveDevice` et `removeDevice` (`server/LiveWire/LW_Registry.lua:87-98`, `:205-239`). Ne parcourir les onduleurs que pour l'invalidation de la demande.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S-M.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Index de session par chunk et ensemble des onduleurs, reconstruits à l’initialisation et maintenus sur ajout/déplacement/retrait. Tests de cycle de vie hors jeu et SP/MP.

### C07 — Baril déplacé : marque orpheline qui bloque tout nouveau raccordement
- **Problème.**
  - Quand un baril raccordé est ramassé puis reposé ailleurs, la pompe l'oublie après deux contrôles (`LW_Pump.lua:217-238`). La marque `LiveWireBarrel` reste pourtant sur l'objet, si sa ModData suit le ramassage, comme pour un `IsoThumpable` (`shared/LiveWire/LW_Marks.lua:4-6`).
  - Ensuite :
    - `checkBarrelLink` refuse avec « raccordé à une autre pompe » (`LW_Install.lua:374-376`) ;
    - le menu affiche « Raccordé » et propose « Débrancher » (`client/LiveWire/LW_ContextMenu.lua:384-390`), mais le serveur ignore la demande en silence (`LW_Commands.lua:150`) ;
    - `Pump.onLoadChunk` ne nettoie la marque que si la pompe a disparu (`LW_Pump.lua:413-417`).
- **Risque.** Bug et persistance : le baril devient inutilisable pour toute pompe.
- **Correction proposée.**
  - Écrire la position dans la marque (`{ pump, x, y, z }`). Côté serveur, la marque est orpheline si la position ne correspond plus, ou si la pompe ne liste pas cette case.
  - Dans ce cas, l'effacer dans `checkBarrelLink`, `C_UNLINK_BARREL` et `onLoadChunk`. Le client affiche le baril comme libre.
- **Statut.** Mécanisme confirmé statiquement ; conservation de la ModData d'un récupérateur ramassé à vérifier en jeu. **Priorité moyenne, effort S.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Marques positionnelles avec validation de l’appartenance réelle sur l’autorité ; migration des anciennes marques et nettoyage au chargement/à la lecture. Tests sur vrais objets SP/MP ; le transfert vanilla complet du baril entre inventaire et monde n’est pas reproduit par ce scénario.

### C08 — Deux pompes : la règle « la plus proche dessert » n'est pas codée
- **Problème.**
  - Les décisions de la pompe (`docs/annexes/recherches/idees-initiales.md`, tableau « Points tranchés ») disent qu'un point d'eau à portée de deux pompes est desservi par la plus proche.
  - Le code garde le relais de la première pompe qui l'a posé (`LW_Pump.lua:142-153`). L'ordre dépend de l'identifiant (`:340-345`) et de l'ordre des réseaux (`LW_Simulation.lua:571-580`), pas de la distance.
- **Risque.** Écart entre la documentation et le comportement ; maintenabilité.
- **Correction proposée.** Choisir l'une des deux voies :
  - **coder la règle** : quand la source trouvée est le relais d'une autre pompe plus lointaine, réattribuer la marque `RELAY_KEY`, et la retirer de la liste de l'autre pompe au pas suivant ;
  - **documenter** la règle réelle (« la première raccordée »).
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C09 — Le générateur de secours annule la marche ou l'arrêt manuel du joueur
- **Problème.** Tant qu'il est chargé, `Backup.step` impose `setActivated(run)` à chaque sous-pas (`server/LiveWire/LW_Backup.lua:154`), et `Backup.restore` fait de même au chargement (`:192`). Si le joueur éteint le générateur par le menu vanilla, par exemple pour échapper à la toxicité à l'intérieur, le mod le rallume dans les 10 minutes de jeu. Le seul moyen de l'arrêter est de le débrancher.
- **Risque.** Ergonomie, avec un danger réel puisque le générateur est toxique à l'intérieur (D-14).
- **Correction proposée.**
  - Mémoriser `dev.lastSet`. Si `gen:isActivated() ~= dev.lastSet`, le joueur a agi : passer en état `manual`, respecter son choix et l'afficher sur l'écran LCD et dans le logiciel.
  - Proposer « Reprendre le mode automatique » dans le menu du générateur.
- **Statut.** Confirmé statiquement ; à vérifier en jeu. **Priorité moyenne, effort S.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Mode manuel persistant, dernier état physique observé, rapprochement du carburant hors zone préservé ; commande serveur de reprise et menu traduit. Arrêt/allumage manuel, restauration et reprise vérifiés en SP/MP.

### C10 — Écran LCD illisible en chinois, japonais et coréen
- **Problème.**
  - L'écran de l'onduleur et le démarrage de notre écran d'ordinateur dessinent en `UIFont.Code` (`client/LiveWire/LW_InverterPanel.lua:27-29`, `client/LiveWire/LW_SoftwareScreen.lua:93`). C'est `media/fonts/zomboidCode.fnt` dans toutes les langues (`media/fonts/CN/fonts.txt:3-7`).
  - Ce fichier ne contient que 613 caractères, jusqu'au point de code 7929 : latin, cyrillique et vietnamien, aucun idéogramme.
  - Le vanilla tient la liste des langues qu'il ne sert pas en police LCD (`media/lua/client/ISUI/ISLcdBar.lua:8` : CH, CN, JP, KO, RU, TH, UA), et `knowledge/ui-windows.md:96` le note pour `CodeSmall`.
  - Les traductions CN, JP et KO du mod sont livrées, mais l'écran LCD les affiche vides ou en carrés.
- **Risque.** Traduction ; bug visible pour trois langues livrées.
- **Correction proposée.** `lcdFont()` rend `UIFont.Small` (qui a une variante par langue) quand `Translator.getLanguage():name()` est CN, CH, JP, KO ou TH. Vérifier aussi le thaï, que le mod ne livre pas.
- **Statut.** Confirmé statiquement (glyphes de la police) ; rendu à vérifier en jeu. **Priorité haute, effort S.**
- **Avancement : ✅ corrigé, publié en 1.3.2 (commit dc553a5), à vérifier en jeu** — `LiveWire.Client.lcdFont()`, CN, CH, JP, KO, TH.

### C11 — La table publique des ancres expose toutes les bases et leur historique à chaque client
- **Problème.**
  - La ModData globale `LiveWireAnchors` contient la position de chaque onduleur **et** son journal de 16 changements (`server/LiveWire/LW_Registry.lua:246-281`).
  - Elle est diffusée en entier à tous les clients à chaque changement de n'importe quel onduleur (`:279`), et demandée à la connexion (`shared/LiveWire/LW_Anchor.lua:204-208`).
  - Les clients n'utilisent que `x`, `y`, `z` et `on`. Le journal ne sert qu'à l'autorité (`server/LiveWire/LW_FridgeCatchup.lua`).
- **Risque.**
  - MP et vie privée : n'importe quel client peut lire la position de toutes les bases (`knowledge/multiplayer.md` : aucune donnée sensible dans une ModData globale).
  - Bande passante : la table grossit avec le nombre de bases.
- **Correction proposée.** Déplacer `log` et `log0` dans le registre serveur (`data.anchorLogs`), et ne publier que `{x, y, z, on}`. En option, plus tard : envoyer à chaque client seulement les ancres proches, par `sendServerCommand` lors de ses chargements de chunks.
- **Statut.** Confirmé statiquement. **Priorité basse** (serveur entre amis, voir les préférences de l'utilisateur sur l'anti-triche). **Effort** S pour le journal, M pour la diffusion par proximité.
- **Avancement :** ⏸ différé après décision utilisateur du 2026-10-24. La diffusion communautaire est acceptée. Pas d’envoi si état et position restent identiques (100 appels stables vérifiés en SP/MP). Modèle de sérialisation : environ 6 Ko/événement/client pour 10 bases, 62 Ko pour 100 bases, avec 16 changements d’historique. Pas de restriction ajoutée ; étudier le trafic réel si serveur très chargé. Voir [mesures et hypothèses](annexes/tests/c25-validation.md).

### C12 — Le journal d'alimentation est trop court pour une longue absence
- **Problème.**
  - Le journal garde 16 changements (`LW_Registry.lua:246`, `:270-273`). Avec un cycle jour/nuit des batteries (deux bascules par jour), il ne couvre qu'environ 8 jours.
  - Au-delà, `onAt` attribue à toute la période plus ancienne l'état `log0`, qui est seulement l'état juste avant la plus vieille entrée gardée (`LW_FridgeCatchup.lua:29-36`). La nourriture d'un frigo abandonné deux semaines vieillit alors sur une base fausse.
- **Risque.** Persistance ; équilibre de la nourriture.
- **Correction proposée.** Une fois le journal sorti de la table publique (C11), le borner **dans le temps** (par exemple 60 jours de jeu) plutôt qu'en nombre. Fusionner les entrées qu'aucun aliment chargé ne peut plus concerner.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C13 — Erreur de `Pump.maintain` avalée sans trace
- **Problème.** `pcall(LiveWire.Pump.maintain, pumps[p])` ignore son résultat (`LW_Simulation.lua:550`). Toute erreur de pose ou de retrait des relais disparaît, alors que `Pump.tickMinute` journalise les siennes (`LW_Pump.lua:348-349`).
- **Risque.** Maintenabilité : un diagnostic de la pompe en MP sans aucune trace.
- **Correction proposée.** `local ok, err = pcall(...)`, puis `LiveWire.warn(...)` en cas d'échec, comme ailleurs.
- **Statut.** Confirmé statiquement. **Priorité moyenne** (coût quasi nul), **effort S.**
- **Avancement :** ✅ corrigé localement le 2026-10-24, non publié. Les erreurs de maintenance sont journalisées en anglais avec l’identifiant de la pompe ; les autres pompes continuent. Test hors jeu par injection d’erreur et campagnes SP/MP.

### C14 — Constante de version périmée
- **Problème.** `LiveWire.VERSION = "0.1.2"` (`shared/LiveWire/LW_Core.lua:7`) alors que le mod est en 1.3.1.
- **Risque.** Maintenabilité : un journal ou un rapport de bug trompeur.
- **Correction proposée.** Mettre la constante à jour, l'écrire dans le journal au démarrage (`registry ready`), et faire comparer par `tools/check_mod.py` `VERSION` à `modversion` de `mod.info`.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement :** ✅ corrigé localement le 2026-10-24, non publié. `LiveWire.VERSION = "1.4.0"`, journal de démarrage avec version ; `tools/check_mod.py` compare les deux variantes `mod.info` livrées à cette constante.

### C15 — Commandes réseau mortes ou à moitié branchées
- **Problème.**
  - `C_RENAME` a un gestionnaire serveur (`LW_Commands.lua:222-233`), et le logiciel affiche `snap.name` (`LW_SoftwareApp.lua:445-446`), mais aucun client n'envoie la commande.
  - `C_REQUEST_ANCHORS` (`shared/LiveWire/LW_Protocol.lua:19`, `LW_Commands.lua:235-237`), `S_REFUSE` et `S_ANCHORS` (`LW_Protocol.lua:26-27`) ne sont utilisés nulle part.
- **Risque.** Maintenabilité.
- **Correction proposée.** Brancher le renommage (voir I05) et retirer les autres constantes, ou les documenter comme réservées.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement :** ✅ corrigé localement le 2026-10-24, non publié. Renommage par boîte de saisie vanilla depuis le menu de l’onduleur et l’onglet Équipements du logiciel ; commande existante, nom nettoyé et borné à 24 caractères. Contrôle `via` des ordinateurs raccordés, distance et safehouse côté serveur ; nom dans les instantanés et la marque de l’onduleur. Constantes/gestionnaire `C_REQUEST_ANCHORS`, `S_REFUSE`, `S_ANCHORS` inutilisés retirés. Compléments d’affichage de I05 non inclus.

### C16 — En solo, l'instantané est recalculé à chaque image
- **Problème.**
  - En solo, `Client.snapshot` appelle `Sim.snapshot` à chaque appel (`LW_ClientState.lua:37-44`).
  - L'écran LCD l'appelle dans `update` **et** dans `render` (`LW_InverterPanel.lua:101-118`, `:208-210`), et le logiciel de même.
  - `Sim.snapshot` refait `R.members` plusieurs fois, avec des tris (`LW_Simulation.lua:164-251`).
- **Risque.** Performance faible mais permanente tant qu'une fenêtre est ouverte.
- **Correction proposée.** Garder un cache par `(grid.id, grid.rev)` dans `Client.snapshot` côté autorité. `rev` change à chaque pas et à chaque commande.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Cache solo lié à l’identité du registre, du réseau et à sa révision. Réutilisation et invalidation vérifiées hors jeu et en SP.

### C17 — Seuils du générateur de secours non contrôlés
- **Problème.** Les options autorisent un seuil de démarrage supérieur au seuil d'arrêt : démarrage de 0 à 90, arrêt de 10 à 100 (`media/sandbox-options.txt:93-101`). L'hystérésis de `Backup.step` (`LW_Backup.lua:131-139`) se réduit alors à « arrêt au seuil de démarrage », sans message.
- **Risque.** Réglage incohérent et silencieux.
- **Correction proposée.** Calculer `stop = max(stop, start + 5)` dans `Backup.step`, le journaliser une fois, et le préciser dans l'infobulle de l'option.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C18 — Débit de la pompe : réserve accumulée à vide et constante en dur
- **Problème.**
  - Le budget de la pompe augmente **avant** le test « rien à remplir » (`LW_Pump.lua:296-299`). Une pompe au repos accumule donc 10 L, qu'elle déverse d'un coup à la première prise d'eau (deux fois le débit annoncé).
  - Ce plafond de 10 est écrit en dur, à côté de `PUMP_LITRES_PER_MINUTE = 5` (`shared/LiveWire/LW_Defs.lua:109`).
- **Risque.** Équilibrage et maintenabilité, impact faible.
- **Correction proposée.** N'ajouter le budget que lorsqu'il y a un besoin, et définir `Defs.PUMP_BUDGET_MAX`.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C19 — Nettoyage des relais limité aux étages −1 à 7
- **Problème.**
  - `Pump.onLoadChunk` borne les étages à `[-1, 7]` (`LW_Pump.lua:395-396`).
  - Or une pompe peut servir jusqu'à ±`GeneratorVerticalPowerRange` étages et poser ses relais à `z + 1`. Le reste du mod utilise −32 à 31 (`LW_Anchor.lua:67`).
  - Un relais orphelin au sous-sol −2 ou au 9ᵉ étage n'est jamais retiré.
- **Risque.** Persistance (cas rare).
- **Correction proposée.** Utiliser `chunk:getMinLevel()` et `chunk:getMaxLevel()` sans autre borne.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C20 — Bruit pour les zombies : une seule impulsion par pas
- **Problème.**
  - L'onduleur émet `addSound` **une fois par pas de 10 minutes de jeu** (`LW_Simulation.lua:534-547`), la pompe une fois par minute (`LW_Pump.lua:329-330`).
  - D-8 annonce « zombies : rayon 2 », mais l'impulsion décennale de l'onduleur n'a probablement presque aucun effet. Le bruit de la pompe est, lui, 10 fois plus fréquent.
- **Risque.** Écart entre l'intention et l'effet ; équilibrage.
- **Correction proposée.** Choisir l'une des deux voies :
  - émettre le bruit de l'onduleur chaque minute de jeu (sur `EveryOneMinute`, pour les onduleurs chargés en marche) ;
  - documenter que le bruit est volontairement négligeable.
- **Statut.** Confirmé statiquement ; effet réel sur les zombies à vérifier en jeu. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C21 — Pas « tout ou rien » quand le stock ne couvre pas le pas
- **Problème.**
  - Si l'énergie manquante d'un sous-pas dépasse le stock, la maison est coupée **pour tout le sous-pas**, et le reste des batteries n'est pas utilisé (`shared/LiveWire/LW_Physics.lua:167-187`).
  - Le redémarrage exige ensuite plus de 2 % de stock et un besoin couvert.
  - Pendant un rattrapage sans joueur, le sous-pas dure 1 h : la coupure peut survenir avec presque une heure d'énergie en réserve.
- **Risque.** Équilibrage : une coupure perçue comme prématurée, sur l'écran comme au retour.
- **Correction proposée.** Servir une fraction du pas (`on` pendant `stock / besoin` du sous-pas), puis couper. Retenir la fraction pour l'historique.
- **Statut.** Confirmé statiquement. **Priorité basse, effort M** (tests hors jeu à étendre).
- **Avancement : ⬜ à faire.**

### C22 — Inspecter et déneiger sans contrôle de safehouse ; frein de l'éolienne définitif
- **Problème.**
  - `LWInspectAction:complete` et `LWClearSnowAction:complete` n'appellent pas `allowed()` (`shared/LiveWire/TimedActions/LW_TimedActions.lua:451-475`, `:596-603`), contrairement aux autres actions.
  - L'inspection d'une éolienne au niveau 7 pose `dev.brake = true` pour toujours (`:458-460`), sans moyen de le retirer.
- **Risque.** Faible en MP ; ergonomie.
- **Correction proposée.** Ajouter `allowed()`. Transformer le frein en interrupteur explicite (voir I14).
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ✅ corrigé localement le 2026-10-24, non publié.** Inspection sans effet sur le frein, commandes explicites réversibles de niveau 7, production et rotation bloquées par le frein. Contrôles safehouse à la fin des actions ; refus vérifiés avec un vrai client MP non administrateur.

### C23 — Tables en mémoire jamais purgées ; expérience du testeur exploitable
- **Problème.**
  - `rate` (`LW_Commands.lua:15`) et `Xp.cooldowns` (`server/LiveWire/LW_Xp.lua:11`) grossissent pendant toute la vie du serveur.
  - La mesure crée une clé par case (`LW_TimedActions.lua:701`). Mesurer des cases différentes donne 1 XP chacune, sans limite globale.
- **Risque.** Mémoire (faible) ; expérience trop facile à obtenir.
- **Correction proposée.** Purger les entrées de plus de 24 h de jeu une fois par heure de jeu. Limiter l'expérience de mesure par joueur (par exemple 5 XP par heure de jeu, toutes cases confondues).
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : 🟡 en partie le 2026-10-24, non publié.** Purge horaire des entrées mémoire périmées ; les délais encore actifs sont conservés. Le plafond global d’expérience du testeur reste à faire (hors du périmètre performances).

### C24 — Adoption de tuiles et marques réécrites par un client
- **Problème.**
  - `C_ADOPT` permet à tout client à 40 cases d'inscrire une tuile non liée. Le rendement d'installation vient alors **du niveau de ce client** (`LW_Commands.lua:242-254`, `server/LiveWire/LW_Devices.lua:146-152`).
  - Un client peut réécrire la ModData d'un objet (`LW_Marks.lua:7`). `Devices.validate` retire alors du registre un appareil dont la marque a disparu (`LW_Devices.lua:265-271`).
- **Risque.** MP, nuisance volontaire. Faible sur un serveur entre amis.
- **Correction proposée.**
  - Rendement fixe de 0,85 pour une tuile adoptée.
  - Avant de supprimer, vérifier sur l'autorité que la **tuile** (sprite) a disparu, pas seulement la marque. Si la tuile est encore là, réécrire la marque depuis le registre.
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement : ⬜ à faire.**

### C25 — Tests pompe, relais, couplage et persistance SP/MP
- **Problème.**
  - Le crochet `autotest/lw_hooks.lua` ne mentionne ni la pompe, ni les relais, ni le couplage (0 occurrence de « pump » ou « relay »).
  - Le protocole manuel (`docs/annexes/tests/protocole-tests.md`) n'a pas de section pompe ni onduleurs couplés.
  - `autotest.json` ne définit qu'un scénario `sp`.
  - Les tests hors jeu couvrent seulement `Pump.demandW` et la capacité des esclaves (`tests/test_simulation.py:430-460`).
  - Le prototype P-pompe exigé par les décisions de la 1.2.0 n'a pas été fait. Il comprend : relais créé sur une case `z + 1` neuve, relais vu par un client MP, sauvegarde, invisibilité.
- **Risque.** Fonctions publiées non testées en jeu (1.2.0 et 1.3.0, d'après le CHANGELOG et les décisions).
- **Correction proposée.**
  - Ajouter au crochet un scénario pompe : poser, raccorder un récupérateur, vérifier le relais, tirer de l'eau, ramasser, puis exécuter C01.
  - Ajouter un scénario couplage : coupler, découpler, retirer le maître.
  - Ajouter une section `mp` à `autotest.json` (serveur et deux clients, l'un non admin), sur le modèle des autres mods de l'utilisateur.
- **Statut.** Confirmé statiquement. **Priorité haute, effort M.**
- **Avancement :** ✅ terminé le 2026-10-24 (`b242a36`, outil hors mod). Création sur case z+1 neuve, persistance de 7,25 L/25 L et de la marque après vrais redémarrages, invisibilité du sprite chargé, retrait C01 en zone chargée puis réellement déchargée, nettoyage au retour et absence de recréation après le dernier redémarrage. Trois phases SP et trois phases MP réussies ; serveur dédié et deux clients, assertions sur chacun. Droits ordinaires couverts par la campagne ciblée distincte. [Protocole, résultats et limites](annexes/tests/c25-validation.md).

### C26 — README : limite des frigos dépassée par la 1.0.1
- **Problème.** `README.md:53` dit encore que l'état trouvé au retour vaut pour toute l'absence. Or la 1.0.1 rejoue l'absence d'après le journal des ancres (`CHANGELOG.md`, 1.0.1 ; `LW_FridgeCatchup.lua`).
- **Risque.** Documentation joueur fausse (la même phrase existe probablement dans les autres README).
- **Correction proposée.** Reformuler, à faire après la réorganisation de la documentation en cours : « l'absence est rejouée d'après les 16 derniers changements de courant » (voir C12).
- **Statut.** Confirmé statiquement. **Priorité basse, effort S.**
- **Avancement :** ✅ corrigé localement le 2026-10-24, non publié (`21cc584`). README anglais et français : rattrapage depuis les 16 derniers changements d’alimentation par onduleur, limite pour une absence dépassant cet historique.

---

## Partie 2 — Idées de fonctionnalités

Les idées déjà retenues (chargeur de piles, clôture électrifiée, installations abandonnées : `docs/annexes/recherches/idees-initiales.md`, idées 1, 3 et 4) et les idées **écartées** n'y sont pas reprises. Les idées écartées sont : capteurs et projecteurs, dynamo à pédales, voiture raccordée, ligne aérienne, pannes à diagnostiquer, alerte radio, priorités de charge, parafoudre, programmateur, régulateur et onduleur renforcé. I19 et I20 approfondissent deux points déjà prévus dans `docs/specifications-fonctionnelles.md`, § 9 et § 8.2. Aucune idée ne crée un second modèle d'onduleur (D-17).

### I01 — « Afficher les consommateurs » : la carte de charge de la maison
- **Description.** Une option du menu de l'onduleur surligne les appareils comptés dans sa demande, coloré selon leur puissance : vert sous 50 W, orange jusqu'à 300 W, rouge au-delà. Les appareils comptés par un autre onduleur, plus proche, sont gris. Un survol indique « Congélateur : 130 W ».
- **Intérêt joueur.** Le plafond de 1 500 W est la première frustration (question Workshop à l'origine des onduleurs couplés). Le joueur voit tout de suite ce qui consomme.
- **Faisabilité moteur.**
  - Le serveur connaît déjà la liste (`Demand.inventories[id].objects`) et la règle de comptage (`LW_Demand.lua:178-233`). Une commande `C_LOADMAP` rend les positions et les puissances, une fois, au plus à 30 cases.
  - Le client surligne avec `setHighlighted` et `setHighlightColor`, comme `LW_PumpView.lua:132-141`.
- **Impact MP.** Une commande ponctuelle, limitée en débit ; aucune donnée d'un autre réseau n'est envoyée.
- **Dépendances.** C04, pour ne pas reproduire le balayage synchrone côté client.
- **Effort.** M.
- **Avancement : ⬜ proposée.**

### I02 — « Afficher les raccordements » : le câblage du réseau
- **Description.** Des lignes dessinées au sol de l'onduleur vers chaque source, powerbank, option, pompe ou ordinateur raccordé, avec une couleur par rôle, et en pointillé quand l'appareil est sur un autre étage.
- **Intérêt joueur.** Répond à « à quel onduleur est branché ce panneau ? » sans cliquer appareil par appareil. Prépare aussi les câbles visibles prévus « après les modèles définitifs ».
- **Faisabilité moteur.**
  - Les positions sont dans les marques (`x`, `y`, `z`, `inv`), déjà reçues par le client.
  - Le tracé reprend `RangeView` : un élément de 1 × 1 qui projette par `isoToScreenX/Y` (`client/LiveWire/LW_RangeView.lua:39-64`).
- **Impact MP.** Aucun : affichage local, à partir de données déjà envoyées.
- **Dépendances.** Aucune.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I03 — Prévision de production sur trois jours
- **Description.** Un onglet « Prévisions » du logiciel montre, pour aujourd'hui, demain et après-demain, la production attendue en kWh par famille (solaire d'après les nuages, éolien d'après le vent). Il compare cette production à la consommation moyenne des 48 dernières heures et conclut : « réserve suffisante », « prévoir le générateur ».
- **Intérêt joueur.** Valorise l'ordinateur de gestion (Électricité 6) et l'éolienne. Donne une vraie décision : faire le plein du générateur de secours avant trois jours sans vent.
- **Faisabilité moteur.**
  - `getClimateManager():getClimateForecaster():getForecast(offset)` est exposé à Lua (`index-lua-exposed-classes.txt:129-131`). `DayForecast:getCloudiness()` et `getWindPower()` rendent des `ForecastValue` (`java/zombie/iso/weather/ClimateForecaster.java:30`, `:269-275`). C'est la même source que la météo radio vanilla.
  - Le calcul réutilise `Physics.solarCurveMean`, `windFactor` et le rendement des sources du réseau.
- **Impact MP.** Calcul sur le serveur, ajouté à l'instantané seulement quand l'ordinateur est alimenté (comme `history`).
- **Dépendances.** Ordinateur de gestion raccordé.
- **Effort.** M.
- **Avancement : ⬜ proposée.**

### I04 — Journal des événements du réseau
- **Description.** L'onglet Historique du logiciel ajoute une liste horodatée des 30 derniers événements : disjonction de l'onduleur ou du disjoncteur, réarmement, batterie faible, démarrage et arrêt du générateur, délestage, appareil hors service, couplage. L'écran LCD montre le dernier sur sa page État.
- **Intérêt joueur.** Comprendre au retour d'expédition pourquoi le congélateur a décongelé (« 03:10 batterie vide, 06:40 retour du solaire »).
- **Faisabilité moteur.**
  - Les événements sont déjà repérés sur l'autorité : `notifyNear` dans `LW_Simulation.lua:452-491`, `LW_Alarm.lua`, `LW_Backup.lua:37-50`, `LW_Computer.lua:95-114`.
  - Il suffit d'ajouter `grid.events[#+1] = { t, key, args }` borné. Clés traduites côté client, comme les notifications.
- **Impact MP.** Quelques dizaines d'octets dans l'instantané des abonnés.
- **Dépendances.** Aucune.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I05 — Nommer son réseau
- **Description.** « Renommer le réseau » dans le menu de l'onduleur et dans l'en-tête du logiciel, avec une saisie de 24 caractères au plus. Le nom apparaît sur l'écran LCD, dans le logiciel, à l'inspection et dans les messages d'alarme (« Batterie faible — Chalet nord »).
- **Intérêt joueur.** Distingue plusieurs installations (base et avant-poste), surtout en MP.
- **Faisabilité moteur.**
  - Le serveur sait déjà renommer et nettoyer le nom (`LW_Commands.lua:222-233`, `LW_Protocol.lua:cleanName`).
  - Il ne manque qu'un `ISTextBox` côté client. Voir `knowledge/ui-windows.md` : `maxChars`, `noEmpty`, manette.
- **Impact MP.** Aucun nouveau paquet hors la commande existante.
- **Dépendances.** C15.
- **Effort.** S.
- **Avancement : 🟡 en partie, non publié (2026-10-24).** Renommage par menu et onglet Équipements du logiciel, nom affiché dans le logiciel ; affichages LCD, inspection et messages d’alarme non réalisés.

### I06 — Compteurs cumulés et « carburant économisé »
- **Description.** Chaque source compte ses kWh produits depuis sa pose, et chaque réseau ses kWh consommés, perdus (batteries pleines) et fournis par le générateur de secours. Le logiciel affiche aussi l'équivalent en litres d'essence qu'aurait brûlés un générateur vanilla pour la même consommation.
- **Intérêt joueur.** Récompense visible du travail d'électricien. Aide à choisir entre une éolienne de plus et une batterie de plus, d'après les kWh perdus.
- **Faisabilité moteur.**
  - Il suffit d'accumuler dans `Sim.stepGrid` (`r.lostKWh`, `prodW × h`, `backupW × h`).
  - L'équivalent essence suit la règle vanilla : consommation horaire égale à la somme des `getGeneratorPowerConsumption` et à `GeneratorFuelConsumption`. Le mod mesure déjà cette somme (`Demand.measure`).
  - Les compteurs vivent dans le registre et suivent l'appareil ramassé par sa marque.
- **Impact MP.** Quelques nombres en plus dans l'instantané.
- **Dépendances.** Aucune.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I07 — Orientation des panneaux solaires
- **Description.** La rotation du panneau, déjà possible avec le curseur vanilla, compte :
  - plein sud : rendement nominal ;
  - est ou ouest : courbe décalée vers le matin ou le soir, 85 % ;
  - nord : 55 %.

  L'infobulle de pose et l'inspection indiquent l'orientation.
- **Intérêt joueur.** Un choix simple et réaliste à la pose. Les panneaux orientés est et ouest lissent la production sur la journée.
- **Faisabilité moteur.**
  - L'orientation se lit sans nouvelle donnée : `index de sprite − def.tile` (0 à 3, `client/LiveWire/LW_Visuals.lua:167`).
  - Dans `Physics.solarCurveMean`, décaler le pic de ±2 h et appliquer un facteur. L'axe nord-sud du jeu est connu : nord = y décroissant (`knowledge/api-42-21.md`).
- **Impact MP.** Aucun : calcul serveur.
- **Dépendances.** Nouvelle option sandbox `SolarOrientation` (vrai par défaut) pour les parties existantes.
- **Effort.** S-M.
- **Avancement : ⬜ proposée.**

### I08 — Ombre des arbres et des bâtiments
- **Description.** Un panneau sous ou juste au sud d'un arbre, ou au pied d'un mur plus haut, perd une part de sa production. Le message de pose prévient : « Ombragé par un arbre : −40 % ».
- **Intérêt joueur.** Pousse à poser les panneaux sur le toit ou dans un champ dégagé, à abattre un arbre (lien avec la hache). Limite le « champ de panneaux dans la forêt ».
- **Faisabilité moteur.**
  - `IsoGridSquare:HasTree()` et `getTree()` (`java/zombie/iso/IsoGridSquare.java:2352-2358`) sur 1 à 3 cases au sud et à l'est ou l'ouest.
  - Un objet `solid` ou un étage `z + 1` existant au sud pour les bâtiments.
  - Calcul fait à la pose et une fois par jour de jeu sur les panneaux chargés, gardé dans `src.shade`. Le panneau non chargé garde la dernière valeur.
- **Impact MP.** Aucun.
- **Dépendances.** I07 conseillé (même passage dans `sourceRaw`). Le risque R-9 (`isOutside()` sous un arbre) est à revoir en même temps.
- **Effort.** M.
- **Avancement : ⬜ proposée.**

### I09 — Encrassement et nettoyage des panneaux
- **Description.** La production d'un panneau baisse lentement avec la poussière, et plus vite en automne (feuilles) ou après un incendie proche. « Nettoyer le panneau » avec un chiffon et un peu d'eau rend le rendement. L'action « Déneiger » devient « Nettoyer », et la neige compte comme une salissure.
- **Intérêt joueur.** Un entretien léger et régulier, cohérent avec l'usure, qui donne une raison de revenir à la base. Le gain d'expérience est limité par jour, comme pour l'inspection.
- **Faisabilité moteur.**
  - Champ `src.dirt` à côté de `src.snow` (`LW_Simulation.lua:75-81`).
  - Action calquée sur `LWClearSnowAction`, eau retirée comme dans `LWReconditionAction` (`adjustSpecificFluidAmount`, `LW_TimedActions.lua:775-777`).
  - Le chiffon est un objet vanilla (bandes de tissu `Base.RippedSheets`, à vérifier dans les scripts 42.21).
  - La pluie nettoie partiellement (`getClimateManager():getRainIntensity()`).
- **Impact MP.** Aucun, en dehors de l'action chronométrée.
- **Dépendances.** Option sandbox pour la désactiver.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I10 — Batteries et froid
- **Description.** Une powerbank posée **dehors** perd de la capacité utile par grand froid : −20 % à 0 °C, −40 % à −15 °C. La charge reste intacte et la capacité revient au dégel. Une powerbank à l'intérieur n'est pas touchée.
- **Intérêt joueur.** Récompense l'installation dans un abri ou une cave. Donne une raison de plus à l'hiver, qui coupe déjà le solaire, de rendre l'autonomie difficile.
- **Faisabilité moteur.**
  - La simulation lit déjà `getClimateManager():getTemperature()` (`LW_Simulation.lua:29`). Retenir `bank.outside = sq:isOutside()` à la pose et à chaque chargement.
  - Appliquer le facteur dans `Batteries.capacity` pour les entrées de cette powerbank, sans toucher à l'état de la batterie.
- **Impact MP.** Aucun.
- **Dépendances.** Option sandbox (désactivée par défaut, pour ne pas changer l'équilibre des parties existantes).
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I11 — Tester une batterie au testeur de tension
- **Description.** Clic droit sur une batterie de l'inventaire > « Tester la batterie ». Le message dépend du niveau :
  - niveau 1 : charge en % ;
  - niveau 3 : kWh et capacité réelle ;
  - niveau 5 : cycles effectués et durée de vie restante estimée.
- **Intérêt joueur.** Choisir les bonnes batteries à ranger dans la powerbank, et savoir quand reconditionner. Aujourd'hui, les cycles (`LiveWireCycles`) ne sont visibles nulle part.
- **Faisabilité moteur.**
  - Action chronométrée courte. Sa `complete()` sur l'autorité lit `getCurrentUsesFloat`, `getCondition` et la ModData des cycles, qui reste sur le serveur (`server/LiveWire/LW_Batteries.lua:9`), puis envoie une notification traduite côté client.
  - Ce choix évite d'envelopper `ISToolTipInv:render`, qu'interdit `developpement.md` (aucun crochet de rendu par image).
- **Impact MP.** Une notification.
- **Dépendances.** Aucune.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I12 — Recycler les batteries mortes
- **Description.** Une batterie à 0 % d'état n'est aujourd'hui qu'un déchet (capacité nulle, `Physics.batteryCapacity`). Une recette d'Électricité 5 « Récupérer les plaques » donne de la ferraille et un « bloc de plaques ». Deux blocs, de l'eau et un boîtier de batterie usagé donnent une batterie à décharge profonde reconstruite à 30-40 %.
- **Intérêt joueur.** Boucle de fin de partie : l'usure des batteries devient une ressource à gérer, plus un mur.
- **Faisabilité moteur.**
  - `craftRecipe` avec `OnCreate`, sur le modèle de `LiveWire.Recipes.onDeepCycleBattery` (`shared/LiveWire/LW_Recipes.lua`).
  - Filtrer l'entrée par état : `OnTest` ou tag ; voir `knowledge/api-42-21.md`, « craftRecipe (tags, OnTest, OnCreate) ».
- **Impact MP.** Aucun : recette vanilla, `OnCreate` sur le serveur.
- **Dépendances.** Nouvel objet intermédiaire (traductions, icône).
- **Effort.** S-M.
- **Avancement : ⬜ proposée.**

### I13 — Démonter un équipement hors service pour ses pièces
- **Description.** Un équipement à 0 % qu'on ne peut pas réviser (niveau 8 exigé, `LW_TimedActions.lua:328`) peut être « démonté pour pièces » dès le niveau 3. Il donne des déchets électroniques, du fil, et des cellules pour un panneau. L'équipement est détruit.
- **Intérêt joueur.** Une voie de recyclage avant le niveau 8. La valeur des installations abandonnées (idée retenue n° 4) augmente aussi.
- **Faisabilité moteur.**
  - Action chronométrée sur l'autorité : `transmitRemoveItemFromSquare`, `Devices.remove`, `Install.giveItem`.
  - Les gardes vanilla du démontage restent en place (`shared/LiveWire/LW_VanillaGuards.lua`). Seule cette action du mod est autorisée.
- **Impact MP.** Une action chronométrée, revérifiée dans `complete()`.
- **Dépendances.** Aucune.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I14 — Frein manuel de l'éolienne
- **Description.** « Serrer le frein » et « Desserrer le frein » dans le menu de l'éolienne, dès le niveau 7. Frein serré : production nulle et aucun dégât de tempête. Une alerte d'orage peut rappeler de le serrer. Le voyant vert de l'éolienne clignote tant que le frein est serré.
- **Intérêt joueur.** Remplace le frein implicite et définitif posé par l'inspection (C22) par un choix clair.
- **Faisabilité moteur.** Le champ `dev.brake` existe déjà (`LW_Simulation.lua:85-86`). Il faut une commande, l'état dans la marque et un calque existant.
- **Impact MP.** Une commande de plus, revérifiée (distance, safehouse).
- **Dépendances.** C22.
- **Effort.** S.
- **Avancement : 🟡 en partie, non publié (2026-10-24).** Commandes explicites, niveau 7, frein réversible, arrêt de production et des pales réalisés avec C22 ; alerte d’orage et voyant clignotant non réalisés.

### I15 — Intervention sous tension : risque de décharge
- **Description.** Raccorder, réparer ou débrancher un équipement pendant que l'onduleur est en marche et que la maison est alimentée donne une petite chance de décharge. La chance baisse avec le niveau, et devient nulle au niveau 6 ou si l'onduleur est éteint. Effets : douleur et brûlure légère à la main, objet lâché. L'onduleur, lui, exige déjà d'être éteint pour sa propre réparation (`LW_TimedActions.lua:382-385`).
- **Intérêt joueur.** Donne du sens aux gestes de l'électricien (couper avant d'intervenir) et au niveau d'Électricité, sans pénaliser qui suit la procédure.
- **Faisabilité moteur.**
  - Dégâts appliqués sur l'autorité, partie du corps choisie, puis `sendDamage` / `syncBodyPart` (`knowledge/combat-and-xp.md`, « blesser un joueur par code depuis le serveur » ; `knowledge/multiplayer.md`).
  - Option sandbox, désactivée par défaut.
- **Impact MP.** Dégâts décidés par le serveur, comme le reste.
- **Dépendances.** Aucune.
- **Effort.** S-M.
- **Avancement : ⬜ proposée.**

### I16 — Arroseur de potager branché sur la pompe
- **Description.** Un petit arroseur, nouvelle tuile posée au sol, se raccorde à une pompe comme un baril. Tant que la pompe a du courant et de l'eau, il arrose les plantes vanilla dans un rayon de 2 à 3 cases. La quantité suit le besoin de chaque plante, à raison de 200 ml par dose, prélevés **réellement** dans les barils, comme pour les relais.
- **Intérêt joueur.** Prolonge logiquement la pompe : la base autonome nourrit son potager pendant une expédition.
- **Faisabilité moteur.**
  - `knowledge/food-production.md:17` : `plant:water(nil, doses)` sur le serveur, sans joueur, +10 par dose, eau propre ou croupie acceptée. L'eau est retirée par le script (`FluidContainer`).
  - Les plantes sont lues par le système global de culture du serveur.
  - Consommation : quelques watts par arroseur, en plus des 250 W de la pompe en marche.
- **Impact MP.** Tout sur l'autorité. Synchronisation par le système de culture vanilla.
- **Dépendances.** Pompe ; C03 et C04 avant d'ajouter du travail à la minute.
- **Effort.** M-L.
- **Avancement : ⬜ proposée.**

### I17 — Approvisionnement en fil électrique
- **Description.** Le mod consomme beaucoup de `Base.ElectricWire` : 1 fil pour 4 cases à chaque raccordement, pour la réparation et la révision. Une recette « Récupérer le câblage » d'Électricité 2 tirerait du fil de rallonges, lampes et petits appareils vanilla, et une action lente « Arracher le câblage d'un mur » en tirerait d'une maison sans courant public.
- **Intérêt joueur.** Débloque les grandes installations sans dépendre du seul butin, et rend utiles des objets ignorés.
- **Faisabilité moteur.**
  - `craftRecipe` avec des entrées par tag ou par liste d'objets vanilla. **À vérifier d'abord** : quels objets vanilla 42.21 donnent déjà du fil au démontage, pour ne pas doubler l'existant.
  - L'action murale vérifie `hasGridPower()` (refus avec danger de décharge si le réseau public tourne encore).
- **Impact MP.** Recette ou action chronométrée classique.
- **Dépendances.** I15, si le danger est retenu.
- **Effort.** S.
- **Avancement : ⬜ proposée.**

### I18 — Petite API pour les mods d'extension
- **Description.** Une table publique `LiveWire.API` qui permet à un autre mod :
  - de déclarer une batterie (`registerBattery(fullType, kWh, lifeCycles)`) ;
  - de déclarer une source (`registerSource(model, { kind, nominalW, tile, … })`) ;
  - de connaître l'état d'un réseau en lecture seule (`gridAt(x, y, z)`).
- **Intérêt joueur.** Batteries de mods tiers (lithium, batteries de camion) et appareils de mods comptés proprement, sans modifier Live Wire.
- **Faisabilité moteur.**
  - `Defs.batteries` et `Defs.devices` sont de simples tables (`LW_Defs.lua:19-72`, `:117-122`). `spriteToModel` doit être recalculé à l'enregistrement.
  - Ordre de chargement : `require "LiveWire/LW_Defs"` côté extension. Documenter l'événement de fin d'enregistrement.
- **Impact MP.** Le mod d'extension doit être actif sur le serveur et les clients, comme tout mod.
- **Dépendances.** Documentation développeur ; garde de version (`LiveWire.VERSION`, C14).
- **Effort.** S-M.
- **Avancement : ⬜ proposée.**

### I19 — Bascule automatique avec un générateur vanilla (approfondissement de D-10)
- **Description.** La spécification annonce depuis la 0.1 la bascule de la v0.2 (`docs/specifications-fonctionnelles.md`, § 8.2) : un générateur vanilla **non raccordé** qui tourne dans la zone de l'onduleur ne fait plus payer deux fois. L'onduleur cesse de compter les appareils déjà alimentés par ce générateur, et l'écran affiche « Appoint : générateur vanilla ».
- **Intérêt joueur.** Supprime un piège : aujourd'hui, les deux paient les appareils communs.
- **Faisabilité moteur.**
  - Pendant le travail étalé de `Demand`, retenir les `IsoGenerator` actifs du disque élargi (`isActivated`, `isPoweringSquare` absent en Lua : reproduire la distance et l'étage comme `closerInverter`, `LW_Demand.lua:158-172`).
  - Puis exclure les appareils couverts dans `Demand.measure`. Les générateurs **raccordés** comme secours restent comptés comme aujourd'hui.
- **Impact MP.** Calcul serveur seulement.
- **Dépendances.** Aucune.
- **Effort.** M.
- **Avancement : ⬜ proposée.**

### I20 — Couper l'alarme d'une maison au tableau électrique (approfondissement de I-3)
- **Description.** Prévue en 0.3 (§ 9 de la spécification), non écartée. Un électricien d'Électricité 3, avec testeur et tournevis, peut « Neutraliser l'alarme » d'un bâtiment depuis un mur intérieur. Action longue, bruyante en cas d'échec : l'alarme se déclenche.
- **Intérêt joueur.** Le premier usage concret du niveau 3 hors de sa propre installation ; il facilite l'exploration.
- **Faisabilité moteur.**
  - `BuildingDef:setAlarmed(false)` (notes moteur, NM-15). Le bâtiment se trouve par la pièce de la case (`knowledge/world-placement.md`, « cases du même bâtiment »).
  - La décision se prend sur l'autorité. L'échec déclenche l'alarme vanilla (impossible à arrêter ensuite, `knowledge/world-placement.md`).
- **Impact MP.** Action chronométrée revérifiée. Règles de safehouse.
- **Dépendances.** Aucune.
- **Effort.** S-M.
- **Avancement : ⬜ proposée.**

### Remarques sur les idées déjà retenues
- **Chargeur de piles (idée 1).** Le moteur a déjà une classe `IsoCarBatteryCharger` (`java/zombie/iso/objects/IsoCarBatteryCharger.java`), que `Demand.category` range en `charger`. Vérifier son comportement avec l'ancre : il pourrait recharger les batteries de voiture vanilla sans aucun code. Le chargeur de piles du mod peut en reprendre le principe (consommation lue par `getGeneratorPowerConsumption`) plutôt que d'ajouter une demande à part.
- **Clôture électrifiée (idée 3).** La détection par proximité, côté serveur, devra reprendre l'étalement de `Demand` (C04, C05) pour ne pas ajouter un balayage par minute.
- **Installations abandonnées (idée 4).** I13 (démontage pour pièces) et I12 (recyclage) leur donnent une valeur même quand les équipements trouvés sont hors service.

---

## Partie 3 — Priorisation : les 5 actions les plus rentables

Avancement au 2026-10-23 indiqué devant chaque action.

| Rang | Action | Pourquoi maintenant | Effort | Risque de la correction |
|---|---|---|---|---|
| 1 | ✅ **C02** — commandes et abonnement du logiciel depuis l'ordinateur raccordé | Bug visible dès qu'on utilise l'ordinateur de gestion (Électricité 6), et logiciel muet en MP depuis un autre étage | S-M | Faible : un argument de plus, revérifié par le serveur |
| 2 | ✅ **C01** — vraie procédure de retrait des relais | Le README promet une désinstallation propre que le code ne tient pas ; des objets restent dans les sauvegardes | S | Faible |
| 3 | ✅ **C10** — police de l'écran LCD pour CN, JP et KO | Trois traductions livrées et illisibles sur l'écran principal | S | Très faible |
| 4 | 🟡 **C25 + C03** (C03 fait, C25 en partie) — scénario d'autotest pompe et couplage (SP puis MP), avec la synchro des relais limitée | 1.2.0 et 1.3.0 ne sont pas testées en jeu ; la synchro des relais est le premier coût côté client à mesurer pendant ce test | M | Faible ; le test peut révéler d'autres défauts de la pompe |
| 5 | ⬜ **I04 + I05** — journal des événements et nom du réseau | Gain joueur net pour un code minime : le serveur repère déjà les événements et sait renommer (C15) | S | Très faible |

Corrections presque gratuites encore proposées : C17 (seuils du secours), C19 (étages du nettoyage). C13 et C14 sont réalisés ; C25 est terminé. La priorisation du tableau ci-dessus décrit la revue du 2026-10-23, avant ces campagnes.

---

*Mise à jour du 2026-10-24 : la demande utilisateur autorise la campagne groupée C04, C05, C06, C07, C09, C16, C22 et la mémoire de C23. Ces correctifs sont locaux et non publiés. Les autres propositions restent soumises aux décisions utilisateur. Les constats d’origine sont issus de la lecture du code ; les nouveaux essais et leurs limites sont détaillés dans le [plan de campagne](annexes/plans/correctifs-blocages-performances.md).*

La demande complémentaire du 2026-10-24 autorise C25 puis C13, C14, C26 et C15. C11 est différé selon la préférence communautaire de l’utilisateur ; aucun changement de diffusion n’a été effectué.
