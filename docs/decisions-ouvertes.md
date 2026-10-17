# Live Wire — décisions ouvertes

Ces choix reviennent à l'utilisateur.
- **Pour chaque décision** : trois options fermées, une recommandation et ses conséquences.
- **Par défaut**, la recommandation est appliquée dans `fonctionnel.md` et `architecture.md`, marquée **« à valider »**.
- **Pour changer**, il suffit d'indiquer le numéro et l'option (par exemple « D-3 : option 1 »).

**Déjà tranché par l'utilisateur** (2026-10-17), et donc retiré des décisions ouvertes :
- onduleur posable à l'intérieur ;
- fonctionnement sans joueur dans la zone ;
- usure et léger bruit de l'onduleur acceptés ;
- trois rôles distincts : source, batterie, onduleur ;
- système minimal = source + onduleur, batterie facultative, autres équipements optionnels ;
- chaque source a un micro-onduleur intégré qui lisse sa production ; pas de parafoudre, de programmateur horaire ni de régulateur solaire.

---

## D-1. Contenu de la version 0.1

| Option | Contenu | Conséquences |
|---|---|---|
| 1 | **Socle** : testeur, onduleur, batteries facultatives, solaire, éolien, disjoncteur optionnel, compétence, usure, tableau de bord, fonctionnement sans joueur | Le cœur du mod est jouable tôt. L'hydraulique, la charge depuis un générateur vanilla et les autres équipements optionnels attendent la 0.2 |
| 2 | Utilitaire de survie (idées 1 à 5 : testeur, chargeur de piles, alarmes, réparations) | Livraison rapide, mais la production d'électricité, idée centrale, est repoussée |
| 3 | Tout le système d'énergie d'un coup (trois sources, charge depuis un générateur, pompe, tous les équipements optionnels) | Première version longue ; beaucoup de risques empilés avant le premier test en jeu |

**Recommandation : option 1 — à valider.** Elle dérisque d'abord le mécanisme le plus incertain, l'ancre d'alimentation (R-1), sur un périmètre testable.

## D-2. Mécanisme qui amène le courant (onduleur à l'intérieur)

| Option | Mécanisme | Conséquences |
|---|---|---|
| 1 | **Ancre d'alimentation** : l'onduleur est un objet simple, et le mod pose lui-même sa position de générateur sur les chunks de sa portée, reposée à chaque chargement, sur le serveur et sur les clients | Posable partout ; aucune toxicité, aucun incendie ; usure et bruit maîtrisés ; courant conservé sans joueur ; aucune fuite à la désinstallation. Il faut mesurer la consommation soi-même et tenir les clients à jour. À confirmer au prototype P1 |
| 2 | Vrai générateur du moteur **caché dehors**, relié à l'onduleur intérieur | Le moteur mesure la consommation, mais il faut un second objet dehors, la zone couverte est décalée, le son de générateur vanilla est imposé et le menu vanilla est à bloquer |
| 3 | Vrai générateur du moteur à l'intérieur, toxicité effacée après coup | **À exclure** : la toxicité abîme les occupants à chaque image avant d'être effacée (NM-20) |

**Recommandation : option 1 — à valider.** Repli prévu : l'option 2, si le prototype P1 échoue.

## D-3. Raccorder les appareils à l'onduleur

| Option | Règle | Conséquences |
|---|---|---|
| 1 | Automatique : tout appareil à moins de N cases est raccordé | Aucun geste ; peu lisible avec plusieurs onduleurs ; pas d'expérience |
| 2 | **Raccordement explicite par menu, en consommant du fil électrique** (1 fil pour 4 cases, portée 12) | Geste lisible, qui coûte une ressource vanilla et donne de l'expérience ; pas de câble visible en v0.1 |
| 3 | Câbles posés case par case | Immersif, mais lourd ; attend les tuiles définitives |

**Recommandation : option 2 — à valider.** `WirePerTiles = 0` rend le fil gratuit.

## D-4. Comment une batterie fait partie du réseau

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Batterie posée au sol (pose vanilla), puis raccordée à l'onduleur** | Vrai objet visible, avec son modèle 3D vanilla ; charge dans l'infobulle ; la ramasser la débranche. La charge et l'usure voyagent par les champs moteur de l'objet (NM-10) |
| 2 | Rack de batteries : un objet posé avec des emplacements ; « Installer une batterie » la retire de l'inventaire et l'enregistre | Aucun souci de synchronisation d'objets, mais les batteries ne sont plus visibles une par une et un objet de plus est à concevoir |
| 3 | Meuble conteneur vanilla câblé, où l'on range ses batteries | Familier, mais le conteneur mélange les rôles (rangement et batterie) et il faut tester la synchronisation de chaque meuble |

