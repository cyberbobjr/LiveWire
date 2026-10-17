# Live Wire v0.1 — protocole de test en jeu

**Rien de ce qui suit n'a encore été fait en jeu.** Le code a seulement passé les vérifications hors jeu (`architecture.md`, § 10). Ce protocole sert à confirmer, ou à infirmer, chaque point du moteur dont le mod dépend. Il se déroule dans l'ordre : un échec à l'étape 1 change la suite (repli prévu : `architecture.md`, § 1.3, option C).

## Préparation

- **Solo** : nouvelle partie en mode « bac à sable », jeu lancé avec `-debug` pour pouvoir donner des objets et monter la compétence.
- **MP dédié** : serveur Linux local avec le mod activé, deux clients. Le second client n'a **pas** les droits d'admin.
- **Objets à donner** (menu de débogage « Items ») :
  - `LiveWire.InverterKit`, `LiveWire.SolarPanelKit` ×4, `LiveWire.WindTurbineKit`, `LiveWire.BreakerKit`, `LiveWire.VoltageTester` ;
  - `Base.CarBattery2` ×2 ;
  - `Base.ElectricWire` ×20, `Base.ElectronicsScrap` ×10 ;
  - un tournevis.
- **Compétence** : monter Électricité à 8 (menu de débogage du personnage).
- **Après chaque essai**, relever les lignes `[LiveWire]` et les erreurs Lua de `console.txt` (client) et du journal du serveur.

## 1. L'ancre d'alimentation (risque R-1, bloquant)

1. Après la coupure du réseau (`ElecShutModifier` court, ou attendre), choisir une maison sans courant.
2. Clic droit dans la maison, sur une case de sol libre : « Live Wire » → « Installer ici : Onduleur ».
   - **Attendu** : l'onduleur apparaît (aspect provisoire : armoire à outils). Message « Onduleur installé ».
3. Dehors, sur une case à ciel ouvert : installer 4 panneaux, puis « Raccorder à l'onduleur » sur chacun.
4. En plein jour, attendre 10 à 20 minutes de jeu.
   - **Attendu** : les lumières de la maison s'allument à l'interrupteur, le réfrigérateur ronronne, aucun moodle de toxicité.
5. Ouvrir le tableau de bord (onduleur → « Ouvrir le tableau de bord »).
   - **Attendu** : production en W, demande en W, sources listées.
6. **MP** : le 2e client voit les lumières allumées et entend le réfrigérateur.
7. S'éloigner de deux cellules (plus de 150 cases), attendre une heure de jeu, revenir.
   - **Attendu** : le courant est présent **dès l'arrivée**.
8. Copie de la sauvegarde **sans** le mod : recharger.
   - **Attendu** : plus aucun courant dans la maison (pas de fuite).

## 2. Sans batterie, puis avec batteries

1. Sans batterie, la nuit.
   - **Attendu** : la maison s'éteint (« à vide » sur le tableau de bord) et se rallume le matin. Pas de clignotement au passage d'un nuage.
2. Poser 2 batteries de voiture au sol près de l'onduleur (pose vanilla), puis « Raccorder … à l'onduleur ».
   - **Attendu** : elles apparaissent dans le tableau de bord ; leur charge monte le jour (infobulle de l'objet).
3. La nuit.
   - **Attendu** : la maison reste alimentée, la charge baisse.
4. Ramasser une batterie.
   - **Attendu** : elle disparaît du tableau de bord au pas suivant ; sa charge reste dans l'objet.
   - Variante : « Live Wire » → « Débrancher … » sur une batterie au sol, qui doit avoir le même effet.
5. **MP** : le 2e client voit la charge de la batterie au sol changer (infobulle).

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
3. Installer le disjoncteur contre un mur (clic droit au pied d'un mur), puis le raccorder. Recommencer la surcharge.
   - **Attendu** : l'onduleur disjoncte, mais son état ne baisse plus.
4. **À noter** : orientation du disjoncteur contre un mur nord, ouest, est et sud. Le sprite (applique murale provisoire) colle-t-il au mur ? Aucune lumière ne doit apparaître.
5. Essayer de détruire à la masse le mur qui porte le disjoncteur.
   - **Attendu** : refusé.

## 5. Éolienne, testeur, compétence

1. Installer l'éolienne dehors, si possible en hauteur, puis la raccorder.
   - **Attendu** : production nulle sans vent, positive par vent moyen (inspection : W fournis et bruts).
2. Testeur : « Mesurer » une case de la maison au niveau 0, puis 2, puis 4.
   - **Attendu** :
     - au niveau 0 : courant oui ou non ;
     - au niveau 2 : consommation de l'appareil de la case ;
     - au niveau 4 : bilan du réseau.
3. **MP, 2e client non-admin** : fabriquer, installer et réparer.
   - **Attendu** : expérience d'Électricité gagnée, preuve que l'expérience est donnée par le serveur.
4. Gestes vanilla sur un panneau, l'onduleur et le disjoncteur : ramasser comme meuble, démonter, détruire à la masse.
   - **Attendu** : refusés. Une ligne `refused vanilla …` apparaît dans le journal en cas de tentative forcée.

## 6. Sons, modèles et recettes provisoires

1. Près de l'onduleur en marche : ronronnement discret (`FridgeHumA`) audible jusqu'à environ 12 cases, qui s'arrête quand l'onduleur s'arrête. En MP, aucun son fantôme chez l'autre joueur.
2. Poser les kits au sol.
   - **Attendu** : formes géométriques provisoires de taille raisonnable (panneau plat bleu, onduleur gris, éolienne en cylindre).
   - **À noter** : taille, orientation, texture.
3. Recette « Fabriquer une batterie stationnaire ».
   - **Attendu** : les deux batteries de voiture sont consommées, et la batterie obtenue est vide, avec un état égal à la moyenne des deux.

## Que rapporter

Pour chaque étape : réussi ou échoué, ce qui a été vu, et les lignes du journal. Les constats confirmés iront dans `docs/notes-moteur.md` avec le statut « confirmé en jeu ».
