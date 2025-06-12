# ===========================
# Active Directory Setup Script
# Creates OUs, Groups, Users, and assigns them
# ===========================

Import-Module ActiveDirectory

# --- Default user password (change before production use!)
$SecurePassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# --- Organizational Units
$OUs = @("IT", "HR", "Sales")

foreach ($OU in $OUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OU'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $OU -Path "DC=corp,DC=local"
        Write-Host "Created OU: $OU"
    }
}

# --- Groups and Users
$Users = @(
    @{ Name = "hruser";     OU = "HR";    Group = "HR Group";     Display = "HR User" },
    @{ Name = "salesuser";  OU = "Sales"; Group = "Sales Group";  Display = "Sales User" },
    @{ Name = "itadmin";    OU = "IT";    Group = "IT Admins";    Display = "IT Admin" }
)

foreach ($user in $Users) {
    $ouPath = "OU=$($user.OU),DC=corp,DC=local"
    
    # Create group if not exists
    if (-not (Get-ADGroup -Filter "Name -eq '$($user.Group)'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $user.Group -Path $ouPath -GroupScope Global -GroupCategory Security
        Write-Host "Created Group: $($user.Group)"
    }

    # Create user
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($user.Name)'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name $user.Display `
            -SamAccountName $user.Name `
            -UserPrincipalName "$($user.Name)@corp.local" `
            -Path $ouPath `
            -AccountPassword $SecurePassword `
            -Enabled $true `
            -PasswordNeverExpires $false `
            -ChangePasswordAtLogon $true
        Write-Host "Created user: $($user.Name)"
    }

    # Add user to group
    Add-ADGroupMember -Identity $user.Group -Members $user.Name
    Write-Host "Added $($user.Name) to $($user.Group)"
}

Write-Host "`n✅ Active Directory setup complete."
