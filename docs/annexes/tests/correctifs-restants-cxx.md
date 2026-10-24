# Validation des derniers correctifs CXX — 2026-10-24

## Périmètre et environnement

C08, C12, C17, C18, C19, C21, fin de C23 et C24. C11 reste différé selon la
confirmation utilisateur ; C20 et toutes les idées IXX sont exclus. Aucune
publication Workshop. [Plan et responsabilités](../plans/correctifs-restants-cxx.md).

Jeu réellement exécuté : **42.21**, journal de démarrage **42.21.0**. Référence
Java décompilée 42.21.0 correspondant au JAR installé (SHA-256
`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`).
Tests sur copies privées : aucune sauvegarde utilisateur ni ressource Steam
Workshop modifiée. Le mode MP utilise un serveur dédié local Windows et deux
processus clients, pas un serveur Linux ni une session hébergée.

## Scénarios couverts

- **C08** : vraie découverte d'un robinet par les ticks, relais d'une première
  pompe transféré à une pompe plus proche, même objet et même eau ; maintenances
  répétées sans oscillation ; débranchement du baril qui rend le relais à l'autre
  pompe, puis reprise ; propriété et fluide constatés par les deux clients et
  après arrêt/redémarrage. Égalité de distance et entrée périmée de l'ancien
  propriétaire couvertes hors jeu.
- **C18** : relais pleins, dix minutes de service appelées au repos avec un ancien
  crédit de 10 L, puis demande de 10 L : transfert limité à 5 L, prélevés dans le
  vrai baril. Aucun crédit sauvegardé ne crée une rafale.
- **C17** : réglages sandbox natifs 80/20, vrai générateur qui démarre à 79 %,
  reste en marche à 82 % et s'arrête à 85 % ; instantané à seuil effectif 85.
  Contrôle hors jeu de l'avertissement unique et des réglages valides ; dix
  infobulles traduites contrôlées automatiquement.
- **C21** : vrai service de simulation d'un réseau hors zone, batterie à 0,3 kWh,
  besoin total de 1 kW, pas d'une heure : service pendant 0,3 h, stock consommé,
  coupure datée à cette fraction et conservée après redémarrage. Hors jeu :
  conservation de l'énergie, production partielle, épuisement exact et seuil de
  redémarrage. Les sous-pas météo restent une approximation d'une heure au plus.
- **C12** : véritable pomme dans un réfrigérateur ; quarante changements datés
  injectés comme historique de test, moitié du temps alimenté : âge égal au
  calcul attendu, journal public toujours limité à seize changements, historique
  privé conservé après relance. Les deux clients reçoivent l'objet sérialisé
  après rattrapage et constatent son âge. Rétention à 60 jours, reprise d'un ancien
  journal sans alias, retrait d'une ancre et absence de diffusion supplémentaire
  d'un état stable couverts hors jeu. Ce test n'attend pas réellement 60 jours de
  jeu ; la durée de rétention est vérifiée sur les entrées horodatées.
- **C19** : vrais relais aux niveaux −2 et 9, nettoyage sur les limites natives du
  chunk ; nouveaux orphelins sauvegardés puis retirés par le vrai `LoadChunk` du
  processus suivant. Absence constatée après reconnexion par les deux clients.
- **C24** : marque effacée puis altérée, restauration du même identifiant et des
  valeurs serveur sans double adoption ; vraie tuile détruite retirée du registre.
  Deux clients de niveaux différents, passés au rôle `user`, envoient chacun la
  commande d'adoption : rendement 0,85 et niveau neutre reçus par chacun.
- **C23** : cinq mesures réelles sur des cases différentes donnent de l'XP ; la
  sixième garde son résultat mais n'ajoute plus d'XP. Budget sauvegardé puis relu
  après redémarrage. Fenêtre glissante, indépendance entre joueurs et expiration
  vérifiées hors jeu. Les cinq points sont de l'XP de base, avant multiplicateurs.

## Résultats en jeu

| Mode / phase | Dossier local `runs/` | Résultat |
|---|---|---|
| SP création | `20261024-141057-sp-33a68c2e6191` | 15/15, sortie 0 |
| SP redémarrage | `20261024-141152-sp-ec9cf85b7200` | 7/7, sortie 0 |
| MP création, deux clients | `20261024-142813-mp-791ec0f6befa` | Serveur 14/14 ; chaque client 6/6 ; sortie 0 |
| MP redémarrage, deux clients | `20261024-143036-mp-b80e17c100be` | Serveur 8/8 ; chaque client 4/4 ; sortie 0 |
| SP général, sans captures (`shots=0`) | `20261024-143700-sp-aea74127a9dd` | 34/34, sortie 0 |
| MP de non-régression précédente, un client | `20261024-143845-mp-061a6762f362` | Serveur 14/14 ; client 7/7 ; sortie 0 |

