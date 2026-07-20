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
