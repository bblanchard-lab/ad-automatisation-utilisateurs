# 1. Définition du chemin automatique vers le fichier CSV
$cheminFichier = "$PSScriptRoot\utilisateurs.csv"

# 2. Importation des données des utilisateurs
$listeUtilisateurs = Import-Csv -Path $cheminFichier

# 3. Boucle de traitement et validation de la lecture des données
foreach ($user in $listeUtilisateurs) {
    Write-Host "Utilisateur trouvé : $($user.Prenom) qui travaille au département : $($user.Departement)"
}
