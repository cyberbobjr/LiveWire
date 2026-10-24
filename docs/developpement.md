# Live Wire — contraintes de développement

Contraintes propres à ce projet. Les règles communes à tous les mods de l'utilisateur (règle immuable du Workshop
Steam, méthode de diagnostic, Kahlua, multijoueur, traductions, base de connaissances du moteur, tests en jeu
automatisés) vivent dans le fichier d'instructions unique du dossier de développement parent, hors de ce dépôt.

## Périmètre du projet

- Deux mods frères sous `Contents/mods` : **`batman_LiveWire`** (le mod) et **`batman_LiveWireViewpoint`**, qui déclare
  `require=batman_LiveWire`. Toute modification de structure, de version ou de publication concerne les deux.
- Chaque mod a un dossier `common/` et la variante `42.21/` portant `mod.info` (`versionMin=42.21`, `modversion=` à
  jour) et `media/`. Noms de fichiers et espaces de noms Lua propres au mod (`LiveWire/…`, table globale `LiveWire`).
- `preview.png` existe en 512 × 512.

## Architecture à préserver

Le pattern en place est une **architecture modulaire événementielle à serveur autoritaire**, décrite dans
[`architecture.md`](architecture.md) (§ 2) et issue des décisions validées par l'utilisateur le 2026-10-17
([`decisions.md`](decisions.md)). Il est conservé pour la campagne de correctifs autorisée le 2026-10-24 ; **aucune
migration de pattern**.

- `shared` : contrats réseau, configuration, fonctions pures, marques et adaptateurs vanilla nécessaires des deux
  côtés. Aucune dépendance obligatoire vers le client.
- `server` : registre/persistance, règles métier, simulation, validation des actions et commandes. Garde d'autorité
  obligatoire. Aucun appel d'interface.
- `client` : présentation et commandes ; aucune mutation du registre autoritaire.
- Le registre possède ses index ; chaque service possède ses caches de session. La simulation orchestre les services
  sans absorber leurs responsabilités.
- Les parcours bornés sont indépendants des règles de pompe et de présentation. Conserver les contrats existants,
  éviter les dépendances circulaires et les abstractions sans usage concret (principes SOLID).

Les scénarios, résultats et limites des campagnes CXX sont regroupés dans le
[bilan de validation](annexes/tests/validation.md). Le
[suivi](ameliorations-et-idees.md) indique les correctifs réalisés, différés et exclus.

## Règle de création indépendante

- **Aucun code, asset, texte ni nom repris d'un autre mod**, en particulier des mods d'énergie existants (ERS – Energy
  Routing System, Plysken Solar Revolution, Immersive Solar Arrays). Leurs licences l'interdisent. Les idées et
  mécaniques de jeu sont libres ; leur réalisation doit être originale et fondée sur le jeu vanilla.
- Les modèles 3D et tuiles définitifs viendront plus tard (Blender). En attendant : **formes géométriques simples**
  (cubes, cylindres, plans) ou objets vanilla existants comme substituts, clairement marqués `placeholder` dans les
  scripts et la documentation (`tools/make_placeholder_models.py`).

## Documentation et outils

- Toute la documentation est sous `docs/` (index [`README.md`](README.md)), selon la structure commune imposée à tous
  les projets de l'utilisateur.
- Images régénérées par `python tools/make_doc_images.py` (→ `docs/images/diagrams/`) ; tableaux de recettes et de
  butin par `python tools/make_doc_tables.py` (→ `docs/wiki/<langue>/_tables.md`).
- Contrats techniques, clés ModData, commandes réseau, options sandbox et langues livrées :
  [`specifications-techniques.md`](specifications-techniques.md). Langues : `EN` (référence), `FR`, `DE`, `ES`, `PT`,
  `PTBR`, `RU`, `CN`, `JP`, `KO`.
- Un fait nouveau et réutilisable sur le **moteur du jeu** découvert ici se note dans
  [`annexes/recherches/notes-moteur.md`](annexes/recherches/notes-moteur.md) (titre, Build, date, statut, preuve,
  conséquence) : l'utilisateur le reportera dans sa base de connaissances maîtresse, hors de ce dépôt.

## Dépôt

Dépôt GitHub **public**. N'y mettre aucune donnée personnelle : chemins absolus du poste de l'utilisateur, adresses,
noms de dépôts privés, clés. Travailler sur `main`, un commit par étape cohérente, message en anglais. La publication
Workshop se fait sur le poste de l'utilisateur, jamais depuis une session automatique.

Les notes de changement Steam décrivent les changements pour les joueurs, sans section de tests ou de validation.
Les résultats et limites des essais restent dans le bilan de validation du projet.
