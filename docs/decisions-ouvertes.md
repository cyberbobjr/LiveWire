# Live Wire — décisions

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

## Décisions validées

| N° | Sujet | Choix retenu |
|---|---|---|
| D-1 | Contenu de la v0.1 | Socle : testeur, onduleur, batteries facultatives, solaire, éolien, disjoncteur, compétence, usure, tableau de bord, fonctionnement sans joueur |
| D-2 | Mécanisme d'alimentation | **Ancre d'alimentation** posée par le mod, reposée à chaque chargement, sur le serveur et chez les clients (`architecture.md`, § 1.4). Repli si le prototype P1 échoue : vrai générateur caché dehors |
| D-3 | Raccordement | Explicite, par menu, en consommant du fil électrique (1 fil pour 4 cases, portée 12) |
| D-4 | Batteries | Rangées dans une **powerbank** qui s'ouvre comme une caisse (4 batteries comptées). Plus de batterie au sol. Choix de l'utilisateur, le 2026-10-17 : « rangement ouvrable », préféré à des emplacements gérés par menu et à une capacité fixe. Depuis 0.1.1, le conteneur vient de la tuile (`container = livewirepowerbank`, capacité 50) : le jeu le crée et le marque exploré à la pose, donc sans butin |
| D-5 | Échelle d'énergie | 1 unité de consommation moteur par heure = 1 000 W (option `PowerScale`) |
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
| D-18 | Roue à aubes (2026-10-17) | **Avancée en 0.1** : l'utilisateur veut raccorder panneau, éolienne et hydraulique. Règles reprises du § 3.4 de `fonctionnel.md` : 120 W jour et nuit, saison, berge d'une rivière au niveau 0, Électricité 7 |
| D-19 | Raccordement par menu (2026-10-17) | Clic droit sur un équipement : son état (« Raccordé à l'onduleur à N cases » ou « Non raccordé ») puis la liste des onduleurs à portée, avec distance et nombre de fils. Clic droit sur l'onduleur : « Raccorder un équipement » et « Débrancher un équipement », listes des équipements à portée. Les onduleurs sont cherchés sur les cases chargées autour, plus dans la table des ancres |
