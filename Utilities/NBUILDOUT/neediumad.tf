################################################################
#This project is geared towards creating an Active Directory.  #
#Spin up Linux and Windows Servers and join them to AD         #
#Add users and groups to the organization units and required   #
#access in both the Windows and Linux servers                  #
#Validate that the deployment works as expected.               #
#Spinning the AD up with AWS service for AD (Directory Service)#
#Steps involved includes:                                      #
#- Deploy networking components                                #
#- Create admin and users credentials,groups and organizational#
#  units                                                       #
#- Deploy the AD                                               #
#- Fetch the secrets for users and groups                      #
#- Create the roles, permissions                               #
#- Create SGs for the servers                                  #
#- Deploy the Windows machine with appropriate userdata        #
#- Deploy the Linux machine with appropriate userdata          #
#- Deploy the SSSD authentication for Linux, to enable its     #
#  functionality with Windows                                  #
#- Validate the deployments                                    #
################################################################


#########################################################
#Networking Configs
#########################################################
##Create VPC, Subnets and Routes
# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "neediumad-vpc" {
  cidr_block           = "10.0.0.0/24" # Define the IP address range for the VPC
  enable_dns_support   = true          # Enable DNS resolution within the VPC
  enable_dns_hostnames = true          # Allow instances to have public DNS hostnames

  tags = {
    Name = "neediumad-vpc"
  }
}

# Create an Internet Gateway (IGW) to allow outbound internet access
resource "aws_internet_gateway" "neediumad-igw" {
  vpc_id = aws_vpc.neediumad-vpc.id

  tags = {
    Name = "neediumad-igw"
  }
}

# Create a route table for managing routing rules
resource "aws_route_table" "neediumrt-pub" {
  vpc_id = aws_vpc.neediumad-vpc.id

  tags = {
    Name = "neediumrt-pub"
  }
}

# Create a default route in the public route table to send all traffic to the Internet Gateway
resource "aws_route" "neediumad_default_route" {
  route_table_id         = aws_route_table.neediumrt-pub.id # Reference the public route table
  destination_cidr_block = "0.0.0.0/0"                      # Define the default route (all IPs allowed)
  gateway_id             = aws_internet_gateway.neediumad-igw.id
  # Use the Internet Gateway for outbound traffic
}

# Create the first public subnet within the VPC
resource "aws_subnet" "neediumad-subnetuat1" {
  vpc_id                  = aws_vpc.neediumad-vpc.id
  cidr_block              = "10.0.0.0/26" # assign a CIDR block (64 IPs)
  map_public_ip_on_launch = true          # automatically assign public IPs to instances
  availability_zone       = "us-east-2a"

  tags = {
    Name = "neediumad-subnetuat1"
  }
}

# Create the second public subnet within the VPC
resource "aws_subnet" "neediumad-subnetuat2" {
  vpc_id                  = aws_vpc.neediumad-vpc.id
  cidr_block              = "10.0.0.64/26" # assign a CIDR block (64 IPs, next available range)
  map_public_ip_on_launch = true           # automatically assign public IPs to instances
  availability_zone       = "us-east-2b"

  tags = {
    Name = "neediumad-subnetuat2"
  }
}

# Associate the public route table with the first public subnet
resource "aws_route_table_association" "neediumad_public_rta1" {
  subnet_id      = aws_subnet.neediumad-subnetuat1.id
  route_table_id = aws_route_table.neediumrt-pub.id # Attach the public route table
}

# Associate the public route table with the second public subnet
resource "aws_route_table_association" "neediumad_public_rta2" {
  subnet_id      = aws_subnet.neediumad-subnetuat2.id # Reference the second public subnet
  route_table_id = aws_route_table.neediumrt-pub.id   # Attach the public route table
}

###################################################
#Create admin and users credentials, groups, OUs
###################################################

# Generate a random password for the Active Directory (AD) Administrator
resource "random_password" "admin_password" {
  length             = 20    # Set password length to 20 characters
  special            = true  # Include special characters in the password
  override_special   = "!@#$?%" # Limit special characters to this set
}