**Recommandation : option 1 — à valider.** C'est l'option qui sépare le mieux les rôles : chaque batterie est un appareil distinct, facultatif.

## D-5. Échelle d'énergie

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **1 unité de consommation moteur par heure = 1 000 W** (réfrigérateur-congélateur 130 W, lumière 2 W) | Ordres de grandeur crédibles |
| 2 | 1 unité = 10 000 W | Énergie très chère ; frustrant |
| 3 | Unités abstraites | Simple, mais le testeur perd son intérêt pédagogique |

**Recommandation : option 1 — à valider**, ajustable par `PowerScale`.

## D-6. Apprentissage des recettes

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Connues automatiquement au niveau requis** | Simple ; aucun objet de butin à créer |
| 2 | Magazines de mod | Raison d'explorer ; plus de contenu |
| 3 | Mixte | Bon compromis, mais plus de travail avant la 0.1 |

**Recommandation : option 1 pour la v0.1 — à valider.**

## D-7. Propriété des installations en multijoueur

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Commune, sous les règles de safehouse vanilla** | Adaptée à un serveur entre amis |
| 2 | Propriétaire unique | Protège du vol ; gêne le jeu en groupe |
| 3 | Propriétaire et invités | Souple, mais lourd |

**Recommandation : option 1 — à valider.**

## D-8. Bruit de l'onduleur

L'utilisateur accepte un très léger bruit.

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Bourdonnement léger** : les zombies l'entendent à 2 cases (option `InverterNoiseRadius`), et les joueurs proches entendent un son vanilla discret, à choisir au prototype | Cohérent et réglable. Il faut un émetteur en boucle côté client, qui s'arrête bien en MP (R-5) |
| 2 | Bruit pour les zombies seulement, aucun son pour les joueurs | Rien à produire côté son ; moins vivant |
| 3 | Silence total | Simple, mais l'onduleur devient un avantage gratuit |

**Recommandation : option 1 — à valider.** Un son propre au mod viendra avec les modèles définitifs.

## D-9. Ce qui continue sans joueur dans la zone

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Tout continue** : production, consommation à la dernière demande mesurée, usure, courant de la maison | Répond à l'exigence de l'utilisateur ; cohérent avec le carburant vanilla qui rattrape les heures |
| 2 | Production seulement | Généreux : batteries toujours pleines au retour |
| 3 | Tout s'arrête | Contraire à l'exigence de l'utilisateur |

**Recommandation : option 1 — à valider** pour le réglage par défaut de `SimulateUnloaded`. L'option 3 reste possible en sandbox.

## D-10. Onduleur et générateur vanilla sur les mêmes appareils

Chacun compte les appareils communs (NM-5).

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **v0.1 : laisser faire et avertir** ; v0.2 : bascule automatique (l'onduleur passe en veille quand un générateur vanilla tourne dans sa zone) | Rien de bloquant |
| 2 | Refuser la pose d'un onduleur à portée d'un générateur vanilla | Interdit l'usage « générateur le jour, batteries la nuit » |
| 3 | Bascule automatique dès la v0.1 | Meilleure expérience, mais plus de travail avant d'avoir validé l'ancre |

**Recommandation : option 1 — à valider.**

## D-11. Équipements optionnels

Liste détaillée dans `fonctionnel.md`, § 2.4 : disjoncteur, ordinateur de gestion, alarme de batterie faible. Parafoudre, programmateur horaire et régulateur solaire ont été retirés par l'utilisateur (2026-10-17). Le lissage de la production est assuré par le micro-onduleur intégré à chaque source.

| Option | Règle | Conséquences |
|---|---|---|
| 1 | **Disjoncteur seul en 0.1** ; ordinateur de gestion et alarme de batterie faible en 0.2 | Le système de base reste simple au lancement. La sécurité la plus utile (pas d'usure en cas de surcharge) arrive tout de suite |
| 2 | Aucun équipement optionnel avant la 0.2 | Le plus simple ; le disjoncteur manque aux joueurs qui découvrent la surcharge |
| 3 | Les trois dès la 0.1 | Riche, mais la 0.1 s'alourdit et chaque équipement ajoute des cas à tester |

**Recommandation : option 1 — à valider.** Chaque équipement peut être retiré ou repoussé sans toucher au reste : ils ne changent que des paramètres du pas de simulation.