Hors jeu : `check_mod.py` OK (Lua, chargement SP/client/serveur, traductions,
événements, versions), physique OK, simulation OK, régressions précédentes
**11/11**, nouveaux scénarios **14/14**. Les scripts Python et Lua du banc passent
leurs contrôles de syntaxe.

Les assertions de compte d'erreurs Lua ne signalent aucune nouvelle erreur
pendant les scénarios. Les journaux conservent des avertissements/erreurs vanilla
de chargement déjà présents (polices, zones et ressources de debug) ; ils ne sont
pas présentés comme absents. Les avertissements du mod sur la normalisation des
seuils et la destruction volontaire d'une tuile sont attendus par les scénarios.

## Défaut découvert et ajustements du banc

Le premier redémarrage SP a révélé un défaut réel de conservation des relais :
un cache de session vide pendant la première découverte asynchrone provoquait le
retrait d'un réservoir sauvegardé. `Pump.maintain` attend maintenant la fin de
cette première découverte avant de conclure qu'il n'existe plus de robinet.
Un scénario hors jeu et les redémarrages réels couvrent cette régression.

Deux premiers contrôles SP utilisaient mal le banc : `SandboxVars` n'est pas la
valeur prioritaire des options natives, et baisser le niveau debug d'une
compétence n'efface pas son XP accumulée. Les tests modifient maintenant les
options sandbox réelles et fixent l'XP au niveau testé.

Le premier contrôle client de C12 envoyait la pomme avant son rattrapage. Le
paquet vanilla `ItemStats` ne transporte pas l'âge (`ItemStatsPacket.java:170–214`).
Le test sérialise désormais l'objet après rattrapage, comme le contenu d'un chunk
envoyé après son chargement serveur. Aucun protocole de synchronisation d'âge
supplémentaire n'a été ajouté au mod.

L'ancien scénario général des frigos injectait directement son journal dans la
table publique. Il a été adapté à la nouvelle source privée avant sa relance
réussie ; le résultat attendu et les conditions alimentaires restent identiques.

La première relance MP copiait le monde sans recopier son fichier sandbox serveur.
Le nouveau processus reprenait donc `WaterShutModifier = 14` : les pompes retiraient
légitimement leurs relais au retour de l'eau publique. Le lanceur sauvegarde et
copie maintenant aussi ce fichier, puis vérifie le réglage au redémarrage. Les
fichiers de chunks et le registre avaient bien été sauvegardés ; ce défaut de
configuration du banc ne demandait aucune modification supplémentaire du mod.

Pour isoler les assertions de débit, le banc suspend les deux événements de
service automatiques puis appelle les vrais services de façon déterministe ;
les ticks de découverte restent actifs. Le réseau de pompe est sauvegardé éteint
pour qu'un remplissage légitime avant le démarrage des hooks ne fausse pas la
comparaison exacte de litres. Les tests généraux conservent les événements normaux.

## Relancer

Depuis la racine du projet, **séquentiellement**, en attendant la fin des deux
phases de chaque commande :

```powershell
python autotest/run_remaining.py sp
python autotest/run_remaining.py mp
python tools/check_mod.py <sources-42.21>
python tests/test_physics.py
python tests/test_simulation.py
python tests/test_regressions.py
python tests/test_remaining.py
```

Les rapports `runs/remaining-sp-latest.json` et `remaining-mp-latest.json` désignent
les dossiers de chaque phase. Comme pour C25, le pilote générique n'active
normalement que les hooks du premier client ; le lanceur active ceux du second
dans sa copie privée et exige aussi son fichier de résultat. L'outil partagé
reste inchangé. La reprise d'un personnage MP sauvegardé adapte uniquement le
pilote de cette copie pour reconnaître l'événement de connexion.

## Limites

Pas de mesure de FPS en charge d'un grand serveur, ni de validation manuelle du
rendu/son. Les contrôles vérifient les objets et états reçus en jeu, pas une
impression visuelle. C11 garde sa diffusion publique existante ; l'historique
privé C12 n'est jamais diffusé. Au-delà de 60 jours, l'état à la borne conservée
sert d'approximation ; une ancienne sauvegarde ne récupère pas les événements
déjà supprimés par les versions précédentes.
