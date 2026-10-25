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
| D-16 | Aspect et pose des équipements (2026-10-17, demande de l'utilisateur) | **Tuiles du mod** `batman_livewire_01` (tiledef 7174), formes géométriques provisoires rendues avec Blender. Le kit est un meuble posable `Base.Mov_LiveWire_*` ; la pose, la rotation et le ramassage sont ceux du curseur de meubles vanilla (tournevis et niveau d'Électricité exigés par la tuile). Plus d'action « Installer » ni « Démonter » du mod |
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
