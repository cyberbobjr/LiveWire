> English version: [Sandbox Options](../en/11-sandbox-options.md)

# Options sandbox

Les réglages du jeu et du serveur sont sur deux pages des options sandbox : **LiveWire** pour le mod de base, et **LiveWire Extended** pour l'extension optionnelle (seulement quand l'extension est activée).

## Page LiveWire

| Option | Défaut | Plage | Effet |
|---|---|---|---|
| EquipmentLootMultiplier (Fréquence des équipements et pièces) | 5 | 1–20 | Poids de butin des équipements et pièces LiveWire (appareils, kits, cellules photovoltaïques, pales, mâts) et des équipements LiveWire Extended ; redémarrage requis, prochains tirages seulement |
| `ConsumptionProfile` | Valeurs du jeu | Ultra-réaliste 1993, Réaliste 1993, Valeurs du jeu, Confort | Puissance absorbée par les appareils allumés ; voir le tableau de [Production et calculs](04-production-et-calculs.md#consommation-des-appareils) |
| `PowerScale` | 1,0 | 0,1–10 | Multiplie la consommation donnée par le profil (1 = aucun changement) |
| `SolarMultiplier` / `WindMultiplier` / `HydroMultiplier` | 1,0 | 0–10 | Production par famille de source |
| `BatteryCapacityMultiplier` | 1,0 | 0,1–10 | Capacité des batteries |
| `BatteryWearMultiplier` / `DeviceWearMultiplier` | 1,0 | 0–10 | Usure ; 0 = aucune |
| `InverterNoiseRadius` | 2 | 0–10 | Rayon du bourdonnement entendu par les zombies ; 0 = silencieux |
| `LinkRange` | 12 | 4–30 | Distance maximale de câble |
| `LinkVerticalRange` | 3 | 0–10 | Différence d'étage maximale pour les raccordements d'appareils et le couplage d'onduleurs ; 0 = même étage |
| `PumpRange` | 15 | 5–30 | Rayon autour d'une pompe à eau où ses robinets sont alimentés |
| `WirePerTiles` | 4 | 0–20 | Cases par fil électrique ; 0 = câblage gratuit |
| `SolarOrientation` | vrai | — | L'orientation influence le rendement : sud 100 %, est/ouest 85 %, nord 55 % |
| `SolarDirt` | vrai | — | La poussière réduit la production solaire ; la pluie et le nettoyage l'enlèvent |
| `BatteryCold` | faux | — | Les banques extérieures perdent temporairement de la capacité utilisable par temps froid ; l'énergie est conservée |
| `LiveWorkRisk` | vrai | — | Risque de choc pendant l'entretien sous tension, de 50 % à Électricité 0 à 0 % à Électricité 6 ; coupez l'onduleur maître |
| `StormDamage` | faux | — | Les orages et les vents très forts endommagent les panneaux et les éoliennes |
| `XPMultiplier` | 1,0 | 0–10 | Expérience donnée par le mod |
| `SkillGates` | vrai | — | Faux = aucun niveau d'Électricité requis |
| `SimulateUnloaded` | vrai | — | La production, la consommation et l'usure continuent quand aucun joueur n'est à proximité |
| `GridCharging` (Recharge sur le réseau public) | vrai | — | Tant que le réseau public fonctionne, un onduleur à l'intérieur d'un bâtiment s'alimente lui-même et charge ses batteries à partir du réseau, jusqu'au cinquième de sa puissance nominale |
| `BackupStartPercent` | 20 | 0–90 | Un générateur de secours démarre quand les batteries descendent sous ce pourcentage |
| `BackupStopPercent` | 90 | 10–100 | Le générateur de secours s'arrête quand les batteries atteignent ce pourcentage ; le seuil d'arrêt est toujours d'au moins 5 points au-dessus du seuil de démarrage |

## Page LiveWire Extended

| Option | Défaut | Plage | Effet |
|---|---|---|---|
| `LiveWireExtended.BuildingBand` (Bande extérieure autour d'un bâtiment) | 0 | 0–8 | Largeur en cases de la bande extérieure autour d'un bâtiment raccordé, qui reçoit aussi le courant (perron, allée de jardin). Le jeu alimente des blocs entiers de 8 x 8 cases : la zone alimentée est arrondie à ces blocs |
| `LiveWireExtended.HouseBoardPercent` (Bâtiments avec un tableau électrique (%)) | 30 | 0–100 | Part des bâtiments de la carte qui ont déjà un tableau électrique (leur propre boîte électrique quand ils en ont une). Une fois raccordé à un onduleur, il est câblé pièce par pièce, sans étiquettes ; les appareils non raccordés du bâtiment n'ont alors pas de courant |

## Option du joueur

Dans **Options > Mods > LiveWire** : volume du bourdonnement de l'onduleur, de 0 à 100, 100 par défaut (0 = coupé). Elle est propre à chaque joueur et n'agit que sur ce qu'il entend.

## Risque sous tension

Le risque sous tension vaut 50 % à Électricité 0 et tombe à zéro à Électricité 6. Coupez l'onduleur maître : le disjoncteur principal ne suffit pas. Voir [règles de sécurité et d'XP](10-competence-electricite-et-entretien.md#sécurité-électrique-et-expérience).

## Voir aussi

[Production et calculs](04-production-et-calculs.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) · [Raccordement](03-raccordement.md) · [Multijoueur](12-multijoueur.md) · [LiveWire Extended](14-livewire-extended.md)
