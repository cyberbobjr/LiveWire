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

## Campagne locale IXX après v1.5.0

Lanceurs : `python autotest/run_ixx.py sp` puis `python autotest/run_ixx.py mp`.
Chaque campagne crée une copie privée de monde, puis redémarre complètement les
processus et reconnecte les personnages sauvegardés. MP : deux vrais clients
ordinaires, commandes du tableau depuis la GUI, actions natives de diagnostic et
reconditionnement, vérifications sur l'autorité et chaque observateur. Les outils
de test seuls injectent une batterie d'extension réelle dans les copies temporaires.

Vérifier orientation, entretien avec dépense d'eau, froid extérieur/dégel,
réparation morte et chargée, cycles/coûts/plafonds, démontage unique, refus par
compétence/refuge, risque électrique, frein et avertissement d'orage, API fermée et
lectures détachées. Le scénario coupe et rétablit l'éclairage natif sans couper
le frigo, puis le principal en contrôlant le vrai `isPowered()` du frigo. Le
réseau public est coupé dans les trois processus du monde de test ; une édition
directe des options serveur après connexion n'est pas diffusée automatiquement.

Conserver aussi les régressions CXX : `run_remaining.py sp/mp`, `run_c25.py sp/mp`.
Hors jeu : `check_mod.py`, les cinq suites demandées et `tests/test_features.py`.
Ces dernières couvrent les petites écritures d'énergie successives, les arrondis
natifs, les modifications externes de batterie et le propriétaire des lumières
en chevauchement. Elles ne remplacent pas les assertions du vrai moteur.

Pour I21 : `python autotest/run_ixx.py sp --suite appliances`, puis `mp --suite appliances`.
Les vrais appareils sont créés avec leurs conteneurs et réglages **avant** l'envoi
aux clients. Les deux clients sont rétrogradés en utilisateurs ordinaires après
la connexion de debug. Vérifier TV/radio sur secteur et pile, appareils déjà
éteints, lavage/séchage simple, combiné et superposé, cuisson/micro-ondes, chargeur,
frigo/congélateur et distribution de carburant. Observer service et watts, refuser
les transferts génériques de fluides B42 ainsi que le remplissage direct d'un
récipient depuis une pompe coupée ; conserver les stocks et vérifier leur reprise.
Puis refuser
les actions natives pendant la coupure, vérifier les deux combinaisons croisées
et les deux circuits coupés, puis sauvegarder coupé, redémarrer tous les processus,
reconnecter et rétablir. Les clients doivent aussi constater le rétablissement
des services et le maintien des appareils initialement éteints.