# Create an AWS Secrets Manager secret to store AD Admin credentials
resource "aws_secretsmanager_secret" "admin_secret" {
  name        = "admin_ad_credentials"
  description = "AD Admin Credentials"
  
  lifecycle {
    prevent_destroy = false # Allow secret deletion if necessary
  }
}

# Store the admin credentials in AWS Secrets Manager with a versioned secret (don't really recommend this)
resource "aws_secretsmanager_secret_version" "admin_secret_version" {
  secret_id     = aws_secretsmanager_secret.admin_secret.id
  secret_string = jsonencode({
    username = "NINC\\Admin"  # AD username
    password = random_password.admin_password.result
  })
}

# --- User: Abiona Oladosu ---

# Generate a random password for Abiona Oladosu
resource "random_password" "aoladosu_password" {
  length             = 20
  special            = true
  override_special   = "!@#$%?"
}

# Create a Secrets Manager entry for Abiona Oladosu's credentials
resource "aws_secretsmanager_secret" "aoladosu_secret" {
  name        = "aoladosu_ad_credentials"
  description = "Abiona Oladosu's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Abiona Oladosu's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "aoladosu_secret_version" {
  secret_id     = aws_secretsmanager_secret.aoladosu_secret.id
  secret_string = jsonencode({
    username = "NINC\\aoladosu"
    password = random_password.aoladosu_password.result
  })
}

# --- User: Lana Lajide ---

# Generate a random password for Lana Lajide
resource "random_password" "llajide_password" {
  length             = 20
  special            = true
  override_special   = "!@#$?%"
}

# Create a Secrets Manager entry for Lana Lajide's credentials
resource "aws_secretsmanager_secret" "llajide_secret" {
  name        = "llajide_ad_credentials"
  description = "Lana Lajide's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Lana Green's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "llajide_secret_version" {
  secret_id     = aws_secretsmanager_secret.llajide_secret.id
  secret_string = jsonencode({
    username = "NINC\\llajide"
    password = random_password.llajide_password.result
  })
}

# --- User: Awwal Imran ---

# Generate a random password for Awwal Imran
resource "random_password" "aimran_password" {
  length             = 20
  special            = true
  override_special   = "!@#$?%"
}

# Create a Secrets Manager entry for Awwal Imran's credentials
resource "aws_secretsmanager_secret" "aimran_secret" {
  name        = "aimran_ad_credentials"
  description = "Awwal Imran's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Awwal Imran's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "aimran_secret_version" {
  secret_id     = aws_secretsmanager_secret.aimran_secret.id
  secret_string = jsonencode({
    username = "NINC\\aimran"
    password = random_password.aimran_password.result
  })
}

# --- User: Janet Omoni ---

# Generate a random password for Janet Omoni
resource "random_password" "jomoni_password" {
  length             = 20
  special            = true
  override_special   = "!@#$%?"
}

# Create a Secrets Manager entry for Janet Omoni's credentials
resource "aws_secretsmanager_secret" "jomoni_secret" {
  name        = "jomoni_ad_credentials"
  description = "Janet Omoni's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Janet Omoni's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "jomoni_secret_version" {
  secret_id     = aws_secretsmanager_secret.jomoni_secret.id
  secret_string = jsonencode({
    username = "NINC\\jomoni"
    password = random_password.jomoni_password.result
  })
}

# --- User: Sirius Black ---

# Generate a random password for Sirius Black
resource "random_password" "sblack_password" {
  length             = 20
  special            = true
  override_special   = "!@#$%?"
}

# Create a Secrets Manager entry for Sirius Black's credentials
resource "aws_secretsmanager_secret" "sblack_secret" {
  name        = "sblack_ad_credentials"
  description = "Sirius Black's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Sirius Black's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "sblack_secret_version" {
  secret_id     = aws_secretsmanager_secret.sblack_secret.id
  secret_string = jsonencode({
    username = "NINC\\sblack"
    password = random_password.sblack_password.result
  })
}

# --- User: Indira Gandhi ---

# Generate a random password for Indira Gandhi
resource "random_password" "igandhi_password" {
  length             = 20
  special            = true
  override_special   = "!@#$%?"
}

