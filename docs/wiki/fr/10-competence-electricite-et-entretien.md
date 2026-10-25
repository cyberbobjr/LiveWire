> English version: [Electrical skill and maintenance](../en/10-electrical-skill-and-maintenance.md)

# Entretien et compétence

## Usure

| Appareil | Usure normale | Accélérateurs |
|---|---|---|
| Panneau photovoltaïque | −1 tous les 10 jours | Orage, seulement avec l'option StormDamage (désactivée par défaut) |
| Éolienne | −1 tous les 4 jours | Vent > 85 km/h avec StormDamage |
| Roue à aubes | −1 tous les 6 jours | aucun |
| Onduleur | −1 tous les 5 jours en marche | Charge > 80 % : usure × 2 ; chaque disjonction sans disjoncteur : −3 ; insonorisé : × 1,25 |
| Disjoncteur | −1 tous les 15 jours | aucun |
| Powerbank, alarme | −1 tous les 30 jours | aucun |
| Batterie | 100 / durée de vie en cycles par cycle complet | Décharge sous 20 % : usure doublée ; autodécharge 0,2 % par jour |

## Réparation, remise à neuf, reconditionnement

| Action | Niveau | Coût | Effet |
|---|---|---|---|
| Réparer (Repair) | selon l'appareil | 1 déchets électroniques + 1 fil électrique | Gain de 5 + niveau d'Électricité en points d'état (jusqu'à 90). Échec : max(5, 40 − 5 × niveau) %, divisé par deux dès le niveau 8 ; pièces perdues en cas d'échec |
| Remise à neuf (Overhaul) | 8 | 4 déchets électroniques + 2 fils électriques | Retour à 100 |
| Reconditionner une batterie | 4, ou 6 si morte | Tournevis conservé, 1 déchet électronique + 1 fil + 0,5 L d'eau | +15 d'état, plafond 80, quatre réparations au maximum ; cycles et énergie conservés, une batterie morte revient vide |

## Testeur de tension

`LiveWire.VoltageTester` : clic droit sur une case, « Live Wire », « Mesurer ».

| Niveau | Lecture |
|---|---|
| 0 | Alimenté ou non |
| 1 | Origine du courant |
| 2 | Consommation de l'appareil |
| 4 | Bilan du réseau |

## Compétence Électricité

| Niveau | Débloque | Effet continu |
|---|---|---|
| 0 | Lire un testeur : alimenté ou non | aucun |
| 1 | Testeur de tension | Lecture détaillée de la case |
| 2 | Powerbank, alarme de batterie faible, kit d'insonorisation | Usure des batteries −5 % |
| 3 | Panneaux photovoltaïques, disjoncteur, générateur de secours | Rendement de pose 0,85 |
| 4 | Reconditionner une batterie | Lecture de l'autonomie |
| 5 | Onduleur | aucun |
| 6 | Assemblage de l’éolienne, batterie stationnaire, ordinateur de gestion | Usure des batteries −10 % |
| 7 | Fabrication de la roue à aubes, délestage | Rendement de pose 0,95 |
| 8 | Cellules à partir de déchets, remise à neuf | Échec de réparation divisé par deux |
| 9-10 | aucun | Rendement de pose 1,0 ; usure des appareils −25 % |

## Expérience

Toujours attribuée par le serveur.

| Action | Expérience |
|---|---|
| Recettes du mod | voir [Recettes](08-recettes.md) |
| Poser une source | 10 (panneau), 20 (éolienne, roue à aubes) |
| Poser un onduleur | 25 |
| Connecter une source ou une batterie | 3 |
| Inspecter un appareil | 2 (une fois par appareil et par jour) |
| Mesurer au testeur | 1 (une fois par case et par heure) |
| Réparer | 5 + 1 par point, maximum 15 |
| Reconditionner une batterie | 8 |
| Réarmer après avoir réglé une surcharge | 5 (une fois par heure) |
| Insonoriser l'onduleur | 3 |

L'option XPMultiplier ajuste l'expérience donnée, et SkillGates = false supprime les niveaux requis ([Options sandbox](11-options-sandbox.md)).

## Test des batteries et entretien

Avec une batterie dans votre inventaire et le testeur, le niveau 1 révèle la
charge ; le niveau 3 ajoute énergie, capacité et état ; le niveau 5 ajoute cycles,
durée de vie estimée et réparations. Charge, état et cycles restent distincts.

