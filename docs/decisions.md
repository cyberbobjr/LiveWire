# Live Wire — décisions

## Maintien du fonctionnement et marquage du tableau — 2026-10-24

Après examen des variantes par bâtiment et lignes distantes, l'utilisateur choisit
de conserver le fonctionnement actuel par portée d'onduleur. Aucune migration de
réseau ni de sauvegarde engagée. Il demande une mention « legrand » sur le coffret,
avec les couleurs de la marque : rouge, noir et fond blanc. Plaquette dessinée en
primitives ISUI ; référence : [histoire officielle du logo](https://www.legrand.com/fr/le-groupe/notre-histoire).

## Complément d'ergonomie autorisé — 2026-10-24

Demande utilisateur : LCD sur chaque powerbank, panneau unique de raccordement,
ouverture des équipements au clic simple, et « ghost » coloré sur les consommateurs
à la place des repères décalés. Réalisation locale dans le pattern existant, sans
migration : interface cliente, actions et modèle de batterie autoritaires réutilisés.
L'ouverture d'un panneau ne donne aucun droit supplémentaire sur le réseau.

Le [plan](annexes/plans/acces-equipements.md) définit les lots ; les preuves et
limites de validation sont dans le [bilan](annexes/tests/validation.md).


**Toutes les décisions de conception ont été validées par l'utilisateur le 2026-10-17.** Ce fichier garde la trace de ce qui a été choisi et pourquoi.

**Méthode pour les prochaines décisions** (demande de l'utilisateur) : une question à la fois, avec **3 réponses fermées et 1 réponse libre**. Chaque nouveau choix est ajouté ici.

## Exigences de l'utilisateur (non négociables)

- **Onduleur posable à l'intérieur** d'une maison.
- **L'installation fonctionne sans joueur** dans la zone.
- **Usure et très léger bruit de l'onduleur** acceptés.
- **Trois rôles distincts** :
  - les **sources** fournissent la puissance ;
  - les **batteries** la stockent ;
  - l'**onduleur** la convertit.
- **Système minimal** = une source et un onduleur. La batterie est facultative, et les autres équipements sont optionnels.
- **Micro-onduleur intégré à chaque source**, qui lisse sa production.
- **Disjoncteur posé sur un mur**, comme un vrai disjoncteur.
- **Powerbank** pour stocker les batteries ; **aucune batterie au sol**.
- **Plusieurs sources par onduleur**, et **rayon d'alimentation centré sur l'onduleur**.
- **Retirés** : parafoudre, programmateur horaire, régulateur solaire.
- **Modèles 3D** : formes géométriques simples en attendant les modèles définitifs.
- **Générateur de secours** : un générateur vanilla, branché comme alimentation de secours, qui s'allume quand les batteries sont vides et s'éteint quand elles sont rechargées (2026-10-17).
- **Ordinateur de gestion** : un **vrai ordinateur du jeu**, et une **alarme de batterie faible** (2026-10-17).
- **Outils de debug** : menus réservés au mode `-debug` en solo et aux admins en multijoueur (2026-10-17).
- **Équipements posés = de vraies tuiles** (2026-10-17) : chaque équipement posé est une tuile du mod, posée, tournée et ramassée comme un meuble vanilla. Pas d'objet 3D posable n'importe où.
- **Un seul onduleur** (2026-10-17) : l'onduleur renforcé n'a jamais été demandé ; il est supprimé.
- **Sources raccordables : panneau, éolienne et roue à aubes** (2026-10-17).
- **Frigos et congélateurs** (2026-10-17, non négociable) : ils doivent rester froids quand le joueur quitte la zone, pour que la nourriture ne pourrisse pas.

## Décisions validées

| N° | Sujet | Choix retenu |
|---|---|---|
| D-1 | Contenu de la v0.1 | Socle : testeur, onduleur, batteries facultatives, solaire, éolien, disjoncteur, compétence, usure, tableau de bord, fonctionnement sans joueur |
| D-2 | Mécanisme d'alimentation | **Ancre d'alimentation** posée par le mod, reposée à chaque chargement, sur le serveur et chez les clients (`architecture.md`, § 1.4). Repli si le prototype P1 échoue : vrai générateur caché dehors |
| D-3 | Raccordement | Explicite, par menu, en consommant du fil électrique (1 fil pour 4 cases, portée 12) |
| D-4 | Batteries | Rangées dans une **powerbank** qui s'ouvre comme une caisse (4 batteries comptées). Plus de batterie au sol. Choix de l'utilisateur, le 2026-10-17 : « rangement ouvrable », préféré à des emplacements gérés par menu et à une capacité fixe. Depuis 0.1.1, le conteneur vient de la tuile (`container = livewirepowerbank`, capacité 50) : le jeu le crée et le marque exploré à la pose, donc sans butin |
| D-5 | Échelle d'énergie | 1 unité de consommation moteur par heure = 1 000 W (option `PowerScale`) ; c'est le profil « valeurs du jeu » de D-28 |
| D-6 | Apprentissage des recettes | Automatique au niveau requis |
| D-7 | Propriété en multijoueur | Installations communes, règles de safehouse vanilla |
| D-8 | Bruit de l'onduleur | Zombies : rayon 2 (option `InverterNoiseRadius`). Joueurs : ronronnement de réfrigérateur vanilla **`FridgeHumA`**, choisi par l'utilisateur, joué localement |
| D-9 | Sans joueur dans la zone | Tout continue (option `SimulateUnloaded`, vraie par défaut) |
| D-10 | Recouvrement avec un générateur vanilla | v0.1 : les deux paient les appareils communs ; v0.2 : bascule automatique |
| D-11 | Équipements optionnels | Disjoncteur mural, ordinateur de gestion (vrai ordinateur de bureau vanilla) et alarme de batterie faible, **tous en 0.1** (avancés à la demande de l'utilisateur, 2026-10-17) |
| — | Dégâts d'orage | **`LiveWire.StormDamage` désactivée par défaut** |
| D-12 | Zone alimentée par l'onduleur | **Rayon autour de l'onduleur** (20 cases, ±3 étages, réglages vanilla des générateurs) : tous les appareils de la maison dans cette zone sont alimentés, sans raccordement. Préféré, le 2026-10-17, à « tout le bâtiment » et à « bâtiment et terrain » |
| D-3 (confirmé) | Raccordement des équipements du mod | **Manuel**, par « Raccorder à l'onduleur », avec du fil électrique. Reconfirmé le 2026-10-17, préféré au raccordement automatique |
| D-14 | Générateur de secours | Générateur vanilla raccordé (niv. 3, un par réseau). Démarre sous 20 %, s'arrête à 90 % (options). 1 200 W, 1 L pour 3 kWh, en plus de sa consommation vanilla. Ne démarre que par un onduleur en marche et s'il y a des batteries. Reste vanilla, donc toxique à l'intérieur |
| D-15 | Outils de debug | Solo : `isDebugEnabled()`. MP : `checkPermissions` **et** `getRole():hasCapability(ChangeAndReloadServerOptions)`, revérifiés sur le serveur, journalisés |
| D-13 | Interface de gestion | Fenêtre de l'onduleur : production et consommation, batteries, sources par famille (solaire, éolien, hydraulique), maison alimentée par famille d'appareils, équipements, boutons Allumer, Éteindre et Réarmer |
| D-16 | Aspect et pose des équipements (2026-10-17, demande de l'utilisateur) | **Tuiles du mod** `batman_livewire_01` (tiledef 7174), formes géométriques provisoires rendues avec Blender. Le kit est un meuble posable `Base.Mov_LiveWire_*` ; la pose, la rotation et le ramassage sont ceux du curseur de meubles vanilla (tournevis et niveau d'Électricité exigés par la tuile ; le niveau est remplacé par D-29). Plus d'action « Installer » ni « Démonter » du mod |
| D-17 | Onduleur renforcé (2026-10-17) | **Supprimé** : jamais demandé par l'utilisateur |
| D-18 | Roue à aubes (2026-10-17) | **Avancée en 0.1** : l'utilisateur veut raccorder panneau, éolienne et hydraulique. Règles reprises du § 3.4 de [`specifications-fonctionnelles.md`](specifications-fonctionnelles.md) : 120 W jour et nuit, saison, berge d'une rivière au niveau 0, Électricité 7 |
| D-19 | Raccordement par menu (2026-10-17) | Clic droit sur un équipement : son état (« Raccordé à l'onduleur à N cases » ou « Non raccordé ») puis la liste des onduleurs à portée, avec distance et nombre de fils. Clic droit sur l'onduleur : « Raccorder un équipement » et « Débrancher un équipement », listes des équipements à portée. Les onduleurs sont cherchés sur les cases chargées autour, plus dans la table des ancres |
| D-8 (révisé) | Bourdonnement de l'onduleur (2026-10-17) | `FridgeHumA` n'était pas audible en jeu. Remplacé par un **son du mod** (`LiveWireInverterHum`, bourdonnement électrique de 100 Hz synthétisé, `source/sound/make_hum.sh`), entendu à moins de 10 cases tant que l'onduleur est allumé, alimenté ou non |
| D-20 | Disjoncteur (2026-10-17) | Avec un disjoncteur raccordé, c'est **lui qui saute** en cas de surcharge (demande des appareils > 1 500 W à un pas de simulation) ; l'onduleur reste allumé et n'est pas abîmé ; on réarme **sur le disjoncteur**. Sans disjoncteur, l'onduleur disjoncte, perd 3 points d'état et se réarme sur l'onduleur. Tuile du disjoncteur plus petite |
| D-21 | Voyants et pièces mobiles (2026-10-17) | Calques de tuile posés par le client : écran allumé de l'onduleur, voyant rouge de défaut, voyant vert « raccordé » sur les sources et la powerbank, pales de l'éolienne qui tournent avec le vent, lampe rouge du disjoncteur déclenché, gyrophare de l'alarme |
| D-22 | Alarme de batterie faible (2026-10-17) | Elle sonne à chaque pas de simulation (10 minutes de jeu) tant que le stock reste sous 20 % et que personne ne l'a coupée (« Couper la sonnerie ») ; son gyrophare reste allumé jusqu'au retour au-dessus de 25 % |
| D-23 | Écran de l'onduleur et ordinateur (2026-10-17) | L'onduleur a un **écran LCD** : 5 pages (production/conso, batteries, sources, maison, état), boutons < et >, bouton marche/arrêt avec voyant, RESET en cas de disjonction. La **vue complète** est le logiciel de gestion, sur un ordinateur raccordé. Avec le **Computer Mod** (facultatif, et son Laptop Mod), le logiciel vient d'un **disque trouvé dans le butin**, s'installe sur l'ordinateur ou le portable et apparaît comme une application « Live Wire » sur son bureau |
| D-24 | Zone alimentée (2026-10-17) | Option « Afficher la zone alimentée » sur l'onduleur : cercle dessiné au sol, à l'étage du joueur |
| D-25 | Panneau solaire (2026-10-17, demande de l'utilisateur) | **10 cellules** par panneau. « Démonter une calculatrice » (comme le démontage vanilla : tournevis, sans niveau) donne 1 déchet électronique et 1 cellule. Cellules dans le butin des garages, ateliers et électriciens ; panneaux tout faits dans les garages, ateliers et quincailleries |
| D-26 | Logiciel de gestion (2026-10-17, demande de l'utilisateur) | Un **vrai logiciel** à l'écran d'un ordinateur, le même partout (`client/LW_SoftwareApp.lua`) : en-tête, onglets Vue d'ensemble, Batteries, Sources, Maison, Historique, Équipements ; production et consommation à la même échelle ; commandes de l'onduleur. **Avec le Computer Mod ou le Laptop Mod** : application de leur bureau, dans leur fenêtre (barre de titre, réduire, fermer, barre des tâches). **Sans eux** : notre écran d'ordinateur (moniteur, démarrage, barre d'état), ouvert depuis l'ordinateur raccordé. La fenêtre « tableau de bord » est supprimée |
| D-8 (révisé 2) | Volume du bourdonnement (2026-10-17) | Jugé insupportable au premier essai : volume divisé par 10 (0,045), portée 6 cases, sifflement aigu retiré |
| D-8 (révisé 3) | Portée du bourdonnement (2026-10-17, utilisateur) | **Une case** autour de l'onduleur, au même étage : son coupé au-delà de 1,5 case du centre (atténuation du son : pleine force jusqu'à 0,5 case, nulle à 2). **Volume réglable par joueur** dans *Options > Mods > Live Wire* (0 = coupé) |
| D-27 | Kit d'insonorisation (2026-10-17, choix de l'utilisateur) | Fabriqué au niveau 2 d'Électricité (4 planches, 10 clous, 4 bandes de tissu, marteau gardé), posé sur l'onduleur avec un tournevis (« Insonoriser l'onduleur »), retiré en le rendant. Effets : plus de bourdonnement pour les joueurs, plus de bruit pour les zombies, usure de l'onduleur +25 %. Il suit l'onduleur quand on le ramasse |
| D-28 | Profils de consommation (2026-10-21, demande de l'utilisateur après un retour Workshop) | Option sandbox **liste** `ConsumptionProfile` plutôt que des multiplicateurs chiffrés : ultra-réaliste 1993, réaliste 1993, **valeurs du jeu (défaut, sauvegardes inchangées)**, confort. L'état allumé reste celui du moteur ; le profil donne la puissance par type d'appareil. Appareils de deux cases toujours comptés deux fois (comme le vanilla) ; limite de l'onduleur inchangée (1 500 W, 6 000 W couplés) |
| D-29 | Niveaux : brancher, pas poser (2026-11-07, demande de l'utilisateur : « poser ne nécessite pas de niveau, c'est brancher qui nécessite un niveau ») | **Poser, tourner : aucun niveau ni outil ; ramasser : tournevis, sans niveau.** Brancher un appareil à un onduleur exige le niveau d'Électricité de **cet appareil** : panneau 3, éolienne 2, roue à aubes 2, powerbank 2, disjoncteur 3, alarme de batterie 2, pompe à eau 3, générateur de secours 2, ordinateur de gestion 3. Coupler deux onduleurs : 3 (inchangé). **Mettre un onduleur (ou une armoire) en service = son premier branchement** : niveau 3 requis ; ensuite, un appareil de niveau 2 se branche à un onduleur en service avec un joueur de niveau 2 (une sauvegarde où un onduleur porte déjà des équipements compte comme en service). Relier un baril à la pompe à eau : sans niveau (tuyauterie) ; la pompe elle-même se branche à l'onduleur au niveau 3. Rendement de pose, bonus d'installateur (usure −25 % aux niveaux 9-10) et facteur d'usure de la batterie de la powerbank viennent du niveau d'Électricité de **celui qui branche** l'appareil (et, pour l'onduleur, de celui qui le branche ou qui le met en service) ; le meilleur niveau vu est conservé (un meilleur électricien qui rebranche améliore, un plus faible ne baisse jamais). Valeurs inchangées : 0,85 (moins de 7), 0,95 (7-8), 1,0 (9-10). XP de l'appareil (mêmes montants qu'avant) donnée **une fois, au premier branchement**, et non plus à la pose ; plus de 3 XP forfaitaires par branchement d'appareil (un générateur ou un ordinateur vanilla garde 3 XP, plus l'XP de l'onduleur si ce branchement le met en service). Couplage : 5 XP (plus celle de l'onduleur si due). Option sandbox `SkillGates` : couvre désormais tous ces niveaux. Niveaux de fabrication inchangés. Remplace les niveaux de pose de D-16. |
| D-30 | Recharge sur le réseau public (2026-11-07, demande de l'utilisateur après avoir vu ses batteries ne pas se recharger alors que le courant mondial fonctionnait) | Option sandbox `GridCharging`, **activée par défaut**. Tant que le réseau public existe (`getElecShutModifier()`, même règle que le vanilla) et que la case de l'onduleur est dans une pièce qui n'est pas sans courant (`isNoPower`, comme les appareils vanilla), l'onduleur tire au plus 20 % de sa puissance continue (300 W, armoire 900 W, esclaves compris) : d'abord pour couvrir ce que les sources ne fournissent pas (consommation propre comprise), puis pour charger les batteries (rendement 0,90). Les sources passent avant ; le réseau n'est tiré que si besoin (aucune « production perdue »). Onduleur cassé : rien ; éteint ou disjoncté : charge quand même, comme le surplus solaire. Le site est mémorisé pour les pas hors chargement. **Affichage** (2026-11-07, option 1 choisie par l'utilisateur) : écran de l'onduleur, page Bilan, ligne `SECTEUR n W` seulement quand le réseau est tiré ; page Sources, ligne `Réseau public : n W` tant que l'onduleur peut s'en servir (0 W après la coupure). PROD reste la seule production des sources. Aucune date de coupure affichée. |

## Campagne de correctifs autorisée — 2026-10-24

L’utilisateur autorise explicitement les corrections des catégories « bugs bloquants »
et « performances » de la revue : C07, C09, C22, C04, C05, C06, C16 et purge mémoire
de C23, avec planification, principes SOLID et essais SP/MP. L’architecture modulaire
autoritaire existante est conservée ; aucun changement de pattern ni de schéma
persistant. Le frein explicite réversible fait partie de C22. Les autres idées
restent proposées, notamment les compléments visuels/alerte de I14. Le plafond global d’expérience de C23 a ensuite été réalisé ;
voir le [suivi actualisé](ameliorations-et-idees.md) et le [bilan de validation](annexes/tests/validation.md).

## Campagne IXX autorisée — 2026-10-24

Autorisation explicite : I01, I02, I03, I04, compléments I05, I07, I09, I10,
I11, I12, I13, compléments I14, I15, I18 et I21. I12 remplace le recyclage en
plaques par la réparation du même objet ; reconditionnement existant étendu.
I21 inclut une GUI de tableau électrique dessiné, inspirée de la façade LCD.
Le dessin a ensuite été revu d'après la photo de coffret fournie par l'utilisateur
et les [exemples de tableaux modulaires Legrand](https://www.legrand.fr/catalogue/tableaux-electriques-et-disjoncteurs/tableau-electrique) :
coffret clair, capot translucide, modules sur rail, pôles liés et principal orange.
La façade est dessinée en primitives natives du jeu.
Pattern modulaire événementiel à serveur autoritaire conservé.

Le [plan](annexes/plans/campagne-ixx.md) précise dépendances et critères.
Les quatre états indépendants de I21 utilisent des adaptateurs de service vanilla :
types frigorifiques temporairement inertes, activation des machines et refus de
distribution du carburant. L'ancien diagnostic fondé sur l'absence de setter de
courant par appareil est retiré. [Preuves, portée et migration](annexes/recherches/circuits-42-21.md).
Aucun changement de pattern ni correctif Java.

I06, I08, I16, I17, I19, I20 exclus ; C11 différé, C20 exclu.
Commit, push et publication sur ordre séparé. Les notes Steam resteront sans
section de tests ou de validation.


## Empilage de deux powerbanks — 2026-10-24

Autorisation utilisateur : poser une powerbank supplémentaire sur une banque
existante afin d'augmenter le stockage. Choix de réalisation : empilage physique
vanilla de deux objets existants, quatre emplacements chacun, conteneurs et
raccordements indépendants, sélection du niveau dans le LCD. Retrait/rotation et
recyclage du support refusés tant qu'un objet repose dessus. Aucun nouveau modèle
ni changement d'architecture, d'identifiant ou de schéma de sauvegarde.

## Butin d'équipements — 2026-10-25

Demande utilisateur : option sandbox pour augmenter les découvertes, élargissement
des lieux et **×5 par défaut**. Réalisation : multiplicateur des poids 1–20, huit
familles d'objets existantes, huit catégories de butin supplémentaires. Seuls les objets propres à LiveWire sont concernés, cellules incluses ; le CD garde son taux ; roues et pompes restent à fabriquer. Aucun remplissage
de sauvegarde. Le changement s'applique au redémarrage aux prochains tirages,
sur l'autorité seulement, sans nouveau traitement par image ou modification réseau.

Périmètre final précisé par l'utilisateur : uniquement les pièces et équipements
du mod. Le traitement des six composants vanilla est retiré intégralement ;
aucun de leurs poids ni aucune de leurs entrées de butin n'est modifié.

## Sources accessibles, pales, mât et amplificateurs — F32, 2026-10-25

Choix utilisateur final : deux `Base.Amplifier` directement dans chaque machine.
Le démontage des haut-parleurs garde son fonctionnement vanilla (amplificateur
et déchet électronique). Aucun nouvel ingrédient intermédiaire. Pose de
l'éolienne et de la roue à Électricité 2, fabrication à 6/7. Pales et mât sont
fabriqués séparément ou trouvés, puis consommés par l'assemblage de l'éolienne.
Éolienne complète plus accessible, roue ajoutée au butin. Butin limité aux objets
LiveWire ; fréquence des amplificateurs vanilla inchangée.
Plan : [fabrication et composants](annexes/plans/fabrication-eolienne-et-composants.md).

## Sécurité et progression électrique — 2026-10-25

Choix utilisateur : risque 50 % au niveau 0, blessure de la main du tournevis,
arrêt de l'onduleur obligatoire pour isoler les interventions ; le principal du
tableau n'est pas une protection de maintenance. Progression retenue 50/42/33/25/17/8,
nulle dès 6 ; option ensuite activée par défaut sur demande utilisateur. Arrêt explicite disponible
après panne ou disjonction, sans réparation implicite. Toutes les recettes donnent
de l'XP électrique : ajout de 2 XP pour pales et mât. Les réparations réussies
récompensent déjà l'Électricité. Guides et dix descriptions Steam locales enrichis,
sans publication. Les anciennes règles de risque sont remplacées par ce contrat.


## Debug par équipement et risque par défaut — 2026-10-25

Choix utilisateur : actions contextuelles pour abîmer les équipements, suppression
des entrées ouvrant le même panneau, risque d'intervention activé par défaut.
Les choix sandbox déjà enregistrés restent prioritaires. Pas de migration du
pattern, du registre, des identifiants ou des sauvegardes.

## Portée verticale des câbles — 2026-10-27

Proposition validée par l'utilisateur, avec confirmation explicite du défaut à
**3 étages** : remplacer la limite fixe de 1 étage par `LiveWire.LinkVerticalRange`,
entier de 0 à 10, appliqué aux raccordements d'équipements et au couplage
d'onduleurs, au-dessus comme au-dessous. 0 limite les nouvelles liaisons au même
étage. La portée horizontale et la couverture électrique restent distinctes.
Les liaisons existantes sont conservées ; aucune migration de données ni de pattern.

## Équipements sur les étagères de garage — 2026-11-03

Signalement utilisateur : aucun équipement trouvé dans des dizaines de garages. Mesure
en jeu sur les listes parsées : le butin sort bien, mais une partie créée avant l'ajout
du butin garde ses conteneurs déjà remplis, et les étagères de garage tirent surtout
des listes menuiserie, mécanique et métallurgie, presque sans équipement. Choix
utilisateur : ajouter quelques équipements aux étagères de mécanique et de métallurgie,
puis davantage de panneaux solaires sur ces étagères et des équipements dans les véhicules
d'électricien (et de métallier pour l'éolien). Pas de remplissage rétroactif des conteneurs
ni des véhicules déjà générés.

## LiveWire Extended et meubles de plusieurs cases — 2026-11-08

Origine : idée I22 (commentaire Steam du 2026-11-07), analyse du mod Workshop 3779562002
(LG Extended Electricity et LG Realistic Power Usage, variante `42.20`) présentée le 2026-11-08.
Plan de livraison : [`annexes/plans/livewire-extended.md`](annexes/plans/livewire-extended.md).

| # | Sujet | Décision |
|---|---|---|
| D-31 | Meubles de plusieurs cases (2026-11-08, demande de l'utilisateur) | **Live Wire de base** compte un appareil de plusieurs cases **une seule fois**, sur la case d'origine de sa grille de sprites (`IsoObject.getSpriteGridObjectsIncludingSelf`, `IsoObject.java:5047`). Vaut pour la facture, le délestage et l'affichage. **Remplace** la phrase de D-28 « appareils de deux cases toujours comptés deux fois (comme le vanilla) », choisie le 2026-10-21 pour ne pas changer les sauvegardes : l'utilisateur préfère désormais la consommation juste. Limites de l'onduleur inchangées. Le double comptage actuel est confirmé statiquement côté Live Wire (`LW_Demand.lua:250-268`) ; son existence côté moteur pour chaque meuble reste à mesurer (étape E0 du plan) |
| D-32 | Sous-mod facultatif (2026-11-08) | Nouveau mod **`batman_LiveWireExtended`**, nom affiché « LiveWire Extended », dans le même dépôt, `require=batman_LiveWire`, sur le modèle de `batman_LiveWireViewpoint`. **Sans lui, Live Wire fonctionne exactement comme avant** : la base reçoit seulement un point d'extension « couverture » (quelles cases alimente un onduleur), dont l'implémentation par défaut est le disque actuel (D-12). Le sous-mod ne modifie ni `GeneratorTileRange` ni `GeneratorVerticalPowerRange`, et range ses données sous sa propre clé ModData : le décocher ramène au disque sans menu de sortie. Il se déclare incompatible avec `LGExtendedElectricity`, qui force `GeneratorTileRange` à 1 alors que Live Wire en tire sa portée (`LW_Config.lua:52`). Création indépendante (`developpement.md`) : mécaniques reprises, ni code, ni texte, ni nom, ni asset de ce mod |
| D-33 | Périmètre (2026-11-08, choix de l'utilisateur : « tout, lampadaires compris ») | Avec le sous-mod : **bâtiment entier** (tous les étages, toit, sous-sol, bande extérieure réglable) sur action du joueur ; facture, disjoncteur et partage par les règles existantes de Live Wire ; **relais vers un bâtiment éloigné** ; **lampadaires** raccordables ; vue de la zone alimentée. Exclus car propres aux générateurs : carburant, fûts, conduites, pompes de station, reprise de la portée des générateurs. Pour qui active le sous-mod, cette couverture s'ajoute au rayon de D-12 au lieu de le remplacer |
| D-34 | Alimenter une zone extérieure (2026-11-08, solution D choisie par l'utilisateur) | **Borne extérieure + zone réglable.** Le joueur pose une borne, la raccorde à un onduleur avec du fil, puis trace sa zone dans une limite autour d'elle. Le moteur alimente par blocs de 8 × 8 cases (`IsoChunk.java:4773`, `IsoGenerator.java:637`) : la zone tracée s'arrondit aux blocs, et l'aperçu montre les cases réellement alimentées. Couvre les constructions des joueurs, solo comme serveur dédié. Dehors, l'option vanilla « générateur en extérieur » reste souveraine (`IsoGridSquare.java:8224`) |

**Réglages par défaut (confirmés par défaut, modifiables par l'utilisateur)** :
raccorder un bâtiment se fait par une action sur l'onduleur ou sur une borne, sans outil ni fil, au niveau 3
d'Électricité (celui de la mise en service, D-29) ; bande extérieure d'une case, option sandbox de 0 à 8 ; une borne
couvre au plus 2 × 2 blocs (16 × 16 cases) et ±1 étage de sa position, se fabrique et se branche au niveau 3, et se relie
par les règles de câble existantes (`LinkRange`, `LinkVerticalRange`, `WirePerTiles`) ; une borne posée dans ou près
d'un bâtiment éloigné peut aussi « raccorder le bâtiment » : c'est le relais de D-33, sans objet supplémentaire.

**Lampadaires reportés (2026-11-08, choix de l'utilisateur)** : les lampadaires de D-33 ne font pas partie de la
première version. L'arbitrage Q01 (changer l'image du lampadaire raccordé, retirer la marque de toutes les images, ou
poser une lumière invisible à son pied) est suspendu ; la piste privilégiée reste le changement d'image avec un
débranchement de sortie. Le moteur interdit tout courant de générateur à un lampadaire de rue
(`IsoLightSwitch.java:765`, `:813`, `LightingJNI.java:261`).

**Production solaire et saisons (2026-11-08)** : la durée du jour suit déjà la date (aube et crépuscule du moteur,
latitude 38°, `ErosionSeason.java:380-421`, lus par `LW_Simulation.lua:35-36`). L'ajout d'un facteur de hauteur du
soleil à midi a été proposé puis **écarté par l'utilisateur** : modèle inchangé.

## LiveWire Extended : tableaux électriques et disjoncteurs par appareil — 2026-11-08

Demande de l'utilisateur : des tableaux électriques où les joueurs raccordent directement des disjoncteurs à des points
électriques (interrupteurs, appareils, pompes à eau, ordinateurs, machines à coudre de My Tailor Is Rich, appareils de
Functional Appliances 2, et tout appareil d'un autre mod), avec des disjoncteurs renommables pour cartographier
l'installation. Plan : [`annexes/plans/livewire-extended.md`](annexes/plans/livewire-extended.md), étapes E12 et
suivantes.

| # | Sujet | Décision |
|---|---|---|
| D-35 | Tableau et disjoncteurs (2026-11-08) | Dans **LiveWire Extended** : tableau mural de 8, 16 ou 24 modules relié à un onduleur ; disjoncteurs à installer (objets de 15, 20 et 30 A en 120 V, double 30 A en 240 V pour four et sèche-linge) ; chaque disjoncteur protège son circuit et saute au-delà de son calibre, seul ; réarmement sur le tableau. Le disjoncteur et le tableau à deux circuits de la base (D-20, I21) restent le **disjoncteur général** du réseau |
| D-36 | Raccordement d'un point (2026-11-08) | Clic droit sur l'appareil « Raccorder au tableau… », ou depuis le tableau ; fil selon la distance, tournevis, niveau d'Électricité selon l'appareil. Une **pièce** et son interrupteur mural forment un seul point d'éclairage ; une borne extérieure (D-34) est un point dont toute la zone suit le disjoncteur. Étiquette de chaque disjoncteur modifiable au stylo ou au crayon (`Base.Pen`, `Pencil`, `RedPen`, `BluePen`), texte filtré et validé par le serveur ; fenêtre du tableau avec charge par circuit, « Localiser », et circuit indiqué dans l'info-bulle de l'appareil |
| D-37 | Appareil non raccordé (2026-11-08, choix 2 de l'utilisateur) | **Dès qu'un tableau dessert un bâtiment ou une zone, un appareil qui n'y est pas raccordé n'a plus de courant.** Sans tableau, la règle actuelle de la zone s'applique (tout est alimenté). Réalisme maximal assumé : poser un tableau impose de câbler |
| D-38 | Appareils pris en charge (2026-11-08) | Registre d'**adaptateurs** dans Extended (reconnaître, consommation, état, couper, rétablir). Premiers adaptateurs : les familles vanilla déjà isolées par I21 ([circuits-42-21](annexes/recherches/circuits-42-21.md)), la pompe à eau et l'ordinateur Live Wire, les machines à coudre de My Tailor Is Rich (son test de courant `MTIR_SewingMachine.lua:104-112` interrogera Live Wire s'il est présent, sans dépendance obligatoire), Functional Appliances 2 (`FunctionalAppliances2`, 3042138819, variante 42.20 : ses menus et son serveur testent `square:haveElectricity()`, méthode de coupure à mesurer). Un appareil de mod aux classes vanilla est couvert d'office ; les autres demandent un adaptateur |
| D-39 | Idées retenues et écartées (2026-11-08) | **Retenus** : interrupteur crépusculaire sur un disjoncteur (circuit allumé seulement entre le crépuscule et l'aube du jour) ; **compteur par circuit** (kWh du jour et historique, ajouté le 2026-11-08 à la demande de l'utilisateur). **Écartés** : différentiel, sous-tableau. Non retenue faute de décision : consignation au cadenas. **Précision (2026-11-11, choix de l'utilisateur)** : l'interrupteur se pose sur un disjoncteur, ce n'est pas un module à part ; l'objet s'appelle désormais « interrupteur crépusculaire pour disjoncteur » et son info-bulle dit où il se pose, que le disjoncteur est fermé la nuit et ouvert le jour, et que l'heure suit les saisons (aube et crépuscule de `ErosionSeason`) |
| D-41 | Niveau et XP d'un raccordement (2026-11-09, choix de l'utilisateur) | Raccorder un appareil, une pièce ou une borne à un disjoncteur demande le **niveau 3** d'Électricité pour tout appareil, comme la borne et le tableau, et rapporte **5 XP** par raccordement |
| D-42 | Tableaux des maisons : répartition et fréquence (2026-11-09, choix de l'utilisateur) | Circuits précâblés **par pièce** : un disjoncteur 20 A par pièce (son éclairage et ses appareils), cuisinière et sèche-linge chacun sur leur propre double 30 A (remplacé le 2026-11-09 par un 30 A simple, D-43). Option sandbox de part des bâtiments recevant un tableau (coffret vanilla repris s'il existe, sinon tableau Extended) : **30 %** par défaut |
| D-43 | Disjoncteurs : calibres, recette, butin (2026-11-09, choix de l'utilisateur) | **Plus de disjoncteur double 30 A en 240 V** (trop compliqué) : seulement 15, 20 et 30 A en 120 V, un module chacun ; D-35 modifiée en ce sens, la décision précédente gardée ci-dessus. Recettes au **niveau 3** ; ingrédients selon le calibre (15 A : 1 débris électronique, 1 fil, 1 vis ; 20 A : 2, 1, 2 ; 30 A : 3, 2, 3) ; interrupteur crépusculaire : 2 débris, 1 fil, 1 vis. **Butin et recette** : disjoncteurs chez les électriciens, quincailleries, entrepôts d'électricité, camion d'électricien, et un peu dans les garages et caisses à outils des maisons ; tableaux et interrupteurs crépusculaires seulement chez les professionnels, plus rares ; le tout multiplié par l'option de butin d'équipement de Live Wire |
| D-44 | Plus de rayon avec LiveWire Extended (2026-11-09, choix de l'utilisateur : « fini pour tout onduleur ») | **Remplace la dernière phrase de D-33** (la couverture s'ajoutait au rayon de D-12 ; décision gardée ci-dessus, elle laissait le rayon alimenter gratuitement le jardin et les maisons voisines, ce qui ôtait son intérêt au câblage). **Dès que LiveWire Extended est activé, aucun onduleur n'a de rayon** : le courant n'arrive que dans un bâtiment relié (par « Raccorder le bâtiment », ou par le tableau électrique relié, qui raccorde son bâtiment) et dans les zones des bornes extérieures. Live Wire seul garde son rayon (D-12) : la base reçoit seulement un indicateur facultatif « le fournisseur de couverture remplace le disque », sans aucune référence au sous-mod |
| D-45 | Point d'extension « couplage » (2026-11-09, choix de l'utilisateur après la question d'un auteur d'add-on) | **Pas de zones couplées dans Live Wire**, mais une API pour qu'un add-on les ajoute sans remplacer de fichier : `LiveWire.Coupling.register{ slaveKeepsZone, range, inverters, menu }`, un seul inscrit, avant `OnInitGlobalModData`. Sans inscrit, rien ne change (un onduleur couplé perd sa zone, couplage à `LinkRange`). Avec `slaveKeepsZone`, la base traite chaque onduleur du réseau qui a une zone : facture (`Demand.measureGrid`), circuits, allumage avec le maître, extinction des lumières de l'ordinateur, partage des appareils entre zones du même réseau ; un inscrit permet aussi d'ouvrir l'écran du maître depuis un onduleur couplé. Sous LiveWire Extended (D-44), les onduleurs n'ont pas de disque : garder la zone d'un couplé n'y apporte rien |
| D-40 | Tableaux dans les maisons (2026-11-08, Q02 tranchée par l'utilisateur : « Extended le fait lui-même ») | Extended pose lui-même, avec sa propre réalisation, un tableau dans une partie des bâtiments de la carte : le coffret vanilla `industry_02_212` à `215` quand il existe, sinon le sien. Circuits précâblés et **non étiquetés**, à découvrir par le joueur. **Extended est déclaré incompatible avec Knox Power** (`KnoxPower`, 3814302595), qui fait la même chose avec un autre système de disjoncteurs ; aucun code ni asset repris de ce mod |

**Arbitrage Q02 tranché le 2026-11-08 (D-40)** : tableaux déjà présents dans les maisons. Le mod Knox Power (`KnoxPower`, 3814302595,
variante `42`, v1.3.5) en pose un dans une partie des bâtiments au premier chargement, en réutilisant le coffret vanilla
`industry_02_212` à `215` quand il existe (`KP_PrePlace.lua:1-39`). La feuille `industry_02` existe bien dans
`newtiledefinitions.tiles` ; que ces quatre tuiles soient des coffrets électriques reste à vérifier. Knox Power a aussi
ses propres tableaux, disjoncteurs et zones : il recoupe largement Extended.

## Compatibilité Let Me Drive! — 2026-10-28

Signalement d'un joueur : avec Let Me Drive! (`LetMeDrive`, 3805307651), la
nourriture des frigos est comptée avariée en rentrant vite à la base. Cause confirmée statiquement : ce mod remplace
la table `Events.LoadChunk` et rejoue les abonnés des mods chargés après lui sur
les images suivantes, alors que le moteur purge les positions de générateur de
l'ancre avant de déclencher `LoadChunk`, et que `Food.updateAge` applique toute
l'absence avec l'état électrique de l'instant (NM-57 à NM-59).

Choix utilisateur : corriger **uniquement** les deux abonnés dont le retard est
destructeur (`LW_Anchor`, `LW_ChunkSync`), en les inscrivant hors de la file de
ce mod et seulement s'il est installé. Les autres abonnés `LoadChunk` de Live Wire
restent lissés par lui. **Pas de sonde périodique ni d'abonné `OnTick`** : le
renfort qui réarmait les passes d'ancre depuis `OnTick` est explicitement écarté
pour son coût. Aucune migration de pattern, de registre ni de sauvegarde.

## Correction de la dette technique — 2026-11-09

Audit du 2026-11-09 (`annexes/audit/2026-11-09-dette-technique.md`), plan validé par l'utilisateur le même jour
(« implémente tous les lots »), suivi dans `annexes/plans/dette-technique.md`. Aucun format de sauvegarde ni réglage
sandbox ne change ; aucune migration de pattern (serveur autoritaire, modules `LiveWire.*`).

| ID | Sujet | Décision |
|---|---|---|
| D-46 | Campagne de correction (2026-11-09, choix de l'utilisateur) | Neuf lots, de la sûreté au découpage, sans changement de jeu sauf : « RESET » traduit, voyants des sources ajoutées par l'API, moins d'abonnés `OnTick`. Les `pcall` locaux, journalisés et commentés (une pompe, un appareil de chunk, une commande) restent une exception admise ; aucun `pcall` englobant de plus |
| D-47 | API des sous-mods (2026-11-09, choix de l'utilisateur : « élargir l'API ») | LiveWire Extended n'appelle de la base que `LiveWire.API`, les points d'extension (`Coverage`, `CircuitProvider`, `Coupling`), la lecture de `LiveWire.Config`, `LiveWire.UIScale`, `LiveWire.notify`/`notifyNear`, `LiveWire.Anchor.reshape` et la classe de base `LWBaseAction` des actions (D-49). Tout autre besoin devient une fonction de `LiveWire.API`, qui délègue aux modules internes et ne rend que des copies détachées. La base ne connaît toujours pas Extended |
| D-48 | Membres d'un réseau et onduleurs (2026-11-09) | `Registry.members(grid)` rend une table indexée par rôle ; un module serveur `LW_Inverters` porte les règles de parc (`inService`, `capacityW`, `idleW`, esclave en service) ; aucun module ne lit le cache d'un autre (`Demand.eachObject`) ; les champs persistés du registre ont des accesseurs du registre |
| D-49 | Actions chronométrées (2026-11-09) | Toute action de Live Wire et d'Extended dérive de `LWBaseAction` (orientation, portée, durée, garde d'autorité complète dont `readOnly`). Les noms globaux des classes restent (NetTimedAction) |
| D-50 | Appareils décrits par des données (2026-11-09) | Voyants (`def.overlays`), production et météo (`Sim.sourceKinds`), menu (`Menu.providers`) et familles d'appareils vanilla (`Appliances.FAMILIES`) se déclarent dans des tables ; aucune nouvelle branche `if model == …` |
| D-51 | Abonnés à chaque image (2026-11-09) | Les vues (portée, pompe, réseau) ne s'abonnent à `OnTick` que tant qu'elles sont ouvertes ; l'affichage de l'ancre ne tourne que côté joueur et le vieillissement des frigos que côté serveur ; les pompes se trouvent par un index de rôle. La découverte des appareils reste inchangée tant qu'aucune mesure ne justifie un passage à `EveryOneMinute` |
| D-52 | Événements internes (2026-11-09) | Un bus local `LiveWire.Events` (`on`, `emit`) remplace les appels du registre et des wrappers de placement vers les autres modules (`topologyChanged`, `squareChanged`, …) ; un module absent ne s'abonne simplement pas |
| D-53 | Voyants des sources ajoutées par l'API (2026-11-09, demande de l'utilisateur) | `API.registerSource` accepte un champ facultatif `overlays` (mêmes clés que `Defs.devices`, valeurs dans la feuille de la source, jamais sur ses 4 tuiles, recopiées) ; `LW_Visuals` dessine les voyants depuis la feuille de l'appareil et ne pose que les sprites dont la texture existe. Aucun changement pour les appareils de la base |

## Harmonisation des disjoncteurs — 2026-11-09

Plan `annexes/plans/harmonisation-disjoncteurs.md`, maquette validée `annexes/maquettes/disjoncteurs-harmonises.html`
(proposition A). Numérotation : D-53 est déjà prise (voyants des sources de l'API) ; les deux décisions de ce plan
prennent D-54 (rendu) et D-55 (agrandissement).

| ID | Sujet | Décision |
|---|---|---|
| D-54 | Rendu commun « coffret dessiné » (2026-11-09, choix de l'utilisateur) | La fenêtre du tableau d'Extended (8, 16, 24 modules) prend le rendu et la géométrie de la fenêtre du disjoncteur de Live Wire : en-tête « LIVE WIRE », coffret crème, capot fumé, plaque fabricant, renfoncement, rail galvanisé, afficheur LCD à gauche, modules à droite, texte d'aide et boutons dans le coffret. Les disjoncteurs sont dessinés (plus de textures `LWX_UI_module_*` dans la fenêtre), avec une bande et une plaque de calibre colorées (15 A bleu, 20 A jaune, 30 A vert). Les deux fenêtres utilisent un seul code de dessin, dans Live Wire ; Extended l'obtient par `LiveWire.API` (voir la mise à jour de D-47 ci-dessous). Les textes trop longs sont abrégés avec « … » (texte complet en infobulle), jamais découpés |
| D-55 | Agrandissement sur place (2026-11-09, choix de l'utilisateur) | Un tableau posé s'agrandit de 8 à 16, puis de 16 à 24 modules, sans être démonté : action « Agrandir le tableau », Électricité 3, tournevis gardé, 1 `Base.SmallSheetMetal` et 4 `Base.Screws` consommés. L'autorité remplace la tuile par celle de la taille suivante, même orientation, et met à jour `record.size`. Les modules existants gardent disjoncteurs, étiquettes, compteurs et raccordement à l'onduleur ; les nouveaux modules sont vides. Pas d'agrandissement au-delà de 24 |

Mise à jour de D-47 (2026-11-09, pour D-54) : le kit de dessin des fenêtres (`LiveWire.Enclosure`, fichier
`client/LiveWire/LW_Enclosure.lua`) est exposé à Extended par `LiveWire.API.enclosure()`, qui rend la table du
module (et non une copie) : c'est la seule exception à la règle « copies détachées », justifiée par le fait qu'il
s'agit de code d'interface sans état de jeu. Extended ne l'appelle qu'à l'ouverture de sa fenêtre.

Mise à jour de D-54 (2026-11-09, réponse de l'utilisateur à la question Q0 de la session d'harmonisation, option 1) :
la maquette `propA` est la référence des deux fenêtres. Le disjoncteur de Live Wire devient un peu plus haut (477 px à
taille de police normale au lieu de 454), sa bande d'état entre dans le renfoncement, ses leviers gardent leur forme ;
le tableau d'Extended a le même aspect. Largeur de Live Wire inchangée (750 px).

Mise à jour de D-55 (2026-11-09, réponse de l'utilisateur à la question Q1) : « Non, seulement les tableaux posés par
le joueur. » Les coffrets muraux vanilla `industry_02_212` à `215` restent à 8 modules et ne peuvent pas être agrandis.

Mise à jour de D-52 (2026-11-09, commit `0d7bb72` d'une autre session de dette technique) : le bus local publie trois
événements de plus, déclarés dans `shared/LiveWire/LW_EventBus.lua` : `DEVICE_PICKED_UP`, `ROTATION_STARTED` et
`ROTATION_ENDED`. Ils remplacent les appels directs `Devices.onPickedUp`, `beginRotation` et `endRotation`. Deux appels
restent directs parce que leur valeur de retour est utilisée : `Devices.beforePickUp` et `Registry.forgetVanilla`
(dans `LW_Commands`).

## Écrans LCD communs — 2026-11-09

Plan `annexes/plans/lcd-commun.md`. Tous les écrans LCD d'appareil dessinés par Live Wire et LiveWire Extended
(batterie, appareil, pompe, onduleur, tableau électrique de Live Wire et d'Extended) passent par un seul module.

| ID | Sujet | Décision |
|---|---|---|
| D-56 | Module LCD commun et teinte unique (2026-11-09, teinte choisie par l'utilisateur) | Un seul module client `LiveWire/LW_Lcd.lua` (`LiveWire.Lcd`) porte la palette, le dessin du cadre et de l'écran, les lignes de texte, la jauge, le texte d'attente et l'indicateur de page. **Une seule teinte** : tous les écrans prennent le vert clair rétroéclairé des appareils (fond 0.62, 0.74, 0.40 ; encre 0.08, 0.13, 0.05), y compris l'afficheur et la bande d'état du tableau électrique (réponse de l'utilisateur : « Tout en vert clair »). Variantes de la palette : `green` (appareils et tableau), `pump` (bleu de la pompe), `off` (onduleur éteint). Un seul cadre (couleur 0.06, 0.07, 0.06 et reflet en haut de l'écran), une seule police (`LiveWire.Client.lcdFont()`) pour le texte affiché sur un écran. Les lignes trop longues des écrans d'appareil défilent (logique de l'onduleur, pause 1,2 s, 40 px/s de référence) ; les lignes du tableau électrique restent abrégées avec « … » (D-54). Seule la présentation change : ni données, ni réseau, ni serveur |

Confirmé par défaut (brief du 2026-11-09, non soumis au choix de l'utilisateur) : défilement généralisé aux écrans
d'appareil, jauge unique, cadre unique, police `lcdFont()` sur tous les écrans. Le texte imprimé sur la façade crème du
tableau (titre, ligne du voyant, ligne d'état) n'est pas un écran : il garde `UIFont.Small`. L'écran de démarrage de
l'ordinateur (`LW_SoftwareScreen.lua`) reste hors périmètre. Extended n'appelle pas `LW_Lcd` directement : il dessine
son afficheur par le kit de coffret (`LiveWire.API.enclosure()`, D-47), qui délègue à `LW_Lcd`.

Mise à jour de D-56 (2026-11-09, essai en jeu L6) : la police d'écran `UIFont.Code` n'a pas le caractère « … »
(U+2026), dessiné « ? » sur la bande d'état du tableau. Le texte abrégé **sur un écran** finit donc par trois points
ASCII « ... » (`LiveWire.Lcd.ELLIPSIS`) ; le texte imprimé sur la façade garde « … » (D-54).

Mise à jour de D-45 et D-47 (2026-11-10, D-57, choix de l'utilisateur après la relecture de l'auteur d'un add-on de couplage) : (1) l'écran de l'onduleur reste ouvert près de n'importe quel onduleur du réseau (le serveur l'acceptait déjà) ; le cliché porte `network` (positions du maître et des couplés). (2) `Coupling.inverterById` retrouve le maître par la case de son ancre, à toute distance, quand le rayon de couplage a baissé. (3) Au chargement, sans add-on qui garde les zones des couplés, les ancres restées aux onduleurs couplés sont retirées : retirer l'add-on ne laisse plus de zones que rien n'allume ni n'éteint. Réactiver l'add-on ensuite ne les rend qu'au prochain passage de la simulation (elle rallume les zones des couplés en service). (4) API révision 3 : `networkInverters`, `anchors`, `showRange`, `hideRange`, `rangeShown`, `rangeColor`, `onRangeView`, pour que l'add-on ne lise plus `LiveWire.Anchor`, `LiveWire.RangeView` ni `LiveWire.Menu`.

Mise à jour de D-45 (2026-11-10, retour d'un testeur de l'add-on de couplage) : sous LiveWire Extended, un onduleur couplé dont l'add-on garde la zone garde aussi ses bâtiments, ses bornes et ses tableaux (`X.Inverters.ownsZone`). Le nettoyage horaire ne les oublie plus, et l'on peut brancher ou débrancher un bâtiment, relier une borne ou un tableau depuis cet onduleur. Sans add-on, rien ne change : coupler retire la zone et Extended oublie ses zones ; le menu grise « Brancher le bâtiment » sur un onduleur couplé et l'action explique son refus au lieu d'échouer en silence.

| ID | Sujet | Décision |
|---|---|---|
| D-58 | Roue à aubes animée (2026-11-10, demande de l'utilisateur : « fais le nécessaire, surtout non négociable : ne casse rien ») | La roue tourne comme les pales de l'éolienne : tuile 8-11 sans roue, quatre images de roue en calques 104-119 (ajoutés à la fin de la feuille, aucun index déplacé), animées par le client tant que la roue n'est pas cassée, vitesse selon la saison (`Physics.hydroFactor`). Les tuiles 8-11 portent `CustomItem` pour que la roue ramassée garde son icône. Détails : `specifications-techniques.md`, « Roue à aubes animée ». |
| D-59 | Tournevis partout (2026-11-10, demande de l'utilisateur : « sauf pour le raccordement d'une pompe à eau à un baril, il faut toujours un tournevis pour LiveWire et LiveWire_extended dans les recettes de craft et de pose ») | **Toutes les recettes** de LiveWire et d'Extended demandent un tournevis conservé (ajouté à la cellule de récupération, aux pales, au mât, à la batterie à décharge profonde, au kit d'insonorisation et à son démontage). **Poser** un équipement, un tableau ou une borne demande un tournevis : tuiles `PlaceTool = Electrician`, toujours sans niveau (D-29 reste vrai pour le niveau). **Raccorder** demande un tournevis : équipement ou appareil vanilla à l'onduleur, couplage de deux onduleurs, tableau ou borne d'Extended à l'onduleur, bâtiment à l'onduleur ou à la borne (s'ajoute aux points et disjoncteurs, qui l'exigeaient déjà). Seule exception : relier un baril à la pompe à eau. Remplace « poser : aucun outil » de D-29. |
| D-60 | Teinte des appareils depuis le tableau (2026-11-11, demande de l'utilisateur après l'oubli de raccorder un interrupteur) | Tant que la fenêtre d'un tableau est ouverte, les appareils de la région qu'il dessert (son bâtiment, ou la zone de borne qui le contient) sont teintés : rouge = raccordé à aucun tableau (sans courant, D-37), vert = ce tableau, bleu = disjoncteur de ce tableau ouvert, gris = autre tableau (un bâtiment peut avoir plusieurs tableaux ; un appareil n'appartient qu'à un seul). Les appareils de ce tableau situés hors de sa région sont teintés aussi. Une seule recherche à l'ouverture, refaite seulement quand les données publiques d'Extended changent (révision `X.Data.rev`), aucune minuterie ; teinte retirée pendant « Localiser » et à la fermeture. Un tableau qui ne dessert aucun bâtiment ni zone l'indique dans sa fenêtre. Complément du même jour : un disjoncteur sans appareil a son étiquette en orange, « Aucun appareil raccordé » sur l'écran, et le basculer l'annonce. |
| D-61 | Tableau facultatif, bâtiment d'un tableau (2026-11-11, demande de l'utilisateur) | Confirme D-37/D-44 : sans tableau, l'onduleur raccordé au bâtiment alimente tout et une surcharge fait sauter le réseau ; avec un tableau relié à l'onduleur, tout le courant du bâtiment passe par lui, chaque appareil doit être raccordé à un disjoncteur, un tableau sans disjoncteur coupe tout le bâtiment. **Un tableau appartient au bâtiment dont il touche le mur, côté intérieur ou extérieur** (pose dehors autorisée) : une seule règle `X.Panel.buildingOf` pour l'alimentation et les disjoncteurs ; à défaut, la zone de borne qui le contient ; sinon aucun bâtiment, et la fenêtre comme le menu le disent. Les vues (teinte, menu « Raccorder un appareil ») lisent la région par une seule requête `X.Points.regionPoints`. Schéma : `docs/images/diagrams/diagram_extended_<en|fr>.png`. **Mise à jour du 2026-11-11 : la pose sur la face extérieure, la recherche à une case et le repli sur la zone d'une borne sont remplacés par D-62 (mur intérieur seulement, règle `X.Sites`).** |
| D-62 | Tableau sur un mur intérieur seulement (2026-11-11, demande de l'utilisateur ; remplace la pose extérieure de D-61) | Un tableau fabriqué d'Extended (tuiles 8-13), qui n'est pas étanche, **ne se pose que sur la face intérieure d'un mur** : la case de l'objet mural (celle qu'il regarde : orientation S sur le mur nord de sa case, E sur le mur ouest) doit être l'intérieur d'un bâtiment, sinon le curseur refuse avec la raison en rouge. Règle unique `X.Sites.at(x, y, z)` (« lieu » d'une case), utilisée par la pose, la liaison, les disjoncteurs, la teinte et le menu : (1) une **pièce de la carte** (`IsoMetaGrid:getRoomAt`, qui ignore les cases « emptyoutside ») non `RoomDef:isUserDefined()` → son `BuildingDef` (maisons de la carte, pièces créées par `BuildingRoomsEditor`, donc Basement Building) ; un bâtiment tout entier sous le sol (cave vanilla, que le jeu ne fusionne jamais à la maison : `Basements.getBuildingToMergeWith`, `Basements.java:502-519`, mesuré en jeu le 2026-11-11 ; ou cave de Basement Building) compte avec la maison de la carte qui le recouvre (`X.Buildings.houseOf` / `group` : même clé, mêmes cases, même précâblage ; choix de l'utilisateur, 2026-11-11) ; les pièces `derelict` (sans réseau public) restent des intérieurs que LiveWire alimente ; (2) sinon, au sol ou au-dessus, une **enceinte de joueur** : région du jeu close et couverte (`IsoRegions.getIsoWorldRegion(x, y, z):isPlayerRoom()`), présente en solo, sur le client et sur le serveur dédié, alors que le bâtiment `userDefined` qu'en tire le jeu n'existe pas sur un serveur dédié (`IsoRegions.java:217`) ; le jeu tient une région par étage, l'enceinte réunit les régions closes et couvertes empilées (maison de joueur, tous ses étages ; précision de l'utilisateur, 2026-11-11 : « un tableau par étage » est exclu). Un tableau dessert le lieu de sa propre case, sinon rien (plus de recherche à une case ni de repli sur une zone de borne). **Un coffret vanilla (`industry_02_212..215`) est étanche** (précision de l'utilisateur, 2026-11-11) : il n'est pas déplaçable (curseur vanilla : `isMoveable` faux pour `industry_02_212`, mesuré en jeu le 2026-11-11 ; 213 à 215 supposés identiques), seule la carte le pose ; accroché dehors il dessert le lieu de la case de l'autre côté de son mur (`X.Panel.acrossWall`, noté `record.wall` à la liaison) ; un coffret de façade reste le tableau de sa maison. Les tableaux de maison ne se posent pas dans les bâtiments `userDefined`. La règle de pose passe par le point d'extension `LiveWire.API.addPlacementRule` (D-47). **Client MP** (choix de l'utilisateur, 2026-11-11) : le client n'apprend qu'à la reconnexion qu'une maison de joueur toute neuve est close et couverte (mesuré) ; sous un toit, hors pièce de la carte, son curseur accepte et l'autorité juge à la fin de l'action, en disant au joueur pourquoi elle refuse. Plan : `annexes/plans/tableau-mur-interieur.md`. **Ajout (2026-11-11, bug signalé par l'utilisateur)** : `industry_02_180` à `183`, le même coffret dessiné plus bas sur son mur, sont reconnus comme les coffrets 212 à 215 (8 modules, étanches, non déplaçables). |
| D-63 | Consommateurs sur le réseau public (2026-11-11, option A choisie par l'utilisateur) | « Afficher les consommateurs » montre en **blanc** les appareils encore alimentés par le réseau public, avec « Réseau public encore actif » en texte flottant au-dessus du personnage à l'ouverture et en jaune dans la légende, devenue une fenêtre vanilla `ISCollapsableWindow` en haut au centre (pastilles de couleur, croix qui ferme la vue ; choix de l'utilisateur, 2026-11-11) ; la liste du logiciel les marque « réseau public ». Ils restent hors facture de l'onduleur (même filtre que le moteur). Avant : vue vide, cru être un bug |