# Create a Secrets Manager entry for Indira Ghandi's credentials
resource "aws_secretsmanager_secret" "igandhi_secret" {
  name        = "igandhi_ad_credentials"
  description = "Indira Ghandi's AD Credentials"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Store Sirius Black's AD credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "igandhi_secret_version" {
  secret_id     = aws_secretsmanager_secret.igandhi_secret.id
  secret_string = jsonencode({
    username = "NINC\\igandhi"
    password = random_password.igandhi_password.result
  })
}

##########################################################
# Create a DC
##########################################################
# Create an AWS Managed MAD (Directory Service) instance
resource "aws_directory_service_directory" "needium_managedad" {
  name     = "uat.needium.com" # Fully Qualified Domain Name (FQDN) of the active directory.
  password = random_password.admin_password.result
  # Admin password for the directory
  edition     = "Standard"    # "Standard" (supports up to 5,000 users)
  type        = "MicrosoftAD" # Microsoft Active Directory deployment.
  short_name  = "NINC"        # Shortened NetBIOS name of the domain.
  description = "uat active directory for testing"

  # Define the Virtual Private Cloud (VPC) configuration for the AD directory
  vpc_settings {
    vpc_id = aws_vpc.neediumad-vpc.id # associates the directory with a specific vpc.
    subnet_ids = [
      aws_subnet.neediumad-subnetuat1.id,
      aws_subnet.neediumad-subnetuat2.id
    ]
  }

  tags = {
    Name = "neediumad-uat"
  }
}

# Create a DHCP Options Set for the VPC to configure DNS settings for Active Directory
resource "aws_vpc_dhcp_options" "neediumad_dhcp_options" {
  domain_name         = "needium.com"                                                      # Specifies the domain name clients will use for DNS resolution within the VPC.
  domain_name_servers = aws_directory_service_directory.needium_managedad.dns_ip_addresses # Uses AD-provided DNS servers for domain name resolution.

  tags = {
    Name = "neediumad-dhcp-options"
  }
}

# Associate the DHCP Options Set with the VPC to enforce AD-specific DNS settings
resource "aws_vpc_dhcp_options_association" "needium_ad_dhcp_association" {
  vpc_id          = aws_vpc.neediumad-vpc.id                       # the vpc where the DHCP options set will be applied.
  dhcp_options_id = aws_vpc_dhcp_options.neediumad_dhcp_options.id # The DHCP options set being associated with the VPC.
}

###########################################################
#Fetch the secrets for users and groups
###########################################################

# Fetch AWS Secrets Manager secrets for different Active Directory users
# These secrets store AD credentials for authentication purposes
# Adds the depends_on to enable the resources be created before being fetched

data "aws_secretsmanager_secret" "jomoni_secret" {
  name = "jomoni_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.jomoni_secret]
}

data "aws_secretsmanager_secret" "aimran_secret" {
  name = "aimran_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.aimran_secret]
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials" # Secret name for the admin user in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.admin_secret]
}

data "aws_secretsmanager_secret" "llajide_secret" {
  name = "llajide_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.llajide_secret]
}

data "aws_secretsmanager_secret" "aoladosu_secret" {
  name = "aoladosu_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.aoladosu_secret]
}

data "aws_secretsmanager_secret" "sblack_secret" {
  name = "sblack_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.sblack_secret]
}

data "aws_secretsmanager_secret" "igandhi_secret" {
  name = "igandhi_ad_credentials" # Secret name in AWS Secrets Manager
  depends_on = [aws_secretsmanager_secret.igandhi_secret]
}

######################################################
#Create the roles, permissions
######################################################

# Define an IAM Role for EC2 instances to access AWS Secrets Manager
resource "aws_iam_role" "ec2_secrets_role" {
  name = "EC2SecretsAccessRole"

  # Define the trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances can assume this role
      }
      Action = "sts:AssumeRole"  # Allows EC2 instances to request temporary credentials
    }]
  })
}

# Define an IAM Role for EC2 instances to interact with AWS Systems Manager (SSM)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2SSMRole"

  # Define the trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances can assume this role
      }
      Action = "sts:AssumeRole"  # Allows EC2 instances to request temporary credentials
    }]
  })
}

