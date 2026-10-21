> English version: [Optional equipment](../en/06-optional-equipment.md)

# Équipements optionnels

Quatre équipements facultatifs renforcent un réseau. Chaque réseau en accepte au plus un de chaque. Pour les relier, voir [Raccordement](03-raccordement.md).

| Équipement | Effet | Niveau |
|---|---|---|
| Disjoncteur (mural) | Saute à la place de l'onduleur quand la demande de la maison dépasse 1 500 W : l'onduleur ne perd plus 3 points d'état. Lampe rouge quand il a sauté ; réarmement sur le disjoncteur lui-même (« Réarmer le disjoncteur »), refusé tant qu'il y a surcharge. | 3 |
| Alarme de batterie faible (murale) | Sous 20 % de stock : message aux joueurs à moins de 30 cases, bip toutes les 10 minutes de jeu jusqu'à « Couper la sonnerie » ; le gyrophare reste allumé jusqu'à ce que le stock repasse au-dessus de 25 %. | 2 |
| Générateur de secours (générateur vanilla) | Démarré par le mod sous 20 % de batterie, arrêté à 90 % (options sandbox). Fournit 1 200 W et brûle 1 L de carburant par 3 kWh (en plus de sa consommation vanilla). Toujours bruyant et toxique en intérieur ; à brancher et alimenter en carburant à la manière vanilla. Ne démarre jamais sans batterie. | 3 |
| Ordinateur de gestion (ordinateur de bureau vanilla) | Historique 48 h, prévision jusqu'au lever du jour. Délestage au niveau 7 : éteint les lumières sous 15 % pour garder le frigo, réarmé au-dessus de 30 %. | 6 |

Le générateur de secours et l'ordinateur ne se fabriquent pas : ce sont des objets vanilla trouvés dans le monde.

## Onduleurs en parallèle (couplage)

Dans une vraie installation autonome, on gagne de la puissance en ajoutant des onduleurs identiques en parallèle, pas en poussant un onduleur au-delà de sa capacité. Live Wire fait de même :

- Clic droit sur un onduleur > **Coupler à un onduleur** > un onduleur maître à portée de câble. L'onduleur cliqué devient **esclave**. Coût : le fil électrique de la distance et 1 **kit de couplage d'onduleurs** (recette au niveau 6 d'Électricité).
- L'esclave ne doit avoir aucun équipement raccordé ; un maître accepte au plus 3 esclaves (4 onduleurs).
- Un seul réseau, un seul parc de batteries, une seule zone alimentée (celle du maître). Capacité = 1 500 W × onduleurs en service ; chaque onduleur allumé consomme 20 W à vide et s'use comme d'habitude.
- Un esclave éteint ou cassé ne compte plus : si la demande dépasse alors ce qui reste, le disjoncteur (ou le maître) saute. Chaque esclave a son interrupteur ; on réarme sur le maître ou le disjoncteur.
- **Découpler** sur l'esclave le rend de nouveau indépendant (le kit est rendu). Un maître ramassé libère ses esclaves.
- La page État de l'écran LCD et le logiciel affichent « Couplés : n / total en service » et la capacité totale.
- Deux onduleurs indépendants dont les zones se recouvrent ne comptent plus deux fois les mêmes appareils : chaque appareil est compté par l'onduleur allumé le plus proche.

## Quand le disjoncteur saute-t-il ?

Quand la demande des appareils de la maison dépasse le maximum de l'onduleur, 1 500 W (les 20 W à vide ne comptent pas). La vérification a lieu à chaque pas de simulation : toutes les 10 minutes de jeu et juste après une action. Exemples : un lave-linge et un sèche-linge superposés qui tournent ensemble (1 800 W avec les valeurs du jeu) ; avec les profils de consommation 1993, une cuisinière électrique ou un sèche-linge seul.

Sans disjoncteur, c'est l'onduleur qui saute et perd 3 points d'état (réarmement sur l'onduleur).

## Voir aussi

[Équipements](02-equipements.md) · [Écran et logiciel](05-ecran-et-logiciel.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) · [Options sandbox](11-options-sandbox.md)
