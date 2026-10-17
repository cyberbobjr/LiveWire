# Live Wire v0.1 — protocole de test en jeu

**Fait automatiquement en solo (0.1.1)** : `autotest/lw_hooks.lua` pose les équipements par le code vanilla des meubles, vérifie la powerbank (conteneur vide, batteries acceptées), le refus d'un panneau à l'intérieur et d'une roue loin d'une rivière, le raccordement par l'action réelle, la rotation qui garde les liens, le ramassage qui garde l'état, et le contenu des menus clic droit. **Le reste de ce protocole n'a pas été fait en jeu**, en particulier le courant dans la maison, les sons et le multijoueur. Ce protocole sert à confirmer, ou à infirmer, chaque point du moteur dont le mod dépend. Il se déroule dans l'ordre : un échec à l'étape 1 change la suite (repli prévu : `architecture.md`, § 1.3, option C).

## Préparation

- **Solo** : nouvelle partie en mode « bac à sable », jeu lancé avec `-debug` pour pouvoir donner des objets et monter la compétence.
- **MP dédié** : serveur Linux local avec le mod activé, deux clients. Le second client n'a **pas** les droits d'admin.
- **Objets à donner** (menu de débogage « Items ») :
  - `Base.Mov_LiveWire_Inverter`, `Base.Mov_LiveWire_SolarPanel` ×4, `Base.Mov_LiveWire_WindTurbine`, `Base.Mov_LiveWire_WaterWheel`, `Base.Mov_LiveWire_Breaker`, `LiveWire.VoltageTester` ;
  - `Base.Mov_LiveWire_PowerBank`, `Base.CarBattery2` ×5 ;
  - ou « Live Wire » → « Debug » → « Donner un kit de test complet » ;
  - `Base.ElectricWire` ×20, `Base.ElectronicsScrap` ×10 ;
  - un tournevis.
- **Compétence** : monter Électricité à 8 (menu de débogage du personnage).
- **Après chaque essai**, relever les lignes `[LiveWire]` et les erreurs Lua de `console.txt` (client) et du journal du serveur.

## 1. L'ancre d'alimentation (risque R-1, bloquant)

1. Après la coupure du réseau (`ElecShutModifier` court, ou attendre), choisir une maison sans courant.
2. Dans l'inventaire, sur l'onduleur : « Placer » (bouton ou menu vanilla du meuble). Poser le fantôme dans la maison, le tourner (touche de rotation du curseur), valider.
   - **Attendu** : l'onduleur apparaît (armoire grise provisoire, sans conteneur ni butin). Message « Onduleur installé ».
3. Dehors, à ciel ouvert : poser 4 panneaux. Essayer d'en poser un dans la maison : le fantôme reste rouge et le panneau d'information dit « Doit être posé dehors, à ciel ouvert ».
   - Clic droit sur un panneau → « Live Wire » → « Panneau photovoltaïque » : « Non raccordé », puis « Raccorder à un onduleur » → « Onduleur à N cases (k fils) ».
   - Ou clic droit sur l'onduleur → « Raccorder un équipement » → la liste des panneaux.
4. En plein jour, attendre 10 à 20 minutes de jeu.
   - **Attendu** : les lumières de la maison s'allument à l'interrupteur, le réfrigérateur ronronne, aucun moodle de toxicité.
5. Ouvrir l'interface de gestion (onduleur → « Ouvrir le tableau de bord »).
   - **Attendu** :
     - production et consommation en W, avec leurs jauges ;
     - sources groupées par famille (Solaire avec les 4 panneaux, Éolien, Hydraulique) ;
     - section « Maison alimentée » avec la zone (20 cases, 3 étages) et les familles d'appareils en marche (réfrigérateur, lumières…) avec leur consommation.
   - Allumer ou éteindre une lumière, puis attendre 10 minutes de jeu : la ligne « Lumières » change.
   - Boutons « Éteindre » puis « Allumer » : la maison s'éteint puis se rallume.
6. **MP** : le 2e client voit les lumières allumées et entend le réfrigérateur.
7. S'éloigner de deux cellules (plus de 150 cases), attendre une heure de jeu, revenir.
   - **Attendu** : le courant est présent **dès l'arrivée**.
8. Copie de la sauvegarde **sans** le mod : recharger.
   - **Attendu** : plus aucun courant dans la maison (pas de fuite).

## 2. Sans batterie, puis avec batteries

1. Sans batterie, la nuit.
   - **Attendu** : la maison s'éteint (« à vide » sur le tableau de bord) et se rallume le matin. Pas de clignotement au passage d'un nuage.
2. Poser une powerbank près de l'onduleur, la raccorder, l'ouvrir comme une caisse et y glisser 2 batteries de voiture.
   - **Attendu** : la fenêtre s'appelle « Powerbank » et ne contient aucun butin ; les batteries apparaissent dans le tableau de bord ; leur charge monte le jour (infobulle de l'objet).
3. La nuit.
   - **Attendu** : la maison reste alimentée, la charge baisse.
4. Retirer une batterie de la powerbank.
   - **Attendu** : elle disparaît du tableau de bord au pas suivant ; sa charge reste dans l'objet.
5. Y mettre 5 batteries.
   - **Attendu** : 4 sont comptées, le tableau de bord signale la 5e.
6. Essayer de ramasser la powerbank pleine (ramassage vanilla).
   - **Attendu** : refusé par le jeu (conteneur non vide).
7. **MP** : le 2e client ouvre la même powerbank, voit les mêmes batteries et leur charge changer.