# Define an IAM Policy granting EC2 instances permission to read secrets from Secrets Manager
resource "aws_iam_policy" "secrets_policy" {
  name        = "SecretsManagerReadAccess"
  description = "Allows EC2 instance to read secrets from AWS Secrets Manager and manage IAM instance profiles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Grant EC2 permission to retrieve secret values and list secrets
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",   # Fetch secret values
          "secretsmanager:DescribeSecret",   # Get metadata about secrets
          "secretsmanager:ListSecrets"       # List all secrets in AWS Secrets Manager
        ]
        Resource = [
          data.aws_secretsmanager_secret.admin_secret.arn,
          data.aws_secretsmanager_secret.aoladosu_secret.arn,
          data.aws_secretsmanager_secret.llajide_secret.arn,
          data.aws_secretsmanager_secret.aimran_secret.arn,
          data.aws_secretsmanager_secret.jomoni_secret.arn,
          data.aws_secretsmanager_secret.sblack_secret.arn,
          data.aws_secretsmanager_secret.igandhi_secret.arn
        ]
      },

      # Allow EC2 instances to manage IAM instance profile associations
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",                        # List EC2 instances
          "ec2:DescribeIamInstanceProfileAssociations",   # Get IAM profile associations for instances
          "ec2:DisassociateIamInstanceProfile",           # Remove an IAM profile from an instance
          "ec2:ReplaceIamInstanceProfileAssociation"      # Swap IAM profiles on an instance
        ]
        Resource = "*"  # Applies to all EC2 instances
      },

      # Allow EC2 instances to pass the SSM role to other AWS services
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "${aws_iam_role.ec2_ssm_role.arn}"  # Reference to the SSM role ARN
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the secrets role
# This allows EC2 instances using this role to interact with AWS Systems Manager (SSM)
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the AmazonSSMManagedInstanceCore policy to the SSM role
# This ensures instances using the SSM role can be managed via AWS Systems Manager
resource "aws_iam_role_policy_attachment" "attach_ssm_policy_2" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the Secrets Manager access policy to the EC2 Secrets role
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn  # Custom policy granting Secrets Manager access
}

# Create an IAM Instance Profile for EC2 instances using the Secrets role
resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "EC2SecretsInstanceProfile"
  role = aws_iam_role.ec2_secrets_role.name  # Associate the EC2SecretsAccessRole with this profile
}

# Create an IAM Instance Profile for EC2 instances using the SSM role
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2SSMProfile"
  role = aws_iam_role.ec2_ssm_role.name  # Associate the EC2SSMRole with this profile
}


##################################################
#Create SGs
##################################################

# WARNING: This configuration allows unrestricted access from the internet (0.0.0.0/0)
# It is highly insecure and should be restricted to trusted IPs.
# Consider limiting access to known CIDR ranges instead.

# Security Group for RDP (Port 3389) - Used for Remote Desktop Protocol access to Windows instances
resource "aws_security_group" "neediumad_rdp_sg" {
  name        = "neediumad-rdp-security-group"               # Security Group name
  description = "Allow RDP access from the internet"  # Description of the security group
  vpc_id      = aws_vpc.neediumad-vpc.id                # Associates the security group with the specified VPC

  # INGRESS: Defines inbound rules allowing access to port 3389 (RDP)
  ingress {
    description = "Allow RDP from anywhere"           # This rule permits RDP access from all IPs
    from_port   = 3389                                # Start of port range (RDP default port)
    to_port     = 3389                                # End of port range (same as start for a single port)
    protocol    = "tcp"                               # Protocol type (TCP for RDP)
    cidr_blocks = ["0.0.0.0/0"]                       # WARNING: Allows traffic from ANY IP address (highly insecure!)
  }

  # EGRESS: Allows all outbound traffic (default open rule)
  egress {
    from_port   = 0                                   # Start of port range (0 means all ports)
    to_port     = 0                                   # End of port range (0 means all ports)
    protocol    = "-1"                                # Protocol (-1 means all protocols)
    cidr_blocks = ["0.0.0.0/0"]                       # Allows outbound traffic to ANY destination
  }

  tags = {
    Name = "neediumad-rdp-security-group"
  }
}

