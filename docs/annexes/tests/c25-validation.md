# C25 — persistance, invisibilité et retrait des relais

Campagne autorisée le 2026-10-24. C13, C14, C26 et C15 seront traités ensuite, dans
cet ordre, selon la demande complémentaire. Architecture modulaire autoritaire
conservée ; aucun changement de pattern.

## Protocole automatisé

`autotest/run_c25.py sp` puis `autotest/run_c25.py mp`, depuis la racine du projet.
Le lanceur réutilise les services de `pz-autotest`, sans modifier cet outil :

1. Copier la sauvegarde SP ou créer un serveur de test ; créer un relais sur une
   case `z + 1` qui n'existait pas, lui donner 7,25 L et enregistrer son propriétaire.
2. Fermer le vrai processus, copier le monde ainsi sauvegardé dans un nouveau cache
   et relancer le jeu. Vérifier capacité, eau, propriétaire et absence de doublon.
3. Exécuter la vraie commande C01 sur un relais chargé ; vérifier sa disparition
   côté client. Recréer un relais, éloigner tous les joueurs, attendre que la case
   soit réellement absente de la cellule serveur, puis exécuter C01 hors zone.
4. Revenir : le vrai événement `LoadChunk` doit retirer l'orphelin sauvegardé.
   La pompe désactivée ne doit pas le recréer.
5. Fermer et relancer encore une fois ; vérifier la persistance de la désactivation
   et l'absence de relais sur l'autorité et chez les clients.

En MP, deux clients exécutent les assertions et le serveur attend leurs accusés
avant chaque transition. Les droits ordinaires et les refus de safehouse restent
couverts par `autotest/fixes.json` (campagne du plan précédent).

## Invisibilité

Le générateur de sprites produit une case entièrement transparente pour le relais ;
`pzforge.sheet` omet les cellules vides de l'atlas. Dans le jeu, le sprite de relais
existe mais sa texture est nulle. Le rendu vanilla sort immédiatement dans ce cas
(`IsoSprite.java:854-856`, sources 42.21.0). Le test client vérifie ce résultat en
gardant la texture visible de la pompe comme témoin de chargement du pack. Si une
texture de relais existe, son masque doit être entièrement transparent. Les gardes
de passage et d'interdiction de démontage sont également vérifiées.

## Résultats

Les **trois phases SP et les trois phases MP sont réussies**, code de sortie 0,
runtime **42.21** ; JAR installé identique aux sources décompilées 42.21.0
(`e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33`).

| Mode / phase | Autorité | Client 1 | Client 2 | Résumé dans `runs/` |
|---|---|---|---|---|
| SP création | 8/8 (rapport commun) | — | — | `20261024-123143-sp-37c79f1e8685` |
| SP rechargement et retrait | 14/14 (rapport commun) | — | — | `20261024-123230-sp-25cc2d87d553` |
| SP dernier redémarrage | 5/5 (rapport commun) | — | — | `20261024-123318-sp-b5a46a13245d` |
| MP création | 5/5 | 4/4 | 4/4 | `20261024-124104-mp-4535766fd515` |
| MP rechargement et retrait | 9/9 | 6/6 | 6/6 | `20261024-124314-mp-43434f8e2382` |
| MP dernier redémarrage | 4/4 | 2/2 | 2/2 | `20261024-124527-mp-3d74f852d3ea` |

Chaque dossier contient `summary.txt` et les `result.txt` par processus. Les rapports
`runs/c25-sp-latest.json` et `runs/c25-mp-latest.json` référencent les trois passages.
Les deux observateurs MP exécutent leurs propres assertions ; le rapport du client 2
est vérifié explicitement par le lanceur. Aucune nouvelle erreur Lua dans les scénarios.

Le journal du retrait MP confirme **1 relais chargé retiré**, puis, dans le second
cas, **1 relais laissé hors zone pour retrait à son chargement**. Le retour dans la
zone déclenche le nettoyage et les deux clients constatent l'absence du relais.

### Ajustements du harnais et limites

- Les premiers essais ont révélé des hypothèses incorrectes du harnais, corrigées
  avant la campagne réussie : texture attendue alors que la cellule transparente
  est omise de l'atlas ; téléportation SP nécessitant également la mise à jour des
  dernières coordonnées ; pilote MP attendant un écran de création absent à la
  reconnexion. Aucun de ces ajustements n'a modifié le code de la pompe.
- Pour la reconnexion, le lanceur ajoute un abonné `OnConnected` uniquement dans
  les copies privées du pilote. L'outil partagé n'est pas modifié.
- L'invisibilité est vérifiée par la ressource réellement chargée et le chemin de
  rendu vanilla ; aucun jugement manuel sur une capture ou sur Project Viewpoint.
- Ne pas lancer un second lanceur en attente pendant cette campagne : son contrôle
  de disponibilité ne réserve pas les intervalles entre les trois processus.
- Le prototype crée directement le relais avec l'API de la pompe pour isoler le
  format et sa persistance. Découverte des points d'eau, débit et couplage restent
  couverts par les campagnes fonctionnelles existantes.

## C11 — décision sur la diffusion des ancres

L'utilisateur accepte la diffusion actuelle sur les serveurs communautaires ; pas
de restriction par confidentialité. Le coût réseau est étudié sans modifier le mod.

`Registry.setAnchor` retourne avant `ModData.transmit` si état et position sont
inchangés (`LW_Registry.lua:282-313`). Le pas de simulation ne provoque donc pas une
diffusion périodique systématique. Une connexion demande aussi la table initiale.

Le modèle `autotest/anchor_payload.py`, fondé sur `KahluaTableImpl.save(ByteBuffer)`
et `GlobalModDataPacket.write`, donne, avec 16 changements d'historique par base :

| Bases | Octets par événement et par client | Moyenne par client si 2 bascules/base/jour de jeu, journée réelle de 60 min |
|---|---:|---:|
| 10 | 6 223 | 0,03 Kio/s |
| 100 | 62 114 | 3,37 Kio/s |
| 500 | 310 914 | 84,34 Kio/s |
| 1 000 | 621 915 | 337,41 Kio/s |

Ce sont des tailles de sérialisation modélisées, hors en-têtes UDP/RakNet et
retransmissions, pas une capture réseau. Multiplier par le nombre de clients pour
le trafic sortant serveur. Des centaines de bascules simultanées produisent des
pointes, puisque chaque changement renvoie la table complète. À 100 bases et 20
clients, l'hypothèse moyenne ci-dessus donne environ 67 Kio/s sortants ; 100 bascules
groupées représenteraient environ 124 Mo au total. Aucune fréquence courte
systématique n'est établie. C11 est différé ; mesurer un gros serveur en conditions
réelles avant toute optimisation.
