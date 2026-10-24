# Live Wire — protocole de test

Build cible : 42.21. Protocole révisé le 2026-10-24.
Les résultats déjà obtenus et leurs limites figurent dans le
[bilan de validation](validation.md). Une étape décrite ici n'est pas une preuve
qu'elle a été exécutée sur toutes les plateformes ou avec tous les mods.

## Préparation

1. Utiliser une copie de sauvegarde ou un monde de test, avec le mod principal
   et son complément Viewpoint si ces scènes sont nécessaires. Ne pas modifier
   une sauvegarde de jeu habituelle ni les fichiers Workshop abonnés.
2. Relever la version dans le journal du processus et celle des sources vanilla
   utilisées pour les vérifications. Ne pas assimiler des sources 42.20 à 42.21.
3. Préparer un essai solo avec `-debug`, puis un serveur dédié avec deux clients,
   dont au moins un utilisateur ordinaire. Noter le système du serveur et les
   mods activés. Linux constitue une validation distincte de Windows.
4. Donner le kit par le menu debug Live Wire, du fil électrique, un tournevis,
   des batteries de voiture et un tuyau par réserve d'eau. Préparer un personnage
   de niveau suffisant et un autre de bas niveau pour les refus de compétence.
5. Enregistrer les options sandbox, les journaux et les étapes. Tester les
   commandes du joueur avec son rôle ordinaire, même si la préparation est admin.

## Vérifications hors jeu

Depuis la racine du dépôt, avec Python et les dépendances de l'outillage installés :

```powershell
python tools/check_mod.py <sources-42.21>
python tests/test_physics.py
python tests/test_simulation.py
python tests/test_regressions.py
python tests/test_remaining.py
```

`<sources-42.21>` désigne la racine des sources de référence, contenant `java/`
et `media/`. Ces contrôles couvrent syntaxe, ressources, traductions, contrats
et scénarios simulés ; ils ne remplacent pas l'exécution des API Java du jeu.

## Campagnes automatisées en jeu

Les hooks et profils sont versionnés dans `autotest/` et `autotest.json`.
Les lanceurs dépendent de l'outil externe **pz-autotest**, attendu dans
`../.claude/tools/pz-autotest/` ; cet outil n'est pas fourni par ce dépôt.
Ils utilisent des caches et des copies de mondes dédiés aux essais.

Depuis la racine du projet, lancer les commandes **une par une**, en attendant
la fin complète de chaque campagne, y compris ses redémarrages :

```powershell
python autotest/run_c25.py sp
python autotest/run_c25.py mp
python autotest/run_remaining.py sp
python autotest/run_remaining.py mp
```

- `run_c25.py` : création, sauvegarde, vrai redémarrage, retrait chargé et hors
  zone, retour puis dernier redémarrage. Trois phases par mode, deux clients MP.
- `run_remaining.py` : attribution des relais, débit, seuils du secours, épuisement
  partiel, historique alimentaire, niveaux de chunk, XP et adoption. Création
  puis redémarrage ; deux clients MP, résultats exigés pour chacun.

Pour les campagnes générales et les profils complémentaires, depuis le dossier
parent du dépôt :

```powershell
python .claude/tools/pz-autotest/pz_autotest.py check LiveWire
python .claude/tools/pz-autotest/pz_autotest.py sp LiveWire --wait-idle 3600
python .claude/tools/pz-autotest/pz_autotest.py mp LiveWire --clients 1 --wait-idle 3600
python .claude/tools/pz-autotest/pz_autotest.py sp LiveWire/autotest/fixes.json --wait-idle 3600
python .claude/tools/pz-autotest/pz_autotest.py mp LiveWire/autotest/fixes.json --wait-idle 3600
```

Le profil général couvre pose, menus, raccordement, protections, batteries,
alarmes, rotation, ramassage, vieillissement, pompe et couplage. Le profil MP
vérifie aussi les commandes depuis l'ordinateur raccordé. `fixes.json` couvre
les budgets de découverte, marques, cache, secours manuel et permissions.
Un point d'eau absent peut provoquer un `SKIP` dans le profil général : ce cas
ne compte pas comme réussite. Le bilan indique le périmètre de chaque passage.

## Contrôles fonctionnels et manuels

