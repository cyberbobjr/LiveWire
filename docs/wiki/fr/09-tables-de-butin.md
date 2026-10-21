> English version: [Loot tables](../en/09-loot-tables.md)

# Tables de butin

## Lire les poids et les tirages

Project Zomboid teste chaque objet indépendamment à chaque tirage d'une liste de conteneur. Un poids W donne environ W % par tirage à rareté normale du butin (avant les réglages sandbox de butin et la densité de zombies). La colonne « Tirages » est le nombre de tirages de cette liste vanilla.

Chance approximative par conteneur ≈ 1 − (1 − W/100)^Tirages. Pour les meubles posables comme le panneau, le jeu applique le modificateur de butin « Other » (0,6 à rareté normale).

## Cellule photovoltaïque (`LiveWire.SolarCell`, toujours)

| Liste vanilla | Où | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| GarageTools | Rangement d'outils de garage | 2 | 4 | 7,8 % |
| CrateTools | Caisses d'outils | 1 | 4 | 3,9 % |
| GarageMetalwork | Rangement de métallerie de garage | 1 | 4 | 3,9 % |
| MechanicShelfElectric | Garage mécanique, étagère électrique | 2 | 4 | 7,8 % |
| ElectricianTools | Outils d'électricien | 3 | 3 | 8,7 % |
| MetalShopTools | Outils de métallerie | 1 | 4 | 3,9 % |
| WireFactoryElectric | Fabrique de fils, électrique | 2 | 4 | 7,8 % |
| ToolStoreMisc | Quincaillerie, divers | 2 | 4 | 7,8 % |

## Panneau photovoltaïque tout fait (`Base.Mov_LiveWire_SolarPanel`, toujours ; meuble, × 0,6 à rareté normale)

| Liste vanilla | Où | Poids | Tirages | Chance ≈ par conteneur |
|---|---|---|---|---|
| GarageTools | Rangement d'outils de garage | 0,3 | 4 | 0,7 % |
| CrateTools | Caisses d'outils | 0,3 | 4 | 0,7 % |
| GarageMetalwork | Rangement de métallerie de garage | 0,2 | 4 | 0,5 % |
| ToolStoreMisc | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
| ToolStoreTools | Quincaillerie, outils | 0,3 | 4 | 0,7 % |

## Équipements Live Wire tout faits

Trouvés déjà fabriqués, en plus des recettes (les réglages de butin sandbox s'appliquent).

| Équipement | Liste vanilla | Où | Poids | Tirages | ≈ chance par conteneur |
|---|---|---|---|---|---|
| <img src="../../images/icons/VoltageTester.png" width="24" height="24"> **Testeur de tension** | `ElectricianTools` | Outils d'électricien | 3 | 3 | 8,7 % |
|  | `ToolStoreTools` | Quincaillerie, outils | 1 | 4 | 3,9 % |
|  | `GarageTools` | Rangement d'outils de garage | 1 | 4 | 3,9 % |
|  | `CrateTools` | Caisses d'outils | 1 | 4 | 3,9 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 3,9 % |
| <img src="../../images/icons/DeepCycleBattery.png" width="24" height="24"> **Batterie stationnaire** | `CarSupplyBatteries` | Magasin de pièces auto, batteries | 2 | 4 | 7,8 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 1 | 4 | 3,9 % |
|  | `GarageMechanics` | Garage, rangement mécanique | 0,3 | 4 | 1,2 % |
| <img src="../../images/icons/Inverter.png" width="24" height="24"> **Onduleur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 0,5 | 3 | 0,9 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 0,5 | 4 | 1,2 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,2 | 4 | 0,5 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,1 | 4 | 0,2 % |
| <img src="../../images/icons/Breaker.png" width="24" height="24"> **Disjoncteur** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 1 | 3 | 1,8 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 2,4 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,3 | 4 | 0,7 % |
|  | `CrateTools` | Caisses d'outils | 0,3 | 4 | 0,7 % |
| <img src="../../images/icons/PowerBank.png" width="24" height="24"> **Powerbank** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 0,5 | 3 | 0,9 % |
|  | `MechanicShelfElectric` | Garage automobile, étagère électrique | 0,5 | 4 | 1,2 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,3 | 4 | 0,7 % |
|  | `GarageTools` | Rangement d'outils de garage | 0,2 | 4 | 0,5 % |
| <img src="../../images/icons/BatteryAlarm.png" width="24" height="24"> **Alarme de batterie faible** (meuble : × 0,6 inclus) | `ElectricianTools` | Outils d'électricien | 1 | 3 | 1,8 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 1 | 4 | 2,4 % |
|  | `ToolStoreMisc` | Quincaillerie, divers | 0,5 | 4 | 1,2 % |
| <img src="../../images/icons/WindTurbine.png" width="24" height="24"> **Éolienne** (meuble : × 0,6 inclus) | `ToolStoreMisc` | Quincaillerie, divers | 0,1 | 4 | 0,2 % |
|  | `WireFactoryElectric` | Usine de câbles, rayon électrique | 0,1 | 4 | 0,2 % |

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
