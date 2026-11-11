> English version: [Sandbox Options](../en/11-sandbox-options.md)

# Options sandbox

Les réglages du jeu et du serveur sont sur deux pages des options sandbox : **LiveWire** pour le mod de base, et **LiveWire Extended** pour l'extension optionnelle (seulement quand l'extension est activée).

## Page LiveWire

| Nom dans le jeu | Option | Défaut | Plage | Effet |
|---|---|---|---|---|
| Fréquence des équipements et pièces LiveWire | `EquipmentLootMultiplier` | 5 | 1–20 | Poids de butin des équipements et pièces LiveWire (appareils, kits, cellules photovoltaïques, pales, mâts) et des équipements LiveWire Extended ; redémarrage requis, prochains tirages seulement. Voir [Tables de butin](09-tables-de-butin.md) |
| Échelle de puissance | `PowerScale` | 1 | 0,1–10 | Multiplie la consommation donnée par le profil (1 = aucun changement) |
| Profil de consommation | `ConsumptionProfile` | Valeurs du jeu | Ultra-réaliste 1993, Réaliste 1993, Valeurs du jeu, Confort | Puissance absorbée par les appareils allumés ; voir le tableau de [Production et calculs](04-production-et-calculs.md#consommation-des-appareils) |
| Production solaire | `SolarMultiplier` | 1 | 0–10 | Production des panneaux photovoltaïques |
| Production éolienne | `WindMultiplier` | 1 | 0–10 | Production des éoliennes |
| Production hydraulique | `HydroMultiplier` | 1 | 0–10 | Production des roues à aubes |
| Capacité des batteries | `BatteryCapacityMultiplier` | 1 | 0,1–10 | Capacité de toutes les batteries |
| Usure des batteries | `BatteryWearMultiplier` | 1 | 0–10 | Usure des batteries ; 0 = aucune |
| Usure des appareils | `DeviceWearMultiplier` | 1 | 0–10 | Usure des sources, des onduleurs et des équipements ; 0 = aucune |
| Rayon du bruit de l'onduleur | `InverterNoiseRadius` | 2 | 0–10 | Rayon en cases du bourdonnement entendu par les zombies ; 0 = silencieux |
| Portée des câbles | `LinkRange` | 12 | 4–30 | Distance maximale de câble, en cases, entre un appareil et son onduleur |
| Portée verticale des câbles | `LinkVerticalRange` | 3 | 0–10 | Différence d'étage maximale pour les raccordements d'appareils et le couplage d'onduleurs ; 0 = même étage |
| Portée de la pompe à eau | `PumpRange` | 15 | 5–30 | Rayon autour d'une pompe à eau où ses robinets sont alimentés |
| Cases par fil électrique | `WirePerTiles` | 4 | 0–20 | Cases par fil électrique ; 0 = câblage gratuit |
| Dégâts d'orage | `StormDamage` | désactivé | — | Les orages et les vents très forts endommagent les panneaux et les éoliennes |
| Expérience d'électricité | `XPMultiplier` | 1 | 0–10 | Expérience donnée par les actions LiveWire |
| Niveaux requis | `SkillGates` | activé | — | Désactivé = aucun niveau d'Électricité requis |
| Fonctionnement sans joueur | `SimulateUnloaded` | activé | — | La production, la consommation et l'usure continuent quand aucun joueur n'est à proximité |
| Recharge sur le réseau public | `GridCharging` | activé | — | Tant que le réseau public fonctionne, un onduleur à l'intérieur d'un bâtiment s'alimente lui-même et charge ses batteries à partir du réseau, jusqu'au cinquième de sa puissance nominale |
| Démarrage du secours (pourcentage) | `BackupStartPercent` | 20 | 0–90 | Un générateur de secours démarre quand les batteries descendent sous ce pourcentage |
| Arrêt du secours (pourcentage) | `BackupStopPercent` | 90 | 10–100 | Le générateur de secours s'arrête quand les batteries atteignent ce pourcentage ; le seuil d'arrêt est toujours d'au moins 5 points au-dessus du seuil de démarrage |
| Orientation solaire | `SolarOrientation` | activé | — | L'orientation influence le rendement : sud 100 %, est/ouest 85 %, nord 55 % |
| Encrassement des panneaux | `SolarDirt` | activé | — | La poussière réduit la production solaire ; la pluie et le nettoyage l'enlèvent |
| Batteries et froid | `BatteryCold` | désactivé | — | Les banques extérieures perdent temporairement de la capacité utilisable par temps froid ; l'énergie est conservée |
| Risque sous tension | `LiveWorkRisk` | activé | — | Risque de choc pendant l'entretien sous tension, de 50 % à Électricité 0 à 0 % à Électricité 6 ; coupez l'onduleur maître |

## Page LiveWire Extended

| Nom dans le jeu | Option | Défaut | Plage | Effet |
|---|---|---|---|---|
| Bande extérieure autour d'un bâtiment | `LiveWireExtended.BuildingBand` | 0 | 0–8 | Largeur en cases de la bande extérieure autour d'un bâtiment raccordé, qui reçoit aussi le courant (perron, allée de jardin). Le jeu alimente des blocs entiers de 8 x 8 cases : la zone alimentée est arrondie à ces blocs |
| Bâtiments avec un tableau électrique (%) | `LiveWireExtended.HouseBoardPercent` | 30 | 0–100 | Part des bâtiments de la carte qui ont déjà un tableau électrique (leur propre boîte électrique quand ils en ont une). Une fois raccordé à un onduleur, il est câblé pièce par pièce, sans étiquettes ; les appareils non raccordés du bâtiment n'ont alors pas de courant |

## Option du joueur

Dans **Options > Mods > LiveWire** : **Volume du bourdonnement de l'onduleur (0-100)**, 100 par défaut (0 = coupé). Elle est propre à chaque joueur et n'agit que sur ce qu'il entend.

## Risque sous tension

Le risque sous tension vaut 50 % à Électricité 0 et tombe à zéro à Électricité 6. Coupez l'onduleur maître : le disjoncteur principal ne suffit pas. Voir [règles de sécurité et d'XP](10-competence-electricite-et-entretien.md#sécurité-électrique-et-expérience).

## Voir aussi

[Production et calculs](04-production-et-calculs.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) · [Raccordement](03-raccordement.md) · [Multijoueur](12-multijoueur.md) · [LiveWire Extended](14-livewire-extended.md)