| Domaine | Manipulation | Résultat attendu |
|---|---|---|
| Alimentation | Après coupure du réseau public, raccorder des sources à l'onduleur ; allumer et éteindre | Éclairage et appareils suivent l'état ; aucune toxicité de l'ancre |
| Placement | Poser dehors/dedans selon le type, tourner, ramasser et reposer | Contraintes affichées ; rotation conserve les liens ; ramassage détache et conserve l'état |
| Batteries | Ajouter, charger, retirer ; dépasser quatre batteries ; ramasser une powerbank pleine | Quatre batteries actives au plus ; charge conservée ; ramassage refusé par le conteneur vanilla |
| Absence | Quitter la zone avec un stock suffisant, puis insuffisant ; revenir | Énergie et date de coupure cohérentes ; âge des aliments rattrapé selon l'historique disponible |
| Serveur vide | Désactiver `PauseEmpty`, déconnecter tous les joueurs, puis revenir | Simulation et persistance cohérentes sans client connecté |
| Surcharge | Dépasser la puissance, avec puis sans disjoncteur ; réarmer au bon appareil | Disjoncteur protège l'onduleur ; sans protection, disjonction et perte d'état |
| Secours | Passer sous le seuil, recharger, arrêter manuellement, reprendre l'automatisme ; quitter/revenir | Hystérésis effective ; choix manuel conservé ; carburant sans double décompte |
| Actions et droits | Inspecter, déneiger, freiner, adopter, réparer avec rôles et safehouses différents | Contrôles revérifiés sur le serveur ; pas d'effet refusé ni d'XP supplémentaire après le plafond |
| Logiciel | Ouvrir depuis ordinateur raccordé, renommer, commander ; essayer une fausse position | Commandes valides synchronisées ; accès invalide refusé |
| Recouvrement | Poser plusieurs réseaux et un générateur vanilla | Attribution déterministe ; demande et alimentation conformes aux règles du profil choisi |
| Consommation | Comparer les quatre profils et plusieurs appareils allumés/éteints | État natif respecté, puissance du profil affichée, limites d'onduleur inchangées |

### Pompe et relais

1. Couper l'eau publique ; raccorder une pompe, une réserve d'au moins 20 L et
   un point d'eau admissible. Vérifier la découverte progressive et le transfert
   réel, limité à 5 L/min de service. Une réserve vide reste liée.
2. Vérifier la priorité d'une source vanilla et le refus des fluides autres que
   l'eau. Comparer réserve, relais et consommation sans duplication de fluide.
3. Ajouter une pompe plus proche ; vérifier le transfert de propriété du même
   relais, sans perte d'eau. Retirer la pompe ou le baril et vérifier le repli.
4. Sauvegarder avec un relais rempli, fermer le jeu et relancer. Contrôler eau,
   capacité, propriétaire et absence de doublon pendant la première découverte.
5. Tester le retrait global des relais chargés, puis déchargés. Revenir et
   redémarrer : les orphelins disparaissent et ne sont pas recréés après désactivation.
6. En MP, contrôler les mêmes objets chez les deux clients. Observer aussi
   invisibilité, passage, surbrillances et absence d'interaction de démontage.

### Onduleurs couplés

1. Coupler un esclave admissible avec le kit et le fil ; vérifier la capacité
   active, la veille et l'interface du maître. Essayer les configurations interdites.
2. Éteindre puis rallumer l'esclave ; vérifier la puissance disponible et la
   synchronisation. Découpler : kit rendu, fil consommé conservé.
3. Retirer le maître : esclaves libérés sans membres. Recharger la sauvegarde
   et vérifier les identifiants, liens et capacités chez les deux clients.

### Rendu et son

Observer les quatre orientations, les objets muraux, les calques animés, la zone
alimentée et les effets du zoom. Écouter alarme, pompe et onduleur, puis tester
l'arrêt, l'éloignement et la reconnexion du second client. Vérifier l'absence de
son fantôme. Ces observations restent distinctes des assertions de texture ou
d'état. Le réglage du bruit de l'onduleur C20 reste hors de la campagne de correctifs.

## Résultats à conserver

Pour chaque passage : version, plateforme, profils, options, rôles, résultat par
processus et scénario, `SKIP`, nouvelles erreurs et limites. Les sorties locales
sont dans `runs/<identifiant>/summary.txt` et les fichiers `result.txt` associés ;
`runs/` reste ignoré par Git. Les lanceurs multi-phases écrivent aussi un rapport
`*-latest.json`.

Publier un bilan synthétique avec les conditions de reproduction et les limites,
sans journaux bruts, caches ni chemins personnels. Une simulation hors jeu,
une assertion automatique en jeu et une observation manuelle doivent rester
explicitement distinguées.
