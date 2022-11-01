function Send-Report {
<# 
.NAME
Send-Report

.SYNOPSIS
This function sends out the password expiration report to Bob

.DESCRIPTION

.PARAMETERS
$file...This is the .csv file that was created in the main body of the script
$date...this is today's date

.EXAMPLE
Sent-Report c:\documents\help.csv $today_date

.INPUTS
none

.OUTPUTS
An email is sent to the approropriate individuals and groups

.NOTES
 AUTHOR: Mike Egan
 LASTEDIT: 11/1/2022
 KEYWORDS: send, email, function, parameter, mail

.Link
none

#> 
    param (
        
        [Parameter(Mandatory=$true)] $file
        ,[Parameter(Mandatory=$true)] $date
    )


    $smtp = "smtp.my.com"
    $TO = "bob@my.com"
    $FROM = "system@my.com"
    $SUBJECT = "MR Password Expiry Report for" + " " + (get-date -format MM/dd/yyyy)
    $BODY = @"
Greetings!
Here is the Managed Review Expiry report for $date

Thank you!
"@
    $ATTACHMENT = $file

    Send-MailMessage -SMTP $SMTP -From $FROM -To $TO -Subject $SUBJECT -Body $BODY -attachments $file


}


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
 LASTEDIT: 11/1/2022
 KEYWORDS: password, expiration
 This script should be run as Administrator

.Link
none

#> 

# gather all the accounts that meet the following criteria
#  1. The account is enabled
#  2. The account is active (UAC = 512)
#  3. The account is OU=Users,DC=My,DC=Com
#
#  NOTE: the -SearchBase switch is optional.  It is used in this script to narrow the focus of the search

$today_date = get-date -Format "MM/dd/yyyy"
$users = Get-ADUser -filter {Enabled -eq $True -and UserAccountControl -eq 512} -SearchBase "OU=Users,DC=My,DC=Com" -Properties "DisplayName","pwdLastSet","msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "DisplayName",@{Name="Password Last Set";Expression={[datetime]::FromFileTime($_."pwdLastSet")}}, @{Name="Password Expiry Date";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} | sort-object DisplayName

$expiring_users = foreach($user in $users)
{

    if ($user.'Password Expiry Date' -ge (get-date).Date -and $user.'Password Expiry Date' -lt (get-date).AddDays(+14))
    {
        # the `t is the text code for a Tab
        $user.DisplayName + "`t" + $user.'Password Expiry Date'
        
    }

}
#Save the base file
$expiring_users | out-file c:\files\expiring_users.csv -Force

#creates the final report
$filename = "Expiring Users" + "_" + (get-date -Format "MMddyyyy") + ".csv"

#Adds the necessary headers for the report by combining the headers.csv file with the expiring_users.csv and, thus, populating the final report
get-content c:\files\headers.csv,c:\files\expiring_users.csv | out-file c:\reports\$filename -Force

#runs the function
send-report c:\reports\$filename $today_date