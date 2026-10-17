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

## Décisions validées

| N° | Sujet | Choix retenu |
|---|---|---|
| D-1 | Contenu de la v0.1 | Socle : testeur, onduleur, batteries facultatives, solaire, éolien, disjoncteur, compétence, usure, tableau de bord, fonctionnement sans joueur |
| D-2 | Mécanisme d'alimentation | **Ancre d'alimentation** posée par le mod, reposée à chaque chargement, sur le serveur et chez les clients (`architecture.md`, § 1.4). Repli si le prototype P1 échoue : vrai générateur caché dehors |
| D-3 | Raccordement | Explicite, par menu, en consommant du fil électrique (1 fil pour 4 cases, portée 12) |
| D-4 | Batteries | Rangées dans une **powerbank** qui s'ouvre comme une caisse (4 batteries comptées). Plus de batterie au sol. Choix de l'utilisateur, le 2026-10-17 : « rangement ouvrable », préféré à des emplacements gérés par menu et à une capacité fixe |
| D-5 | Échelle d'énergie | 1 unité de consommation moteur par heure = 1 000 W (option `PowerScale`) |
| D-6 | Apprentissage des recettes | Automatique au niveau requis |
| D-7 | Propriété en multijoueur | Installations communes, règles de safehouse vanilla |
| D-8 | Bruit de l'onduleur | Zombies : rayon 2 (option `InverterNoiseRadius`). Joueurs : ronronnement de réfrigérateur vanilla **`FridgeHumA`**, choisi par l'utilisateur, joué localement |
| D-9 | Sans joueur dans la zone | Tout continue (option `SimulateUnloaded`, vraie par défaut) |
| D-10 | Recouvrement avec un générateur vanilla | v0.1 : les deux paient les appareils communs ; v0.2 : bascule automatique |
| D-11 | Équipements optionnels | Disjoncteur mural en 0.1 ; ordinateur de gestion et alarme de batterie faible en 0.2 |
| — | Dégâts d'orage | **`LiveWire.StormDamage` désactivée par défaut** |
| D-12 | Zone alimentée par l'onduleur | **Rayon autour de l'onduleur** (20 cases, ±3 étages, réglages vanilla des générateurs) : tous les appareils de la maison dans cette zone sont alimentés, sans raccordement. Préféré, le 2026-10-17, à « tout le bâtiment » et à « bâtiment et terrain » |
| D-3 (confirmé) | Raccordement des équipements du mod | **Manuel**, par « Raccorder à l'onduleur », avec du fil électrique. Reconfirmé le 2026-10-17, préféré au raccordement automatique |
| D-13 | Interface de gestion | Fenêtre de l'onduleur : production et consommation, batteries, sources par famille (solaire, éolien, hydraulique), maison alimentée par famille d'appareils, équipements, boutons Allumer, Éteindre et Réarmer |