# Security Group for SSH (Port 22) - Used for Secure Shell access to Linux instances
resource "aws_security_group" "neediumad_ssh_sg" {
  name        = "neediumad-ssh-security-group"               # Security Group name
  description = "Allow SSH access from the internet"  # Description of the security group
  vpc_id      = aws_vpc.neediumad-vpc.id                # Associates the security group with the specified VPC

  # INGRESS: Defines inbound rules allowing access to port 22 (SSH)
  ingress {
    description = "Allow SSH from anywhere"           # This rule permits SSH access from all IPs
    from_port   = 22                                  # Start of port range (SSH default port)
    to_port     = 22                                  # End of port range (same as start for a single port)
    protocol    = "tcp"                               # Protocol type (TCP for SSH)
    cidr_blocks = ["0.0.0.0/0"]                       # WARNING: Allows traffic from ANY IP address (highly insecure!)
  }

  # EGRESS: Allows all outbound traffic (default open rule)
  egress {
    from_port   = 0                                   # Start of port range (0 means all ports)
    to_port     = 0                                   # End of port range (0 means all ports)
    protocol    = "-1"                                # Protocol (-1 means all protocols)
    cidr_blocks = ["0.0.0.0/0"]                       # Allows outbound traffic to ANY destination
  }

  tags = {
    Name = "neediumad-ssh-security-group"
  }
}

# Security Group for SSM (Port 443) - Used for AWS Systems Manager (SSM) agent communication
resource "aws_security_group" "neediumad_ssm_sg" {
  name        = "neediumad-ssm-security-group"               # Security Group name
  description = "Allow SSM access from the internet"  # Description of the security group
  vpc_id      = aws_vpc.neediumad-vpc.id                # Associates the security group with the specified VPC

  # INGRESS: Defines inbound rules allowing access to port 443 (HTTPS for SSM communication)
  ingress {
    description = "Allow SSM from anywhere"           # This rule permits SSM agent communication from all IPs
    from_port   = 443                                 # Start of port range (HTTPS default port)
    to_port     = 443                                 # End of port range (same as start for a single port)
    protocol    = "tcp"                               # Protocol type (TCP for HTTPS)
    cidr_blocks = ["0.0.0.0/0"]                       # WARNING: Allows traffic from ANY IP address (highly insecure!)
  }

  # EGRESS: Allows all outbound traffic (default open rule)
  egress {
    from_port   = 0                                   # Start of port range (0 means all ports)
    to_port     = 0                                   # End of port range (0 means all ports)
    protocol    = "-1"                                # Protocol (-1 means all protocols)
    cidr_blocks = ["0.0.0.0/0"]                       # Allows outbound traffic to ANY destination
  }

  tags = {
    Name = "neediumad-ssm-security-group"
  }
}

############################################################
# Create Windows Server
############################################################

# EC2 INSTANCE CONFIGURATION
# This resource block defines an AWS EC2 instance named "windows_ad_instance".

