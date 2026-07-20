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

## Technologies & Environnement utilisés

* **Système d'exploitation :** Windows Server 2022 Core / Desktop Experience
* **Rôles Serveur :** Active Directory Domain Services (AD DS), DNS
* **Langage de script :** PowerShell 5.1 / 7+ (Module `ActiveDirectory`)
* **Environnement de test :** Infrastructure virtualisée sous VMware Workstation Pro

---

## Évolution du projet et résolution de problèmes

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

```
![Preuve photo V1 - Validation de la lecture](./images/V1-Validation.png)

---

### Étape 2 : Blocage de sécurité (Erreur de complexité de mot de passe)
Une fois l'infrastructure Active Directory prête, la deuxième itération du script (version semi-finale) visait à automatiser la création conjointe des Unités Organisationnelles (OU) et des comptes utilisateurs directement depuis le fichier CSV.

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

Deux problèmes majeurs ont été identifiés lors de ce test :
1. **Erreur d'encodage de la console (UTF-8) :** Les messages de sortie affichaient un problème de décodage des accents (ex: `CRÃ©ation de l'OU : TI`). Cela indique que la console PowerShell par défaut n'interprétait pas correctement les caractères accentués du script.
2. **Blocage de sécurité AD (`ADPasswordComplexityException`) :** La commande `New-ADUser` (située à la ligne 35 du script) a renvoyé l'erreur système :  
   > *New-ADUser : Le mot de passe ne répond pas aux spécifications de longueur, de complexité ou d'historique du domaine.*

**Analyse technique :** 
Par défaut, un domaine Active Directory Windows Server applique strictement la politique `Default Domain Policy`. Tenter d'injecter et d'activer immédiatement (`-Enabled $true`) un compte utilisateur sans passer de paramètre `-AccountPassword` force l'AD à rejeter la requête, car la création d'un compte avec un mot de passe vide enfreint les critères de complexité obligatoires du domaine.

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
**Résultats obtenus et preuves de succès (V3) :**

L'exécution finale du script démontre une automatisation fluide, sans aucune erreur rouge, respectant à la fois l'indempotence et la sécurité des données.

#### 1. Validation de l'exécution dans la console PowerShell
Les captures suivantes montrent l'exécution pas à pas du script, la création des objets et la détection intelligente des comptes existants :

![Exécution initiale - Création des OUs](./images/V2-Validation-1.png)
![Provisioning des utilisateurs en direct](./images/V2-Validation-2.png)
![Idempotence - Détection et saut des comptes existants](./images/V2-Validation-3.png)

#### 2. Structure finale validée dans l'Active Directory
Voici la validation visuelle directement dans la console *Utilisateurs et ordinateurs Active Directory* ($ADUC$). Les comptes ont été correctement injectés et répartis dans leurs Unités Organisationnelles respectives avec l'obligation de changer le mot de passe à la prochaine session :

![Validation des comptes - Département TI](./images/Validation-TI.png)
![Validation des comptes - Département RH](./images/Validation-RH.png)
![Validation des comptes - Département Ventes](./images/Validation-Ventes.png)
