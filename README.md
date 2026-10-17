# Live Wire (`batman_LiveWire`)

Mod Project Zomboid Build 42.21 qui donne un vrai rôle à la compétence Électricité. Il construit une installation électrique en trois rôles :
- **sources** : panneaux photovoltaïques et éoliennes ;
- **batteries** : facultatives, pour stocker ;
- **onduleur** : convertit le courant, et peut se poser à l'intérieur.

Un **disjoncteur mural** est disponible en option.

**État : v0.1 implémentée, vérifiée hors jeu, jamais testée en jeu.** Les modèles 3D sont des formes géométriques provisoires.

- Conception : `docs/fonctionnel.md`, `docs/architecture.md`.
- Décisions : `docs/decisions-ouvertes.md`.
- Faits du moteur : `docs/notes-moteur.md`.
- **Test en jeu à faire** : `docs/protocole-tests.md`.
- Vérifications hors jeu (Python 3, `pip install lupa pillow`) :
  - `python3 -I tools/check_mod.py`
  - `python3 -I tests/test_physics.py`
  - `python3 -I tests/test_simulation.py`
- Fichiers générés : traductions (`tools/translations_src.py`) et modèles provisoires (`tools/make_placeholder_models.py`).
- Instructions pour les agents : `CLAUDE.md`.
- Sources de référence du jeu : dépôt privé `cyberbobjr/pz-source-42.21`.

Dépôt privé.
