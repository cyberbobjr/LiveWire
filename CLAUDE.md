# Live Wire (`batman_LiveWire`) — instructions pour les agents

Mod Project Zomboid **Build 42.21** de l'utilisateur (compte de jeu `batman`). Ce fichier vaut pour toute session, locale ou dans le cloud.

## Communication
- Répondre et documenter **en français**. Code, identifiants, messages console (`print`, `error`) et notes de version Workshop **en anglais**.
- Présenter la cause, les preuves (`fichier:ligne`), la décision et ses limites. Qualifier chaque fait : « confirmé statiquement », « confirmé en jeu », « hypothèse ».
- **Ne jamais annoncer un test en jeu non effectué.** Fournir un protocole court à la place.

## Sources de référence
- Dépôt privé **`cyberbobjr/pz-source-42.21`** : Java décompilé (`java/`), index des fonctions Lua globales et classes exposées (`index-lua-*.txt`), Lua et scripts vanilla (`media/`), et **base de connaissances du moteur** (`knowledge/`, index `knowledge/README.md`). En session cloud, le cloner à côté de ce dépôt (`git clone https://github.com/cyberbobjr/pz-source-42.21 ../pz-source-42.21`).
- Avant d'investiguer un mécanisme : 1) chercher par mots-clés dans `knowledge/` ; 2) puis dans `media/lua` et `media/scripts` ; 3) puis dans `java/`. Ne jamais transposer une recette Build 41 ou une ancienne Build 42 sans vérifier dans ces sources.
- Un fait nouveau et réutilisable sur le moteur se note dans `docs/annexes/recherches/notes-moteur.md` de ce dépôt (titre, Build, date, statut, preuve, conséquence) : l'utilisateur le reportera dans la base maîtresse.

## Documentation
- Toute la documentation est sous `docs/` (index `docs/README.md`), selon la structure commune `../docs/structure-documentaire.md` : `architecture.md`, `specifications-fonctionnelles.md` (F01…), `specifications-techniques.md` (contrats à jour), `decisions.md`, `ameliorations-et-idees.md`, `wiki/en` + `wiki/fr`, `images/` (`diagrams`, `screenshots`, `icons`), `annexes/`.
- Images régénérées par `python tools/make_doc_images.py` (→ `docs/images/diagrams/`) et tableaux par `python tools/make_doc_tables.py` (→ `docs/wiki/<langue>/_tables.md`).

## Règle de création indépendante
- **Aucun code, asset, texte ni nom repris d'un autre mod** (en particulier les mods d'énergie existants : ERS – Energy Routing System, Plysken Solar Revolution, Immersive Solar Arrays). Leurs licences l'interdisent. Les idées et mécaniques de jeu sont libres ; leur réalisation doit être originale et fondée sur le jeu vanilla.
- Les modèles 3D et tuiles définitifs viendront plus tard (Blender). En attendant : **formes géométriques simples** (cubes, cylindres, plans) ou objets vanilla existants comme substituts, clairement marqués `placeholder` dans les scripts et la documentation.

## Structure du mod
- Projet Workshop : `workshop.txt`, `preview.png` (256 × 256, plus tard), `Contents/mods/batman_LiveWire/` avec `common/` et `42.21/mod.info` + `42.21/media/`.
- `mod.info` : `id=batman_LiveWire`, `versionMin=42.21`, `modversion=` à jour. Noms de fichiers et espaces de noms Lua propres au mod (`LiveWire/…`, table globale `LiveWire`).
- Séparer `client`, `server`, `shared`. Le dossier `media/lua/server` est **aussi chargé par les clients MP** : garder la logique serveur par `if isClient() then return end` (ou équivalent) quand elle ne doit tourner que sur l'autorité.
- Lua Kahlua : pas de littéral non ASCII dans un `.lua` (écrire les accents en échappements d'octets UTF-8 `"\195\169"`) ; les fonctions ne sont pas des tables ; préserver arguments et retours vanilla dans tout wrapper ; aucun crochet global sur une fonction de rendu appelée à chaque image (`drawText`, `render` de classes vanilla) ; pas d'abonnement répété aux événements.

## Multijoueur
- Serveur **autoritaire** : stocks d'énergie, états, dégâts, expérience (`addXp` est sans effet sur un client MP) décidés sur le serveur ; le client affiche et envoie des commandes (`sendClientCommand`), que le serveur revérifie entièrement.
- Cible réelle : serveur dédié Linux entre amis. Tout chemin de ressource respecte la casse exacte.
- Préserver les identifiants persistants (types d'objets, clés de ModData) ; prévoir une migration explicite en cas de changement.

## Traductions
- Tout texte affiché au joueur passe par `getText` et `media/lua/shared/Translate/<LANGUE>/*.json` (objet JSON plat ; préfixe de clé = fichier : `IGUI_` → `IG_UI.json`, `Sandbox_` → `Sandbox.json`, `ContextMenu_` → `ContextMenu.json`, recettes dans `Recipes.json` par nom de recette, objets dans `ItemName.json` en `Module.Objet`). Arguments `%1`, `%2` ; `%%` pour un signe pour-cent.
- Langues livrées : **EN** (référence), **FR**, CN, DE, ES, JP, KO, PT, PTBR et RU (dix langues). Reprendre le vocabulaire vanilla de `media/lua/shared/Translate/FR` du dépôt de référence.

## Git
- Dépôt **public** `cyberbobjr/LiveWire` : n'y mettre aucune donnée personnelle (chemins de ton poste, adresses, clés). Travailler sur `main`, un commit par étape cohérente, message en anglais. Ne jamais publier sur le Workshop : la publication se fait sur le poste de l'utilisateur.
