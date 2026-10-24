# Correctifs des blocages et performances

Autorisation utilisateur : 2026-10-24, C07, C09, C22, C04, C05, C06, C16 et partie
mémoire de C23. Conserver l'architecture modulaire autoritaire validée, cf. AGENTS.md.

## Ordre de réalisation

1. C07 : validation des marques de barils par position et appartenance réelle,
   nettoyage autoritaire et compatibilité des anciennes marques.
2. C09 : distinguer contrôle automatique et intervention manuelle, préserver ce
   choix au chargement ; commande explicite de reprise avec contrôles serveur.
3. C22 : inspection sans effet implicite, frein explicite réversible, contrôles
   safehouse revérifiés à la fin de l'inspection et du déneigement.
4. C06 : index de session par chunk dans Registry, reconstruit au chargement et
   maintenu lors des ajouts, déplacements et retraits.
5. C16 : cache solo lié à l'identité du registre/réseau et à sa révision.
6. C23 : purge périodique des limiteurs mémoire sans raccourcir les délais actifs.
7. C04 : découverte des points d'eau étalée et invalidée par mobilier/chunks ; vue
   client étalée puis rafraîchie depuis sa liste.
8. C05 : inventaire des frigos chargés pour vieillissement avant bascule ; file
   bornée pour le rafraîchissement visuel après bascule.
9. Vérifications hors jeu, campagne réelle SP puis MP, mise à jour du tableau de
   bord et des contrats. Aucun envoi Workshop.

## Responsabilités et validation

Le registre possède les index ; Backup possède le mode manuel ; Pump possède ses
travaux de découverte ; PumpView possède ses surbrillances ; Anchor possède les
effets de l'alimentation ; le parcours de cases ne connaît aucune règle métier.
Les commandes revérifient distance, type, compétence et safehouse sur l'autorité.

Tests ciblés : marques déplacées et anciennes ; arrêt/allumage manuel et reprise ;
inspection/déneigement interdits ; frein aller/retour ; index après déplacement et
retrait ; cache invalidé ; purge avec délai actif ; budgets par tick ; pompe et vue
après ajout/retrait ; vieillissement avant bascule et alimentation vanilla voisine.

## Résultats

Les huit points du périmètre sont réalisés localement, sans publication Workshop.
C23 reste partiel dans le suivi : sa purge mémoire est faite, son plafond global
d'expérience est une proposition distincte.

### Vérifications hors jeu

- `python tools/check_mod.py E:/pz-decompiled/42.21.0` : OK (syntaxe Lua 5.1,
  chargement simulé, ressources, traductions dans dix langues et événements).
- `python tests/test_physics.py` et `python tests/test_simulation.py` : OK.
- `python tests/test_regressions.py` : **10/10**. Cycle de vie des index, préservation du mode lecture seule des schémas futurs, migration et
  déplacement des marques, arrêt/allumage manuel, reprise automatique et
  rapprochement du carburant hors zone, identité/révision du cache, purge avec
  délai de 48 h encore actif, permissions, vieillissement avant bascule.
- Les parcours de trois pompes et de trois ancres ont chacun un budget global
  maximal de **250 positions par appel de tick**. Une mise en file ne parcourt pas
  le disque ; le curseur au rayon 30 couvre exactement 19 747 cases sur sept niveaux.

### Vérifications dans le vrai jeu — 42.21

Version du runtime relevée par les hooks : **42.21**. Empreinte SHA-256 du JAR
installé identique à celle des sources décompilées 42.21.0 :
`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`.

| Campagne | Résultat | Preuve locale (dossier ignoré par Git) |
|---|---|---|
| SP existante complète, scènes et absence du joueur comprises | **36/36**, code 0 | `runs/20261024-120604-sp-9c727093877e/summary.txt` |
| MP existante, serveur dédié + client | **12/12 serveur, 6/6 client**, code 0 | `runs/20261024-115346-mp-dcdfc4c745dd/summary.txt` |
| SP ciblée C04–C09, C16, C22, mémoire C23 | **12/12**, code 0 | `runs/20261024-120157-sp-e159635ae8c5/summary.txt` |
| MP ciblée, client rétrogradé au rôle utilisateur | **14/14 serveur, 6/6 client**, code 0 | `runs/20261024-120346-mp-7e4f69399c86/summary.txt` |

Les nouvelles campagnes ne signalent aucune nouvelle erreur Lua. La pompe découvre
le point d'eau en **28 ticks serveur** et transfère réellement l'eau. Le client
ordinaire serre/desserre le frein et reprend le secours par le réseau ; les marques
sont synchronisées. Les refus de safehouse sont exercés sur l'autorité avec les
vraies actions d'inspection/déneigement et la commande du frein. Un vrai aliment de
réfrigérateur vieillit sous l'ancien état d'alimentation avant la coupure.

Reproduction : depuis la racine de travail, lancer
`python .claude/tools/pz-autotest/pz_autotest.py sp LiveWire/autotest/fixes.json --wait-idle 3600`,
puis la même commande avec `mp` à la place de `sp`. Les campagnes existantes utilisent
`LiveWire` comme projet. Les sauvegardes utilisateur sont copiées dans les caches de test.

### Limites

- Ces essais confirment les fonctions et le budget de travail, pas un gain de FPS
  chiffré sur un serveur chargé de nombreuses bases ; ce profilage reste à faire.
- La création des relais et l'inventaire de leur vue deviennent progressifs. Au
  rayon par défaut, la découverte initiale dure environ 2,8 s sur le serveur testé.
- C07 est vérifié avec de vrais objets à des positions différentes et des marques
  héritées ; le cycle vanilla complet ramassage/inventaire/repose du baril reste
  à contrôler manuellement. Les anciennes marques sont migrées à la lecture.
- Le prototype P-pompe complet (sauvegarde et invisibilité des relais) et le scénario
  de désinstallation C01 restent à compléter dans C25. Le test MP non administrateur
  est maintenant couvert. Le rendu Project Viewpoint n'a pas été testé.
