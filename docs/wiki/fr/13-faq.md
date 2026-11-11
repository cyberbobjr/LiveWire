> English version: [FAQ](../en/13-faq.md)

# FAQ

Réponses courtes sur LiveWire (`batman_LiveWire`, Project Zomboid Build 42.21 et versions ultérieures). Le mod est publié sur le [Workshop Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3821807453). Pour les détails, suivez les liens vers les pages correspondantes.

## Démarrage

**Ai-je besoin de batteries ?**
Non. Une source et un onduleur forment le système minimal. Sans batteries, la maison ne fonctionne que sur la production du moment (par exemple, trois panneaux par temps ensoleillé font tourner un réfrigérateur-congélateur à midi, pas la nuit). Ajoutez une powerbank pour couvrir la nuit. Voir [Premiers pas](01-premiers-pas.md).

**Quelle est la configuration minimale ?**
Une source (panneau solaire 100 W, éolienne 400 W ou roue à aubes 120 W) et un onduleur, reliés par du fil électrique. Tout appareil alimenté à moins de 20 cases et 3 étages de l'onduleur reçoit alors le courant, sans câblage par appareil. Voir [Équipements](02-equipements.md).

**Quel niveau d'Électricité faut-il pour quoi ?**
La pose et le ramassage demandent un tournevis, mais aucun niveau. Le niveau sert au raccordement à un onduleur : powerbank, alarme de batterie faible, générateur de secours, éolienne et roue à aubes : niveau 2 ; panneau photovoltaïque, disjoncteur, onduleur et armoire onduleur (le premier branchement la met en service), couplage, pompe à eau et ordinateur de gestion (avec délestage) : niveau 3. Fabrication : testeur de tension niveau 1 ; powerbank, alarme de batterie faible et kit d'insonorisation niveau 2 ; roue à aubes niveau 4 ; tous les autres appareils et kits, la batterie stationnaire et les cellules à partir de pièces électroniques niveau 3. Les pales et mâts d'éolienne, ainsi que toutes les recettes de démontage, ne demandent aucun niveau. La remise à neuf d'un appareil demande le niveau 3. Lire un testeur (alimenté ou non) ne demande aucun niveau. Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) et [Recettes](08-recettes.md).

## Raccordement

**Quelle est la portée des câbles et que coûte le fil ?**
La portée est de 12 cases à l'horizontale (option sandbox `LinkRange`, de 4 à 30), et de 3 étages au plus par défaut (option sandbox `LinkVerticalRange`, de 0 à 10 ; 0 = même étage). Le coût est de 1 fil électrique (`Base.ElectricWire`) par 4 cases de distance horizontale, arrondi au supérieur, avec un minimum de 1 (option sandbox `WirePerTiles`, 0 = gratuit). Voir [Raccordement](03-raccordement.md) et [Options sandbox](11-options-sandbox.md).

**Comment raccorder ou débrancher un appareil ?**
Clic droit sur l'appareil, « LiveWire », puis son nom, puis « Raccorder à un onduleur » et choisissez l'onduleur (la liste indique la distance et les fils). Ou clic droit sur l'onduleur et utilisez « Raccorder des équipements » ou « Débrancher des équipements ». Le menu de l'appareil propose aussi « Débrancher de l'onduleur ». Voir [Raccordement](03-raccordement.md).

**Combien d'appareils de chaque type par réseau ?**
Autant de sources et de powerbanks que vous voulez par onduleur, avec jusqu'à quatre onduleurs couplés par réseau. Un disjoncteur, une alarme de batterie faible, un ordinateur de gestion et un générateur de secours au plus par réseau. Cette limite ne concerne pas les tableaux électriques de LiveWire Extended, qui accueillent plusieurs disjoncteurs (un par circuit). Voir [Raccordement](03-raccordement.md).

**Que se passe-t-il quand je ramasse l'onduleur ?**
Tout son réseau est débranché. La rotation garde les raccordements. Une source ramassée garde son état, mais une fois reposée elle est « Non raccordé » jusqu'à ce que vous la raccordiez de nouveau. Voir [Raccordement](03-raccordement.md).

## Production

