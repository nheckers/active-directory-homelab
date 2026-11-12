# bulk-create-users.ps1
# Creates Active Directory users from a CSV file, places each user in their
# department's OU, and adds them to their department's security group.
#
# CSV columns: FirstName, LastName, Department
# Department must match an existing OU under OU=Lab (IT, Sales, HR)
# and an existing group named "<Department>-Staff".
 
param(
    [string]$CsvPath = "C:\Scripts\users.csv"
)
 
Import-Module ActiveDirectory
 
$domain   = "lab.local"
$basePath = "OU=Lab,DC=lab,DC=local"
 
# One starting password for all new users. It is typed in when the script runs
# and is never saved in this file. Users must change it at first login.
$password = Read-Host -AsSecureString "Initial password for new users"
 
$users = Import-Csv -Path $CsvPath
 
foreach ($user in $users) {
    $first = $user.FirstName
    $last  = $user.LastName
    $dept  = $user.Department
 
    # Username = first initial + last name, lowercase (Alex Rivera -> arivera)
    $username = ($first.Substring(0,1) + $last).ToLower()
 
    # Skip anyone who already exists, so the script is safe to run twice
    if (Get-ADUser -Filter "SamAccountName -eq '$username'") {
        Write-Host "Skipped $username (already exists)" -ForegroundColor Yellow
        continue
    }
 
    # All the settings for the new user, passed to New-ADUser at once ("splatting")
    $params = @{
        Name                  = "$first $last"
        GivenName             = $first
        Surname               = $last
        SamAccountName        = $username
        UserPrincipalName     = "$username@$domain"
        Department            = $dept
        Path                  = "OU=$dept,$basePath"
        AccountPassword       = $password
        Enabled               = $true
        ChangePasswordAtLogon = $true
    }
 
    New-ADUser @params
    Add-ADGroupMember -Identity "$dept-Staff" -Members $username
 
    Write-Host "Created $username in $dept" -ForegroundColor Green
}