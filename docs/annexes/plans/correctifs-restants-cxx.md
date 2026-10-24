# Correctifs CXX restants — 2026-10-24

## Périmètre autorisé

Demande utilisateur : réaliser tous les correctifs CXX restants, sauf C20, mettre
à jour le suivi et tester en solo puis en multijoueur. Les idées IXX sont exclues
et attendent un ordre distinct. L'utilisateur a confirmé le maintien du report de
C11 : diffusion communautaire conservée.

Architecture conservée : modules événementiels à serveur autoritaire, validés
dans `../../architecture.md` et `../../developpement.md`. Aucune migration de
pattern. Registre et persistance sur le serveur ; formules sans API dans Physics ;
pompage dans Pump ; expérience dans Xp ; présentation seule côté client.

## Étapes et critères

1. **C19, C17** : nettoyer les relais sur les niveaux réels du chunk ; normaliser
   l'hystérésis du secours avec cinq points d'écart, avertissement unique et
   infobulles traduites. Tester niveaux extrêmes et seuils inversés/valides.
2. **C08, C18** : choisir la pompe raccordée la plus proche de chaque point d'eau,
   départager par identifiant, transférer la propriété sans perdre l'eau ni créer
   de doublon ; ne pas accumuler de débit au repos. Préserver les sources vanilla
   et les parcours de découverte bornés. Tester chevauchement, retrait et reprise.
3. **C21, C12** : servir la fraction du pas couverte par le stock puis dater la
   coupure ; conserver un historique serveur de 60 jours de jeu pour le rattrapage
   des aliments. Le journal public reste limité à 16 changements, sans augmentation
   de sa fréquence de diffusion. Reprendre les anciennes données sans inventer
   l'historique perdu. Tester conservation de l'énergie, temps de coupure,
   alternances au-delà de 16 événements, rétention et redémarrage.
4. **C24, C23** : restaurer une marque depuis le registre si la tuile existe encore,
   adopter avec rendement indépendant du déclarant ; limiter les mesures à cinq
   gains d'XP de base par heure de jeu et par joueur, toutes cases confondues.
   Tester disparition réelle, marque effacée/altérée, adoption et plafond global.
5. **Validation** : contrôles de syntaxe/contrats/traductions, scénarios hors jeu,
   campagnes réelles Build 42.21 SP et serveur dédié/clients MP sur copies privées,
   redémarrage pour les données persistantes. Relire les nouvelles erreurs.
6. **Documentation** : mettre à jour les statuts CXX, les contrats modifiés et les
   limites de validation. Commits locaux cohérents ; aucune publication Workshop.

## Résultats

Les huit points sont réalisés. Contrôles hors jeu : physique et simulation OK,
régressions précédentes 11/11, nouveaux scénarios 14/14, contrats/traductions OK.
En jeu 42.21 : SP 15/15 puis 7/7 après redémarrage ; MP deux clients, serveur
14/14 puis 8/8 après redémarrage, chaque client 6/6 puis 4/4. Sorties 0.
Non-régression générale : SP sans captures 34/34 ; MP de la campagne précédente,
14/14 serveur et 7/7 client, sorties 0.

Le redémarrage SP a révélé puis couvert une régression supplémentaire : les
relais sauvegardés sont désormais conservés pendant la première découverte
asynchrone. Les premiers échecs et ajustements du banc, ainsi que les chemins de
résultats, sont détaillés dans la [validation](../tests/correctifs-restants-cxx.md).
Les impressions visuelles, le son et les FPS d'un grand serveur restent distincts
de ces assertions d'objets et de synchronisation. C11 reste différé ; C20 et IXX
ne sont pas implémentés dans cette campagne.
