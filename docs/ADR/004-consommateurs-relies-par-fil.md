# ADR-004 — Consommateurs d'autres mods reliés par fil à un onduleur

| Champ | Valeur |
|---|---|
| Identifiant | `ADR-004-CONSOMMATEURS-RELIES-PAR-FIL` |
| Date de création et de mise à jour | 2026-11-20 |
| Statut | Accepté (2026-11-20) |
| Avancement | voir le [plan 004](../ADR-plans/plan-004-consommateurs-relies-par-fil.md) |
| Décideur | l'utilisateur (« il faut pouvoir connecter avec un fil » ; portée retenue : « Portée du câble », 2026-11-20) |
| Portée | `batman_LiveWire` : API (révision 9), consommateurs inscrits, branchement (`LW_Install`, actions, commandes), registre, simulation et facturation, circuits, menus et fenêtre « Connexions », ramassage ; spécifications, wiki développeurs |
| Documents liés | [ADR-002](002-api-consommateurs.md) (consommateurs inscrits, révision 6), ADR-017 de LiveWater (la pompe s'en sert), [`architecture.md`](../architecture.md) |
| Références | `LW_Install.lua:65-134` (`linkKind`, `checkLink`), `LW_Computer.lua:32-64` (appareil vanilla relié, modèle suivi), `LW_Registry.lua:276-348` (`link`, `members`, `forgetVanilla`), `LW_Pump.lua:65-66` (règle « alimenté » d'un appareil relié), `LW_Demand.lua:252-328` (`measure`), `LW_Circuits.lua:55-85` (`owner`), `LW_API.lua:484-499` (`registerConsumer`, `consumerPowered`) |
| Origine | demande de l'utilisateur du 2026-11-20 : « pouvoir connecter une pompe à eau à un onduleur de LiveWire, mais cela doit rester facultatif si LiveWire n'est pas installé, dans ce cas utiliser le courant présent sur la case » |

## Contexte

Un consommateur inscrit par un autre mod (ADR-002) n'a de courant que si sa case est dans la zone alimentée d'un
onduleur (20 cases, `GeneratorTileRange`), ou sous générateur ou réseau public. Il n'a ni fil ni menu « Connecter à un
onduleur ». Une pompe à eau de LiveWater posée au bord d'un étang, loin de la maison, n'a donc pas de courant LiveWire.
Les appareils de Live Wire, eux, se relient par fil jusqu'à la portée du câble (`LinkRange`, 12 cases), et un appareil
relié est alimenté et facturé par son onduleur même hors de la zone (règle de la pompe de Live Wire). Le générateur et
l'ordinateur vanilla se relient déjà par fil sans marque Live Wire : leur lien vit dans leur ModData.

## Décisions

- **D01 — Contrat.** `API.registerConsumer` accepte un champ facultatif `link = { level = 0..10 }` : le consommateur se
  relie par fil. API révision 9. Sans ce champ, rien ne change. L'inscription se fait dans un fichier `shared` (client et
  serveur doivent reconnaître l'objet).
- **D02 — Règles de branchement.** Celles de tout appareil Live Wire : portée du câble (`LinkRange`) et portée verticale
  (`LinkVerticalRange`), même hors de la zone alimentée ; niveau d'Électricité `link.level` (relevé au niveau de
  l'onduleur s'il n'est pas encore en service), tournevis, fil électrique selon la distance (`wiresFor`) ; nombre de
  consommateurs reliés par réseau non limité. Menus « Connecter à un onduleur » / « Déconnecter », « Connecter un
  équipement » de l'onduleur et fenêtre « Connexions ». Débrancher ou ramasser l'objet rend les fils.
- **D03 — Persistance.** Comme le générateur et l'ordinateur : le lien vit dans la ModData de l'objet (clé
  `LiveWireLink` : `id`, onduleur, état alimenté), l'appareil dans le registre (rôle `consumer`, modèle = id du
  consommateur, position, fils). Pas de marque `movableData`. Un lien périmé (objet déplacé, appareil inconnu) est ignoré
  et effacé.
- **D04 — Courant et facturation.** Un consommateur relié est alimenté par son onduleur selon la règle de la pompe de
  Live Wire (réseau alimenté, onduleur allumé, circuit et disjoncteur non coupés), où qu'il soit ; il est facturé à cet
  onduleur seulement (jamais une seconde fois par la zone d'un onduleur) et ses circuits sont ceux de son onduleur.
  Chargé, il est facturé de sa consommation réelle (`powerConsumption`) ; déchargé, de la dernière valeur mesurée.
- **D05 — Lecture pour le mod.** `API.consumerPowered(obj)` suit le lien quand il existe (registre sur l'autorité, état
  synchronisé sur un client), la règle de la case sinon. Nouvelles fonctions `API.consumerLink(obj)` (onduleur relié ou
  `nil`) et `API.consumerLinkPowered(x, y, z)` (case non chargée, lecture du registre).
- **D06 — Extension sans liste fermée.** Les sortes de lien (générateur de secours, ordinateur, consommateur) passent par
  une table de sortes dans `LW_Install` ; les rôles de membres et l'oubli d'un appareil vanilla passent par des tables
  dans le registre. Aucun nouveau `if` sur un rôle.

## Conséquences

- La pompe de LiveWater peut être reliée par fil comme la pompe de Live Wire ; sans lien, ou sans Live Wire, elle
  garde le courant de sa case.
- Tout autre mod peut rendre un appareil reliable en ajoutant un champ.
- Plus de code dans le branchement et la simulation de Live Wire : tests hors jeu et passage en jeu SP et MP requis.