Mesurer aussi l'entretien autoritaire pendant une coupure : enveloppes de mesure
temporaires du banc, nombre d'entrées par créneau, écart entre créneaux, temps
cumulé et maximum du rappel. Forcer un setter natif en contournant volontairement
l'action joueur doit être corrigé par cet entretien. Les tests hors jeu à horloge
contrôlée vérifient les limites (20 ms pour les travaux explicites, 100 ms pour
l'entretien seul, 16 unités, arrêt après le budget de temps),
l'absence de rattrapage en rafale, le parcours complet de 5 000 entrées, l'arrêt
après rétablissement et zéro visite sans travail. La mesure en jeu est une courte
observation Windows du banc, pas une validation de charge ni un benchmark de FPS.

Le rattrapage alimentaire est testé sur un vrai aliment et une chronologie connue
du circuit sans changement d'ancre. L'appel explicite du gestionnaire de chunk est
identifié comme tel ; il ne prouve pas à lui seul un vrai déchargement de zone.
Voir [les preuves moteur et la portée des catégories](../recherches/circuits-42-21.md).
`python autotest/run_ixx.py sp --suite scope` ajoute un vrai déchargement/rechargement
de zone et les changements de propriétaire, couplage/découplage et retrait d'un
maître en recouvrement ; puis redémarre le monde sauvegardé avec son circuit coupé.
Les captures permettent une revue du dessin ; les assertions ne jugent pas le son
ni le confort visuel. Aucune exécution Windows n'établit une validation Linux.

Mémoire : `python tests/test_memory.py` contrôle les durées de vie sous Lua 5.1,
avec références faibles de test pour vérifier la libération des anciens objets.
`python autotest/run_ixx.py sp --suite memory`, puis `mp --suite memory`, exécute
par processus 100 cycles de chauffe puis trois blocs : 500 coupures/rétablissements
internes sur l'autorité, 200 ouvertures/fermetures de la GUI sur chaque client.
Contrôler l'identité des conteneurs, le journal borné, les caches abandonnés, les
abonnements de réseaux supprimés, le plafond de 64 instantanés, leur effacement
et l'absence d'anciens tableaux dans le gestionnaire UI natif.

Le banc seul force le GC et relève le tas JVM après chauffe et entre blocs.
`collectgarbage("count")` mesure ici le tas JVM complet, pas seulement Lua.
Ces relevés courts sont des observations, sans seuil arbitraire ni affirmation
d'absence générale de fuite. Ils ne mesurent pas les allocations natives/GPU,
ne remplacent pas une analyse de tas par chemins de rétention ni un essai de
plusieurs heures. Aucun GC forcé n'est ajouté au mod livré. Le scénario de portée
contrôle aussi la purge après un vrai déchargement et la reconstruction au retour.


## Complément interface : clic, banque, raccordements, consommateurs

Banc préparé : `python autotest/run_ixx.py sp --suite interface`, puis
`python autotest/run_ixx.py mp --suite interface`. Copies de mondes uniquement,
redémarrage entre create/reload, deux clients ordinaires en MP, attente d'un jeu
libre. Le banc doit rapporter son code de sortie et le dossier de résultats avant
qu'un passage puisse être annoncé comme exécuté.

Le banc vérifie les API réelles des panneaux, l'ouverture par appel du gestionnaire
de clic, une lecture de banque indépendante, le raccordement par action native,
les fils consommés, la réception sur deux clients, les lectures sans création
d'énergie, la persistance et la libération des panneaux. Une lumière native créée
localement sert de fixture de teinte ; ce n'est pas une preuve du placement naturel
d'un luminaire ni d'un vrai clic physique.

À compléter manuellement : cliquer les différentes orientations, notamment les
objets muraux ; visée/construction/obstacle/refuge ; ouvrir une banque vide, remplie,
froide, avec batterie morte et excédents ; déplacer une batterie pendant la lecture ;
changer d'onduleur, fils insuffisants, option déjà présente, débrancher/raccorder ;
monter d'étage, décharger/recharger les zones, reconnexion ; masquer les consommateurs
et contrôler lampes au sol, interrupteurs et plafonniers, zoom et autres surbrillances.
Aucun test Windows ne valide Linux ; ne pas confondre appel du gestionnaire et
interaction physique de souris.


## Powerbanks superposées — essais manuels

Redémarrer complètement le jeu pour charger les propriétés des tuiles.

1. Poser une banque, puis une seconde sur la même case ; contrôler le fantôme en
   hauteur et les quatre orientations. Essayer une troisième : refus sans retrait
   de l'objet d'inventaire. Essayer au-dessus d'une caisse : refus explicite.
2. Placer des batteries de charges différentes dans les deux conteneurs. Le LCD
   doit afficher les contenus séparément et le bouton Banque 1/2 ou 2/2 doit aussi
   sélectionner le bon conteneur dans la fenêtre de butin.
3. Raccorder les deux à l'onduleur, vérifier les lignes distinctes dans le panneau
   de raccordement, la capacité totale et l'évolution des charges. Aucune batterie
   supplémentaire créée, aucune copie d'un contenu entre les conteneurs.
4. Essayer de retirer, tourner ou recycler la banque inférieure : refus tant qu'une
   autre unité ou un objet repose dessus. La banque supérieure pleine doit conserver
   le refus vanilla de déplacement ; la vider, la tourner, puis la ramasser.
5. Après retrait de la supérieure, vérifier que l'inférieure garde ses contenus,
   charge et raccordement. Ajouter une banque neuve : nouvelle unité vide.
6. Sauvegarder avec deux banques raccordées, quitter complètement, relancer, puis
   refaire les contrôles d'identité, position, contenu et charge. Répéter en MP avec
   deux clients ordinaires, y compris refus de refuge, deux poses concurrentes,
   déconnexion/reconnexion et rechargement de zone.
7. Refaire le premier ajout sur une banque provenant d'une sauvegarde antérieure :
   ses batteries, son identifiant et son raccordement doivent être conservés.

Banc hors jeu : `python tests/test_stacking.py --vanilla <media/lua/shared/Moveables/ISMoveableSpriteProps.lua>`.
Il exécute les règles et le Lua vanilla installé sous des stubs ; ce n'est pas un
passage du vrai moteur, ni une validation du rendu ou de Linux.

## Butin d'équipements configurable (F31)

Contrôle hors jeu : `python tests/test_loot.py --vanilla-dir <media/lua/server/Items>`.
Le test charge les distributions installées et les scripts du mod sous Lua 5.1 ;
ce n'est pas un test du tirage Java ou une partie réelle.

Essais manuels sur mondes de test :

1. Créer une partie avec le défaut 5, puis avec 1 et 20. Vérifier le texte de
   l'option et sa sauvegarde ; redémarrer complètement entre réglages.
2. Explorer des zones neuves de quincaillerie, d'électronique, d'entrepôt et de
   mécanique, ainsi que du matériel de camping pour les batteries. Relever les
   types de rangements et plusieurs échantillons, pas un conteneur unique.
3. Avec le débogueur, contrôler les poids Java après démarrage : ×5 sur les
   équipements et cellules LiveWire, poids vanilla et CD inchangés,
   pas de doublons ; répéter
   après sauvegarde et rechargement et avec une ancienne partie sans option.
4. Revenir aux conteneurs déjà fouillés : aucun remplissage immédiat. Si la
   réapparition vanilla est activée, contrôler un vrai nouveau tirage selon ses
   règles, sans accélération ou remplissage forcé du mod.
5. Sur serveur dédié, régler 5 puis 20 côté serveur et redémarrer. Deux clients,
   dont un joueur ordinaire, voient le même contenu ; reconnexion et redémarrage
   conservent les objets obtenus sans nouvelle distribution ou duplication.
6. Vérifier qu'un réglage local du client ne pilote pas le butin du serveur et
   que le CD conditionnel au Computer Mod, les recettes et toutes les entrées
   vanilla restent inchangés, y compris fils, amplificateurs et autres composants
   dans les catégories techniques. Aucun objet vanilla ne doit être ajouté.
   Les règles vanilla de rareté restent applicables.

Les essais Windows ne valent pas validation d'un serveur Linux. Essais en jeu
manuels conformément au choix utilisateur ; ne pas lancer une partie automatique.

## F32 — composants, démontage et pose des sources

Contrôles hors jeu : `tests/test_crafting.py --vanilla <ISMoveableSpriteProps.lua>`
et `tests/test_loot.py --vanilla-dir <media/lua/server/Items>`. Ce sont des bancs
Lua sous environnement simulé et des contrôles de données, pas des parties réelles.

Essais manuels sur monde de test, après redémarrage complet :

1. Joueur ordinaire niveau 0 : pales/mât possibles avec outils et matériaux ;
   outils conservés, matières consommées. Deux XP d'Électricité par recette de pales ou mât.
2. Niveau 5 : assemblage éolienne refusé ; niveau 6 accepté. Roue refusée à 6,
   acceptée à 7. Les deux recettes demandent deux amplificateurs, sans haut-parleur direct.
3. Démonter un haut-parleur par la recette vanilla : un amplificateur et un
   déchet, haut-parleur retiré, tournevis conservé. Tester interruption, matières
   manquantes et double demande ; pas de duplication. CD, télécommande et alarme
   vanilla : résultats précédents conservés. Vérifier les icônes de toutes les
   recettes et les sorties après création, y compris sept équipements corrigés.
4. Pose et ramassage aux niveaux 1 puis 2, quatre orientations des deux machines.
   Vérifier refus à 1, réussite à 2, soleil/vent/berge et collisions habituelles.
   Éolienne intérieure et roue éloignée d'une rivière restent refusées.
5. Butin en nouvelles zones : pales, mâts et deux machines complètes,
   option ×1/×5/×20. Aucune modification des poids d'objets vanilla ni remplissage
   des conteneurs déjà fouillés.
6. Sauvegarde/redémarrage complet : anciens appareils et nouvelles pièces conservés.
   Sur serveur dédié Windows avec deux clients dont un ordinaire : commandes
   concurrentes sur les mêmes matières, refus serveur, synchronisation des sorties,
   reconnexion et redémarrage sans doublon. Aucun résultat Windows ne valide Linux.

Ne pas lancer de jeu automatiquement : essais manuels choisis par l'utilisateur.

### Démontage du testeur de tension

Sur un monde de test, en solo puis avec deux clients dont un ordinaire :
fabriquer ou trouver un testeur, ouvrir la recette « Démonter un testeur de
tension », vérifier qu'un tournevis en état est requis, puis lancer au niveau 0.
Attendu : un testeur en moins, un déchet électronique en plus, tournevis conservé.
Tester annulation avant fin et deux actions concurrentes sur le même testeur :
pas de gain ni de double sortie. Vérifier synchronisation, sauvegarde et reconnexion.

### Wattmètre LCD du tableau

Sur monde de test solo puis serveur dédié avec deux clients, dont un ordinaire :

1. Réseau alimenté avec éclairage, frigo/TV et pompe remplissant un réservoir :
   vérifier les deux lignes et total = somme. Veille et charge des batteries exclues.
2. Quatre combinaisons de circuits : les appareils concernés s'arrêtent et leurs
   watts baissent ; une ligne sans charge coupée affiche « 0 W / coupé ». Vérifier
   les choix individuels au rétablissement et les consommations après mesure.
3. Principal coupé, surcharge, onduleur arrêté et batteries vides : total zéro ;
   réarmement et production/charge conservent leurs comportements existants.
4. Fermer, quitter entièrement la zone, revenir et rouvrir : aucune ancienne valeur
   présentée comme fraîche ; tirets/Actualisation jusqu'à nouvelle mesure, puis
   valeurs cohérentes. Refaire après sauvegarde/redémarrage et reconnexion client.
5. Couplage : relevé du maître ; chevauchement : consommation comptée une fois,
   y compris une charge possédée par un autre tableau mais alimentée par ce réseau.
6. FR/EN et une langue CJK, tailles de police usuelles : libellés lisibles, valeurs
   et état non superposés, aucune erreur console à l'ouverture ou après attente.

Choix utilisateur conservé : aucun lancement de jeu automatique. Les previews
hors jeu et les doubles Lua ne valident ni le rendu moteur ni SP/MP ou Linux.
Un testeur coûte un déchet, un fil, une ampoule et une pile à fabriquer ; le
démontage ne rend que le déchet. Contrôles hors jeu distincts des essais réels.

### Risque sous tension révisé et expérience

Sur monde de test, solo puis serveur dédié avec deux clients dont un ordinaire :

1. Activer Risque sous tension. Personnage réel d'Électricité 0 : forcer un tirage
   favorable au choc dans un scénario de test, puis un tirage hors seuil ; ne pas
   annoncer 50 % depuis quelques tentatives manuelles. Vérifier séparément 0–6.
2. Raccorder/débrancher/réparer/démonter un appareil raccordé : tester tournevis en
   primaire, secondaire seule, les deux mains et inventaire. Brûlure de la main
   choisie, douleur, lâcher, journal, même blessure visible après reconnexion ;
   aucune matière/XP de réparation ni modification d'appareil en cas de choc.
3. Principal et deux circuits coupés, stock vide, onduleur tripped/broken : risque
   encore présent. Maître explicitement off : pas de choc. Option désactivée et
   compétence ≥6 : pas de choc. Arrêt du cassé proposé dans LCD et menu, état
   matériel inchangé, aucune charge tant que sa condition est nulle.
4. Débranchement sans tournevis, trop loin ou refuge interdit : refus avant
   tirage, sans blessure ni mutation. Un client ne décide jamais sa probabilité
   ou sa main blessée. Interrompre volontairement l'action avant la fin.
5. Réparation réussie : XP selon état gagné ; action refusée/choc : pas d'XP de
   réparation. Fabriquer pales puis mât : 2 XP par recette ; vérifier un autre
   craftRecipe, niveaux/couts/durées et outils conservés ; sauvegarde/reconnexion.

Les bancs Lua n'attestent pas du rendu d'animation, des dégâts natifs ou de la
synchronisation réelle. Tests en jeu manuels selon le choix de l'utilisateur.


## Menus et usure de debug — test manuel

1. Solo `-debug` : chaque modèle LiveWire, raccordé puis indépendant. Vérifier une
   seule entrée par écran, accès correct aux LCD/tableau/raccordements ; onduleur
   couplé vers maître, deux banques superposées chacune indépendante.
2. Debug sur l'appareil : −10, 50 %, 10 %, 0 %, 100 %. À 0, vérifier panne/arrêt
   de production et entretien/démontage ; restauration d'un onduleur cassé à off.
   Vérifier état/charge/cycles des batteries, inventaire et raccordements inchangés
   directement ; seule la simulation normale peut ensuite évoluer.
3. MP deux clients : admin autorisé, utilisateur ordinaire sans menu ; commande
   forgée refusée. Distance/refuge/objet retiré entre ouverture et clic : refus.
   Observer la synchronisation, reconnexion et redémarrage complet sur monde test.
4. Nouveau monde : Risque sous tension coché. Monde existant explicitement à faux :
   faux conservé ; après activation, interventions avec maître allumé à niveau 0
   puis 6, et maître off à niveau 0. Principal seul coupé : danger conservé.

Ces étapes sont à exécuter manuellement ; les doubles Lua ne prouvent ni le rendu,
ni la synchronisation réelle, ni une sauvegarde/reconnexion dans le moteur.


### État des équipements dans les écrans

Sur monde test, comparer chaque état affiché avec Inspection ; abîmer/restaurer
en debug pendant que le panneau est ouvert. Banque à 10 % avec batterie à 80 %
et charge à 50 % : trois valeurs distinctes. Répéter avec deux banques empilées,
sans raccordement, à 0 %, tableau mort et autre disjoncteur du même réseau.
Tester Raccordements sur sources, pompe et alarme, avec et sans onduleur proche.
Vérifier police agrandie, dix langues, puis client MP ordinaire après modification
admin, reconnexion et retour de zone. Tests manuels à effectuer, non revendiqués.

### Fermeture des fenêtres

Ouvrir puis fermer par la croix le tableau, le LCD powerbank et Raccordements,
plusieurs fois, raccordé et indépendant. Refaire en s'éloignant pour provoquer
la fermeture automatique. Fermer puis rouvrir immédiatement une autre powerbank,
notamment superposée : ses données doivent rester présentes. Aucun nouveau message
`LW_BreakerPanel.prerender` ou autre erreur de panneau dans la console ; répéter
sur client MP. Protocole manuel, non exécuté automatiquement.


### LCD individuels et raccordement ciblé

1. Cliquer chaque source, pompe et alarme : son LCD, jamais la liste globale.
   Vérifier état, zéro quand non raccordé/cassé, vent freiné, neige/saleté ; comparer
   les watts au relevé de la même source dans l'onduleur/logiciel. Pompe : son
   propre débit et ses watts ; deux pompes avec débits différents ne se mélangent pas.
2. Chaque bouton Raccordements cible l'appareil d'origine ; choisir entre deux
   onduleurs et raccorder/débrancher avec coûts et déplacement. Autre réseau :
   aucun transfert implicite. Aucun onduleur à portée : boutons indisponibles.
   Depuis un onduleur, retrouver la liste complète et gérer plusieurs équipements.
3. Circuit équipements/principal coupé, onduleur arrêté/disjoncté, pompe cassée :
   débit et watts de service nuls. Lire plusieurs fois ne déplace pas d'eau et ne
   crée pas d'énergie. Comparer avant/après connexion sans rouvrir le LCD.
4. SP puis MP admin et utilisateur ordinaire : visibilité et refus de refuge,
   distance et objet retiré. Fermetures répétées, éloignement, réouverture rapide,
   perte réseau et réponses tardives sans erreur. Déconnexion/menu libèrent la vue.
5. Retour de zone, sauvegarde/redémarrage/reconnexion : mêmes appareils et liens ;
   nouveau relevé de l'appareil courant. Polices agrandies et dix langues : pas
   de dernière ligne cachée, textes et bouton accessibles.

Scénarios moteur à effectuer manuellement, non prouvés par les doubles Lua.


### Couleurs des LCD et voyants posés

Vérifier en SP puis MP (utilisateur ordinaire), après redémarrage complet :
pompe avec LCD bleu et texte « Débit d'eau » ; voyant bleu sur ses quatre faces
si alimentée, même sans baril/relais. Coupure équipements ou principal, onduleur
off/tripped/broken, stock épuisé, pompe cassée/débranchée : voyant éteint. Coupure
lumières seule : bleu conservé. Le débit réel reste indépendant du voyant.

Tableau sur ses deux murs : vert si distribution alimentée ; deux circuits
ouverts seuls : vert conservé ; principal coupé/hors courant/cassé/débranché :
éteint ; surcharge : rouge prioritaire. Vérifier réarmement, reconnexion, retour
de zone et redémarrage, ainsi que le mod Viewpoint. Les anciennes tuiles doivent
rester identiques. Aucun test moteur revendiqué par les comparaisons d'images.

## Revue complémentaire : points 1 à 7

À confirmer dans le vrai moteur 42.21, en solo puis avec deux clients MP :

1. Sauvegarder les équipements coupés, redémarrer, puis retirer le maître rapidement,
   avant ouverture d'un écran. Attendre la fin du traitement progressif : frigo et
   congélateur retrouvent leur type et leur service selon le courant disponible.
   Refaire après départ/retour de zone ; aucun contenu d'inventaire ne change.
2. Sur une machine superposée, allumer seulement le sèche-linge. Couper équipements,
   puis principal ; rétablir équipements avant principal. Le sèche-linge attend le
   courant et repart ensuite ; le lave-linge reste arrêté. Vérifier aussi plusieurs
   interrupteurs d'une même pièce et une radio passée sur pile pendant la coupure.
3. Pendant que le client 2 rejoint ou charge la zone, le client 1 coupe puis rétablit
   les équipements. Après réception et lecture de réconciliation, types des frigos
   et états TV/radio concordent avec le serveur. Vérifier deux appareils de même
   sprite sur une case, changement manuel de radio, déconnexion et reconnexion.
   Les identifiants et contenus des inventaires clients doivent rester intacts.
4. Sur une grande installation, changer plusieurs fois les circuits puis attendre
   leur dernier choix. Contrôler traitement progressif, mesure en attente puis
   actualisée, et reprise des appareils malgré retrait du maître. Mesurer les
   pointes réelles ; les bornes hors jeu ne sont pas une preuve de gain de FPS.
5. Dans le logiciel, changer d'onglet et de page, recevoir une nouvelle mesure,
   fermer et rouvrir. Textes et puissances restent actualisés. Vérifier une action
   vanilla voisine : interrupteur, frigo, cuisson, lavage et radio sur pile.

Contrôles hors jeu : `python -B tests/test_review_fixes.py`, puis suites et contrôle
statique consignés dans le bilan. Aucun de ces essais manuels n'est revendiqué
par les résultats du 2026-10-25.

## Portée verticale des câbles — 1.6.2

Contrôles hors jeu : `python -B tests/test_link_range.py` et
`python -B tests/test_menus_debug.py`. Couvrent les bornes, les deux sens verticaux,
la lecture du réglage courant, les menus, le couplage, le coût horizontal et le
refus de l'action avant consommation si la limite change.

Scénario ciblé en jeu, depuis le dossier Workshop parent :

```powershell
python .claude/tools/pz-autotest/pz_autotest.py sp LiveWire -P vertical=1 -P shots=0 --no-screenshot --wait-idle 3600
```

Crée des plateformes dans la copie jetable du monde et utilise les objets réels
et `LWLinkAction:complete` : raccordement à +2 et +3 étages, refus à +4 sans coût,
découverte dans les deux sens, baisse à 1 sans perte des liaisons existantes,
hausse à 4 puis limite à 0. Vérifie le défaut 3 et les bornes sandbox 0–10.
Les polices et le rendu des libellés traduits restent un contrôle manuel.