**Combien de panneaux faut-il à une maison ?**
Il n'y a pas de limite : les productions s'additionnent. Une journée de référence (réfrigérateur-congélateur, 10 lampes pendant 6 h, télévision pendant 3 h) demande environ 3,8 kWh avec Valeurs du jeu et 7,4 kWh avec Réaliste 1993. En hiver, 6 panneaux et 1 éolienne donnent environ 7,8 kWh avec un vent régulier de 25 km/h (suffisant pour Réaliste 1993), et 1 roue à aubes et 8 panneaux environ 6,5 kWh (suffisant pour Valeurs du jeu). Voir [Production et calculs](04-production-et-calculs.md).

**Quelle vitesse de vent faut-il à l'éolienne ?**
Elle ne produit rien en dessous de 10 km/h, donne environ 15 W à 10 km/h, atteint 100 % (400 W) de 30 à 85 km/h, et freine automatiquement au-delà de 85 km/h. Entre les deux, 15 km/h donne environ 50 W et 25 km/h environ 231 W. Installez-la sur un toit pour plus de vent. Le vent compte +15 % par étage, jusqu'au 3e. Voir [Production et calculs](04-production-et-calculs.md).

**Où poser la roue à aubes ?**
Au rez-de-chaussée, sur une berge, à côté de l'eau d'une rivière. Les lacs et étangs sont refusés car le moteur ne sait pas distinguer le courant d'un lac. Elle demande le niveau 2 d'Électricité pour être raccordée à un onduleur (niveau 4 pour la fabriquer) ; la pose ne demande aucun niveau, et elle produit de jour comme de nuit (environ 2,9 kWh par jour). Voir [Équipements](02-equipements.md).

**Et la nuit, l'hiver et la neige ?**
Les panneaux solaires suivent une courbe sinusoïdale entre l'aube et le crépuscule : un panneau neuf sous un ciel dégagé donne environ 0,93 kWh par journée d'été et 0,60 kWh en hiver avant le rendement d'installation, et 20 % subsistent sous un ciel totalement couvert. La neige arrête un panneau pendant les chutes, jusqu'à ce qu'elle fonde au-dessus de 0 °C ou que vous utilisiez « Déneiger ». Les roues à aubes tournent jour et nuit. Voir [Production et calculs](04-production-et-calculs.md).

**Comment dimensionner le stockage pour la nuit ?**
Avec Valeurs du jeu, la nuit d'hiver de 14 h de la journée de référence (réfrigérateur-congélateur, lampes et télévision) demande environ 2,3 kWh : à peu près 4 batteries de voiture ou 2 batteries stationnaires. Une powerbank compte pour 4 batteries. Voir [Production et calculs](04-production-et-calculs.md).

**La maison se recharge-t-elle sur le réseau public ?**
Oui, tant que le réseau public fonctionne et que l'option sandbox `GridCharging` est activée (par défaut : activée). Un onduleur à l'intérieur d'un bâtiment s'alimente alors lui-même et charge ses batteries à partir du réseau, jusqu'au cinquième de sa puissance nominale. Voir [Options sandbox](11-options-sandbox.md).

## Stockage et appareils

**Les réfrigérateurs continuent-ils de fonctionner quand je quitte la zone ?**
Oui, tant qu'il y a du courant. Le serveur simule toutes les 10 minutes de jeu même sans personne à proximité (option sandbox `SimulateUnloaded`). Le rattrapage rejoue les changements de courant conservés pendant 60 jours de jeu ; l'historique manquant au-delà ne peut pas être récupéré. Voir [Premiers pas](01-premiers-pas.md).

**Qu'est-ce qui consomme du courant ?**
Cela dépend de l'option sandbox `ConsumptionProfile`. Avec les valeurs par défaut du jeu : lampe 2 W, radio 10 W, télévision 30 W, réfrigérateur seul 80 W, cuisinière, micro-ondes, lave-linge et sèche-linge 90 W chacun, réfrigérateur-congélateur 130 W, un lave-linge et sèche-linge superposés jusqu'à 1 800 W. Avec Réaliste 1993 : lampe 60 W, télévision 80 W, réfrigérateur-congélateur 130 W, cuisinière électrique 2 000 W, sèche-linge 3 000 W. L'onduleur lui-même consomme 20 W à vide. Voir [Production et calculs](04-production-et-calculs.md).