Le reconditionnement existant répare aussi une batterie morte : niveau 4 pour une
batterie usée, 6 si morte, tournevis, un déchet électronique, un fil électrique et
0,5 L d'eau. Gain de 15 points d'état, plafond 80, quatre réparations au maximum.
La même batterie conserve ses cycles et son énergie ; une batterie morte reste
vide après réparation. La précision inférieure à une graduation native est
conservée dans ses données ; une modification native de charge invalide ce reliquat.

L'option de froid réduit la capacité accessible des banques extérieures : 20 % à
0 °C, 40 % à −15 °C. L'énergie immobilisée redevient accessible au dégel. Le froid
est désactivé par défaut. Le risque électrique est activé par défaut ; règles détaillées ci-dessous.

Un équipement mort et vide peut être démonté au niveau 3 avec un tournevis. Il est
retiré une seule fois et rend quelques pièces ; les batteries doivent être retirées
de la banque avant ce démontage.

Éoliennes et roues à aubes : pose/ramassage au niveau 2 ; fabrication aux niveaux 6 et 7 respectivement. Les pales et le mât se fabriquent sans niveau électrique.

## Sécurité électrique et expérience

L'option **Risque sous tension** est activée par défaut. Lorsqu'elle est active,
raccorder, débrancher, réparer ou démonter pour pièces un équipement raccordé
peut provoquer une décharge. Un seul tirage est effectué à la fin de chaque
intervention autorisée, avant consommation des matériaux.

| Niveau réel d'Électricité | Risque par intervention |
|---|---:|
| 0 | 50 % |
| 1 | 42 % |
| 2 | 33 % |
| 3 | 25 % |
| 4 | 17 % |
| 5 | 8 % |
| 6 à 10 | 0 % |

**Éteignez l'onduleur maître avant d'intervenir.** Couper le principal ou les deux
circuits au tableau n'isole pas les bornes de l'onduleur. Une panne, une protection
déclenchée ou des batteries vides ne remplacent pas l'arrêt explicite de l'onduleur.
L'arrêt reste disponible sur un onduleur en panne ; il ne le répare pas et ne lui
permet pas de charger les batteries tant que son état reste nul.

La brûlure et la douleur touchent la **main tenant le tournevis** : droite en
main principale, gauche en secondaire ; si l'outil est dans l'inventaire,
l'animation l'utilise en main principale. Les objets tenus sont lâchés et l'action
est interrompue avant dépense des matériaux. Un tournevis en état est aussi requis
pour débrancher. Gants et météo ne modifient pas ce calcul.

Ouvrir un écran, actionner les leviers, nettoyer/déneiger, changer les batteries,
poser/déplacer ou coupler des onduleurs ne déclenche pas ce contrôle de décharge.
La réparation d'un onduleur encore en marche est refusée avant intervention.
Les règles de distance, de compétence requise et de refuge restent applicables.

**Chaque réparation réussie d'un équipement LiveWire donne de l'XP d'Électricité** :
5 XP plus un par point d'état restauré, au maximum 15 ; la remise à neuf utilise
le même calcul. Le reconditionnement d'une batterie donne 8 XP.
**Toutes les recettes LiveWire donnent de l'XP d'Électricité**, y compris fabrication
et démontage du testeur. Pales et mât donnent chacun 2 XP, sans niveau électrique
requis ; l'assemblage final de l'éolienne conserve ses 30 XP.
Une action refusée ou interrompue par un choc ne donne pas d'XP de réparation.


## Tester l'usure en debug

En solo `-debug`, ou en administrateur MP : clic droit sur l'appareil → Live Wire
→ son nom → **Debug : cet équipement**. Retirez 10 points d'état, fixez 50 % ou
10 %, mettez hors service (0 %) ou restaurez à 100 %. Fonctionne même sans câble.
Cela concerne l'équipement sélectionné, pas directement les batteries à l'intérieur,
et ne donne pas d'XP. Un onduleur cassé restauré reste éteint.

Une partie qui avait déjà enregistré le risque électrique sur « désactivé » garde
ce choix : activez **Risque sous tension** dans ses options sandbox si nécessaire.

## Voir aussi

[Équipements](02-equipements.md) · [Recettes](08-recettes.md) · [Production et calculs](04-production-et-calculs.md)
