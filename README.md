# Live Wire (`batman_LiveWire`)

Mod Project Zomboid Build 42.21 qui donne un vrai rôle à la compétence Électricité. Il construit une installation électrique en trois rôles :
- **sources** : panneaux photovoltaïques, éoliennes et roues à aubes ;
- **batteries** : facultatives, pour stocker ; on les range dans une **powerbank** qui s'ouvre comme une caisse ;
- **onduleur** : convertit le courant, et peut se poser à l'intérieur.

Un **disjoncteur mural** et une **alarme de batterie faible** sont disponibles en option. Un générateur vanilla peut servir de secours, et un ordinateur de bureau vanilla de poste de gestion.

**Pose** : chaque équipement est une **tuile du mod** (`batman_livewire_01`, formes géométriques provisoires), fabriquée par recette puis posée, tournée et ramassée comme un meuble vanilla. **Raccordement** : clic droit → « Live Wire ».

**État : v0.1.1.** Un test en jeu automatique en solo passe (`autotest/lw_hooks.lua` : pose, conteneur, raccordement, rotation, ramassage, menus). Le multijoueur n'a pas encore été testé en jeu.

- Conception : `docs/fonctionnel.md`, `docs/architecture.md`.
- Décisions : `docs/decisions-ouvertes.md`.
- Faits du moteur : `docs/notes-moteur.md`.
- Test manuel : `docs/protocole-tests.md`.
- Test en jeu automatique (depuis `C:\Users\cyber\Zomboid\Workshop`) : `python .claude/tools/pz-autotest/pz_autotest.py sp LiveWire --wait-idle 3600`.
- Vérifications hors jeu (Python 3, `pip install lupa pillow`) :
  - `python tools/check_mod.py`
  - `python tests/test_physics.py`
  - `python tests/test_simulation.py`
- Fichiers générés :
  - traductions : `tools/translations_src.py` ;
  - modèles 3D provisoires des objets d'inventaire : `tools/make_placeholder_models.py` ;
  - tuiles : `source/tiles/build_livewire_tiles.py` (Blender et pz-sprite-forge, voir son en-tête).
- Instructions pour les agents : `CLAUDE.md`.
- Sources de référence du jeu : dépôt privé `cyberbobjr/pz-source-42.21`.

Dépôt privé.