**Pourquoi le disjoncteur (ou l'onduleur) a-t-il sauté ?**
La demande des appareils de la maison a dépassé 1 500 W, par exemple un lave-linge et un sèche-linge superposés. Avec un disjoncteur, il saute et l'onduleur ne subit aucun dommage ; utilisez « Réarmer le disjoncteur » une fois la charge réduite. Sans disjoncteur, l'onduleur saute et perd 3 points d'état ; utilisez « Réarmer » sur lui. Voir [Équipements optionnels](06-equipements-optionnels.md).

**1 500 W ne suffisent pas. Puis-je combiner plusieurs onduleurs ?**
Oui : couplez-les. Posez un second onduleur sans équipement raccordé, faites un clic droit dessus, « LiveWire », puis « Coupler à un onduleur », et choisissez l'onduleur maître à portée de câble. Il coûte le fil électrique de la distance et 1 kit de couplage d'onduleurs (fabrication au niveau 3 d'Électricité). Un maître accepte jusqu'à 3 esclaves : 4 onduleurs donnent donc 6 000 W sur un même réseau, avec une seule banque de batteries et la zone alimentée du maître. Chaque onduleur allumé consomme 20 W à vide et s'use normalement ; un esclave éteint ou cassé ne compte plus. « Découpler » sur l'esclave rend le kit. Voir [Équipements optionnels](06-equipements-optionnels.md). Vous pouvez aussi transformer un onduleur en **armoire onduleur** (4 500 W, 60 W à vide, fabrication au niveau 3 d'Électricité) ; les armoires se couplent comme les onduleurs.

**Comment fonctionne l'alarme de batterie faible ?**
Sous 20 % de stock, elle envoie un message aux joueurs à moins de 30 cases, répété toutes les 2 heures de jeu, et bipe toutes les 10 minutes de jeu jusqu'à ce que vous choisissiez « Couper la sonnerie ». Le voyant reste allumé jusqu'à ce que le stock remonte au-dessus de 25 %. Le raccordement demande le niveau 2 d'Électricité. Voir [Équipements optionnels](06-equipements-optionnels.md).

**Comment fonctionne le générateur de secours ?**
Un générateur vanilla raccordé à l'onduleur est démarré par le mod sous 20 % de batterie et arrêté à 90 % (options sandbox `BackupStartPercent` et `BackupStopPercent`). Il fournit 1 200 W et brûle 1 L de carburant par 3 kWh, en plus de sa consommation vanilla. Il reste bruyant et toxique à l'intérieur, doit être branché et alimenté comme en vanilla, et ne démarre jamais sans batteries. Voir [Équipements optionnels](06-equipements-optionnels.md).

**Comment rendre le générateur de secours au contrôle automatique ?**
Si vous allumez ou éteignez vous-même le générateur (menu vanilla), le mod respecte votre choix : il passe en **contrôle manuel** et ne le pilote plus. Un message près du générateur l'indique, et l'écran de l'onduleur ainsi que le logiciel de gestion affichent « contrôle manuel ». Pour lui rendre le contrôle : clic droit sur le générateur > **LiveWire** > **Générateur de secours** > **Reprendre le secours automatique**. Raccorder un générateur déjà en marche le place aussi en contrôle manuel.

## Logiciel et ordinateur

**Ai-je besoin d'un ordinateur ou du Computer Mod ?**
Non, l'onduleur a son propre écran LCD (« Ouvrir l'écran de l'onduleur », 5 pages). Un ordinateur n'est nécessaire que pour le logiciel de gestion (« LiveWire Monitor »), qui ajoute un historique de 48 h et la prévision « les batteries tiendront jusqu'au lever du soleil ». Voir [Écran et logiciel de l'onduleur](05-ecran-et-logiciel.md).

**Comment cela fonctionne-t-il avec ou sans le Computer Mod ou le Laptop Mod ?**
Sans eux, un ordinateur de bureau vanilla raccordé à l'onduleur ouvre le logiciel sur l'écran d'ordinateur propre au mod. Avec le Computer Mod (Workshop 3725497089) ou le Laptop Mod (3798992436), en option, le logiciel est sur un disque et apparaît comme une application « LiveWire » sur leur bureau. Voir [Écran et logiciel de l'onduleur](05-ecran-et-logiciel.md).

**Où trouver le disque ?**
« Disque : logiciel de gestion LiveWire » se trouve dans le butin informatique, seulement quand le Computer Mod est actif (le Laptop Mod est son extension) : caisses d'informatique (environ 4,7 % par conteneur), bureaux universitaires d'électricité (4,7 %), rayon informatique des magasins d'électronique (1,2 %), entre autres. Faites un clic droit sur l'ordinateur avec le disque et choisissez « Installer le logiciel LiveWire ». Voir [Tables de butin](09-tables-de-butin.md).

**Pourquoi « Afficher les consommateurs » ne compte pas mes appareils ?**
Tant que le réseau public fonctionne, il alimente la maison : ses appareils ne consomment rien sur l'onduleur. La vue les montre en blanc, et le message « Réseau public encore actif » s'affiche au-dessus du personnage et dans la fenêtre de légende. Ils passent sur l'onduleur quand le jeu coupe l'électricité. Voir [Écran et logiciel](05-ecran-et-logiciel.md).

## Bruit et zombies

**L'onduleur est-il bruyant, et peut-on le faire taire ?**
Il produit un bourdonnement entendu à environ deux cases d'un onduleur allumé. Chaque joueur règle son volume dans Options > Mods > LiveWire (0 = coupé). Un kit d'insonorisation le supprime entièrement. Voir [Écran et logiciel de l'onduleur](05-ecran-et-logiciel.md).

**Comment fonctionne le kit d'insonorisation, et l'onduleur attire-t-il les zombies ?**
Les zombies entendent un onduleur en marche dans un rayon de 2 cases (option sandbox `InverterNoiseRadius`, 0 = silencieux). Le kit (niveau 2, « Insonoriser l'onduleur » avec un tournevis) supprime à la fois le bourdonnement et ce bruit, mais l'onduleur chauffe davantage et s'use 25 % plus vite. « Retirer l'insonorisation » rend le kit. Voir [Équipements optionnels](06-equipements-optionnels.md).

## Entretien

**À quelle vitesse les appareils s'usent-ils ?**
Par jours de jeu, en gros : panneau solaire -1 tous les 10 jours, éolienne -1 tous les 4, roue à aubes -1 tous les 6, onduleur -1 tous les 5 quand il est allumé (deux fois plus vite au-dessus de 80 % de charge), disjoncteur -1 tous les 15, powerbank et alarme -1 tous les 30. Les dégâts d'orage sont désactivés par défaut (`StormDamage`). Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md).

**Comment réparer ou remettre à neuf un appareil ?**
Réparation : 1 pièce électronique + 1 fil électrique, qui donne 5 + votre niveau d'Électricité en points d'état (jusqu'à 90), avec un échec de max(5 ; 40 − 5 × niveau) %, divisé par deux dès le niveau 8, qui fait perdre les pièces. La remise à neuf (niveau 3, 4 pièces électroniques + 2 fils électriques) rétablit 100. Une batterie peut être reconditionnée au niveau 4 (6 si elle est morte) : tournevis conservé, 1 pièce électronique, 1 fil et 0,5 L d'eau ; +15 d'état, plafond 80, quatre réparations au maximum. Voir [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md).

## LiveWire Extended

**Qu'est-ce que LiveWire Extended ?**
Une extension optionnelle, dans le même élément du Workshop que LiveWire. Elle raccorde un bâtiment entier à un onduleur, alimente des zones extérieures par une borne électrique et câble chaque appareil sur son propre disjoncteur d'un tableau électrique. Voir [LiveWire Extended](14-livewire-extended.md).

**Pourquoi un tableau électrique ne s'accroche-t-il pas à l'extérieur ?**
Un tableau fabriqué n'est pas étanche. Le curseur de meuble refuse un emplacement extérieur et indique la raison. Accrochez-le sur un mur intérieur d'un bâtiment, ou dans une pièce fermée et couverte. Voir [LiveWire Extended](14-livewire-extended.md#tableaux-électriques).

## Multijoueur et serveur

**Cela fonctionne-t-il sur un serveur dédié ?**
C'est prévu pour : la production, les stocks, les états, les pannes et l'expérience sont calculés par le serveur, qui vérifie chaque demande du client. Voir [Multijoueur](12-multijoueur.md).

**Quels sont les identifiants Workshop et Mod ?**
L'identifiant du mod est `batman_LiveWire`. L'identifiant Workshop est `3821807453` ; LiveWire Extended (`batman_LiveWireExtended`) se trouve dans le même élément du Workshop. Vous pouvez aussi copier `Contents/mods/batman_LiveWire` dans `Zomboid/mods`. Voir [Premiers pas](01-premiers-pas.md).

**Quelles options sandbox comptent pour un serveur ?**
Page « LiveWire » : `ConsumptionProfile` (ultra-réaliste 1993, réaliste 1993, valeurs du jeu, confort), `PowerScale`, multiplicateurs de sources (`SolarMultiplier`, `WindMultiplier`, `HydroMultiplier`), `BatteryCapacityMultiplier`, multiplicateurs d'usure, `LinkRange`, `WirePerTiles`, `SkillGates`, `SimulateUnloaded` (activée par défaut) et `GridCharging` (activée par défaut). Si le serveur se met en pause quand il est vide, l'installation se met aussi en pause. Voir [Options sandbox](11-options-sandbox.md).

**Qui peut utiliser une installation, et y a-t-il du décalage ?**
Les installations partagées suivent les règles vanilla de la planque (safehouse). Le logiciel peut avoir jusqu'à 10 minutes de jeu de retard. Les générateurs vanilla ne changent pas : si un générateur et un onduleur alimentent les mêmes appareils, les deux comptent. Voir [Multijoueur](12-multijoueur.md).

## Compatibilité

**Puis-je l'utiliser avec d'autres mods d'énergie ?**
Les autres mods d'énergie ne sont pas pris en charge avec LiveWire. LiveWire est une création originale : aucun code ni aucun actif n'a été repris d'un autre mod. LiveWire Extended est incompatible avec LG Extended Electricity et Knox Power. Les intégrations optionnelles incluent Computer Mod, Laptop Mod, Project Viewpoint et Useful Barrels ; avec LiveWire Extended, My Tailor Is Rich et Functional Appliances 2 suivent leur disjoncteur. Voir [LiveWire Extended](14-livewire-extended.md#autres-mods).

## Dépannage

**Un appareil affiche « Non raccordé ».**
Il n'est pas relié à un onduleur. Faites un clic droit dessus, « LiveWire », puis « Raccorder à un onduleur ». L'onduleur doit être à portée de câble (12 cases à l'horizontale et 3 étages au plus par défaut). Une source reposée après ramassage doit être raccordée de nouveau. Voir [Raccordement](03-raccordement.md).

**Tout est raccordé mais rien n'est alimenté.**
Vérifiez que l'onduleur est allumé (« Allumer ») et non déclenché (« Réarmer »), que les appareils sont à moins de 20 cases et 3 étages (utilisez « Afficher la zone alimentée »), et qu'une source produit réellement (nuit, pas de vent, neige). L'écran de l'onduleur affiche la production, la charge et l'état. Voir [Écran et logiciel de l'onduleur](05-ecran-et-logiciel.md).

**La tuile n'apparaît pas quand je la pose.**
Le curseur de meuble refuse les cases qui enfreignent les règles de pose et affiche la raison en rouge dans son panneau : à l'extérieur, à ciel ouvert, pour le panneau solaire et l'éolienne ; berge au rez-de-chaussée pour la roue à aubes ; un mur nord ou ouest pour le disjoncteur. La pose demande un tournevis mais aucun niveau d'Électricité ; le niveau ne s'applique qu'au raccordement à un onduleur. Voir [Équipements](02-equipements.md).
