# Live Wire — choix de conception et extensions

État au 2026-10-24, Build 42.21. Ce document conserve les motivations et les
questions ouvertes. Les règles livrées font référence aux
[spécifications fonctionnelles](../../specifications-fonctionnelles.md) et aux
[contrats techniques](../../specifications-techniques.md). Le
[suivi des correctifs et idées](../../ameliorations-et-idees.md) fait foi pour les priorités.

Les sections 1 à 5 gardent leur numérotation historique. Elles ne correspondent
ni aux identifiants IXX du suivi, ni à l'ancienne liste I-n des spécifications.
Les sections 2 et 5 décrivent des fonctionnalités livrées ; les sections 1, 3 et 4
restent des propositions, sans engagement de version.

## 1. Chargeur de piles — proposé

Un meuble raccordé à un onduleur permettrait de recharger quatre piles
`Base.Battery`, au niveau 2 d'Électricité. La puissance envisagée est de 15 W par
pile et une recharge durerait quelques heures de jeu. Sans alimentation, la
charge s'arrêterait. Les cycles diminueraient progressivement la charge maximale.

`Base.Battery` est un objet drainable sans état d'usure comparable à celui des
batteries de voiture (`media/scripts/generated/items/drainable.txt:673`, sources
42.21.0). Le suivi des cycles nécessiterait une donnée persistante distincte.
Le serveur gérerait la charge et synchroniserait les objets du conteneur ;
l'interface afficherait leur progression. Une éventuelle reprise après absence
devrait respecter l'historique réel d'alimentation.

À préciser avant réalisation : durée de charge, usure, recette, prise en charge
des piles installées dans un appareil et compatibilité avec les piles d'autres mods.
Le premier périmètre envisagé se limite aux piles séparées de leur appareil.

## 2. Pompe à eau — livrée depuis la version 1.2

L'objectif est d'utiliser des réserves au sol pour alimenter la plomberie vanilla.
Le moteur ne cherche sa source qu'à l'étage supérieur, dans un carré de 3 × 3
cases, et impose un `IsoThumpable` contenant du fluide
([NM-46](../recherches/notes-moteur.md)).
La pompe remplit donc un relais invisible de 25 L au-dessus du point d'eau,
sans remplacer les composants des récupérateurs ni leur collecte native de pluie.

### Choix retenus

- Pompe de niveau 6, raccordée à un onduleur ; jusqu'à huit réserves adjacentes
  au même étage, reliées avec un tuyau chacune. Seules l'eau propre et l'eau
  croupie sont acceptées, dans une réserve d'au moins 20 L de capacité.
- Débit plafonné à 5 L/min de jeu, puissance de 250 W pendant le pompage.
  Une réserve vide reste raccordée. Aucun crédit de débit ne s'accumule au repos.
- Portée de plomberie réglable, 15 cases par défaut, de 5 à 30. Une source
  vanilla existante reste prioritaire.
- Un relais partagé appartient à la pompe raccordée, non cassée, la plus proche
  du point situé dessous ; une égalité est départagée par identifiant.
  Un changement de propriétaire conserve le même relais et son eau.
- Au retrait d'une pompe, le relais est réattribué si une autre pompe est
  admissible. Sinon il est retiré et son eau restante est perdue.
  Le nettoyage couvre aussi les chunks déchargés, à leur prochain chargement.
- Les relais sont transparents, traversables, sans collecte de pluie et protégés
  des interactions de démontage. Leur création peut nécessiter une case `z + 1`
  qui n'existait pas encore.
- La vue locale indique la portée et les objets concernés. Le logiciel résume
  les pompes actives et le débit ; le transfert de fluide reste serveur.

La persistance, le transfert entre pompes et le retrait ont été vérifiés en SP/MP
avec redémarrages : voir le [bilan de validation](../tests/validation.md).
Le remplissage par pluie hors zone reste une lecture du moteur, distincte d'un
essai de compatibilité avec chaque mod de récupérateur ([NM-47](../recherches/notes-moteur.md)).

## 3. Clôture électrifiée — proposée

Un électrificateur raccordé alimenterait une longueur limitée de clôture au niveau
7 d'Électricité. Une décharge non létale repousserait ou ferait tomber un zombie,
avec un bruit et un effet visible. L'hypothèse initiale est une consommation de
veille, complétée par 0,02 kWh par décharge. Sans courant ou après disjonction,
la clôture serait inactive.

Le repérage doit rester borné aux zones chargées. En MP, `getThumpTarget` peut
être absent côté serveur pour un zombie piloté par un client : la détection et
l'application de la réaction nécessitent une vérification de l'autorité native.
Un registre de positions serait préférable à une ModData supposée disponible
sur tous les types de clôture.

À décider : clôtures et portails acceptés, longueur, fréquence des décharges,
réaction des zombies, passage du joueur, dégâts aux joueurs et règles PvP.

## 4. Installations abandonnées — proposées

De rares installations incomplètes pourraient apparaître dans des lieux
plausibles : maisons isolées, chalets, ateliers, fermes ou berges. Les appareils
seraient usés, avec des pièces manquantes et des batteries presque vides.
Ils seraient éteints et non raccordés, à réparer ou récupérer selon les règles
habituelles de compétence et de propriété.

La génération devrait avoir lieu une seule fois par bâtiment, avec une fréquence
réglable et une valeur nulle pour la désactiver. L'identifiant persistant du
bâtiment, le placement sur les toits et le repli au sol restent à vérifier avant
réalisation. Le mécanisme de découverte doit s'accorder avec l'adoption actuelle
des appareils, sans créer de doublons.

À décider : bâtiments admissibles, fréquence, plages d'état et de charge,
indices éventuels sur carte ou radio, propriété des objets trouvés et safehouses.

## 5. Onduleurs en parallèle — livrés depuis la version 1.3

Le couplage augmente la puissance disponible en réutilisant le même modèle
d'onduleur. Il évite un second modèle renforcé, écarté par la décision D-17.

- Un maître accepte jusqu'à trois esclaves : 1 500 W par onduleur actif, soit
  6 000 W au maximum. Chaque onduleur actif consomme 20 W de veille.
- Un seul réseau et une seule ancre, à la position du maître. Les appareils
  se raccordent au maître ; un esclave ouvre l'interface du maître.
- Un esclave doit être indépendant et sans membres ni esclaves. Un maître ne
  peut pas lui-même devenir esclave. Le couplage demande le niveau 6,
  un kit de synchronisation et du fil, dans la portée prévue par le contrat.
- Le découplage rend le kit, sans rendre le fil. Le retrait du maître libère
  les esclaves en réseaux indépendants sans membres.
- Chaque esclave garde sa commande de marche. L'interface affiche le nombre
  d'onduleurs actifs et la capacité totale ; l'usure augmente à forte charge.
- En cas de recouvrement, la demande revient à l'onduleur indépendant le plus
  proche, avec départage par identifiant et réattribution au pas suivant.

L'alimentation reste une zone native autour de l'ancre : le couplage ne crée
pas de circuits par pièce. Les essais de couplage et découplage figurent dans
le [protocole](../tests/protocole-tests.md) et le [bilan](../tests/validation.md).

## Périmètre écarté

Les propositions écartées sont recensées dans le
[suivi des idées](../../ameliorations-et-idees.md).
Leur présence dans un ancien calendrier ne vaut pas décision de réalisation.
Toute extension conserve l'architecture modulaire à serveur autoritaire décrite
dans [architecture.md](../../architecture.md).
