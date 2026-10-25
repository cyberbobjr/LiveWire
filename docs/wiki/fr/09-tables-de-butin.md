> English version: [Loot tables](../en/09-loot-tables.md)

# Tables de butin

## Lire les poids et les tirages

Project Zomboid teste chaque objet indépendamment à chaque tirage d'une liste de conteneur. Un poids W donne environ W % par tirage à rareté normale du butin (avant les réglages sandbox de butin et la densité de zombies). La colonne « Tirages » est le nombre de tirages de cette liste vanilla.

Chance approximative par conteneur ≈ 1 − (1 − W/100)^Tirages. Pour les meubles posables comme le panneau, le jeu applique le modificateur de butin « Other » (0,6 à rareté normale).

## Cellule photovoltaïque (`LiveWire.SolarCell`, toujours)

Poids à ×5 ; estimations si cette liste est sélectionnée, avec un modificateur vanilla de 0,6. Les réglages réels, la densité de zombies, le temps et la place disponible peuvent changer le résultat.

| Liste vanilla | Où | Poids (×5) | Tirages | ≈ chance par conteneur |
|---|---|---|---|---|
| `GarageTools` | Rangement d'outils de garage | 10 | 4 | 21,9 % |
| `CrateTools` | Caisses d'outils | 5 | 4 | 11,5 % |
| `GarageMetalwork` | Rangement de métallerie de garage | 5 | 4 | 11,5 % |
| `MechanicShelfElectric` | Garage automobile, étagère électrique | 10 | 4 | 21,9 % |
| `ElectricianTools` | Outils d'électricien | 15 | 3 | 24,6 % |
| `MetalShopTools` | Outils de métallerie | 5 | 4 | 11,5 % |
| `WireFactoryElectric` | Usine de câbles, rayon électrique | 10 | 4 | 21,9 % |
| `ToolStoreMisc` | Quincaillerie, divers | 10 | 4 | 21,9 % |
| `CrateElectronics` | Caisses d'électronique | 10 | 4 | 21,9 % |
| `ElectronicStoreMisc` | Magasin d'électronique, divers | 10 | 4 | 21,9 % |
| `ToolStoreMetalwork` | Quincaillerie, métallerie | 5 | 4 | 11,5 % |
| `CrateMetalwork` | Caisses de métallerie | 5 | 4 | 11,5 % |

## Équipements Live Wire tout faits

Équipements tout faits, avec EquipmentLootMultiplier = 5 par défaut (plage 1–20). Estimations si cette liste est sélectionnée, avec un modificateur vanilla de 0,6, sans effet de densité de zombies ni du temps et avec assez de place ; ce ne sont pas des taux de découverte garantis.

Fouillez les quincailleries, garages et ateliers automobiles, magasins d'électronique, usines électriques et caisses d'entrepôt. Les batteries stationnaires peuvent aussi apparaître parmi le matériel de camping. Les objets disponibles dépendent de la catégorie de rangement : aucun lieu précis ne garantit une découverte. Les roues à aubes se trouvent aussi dans les rangements agricoles, de menuiserie et techniques ; les pompes restent à fabriquer.

Réglez **Fréquence des équipements et pièces LiveWire** dans la page sandbox **LiveWire** : **5 par défaut**, de **1 à 20**. Redémarrez le jeu ou le serveur dédié après modification. Les anciennes parties sans cette option utilisent 5. Seuls les prochains tirages sont concernés, y compris la réapparition vanilla du butin si elle est activée ; aucun remplissage des conteneurs déjà fouillés. Les cellules photovoltaïques sont incluses. Objets et poids vanilla inchangés ; les CD gardent leur taux actuel. À 1, les anciens poids sont rétablis dans les catégories existantes, tout en conservant les nouveaux lieux.

