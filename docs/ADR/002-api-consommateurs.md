# ADR-002 — API publique des équipements consommateurs

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-002-API-CONSOMMATEURS` |
| Date de création et de mise à jour | 2026-11-13 (D07 ajoutée le même jour) |
| Statut | Accepté (2026-11-13), noms des fonctions calqués sur le vanilla à la demande de l'utilisateur (`couldBePowered`, `powerConsumption`) |
| Avancement | C1 à C5 codées et testées hors jeu, C6 à valider en jeu ; voir le [plan 002](../ADR-plans/plan-002-api-consommateurs.md) |
| Décideur | l'utilisateur |
| Portée | `batman_LiveWire` (Lua `shared`, `server`), `batman_LiveWireExtended` (adaptateurs estimés), wiki développeurs |
| Documents liés | [plan 002](../ADR-plans/plan-002-api-consommateurs.md), [`decisions.md`](../decisions.md) (D-31, D-35, D-38, D-47, D-53), [`specifications-techniques.md`](../specifications-techniques.md) (API), [wiki développeurs](../wiki/en/15-developers.md) |
| Références | `shared/LiveWire/LW_API.lua` (révision 5), `LW_Consumption.lua`, `LW_ApplianceFamilies.lua`, `LW_Appliances.lua`, `server/LiveWire/LW_Demand.lua`, `LW_Circuits.lua`, `LW_CircuitProvider.lua` ; Extended `LWX_CircuitProvider.lua`, `Adapters/LWX_AdapterMtir.lua`, `LWX_AdapterFa2.lua` |
| Origine | demande de l'utilisateur du 2026-11-13 : « il faut ajouter une API publique pour les équipements qui consomment » |

## Contexte

Live Wire détecte automatiquement tout appareil que **le jeu lui-même** sait électrique : il reproduit la règle du
générateur vanilla, qui interroge chaque objet de sa zone (`couldBePoweredByGenerator()`, `LW_Demand.lua`, `collect`)
et lui demande sa consommation (`getGeneratorPowerConsumption()`, `LW_Consumption.lua:83`). Frigos, cuisinières,
lampes, télés, lave-linge, et les appareils de mods construits sur ces objets vanilla, sont donc trouvés et facturés
sans rien faire.

Un appareil dont l'électricité est **entièrement gérée en Lua par son mod** est invisible : le mod vérifie lui-même
que la case a du courant, mais le jeu ne sait pas que l'objet consomme et répond 0. Un générateur vanilla ne brûle pas
plus d'essence pour lui, et Live Wire ne le facture pas non plus. Exemple : la machine à coudre électrique de My Tailor
Is Rich. Confirmé statiquement.

Le seul moyen actuel de le facturer est `CircuitProvider.extraWatts`, point d'extension **à inscrit unique** occupé par
LiveWire Extended, qui ne connaît que deux mods écrits en dur (`LWX_AdapterMtir.lua`, `LWX_AdapterFa2.lua`) et
seulement pour les appareils raccordés à un de ses tableaux. Un auteur de mod ne peut rien déclarer lui-même, et sans
Extended rien n'est facturé. `API.estimateWatts` et `API.watts` existent mais ne servent qu'à lire.

Premier usage concret prévu : la pompe à eau, qui sortira de Live Wire vers le mod frère LiveWater et devra tirer son
courant de Live Wire comme n'importe quel appareil tiers, par cette API, sans code de pompe dans la base.

Un auteur d'appareil a besoin de quatre choses : **déclarer** son appareil et sa consommation, que Live Wire le
**facture** comme un appareil vanilla (onglets, « Afficher les consommateurs », coupures), **savoir** s'il a du
courant pour arrêter sa machine, et **montrer** ses données dans le logiciel de gestion (demande de l'utilisateur du
2026-11-13 : « avec ou sans le Computer Mod »).

## Décisions

- **D01 — Inscription.** `LiveWire.API.registerConsumer(id, definition)`, dans `shared`, appelée au chargement des
  fichiers Lua et refusée après `OnInitGlobalModData` (`registration_closed`, même scellé que `registerSource`).
  `definition` :
  - `sprites` (obligatoire) : tableau de noms de sprites exacts, indexé par nom. **Aucun abonnement à `OnTick` ni à un
    autre événement périodique n'est ajouté** (choix de l'utilisateur, 2026-11-13, option A) : les appareils inscrits
    sont trouvés par le recensement existant de la demande (`LW_Demand.lua`, qui ne travaille que lorsqu'une zone est à
    refaire), au prix d'une recherche dans cette table par objet déjà visité. Aucune fonction d'un autre mod n'est
    appelée sur un objet qui n'est pas un des siens. Option écartée : déclaration par le mod à la pose et au retrait
    (aucune recherche, mais appareils oubliés au rechargement et charge reportée sur chaque auteur) ;
  - `powerConsumption(o)` (obligatoire) : consommation **en marche** en W, 0 à l'arrêt, avant les réglages sandbox ; Live Wire
    applique `PowerScale` et le facteur du profil (`Consumption.estimate`), comme pour toute charge estimée ;
  - `couldBePowered(o)` (facultatif) : affine la reconnaissance quand un sprite est partagé ;
  - `category` (facultatif, défaut `"other"`) : famille affichée par l'interface de l'onduleur, parmi les catégories
    existantes ou `"other"` ;
  - `circuit` (facultatif, défaut `"equipment"`) : `"light"` ou `"equipment"`, circuit du panneau qui le coupe (I21) ;
  - `display(o)` (facultatif) : données affichées par le logiciel de gestion (D07).
  Retours : `true`, ou `false` et `invalid_definition`, `duplicate_consumer`, `duplicate_sprite`, `registration_closed`.
  La définition est recopiée champ par champ (liste blanche), comme `registerSource`.
- **D02 — Facturation identique au vanilla.** La demande liste les objets reconnus par un consommateur inscrit en plus
  des objets du moteur ; `Consumption.watts` consulte d'abord le consommateur inscrit (sa valeur **remplace** celle du
  moteur : jamais deux factures pour un objet). Mêmes filtres que le vanilla : case alimentée, extérieur selon la règle
  du moteur, onduleur le plus proche, réseau public listé mais non facturé (D-63). Un meuble de plusieurs cases n'est
  compté qu'une fois : l'auteur ne nomme que le sprite d'une pièce, ou `couldBePowered` n'en accepte qu'une (règle de D-31
  à la charge de l'auteur, documentée).
- **D03 — Coupure publiée, jamais appliquée.** Un consommateur inscrit devient une famille d'appareil (`kind`
  `"consumer"`, sans étape d'activation) : les circuits du panneau et le fournisseur de circuits (Extended) le coupent
  comme les autres, la décision est enregistrée et synchronisée comme celle d'un appareil vanilla. Live Wire ne touche
  jamais l'état propre de l'appareil : il ne fait que facturer 0 W tant qu'il est coupé.
- **D04 — Question d'état.** `LiveWire.API.consumerPowered(obj)`, des deux côtés : vrai quand l'objet a du courant
  (`ItemContainer.isObjectPowered(obj, true)` : Live Wire, générateur ou réseau public) et que l'appareil n'est pas coupé. L'auteur l'interroge au moment
  d'utiliser sa machine, comme le fait déjà My Tailor Is Rich ; **pas de rappel** en v1 (aucun usage concret).
  `LiveWire.API.consumer(obj)` rend l'`id` du consommateur inscrit qui reconnaît `obj`, ou `nil`.
- **D05 — Pas de double compte avec Extended.** Un adaptateur estimé d'Extended (`estimated = true`) ignore un objet
  qu'un consommateur inscrit reconnaît (`API.consumer`) : la base le facture déjà. Les adaptateurs MTIR et FA2 restent
  tant que ces mods ne s'inscrivent pas eux-mêmes.
- **D07 — Données de l'appareil dans le logiciel de gestion** (demande de l'utilisateur, 2026-11-13). La fonction
  facultative `display(o)` est appelée **sur l'autorité**, seulement quand l'instantané d'un réseau est construit
  (`Sim.snapshot` → `Demand.consumers`, déjà borné à 200 lignes) et seulement pour les objets inscrits qu'il liste :
  aucun événement ni tick de plus. L'instantané est construit quand un joueur ouvre l'écran d'un onduleur, puis à chaque
  pas de simulation (10 minutes de jeu) tant qu'il reste abonné et proche, et lors d'un appel à `API.gridAt` ou d'une
  inspection d'appareil. Elle rend
  `{ name = "<clé>", lines = { { "<clé>", arg1, ... }, ... } }`. Live Wire n'en garde qu'une copie de primitives
  (clés de traduction `[%w_]+` de 64 caractères au plus, 4 lignes au plus, 4 arguments par ligne, chaînes de
  32 caractères au plus ou nombres), jointe à la ligne de l'appareil dans l'instantané. Le **client** traduit avec
  `getText` (les traductions du mod tiers sont chargées par le client, pas toujours par un serveur dédié) : le nom
  remplace la famille dans l'onglet « Consommateurs » et les lignes s'affichent dessous, en retrait. Le même
  `LW_SoftwareApp` est dessiné par l'écran de l'ordinateur Live Wire et dans la fenêtre du Computer Mod
  (`LW_ComputerMod.lua`) : l'affichage est donc identique avec ou sans ce mod. Une réponse invalide est ignorée
  (ligne affichée comme aujourd'hui) ; une erreur de la fonction remonte telle quelle.
- **D08 — Résumé par réseau dans l'onglet Équipements** (demande de la session LiveWater, transmise par
  l'utilisateur le 2026-11-13 : tout ce que LiveWater affiche dans le logiciel passe par l'API de Live Wire). Aujourd'hui
  l'onglet Équipements montre un total des pompes par réseau (`LW_Simulation.lua`, `snap.pumps`) ; la pompe passée dans
  LiveWater le perdrait. Fonction facultative `definition.summary(objects)`, appelée **sur l'autorité** au même moment
  que `display` (construction de l'instantané d'un réseau), **une fois par consommateur inscrit** qui a au moins un
  objet desservi par le réseau. `objects` est un nouveau tableau des objets posés de ce consommateur que les onduleurs
  du réseau desservent : zone du maître, plus celle de chaque onduleur couplé en service quand un add-on la leur laisse
  (même périmètre que la facture, `Demand.measureGrid`), appareils à l'arrêt compris, ceux du réseau public exclus. Même
  format et mêmes règles de copie que `display`, **2 lignes au plus**. Affiché dans l'onglet Équipements, sous les
  équipements Live Wire, dans l'ordre d'inscription des consommateurs ; même rendu sur l'écran Live Wire et dans le
  Computer Mod. Réponse invalide ou `nil` : rien n'est affiché pour ce consommateur. La ligne des pompes Live Wire reste
  tant que la pompe est dans la base.
- **D06 — Version et documentation.** `API.revision = 6` (ajout compatible, `version` inchangée). Tableau de l'API dans
  `specifications-techniques.md`, exemple complet dans le wiki développeurs (`15-developers.md`, EN et FR), nouvelle
  décision D-66 dans `decisions.md`.

## Contrat de l'API (révision 6)

Référence à transmettre à l'auteur d'un mod consommateur (LiveWater compris). Toutes les fonctions sont dans
`LiveWire.API` (`shared/LiveWire/LW_API.lua` de `batman_LiveWire`). État : tout ce qui suit est codé et testé hors jeu
(C1 à C5 et C7) ; rien n'est encore validé en jeu.

### Détecter Live Wire

```lua
local API = LiveWire and LiveWire.API
local hasConsumers = API and (API.revision or 0) >= 6 and API.registerConsumer ~= nil
```

`require=\batman_LiveWire` dans `mod.info` n'est utile que si le mod ne fonctionne pas sans Live Wire. Sinon, tester
comme ci-dessus et ne rien inscrire.

### `API.registerConsumer(id, definition)` → `true` | `false, raison`

Côté : **shared** (serveur et clients doivent inscrire la même chose). Moment : au chargement des fichiers Lua ou dans
`Events.OnInitWorld`, **avant** `OnInitGlobalModData` ; après, la réponse est `false, "registration_closed"`.

| Argument | Type | Obligatoire | Règle |
|---|---|---|---|
| `id` | chaîne | oui | `^[%a][%w_]*$`, 64 caractères au plus, unique (`"LiveWaterPump"`) |
| `definition.sprites` | tableau de chaînes | oui | noms exacts des sprites (`"mymod_tiles_01_0"`), 1 à 256, sans doublon, 128 caractères au plus chacun ; un sprite n'appartient qu'à un seul consommateur. Meuble de plusieurs cases : ne nommer que le sprite d'**une** pièce, sinon il est compté plusieurs fois |
| `definition.powerConsumption` | `function(o) -> nombre` | oui | consommation en W **pendant que l'appareil tourne**, 0 à l'arrêt. Live Wire y applique `PowerScale` et le facteur du profil de consommation. Une valeur non numérique, négative ou NaN compte 0 |
| `definition.couldBePowered` | `function(o) -> booléen` | non | appelée seulement pour un objet dont le sprite est inscrit ; `true` = c'est bien l'appareil (utile quand un sprite sert aussi à une version non électrique) |
| `definition.category` | chaîne | non | famille affichée : `"light"`, `"tv"`, `"radio"`, `"stove"`, `"laundry"`, `"charger"`, `"fridge"` ou `"other"` (défaut) |
| `definition.circuit` | chaîne | non | circuit du panneau qui le coupe : `"equipment"` (défaut) ou `"light"` |
| `definition.display` | `function(o) -> table` | non | données d'un appareil, onglet « Consommateurs » du logiciel de gestion (voir plus bas) |
| `definition.summary` | `function(objects) -> table` | non | total du réseau pour ce consommateur, onglet « Équipements » (voir plus bas) |

Raisons de refus : `"registration_closed"`, `"invalid_definition"`, `"duplicate_consumer"` (id déjà pris),
`"duplicate_sprite"` (sprite déjà inscrit). La définition est recopiée : la modifier après l'inscription n'a aucun
effet. `o` est toujours l'objet posé (`IsoObject`) reconnu par son sprite.

### `API.consumer(obj)` → `id` | `nil`

Côté : les deux. Id du consommateur inscrit qui reconnaît l'objet posé `obj`, sinon `nil`.

### `API.consumerPowered(obj)` → booléen

Côté : les deux. `true` quand l'objet est un consommateur inscrit, que sa case a du courant (Live Wire, générateur ou
réseau public, règle vanilla `ItemContainer.isObjectPowered`) et qu'aucun circuit ni disjoncteur ne le coupe. Sur un
client, la coupure est lue dans l'état synchronisé par le serveur. **À appeler quand la machine travaille** (début et
fin d'une action, étape de traitement) : Live Wire ne prévient pas, et ne touche jamais l'état de l'appareil.

### Fonctions déjà existantes utiles à un consommateur

| Fonction | Côté | Retour |
|---|---|---|
| `API.watts(obj)` | les deux | consommation facturée en W (sandbox appliquée), 0 à l'arrêt ou coupé |
| `API.applianceKind(obj)` | les deux | `"consumer"` pour un consommateur inscrit |
| `API.applianceCut(obj)` | les deux | `true` quand un circuit le coupe |
| `API.estimateWatts(w)` | les deux | `w` avec `PowerScale` et le facteur du profil (ce que Live Wire fait de `powerConsumption`) |

### Affichage dans le logiciel de gestion : `definition.display(o)`

Appelée **sur le serveur** (en solo, par le jeu), seulement quand Live Wire construit l'instantané d'un réseau
(écran d'onduleur ouvert, puis toutes les 10 minutes de jeu tant que le joueur reste abonné et proche ; `API.gridAt` ;
inspection d'appareil), et seulement pour les appareils inscrits de sa liste. Elle doit être rapide et sans effet de
bord. Elle rend :

```lua
{
    name = "IGUI_MyMod_Pump",                      -- clé du nom affiché à la place de la famille
    lines = {                                      -- 0 à 4 lignes sous l'appareil
        { "IGUI_MyMod_PumpFlow", "12.5" },         -- clé puis 0 à 4 arguments (%1 à %4)
        { "IGUI_MyMod_PumpBarrels", 3, 4 },
    },
}
```

Règles : clés `^[%w_]+$` de 64 caractères au plus, présentes dans les traductions **du mod** (le client traduit avec
`getText` ; un serveur dédié n'a pas besoin de les connaître) ; arguments chaînes de 32 caractères au plus ou nombres
(affichés tels quels : arrondir soi-même) ; `name` seul ou `lines` seules acceptés. Une réponse hors règles, ou `nil`,
laisse la ligne habituelle (famille, W, position). Même rendu sur l'écran de l'ordinateur Live Wire et dans la fenêtre
du Computer Mod.

### Résumé par réseau : `definition.summary(objects)`

Appelée **sur le serveur**, au même moment que `display`, **une fois par instantané** pour chaque consommateur inscrit
qui a au moins un objet desservi par ce réseau. `objects` est un nouveau tableau (1 objet au moins) des objets posés de
ce consommateur que les onduleurs du réseau desservent : zone du maître, plus celle des onduleurs couplés en service
quand un add-on la leur laisse ; appareils à l'arrêt compris ; ceux encore alimentés par le réseau public exclus. Elle
rend le même format que `display`, avec **2 lignes au plus** :

```lua
{ lines = { { "IGUI_LiveWater_PumpsSummary", 2, 3, "600" } } }   -- « Pompes : 2 en service sur 3, 600 L/h »
```

Mêmes règles de clés et d'arguments que `display` ; `name` facultatif (titre au-dessus des lignes). Affiché dans
l'onglet « Équipements », sous les équipements Live Wire, dans l'ordre d'inscription des consommateurs. Réponse hors
règles ou `nil` : rien n'est affiché pour ce consommateur. Rapide et sans effet de bord.

### Exemple complet

```lua
-- media/lua/shared/MyMod/MyMod_LiveWire.lua
local function register()
    local API = LiveWire and LiveWire.API
    if not (API and (API.revision or 0) >= 6) then return end
    local ok, why = API.registerConsumer("MyModPump", {
        sprites = { "mymod_pumps_01_0", "mymod_pumps_01_1", "mymod_pumps_01_2", "mymod_pumps_01_3" },
        powerConsumption = function(o) return MyMod.isRunning(o) and 250 or 0 end,
        category = "other",
        display = function(o)
            return { name = "IGUI_MyMod_Pump",
                lines = { { "IGUI_MyMod_PumpFlow", string.format("%.1f", MyMod.flow(o)) } } }
        end,
        summary = function(objects)
            local running, flow = 0, 0
            for _, o in ipairs(objects) do
                if MyMod.isRunning(o) then running, flow = running + 1, flow + MyMod.flow(o) end
            end
            return { lines = { { "IGUI_MyMod_PumpsSummary", running, #objects, string.format("%.0f", flow) } } }
        end,
    })
    if not ok then print("MyMod: LiveWire refused the pump: " .. tostring(why)) end
end
Events.OnInitWorld.Add(register)

-- Au moment de pomper (serveur) :
-- if LiveWire and LiveWire.API.consumerPowered and not LiveWire.API.consumerPowered(pump) then return end
```

## Conséquences

- Tout mod peut faire facturer son appareil sans dépendre d'Extended ; `require=\batman_LiveWire` n'est pas exigé
  (l'auteur teste `LiveWire and LiveWire.API and LiveWire.API.registerConsumer`).
- Coût du parcours inchangé pour les objets ordinaires (une recherche de sprite dans une table).
- Une erreur dans la fonction `powerConsumption` d'un autre mod remonte telle quelle (pas de `pcall` généralisé, AGENTS.md).
- MP : inscription des deux côtés (`shared`), facture et coupure sur l'autorité, `consumerPowered` lu par le client à
  partir de l'état synchronisé. À valider par la suite automatique MP.
- Le logiciel montre les données d'un appareil tiers et un total par réseau sans que son mod dessine quoi que ce
  soit ; le volume de l'instantané reste borné (200 lignes, 4 lignes de données par appareil, 2 lignes de total par
  consommateur).

## Hors portée

Rappel sur changement d'état, onglet ou fenêtre propre à un mod dans le logiciel, consommation d'objets d'inventaire ou de véhicules, appareils qui produisent du courant
(`registerSource` existe), nouvelle option sandbox.

Signalé pour plus tard par la session LiveWater, non décidé : une fonction de l'API pour libérer un appareil du
registre (rendre le fil, effacer l'entrée), nécessaire le jour où les pompes Live Wire déjà posées dans les
sauvegardes seront converties en pompes LiveWater au chargement d'une zone. Elle demandera son propre ADR.
