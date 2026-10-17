# Live Wire — décisions ouvertes

Ces choix reviennent à l'utilisateur. Chaque décision propose trois options fermées et une recommandation, avec ses conséquences.

**En attendant ta réponse**, la recommandation sert de choix par défaut dans `fonctionnel.md` et `architecture.md`. Elle est marquée **« à valider »**.

Pour changer une décision, il suffit d'indiquer son numéro et l'option retenue (par exemple « D-3 : option 1 »). Les documents seront alors mis à jour.

---

## D-1. Contenu de la version 0.1

| Option | Contenu | Conséquences |
|---|---|---|
| 1 | **Socle de production** : testeur, onduleur, batteries, solaire et éolien, compétence, usure, tableau de bord | Le cœur du mod est jouable tôt ; l'hydraulique et la charge depuis un générateur vanilla attendent la 0.2 |
| 2 | Utilitaire de survie : testeur, chargeur de piles, désarmement d'alarmes, réparation d'appareils (idées 1 à 5) | Livraison rapide et peu risquée, mais l'idée centrale (production d'électricité) est repoussée |
| 3 | Tout le système d'énergie d'un coup : solaire, éolien, hydraulique, charge depuis un générateur, pompe | Plus complet, mais première version longue ; plus de risques empilés avant le premier test en jeu |

