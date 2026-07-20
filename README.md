# Automatisation Active Directory - Création d'utilisateurs via PowerShell

## Description du projet
Ce projet permet de créer automatiquement des comptes utilisateurs en masse dans un domaine Windows Server (AD DS) à partir d'un simple fichier `.csv`. 

En entreprise, créer des dizaines de comptes à la main un par un est long, répétitif et propice aux erreurs de frappe ou d'oubli. Ce script règle le problème en automatisant tout le processus : il vérifie ou génère les Unités Organisationnelles (OU) nécessaires, puis configure chaque compte de manière sécurisée.

## Objectifs techniques et fonctionnalités

* **Lecture et gestion des données :** Importation et traitement d'un fichier `.csv` contenant les informations des employés (Prénom, Nom, Département, Nom d'utilisateur).
* **Création automatique des OUs :** Le script vérifie si l'Unité Organisationnelle du département existe (ex: TI, RH, Ventes). Si elle manque, le script la crée tout seul à la racine du domaine (`DC=bblanchard,DC=lab`).
* **Gestion des doublons (Idempotence) :** Avant de lancer la création, le script vérifie si le `SamAccountName` existe déjà dans l'Active Directory pour éviter de faire planter le script ou de générer des conflits.
* **Sécurisation des comptes (Bonnes pratiques) :**
    * Génération d'un mot de passe temporaire complexe sous forme de chaîne sécurisée (`SecureString`) pour respecter les exigences de l'AD.
    * Activation de l'option de changement obligatoire du mot de passe à la première connexion (`-ChangePasswordAtLogon $true`), forçant l'employé à choisir son propre mot de passe.

---

## Technologies & environnement utilisés

* **Système d'exploitation :** Windows Server 2022 Core / Desktop Experience
* **Rôles Serveur :** Active Directory Domain Services (AD DS), DNS
* **Langage de script :** PowerShell 5.1 / 7+ (Module `ActiveDirectory`)
* **Environnement de test :** Infrastructure virtualisée sous VMware Workstation Pro

---

## Évolution du projet et résolution de problèmes

### Étape 1 : Validation de la lecture du fichier CSV
Le but de cette première version était simplement de valider que PowerShell arrivait à lire le fichier CSV et à bien mapper les colonnes, avant de commencer à toucher à l'infrastructure.

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

```
![Preuve photo V1 - Validation de la lecture](./images/V1-Validation.png)

---

### Étape 2 : Problème de sécurité (Erreur de complexité de mot de passe)
Une fois le domaine configuré, le but de cette version était de créer les Unités Organisationnelles (OU) et les comptes utilisateurs en même temps à partir du CSV.

**Code du script semi-final (V2) :**
```powershell
# Importation du module Active Directory
Import-Module ActiveDirectory

$cheminFichier = "$PSScriptRoot\utilisateurs.csv"
$listeUtilisateurs = Import-Csv -Path$cheminFichier -Encoding utf8

foreach ($user in $listeUtilisateurs) {$OU = "OU=$($user.Departement),DC=bblanchard,DC=lab"
    
    # Vérification et création de l'OU si manquante
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($user.Departement)'")) {
        Write-Host "CRÉation de l'OU : $($user.Departement)"
        New-ADOrganizationalUnit -Name $($user.Departement) -Path "DC=bblanchard,DC=lab"
    }

    # Tentative de création de l'utilisateur sans mot de passe défini
    New-ADUser -Name "$($user.Prenom) $($user.Nom)" `
               -SamAccountName $user.Username `
               -UserPrincipalName "$($user.Username)@bblanchard.lab" `
               -Path $OU `
               -Enabled $true
}
```
**Résultat obtenu et analyse de l'erreur dans la console :**
L'exécution de cette version semi-finale a généré un blocage critique visible dans la console :

![Erreur de complexité Active Directory](./images/V2-Erreurs.png)

**Erreurs trouvées dans la console :**
L'exécution de cette version a bloqué et a sorti des erreurs dans la console :

Deux problèmes sont ressortis pendant ce test :

Problème d'affichage des accents : Les messages affichaient des caractères bizarres (ex: CRÃ©ation de l'OU : TI). La console PowerShell n'utilisait pas le bon encodage pour afficher les accents du script.

Erreur de mot de passe AD (ADPasswordComplexityException) : La commande New-ADUser a été bloquée par le serveur avec ce message :

New-ADUser : Le mot de passe ne répond pas aux spécifications de longueur, de complexité ou d'historique du domaine.

Pourquoi ça a bloqué...

Par défaut, la stratégie de groupe de Windows Server (Default Domain Policy) interdit la création de comptes actifs (-Enabled $true) sans mot de passe. Comme le script essayait de créer les comptes à vide, l'Active Directory a rejeté la demande par sécurité.

---

### Étape 3 : Implémentation de la solution (Script Final)
Pour résoudre l'erreur de sécurité et corriger les problèmes d'affichage, la version finale du script a été révisée avec succès.

**Code du script final (V3) :**
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Import-Module ActiveDirectory

$cheminFichier = "$PSScriptRoot\utilisateurs.csv"

$listeUtilisateurs = Import-Csv -Path $cheminFichier -Encoding utf8

$motDePasseBrut = "Bienvenue123!"

$motDePasseSecurise = ConvertTo-SecureString $motDePasseBrut -AsPlainText -Force

foreach ($user in $listeUtilisateurs) {
    $OU = "OU=$($user.Departement),DC=bblanchard,DC=lab"
    
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($user.Departement)'")) {
        Write-Host "Création de l'OU : $($user.Departement)" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $($user.Departement) -Path "DC=bblanchard,DC=lab"
    }

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($user.Username)'")) {
        Write-Host "Création de l'utilisateur : $($user.Prenom) $($user.Nom)" -ForegroundColor Green
        
        New-ADUser -Name "$($user.Prenom) $($user.Nom)" `
                   -SamAccountName $user.Username `
                   -UserPrincipalName "$($user.Username)@bblanchard.lab" `
                   -Path $OU `
                   -AccountPassword $motDePasseSecurise `
                   -ChangePasswordAtLogon $true `
                   -Enabled $true
    } else {
        Write-Host "L'utilisateur $($user.Username) existe déjà. Passage au suivant." -ForegroundColor Cyan
    }
}

```
**Résultats et validations :**

Le script fonctionne maintenant sans aucune erreur. Les comptes existants sont détectés pour éviter les doublons et la sécurité est respectée.

### 1. Validation dans la console PowerShell
Ces captures montrent le déroulement du script, la création propre des objets et le saut des comptes qui existaient déjà :

![Exécution initiale - Création des OUs](./images/V2-Validation-1.png)
![Provisioning des utilisateurs en direct](./images/V2-Validation-2.png)
![Idempotence - Détection et saut des comptes existants](./images/V2-Validation-3.png)

### 2. Validation dans l'Active Directory
Voici le résultat visuel dans la console Utilisateurs et ordinateurs Active Directory. Les comptes sont bien classés dans leurs OUs et configurés avec l'obligation de changer le mot de passe à la première connexion :

![Validation des comptes - Département TI](./images/Validation-TI.png)
![Validation des comptes - Département RH](./images/Validation-RH.png)
![Validation des comptes - Département Ventes](./images/Validation-Ventes.png)
