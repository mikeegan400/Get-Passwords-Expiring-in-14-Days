<# 
.NAME
get-passwords_expiring_in_14_days.ps1

.SYNOPSIS
Pulls user password expiration date and saves the information to a .csvfile.
NOTE: This script should be run as Administrator

.DESCRIPTION

.PARAMETERS
no parameters are needed

.EXAMPLE
get-password.expiring_in_14_days.ps1

.INPUTS
none

.OUTPUTS
The .csv file created in the last command

.NOTES
 AUTHOR: Mike Egan
 LASTEDIT: 10/28/2022
 KEYWORDS: password, expiration
 This script should be run as Administrator

.Link
none

#> 

# gather all the accounts that meet the following criteria
#  1. The account is enabled
#  2. The account is active (UAC = 512)
#  3. The account is in OU=Users,DC=My,DC=CORP
#
#  NOTE: the -SearchBase switch is optional.  It is used in this script to narrow the focus of the search
$users = Get-ADUser -filter {Enabled -eq $True -and UserAccountControl -eq 512} -SearchBase "OU=Users,DC=My,DC=CORP" –Properties "DisplayName","pwdLastSet","msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "DisplayName",@{Name="Password Last Set";Expression={[datetime]::FromFileTime($_."pwdLastSet")}}, @{Name="Password Expiry Date";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | sort-object DisplayName

$expiring_users = foreach($user in $users)
{

    if ($user.'Password Expiry Date' -ge (get-date).Date -and $user.'Password Expiry Date' -lt (get-date).AddDays(+14))
    {
        # the `t is the text code for a Tab
        $user.DisplayName + "`t" + $user.'Password Expiry Date'
        
    }

}
#Save the file
$expiring_users | out-file C:\Scripts\expiring_users.csv