# Live Wire — bilan de validation SP/MP

Campagnes du 2026-10-24, Build 42.21. Ce bilan regroupe les essais des correctifs
CXX puis IXX ; le [suivi](../../ameliorations-et-idees.md) indique leur état de publication.
C11 reste différé et C20 est exclu. Les sections CXX historiques précèdent le bilan
de l'extension IXX locale, non publiée.

## Environnement et méthode

Jeu exécuté : **42.21**, journal de démarrage **42.21.0**. Le JAR installé correspond
aux sources Java décompilées 42.21.0, empreinte SHA-256 :
`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`.

Il s'agit de **tests automatisés dans le jeu**, sur copies de mondes. Le MP utilise
un serveur dédié local Windows et un ou deux processus clients selon le passage.
Les campagnes multi-phases ferment réellement les processus entre sauvegarde et
rechargement. Les journaux bruts et caches ne sont pas versionnés ; les identifiants
ci-dessous désignent les dossiers locaux `runs/`, contenant `summary.txt` et les
`result.txt` par processus. Le [protocole](protocole-tests.md) donne les commandes
et la dépendance externe pz-autotest nécessaires à la reproduction.

## Blocages et performances — C04–C09, C16, C22 et mémoire C23

Vérifications : marques de barils déplacées ou anciennes, index par chunk après
rotation/retrait, invalidation du cache, arrêt manuel du secours et reprise,
permissions safehouse à la fin des actions, frein explicite, vieillissement avant
bascule et purge mémoire sans raccourcir les délais actifs.

Les parcours de trois pompes et trois ancres respectent chacun un budget global
de **250 positions par appel de tick**. Le curseur au rayon 30 couvre 19 747 cases
sur sept niveaux. La pompe du scénario découvre le point d'eau en 28 ticks serveur
(environ 2,8 s sur la machine testée) et transfère réellement l'eau. Il s'agit d'un
contrôle du travail borné, sans mesure comparative de FPS.

| Passage | Résultat (sortie 0) | Dossier dans `runs/` |
|---|---|---|
| SP général avec scènes et absence | 36/36 | `20261024-120604-sp-9c727093877e` |
| MP général, un client | Serveur 12/12 ; client 6/6 | `20261024-115346-mp-dcdfc4c745dd` |
| SP ciblé | 12/12 | `20261024-120157-sp-e159635ae8c5` |
| MP ciblé, utilisateur ordinaire | Serveur 14/14 ; client 6/6 | `20261024-120346-mp-7e4f69399c86` |

## Relais — C25 et retrait C01

Trois phases par mode : création d'un relais de 25 L sur une case `z + 1` neuve,
sauvegarde avec 7,25 L, redémarrage, contrôle d'identité/eau/propriétaire, retrait
chargé puis réellement hors zone, retour avec nettoyage par `LoadChunk`, puis
nouveau redémarrage confirmant la désactivation et l'absence de recréation.
Les deux clients MP exécutent leurs propres assertions.

| Mode / phase | Autorité | Client 1 | Client 2 | Dossier dans `runs/` |
|---|---|---|---|---|
| SP création | 8/8 | — | — | `20261024-123143-sp-37c79f1e8685` |
| SP rechargement et retrait | 14/14 | — | — | `20261024-123230-sp-25cc2d87d553` |
| SP dernier redémarrage | 5/5 | — | — | `20261024-123318-sp-b5a46a13245d` |
| MP création | 5/5 | 4/4 | 4/4 | `20261024-124104-mp-4535766fd515` |
| MP rechargement et retrait | 9/9 | 6/6 | 6/6 | `20261024-124314-mp-43434f8e2382` |
| MP dernier redémarrage | 4/4 | 2/2 | 2/2 | `20261024-124527-mp-3d74f852d3ea` |

Tous les passages sortent avec le code 0. Le test vérifie le sprite effectivement
chargé : la cellule transparente est omise de l'atlas, sa texture est nulle et le
rendu vanilla s'arrête immédiatement (`IsoSprite.java:854-856`, sources 42.21.0).
La texture visible de la pompe sert de témoin de chargement du pack. Passage et
protections sont aussi contrôlés ; ce constat n'est pas une observation visuelle
manuelle. Le scénario crée directement le relais via l'API de la pompe pour
isoler sa persistance ; découverte et débit sont couverts séparément.

## Maintenance, version, documentation et renommage — C13–C15 et C26

Erreur de maintenance injectée hors jeu : journal anglais identifiant la pompe,
traitement des pompes suivantes conservé. Version Lua et métadonnées vérifiées.
Le renommage utilise la boîte vanilla et les contrôles serveur, depuis le menu
et le logiciel, avec synchronisation. Les limites alimentaires ont ensuite été
actualisées par C12 : le journal privé conserve désormais 60 jours de jeu.

| Passage | Résultat (sortie 0) | Dossier dans `runs/` |
|---|---|---|
| SP ciblé avec boîte de renommage | 13/13 | `20261024-124314-sp-ba8517dfad80` |
| MP ciblé, utilisateur ordinaire | Serveur 14/14 ; client 7/7 | `20261024-124803-mp-29f7ba39fff3` |
| MP logiciel, même étage et étage voisin | Serveur 14/14 ; client 6/6 | `20261024-124942-mp-6773eabd4b99` |

## Derniers correctifs — C08, C12, C17–C19, C21, C23 et C24

- **C08** : vraie découverte d'un robinet par les ticks, relais d'une première
  pompe transféré à une pompe plus proche, même objet et même eau ; maintenances
  répétées sans oscillation ; débranchement du baril qui rend le relais à l'autre
  pompe, puis reprise ; propriété et fluide constatés par les deux clients et
  après arrêt/redémarrage. Égalité de distance et entrée périmée de l'ancien
  propriétaire couvertes hors jeu.
- **C18** : relais pleins, dix minutes de service appelées au repos avec un ancien
  crédit de 10 L, puis demande de 10 L : transfert limité à 5 L, prélevés dans le
  vrai baril. Aucun crédit sauvegardé ne crée une rafale.
- **C17** : réglages sandbox natifs 80/20, vrai générateur qui démarre à 79 %,
  reste en marche à 82 % et s'arrête à 85 % ; instantané à seuil effectif 85.
  Contrôle hors jeu de l'avertissement unique et des réglages valides ; dix
  infobulles traduites contrôlées automatiquement.
- **C21** : vrai service de simulation d'un réseau hors zone, batterie à 0,3 kWh,
  besoin total de 1 kW, pas d'une heure : service pendant 0,3 h, stock consommé,
  coupure datée à cette fraction et conservée après redémarrage. Hors jeu :
  conservation de l'énergie, production partielle, épuisement exact et seuil de
  redémarrage. Les sous-pas météo restent une approximation d'une heure au plus.
- **C12** : véritable pomme dans un réfrigérateur ; quarante changements datés
  injectés comme historique de test, moitié du temps alimenté : âge égal au
  calcul attendu, journal public toujours limité à seize changements, historique
  privé conservé après relance. Les deux clients reçoivent l'objet sérialisé
  après rattrapage et constatent son âge. Rétention à 60 jours, reprise d'un ancien
  journal sans alias, retrait d'une ancre et absence de diffusion supplémentaire
  d'un état stable couverts hors jeu. Ce test n'attend pas réellement 60 jours de
  jeu ; la durée de rétention est vérifiée sur les entrées horodatées.
- **C19** : vrais relais aux niveaux −2 et 9, nettoyage sur les limites natives du
  chunk ; nouveaux orphelins sauvegardés puis retirés par le vrai `LoadChunk` du
  processus suivant. Absence constatée après reconnexion par les deux clients.
- **C24** : marque effacée puis altérée, restauration du même identifiant et des
  valeurs serveur sans double adoption ; vraie tuile détruite retirée du registre.
  Deux clients de niveaux différents, passés au rôle `user`, envoient chacun la
  commande d'adoption : rendement 0,85 et niveau neutre reçus par chacun.
- **C23** : cinq mesures réelles sur des cases différentes donnent de l'XP ; la
  sixième garde son résultat mais n'ajoute plus d'XP. Budget sauvegardé puis relu
  après redémarrage. Fenêtre glissante, indépendance entre joueurs et expiration
  vérifiées hors jeu. Les cinq points sont de l'XP de base, avant multiplicateurs.

### Résultats

| Mode / phase | Dossier local `runs/` | Résultat |
|---|---|---|
| SP création | `20261024-141057-sp-33a68c2e6191` | 15/15, sortie 0 |
| SP redémarrage | `20261024-141152-sp-ec9cf85b7200` | 7/7, sortie 0 |
| MP création, deux clients | `20261024-142813-mp-791ec0f6befa` | Serveur 14/14 ; chaque client 6/6 ; sortie 0 |
| MP redémarrage, deux clients | `20261024-143036-mp-b80e17c100be` | Serveur 8/8 ; chaque client 4/4 ; sortie 0 |
| SP général, sans captures (`shots=0`) | `20261024-143700-sp-aea74127a9dd` | 34/34, sortie 0 |
| MP de non-régression précédente, un client | `20261024-143845-mp-061a6762f362` | Serveur 14/14 ; client 7/7 ; sortie 0 |

Hors jeu : `check_mod.py` OK (Lua, chargement SP/client/serveur, traductions,
événements, versions), physique OK, simulation OK, régressions précédentes
**11/11**, nouveaux scénarios **14/14**. Les scripts Python et Lua du banc passent
leurs contrôles de syntaxe.

Les assertions de compte d'erreurs Lua ne signalent aucune nouvelle erreur
pendant les scénarios. Les journaux conservent des avertissements/erreurs vanilla
de chargement déjà présents (polices, zones et ressources de debug) ; ils ne sont
pas présentés comme absents. Les avertissements du mod sur la normalisation des
seuils et la destruction volontaire d'une tuile sont attendus par les scénarios.

## Conditions de reproduction des essais ciblés

