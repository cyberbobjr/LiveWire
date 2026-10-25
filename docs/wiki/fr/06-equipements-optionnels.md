> English version: [Optional equipment](../en/06-optional-equipment.md)

# Équipements optionnels

Quatre équipements facultatifs renforcent un réseau. Chaque réseau en accepte au plus un de chaque. Pour les relier, voir [Raccordement](03-raccordement.md).

| Équipement | Effet | Niveau |
|---|---|---|
| Disjoncteur (mural) | Saute à la place de l'onduleur quand la demande de la maison dépasse 1 500 W : l'onduleur ne perd plus 3 points d'état. Lampe rouge quand il a sauté ; réarmement sur le disjoncteur lui-même (« Réarmer le disjoncteur »), refusé tant qu'il y a surcharge. | 3 |
| Alarme de batterie faible (murale) | Sous 20 % de stock : message aux joueurs à moins de 30 cases, bip toutes les 10 minutes de jeu jusqu'à « Couper la sonnerie » ; le gyrophare reste allumé jusqu'à ce que le stock repasse au-dessus de 25 %. | 2 |
| Générateur de secours (générateur vanilla) | Démarré par le mod sous 20 % de batterie, arrêté à 90 % (options sandbox). Fournit 1 200 W et brûle 1 L de carburant par 3 kWh (en plus de sa consommation vanilla). Toujours bruyant et toxique en intérieur ; à brancher et alimenter en carburant à la manière vanilla. Ne démarre jamais sans batterie. | 3 |
| Ordinateur de gestion (ordinateur de bureau vanilla) | Historique 48 h, prévisions météo sur trois jours, consommateurs et journal d'événements. Délestage au niveau 7 : éteint les lumières sous 15 % pour garder le frigo, réarmé au-dessus de 30 %. | 6 |

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

## Tableau électrique à deux circuits

Ouvrir le tableau sur un disjoncteur raccordé : coffret clair, wattmètre LCD,
modules à deux pôles liés par circuit et principal orange. Actionner le principal
pour couper ou rétablir la distribution, ou réarmer après correction d'une surcharge.
Production et charge des batteries continuent. Le circuit lumières éteint de vrais
interrupteurs secteur et rétablit les choix mémorisés. Lampes sur pile exclues ;
un interrupteur vanilla agit sur toute sa pièce.

Le LCD affiche **éclairage, équipements et total en watts**, à partir de la
dernière mesure du réseau. Les équipements incluent les pompes LiveWire. Ce sont
des puissances actuelles, sans compteur cumulatif en kWh ; pertes, charge des
batteries et veille de l'onduleur ne sont pas incluses. Un circuit coupé sans
charge affiche « 0 W / coupé ». Après retour dans une zone ou reconnexion,
« Actualisation… » et des tirets remplacent une mesure encore indisponible.
Le relevé revient après reconstruction et mesure, au rythme de la simulation.
Les réseaux couplés partagent le relevé du maître ; en recouvrement, toute charge
d'un autre tableau alimentée par ce réseau reste comptée dans ses watts.

Le second levier coupe les équipements : frigos et congélateurs ne refroidissent
plus ; TV, radios secteur, cuisinières, micro-ondes, lave-linge, sèche-linge,
combinés et chargeurs s'arrêtent. Les pompes à carburant ne distribuent plus ;
les pompes à eau cessent de remplir leurs relais (l'eau déjà stockée reste disponible). Les lumières
peuvent rester allumées. Les appareils déjà éteints restent éteints au retour du
courant ; les cycles des machines reprennent avec leur durée native. Les radios
et lampes sur piles restent autonomes.

Les deux leviers permettent de tout alimenter, garder seulement l'éclairage,
garder seulement les équipements ou tout couper. Le choix est sauvegardé. Après
une surcharge, corriger la demande puis réarmer le principal ; cela ne ferme pas
les circuits laissés volontairement ouverts. Le délestage automatique ne les
rallume pas non plus. Sources, batteries et organes de gestion restent hors circuit.

Les onduleurs couplés partagent le tableau du maître. En recouvrement, chaque
appareil dépend du maître indépendant le plus proche ; l'affectation ne change
pas lorsque ses batteries se vident. Les interrupteurs d'une pièce suivent tous
le tableau le plus proche du centre de la pièce. Une coupure de circuit arrête
l'appareil affecté même si sa prise pourrait recevoir un autre courant. Le
principal, lui, coupe seulement la distribution de ce réseau.

Les appareils de mods utilisant les mécanismes vanilla suivent les mêmes règles ;
les services électriques spécifiques nécessitent une compatibilité. Avant de
désactiver Live Wire, rétablir les circuits pour restaurer les types des frigos.

![Live Wire 1.6.0](../../images/screenshots/shot6.png)

Le tableau électrique en jeu, avec ses leviers éclairage/équipements et son wattmètre instantané. « Updating... » est l’état temporaire avant réception des mesures.


Le menu contextuel ne propose qu'une ouverture par panneau : tableau électrique
pour le disjoncteur, panneau LCD pour la powerbank. « Raccordements » reste un
écran distinct, accessible par un bouton sur chaque panneau.


Les panneaux affichent **État équipement : … %** : c'est l'usure de la powerbank
ou du tableau, distincte de la charge et de l'état des batteries. Deux powerbanks
superposées ont chacune leur état. Il reste visible sans raccordement et à 0 %.
Les sources, pompes et alarmes ont aussi leur LCD individuel ; l'onduleur
affiche son état dans sa page État. « -- % » signifie donnée inconnue.


## LCD de chaque appareil et choix de l'onduleur

Cliquez sur un panneau solaire, une éolienne ou une roue à aubes pour afficher
son LCD : état en %, production mesurée et puissance nominale. Le solaire montre
aussi saleté/neige, l'éolienne le frein. Non raccordé ou cassé : production 0 W.
La pompe affiche son état, son débit d'eau mesuré et sa consommation électrique.
L'alarme possède un écran d'état. Les relevés reprennent les dernières mesures
de simulation, relues toutes les deux secondes pendant l'ouverture.

Le bouton **Raccordements** de chaque appareil permet de choisir l'onduleur pour
cet appareil seul. Sur l'onduleur, ce bouton garde la liste complète des appareils
du réseau choisi. Changer un appareil de réseau demande de le débrancher d'abord ;
les coûts de câble, outils et compétences restent applicables.


Sur le disjoncteur posé, le **voyant vert** indique une distribution alimentée.
Il reste vert si seuls les circuits lumières/équipements sont ouverts ; principal
coupé ou absence de courant : éteint. **Rouge** : protection déclenchée. Ce voyant
n'est pas une preuve d'isolation pour l'entretien : éteignez l'onduleur.

## Voir aussi

[Équipements](02-equipements.md) · [Écran et logiciel](05-ecran-et-logiciel.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) · [Options sandbox](11-options-sandbox.md)
