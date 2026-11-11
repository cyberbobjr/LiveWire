> English version: [Multiplayer](../en/12-multiplayer.md)

# Multijoueur

## Autorité du serveur

La production, les stocks, les états, les pannes et l'expérience sont calculés par le **serveur**. Le client affiche et envoie des demandes, que le serveur vérifie à nouveau.

- L'expérience n'est accordée que par le serveur.
- Les installations partagées suivent les règles vanilla de la planque (safehouse).
- Le logiciel peut avoir jusqu'à 10 minutes de jeu de retard.
- Si le serveur se met en pause quand il est vide, l'installation se met aussi en pause.
- Les générateurs vanilla ne changent pas : si un générateur et un onduleur alimentent les mêmes appareils, les deux comptent.
- Outils de debug : `-debug` en solo, administrateurs en multijoueur.

## Tableaux électriques en multijoueur

- Un client peut poser un tableau électrique dans une maison de joueur fraîchement construite, fermée et couverte ; le serveur juge ensuite la pose et la refuse si l'emplacement n'est pas dans une pièce fermée et couverte.
- Un perron couvert, une cour ou le bord d'un bâtiment de la carte est refusé sur tous les clients. Ces cases sont des données de la carte.
- Le raccordement, la commande et le déclenchement des disjoncteurs sont décidés par le serveur.

## Actions d'administrateur avant de retirer l'extension

Sur un serveur, un administrateur doit remettre tous les disjoncteurs en service avant de retirer LiveWire Extended de la liste des mods. Ouvrez le menu d'un tableau électrique et choisissez **Admin : tout remettre en service (avant de retirer le mod)**. Ensuite, les tableaux ne coupent plus et les appareils retrouvent leur état normal. **Admin : remettre les tableaux en fonction** reprend le fonctionnement des tableaux. Voir [LiveWire Extended](14-livewire-extended.md#retirer-lextension).

## Licence

MIT (fichier `LICENSE` du dépôt). Aucun code ni aucun actif n'a été repris d'un autre mod.

## Voir aussi

[Premiers pas](01-premiers-pas.md) · [Options sandbox](11-options-sandbox.md) · [Équipements](02-equipements.md) · [Compétence Électricité et entretien](10-competence-electricite-et-entretien.md) · [FAQ](13-faq.md) · [LiveWire Extended](14-livewire-extended.md)