| Équipement | Liste vanilla | Où | Poids (×5) | Tirages | ≈ chance par conteneur |
|---|---|---|---|---|---|
| <img src="../../images/icons/SolarPanel.png" width="24" height="24"> **Panneau photovoltaïque** (meuble : × 0,6 inclus) | `ToolStoreMisc` | Quincaillerie, divers | 2,5 | 4 | 5,9 % |
|  | `CrateElectronics` | Caisses d'électronique | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2,5 | 4 | 5,9 % |
|  | `GarageTools` | Rangement d'outils de garage | 1,5 | 4 | 3,6 % |
|  | `CrateTools` | Caisses d'outils | 1,5 | 4 | 3,6 % |
|  | `ToolStoreTools` | Quincaillerie, outils | 1,5 | 4 | 3,6 % |
|  | `CrateMetalwork` | Caisses de métallerie | 1,5 | 4 | 3,6 % |
|  | `ToolStoreMetalwork` | Quincaillerie, métallerie | 1,5 | 4 | 3,6 % |
|  | `GarageMetalwork` | Rangement de métallerie de garage | 1 | 4 | 2,4 % |
| <img src="../../images/icons/VoltageTester.png" width="24" height="24"> **Testeur de tension** | `ElectricianTools` | Outils d'électricien | 15 | 3 | 24,6 % |
|  | `ToolStoreTools` | Quincaillerie, outils | 5 | 4 | 11,5 % |
|  | `GarageTools` | Rangement d'outils de garage | 5 | 4 | 11,5 % |
|  | `CrateTools` | Caisses d'outils | 5 | 4 | 11,5 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 5 | 4 | 11,5 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 5 | 4 | 11,5 % |
|  | `CrateElectronics` | Caisses d'électronique | 5 | 4 | 11,5 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 5 | 4 | 11,5 % |
|  | `MechanicShelfTools` | Garage automobile, outils | 5 | 4 | 11,5 % |
| <img src="../../images/icons/DeepCycleBattery.png" width="24" height="24"> **Batterie stationnaire** | `CarSupplyBatteries` | Magasin de pièces auto, batteries | 10 | 4 | 21,9 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 5 | 4 | 11,5 % |
|  | `CrateMechanics` | Caisses de mécanique | 3,5 | 4 | 8,1 % |
|  | `CrateElectronics` | Caisses d'électronique | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2,5 | 4 | 5,9 % |
|  | `GarageMechanics` | Garage, rangement mécanique | 1,5 | 4 | 3,6 % |
|  | `CampingStoreGear` | Magasin de camping, matériel | 1,5 | 4 | 3,6 % |
| <img src="../../images/icons/Inverter.png" width="24" height="24"> **Onduleur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 2,5 | 3 | 4,4 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 2,5 | 4 | 5,9 % |
|  | `CrateElectronics` | Caisses d'électronique | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreAppliances` | Magasin d'électronique, appareils | 1,5 | 1 | 0,9 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 1,5 | 4 | 3,6 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 1 | 4 | 2,4 % |
|  | `CrateTools` | Caisses d'outils | 1 | 4 | 2,4 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,5 | 4 | 1,2 % |
| <img src="../../images/icons/Breaker.png" width="24" height="24"> **Disjoncteur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 5 | 3 | 8,7 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 5 | 4 | 11,5 % |
|  | `CrateElectronics` | Caisses d'électronique | 3,5 | 4 | 8,1 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2,5 | 4 | 5,9 % |
|  | `ToolStoreTools` | Quincaillerie, outils | 2,5 | 4 | 5,9 % |
|  | `GarageTools` | Rangement d'outils de garage | 1,5 | 4 | 3,6 % |
|  | `CrateTools` | Caisses d'outils | 1,5 | 4 | 3,6 % |
|  | `CrateMetalwork` | Caisses de métallerie | 1,5 | 4 | 3,6 % |
| <img src="../../images/icons/PowerBank.png" width="24" height="24"> **Powerbank** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 2,5 | 3 | 4,4 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 2,5 | 4 | 5,9 % |
|  | `CrateElectronics` | Caisses d'électronique | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2 | 4 | 4,7 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 1,5 | 4 | 3,6 % |
|  | `CrateMechanics` | Caisses de mécanique | 1,5 | 4 | 3,6 % |
|  | `GarageTools` | Rangement d'outils de garage | 1 | 4 | 2,4 % |
|  | `GarageMechanics` | Garage, rangement mécanique | 1 | 4 | 2,4 % |
|  | `CrateTools` | Caisses d'outils | 1 | 4 | 2,4 % |
| <img src="../../images/icons/BatteryAlarm.png" width="24" height="24"> **Alarme de batterie faible** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 5 | 3 | 8,7 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 5 | 4 | 11,5 % |
|  | `CrateElectronics` | Caisses d'électronique | 3,5 | 4 | 8,1 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 2,5 | 4 | 5,9 % |
|  | `ElectronicStoreMisc` | Magasin d'électronique, divers | 2,5 | 4 | 5,9 % |
|  | `CrateTools` | Caisses d'outils | 1,5 | 4 | 3,6 % |
|  | `GarageTools` | Rangement d'outils de garage | 1,5 | 4 | 3,6 % |
| <img src="../../images/icons/WindTurbine.png" width="24" height="24"> **Éolienne** (meuble : × 0,6 inclus) | `WireFactoryElectric` | Usine de câbles, rayon électrique | 2,5 | 4 | 5,9 % |
|  | `ToolStoreMetalwork` | Quincaillerie, métallerie | 2,5 | 4 | 5,9 % |
|  | `WireFactoryTools` | Usine de câbles, outils | 2,5 | 4 | 5,9 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 1,5 | 4 | 3,6 % |
|  | `CrateElectronics` | Caisses d'électronique | 1,5 | 4 | 3,6 % |
|  | `CrateMetalwork` | Caisses de métallerie | 1,5 | 4 | 3,6 % |
|  | `CrateTools` | Caisses d'outils | 1,5 | 4 | 3,6 % |
|  | `CrateFarming` | Caisses de matériel agricole | 1,5 | 4 | 3,6 % |
|  | `ToolStoreFarming` | Quincaillerie ou magasin extérieur, agriculture | 1,5 | 4 | 3,6 % |
|  | `MechanicShelfTools` | Garage automobile, outils | 1,5 | 4 | 3,6 % |
| <img src="../../images/icons/WaterWheel.png" width="24" height="24"> **Roue à aubes** (meuble : × 0,6 inclus) | `CrateCarpentry` | Caisses de menuiserie | 2,5 | 4 | 5,9 % |
|  | `ToolStoreCarpentry` | Quincaillerie, menuiserie | 2,5 | 4 | 5,9 % |
|  | `CrateFarming` | Caisses de matériel agricole | 2,5 | 4 | 5,9 % |
|  | `ToolStoreFarming` | Quincaillerie ou magasin extérieur, agriculture | 1,5 | 4 | 3,6 % |
|  | `CrateTools` | Caisses d'outils | 1,5 | 4 | 3,6 % |
|  | `CrateMechanics` | Caisses de mécanique | 1,5 | 4 | 3,6 % |
|  | `CrateMetalwork` | Caisses de métallerie | 1,5 | 4 | 3,6 % |
| <img src="../../images/icons/WindTurbineBlades.png" width="24" height="24"> **Jeu de pales d’éolienne** | `CrateMetalwork` | Caisses de métallerie | 5 | 4 | 11,5 % |
|  | `ToolStoreMetalwork` | Quincaillerie, métallerie | 5 | 4 | 11,5 % |
|  | `CrateTools` | Caisses d'outils | 3,5 | 4 | 8,1 % |
|  | `CrateFarming` | Caisses de matériel agricole | 3,5 | 4 | 8,1 % |
|  | `ToolStoreFarming` | Quincaillerie ou magasin extérieur, agriculture | 3,5 | 4 | 8,1 % |
|  | `WireFactoryTools` | Usine de câbles, outils | 3,5 | 4 | 8,1 % |
| <img src="../../images/icons/WindTurbineMast.png" width="24" height="24"> **Mât d’éolienne** | `CrateMetalwork` | Caisses de métallerie | 5 | 4 | 11,5 % |
|  | `ToolStoreMetalwork` | Quincaillerie, métallerie | 5 | 4 | 11,5 % |
|  | `CrateTools` | Caisses d'outils | 3,5 | 4 | 8,1 % |
|  | `CrateMechanics` | Caisses de mécanique | 3,5 | 4 | 8,1 % |
|  | `CrateFarming` | Caisses de matériel agricole | 3,5 | 4 | 8,1 % |
|  | `ToolStoreFarming` | Quincaillerie ou magasin extérieur, agriculture | 3,5 | 4 | 8,1 % |

