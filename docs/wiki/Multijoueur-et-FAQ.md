[English version: [Multiplayer-and-FAQ](Multiplayer-and-FAQ)]

# Multijoueur, FAQ et installation

## Multijoueur

Production, stock, états, pannes et expérience sont calculés par le serveur ; le client affiche et envoie des demandes que le serveur revérifie entièrement.

- Installations partagées selon les règles vanilla des refuges.
- Le logiciel peut avoir jusqu'à 10 minutes de jeu de retard.
- Si le serveur se met en pause quand il est vide, l'installation aussi.
- Les générateurs vanilla ne changent pas : si un générateur et un onduleur couvrent les mêmes appareils, les deux consomment.
- Outils de debug : -debug en solo, administrateurs en multijoueur.
- **Le multijoueur n'a pas encore été testé en jeu.**

## État

Version 1.3.0. Testé en jeu en solo pendant le développement : pose, conteneur, liaison, voyants, disjoncteur, alarme, écran LCD, logiciel, zone alimentée, rotation, ramassage, frigo pendant une absence, intégration du Computer Mod. Les valeurs d'équilibrage sont des valeurs de départ. Les tuiles sont des formes géométriques provisoires (modèles définitifs plus tard).

## FAQ

**Combien de panneaux faut-il ?**
Aucune limite : les productions s'additionnent (100 W nominaux chacun). Pour un frigo-congélateur et 10 lumières (environ 4,1 kWh par jour), 4 panneaux sont en déficit (3,8 kWh en été, 2,4 en hiver). Voir [Production et calculs](Production-et-calculs).

**Quand le disjoncteur saute-t-il ?**
Quand la demande de la maison dépasse 1 500 W (par exemple lave-linge et sèche-linge superposés). Voir [Équipements optionnels](Equipements-optionnels).

**L'onduleur peut-il rester à l'intérieur ?**
Oui. Ce n'est pas un générateur du jeu : pas de toxicité, pas de fumées. Un bourdonnement léger s'entend à une case autour ; le kit d'insonorisation le supprime.

**Où trouver des cellules photovoltaïques et des panneaux ?**
Les cellules se trouvent dans les garages, caisses d'outils, ateliers de métallerie, quincailleries et boutiques d'électricité, se récupèrent sur les calculatrices ou se fabriquent au niveau 8. Un panneau tout fait est rare dans le butin. Voir [Tables de butin](Tables-de-butin).

**Faut-il des batteries ?**
Non. Une source et un onduleur suffisent, mais sans batterie la maison ne tourne que sur la production du moment (pas la nuit pour un panneau).

**Ma base reste-t-elle alimentée pendant une expédition ?**
Oui : le serveur simule même sans personne à proximité (option SimulateUnloaded), et les frigos gardent la nourriture au froid. L'état d'alimentation trouvé au rechargement de la zone compte pour toute l'absence.

**Le bourdonnement est trop fort.**
Réglez le volume dans Options, Mods, Live Wire (0 = coupé), ou posez un kit d'insonorisation (l'onduleur s'use alors 25 % plus vite).

## Installation

Abonnez-vous au mod sur le Workshop Steam (une fois publié), ou copiez `Contents/mods/batman_LiveWire` dans `Zomboid/mods`, puis activez `batman_LiveWire` (Build 42.21). Le Computer Mod (3725497089) et le Laptop Mod (3798992436) sont facultatifs ; leur intégration est décrite dans [Écran et logiciel](Ecran-et-logiciel).

## Licence

MIT (fichier LICENSE). Dépôt : https://github.com/cyberbobjr/LiveWire. Création originale : aucun code ni ressource d'un autre mod.

## Voir aussi

[Présentation](Presentation) · [Options sandbox](Options-sandbox) · [Raccordement](Raccordement) · [FAQ](FAQ-fr)