- Pour isoler les volumes et durées, le banc des derniers CXX suspend les deux
  événements de service et appelle les vrais services de façon déterministe.
  Les ticks de découverte restent actifs ; les tests généraux gardent les
  événements normaux. Le réseau de pompe est sauvegardé éteint pour comparer
  les litres sans remplissage entre le chargement et le démarrage des hooks.
- Le redémarrage MP recopie le monde et ses options sandbox serveur, dont la
  coupure d'eau. Chaque lanceur active les hooks du second client et vérifie
  son résultat. Les adaptations de connexion restent dans les caches de test.
- Pour C12, le véritable aliment est sérialisé après rattrapage, comme un objet
  envoyé au chargement d'un chunk. `ItemStats` ne transporte pas son âge
  (`ItemStatsPacket.java:170–214`) ; aucun protocole d'âge additionnel n'a été ajouté.
- Le premier redémarrage a révélé un défaut réel : un cache de découverte vide
  retirait un relais sauvegardé. Le correctif attend la première découverte
  complète ; régression hors jeu et redémarrages réels couvrent ce cas.

## Diffusion des ancres — C11 différé

Un état et une position inchangés ne déclenchent pas `ModData.transmit` ; cent
appels stables sont vérifiés en SP/MP. Une connexion demande la table initiale.
Le journal public reste limité à seize changements ; l'historique privé de C12
n'est pas diffusé.

Le modèle `autotest/anchor_payload.py`, fondé sur `KahluaTableImpl.save(ByteBuffer)`
et `GlobalModDataPacket.write`, estime les tailles suivantes avec seize
changements conservés par base :

| Bases | Octets par événement/client | Moyenne/client : 2 bascules/base/jour de jeu, journée réelle de 60 min |
|---|---:|---:|
| 10 | 6 223 | 0,03 Kio/s |
| 100 | 62 114 | 3,37 Kio/s |
| 500 | 310 914 | 84,34 Kio/s |
| 1 000 | 621 915 | 337,41 Kio/s |

Il s'agit de sérialisation modélisée, sans capture réseau, hors en-têtes UDP/RakNet
et retransmissions. Multiplier par les clients pour le trafic sortant serveur.
À 100 bases et vingt clients, cette hypothèse donne environ 67 Kio/s en moyenne ;
cent bascules groupées représenteraient environ 124 Mo au total, chaque changement
renvoyant la table complète. Aucune diffusion périodique courte n'est établie.
Une optimisation reste conditionnée à une mesure réelle sur un serveur chargé.

## Limites de validation

- Aucun profilage de FPS ou de bande passante d'un grand serveur, ni validation
  sur serveur Linux. Les résultats MP concernent le serveur dédié Windows indiqué.
- Aucun jugement manuel du rendu, des sons ou de Project Viewpoint. Le cycle
  vanilla complet ramassage/inventaire/repose d'un baril reste à contrôler.
- Le scénario C21 exerce le vrai service sur un stock persistant hors zone ;
  il ne suit pas physiquement une powerbank déchargée pendant une heure réelle.
  La météo hors zone reste approchée par des sous-pas d'une heure au plus.
- Le scénario C12 injecte quarante transitions datées ; il n'attend pas soixante
  jours. Au-delà de la rétention, l'état à la borne sert d'approximation. Une
  ancienne sauvegarde ne peut pas récupérer des transitions déjà supprimées.
- Les tests ne constituent pas une preuve générale de compatibilité avec tous
  les mods, ni une validation exhaustive de chaque profil de consommation.

## Extension IXX locale après v1.5.0 — 2026-10-24

Quinze éléments implémentés localement : I01–I05, I07, I09–I15, I18 et I21.
Aucune publication, aucun commit ni push effectué.
Architecture modulaire événementielle à serveur autoritaire conservée ; schéma 2,
identifiants existants et diffusion des ancres C11 conservés. Les modifications
documentaires préexistantes d'I12 et I21 ont été conservées et actualisées.

### Vérifications hors jeu

Tous les contrôles suivants terminent avec le code 0 : `tools/check_mod.py`
(sources 42.21.0), `tests/test_physics.py`, `tests/test_simulation.py`,
`tests/test_regressions.py` (11 tests), `tests/test_remaining.py` (14 tests) et
`tests/test_features.py` (23 tests). Les nouveaux scénarios couvrent les coûts et
refus de réparation, l'absence de création d'énergie, mille petits pas de charge
et décharge, les modifications natives externes, l'usure fractionnaire, le froid
réversible, les facteurs solaires, le journal borné/détaché, les inscriptions de
l'API et l'attribution des lumières. Un ancien panneau sans orientation est relu
sur sa tuile, même sans changement d'état ni usure. `git diff --check` est propre.
Ces contrôles sont statiques ou simulés ; ils ne prouvent pas une API moteur.

### Essais réels, mondes copiés et redémarrages complets

Lignes `summary` des résultats finaux, avec codes de sortie et dossiers locaux
sous `runs/`. Le second client est vérifié par son propre `result.txt`, même
quand le résumé générique du lanceur l'affiche avec `run=False`.

| Campagne | Phase | Code | Summary par processus | Dossier local dans `runs/` |
|---|---|---|---|---|
| ixx-sp | create | 0 | client : `23/23 PASS` | `20261024-183715-sp-bdca68c45bab` |
| ixx-sp | reload | 0 | client : `15/15 PASS` | `20261024-183808-sp-aa4280cbe68f` |
| ixx-mp | create | 0 | server : `23/23 PASS` ; client1 : `9/9 PASS` ; client2 : `7/7 PASS` | `20261024-183859-mp-a6363a3ee8e7` |
| ixx-mp | reload | 0 | server : `15/15 PASS` ; client1 : `8/8 PASS` ; client2 : `7/7 PASS` | `20261024-184150-mp-e5a0797d2788` |
| remaining-sp | create | 0 | client : `15/15 PASS` | `20261024-184420-sp-1aeaf451e8c0` |
| remaining-sp | reload | 0 | client : `7/7 PASS` | `20261024-184516-sp-527d95fd42bb` |
| remaining-mp | create | 0 | server : `14/14 PASS` ; client1 : `6/6 PASS` ; client2 : `6/6 PASS` | `20261024-184610-mp-cc5fa9b4d94c` |
| remaining-mp | reload | 0 | server : `8/8 PASS` ; client1 : `4/4 PASS` ; client2 : `4/4 PASS` | `20261024-184845-mp-86d331fe0ab1` |
| c25-sp | create | 0 | client : `8/8 PASS` | `20261024-172231-sp-5b043a3e9410` |
| c25-sp | reload | 0 | client : `14/14 PASS` | `20261024-172321-sp-23b6e95f6225` |
| c25-sp | clean | 0 | client : `5/5 PASS` | `20261024-172414-sp-183238d53908` |
| c25-mp | create | 0 | server : `5/5 PASS` ; client1 : `4/4 PASS` ; client2 : `4/4 PASS` | `20261024-172505-mp-22c4aa84b3d6` |
| c25-mp | reload | 0 | server : `9/9 PASS` ; client1 : `6/6 PASS` ; client2 : `6/6 PASS` | `20261024-172727-mp-c3fec5264ea9` |
| c25-mp | clean | 0 | server : `4/4 PASS` ; client1 : `2/2 PASS` ; client2 : `2/2 PASS` | `20261024-172958-mp-1dafa93442d7` |

**Confirmé en jeu, Windows 42.21.0** : orientation des quatre tuiles et reprise
des champs absents ; nettoyage avec dépense de vraie eau et refus de répétition ;
réparation morte refusée au niveau 4, acceptée au niveau 6 sans charge créée ;
réparation chargée avec conservation d'énergie, cycles, coûts et limite ;
diagnostic par compétence ; démontage d'un objet mort et vide une seule fois.
Une batterie drainable d'extension réelle est inscrite par un mod de test dans
les copies temporaires ; ses arrondis natifs, son énergie précise et son identité
après redémarrage sont contrôlés. Le froid utilise une banque réellement dehors
et la température native de test, avec décharge et récupération au dégel.

Deux clients ordinaires exécutent les commandes du tableau et reçoivent les
consommateurs, événements et nom. Le premier réalise les actions natives de
diagnostic et reconditionnement ; l'autorité vérifie énergie, cycles et coûts.
Un refuge étranger refuse les commandes. Le risque électrique produit une vraie
blessure de main ; l'intervention sûre ne la produit pas. Le frein interdit la
production, l'orage génère un seul avertissement par épisode et les calques
natifs du voyant alternent. Le dessin du tableau a été inspecté sur capture.
Raccordements, carte de consommation et nouveaux onglets sont réellement rendus
par les API de jeu, sans nouvelle erreur Lua dans ces passages.
Les journaux des deux derniers passages MP ne reproduisent pas les exceptions
`SyncItemFieldsPacket.parse`, ni les avertissements d'échec de simulation ou de
maintenance de pompe recherchés. Les erreurs vanilla de démarrage déjà présentes
restent distinctes de ce contrôle.

Le nettoyage et le démontage sont exercés par leur `complete()` autoritaire sur
les vrais objets ; les parcours natifs complets client/serveur ajoutés ici portent
sur le diagnostic et le reconditionnement. Les dernières reprises d'orientation
et de précision des batteries sont revérifiées par les quatre passages IXX finaux.

Le circuit lumières éteint le vrai interrupteur et réduit la demande mesurée,
puis restitue le choix initial. Le frigo reste alimenté pendant cette coupure.
La manette principale de la GUI interrompt le vrai `isPowered()` du frigo puis
le rétablit. Le principal laisse l'onduleur en marche et coupe son ancre ; son
choix, les choix d'éclairage et le journal survivent au redémarrage. La commande
équipements est maintenant active ; les essais spécifiques ci-dessous remplacent
le refus de cette commande dans les premiers passages de la campagne.

### Reprise I21 : services réels des équipements

Le diagnostic initial était trop large : l'absence de setter de courant par objet
ne rend pas impossible l'arrêt de son service. Une expérience vanilla seule
(sans le mod tiers) donne sortie 0, `summary=9/9 PASS`, dans
`runs/20261024-175207-sp-f152896fb725` : même conteneur, froid arrêté, watts natifs
nuls, aliment vieillissant plus vite, congélateur qui dégèle, lumière encore active,
puis restauration. Le premier essai, `20261024-175031-sp-fda8591f663e`, sortie 2,
utilisait un type d'objet alimentaire inexistant dans cette Build ; banc corrigé.

