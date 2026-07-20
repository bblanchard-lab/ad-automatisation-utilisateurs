# Active Directory Automation - Provisioning d'utilisateurs via PowerShell

## Description
Ce projet présente un script d'automatisation en PowerShell conçu pour provisionner efficacement des comptes utilisateurs dans un environnement Active Directory (AD) à partir d'un fichier source CSV. 

Cette solution permet d'éviter la création manuelle répétitive, de réduire drastiquement les erreurs humaines (fautes de frappe, oublis de configurations) et d'accélérer l'intégration des nouveaux employés.

## Objectifs Techniques
* **Gestion des données** : Concevoir et structurer un fichier `.csv` contenant les informations des utilisateurs fictifs.
* **Automatisation PowerShell** : Développer un script `.ps1` robuste utilisant le module Active Directory.
* **Logique conditionnelle** : Vérifier l'existence des Unités Organisationnelles (OU) basées sur les départements et les créer dynamiquement au besoin.
* **Sécurité des comptes** : Générer un mot de passe temporaire sécurisé par défaut et forcer la modification de celui-ci à la première connexion de l'utilisateur.

## Structure du projet
* `create-users.ps1` : Le script PowerShell d'automatisation.
* `utilisateurs.csv` : Le fichier de données contenant la liste des utilisateurs à importer.
* `README.md` : Documentation du projet.

## Comment ça fonctionne ?
*(Section à compléter lorsque le script sera fonctionnel)*

## Preuves de concept (PoC)
*(Les captures d'écran de la console Active Directory avant/après l'exécution seront insérées ici)*
