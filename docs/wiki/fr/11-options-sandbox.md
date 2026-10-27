> English version: [Sandbox options](../en/11-sandbox-options.md)

# Options sandbox

Page « LiveWire » des options sandbox.

| Option | Défaut | Plage | Effet |
|---|---|---|---|
| EquipmentLootMultiplier | 5 | 1–20 | Poids du butin des équipements et cellules LiveWire uniquement ; redémarrage requis, prochains tirages uniquement |
| ConsumptionProfile | Valeurs du jeu | Ultra-réaliste 1993, Réaliste 1993, Valeurs du jeu, Confort | Puissance consommée par les appareils allumés ; voir le tableau de [Production et calculs](04-production-et-calculs.md#consommation-des-appareils) |
| PowerScale | 1,0 | 0,1 à 10 | Multiplie la consommation donnée par le profil (1 = aucun changement) |
| SolarMultiplier / WindMultiplier / HydroMultiplier | 1,0 | 0 à 10 | Production par famille de sources |
| BatteryCapacityMultiplier | 1,0 | 0,1 à 10 | Capacité des batteries |
| BatteryWearMultiplier / DeviceWearMultiplier | 1,0 | 0 à 10 | Usure ; 0 = aucune |
| InverterNoiseRadius | 2 | 0 à 10 | Rayon du bourdonnement entendu par les zombies ; 0 = silencieux |
| LinkRange | 12 | 4 à 30 | Distance de câble maximale |
| LinkVerticalRange | 3 | 0 à 10 | Écart maximal en étages pour les raccordements et couplages ; 0 = même étage |
| PumpRange | 15 | 5 à 30 | Rayon autour d'une pompe à eau dans lequel ses points d'eau sont alimentés |
| WirePerTiles | 4 | 0 à 20 | Cases par fil électrique ; 0 = câblage gratuit |
| StormDamage | faux | | Dégâts d'orage et de vent fort |
| XPMultiplier | 1,0 | 0 à 10 | Expérience donnée par le mod |
| SkillGates | vrai | | Faux = aucun niveau requis |
| SimulateUnloaded | vrai | | Continue de simuler sans personne à proximité |
| BackupStartPercent / BackupStopPercent | 20 / 90 | 0 à 90 / 10 à 100 | Seuils du générateur de secours |

## Option joueur

Options, Mods, Live Wire : volume du bourdonnement de l'onduleur, de 0 à 100 (0 = coupé).

## Nouveaux réglages de la 1.6.0

Quatre booléens sont ajoutés : orientation solaire et encrassement activés par
défaut, comme le risque électrique ; effet du froid sur les batteries désactivé
par défaut. Les choix déjà sauvegardés restent prioritaires. Les prévisions utilisent les mêmes options que la simulation.

Risque sous tension : 50 % à Électricité 0, nul dès 6. Éteindre l'onduleur maître ; le principal du tableau ne suffit pas. Voir les [règles de sécurité et d’XP](10-competence-electricite-et-entretien.md#sécurité-électrique-et-expérience).

## Voir aussi

[Production et calculs](04-production-et-calculs.md) · [Raccordement](03-raccordement.md) · [Équipements optionnels](06-equipements-optionnels.md) · [Multijoueur](12-multijoueur.md)