## 3. Sans joueur dans la zone (exigence de l'utilisateur)

1. Base avec 2 batteries chargées, réfrigérateur plein de nourriture fraîche.
2. Partir loin pendant 2 jours de jeu.
   - **Attendu au retour** : le courant est présent si l'énergie a suffi, la nourriture est restée fraîche, et le tableau de bord a évolué.
3. Recommencer en retirant les panneaux, pour que les batteries se vident pendant l'absence.
   - **Attendu** : au retour, la maison est sans courant **dès le chargement**.
4. **Serveur dédié sans aucun joueur connecté** (`PauseEmpty` désactivé), pendant une heure réelle.
   - **Attendu** : à la reconnexion, état cohérent (charge, courant).

## 4. Surcharge et disjoncteur mural

1. Allumer assez d'appareils pour dépasser 1 500 W. Par exemple, un lave-linge et sèche-linge superposés font 1 800 W à eux seuls.
   - **Attendu** : message « L'onduleur a disjoncté », plus de courant, état de l'onduleur −3.
2. Éteindre des appareils, puis « Réarmer ».
   - **Attendu** : le courant revient.
3. Poser le disjoncteur sur un mur (curseur vanilla des objets muraux), puis le raccorder. Recommencer la surcharge.
   - **Attendu** : l'onduleur disjoncte, mais son état ne baisse plus.
4. **À noter** : le coffret colle-t-il au mur nord et au mur ouest ?
5. Essayer de détruire à la masse le mur qui porte le disjoncteur.
   - **Attendu** : refusé.

## 5. Éolienne, testeur, compétence

1. Poser l'éolienne dehors, si possible en hauteur, puis la raccorder.
   Poser une roue à aubes sur la berge d'une rivière (pas d'un lac), la raccorder : environ 120 W jour et nuit.
   - **Attendu** : production nulle sans vent, positive par vent moyen (inspection : W fournis et bruts).
2. Testeur : « Mesurer » une case de la maison au niveau 0, puis 2, puis 4.
   - **Attendu** :
     - au niveau 0 : courant oui ou non ;
     - au niveau 2 : consommation de l'appareil de la case ;
     - au niveau 4 : bilan du réseau.
3. **MP, 2e client non-admin** : fabriquer, poser, raccorder et réparer. Le 2e client voit l'état de raccordement dans son menu.
   - **Attendu** : expérience d'Électricité gagnée, preuve que l'expérience est donnée par le serveur.
4. Gestes vanilla :
   - **ramasser** un panneau raccordé : il quitte le réseau, l'objet garde son état ; reposé, il est « Non raccordé » ;
   - **tourner** l'onduleur : ses équipements restent raccordés ;
   - **ramasser** l'onduleur : tous ses équipements deviennent « Non raccordé » ;
   - démonter (ferraille) et détruire à la masse : refusés (ligne `refused vanilla …` dans le journal en cas de tentative forcée).

## 6. Sons, modèles et recettes provisoires

1. Près de l'onduleur en marche : ronronnement discret (`FridgeHumA`) audible jusqu'à environ 12 cases, qui s'arrête quand l'onduleur s'arrête. En MP, aucun son fantôme chez l'autre joueur.
2. Poser chaque équipement dans ses quatre orientations.
   - **Attendu** : tuiles provisoires lisibles, sans découpe (profondeur), à l'échelle des meubles voisins.
   - **À noter** : taille, orientation, rendu derrière un mur.
3. Recette « Fabriquer une batterie stationnaire ».
   - **Attendu** : les deux batteries de voiture sont consommées, et la batterie obtenue est vide, avec un état égal à la moyenne des deux.

## 7. Générateur de secours, ordinateur, alarme, debug

Préparation rapide : lancer en `-debug`, puis « Live Wire » → « Debug » → « Donner un kit de test complet ».

1. Poser onduleur, powerbank (2 batteries), alarme ; raccorder. Poser un générateur vanilla **dehors**, le brancher (option vanilla), le remplir, puis « Générateur de secours » → « Raccorder à l'onduleur ».
2. Debug → « Batteries à 15 % ».
   - **Attendu** : message « Batterie faible », bip d'environ 3 s ; dans les 10 minutes de jeu, le générateur démarre ; le tableau de bord affiche « recharge les batteries ».
3. Debug → « Faire tourner la simulation 12 heures » (ou attendre).
   - **Attendu** : arrêt du générateur vers 90 %, carburant en baisse. Noter le carburant avant et après, et après être parti puis revenu (NM-32).
4. Vider le générateur, recommencer l'étape 2. **Attendu** : « plus de carburant », pas de démarrage.
5. Raccorder un ordinateur de bureau du jeu (niv. 6), alimenté par la zone de l'onduleur. Clic droit dessus → « Ouvrir le tableau de bord ».
   - **Attendu** : section « Ordinateur de gestion », graphiques qui se remplissent d'un point par heure, prévision jusqu'à l'aube.
6. Avec un raccordement fait au niv. 7, lumières allumées, Debug → « Batteries à 15 % ». **Attendu** : les lumières s'éteignent une fois, message de délestage.
7. MP : un joueur non admin ne voit pas le menu Debug ; un admin le voit et la console du serveur journalise chaque usage.

## Que rapporter

Pour chaque étape : réussi ou échoué, ce qui a été vu, et les lignes du journal. Les constats confirmés iront dans `docs/notes-moteur.md` avec le statut « confirmé en jeu ».