## Pièces du mod

Cellules photovoltaïques, jeux de pales et mâts sont des pièces LiveWire
et utilisent le même multiplicateur. Seuls les objets définis par LiveWire figurent dans ces
ajouts de butin et tableaux. Les ingrédients vanilla (fils, déchets électroniques,
amplificateurs, haut-parleurs, ampoules, piles et matériaux) gardent leurs tables
et poids existants. Cette option n'ajoute, ne retire ni ne repondère aucun objet vanilla.

## Disque du logiciel de gestion (`LiveWire.MonitorDisk`, seulement avec le Computer Mod actif)

| Liste vanilla | Où | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| ElectronicStoreComputers | Magasin d'électronique, ordinateurs | 2 | 1 | 2,0 % |
| CrateComputer | Caisses d'ordinateurs | 2 | 4 | 7,8 % |
| BookstoreComputer | Librairie, rayon informatique | 1 | 4 | 3,9 % |
| UniversityDesk_Computer | Bureau d'université, informatique | 1 | 4 | 3,9 % |
| UniversityDesk_Electrical | Bureau d'université, électricité | 2 | 4 | 7,8 % |
| OfficeDesk | Bureaux | 0,3 | 4 | 1,2 % |

## Autres moyens d'obtenir des cellules

- Une cellule photovoltaïque par calculatrice démontée (aucun niveau requis).
- Au niveau 8 d'Électricité : une cellule à partir de 5 déchets électroniques et 1 aluminium.

## Voir aussi

[Recettes](08-recettes.md) · [Écran et logiciel](05-ecran-et-logiciel.md) · [Multijoueur](12-multijoueur.md)