resource "aws_instance" "neediumwindows_ad_instance" {
  
  # AMAZON MACHINE IMAGE (AMI)
  ami           = "ami-0c24d55d64443eb31"

  # INSTANCE TYPE
  # Defines the compute power of the EC2 instance.
  # "t2.medium" is selected to provide more RAM and CPU power, 
  # since Windows requires more resources than Linux. 
  instance_type = "t2.medium"

  # NETWORK CONFIGURATION - SUBNET
  # Specifies the AWS subnet where the instance will be deployed.
  # This determines whether the instance is public or private.
  
  subnet_id = aws_subnet.neediumad-subnetuat2.id

  # SECURITY GROUPS
  # Applies two security groups:
  # 1. `neediumad_rdp_sg` - Allows Remote Desktop Protocol (RDP) access for Windows management.
  # 2. `neediumad_ssm_sg` - Allows AWS Systems Manager access for remote management.
  
  vpc_security_group_ids = [
    aws_security_group.neediumad_rdp_sg.id,
    aws_security_group.neediumad_ssm_sg.id
  ]

  # PUBLIC IP ASSIGNMENT
  # Ensures the instance gets a public IP upon launch for external access.
  # WARNING: This makes the instance reachable from the internet if security groups are misconfigured.

  associate_public_ip_address = true

  # SSH KEY PAIR (FOR ADMIN ACCESS)
  # Assigns an SSH key pair for secure access.
  # Even though this is a Windows instance, the key may be used for encrypted RDP authentication.
  
  # key_name = aws_key_pair.ec2_key_pair.key_name

  # IAM INSTANCE PROFILE
  # Assigns an IAM role with the necessary permissions for accessing AWS resources securely.
  # This is often used for granting access to S3, Secrets Manager, or other AWS services.
  
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # USER DATA SCRIPT
  # Executes a PowerShell startup script (`userdata.ps1`) when the instance boots up.
  # This script is dynamically templated with values required for Windows Active Directory setup:
  # - `admin_secret`: The administrator credentials secret.
  # - `domain_fqdn`: The fully qualified domain name (FQDN) for the environment.
  # - `computers_ou`: The Organizational Unit where computers are registered in Active Directory.
  
  user_data = templatefile("./NBUILDOUT/userdata.ps1", { 
    admin_secret = "admin_ad_credentials"                       # The administrator credentials secret.
    domain_fqdn  = "uat.needium.com"                       # The domain FQDN for Active Directory integration.
    computers_ou = "OU=Computers,OU=NINC,DC=uat,DC=needium,DC=com" # The AD OU where computers will be placed.
  })

  # INSTANCE TAGS
  # Metadata tag used to identify and organize resources in AWS.
  tags = {
    Name = "neediumwindows_ad_instance"  # The EC2 instance name in AWS.
  }
}



################################################
# Create Linux Server
################################################

# EC2 INSTANCE CONFIGURATION
# This resource block defines an AWS EC2 instance named "linux_ad_instance".

resource "aws_instance" "neediumlinux_ad_instance" {
  
  # AMAZON MACHINE IMAGE (AMI)
  ami = "ami-04f167a56786e4b09"

  # INSTANCE TYPE
  # Defines the compute power of the EC2 instance. 
  # "t2.micro" is selected as a cost-effective option with minimal resources.

  instance_type = "t2.micro"

  # NETWORK CONFIGURATION - SUBNET
  # Specifies the AWS subnet where the instance will be deployed.
  
  subnet_id = aws_subnet.neediumad-subnetuat1.id

  # SECURITY GROUPS
  # Applies two security groups:
  # 1. `neediumad_ssh_sg` - Allows SSH access.
  # 2. `neediumad_ssm_sg` - Allows AWS Systems Manager access for remote management.

  vpc_security_group_ids = [
    aws_security_group.neediumad_rdp_sg.id,
    aws_security_group.neediumad_ssm_sg.id
  ]

  # PUBLIC IP ASSIGNMENT
  # Ensures the instance gets a public IP upon launch for external access.
  
  associate_public_ip_address = true

  # IAM INSTANCE PROFILE
  # Assigns an IAM role with the necessary permissions for accessing AWS resources securely.
  # This is often used for granting access to S3, Secrets Manager, or other AWS services.
  
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # USER DATA SCRIPT
  # Executes a startup script (`userdata.sh`) when the instance boots up.
  # This script is dynamically templated with values required for setup:
  # - `admin_secret`: The administrator credentials secret
  # - `domain_fqdn`: The fully qualified domain name (FQDN) for the environment.
  # - `computers_ou`: The Organizational Unit where computers are registered in Active Directory.

  user_data = templatefile("./NBUILDOUT/userdata.sh", { 
    admin_secret = "admin_ad_credentials"                       # The administrator credentials secret
    domain_fqdn  = "uat.needium.com"                       # The domain FQDN for Active Directory integration.
    computers_ou = "OU=Computers,OU=NINC,DC=uat,DC=needium,DC=com" # The AD OU where computers will be placed.
  })

  # INSTANCE TAGS
  # Metadata tag used to identify and organize resources in AWS.

  tags = {
    Name = "neediumlinux-ad-instance"  # The EC2 instance name in AWS.
  }
}