**Recommandation : option 1 — à valider.** Elle met en premier ce qui fait l'originalité du mod. Elle dérisque d'abord le mécanisme le plus incertain (l'onduleur, R-1) sur un périmètre testable. Le plan de versions complet est dans `fonctionnel.md`, § 9.

## D-2. Mécanisme qui amène le courant

| Option | Mécanisme | Conséquences |
|---|---|---|
| 1 | **Onduleur = vrai générateur du moteur, piloté par le mod** | Le jeu mesure lui-même la consommation, gère la portée, le multijoueur et la sauvegarde. Il faut bloquer les actions vanilla et vivre avec le son de générateur côté joueurs (D-8). Le prototype P1 doit le confirmer |
| 2 | Positions de générateur virtuelles posées par script | Aucun objet à protéger, aucun son. Il faut reposer les positions à chaque chargement, mesurer soi-même la consommation, et une position orpheline peut laisser du courant pour toujours (`knowledge/power-and-lights.md`, « Positions de générateur posées par script ») |
| 3 | Générateur vanilla du joueur, nourri en carburant par les batteries | Le plus simple, mais bruyant et toxique en intérieur ; le joueur peut tout casser avec les menus vanilla |

**Recommandation : option 1 — à valider.** C'est la seule qui laisse le moteur juge de l'alimentation **et** de la consommation. Les preuves sont dans `architecture.md`, § 1. Si le prototype P1 échoue, le repli prévu est l'option 2.

## D-3. Raccorder les appareils à l'onduleur

| Option | Règle | Conséquences |
|---|---|---|
| 1 | Automatique : tout appareil à moins de N cases est raccordé | Aucun geste, aucune ressource ; installation peu lisible avec plusieurs onduleurs ; pas d'expérience gagnée |
| 2 | **Raccordement explicite par menu, avec consommation de fil électrique** (1 fil pour 4 cases, portée 12) | Un geste lisible, qui coûte une ressource vanilla et rapporte de l'expérience. Pas de câble visible en v0.1 |
| 3 | Câbles posés case par case, comme des objets du monde | Le plus immersif, mais beaucoup d'objets, de sprites et de risques de chemin ; attend les tuiles définitives |

**Recommandation : option 2 — à valider.** Les options sandbox `LinkRange` et `WirePerTiles` permettent de la rendre très tolérante, et `WirePerTiles = 0` rend le fil gratuit.

## D-4. Où ranger les batteries

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Dans un compartiment intégré à l'onduleur (4 batteries), plus des bancs câblés facultatifs** | Le plus naturel : on range ses batteries de voiture dans l'onduleur. Le moteur ne crée pas ce conteneur pour un générateur : le mod doit le créer lui-même. Son comportement en MP est une hypothèse à vérifier (NM-17, prototype P1) |
| 2 | Seulement dans des meubles conteneurs vanilla câblés (caisses, étagères) | Repose sur des conteneurs ordinaires, mieux connus ; un objet de plus à poser et à câbler |
| 3 | Batteries « installées » et retirées de l'inventaire, stock purement abstrait | Aucun problème de synchronisation des objets, mais on ne voit plus ses batteries, et on ne peut plus les échanger ni les reprendre telles quelles |

**Recommandation : option 1 — à valider.** Elle répond à l'usage le plus courant : mettre des batteries de voiture dans l'onduleur. Si le compartiment échoue au prototype P1, le repli est l'option 2, sans rien changer au reste du modèle : les batteries restent de vrais objets dont la charge est portée par leurs utilisations.

## D-5. Échelle d'énergie

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **1 unité de consommation moteur par heure = 1 000 W** : réfrigérateur-congélateur 130 W, lumière 2 W | Ordres de grandeur crédibles ; une batterie de voiture de 0,6 kWh tient environ 3,5 h pour une petite base |
| 2 | 1 unité = 10 000 W : réfrigérateur-congélateur 1,3 kW | Énergie très chère ; il faut beaucoup de panneaux ; risque de frustration |
| 3 | Unités abstraites (« points de charge »), sans watts | Simple à équilibrer, mais moins lisible ; le testeur perd son intérêt pédagogique |

**Recommandation : option 1 — à valider.** L'option sandbox `PowerScale` permet de durcir ou d'adoucir l'échelle sans toucher au code.

## D-6. Apprentissage des recettes

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Connues automatiquement au niveau requis** | Simple ; la compétence est la seule clé ; pas de nouvel objet de butin |
| 2 | Magazines de mod à trouver dans le butin | Donne une raison d'explorer ; demande des répartitions de butin et des textes en plus |
| 3 | Mixte : recettes de base automatiques, recettes avancées (onduleur renforcé, cellules à partir de déchets) par magazine | Bon compromis, mais plus de contenu à produire avant la 0.1 |

**Recommandation : option 1 pour la v0.1 — à valider.** L'option 3 pourra venir en 0.2 sans casser les sauvegardes, car les recettes gardent leur nom.

## D-7. Propriété des installations en multijoueur

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Installation commune, règles de safehouse vanilla** | Simple et adaptée à un serveur entre amis ; un joueur hors safehouse peut démonter une installation non protégée |
| 2 | Propriétaire unique (seul l'installateur agit) | Protège contre le vol, mais gêne le jeu en groupe ; demande une gestion des droits |
| 3 | Propriétaire et liste d'invités | Le plus souple, mais interface et protocole plus lourds |

**Recommandation : option 1 — à valider.** C'est la cible déclarée de `CLAUDE.md` (serveur dédié entre amis).

## D-8. Son de l'onduleur en attendant une tuile propre

Les zombies n'entendent presque rien (rayon 1). Les **joueurs** entendent la boucle de son d'un générateur vanilla, et aucun réglage Lua ne permet de la couper (NM-2).

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Accepter le ronflement en v0.1** et l'expliquer dans la description du mod | Rien à produire ; immersion imparfaite jusqu'à la tuile définitive |
| 2 | Créer dès la v0.1 une tuile minimale (cube) avec sa propre valeur `GeneratorSound` et des sons de mod discrets | Silence réel, mais il faut l'outillage des tuiles (`.pack`, `.tiles`) et des fichiers son. C'est la partie la plus risquée du chantier graphique |
| 3 | Utiliser le sprite d'un générateur vanilla | À exclure : un générateur vanilla tourné pourrait prendre les réglages de l'onduleur, ou l'inverse (NM-1) |

**Recommandation : option 1 — à valider.** L'option 2 est la première tâche du chantier « tuiles et modèles ».

## D-9. Ce qui continue quand personne n'est à proximité

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Tout continue** : production, consommation à la dernière demande mesurée, usure | Cohérent avec le carburant vanilla qui rattrape les heures ; on peut revenir à une base déchargée |
| 2 | Production seulement, sans consommation ni usure | Généreux : les batteries sont toujours pleines au retour |
| 3 | Tout s'arrête | Simple, mais incohérent avec le reste du jeu ; une base lointaine ne se recharge jamais |

**Recommandation : option 1 — à valider**, réglable par l'option sandbox `SimulateUnloaded`.

## D-10. Onduleur et générateur vanilla qui alimentent les mêmes appareils

Le moteur fait payer les appareils communs aux deux sources (NM-5).

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **v0.1 : laisser faire et avertir** (testeur, tableau de bord). v0.2 : bascule automatique, l'onduleur passe en veille quand un générateur vanilla tourne à portée | Rien de bloquant ; la bascule demande un balayage limité à une fois par heure |
| 2 | Refuser la pose d'un onduleur à portée d'un générateur vanilla | Simple, mais interdit l'usage « générateur le jour, batteries la nuit » |
| 3 | Bascule automatique dès la v0.1 | Meilleure expérience, mais plus de travail et de coût avant d'avoir validé l'onduleur |

**Recommandation : option 1 — à valider.**
