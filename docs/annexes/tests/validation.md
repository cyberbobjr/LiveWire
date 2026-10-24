# Live Wire — bilan de validation SP/MP

Campagnes du 2026-10-24, Build 42.21. Ce bilan regroupe les essais des correctifs
CXX ; le [suivi](../../ameliorations-et-idees.md) indique leur état de publication.
C11 reste différé et C20 est exclu. Aucune extension IXX n'est réalisée par ces campagnes.

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