Campagne `appliances`, **confirmée en jeu sous Windows 42.21.0** :

| Mode/phase | Code | Lignes summary | Dossier dans `runs/` |
|---|---|---|---|
| SP create | 0 | `69/69 PASS` | `20261024-192426-sp-c60d0f942aa2` |
| SP reload | 0 | `56/56 PASS` | `20261024-192542-sp-cf47880436d5` |
| MP create | 0 | server : `55/55 PASS` ; client1 : `29/29 PASS` ; client2 : `28/28 PASS` | `20261024-192645-mp-4ea389e8b736` |
| MP reload | 0 | server : `42/42 PASS` ; client1 : `29/29 PASS` ; client2 : `28/28 PASS` | `20261024-192938-mp-20ce86a1c10c` |

Les appareils sont natifs : lave-linge, sèche-linge, combiné en mode séchage,
superposé à deux états, four, micro-ondes, TV allumée, TV initialement éteinte,
radio secteur, radio sur pile et chargeur de batterie automobile. Coupure,
rétablissement des choix, sauvegarde coupée et redémarrage complet sont vérifiés.
Les deux clients MP sont réellement rétrogradés en utilisateurs ordinaires ; ils
contrôlent les états natifs après coupure **et** après rétablissement, dont la TV
qui doit rester éteinte et la radio sur pile qui doit rester allumée.
Le premier utilisateur rétablit les équipements depuis le levier de la vraie GUI,
avec une banque réellement chargée ; la commande passe par les validations serveur.

Frigo et congélateur utilisent les mêmes conteneurs et vrais aliments : température,
vieillissement et dégel contrôlés, demande en baisse ; les lumières continuent de
fonctionner. Les quatre combinaisons des circuits sont exercées. Le rattrapage
alimentaire rejoue une chronologie du circuit sans modifier l'ancre. Les actions
natives de remise en marche sont refusées. Le prélèvement de carburant et sa mise
à jour partielle sont refusés sans altérer le vrai stock ni remplir le récipient.
Les transferts génériques de fluides et le remplissage B42 sont également refusés ;
le transfert reprend après rétablissement avec conservation du fluide. Un second
cas alimentaire vérifie l'affectation à un tableau plus proche mais vide, dont
l'historique n'a encore aucune transition de courant. Les contrôles hors jeu
vérifient aussi le profil des watts mémorisés et l'exclusion du pompage passé
dans la demande future prévue après coupure.

Portée et chargement physique : sortie 0, `summary=10/10 PASS`,
`runs/20261024-183534-sp-701d1734ecec`. Deux maîtres indépendants en recouvrement,
maître plus proche mais vide, facturation par l'autre ancre alimentée, couplage,
découplage et retrait du maître sont exercés sur un vrai frigo. Le joueur part
assez loin pour que sa zone soit réellement déchargée ; le circuit change pendant
l'absence, puis le retour charge le frigo, restaure son type et conserve son contenu.
Le changement pendant l'absence est une injection de l'autorité de test ; les
commandes avec proximité/refuge sont vérifiées séparément avec les vrais joueurs.
Le redémarrage de ce monde de portée réussit aussi : sortie 0,
`summary=4/4 PASS`, `runs/20261024-183625-sp-a688274dda35`.

### Coût de l'entretien des circuits — contrôle ciblé

L'entretien des circuits est limité à un créneau toutes les 100 ms réelles au
minimum, au plus 16 entrées en cache et un arrêt entre objets après environ 1 ms.
Entre créneaux, aucun état d'appareil n'est lu par ce rappel. Les tests hors jeu
à horloge contrôlée démontrent l'absence de rattrapage en rafale, l'arrêt après
rétablissement, zéro visite sans travail et la progression jusqu'à la fin d'un
inventaire de 5 000 entrées. Les objets réellement déchargés ne sont pas mutés.
Un appel natif individuel peut dépasser le budget temporel ; les événements de
commande et de chargement restent immédiats. Ce changement ne migre aucune donnée.

