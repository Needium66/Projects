#!/bin/bash

# This script automates the process of updating the OS, installing required packages,
# joining an Active Directory (AD) domain, configuring system settings, and cleaning
# up permissions.

# ---------------------------------------------------------------------------------
# Section 1: Update the OS and Install Required Packages
# ---------------------------------------------------------------------------------

# Update the package list to ensure the latest versions of packages are available.
apt-get update -y

# Set the environment variable to prevent interactive prompts during installation.
export DEBIAN_FRONTEND=noninteractive

# Install necessary packages for AD integration, system management, and utilities.
# - realmd, sssd-ad, sssd-tools: Tools for AD integration and authentication.
# - libnss-sss, libpam-sss: Libraries for integrating SSSD with the system.
# - adcli, samba-common-bin, samba-libs: Tools for AD and Samba integration.
# - oddjob, oddjob-mkhomedir: Automatically create home directories for AD users.
# - packagekit: Package management toolkit.
# - krb5-user: Kerberos authentication tools.
# - nano, vim: Text editors for configuration file editing.
apt-get install less unzip realmd sssd-ad sssd-tools libnss-sss \
    libpam-sss adcli samba-common-bin samba-libs oddjob \
    oddjob-mkhomedir packagekit krb5-user nano vim -y

# ---------------------------------------------------------------------------------
# Section 2: Install AWS CLI
# ---------------------------------------------------------------------------------

# Change to the /tmp directory to download and install the AWS CLI.
cd /tmp

# Download the AWS CLI installation package.
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "awscliv2.zip"

# Unzip the downloaded package.
unzip awscliv2.zip

# Install the AWS CLI using the installation script.
sudo ./aws/install

# Clean up by removing the downloaded zip file and extracted files.
rm -f -r awscliv2.zip aws

# ---------------------------------------------------------------------------------
# Section 3: Join the Active Directory Domain
# ---------------------------------------------------------------------------------

# Retrieve the secret value (AD admin credentials) from AWS Secrets Manager.
# - ${admin_secret}: The name of the secret containing the AD admin credentials.
secretValue=$(aws secretsmanager get-secret-value --secret-id ${admin_secret} \
    --query SecretString --output text)

# Extract the admin password from the secret value using `jq`.
admin_password=$(echo $secretValue | jq -r '.password')

# Extract the admin username from the secret value and remove the domain prefix.
admin_username=$(echo $secretValue | jq -r '.username' | sed 's/.*\\//')

# Join the Active Directory domain using the `realm` command.
# - ${domain_fqdn}: The fully qualified domain name (FQDN) of the AD domain.
# - ${computers_ou}: The organizational unit (OU) for the computer account.
# - Log the output and errors to /tmp/join.log for debugging.
echo -e "$admin_password" | sudo /usr/sbin/realm join -U "$admin_username" \
    ${domain_fqdn} --computer-ou="${computers_ou}" --verbose \
    >> /tmp/join.log 2>> /tmp/join.log

# ---------------------------------------------------------------------------------
# Section 4: Allow Password Authentication for AD Users
# ---------------------------------------------------------------------------------

# Modify the SSH configuration to allow password authentication for AD users.
# - Replace `PasswordAuthentication no` with `PasswordAuthentication yes`.
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
    /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# ---------------------------------------------------------------------------------
# Section 5: Configure SSSD for AD Integration
# ---------------------------------------------------------------------------------

# Modify the SSSD configuration file to simplify user login and home directory creation.
# - Disable fully qualified names (use only usernames instead of user@domain).
sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' \
    /etc/sssd/sssd.conf

# Disable LDAP ID mapping to use UIDs and GIDs from AD.
sudo sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' \
    /etc/sssd/sssd.conf

# Change the fallback home directory path to a simpler format (/home/%u).
sudo sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' \
    /etc/sssd/sssd.conf

# Stop XAuthority warning 

touch /etc/skel/.Xauthority
chmod 600 /etc/skel/.Xauthority

# Restart the SSSD and SSH services to apply the changes.

sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd
sudo systemctl restart ssh

# ---------------------------------------------------------------------------------
# Section 6: Grant Sudo Privileges to AD Linux Admins
# ---------------------------------------------------------------------------------

# Add a sudoers rule to grant passwordless sudo access to members of the
# "linux-admins" AD group.
sudo echo "%linux-admins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/10-linux-admins

# ---------------------------------------------------------------------------------
# Section 7: Clean Up Permissions
# ---------------------------------------------------------------------------------

# Retrieve the instance ID using the EC2 metadata service.
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Generate a token for accessing the EC2 metadata service (required for IMDSv2).
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Retrieve the instance ID again using the token for IMDSv2 compatibility.
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id)

# Retrieve the IAM instance profile association ID for the current instance.
association_id=$(aws ec2 describe-iam-instance-profile-associations \
    --filters "Name=instance-id,Values=$instance_id" \
    --query "IamInstanceProfileAssociations[0].AssociationId" --output text)

# Replace the current IAM instance profile with a new one (e.g., "EC2SSMProfile").
profileName="EC2SSMProfile"
aws ec2 replace-iam-instance-profile-association \
    --iam-instance-profile Name=$profileName --association-id $association_id

# ---------------------------------------------------------------------------------
# End of Script
# ---------------------------------------------------------------------------------