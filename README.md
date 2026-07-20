# Active Directory Automation - Provisioning d'utilisateurs via PowerShell

## Description du Projet
Ce projet présente une solution d'automatisation robuste conçue pour provisionner efficacement des comptes utilisateurs en masse dans un environnement Windows Server Active Directory (AD DS) à partir d'un fichier source CSV. 

En entreprise, la création manuelle de dizaines de comptes est une tâche répétitive, chronophage et sujette aux erreurs humaines (fautes de frappe, oublis de configuration ou incohérences dans les permissions). Ce script résout ces problématiques en automatisant l'intégralité du cycle de création : de la détection et génération des Unités Organisationnelles (OU) jusqu'à la configuration sécurisée des comptes d'employés.

---

## Objectifs Techniques & Fonctionnalités

* **Gestion et parsing des données :** Structuration et importation d'un fichier `.csv` contenant les informations des utilisateurs fictifs (Prénom, Nom, Département, Nom d'utilisateur).
* **Création dynamique de la structure AD (OUs) :** Le script vérifie en temps réel l'existence des Unités Organisationnelles basées sur les départements de l'entreprise (ex: TI, RH, Ventes). Si une OU est manquante, elle est automatiquement créée à la racine du domaine (`DC=bblanchard,DC=lab`).
* **Gestion des doublons (Idempotence) :** Avant chaque création d'utilisateur, le script valide si le `SamAccountName` existe déjà dans l'Active Directory afin d'éviter les interruptions et les conflits de réplication.
* **Sécurisation des accès (Best Practices) :** 
  * Génération d'un mot de passe temporaire robuste sous forme de chaîne sécurisée (`SecureString`) conforme aux exigences de complexité de l'AD.
  * Activation de l'attribut de changement obligatoire du mot de passe à la première connexion (`-ChangePasswordAtLogon $true`), garantissant la confidentialité des accès dès l'intégration de l'employé.
* **Journalisation et Verbosite (Logging) :** Utilisation d'un code couleur dynamique dans la console PowerShell (Jaune pour la création d'infrastructure, Vert pour les succès de création, Cyan pour les sauts de doublons) pour un suivi visuel rapide par l'administrateur.

---

## Technologies & Environnement Utilisés

* **Système d'exploitation :** Windows Server 2022 Core / Desktop Experience
* **Rôles Serveur :** Active Directory Domain Services (AD DS), DNS
* **Langage de script :** PowerShell 5.1 / 7+ (Module `ActiveDirectory`)
* **Environnement de test :** Infrastructure virtualisée sous VMware Workstation Pro

---

## Évolution du Projet et Résolution de Problèmes

### Étape 1 : Validation de la lecture des données (Version initiale)
La première version du script avait pour objectif unique de valider que PowerShell parvenait à lire et mapper correctement les colonnes du fichier CSV avant de faire des modifications sur l'infrastructure. 

**Code du script initial (V1) :**
```powershell
# Définition du chemin vers le fichier CSV
$cheminFichier = "$PSScriptRoot\utilisateurs.csv"

# Importation des données
$listeUtilisateurs = Import-Csv -Path$cheminFichier -Encoding utf8

# Boucle de validation de lecture
foreach ($user in$listeUtilisateurs) {
    Write-Host "Utilisateur trouvé : $($user.Prenom) dans le département : $($user.Departement)"
}
