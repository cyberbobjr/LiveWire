> English version: [FAQ](../en/13-faq.md)

# FAQ

Réponses courtes sur Live Wire (`batman_LiveWire`, Project Zomboid Build 42.21, version 1.6.0). Le mod est publié sur le [Workshop Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3821807453). La portée de validation de cette mise à jour est précisée dans [Multijoueur](12-multijoueur.md#état). Pour le détail, suivez les liens vers les pages correspondantes.

## Pour commencer

**Faut-il des batteries ?**
Non. Une source et un onduleur forment le système minimal. Sans batterie, la maison ne tourne que sur la production du moment (par exemple trois panneaux en plein soleil font tourner un frigo-congélateur à midi, pas la nuit). Ajoutez une powerbank pour couvrir la nuit. Voir [Premiers pas](01-premiers-pas.md).

**Quelle installation minimale ?**
Une source (panneau photovoltaïque 100 W, éolienne 400 W ou roue à aubes 120 W) et un onduleur, reliés par du fil électrique. Tout appareil alimenté situé à 20 cases et 3 étages de l'onduleur au plus est alors alimenté, sans câblage appareil par appareil. Voir [Équipements](02-equipements.md).

**Quel niveau d'Électricité pour quoi ?**
Powerbank, alarme de batterie faible et kit d'insonorisation : niveau 2. Panneau photovoltaïque, disjoncteur et groupe électrogène de secours : niveau 3. Onduleur : niveau 5. Pose/ramassage des éoliennes et roues à aubes : niveau 2. Assemblage final de l’éolienne, batterie stationnaire et ordinateur de gestion : niveau 6. Fabrication de la roue à aubes et délestage : niveau 7. Remise à neuf et cellules à partir de déchets : niveau 8. Lire un testeur (alimenté ou non) ne demande aucun niveau. Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) et [Recettes](08-recettes.md).

## Raccordement

**Quelle portée de câble, et combien coûte le fil ?**
La portée est de 12 cases horizontalement (option sandbox `LinkRange`, de 4 à 30), avec 3 étages d'écart au plus par défaut (option `LinkVerticalRange`, de 0 à 10 ; 0 = même étage). Le coût est de 1 fil électrique (`Base.ElectricWire`) par tranche de 4 cases horizontales, arrondi au-dessus, au moins 1 (option `WirePerTiles`, 0 = gratuit). Voir [Raccordement](03-raccordement.md) et [Options sandbox](11-options-sandbox.md).

**Comment raccorder ou débrancher un équipement ?**
Clic droit sur l'équipement, « Live Wire », puis son nom, puis « Raccorder à un onduleur » et choisissez l'onduleur (la liste donne distance et fils). Ou clic droit sur l'onduleur, « Raccorder un équipement » ou « Débrancher un équipement ». Le menu de l'équipement propose aussi « Débrancher de l'onduleur ». Voir [Raccordement](03-raccordement.md).

**Combien d'appareils de chaque sorte par réseau ?**
Autant de sources et de powerbanks que voulu par onduleur, avec jusqu'à quatre onduleurs couplés par réseau. Au plus un disjoncteur, une alarme, un ordinateur de gestion et un groupe électrogène de secours par réseau. Voir [Raccordement](03-raccordement.md).

**Que se passe-t-il si je ramasse l'onduleur ?**
Tout son réseau est déconnecté. Le tourner conserve les liaisons. Une source ramassée garde son état, mais reposée elle est « Non raccordé » tant que vous ne la reliez pas. Voir [Raccordement](03-raccordement.md).

## Production

**Combien de panneaux faut-il pour une maison ?**
Aucune limite : les productions s'additionnent. Une journée de référence (frigo-congélateur, 10 lumières pendant 6 h, télévision pendant 3 h) demande environ 3,8 kWh avec les valeurs du jeu et 7,4 kWh en Réaliste 1993. En hiver, 6 panneaux plus 1 éolienne donnent environ 4,3 kWh (assez pour les valeurs du jeu), et 1 roue à aubes plus 8 panneaux environ 7,7 kWh (assez pour Réaliste 1993). Voir [Production et calculs](04-production-et-calculs.md#exemple-de-dimensionnement).

**Quelle vitesse de vent faut-il à l'éolienne ?**
Rien en dessous de 10 km/h, 100 % (400 W) de 45 à 85 km/h, et frein automatique au-delà de 85 km/h. Entre les deux, 25 km/h donnent environ 31 W et 40 km/h environ 252 W. Le vent compte +15 % par étage jusqu'au 3e. Voir [Production et calculs](04-production-et-calculs.md).

**Où poser la roue à aubes ?**
Au rez-de-chaussée, sur la berge d'une rivière, à côté de l'eau de la rivière. Les lacs et étangs sont refusés car le moteur ne distingue pas le courant d'un lac. Elle demande le niveau 2 à la pose (7 à la fabrication) et produit jour et nuit (environ 2,9 kWh par jour). Voir [Équipements](02-equipements.md).

**Et la nuit, l'hiver, la neige ?**
Le panneau suit une courbe sinusoïdale entre l'aube et le crépuscule : environ 0,94 kWh par jour d'été et 0,60 kWh l'hiver, et il reste 20 % sous un ciel entièrement couvert. La neige le bloque pendant une chute jusqu'à la fonte au-dessus de 0 °C ou jusqu'à « Déneiger ». La roue à aubes produit jour et nuit. Voir [Production et calculs](04-production-et-calculs.md).

**Comment dimensionner le stockage pour la nuit ?**
Une nuit d'hiver de 14 h pour un frigo-congélateur et 10 lumières demande environ 2,4 kWh : à peu près 4 batteries de voiture ou 2 batteries stationnaires. Une powerbank compte 4 batteries. Voir [Production et calculs](04-production-et-calculs.md).

## Stockage et appareils

**Les frigos continuent-ils de fonctionner quand je quitte la zone ?**
Oui, tant qu'il y a du courant. Le serveur simule toutes les 10 minutes de jeu même sans personne à proximité (option `SimulateUnloaded`). Vérifié en solo : un steak dans un frigo alimenté, joueur à 300 cases pendant 10 heures de jeu, a vieilli de 0,083 jour au lieu de 0,417. Le rattrapage rejoue les changements d'alimentation conservés sur 60 jours de jeu ; un ancien historique manquant ne peut pas être reconstitué. Voir [Premiers pas](01-premiers-pas.md).

**Qu'est-ce qui consomme ?**
Cela dépend de l'option sandbox `ConsumptionProfile`. Avec les valeurs du jeu (défaut) : lumière 2 W, radio 10 W, télévision 30 W, frigo seul 80 W, cuisinière, micro-ondes, lave-linge et sèche-linge 90 W chacun, frigo-congélateur 130 W, lave-linge + sèche-linge superposés jusqu'à 1 800 W. Avec Réaliste 1993 : lumière 60 W, télévision 80 W, frigo-congélateur 130 W, cuisinière électrique 2 000 W, sèche-linge 3 000 W. L'onduleur lui-même consomme 20 W au repos. Voir [Production et calculs](04-production-et-calculs.md#consommation-des-appareils).

**Pourquoi le disjoncteur (ou l'onduleur) a-t-il sauté ?**
La demande des appareils de la maison a dépassé 1 500 W, par exemple un lave-linge + sèche-linge superposés. Avec un disjoncteur, c'est lui qui saute et l'onduleur ne subit aucun dommage ; utilisez « Réarmer le disjoncteur » une fois la charge réduite. Sans disjoncteur, l'onduleur saute et perd 3 points d'état ; utilisez « Réarmer » sur lui. Voir [Équipements optionnels](06-equipements-optionnels.md).

**1 500 W ne suffisent pas. Puis-je associer plusieurs onduleurs ?**
Oui : couplez-les. Posez un second onduleur sans aucun équipement raccordé, clic droit dessus, « Live Wire », puis « Coupler à un onduleur », et choisissez l'onduleur maître à portée de câble. Coût : le fil électrique de la distance et 1 kit de couplage d'onduleurs (recette au niveau 6 d'Électricité). Un maître accepte jusqu'à 3 esclaves : 4 onduleurs donnent 6 000 W sur un seul réseau, avec un seul parc de batteries et la zone alimentée du maître. Chaque onduleur allumé consomme 20 W à vide et s'use comme d'habitude ; un esclave éteint ou cassé ne compte plus. « Découpler » sur l'esclave rend le kit. Voir [Équipements optionnels](06-equipements-optionnels.md#onduleurs-en-parallèle-couplage).

**Comment fonctionne l'alarme de batterie faible ?**
Sous 20 % de stock, elle envoie un message aux joueurs à moins de 30 cases et bipe toutes les 10 minutes de jeu jusqu'à « Couper la sonnerie ». Le feu reste allumé jusqu'au retour du stock au-dessus de 25 %. Niveau 2 requis. Voir [Équipements optionnels](06-equipements-optionnels.md).

**Comment fonctionne le groupe électrogène de secours ?**
Un générateur vanilla raccordé à l'onduleur est démarré par le mod sous 20 % de batterie et arrêté à 90 % (options `BackupStartPercent` et `BackupStopPercent`). Il fournit 1 200 W et brûle 1 L de carburant pour 3 kWh en plus de sa consommation vanilla. Il reste bruyant et toxique en intérieur, doit être branché et rempli comme en vanilla, et ne démarre jamais sans batterie. Voir [Équipements optionnels](06-equipements-optionnels.md).

## Logiciel et ordinateur

**Faut-il un ordinateur ou le Computer Mod ?**
Non, l'onduleur a son propre écran LCD (« Ouvrir l'écran de l'onduleur », 5 pages). Un ordinateur ne sert que pour le logiciel de gestion (« Live Wire Monitor »), qui ajoute un historique de 48 h et la prévision « les batteries tiendront jusqu'au lever du soleil ». Voir [Écran et logiciel](05-ecran-et-logiciel.md).

**Comment cela marche-t-il avec ou sans Computer Mod ou Laptop Mod ?**
Sans eux, un ordinateur de bureau vanilla raccordé à l'onduleur ouvre le logiciel sur l'écran d'ordinateur propre au mod. Avec le Computer Mod (Workshop 3725497089) ou le Laptop Mod (3798992436), facultatifs, le logiciel arrive sur un disque et apparaît comme une application « Live Wire » sur leur bureau. Voir [Écran et logiciel](05-ecran-et-logiciel.md).

**Où trouver le disque ?**
« Disque : logiciel de gestion Live Wire » se trouve dans le butin d'ordinateurs, quand Computer Mod ou Laptop Mod est actif : caisses d'ordinateurs (environ 7,8 % par conteneur), bureaux d'université d'électricité (7,8 %), ordinateurs de magasin d'électronique (2,0 %), entre autres. Clic droit sur l'ordinateur avec le disque, puis « Installer le logiciel Live Wire ». Voir [Tables de butin](09-tables-de-butin.md).

## Bruit et zombies

**L'onduleur est-il bruyant, peut-on le faire taire ?**
Il émet un bourdonnement qui ne s'entend qu'à une case autour d'un onduleur allumé. Chaque joueur règle son volume dans Options > Mods > Live Wire (0 = coupé). Un kit d'insonorisation le supprime entièrement. Voir [Écran et logiciel](05-ecran-et-logiciel.md).

**Comment marche le kit d'insonorisation, et l'onduleur attire-t-il les zombies ?**
Les zombies entendent un onduleur allumé à 2 cases (option `InverterNoiseRadius`, 0 = silencieux). Le kit (niveau 2, « Insonoriser l'onduleur » avec un tournevis) supprime le bourdonnement et ce bruit, mais l'onduleur chauffe davantage et s'use 25 % plus vite. « Retirer l'insonorisation » rend le kit. Voir [Équipements optionnels](06-equipements-optionnels.md).

## Entretien

**À quelle vitesse les appareils s'usent-ils ?**
Par jours de jeu, en gros : panneau -1 tous les 10 jours, éolienne -1 tous les 4, roue à aubes -1 tous les 6, onduleur -1 tous les 5 jours allumé (deux fois plus vite au-dessus de 80 % de charge), disjoncteur -1 tous les 15, powerbank et alarme -1 tous les 30. Les dégâts d'orage sont désactivés par défaut (`StormDamage`). Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md).

**Comment réparer ou remettre à neuf un appareil ?**
Réparation : 1 déchet électronique + 1 fil électrique, pour 5 + votre niveau d'Électricité points (jusqu'à 90), avec un risque d'échec de max(5, 40 - 5 x niveau) % qui fait perdre les pièces. Remise à neuf (niveau 8, 4 déchets + 2 fils) : retour à 100. Une batterie se reconditionne au niveau 4 (6 si morte) : tournevis conservé, déchet, fil et 0,5 L d'eau ; +15 d'état, plafond 80, quatre réparations au maximum. Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md).

## Multijoueur et serveur

**Cela fonctionne-t-il sur un serveur dédié ?**
Il est conçu pour : production, stock, états, pannes et expérience sont calculés par le serveur, qui revérifie chaque demande des clients. Les campagnes antérieures ont couvert le solo et un serveur dédié Windows avec deux clients ; le bilan distingue ces états des derniers changements. Voir [Multijoueur](12-multijoueur.md).

**Quels sont l'ID Workshop et l'ID du mod ?**
L'ID du mod est `batman_LiveWire`. L'ID Workshop est `3821807453`. On peut aussi copier `Contents/mods/batman_LiveWire` dans `Zomboid/mods`. Voir [Premiers pas](01-premiers-pas.md#installation).

**Quelles options sandbox comptent pour un serveur ?**
Page « Live Wire » : `ConsumptionProfile` (ultra-réaliste 1993, réaliste 1993, valeurs du jeu, confort), `PowerScale`, multiplicateurs de sources (`SolarMultiplier`, `WindMultiplier`, `HydroMultiplier`), `BatteryCapacityMultiplier`, multiplicateurs d'usure, `LinkRange`, `WirePerTiles`, `SkillGates` et `SimulateUnloaded` (activé par défaut). Si le serveur se met en pause quand il est vide, l'installation aussi. Voir [Options sandbox](11-options-sandbox.md).

**Qui peut utiliser une installation, et y a-t-il du retard ?**
Les installations partagées suivent les règles vanilla des refuges. Le logiciel peut avoir jusqu'à 10 minutes de jeu de retard. Les générateurs vanilla ne changent pas : si un générateur et un onduleur couvrent les mêmes appareils, les deux consomment. Voir [Multijoueur](12-multijoueur.md).

## Compatibilité

**Puis-je l'utiliser avec d'autres mods d'énergie ?**
Les autres mods d'énergie ne sont pas pris en charge avec Live Wire. C'est une création originale : aucun code ni ressource d'un autre mod. Les intégrations facultatives incluent Computer Mod, Laptop Mod, Project Viewpoint et Useful Barrels. Voir [Premiers pas](01-premiers-pas.md).

## Dépannage

**Un équipement affiche « Non raccordé ».**
Il n'est relié à aucun onduleur. Clic droit, « Live Wire », puis « Raccorder à un onduleur ». L'onduleur doit être à portée de câble (12 cases horizontalement et 3 étages d'écart au plus par défaut). Une source reposée après ramassage doit être reliée de nouveau. Voir [Raccordement](03-raccordement.md).

**Tout est relié mais rien n'est alimenté.**
Vérifiez que l'onduleur est allumé (« Allumer ») et non déclenché (« Réarmer »), que les appareils sont à 20 cases et 3 étages (utilisez « Afficher la zone alimentée »), et qu'une source produit réellement (nuit, pas de vent, neige). L'écran de l'onduleur montre production, charge et état. Voir [Écran et logiciel](05-ecran-et-logiciel.md).

**La tuile n'apparaît pas à la pose.**
Le curseur de meuble refuse les cases qui enfreignent les règles de pose et affiche la raison en rouge dans son panneau : en extérieur à ciel ouvert pour panneau et éolienne, berge de rivière au rez-de-chaussée pour la roue à aubes, mur nord ou ouest pour le disjoncteur. Il faut aussi un tournevis et le niveau d'Électricité requis. Voir [Équipements](02-equipements.md).
