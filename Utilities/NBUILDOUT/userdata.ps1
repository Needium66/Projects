<powershell>

# ------------------------------------------------------------
# Install Active Directory Components
# ------------------------------------------------------------

# Suppress progress bars to speed up execution
$ProgressPreference = 'SilentlyContinue'

# Install required Windows Features for Active Directory management
Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server

# ------------------------------------------------------------
# Download and Install AWS CLI
# ------------------------------------------------------------

Write-Host "Installing AWS CLI..."

# Download the AWS CLI installer to the Administrator's folder
Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile C:\Users\Administrator\AWSCLIV2.msi

# Run the installer silently without user interaction
Start-Process "msiexec" -ArgumentList "/i C:\Users\Administrator\AWSCLIV2.msi /qn" -Wait -NoNewWindow

# Manually append AWS CLI to system PATH for immediate availability
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"

# ------------------------------------------------------------
# Join EC2 Instance to Active Directory
# ------------------------------------------------------------

# Retrieve domain admin credentials from AWS Secrets Manager
$secretValue = aws secretsmanager get-secret-value --secret-id ${admin_secret} --query SecretString --output text
$secretObject = $secretValue | ConvertFrom-Json
$password = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $secretObject.username, $password

# Join the EC2 instance to the Active Directory domain
Add-Computer -DomainName "${domain_fqdn}" -Credential $cred -Force -OUPath "${computers_ou}"

# ------------------------------------------------------------
# Create AD Groups for User Management
# ------------------------------------------------------------

New-ADGroup -Name "ninc-users" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10001'}
New-ADGroup -Name "india" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10002'}
New-ADGroup -Name "us" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10003'}
New-ADGroup -Name "linux-admins" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10004'}
New-ADGroup -Name "nigeria" -GroupCategory Security -GroupScope Universal -Credential $cred -OtherAttributes @{gidNumber='10005'}

# ------------------------------------------------------------
# Create AD Users and Assign to Groups
# ------------------------------------------------------------

# Initialize a counter for uidNumber
$uidCounter = 10000 

# Function to create an AD user from AWS Secrets Manager
function Create-ADUserFromSecret {
    param (
        [string]$SecretId,
        [string]$GivenName,
        [string]$Surname,
        [string]$DisplayName,
        [string]$Email,
        [string]$Username,
        [array]$Groups
    )

    # Increment the uidCounter for each new user
    $global:uidCounter++
    $uidNumber = $global:uidCounter

    $secretValue = aws secretsmanager get-secret-value --secret-id $SecretId --query SecretString --output text
    $secretObject = $secretValue | ConvertFrom-Json
    $password = $secretObject.password | ConvertTo-SecureString -AsPlainText -Force

    # Create the AD user
    New-ADUser -Name $Username `
        -GivenName $GivenName `
        -Surname $Surname `
        -DisplayName $DisplayName `
        -EmailAddress $Email `
        -UserPrincipalName "$Username@${domain_fqdn}" `
        -SamAccountName $Username `
        -AccountPassword $password `
        -Enabled $true `
        -Credential $cred `
        -PasswordNeverExpires $true `
        -OtherAttributes @{gidNumber='10001'; uidNumber=$uidNumber}
    
    # Add the user to specified groups
    foreach ($group in $Groups) {
        Add-ADGroupMember -Identity $group -Members $Username -Credential $cred
    }
}

# Create users with predefined groups
Create-ADUserFromSecret "aoladosu_ad_credentials" "Abiona" "Oladosu" "Abiona Oladosu" "aoladosu@needium.com" "aoladosu" @("ninc-users", "nigeria", "linux-admins")
Create-ADUserFromSecret "llajide_ad_credentials" "Lana" "Lajide" "Lana Lajide" "llajide@needium.com" "llajide" @("ninc-users", "us", "linux-admins")
Create-ADUserFromSecret "aimran_ad_credentials" "Awwal" "Imran" "Awwal Imran" "aimran@needium.com" "aimran" @("ninc-users", "us", "linux-admins")
Create-ADUserFromSecret "jomoni_ad_credentials" "Janet" "Omoni" "Janet Omoni" "jomoni@needium.com" "jomoni" @("ninc-users", "nigeria")
Create-ADUserFromSecret "sblack_ad_credentials" "Sirius" "Black" "Sirius Black" "sblack@needium.com" "sblack" @("ninc-users", "us")
Create-ADUserFromSecret "igandhi_ad_credentials" "Indira" "Gandhi" "Indira Gandhi" "igandhi@needium.com" "igandhi" @("ninc-users", "india")

# ------------------------------------------------------------
# Grant RDP Access to All Users in "ninc-users" Group
# ------------------------------------------------------------

Add-LocalGroupMember -Group "Remote Desktop Users" -Member "ninc-users"

# ------------------------------------------------------------
# Retrieve AWS Metadata and Modify IAM Profile
# ------------------------------------------------------------

# Retrieve the instance ID using AWS IMDSv2 for security
$token = Invoke-RestMethod -Method Put -Uri "http://169.254.169.254/latest/api/token" -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }
$instanceId = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-id" -Headers @{ "X-aws-ec2-metadata-token" = $token }

# Fetch the IAM instance profile association ID for this instance
$associationId = aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=$instanceId" --query "IamInstanceProfileAssociations[0].AssociationId" --output text

# Assign a less privileged IAM role to the instance for security
$profileName = "EC2SSMProfile"
aws ec2 replace-iam-instance-profile-association --iam-instance-profile Name=$profileName --association-id $associationId

# ------------------------------------------------------------
# Final Reboot to Apply Changes
# ------------------------------------------------------------

# Reboot the server to finalize the domain join and group policies
shutdown /r /t 5 /c "Initial EC2 reboot to join domain" /f /d p:4:1

</powershell>