Mesure réelle après cette limitation, Windows 42.21 : solo création, code 0,
`summary=69/69 PASS`, `runs/20261024-192426-sp-c60d0f942aa2` ; redémarrage complet,
code 0, `summary=56/56 PASS`, `runs/20261024-192542-sp-cf47880436d5`.
Une réactivation forcée par setter natif est bien annulée par l'entretien.
Les enveloppes temporaires du banc mesurent respectivement 1 ms sur 3 067 ms
(maximum d'un rappel 1 ms) et 5 ms sur 3 055 ms (maximum 2 ms).
Ces relevés utilisent l'horloge en millisecondes et ne constituent ni un benchmark
de FPS, ni une validation de charge d'un grand serveur ou de toutes les machines.

Avec un serveur dédié et deux clients ordinaires, création : code 0, serveur
`summary=55/55 PASS`, client 1 `summary=29/29 PASS`, client 2 `summary=28/28 PASS`,
`runs/20261024-192645-mp-4ea389e8b736`. L'entretien autoritaire totalise 5 ms sur
3 291 ms, maximum d'un rappel 1 ms ; 108 visites réparties sur 10 créneaux,
16 entrées au maximum et espacement minimal observé de 100 ms.
Après arrêt et redémarrage complet du serveur et des deux clients : code 0,
serveur `summary=42/42 PASS`, client 1 `summary=29/29 PASS`, client 2
`summary=28/28 PASS`, `runs/20261024-192938-mp-20ce86a1c10c`.
Mesure autoritaire : 8 ms sur 3 003 ms, maximum d'un rappel 2 ms,
78 visites sur 10 créneaux, au plus 16 entrées, espacement minimal 101 ms.

Les régressions CXX utilisent les vrais fluides et relais : attribution, eau et
identifiants sauvegardés, chargement initial progressif, retrait chargé puis hors
zone, nettoyage au chargement, étages −2 et 9, couplage/découplage et observateurs.
C12 exerce un vrai aliment sur quarante transitions datées ; C21 contrôle une
coupure fractionnaire, C17 les seuils du secours et C23 le plafond global d'XP.

### Mémoire — rétentions de références et essai répété

La revue ciblée a confirmé statiquement trois rétentions : instantanés client de
tous les réseaux consultés, inventaires/rapports consommateurs conservant des
objets Java après départ de zone, et abonnements à des réseaux supprimés ne
repassant plus par `publish`. Cela ne mesure pas leur coût réel ni ne démontre
une fuite de tout le moteur. Correctifs : plafond client de 64 réseaux, expiration
à cinq minutes réelles, effacement à la déconnexion/au menu, libération des
inventaires et découvertes au retrait/déchargement, purge des abonnements morts
et listes vides. Aucune modification des identifiants ou des sauvegardes.

Six tests hors jeu, `python tests/test_memory.py`, sortie 0 : 5 000 réseaux
successifs, expiration, références faibles vérifiant que les anciens réseaux et
objets deviennent collectables après purge sous Lua 5.1, nettoyage des files et
jobs, départ d'un joueur et fermeture des vues. Ce n'est pas une preuve JVM.
Les cinq autres suites et `check_mod.py` passent aussi, sortie 0.

Le banc réel `memory` fait, par passage, 100 cycles de chauffe puis trois blocs
de 500 coupures/rétablissements sur l'autorité ; chaque client fait 100 puis
trois blocs de 200 ouvertures/fermetures de vrais tableaux. Les bascules de
service sont injectées directement sur l'autorité, les permissions de commande
étant vérifiées par les campagnes fonctionnelles. Les faux instantanés de réseaux
consultés passent par le gestionnaire client, sans trafic supplémentaire.

Solo Windows 42.21, code 0 dans les deux phases :

| Phase | Summary | Dossier dans `runs/` | Tas JVM post-GC, chauffe → dernier bloc (Mio) |
|---|---|---|---|
| Création | `45/45 PASS` | `20261024-194919-sp-fcde2c0eff31` | autorité 1 116,47 → 1 089,77 ; client 1 111,95 → 1 091,72 |
| Redémarrage complet | `45/45 PASS` | `20261024-195056-sp-19fcb83b8574` | autorité 1 103,40 → 1 090,47 ; client 1 103,06 → 1 089,71 |

MP Windows, création : code 0, serveur `summary=26/26 PASS`, client 1
`summary=19/19 PASS`, client 2 `summary=19/19 PASS`,
`runs/20261024-195431-mp-3d32af4e13f1`. Tas JVM post-GC, après chauffe puis dernier
bloc : serveur 1 420,00 → 1 420,00 Mio ; client 1 1 156,19 → 1 155,98 Mio ;
client 2 1 161,92 → 1 160,95 Mio. Les deux clients sont utilisateurs ordinaires.

MP après redémarrage complet/reconnexion : code 0, serveur `summary=26/26 PASS`,
client 1 `summary=19/19 PASS`, client 2 `summary=19/19 PASS`,
`runs/20261024-195752-mp-5a07d44bbf35`. Relevés après chauffe puis blocs 1/2/3 :
serveur 1 398 / 1 398 / 1 402 / 1 402 Mio ; client 1 1 158,23 / 1 157,38 /
1 156,99 / 1 157,68 Mio ; client 2 1 160,91 / 1 160,30 / 1 160,06 / 1 160,93 Mio.
Le palier serveur de +4 Mio sur le tas du jeu entier n'est pas attribué à une
classe ni à un chemin de rétention : aucune analyse de dump de tas n'a été faite.
Il ne permet de conclure ni à une fuite du mod ni à l'absence d'une petite fuite.

Le tas est celui du jeu entier ; en solo, autorité et client partagent la JVM.
Les relevés sont faits à des instants différents et ne s'additionnent pas.
Chaque bloc termine sans ancien tableau dans `UIManager`, avec cache client
≤ 64 puis vide après nettoyage, journal ≤ 30 et découverte consommateur libérée.
Les conteneurs et contenus sont conservés. Aucun nouvel échec Lua pendant les
cycles. Les relevés ne montrent pas de dérive continue proportionnelle aux cycles ;
il ne garantit pas l'absence de toute fuite native/GPU, ni le comportement sur
plusieurs heures ou sous Linux. Le GC forcé reste exclusivement dans le banc.

Purge après départ physique de zone et retour : sortie 0, `summary=11/11 PASS`,
`runs/20261024-195248-sp-f04a10efd9af`. L'inventaire de l'onduleur absent est bien
libéré ; le frigo revient avec son type, son contenu et son service corrects.
Redémarrage de ce monde : sortie 0, `summary=4/4 PASS`,
`runs/20261024-195338-sp-3a89e994baa4`.

### Échecs intermédiaires et correction du banc

- Mémoire, `20261024-194309-sp-ff89f69b6d4e`, sortie 1, `summary=0/1 PASS` :
  le routage solo n'avait démarré que les hooks client, sans scénario autoritaire.
  `20261024-194751-sp-d300a78fb1d8`, sortie 2, summary vide, erreur de hook
  `attempted index: close of non-table: null` : le tableau créé directement par
  le banc n'avait pas encore sa marque de raccordement synchronisée. Routage et
  fixture corrigés ; ces deux passages ne valident aucune propriété mémoire.
- `20261024-180855-sp-4bf0ca56ccd4`, sortie 2 : le nouveau banc choisissait les
  seuls hooks observateurs en solo ; essai interrompu dans son cache privé et
  routage solo corrigé. Les passages `181314-sp-9303b0268b0b` (sortie 0,
  `43/43 PASS`) et `181409-sp-b10e765c9f6c` (sortie 1, `26/31 PASS`) révélaient
  ensuite une fin prématurée du banc ; ils ne valident pas le rétablissement.
- `20261024-181634-sp-415827840606`, sortie 1, `59/60 PASS` : la chronologie
  alimentaire de test commençait avant l'heure zéro du monde. Fenêtre bornée à
  l'âge réel du monde ; les passages finaux contrôlent la valeur attendue.
- `20261024-182108-mp-7a405b36bc01`, sortie 2 : conteneurs de la machine
  superposée créés après son envoi réseau, entraînant une exception native chez
  les clients. Le banc crée désormais conteneurs, mode et réglages avant l'envoi.
- `20261024-182534-mp-cbf8a5da07a5`, sortie 1 : serveur `48/48 PASS`, clients
  `23/28 PASS`. Le banc n'avait pas rétrogradé les clients de debug et changeait
  sans les synchroniser les états initiaux d'une TV et d'une radio. Création
  cohérente et rétrogradation effective ajoutées. L'adaptateur de production
  diffuse aussi le choix initial OFF d'un média, même sans appel de setter.
- `20261024-183352-sp-ae05701ec70b`, sortie 2 : setter de dernière position
  inexistant dans le banc de déplacement ; remplacé par les API `setLastX/Y/Z`
  vérifiées dans la Build exécutée. Le passage de zone final réussit réellement.
- `20261024-185313-mp-df220ad38ff2`, sortie 2 : le récipient des transferts
  génériques était un objet non rattaché à un inventaire. La validation vanilla
  tentait alors `getPlayer()` sur le serveur dédié. Le banc crée désormais les
  récipients dans l'inventaire réel du personnage, configure leur contenu avant
  l'envoi et laisse parvenir les créations avant la reprise du transfert.

- `20261024-161543-mp-d12d2f4daafe`, sortie 1 : `next` absent dans l'environnement
  Kahlua. Remplacé par un parcours `pairs`, avec régression hors jeu `next=nil`.
- `20261024-162531-mp-aa4ff5dc9f20` et `20261024-163017-sp-87fab7bf938b`, sortie 1 :
  le setter natif arrondissait la batterie d'extension vers le haut. Écriture
  native conservatrice, reliquat précis et usure fractionnaire persistante ajoutés.
- `20261024-165043-mp-2cc6200943ac`, sortie 1 : le banc avait coupé l'électricité
  publique côté serveur après connexion, sans répercuter cette option chez les
  clients ; leur frigo utilisait encore le réseau public. Monde de test corrigé.
- `20261024-170317-mp-e2dd66cb6c85`, sortie 1 : clics automatisés trop rapides à
  la reconnexion ; le limiteur de commandes refusait le rétablissement. Clics
  espacés dans le banc, limiteur de production conservé.
- `20261024-171152-mp-cf618729f6cf`, sortie 0 pour les assertions, présentait deux
  exceptions Java `SyncItemFieldsPacket.parse` lors du peuplement immédiat de
  l'inventaire. Ce passage n'est pas retenu comme démarrage sans erreur. Le banc
  prépare les objets avant leur création réseau et laisse parvenir les créations
  avant d'exécuter les actions ; les passages finaux sont relus dans les journaux.

### Limites de validation

- Les familles électriques vanilla sont prises en charge. Un service propre à un
  autre mod nécessite une compatibilité ; aucun essai ici ne valide tous les mods.
  Les cycles/minuteries reprennent selon les setters vanilla, sans sauvegarde
  d'une progression interne non exposée. Les groupes d'éclairage sont ceux des
  pièces natives ; les créations tierces hors parcours standard peuvent attendre
  la redécouverte progressive. Rétablir les circuits avant de désactiver le mod.
  Les changements d'alimentation de générateurs vanilla indépendants ne disposent
  pas d'un historique temporel complet dans Live Wire. Voir le
  [contrat exact](../recherches/circuits-42-21.md).
- Orientation et situation extérieure d'anciens objets hors zone ne peuvent être
  relues avant chargement. La météo hors zone conserve les approximations du
  moteur de simulation existant. La suie des incendies n'est pas modélisée.
- Prévisions : météo moyenne officielle, entretien et capacité supposés constants,
  demande moyenne récente ; ni pannes futures ni secours futur garantis.
- Pas de validation Linux, de charge d'un grand serveur, de sons/ressenti manuel
  ou de rendu dans les dix langues. La capture française confirme le dessin
  observé ; la parité des clés et formats est contrôlée dans les dix langues.
- Intégrations tierces non actives pendant ces passages : aucune preuve générale
  de compatibilité. Les jauges natives de batteries restent graduées ; le modèle
  précis serveur et sa migration sont documentés dans les spécifications.
- I06, I08, I16, I17, I19, I20 et C20 exclus ; C11 reste différé. Aucun test
  n'autorise une modification de Java ou une migration d'architecture.


## Complément d'interface — état local après la demande utilisateur

**Confirmé hors jeu seulement** : LCD powerbank, panneau de raccordement commun,
routage au clic simple et teintes des consommateurs implémentés. Les contrôles
`tools/check_mod.py` (sources 42.21.0), `test_physics.py`, `test_simulation.py`,
`test_regressions.py` (11), `test_remaining.py` (14), `test_features.py` (23),
`test_memory.py` (6) et `test_interface.py` (8) sont passés, codes de sortie 0.
Les huit nouveaux scénarios couvrent énergie de lecture et froid, réponses réseau
obsolètes, refus de lecture, gardes du clic, index de résolution déplacés et nettoyage
respectueux des teintes tierces, absence de découverte du monde sur 10 000 mises à
jour de panneau, et refus de débranchement sur une cible ou permission incorrecte.
Ils utilisent des stubs Lua, sans moteur.

**Non confirmé en jeu pour ce complément** : au moment de ces contrôles, une
instance personnelle du jeu était ouverte. Aucun lancement concurrent, arrêt de
cette partie ou modification de sauvegarde personnelle. Le scénario réel
`autotest/interface.json` et ses phases SP/MP sont préparés, pas encore exécutés.
Aucun code de sortie ni dossier de passage réel à annoncer pour ce complément.
Les campagnes réelles précédentes ne valident pas ces nouveaux panneaux ni leur rendu.
Les textes des dix langues sont contrôlés ; le rendu doit encore être observé.
Pas de validation Linux ni de nouvelle preuve de comportement mémoire longue durée.

Passage lancé ensuite, puis interrompu à la demande de l'utilisateur qui choisit
les essais manuels : `runs/20261024-230704-sp-11b40b49c955`, code du lanceur **2**,
sans résultat de hooks complet (`the game stopped without a complete result.txt`).
Fermeture normale de la seule fenêtre du cache de test, processus Java code 0 ;
aucune phase reload ou MP lancée. Ce passage interrompu ne valide aucune fonctionnalité.

### Retour manuel : erreur de la vue consommateurs

Confirmé dans le journal utilisateur en Build 42.21.0, à `f:21861` :
`__sub not defined for operands in sameColor`, `LW_NetworkView.lua:11`, depuis
`refreshHighlights`. C'est une erreur Lua capturée par le moteur ; ce journal et
la présence du processus ne prouvent pas un arrêt de la JVM ni un manque de mémoire.

Cause : la comparaison utilisait `ColorInfo.r/g/b/a` comme champs de table Lua.
Correction : lecture par `getR/getG/getB/getA`, aussi lors de la mémorisation de la
couleur initiale pour la restaurer. La fréquence et la portée du travail sont inchangées.

Contrôles après correction : `tests/test_interface.py` **8/8**, `tools/check_mod.py`
**OK**, `git diff --check` **OK** (codes 0). Le double de couleur refuse désormais
tout accès aux champs ; vingt rafraîchissements successifs et le nettoyage/restauration
sont exercés. Le scénario réel préparé appelle aussi deux rafraîchissements successifs.
Ce sont des vérifications hors jeu : aucun nouveau passage SP/MP automatique lancé,
conformément au choix de tests manuels de l'utilisateur. Refaire afficher, attendre
plusieurs secondes, masquer, puis réafficher après redémarrage complet du jeu.

### Retouche du coffret : mention du fabricant

À la demande de l'utilisateur, ajout d'une plaquette « legrand », lettrage rouge,
détail noir, fond blanc sur le capot du tableau. Nom identique dans les dix langues.
Contrôle `tools/check_mod.py` et `git diff --check` passés, codes 0. Retouche visuelle
uniquement ; rendu à confirmer lors de l'essai manuel après relance du jeu.


## Powerbanks superposées — implémentation locale

**Confirmé hors jeu** : module partagé de pile, propriétés natives des quatre
orientations, deux conteneurs et membres de réseau distincts, protection du support,
sélecteur de banque du LCD et quatre nouvelles clés dans les dix langues.

Contrôles effectués, codes **0** : `tools/check_mod.py` avec les sources 42.21.0,
`test_physics.py`, `test_simulation.py`, `test_regressions.py` (11),
`test_remaining.py` (14), `test_features.py` (23), `test_memory.py` (6),
`test_interface.py` (8) et `test_stacking.py` (6).

Le banc d'empilage utilise le fichier vanilla installé
`media/lua/shared/Moveables/ISMoveableSpriteProps.lua` sous Lua 5.1 avec stubs :
validation native de la seconde banque et hauteur du curseur, refus de la troisième
avant consommation, protection contre les retraits/rotations du support, charges
et conteneurs distincts sur une même case, reconstruction des index et retrait d'un
membre sans toucher à l'autre. Ces contrôles ne prouvent pas un passage en jeu.

Le binaire `.tiles` a été relu par le codec : seuls les enregistrements 16–19 ont
reçu trois propriétés ; indices et identifiant de tileset conservés. La recette de
production porte les mêmes propriétés ; aucun pack d'images ni profondeur modifié.
Aucune migration de données : schéma, ID d'objets, batteries et raccordements existants
conservés. Aucun nouveau travail par tick, paquet ou cache d'empilage.

**À confirmer manuellement** : pose et rendu natifs, accès aux deux inventaires,
rotation/retrait réels, sauvegarde/redémarrage, concurrence MP, permissions et
reconnexion. Aucun nouveau jeu automatique lancé, selon le choix utilisateur.
Aucune validation Linux. Protocole dans la section Powerbanks superposées.

## 2026-10-25 — F31 : butin d'équipements réglable et élargi

Réalisation locale : multiplicateur sandbox 1–20, défaut demandé **5**, poids
appliqués après lecture de la sauvegarde, huit catégories de butin ajoutées selon
l'équipement. 64 couples équipement/liste contre 31, huit types d'objet existants.

Confirmé statiquement dans les sources **42.21.0**, version également observée
dans le journal : fusion des distributions avant chargement sandbox en solo
(`IsoWorld.java:1791–1809`), événement `OnInitGlobalModData` après ce chargement
(`IsoWorld.java:1908`, `GlobalModData.init`), `ItemPickerJava.Parse` réinitialisant
ses tables sans réinitialiser les facteurs sandbox de butin (`:144–173`, `:333`,
`:473`). Le mod n'ajoute aucun traitement périodique ou parcours du monde.

Le banc `tests/test_loot.py` exécute les vrais scripts Lua du mod sous Lua 5.1
avec environnement simulé : défaut, lecture de l'option solo au bon moment,
priorité à la valeur active, idempotence, changements de monde, ×1/×5/×20,
bornage, catégorie absente, refus côté client MP, cellules LiveWire
incluses, CD et toutes les entrées vanilla inchangés.
La variante `--vanilla-dir` charge les distributions installées et leurs dépendances :
toutes les 64 entrées pointent vers des listes réellement référencées par les salles ;
les poids et nombres de tirages du générateur documentaire correspondent au Lua.

Contrôles exécutés, tous avec code de sortie **0** :

- `test_loot.py --vanilla-dir <media/lua/server/Items>` : **9 tests passés**.
- `tools/check_mod.py <sources-42.21.0>`, `test_physics.py` et
  `test_simulation.py` : **OK**.
- `test_regressions.py` : 11 ; `test_remaining.py` : 14 ;
  `test_features.py` : 23 ; `test_memory.py` : 6 ; `test_interface.py` : 8 passés.
- `test_stacking.py` sans option vanilla : 4 passés, 2 ignorés (tests de curseur
  natif, non nécessaires pour le butin ; résultats antérieurs inchangés).
- Générateurs de traductions (y compris invocation `-I`) et tableaux : exécutés ;
  `git diff --check` : aucun défaut d'espacement.

**Limites :** ces contrôles hors jeu ne mesurent pas la fréquence réelle en carte,
le tirage Java, le rendu de l'option ni une connexion de joueurs. Aucun nouveau
test réel SP/MP ou Linux lancé ; protocole manuel ajouté. Les anciennes campagnes
en jeu ne valident pas cette nouvelle option. Aucun commit, push ou publication.

### Périmètre final : pièces et équipements LiveWire uniquement

L'utilisateur précise que les objets vanilla doivent rester entièrement intacts.
Le traitement intermédiaire des six composants vanilla est retiré : ni listes
ciblées, ni capture/restauration de leurs poids, ni insertion de pièces absentes.
Le multiplicateur 1–20, défaut 5, reste applicable aux huit types d'équipements
LiveWire et à `LiveWire.SolarCell` dans douze listes ; CD conditionnel inchangé.
Les guides, tableaux et dix traductions limitent explicitement le périmètre au mod.

`test_loot.py --vanilla-dir <media/lua/server/Items>` : **9 tests passés**, code **0**.
Le contrôle charge les distributions installées sous Lua 5.1 : tous les objets
et poids vanilla préexistants restent strictement identiques, et chaque entrée
ajoutée appartient à `LiveWire.*` ou `Base.Mov_LiveWire_*`. Des composants vanilla
avec ou sans préfixe sont également vérifiés aux multiplicateurs 1, 5 et 20,
après initialisations répétées et changement de monde ; les changements d'autres
mods après fusion restent intacts. Les catégories, poids et tirages du générateur
documentaire concordent avec les scripts. Ces contrôles hors jeu ne constituent
pas un essai SP/MP réel ; les limites de validation précédentes restent applicables.

## 2026-10-25 — F32 : sources, composants et pose niveau 2

Éolienne en trois étapes, deux amplificateurs vanilla par machine, pose/ramassage
niveau 2 sur les huit sprites, fabrication 6 et 7 conservée. Butin élargi, limité
au mod ; pales et mât conservés. Anciennes machines et identifiants publiés
conservés. Les contrôles du prototype intermédiaire ont été remplacés par ceux
du choix final, décrits dans l'entrée « amplificateurs et icônes » ci-dessous.

Le binaire `.tiles` a été relu lors de cette étape : seules les propriétés
PickUpLevel des sprites 4–11 changent, propriétés d'empilage précédentes conservées.
Contrôles hors jeu exécutés alors, codes 0 : physique, simulation, régressions,
correctifs restants, fonctionnalités, mémoire, interface et empilage. Aucun essai
réel SP/MP ou Linux pour ces modifications, selon le choix manuel de l'utilisateur.

## 2026-10-25 — démontage du testeur de tension

Recette `LWDismantleVoltageTester` ajoutée : un testeur consommé, un déchet
électronique rendu, tournevis en état conservé, sans niveau requis, durée 60 et
2 XP. Aucun hook ni changement du butin, de l'autorité ou de la persistance.
Traductions, tableaux et dix planches de recettes régénérés ; guides EN/FR à jour.

Contrôles hors jeu, codes **0** : `tools/check_mod.py`, `test_crafting.py` avec le
Lua vanilla installé (**6 tests passés**) et `git diff --check`. Bilan de matières
lu dans les scripts : fabrication = un déchet + un fil + une ampoule + une pile ;
démontage = un déchet seulement, testeur détruit et outil gardé. Aucun gain de
matériau sur un cycle. Pas de nouveau test miroir ajouté pour cette recette simple.

Pas d'essai réel SP/MP lancé ; consommation effective, annulation et concurrence
restent à vérifier dans le protocole manuel. Aucun résultat Linux implicite.

## 2026-10-25 — choix final : amplificateurs et icônes

Réalisation : les deux sources consomment directement deux `Base.Amplifier`.
Le composant intermédiaire et son butin, traductions, recette dédiée et adaptation
du démontage vanilla sont retirés. Pales/mât, pose au niveau 2 et démontage du
testeur conservés. Les poids de butin vanilla, dont les amplificateurs, restent
inchangés. Pas de modification des types publiés, réseaux ou ancres ; le type
intermédiaire non publié est retiré sans conversion des inventaires de test.

Cause des « ? », confirmée statiquement dans les sources 42.21.0 : l'aperçu de
recette lit la texture de la déclaration Item, alors que l'icône d'inventaire du
meuble était calculée sur l'instance depuis la tuile. `Icon=default` déclenchait
le repli vers Question_On. Sept PNG et déclarations explicites ajoutés ; icône
de l'éolienne conservée ; récupération de cellule orientée vers son résultat.
Preuves et chemins : NM-56 dans les notes moteur et spécifications techniques.

Contrôles hors jeu exécutés, tous codes **0** :

- `tools/check_mod.py` avec sources 42.21.0 : OK, dont ASCII Lua et dix langues.
- `test_crafting.py` avec curseur vanilla installé : **5 tests passés**, bilan
  des trois étapes, deux amplificateurs par source, niveaux et huit icônes PNG
  valides avec casse exacte. Les deux tests d'adaptation retirée sont supprimés.
- `test_loot.py` avec distributions installées : **9 tests passés**, 88 couples
  équipement/pièce et douze listes de cellules, entrées vanilla toutes conservées.
- Physique et simulation : OK ; régressions **11**, correctifs restants **14**,
  fonctionnalités **23**, mémoire **6**, interface **8**, empilage avec Lua vanilla
  **6** tests passés.
- Audit des ressources : **18 références de sortie sur 17 recettes** résolues
  dans les PNG livrés ou les atlas UI/UI2 installés ; overrides de recette valides.
  Aucun identifiant du composant abandonné ne reste dans scripts, traductions,
  générateurs, tests ou documentation. `git diff --check` : OK.

Les dix planches de recettes, tableaux et guides EN/FR ont été régénérés. Les
sept icônes ont été examinées hors jeu. Aucun hook de rendu, sondage périodique,
paquet ou cache supplémentaire : seulement recettes et ressources statiques.

Limites : pas d'essai réel en jeu, SP/MP, de rendu dans le menu ou sous Linux.
Les tests mémoire de logique ne constituent pas une mesure du tas Java réel.
Redémarrage complet du jeu/serveur requis pour retirer l'ancienne adaptation et
charger scripts/textures. Validation visuelle et fabrication à faire manuellement,
selon le choix utilisateur. Aucun commit, push ou publication.

## 2026-10-25 — wattmètre LCD du tableau

Le compteur à rouleaux est remplacé par un LCD éclairage/équipements/total en W.
Sommes depuis les familles agrégées existantes, pompes incluses par leur débit déjà
mesuré ; aucune consommation de compteur d'eau lors d'une lecture. Veille,
production, pertes et charge des batteries exclues. Les choix, protections,
couplages, recouvrements et identifiants persistants restent ceux du système en place.

Retour de zone : les caches client sont écartés à la réouverture ; `demandReady`
indique si l'inventaire chargé a été mesuré après sa dernière reconstruction.
Relevé inconnu : tirets et Actualisation ; panne générale : zéro. Un circuit
coupé sans charge résiduelle affiche 0 W / coupé. En recouvrement, une consommation
d'un autre tableau mais attribuée à cette ancre n'est pas masquée. Aucun nouveau
parcours d'appareils par image, commande, paquet autonome, historique d'énergie ou
champ de sauvegarde. Deux petites données ajoutées aux instantanés existants.

Contrôles hors jeu exécutés, tous codes **0** : `tools/check_mod.py` avec sources
42.21.0 ; physique ; simulation ; régressions **11** ; correctifs restants **14** ;
fonctionnalités **23** ; mémoire **6** ; interface **13** ; empilage avec curseur
vanilla **6** ; fabrication avec curseur vanilla **5** ; butin avec distributions
installées **9** ; `git diff --check`. Dix traductions mises à jour et contrôlées.

Les cinq nouveaux tests d'interface couvrent : quatre états, panne et valeur
inconnue ; calcul seulement à changement d'instantané et libération à fermeture ;
job borné réel sous double Lua, invalidation, déchargement/rechargement et remise
à zéro du registre simulés ; caches SP/MP à révision inchangée et réception de
nouveaux instantanés ; puissance des pompes sans mutation des litres en attente.
Les instantanés de consommateurs limités à 200 lignes ne servent pas au calcul.

Trente aperçus hors jeu (dix langues × normal/coupé/actualisation) ont été générés
par rejeu des appels de dessin Lua ; FR, RU, DE et CN examinés. Ces images et les
sorties brutes restent sous `runs/`, ignoré par Git. La capture documentaire
antérieure est conservée et identifiée comme antérieure au nouveau LCD.

Limites : le rejeu Pillow emploie des polices approchées ; il ne valide pas le
rendu réel de Project Zomboid. Aucun lancement automatique du jeu, selon le choix
utilisateur ; pas de validation réelle de ce LCD en SP, MP, redémarrage ou Linux.
Protocole manuel mis à jour. Aucun changement du modèle de blessures pendant
cette étape ; l'explication de ce modèle repose sur la lecture de ses appels.

## 2026-10-25 — risque sous tension renforcé et XP de toutes les recettes

Règles utilisateur implémentées : risque 50 % à Électricité 0, puis 42/33/25/17/8 %
aux niveaux 1–5 et nul dès 6 ; option toujours désactivée par défaut. La brûlure
suit la main du tournevis, primaire/droite ou secondaire/gauche ; outil d'inventaire
montré en primaire. Le principal du tableau, les circuits, la protection, le stock
vide et la panne ne suppriment plus le risque : arrêt explicite du maître requis.
Cet arrêt est proposé même pour un onduleur cassé, sans restaurer sa condition ni
sa capacité à charger. Débranchement sans tournevis refusé par l'autorité.

Les réparations réussies donnent déjà de l'XP ; les recettes de pales et de mât
reçoivent chacune 2 XP d'Électricité. Les 17 craftRecipe LiveWire ont désormais un
gain électrique positif. Aucun changement de coûts ou durées, schéma de sauvegarde,
identifiants persistants, architecture, fréquence de simulation ou diffusion réseau.
Les anciennes descriptions de risque de F27 et du prototype F32 sont remplacées
par les contrats révisés ; les anciens résultats de jeu restent datés de leur code.

Preuves statiques 42.21.0 : `IsoGameCharacter.getPrimaryHandItem/getSecondaryHandItem`,
`InventoryItem.hasTag`, `BodyPartType.Hand_R/Hand_L`, `BaseAction.setOverrideHandModelsObject`
et `ISBaseTimedAction.setOverrideHandModels`. Le modèle accepte un InventoryItem
ou un nom ; le mod passe l'outil réel pour préserver son apparence, sans transfert
ni nouvelle copie. `ModelManager` distingue les accessoires Prop1 et Prop2.
Journal de la session locale consulté : version exécutée 42.21.0.

Contrôles hors jeu : nouveau `test_live_work.py`, **6 tests passés, code 0** :
tirages exhaustifs 0–99 pour chaque niveau 0–10 ; principal/circuits/stock/panne ;
mains avec primaire vide, secondaire seule, deux outils, inventaire ; animation
paramétrée, douleur/brûlure sans réduction d'une blessure existante ; lâcher et
appel de synchronisation côté serveur simulé ; refus outil/refuge et interruption
avant mutation ; réparation avant dépenses/XP ; arrêt du cassé sans gain d'énergie.
`test_crafting.py` avec curseur vanilla : **6 tests passés, code 0**, dont XP
positif pour les 17 recettes. Les doubles ne prouvent ni la blessure native, ni
le rendu d'animation, ni le réseau réel.

Wiki EN/FR, règles sandbox et dix traductions en jeu mis à jour. Dix descriptions
Steam locales enrichies avec sécurité et gains d'XP, `workshop.txt` aligné sur
l'anglais. Validation locale de l'outillage Workshop : **OK**, tailles finales
suffixes Workshop/Mod IDs inclus de **6 740 à 7 954 octets**, sous la limite 8 000.
Versions JP/RU raccourcies sans retirer liens ou images. Aucun envoi Workshop.
Protocole manuel SP/MP/reconnexion complété ; aucun jeu lancé automatiquement.

Non-régression finale, tous codes **0** : `tools/check_mod.py` avec sources
42.21.0, physique, simulation, régressions **11**, correctifs restants **14**,
fonctionnalités **23**, mémoire **6**, interface **13**, empilage vanilla **6**,
butin avec distributions vanilla **9**. Audit des dix descriptions : structure
BBCode concordante, liens et images préexistants conservés ; `git diff --check` OK.
Le bloc équipement russe a été remis en cinq puces pour conserver la structure
des autres langues. Ces vérifications ne constituent pas un essai en jeu ou Linux.

## Menus contextuels, usure de debug et risque actif par défaut — 2026-10-25

Réalisé localement : une entrée par destination pour chaque appareil ; l'onduleur
garde son écran, le disjoncteur son tableau, la banque son panneau. Les autres
appareils ouvrent directement les raccordements. Le sous-menu « Debug : cet
équipement » propose −10 points, 50 %, 10 %, 0 % et 100 %, raccordé ou non.
Droits, distance, refuge, modèle/rôle, objet chargé et registre disponible sont
revérifiés côté serveur. La commande historique `damageInverter` reste compatible,
sans seconde entrée visible. Aucun traitement périodique ou schéma ajouté.

Demande suivante prise en compte : `LiveWorkRisk=true` dans le défaut sandbox et
le repli de configuration. Les règles de probabilité et d'isolation restent
inchangées. Un faux explicite sauvegardé reste prioritaire ; pas de migration
forcée. Cette décision remplace le défaut faux décrit dans la campagne précédente.

Confirmé hors jeu (tous codes de sortie **0**) :

| Contrôle | Résultat |
|---|---|
| `tools/check_mod.py` avec sources 42.21.0 | OK |
| `tests/test_physics.py`, `tests/test_simulation.py` | OK |
| Régressions / correctifs restants / fonctionnalités | 11 / 14 / 23 tests passés |
| Mémoire / interface | 6 / 13 tests passés |
| `tests/test_live_work.py` | 7 passés, dont défaut vrai et faux explicite prioritaire |
| `tests/test_menus_debug.py` | 6 passés : huit modèles raccordés/non raccordés, destinations uniques, maître couplé, banques superposées, droits, refus de cible, état borné et périmètre des mutations |
| Fabrication / empilage avec code vanilla | 6 / 6 tests passés |
| Butin avec distributions vanilla | 9 tests passés |
| Dix descriptions Steam locales | BBCode, liens/images préservés ; 6 740–7 952 octets avec suffixes |
| `git diff --check` | OK |

Traductions régénérées pour les dix langues ; guides EN/FR et spécifications
alignés. Sorties brutes dans `runs/debug-defaults-offline-results.json`, hors Git.
Les tests Lua utilisent des doubles : ils ne prouvent pas le rendu réel des menus,
la sauvegarde du moteur, les blessures natives, la reconnexion ou la synchronisation
MP. Aucun jeu lancé, conformément au choix de tests manuels de l'utilisateur ;
aucun essai Linux, commit, push ou publication. Protocole manuel complété.

## État de l'équipement dans les panneaux — 2026-10-25

Confirmé statiquement : libellé « État équipement : … % » sur LCD powerbank,
tableau électrique et raccordements (origine et liste). L'onduleur conserve son
état dans sa page existante. Les marques de l'objet sélectionné sont réutilisées,
sans champ réseau ni lecture du monde supplémentaire. Donnée inconnue : tirets ;
zéro valide ; arrondi borné. Hauteur du LCD powerbank adaptée à la police.
Charge et état des batteries restent séparés de l'état de leur powerbank.

Contrôles hors jeu, tous codes **0** : `tools/check_mod.py` avec sources 42.21.0,
physique, simulation, régressions **11**, correctifs restants **14**, fonctionnalités
**23**, mémoire **6**, menus/debug **6**, interface **16** ; `git diff --check` OK.
Trois nouveaux scénarios d'interface vérifient valeur inconnue/zéro/arrondi,
états bancaires distincts et attente/empilage, position verticale des dernières
lignes avec hauteurs de police 16/26/38, et état propre du tableau indépendant,
mort ou devant l'instantané d'un autre tableau. Le test de raccordements existant
vérifie aussi les libellés de deux objets sur 10 000 updates : préparation bornée
à une seconde, aucun nouveau parcours du monde. Dix traductions régénérées.

Sorties brutes : `runs/equipment-condition-offline-results.json`, hors Git.
Ces résultats proviennent de doubles Lua : rendu, traduction réellement affichée,
MP et retour de zone restent à vérifier manuellement. Aucun test en jeu ou Linux
revendiqué, aucun commit ni publication.

## Correction de la fermeture du tableau — 2026-10-25

Signalement utilisateur en jeu : à la fermeture par la croix. Console examinée,
frame 8077 : `LW_BreakerPanel.lua:203`, `attempted index: lights of non-table: null`.
Cause confirmée statiquement et reproduite hors jeu : `close()` effaçait `reading`
alors que le retrait du moteur est différé ; le dernier `prerender` lisait `r.lights`.
Sources 42.21.0 : `UIManager.RemoveElement` met en file `toRemove`, consommée à
l'update ; `ISUIElement.removeFromUIManager` délègue seulement à ce mécanisme.

Correction locale sur tableau, powerbank et raccordements : marque `closed`,
masquage immédiat avant retrait et libération, gardes sur dessin/update/boutons,
fermeture idempotente. Le LCD onduleur et l'écran logiciel masquent déjà leur
fenêtre et n'effacent pas les données nécessaires au dernier dessin. Pas de
modification serveur, de sauvegarde, de traduction ni de boucle supplémentaire.

Le nouveau test de régression échouait sur le code précédent (code **1**) et
passe après correction : dernier dessin/update/boutons après fermeture, répétition
du clic et préservation d'une nouvelle instance/vue bancaire. Suite interface :
**17 tests passés, code 0**. Non-régression : menus/debug **6**, mémoire **6**,
régressions **11**, correctifs restants **14**, physique, simulation,
`tools/check_mod.py` avec sources 42.21.0 et `git diff --check` : tous codes **0**.
Résultats bruts : `runs/panel-close-offline-results.json`, hors Git.

Ce sont des vérifications hors jeu ; le correctif n'a pas été retesté dans le
moteur réel, en MP ni sous Linux. Retest manuel prévu au protocole ; aucun jeu
lancé automatiquement, commit, push ou publication.

## LCD individuels et raccordements ciblés — 2026-10-25

Réalisé localement : clic sur sources/pompe/alarme vers leur LCD individuel,
avec condition et mesures propres ; boutons Raccordements sur tous les panneaux.
Depuis un équipement : une seule ligne pour cet objet, choix de l'onduleur.
Depuis un onduleur : liste globale existante. Les coûts/compétences/déplacement
et protections de raccordement restent dans les parcours autoritaires existants.
Le menu contextuel conserve une seule entrée pour chaque destination.

Confirmé statiquement : `DeviceView.snapshot` lit les seules mesures existantes.
La requête individuelle vérifie cible/objet, portée/refuge, joueur vivant,
registre et séquence ; elle utilise la limitation de débit existante. Elle répond
au seul demandeur. Une seule vue client en cache, libérée à la fermeture/session ;
cadence 2 secondes pendant ouverture, sans inventaire du monde ni pas de simulation
déclenché par lecture. La puissance des sources est leur dernier `pOut` ; la pompe
utilise son `flowLph` sans appeler `demandW` ni vider `pumped`. Alarme lue depuis
les drapeaux du réseau, sans production fictive. Aucun changement de sauvegarde,
identifiant, architecture, diffusion des ancres ou cadence physique.

Contrôles hors jeu, tous codes de sortie **0** :

| Contrôle | Résultat |
|---|---|
| `tools/check_mod.py`, sources 42.21.0 | OK |
| Physique / simulation | OK |
| Régressions / correctifs restants / fonctionnalités | 11 / 14 / 23 passés |
| Mémoire / interface / menus et debug | 6 / 17 / 6 passés |
| Risque sous tension / fabrication / empilage / butin | 7 / 6 / 6 / 9 passés |
| `tests/test_device_panels.py` | 9 nouveaux scénarios passés |
| `git diff --check` | OK |

Les nouveaux scénarios vérifient les trois sources et les coupures, l'absence
de recalcul physique à la lecture, deux pompes distinctes et leurs compteurs
d'eau, les états d'alarme, utilisateur ordinaire/refus/rate limit côté serveur
simulé, réponses désordonnées ou tardives/réouverture, 10 000 updates sans recherche
du monde et cadence bornée, fermeture, géométrie verticale des LCD sur trois
hauteurs de police, choix d'onduleur ciblé versus liste globale, absence d'onduleur
et origine des quatre types de boutons. Les tests de menus couvrent huit modèles
raccordés/non raccordés et les doublons ; fermeture tardive étendue au nouveau LCD.
Dix langues régénérées, guides EN/FR et spécifications actualisés.

Sorties brutes : `runs/individual-lcd-offline-results.json`, hors Git. Doubles Lua,
sans validation du moteur, du rendu réel, de sauvegarde/reconnexion ou de serveur
MP réel. Aucun jeu lancé automatiquement conformément au choix utilisateur ;
protocole manuel complété. Aucun test Linux, commit, push ou publication.

## LCD bleu et voyants posés — 2026-10-25

Clarification utilisateur : le LCD pompe s'ouvre bien ; demande de fond bleu,
voyant bleu sur la pompe alimentée et voyant vert sur le disjoncteur dans le monde.
Le routage du clic est conservé. Apostrophe U+2019 de « Débit d’eau » remplacée
par ASCII dans le libellé FR pour la police LCD mono. Fond/texte du LCD pompe bleus ;
palette verte conservée sur les autres appareils.

`pw` des marques existantes est calculé sur l'autorité pour pompe/tableau.
La pompe reste bleue au repos ou sans relais si alimentée ; équipements/principal
coupés, panne ou courant absent l'éteignent. Le tableau est vert si distribution
alimentée, hors panne/principal coupé ; le rouge de disjonction reste prioritaire.
Les circuits individuels seuls n'éteignent pas le tableau. Pas de nouveau paquet
ou tick ; la comparaison existante shownPw évite toute rediffusion sans changement.

Assets : Blender **5.2.3 LTS**, forge existant, deux rendus S/E tête hors interface
identiques pixel pour pixel. Nouveaux overlays 84/85 dans les cases réservées,
88 cases et mêmes identifiants. Pack relu après écriture : tous les anciens
sprites comparés identiques pixel pour pixel. Anciennes cellules de profondeur
inchangées. Raytracing B42 : **40 pixels par face**, **27/28 hits directs**,
**0 pixel hors sprite, 0 pixel sans profondeur**. Aperçu hors jeu contrôlé
visuellement ; il n'est pas une capture du moteur. Viewpoint : un modèle de
**12 triangles**, deux binds ajoutés ; palette et autres modèles non réexportés.
La recette globale conserve les propriétés de tuiles préexistantes ; aucun nouveau
changement du `.tiles` par cette installation. Recettes portables versionnables,
copie `.blend` éditable conservée avec les rendus locaux hors Git.

Source moteur observée dans le journal de la dernière session : **42.21.0**.
Contrôles hors jeu, tous codes **0** :

| Contrôle | Résultat |
|---|---|
| `tools/check_mod.py` avec sources 42.21.0, physique, simulation | OK |
| Régressions / correctifs restants / fonctionnalités | 11 / 14 / 23 passés |
| Mémoire / interface / LCD individuels | 6 / 17 / 9 passés |
| Menus/debug / risque sous tension | 6 / 7 passés |
| `tests/test_lcd_indicators.py` avec forge et baseline assets | 7 passés |
| `git diff --check` | OK |

Tests ajoutés : alimentation/coupures/pannes, pompe idle sans barils/relais,
voyant tableau indépendant des circuits, 1 000 refreshStates sans rediffusion,
sélection des deux overlays tableau et quatre pompe sans requête ou recherche,
palette bleue de pompe/verte ailleurs, apostrophe FR et comparaison des assets
pack/profondeur réellement livrés. Sorties brutes : `runs/lcd-indicators-offline-results.json` ;
géométrie, rendus, modèle éditable, baseline et rapport dans `runs/breaker-power-assets/`.
Rappel Viewpoint utilisateur traité : nouveau modèle/binds du voyant vert, bleu
de pompe 3D existant sélectionné selon alimentation. Audit de tous les liens
OBJ/MTL/palette et de leur casse : OK ; UV du vert et du bleu pointent vers les
bonnes couleurs ; géométrie du nouveau voyant alignée sur le rouge existant.
Export ciblé rejoué : chaque fichier du paquet Viewpoint identique octet pour
octet après ce second export, anciens modèles/palette conservés. Le manifeste
n'ajoute que trois lignes ; aucun réencodage des lignes préexistantes.
Ces résultats ne sont ni un test moteur/MP ni une validation Linux. Aucun jeu lancé,
commit, push ou publication. Rendu et reconnexion restent au protocole manuel.

## Revue complémentaire — points 1 à 7 — 2026-10-25

Demande utilisateur : traiter les sept premiers points de la revue des changements
non commités. Architecture modulaire événementielle à serveur autoritaire conservée.
Les points 8 (séquence de réouverture bancaire) et 9 (exclusions Git) restent hors
de cette intervention. Les changements déjà présents sont conservés ; aucun commit,
push ou envoi Workshop.

Confirmé statiquement et par doubles Lua :

1. Les appareils isolés et les travaux en cours appartiennent au service des
   circuits. Une purge de `Demand` ou un retrait du maître ne les abandonne plus.
   Une découverte déjà en file peut aussi restaurer une ancienne coupure orpheline.
2. Une intention ON de l'unité sèche-linge attend aussi le courant lorsque
   l'unité lave-linge est OFF. Le passage d'une radio sur pile libère son ancienne
   coupure secteur ; les choix des interrupteurs de pièce survivent aux lots séparés.
3. Les services MP portent une identité et une révision ; les messages reçus trop
   tôt sont repris et une lecture bornée redemande l'état natif courant. Les sprites
   ambigus attendent l'identité ; une ancienne réponse ne clôt pas une reprise dont
   la ModData signale déjà une révision plus récente. Types et cache électrique sont
   remis à jour sans remplacer les conteneurs ni leurs objets.
4. Commandes, changements de topologie et découvertes de chunks mettent le travail
   en file. Au plus 16 unités par lot, arrêt entre unités après environ 1 ms ;
   espacement minimal 20 ms pour les travaux explicites, 100 ms pour l'entretien
   seul. L'entretien des objets isolés et les travaux alternent. Un appel natif
   individuel et la réévaluation physique finale restent des coûts indivisibles.
5. Le registre indexe les seuls onduleurs par chunk ; une recherche locale ne visite
   plus les onduleurs lointains ni les autres équipements. Test avec 2 000 onduleurs
   éloignés, coordonnées négatives, déplacement, couplage et retrait.
6. La facturation conserve toutes les mesures sans construire ni trier les lignes
   d'affichage. Le rapport est calculé à la demande et retient au plus 200 lignes.
   Test sur 1 000 consommateurs : somme entière conservée, sélection correcte,
   cache réutilisé puis invalidé ; aucun appel à `table.sort`.
7. Les textes des détails du logiciel sont réutilisés pour un même instantané et
   un même onglet. Test sur 10 000 lectures répétées : aucun nouvel appel de
   traduction des lignes ; renouvellement après changement et libération à fermeture.

Vérifications hors jeu du 2026-10-25, toutes de code de sortie **0** :

| Commande | Résultat |
|---|---|
| `python -B -m unittest discover -s tests` | 136 tests recensés, 131 passés, 5 ignorés ; 15 nouveaux scénarios dans `test_review_fixes.py` |
| `python -B tests/test_physics.py` | OK |
| `python -B tests/test_simulation.py` | OK |
| `python -B tools/check_mod.py <sources-42.21.0>` | OK : Lua ASCII/syntaxe, chargement simulé, traductions, références et événements |
| `git diff --check` | OK |

Les tests utilisent Lua 5.1 et des doubles du monde, des conteneurs et du réseau.
Ils ne prouvent ni la durée réelle sous Kahlua, ni le comportement des paquets du
moteur, ni une reconnexion réelle. Aucun jeu lancé, aucun test automatique
`pz-autotest`, aucun essai Linux et aucun gain de FPS mesuré. Les tests restent
dans leur emplacement local existant, couvert par l'exclusion Git déjà présente.
Les essais SP/MP à effectuer figurent au protocole ; les nouveaux contrats et
bornes sont dans les spécifications techniques.


## Préparation de la version 1.6.0 — 2026-10-25

Mise à jour mineure importante, préparée à la demande de l'utilisateur. Les deux
`mod.info` et `LiveWire.VERSION` annoncent 1.6.0. Le changelog anglais constitue la
source de la note de changement Steam ; sa conversion BBCode porte le titre
`Version 1.6.0` et tient sous 8 000 octets. Aucun envoi Steam ni push demandé.

Confirmé statiquement :

- descriptions Steam dans dix langues, structure commune, liens utiles et images
  localisées conservés ; `workshop.txt` reprend exactement l'anglais ; toutes les
  langues tiennent sous 8 000 octets, identifiants ajoutés par l'outil compris ;
- 17 recettes comparées aux scripts livrés : ingrédients, quantités, outils
  conservés, seuils de compétence et résultats ; tableaux EN/FR synchronisés et
  dix planches `recipe_book_*.png` régénérées ;
- guides et wiki EN/FR à jour : circuits, LCD, raccordements, empilement,
  production/prévisions, maintenance, risques, recettes, butin et options ;
- construction locale du wiki par `wiki_sync.py --out <dossier-temporaire>` :
  aucun lien ou fichier image manquant ; simulation de publication sans
  `--submit` : code 0, descriptions et note acceptées par les contrôles locaux.

Vérifications hors jeu relancées : 136 tests recensés, 131 réussis et 5 ignorés ;
physique, simulation et `check_mod.py` : OK, codes 0. Les tests utilisant les
scripts vanilla sont des simulations Lua, pas une exécution native du jeu.

Confirmé en jeu par le retour utilisateur et ses captures : rendu du tableau,
du LCD de powerbank et de l'onduleur, avec le bouton de raccordements à l'intérieur
du panneau. Captures ajoutées : `docs/images/screenshots/shot6.png` et `shot7.png`.
Ce retour ne valide pas à lui seul le multijoueur, la reconnexion ou Linux.
Les campagnes SP/MP historiques ci-dessus gardent leur portée propre ; aucun
nouveau `pz-autotest` exécuté pour cette préparation documentaire.


## Publication 1.6.0 — 2026-10-25

Publication explicitement demandée après validation des notes simplifiées.
`steam_workshop_publish.py LiveWire --submit --tag` : code **0**, version 1.6.0
publiée depuis `f88aa31`, tag `v1.6.0` créé. Description anglaise et neuf
traductions publiées ; neuf captures avant/après, inchangées. API publique :
résultat 1, visibilité 0, description anglaise identique à la source locale,
mise à jour `2026-10-25T17:23:55Z`, références à `shot6.png` et `shot7.png` présentes.

Le dépôt est poussé avant publication pour rendre les images accessibles. Les
documents de statut reflètent la livraison sans étendre la portée des essais
historiques. Aucun lancement, arrêt ou test du jeu ; partie de l'utilisateur
laissée en cours.

## Correctif local — périmètre des appareils et radios — 2026-10-25

Signalement utilisateur : erreur `Object tried to call nil in kind`,
`LW_Appliances.lua:25`, dans une action radio vanilla en solo 42.21.0.
Confirmé statiquement : `ISRadioAction` reçoit aussi bien un appareil posé qu'une
radio d'inventaire ou un `VehiclePart`. Ces deux derniers peuvent renvoyer une
case mais ne possèdent pas `getContainerByType` ; la garde fondée sur la seule
position les laissait atteindre la classification des meubles. Les autres mods
du rapport ne sont pas nécessaires à cette reproduction.

Correctif : classifier uniquement les `IsoObject`, en excluant les
`IsoWorldInventoryObject`, puis laisser passer directement les actions dont
le propriétaire ne correspond à aucun service du tableau. Aucun nouvel état,
changement d'autorité, migration, identifiant ou modification de sauvegarde.

Cinq scénarios ajoutés à `tests/test_remaining.py`, dont deux utilisent le vrai
fichier vanilla `ISRadioAction.lua` installé, exécuté sous Lua 5.1 avec des doubles
typés. Avant correction : trois erreurs, dont l'appel absent signalé ; après :
cinq scénarios réussis. Périmètre vérifié :

- radio d'inventaire et autoradio : allumage/extinction normaux, circuits ouverts
  ou fermés, branche solo/autorité et branche client MP ; pile vide toujours refusée ;
- radio et TV posées sur secteur toujours bloquées par leur circuit, puis
  utilisables après rétablissement ; radio posée sur pile indépendante ;
- transferts/remplissages depuis un objet d'inventaire : arguments, retours et
  effets de l'action d'origine conservés, absence de lecture des données d'un meuble ;
- classes fixes (lumière, cuisinière, machines, chargeur) toujours reconnues ;
  réfrigérateur isolé reconnu grâce à son état sauvegardé et correctement restauré ;
- objets absents ou objets d'inventaire au sol ignorés. Le double d'héritage
  `IsoObject` du banc local `test_review_fixes.py` est corrigé pour représenter les
  vraies classes Java au lieu d'une simple égalité de noms.

Suite hors jeu : `python -B -m unittest discover -s tests`, code **0**,
141 tests recensés, 136 réussis, 5 ignorés. Aucun jeu lancé, aucune reproduction
native en Kahlua ni connexion multijoueur réelle : ces essais ne sont pas annoncés
comme une validation en jeu. Correctif local, non publié à ce stade.

Complément demandé : le garde-fou reste fondé sur le type natif avant toute
lecture de méthode. Deux scénarios supplémentaires couvrent un propriétaire
inconnu dont l'accès à une méthode lève lui-même une erreur, puis un futur
sous-type d'`IsoObject` sans service électrique reconnu. Le premier est ignoré
sans lecture de ses membres ; le second n'est pas affecté à un tableau. Les
actions d'origine restent appelées. Confirmé par doubles Lua, sans exécution
native Java : sept scénarios ciblés réussis ; suite complète, code **0**,
143 tests recensés, 138 réussis et 5 ignorés. `git diff --check` : code **0**.


## Publication corrective 1.6.1 — 2026-10-25

Demandée explicitement par l'utilisateur : changelog, commit, push et publication
avec la note de changement. Contenu livré depuis `ba7ef61`, versions Lua et des
deux mods à 1.6.1, tag `v1.6.1`. Simulation préalable : code **0**, aucun blocage.
`steam_workshop_publish.py LiveWire --submit --tag` : code **0**, publication
principale et neuf traductions confirmées. Onze captures avant et après l'envoi,
inchangées. API publique : visibilité 0, résultat 1, description anglaise
identique à la source ; mise à jour `2026-10-25T20:57:53Z`.

Contrôles de préparation relancés : suite complète, code **0**, 143 tests
recensés, 138 réussis, 5 ignorés ; `check_mod.py` avec les sources 42.21.0 :
code **0**, OK ; `git diff --check` : code **0**. Les essais de physique et de
simulation sont également OK dans le passage de correction précédent.
Aucun jeu lancé ni test natif Kahlua/MP/Linux effectué pour publier : la portée
reste celle des contrôles statiques et des scénarios Lua hors jeu ci-dessus.
