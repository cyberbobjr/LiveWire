# Live Wire — architecture à préserver

Les instructions de `CLAUDE.md` s'appliquent également.

Le pattern existant est une **architecture modulaire événementielle, avec serveur
autoritaire**, décrite dans `docs/architecture.md` (§ 2) et issue des décisions
validées par l'utilisateur le 2026-10-17 (`docs/decisions.md`). Il est conservé pour
la campagne de correctifs autorisée le 2026-10-24 ; aucune migration de pattern.

- `shared` : contrats réseau, configuration, fonctions pures, marques et adaptateurs
  vanilla nécessaires des deux côtés. Aucune dépendance obligatoire vers le client.
- `server` : registre/persistance, règles métier, simulation, validation des actions
  et commandes. Garde d'autorité obligatoire. Aucun appel d'interface.
- `client` : présentation et commandes ; aucune mutation du registre autoritaire.
- Le registre possède ses index ; chaque service possède ses caches de session.
  La simulation orchestre les services sans absorber leurs responsabilités.
- Les parcours bornés sont indépendants des règles de pompe et de présentation.
  Conserver les contrats existants, éviter les dépendances circulaires et les
  abstractions sans usage concret (principes SOLID).

Plan et preuves : `docs/annexes/plans/correctifs-blocages-performances.md`.
