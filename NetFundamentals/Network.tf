########################################################################
#Tinkering with deployment of a Transit Gateway as Hub and VPCs as spoke
#Downside- I have an only AWS account to work it.
#Assumptions: The TGW with its VPC and associated components represent
#resources in a "Shared" AWS account, independent of the 2 other VPCs and
#associated components to be spun up.
#Requirements:
#A TGW with VPC, 2 subnets, 2 attachment (VPC attachment) - default and
#customized, 2 route tables- default and customized
#VPC-A, 2 subnets, 1 attachment, 1 association, 2 route tables, route
#VPC-B, 2 subnets, 1 attachment, 1 association, 2 route tables, route
########################################################################

#####################################################################################
#Steps:
#Create a VPC for the shared account
#Create internet gateway for the shared account
#Create route tables for the shared account
#Create a default route table for the internet gateway for the shared account
#Create subnets for the shared account
#Associate the route table with the VPC network in the shared account
#Create the transit gateway in the shared account
#Create the VPC attachment for the TGW in the shared account
#Create the routes for route propagation in the shared account
#Create 2 VPCs (A & B) in 2 diff accounts act as spoke for the TGW (hub)
#Create 2 internet gateways for the 2 independent accounts/environment
#Create route tables for the 2 independent accounts/environent
#Create default route tables for the internet gateway for the 2 independent accounts
#Create subnets for the 2 independent accounts
#Associate the route tables with the VPC network in the 2 accounts
#Create the VPC attachments for that points to the TGW
#Create the routes for route propagation in the 2 accounts
#######################################################################################

########################################
# Create a Virtual Private Cloud (VPC)
########################################
resource "aws_vpc" "neediumtgw-vpc" {
  cidr_block           = var.neediumtgw_vpc
  enable_dns_support   = true          # Enable DNS resolution within the VPC
  enable_dns_hostnames = true          # Allow instances to have public DNS hostnames

  tags = {
    Name = "neediumtgw-vpc"
  }
}

####################################################################
# Create an Internet Gateway (IGW) to allow outbound internet access
####################################################################
resource "aws_internet_gateway" "neediumtgw-igw" {
  vpc_id = aws_vpc.neediumtgw-vpc.id

  tags = {
    Name = "neediumtgw-igw"
  }
}

###################################################
# Create a route table for managing routing rules for pub sub
###################################################
resource "aws_route_table" "neediumtgw-rt-pub" {
  vpc_id = aws_vpc.neediumtgw-vpc.id

  tags = {
    Name = "neediumtgw-rt-pub"
  }
}

###################################################
# Create a route table for managing routing rules for priv sub
###################################################
resource "aws_route_table" "neediumtgw-rt-priv" {
  vpc_id = aws_vpc.neediumtgw-vpc.id

  tags = {
    Name = "neediumtgw-rt-priv"
  }
}

##############################################################################################
# Create a default route in the public route table to send all traffic to the Internet Gateway
##############################################################################################
resource "aws_route" "neediumtgw_default_route" {
  route_table_id         = aws_route_table.neediumtgw-rt-pub.id # Reference the public route table
  destination_cidr_block = "0.0.0.0/0"                          # Define the default route (all IPs allowed)
  gateway_id             = aws_internet_gateway.neediumtgw-igw.id
  # Use the Internet Gateway for outbound traffic
}

#####################################################
# Create the public subnet within the VPC
#####################################################
resource "aws_subnet" "neediumtgw-pub-sub" {
  vpc_id = aws_vpc.neediumtgw-vpc.id
  cidr_block              = var.neediumtgw_pub_sub
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2a"

  tags = {
    Name = "neediumtgw-pub-sub"
  }
}

###########################################
# Create the private subnet within the VPC
###########################################
resource "aws_subnet" "neediumtgw-priv-sub" {
  vpc_id = aws_vpc.neediumtgw-vpc.id
  cidr_block              = var.neediumtgw_priv_sub
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2b"

  tags = {
    Name = "neediumtgw-priv-sub"
  }
}

##################################################
# Associate the route table with the public subnet
##################################################
resource "aws_route_table_association" "neediumtgw_pub_assoc" {
  subnet_id      = aws_subnet.neediumtgw-pub-sub.id
  route_table_id = aws_route_table.neediumtgw-rt-pub.id # Attach the route table
}

######################################################
# Associate the route table with the private subnet
######################################################
resource "aws_route_table_association" "neediumtgw_priv_assoc" {
  subnet_id      = aws_subnet.neediumtgw-priv-sub.id     # Reference the second public subnet
  route_table_id = aws_route_table.neediumtgw-rt-priv.id # Attach the route table
}

####################################################
# Create the Transit gateway
####################################################

resource "aws_ec2_transit_gateway" "needium_tgw" {
  description                     = "Transit Gateway"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  #ecmp is to enable on-premises network on the tgw
  vpn_ecmp_support = "enable"

  tags = {
    Name = "needium-transitgw"
  }
}

####################################################
# Create the VPC attachment
####################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "needium-tgw-attach" {
  transit_gateway_id = aws_ec2_transit_gateway.needium_tgw.id
  vpc_id             = aws_vpc.neediumtgw-vpc.id
  subnet_ids = [
    aws_subnet.neediumtgw-priv-sub.id,
    aws_subnet.neediumtgw-pub-sub.id
  ]
}

####################################################
# Create the Transit Gateway Routes in each VPCs route table
####################################################
resource "aws_route" "needium_tgw_rt" {
  route_table_id = aws_route_table.neediumtgw-rt-priv.id
  destination_cidr_block = var.destination_cidr_block_tgw
  gateway_id             = aws_ec2_transit_gateway.needium_tgw.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.needium-tgw-attach
  ]
}




#############################################################
# Create Networking Resources for the first Spoke (VPC A)
#############################################################

########################################
# Create a Virtual Private Cloud (VPC) A
########################################
resource "aws_vpc" "neediumtgw-vpc-A" {
  cidr_block           = var.neediumtgw_vpc_A # Define the IP address range for the VPC
  enable_dns_support   = true          # Enable DNS resolution within the VPC
  enable_dns_hostnames = true          # Allow instances to have public DNS hostnames

  tags = {
    Name = "neediumtgw-vpc-A"
  }
}

####################################################################
# Create an Internet Gateway (IGW) to allow outbound internet access
####################################################################
resource "aws_internet_gateway" "neediumtgw-igw-A" {
  vpc_id = aws_vpc.neediumtgw-vpc-A.id

  tags = {
    Name = "neediumtgw-igw-A"
  }
}

###################################################
# Create a route table for managing routing rules for pub
###################################################
resource "aws_route_table" "neediumtgw-rt-pub-A" {
  vpc_id = aws_vpc.neediumtgw-vpc-A.id

  tags = {
    Name = "neediumtgw-rt-pub-A"
  }
}

###################################################
# Create a route table for managing routing rules for priv
###################################################
resource "aws_route_table" "neediumtgw-rt-priv-A" {
  vpc_id = aws_vpc.neediumtgw-vpc-A.id

  tags = {
    Name = "neediumtgw-rt-priv-A"
  }
}

##############################################################################################
# Create a default route in the public route table to send all traffic to the Internet Gateway
##############################################################################################
resource "aws_route" "neediumtgw_default_route-A" {
  route_table_id         = aws_route_table.neediumtgw-rt-pub-A.id # Reference the public route table
  destination_cidr_block = "0.0.0.0/0"                            # Define the default route (all IPs allowed)
  gateway_id             = aws_internet_gateway.neediumtgw-igw-A.id
  # Use the Internet Gateway for outbound traffic
}

#####################################################
# Create the public subnet within the VPC
#####################################################
resource "aws_subnet" "neediumtgw-pub-A" {
  vpc_id = aws_vpc.neediumtgw-vpc.id
  cidr_block              = var.neediumtgw_pub_A
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2a"

  tags = {
    Name = "neediumtgw-pub-A"
  }
}

###########################################
# Create the private subnet within the VPC
###########################################
resource "aws_subnet" "neediumtgw-priv-A" {
  vpc_id = aws_vpc.neediumtgw-vpc-A.id
  cidr_block              = var.neediumtgw_priv_A
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2b"

  tags = {
    Name = "neediumtgw-priv-A"
  }
}

##################################################
# Associate the route table with the public subnet
##################################################
resource "aws_route_table_association" "neediumtgw_pub_assoc-A" {
  subnet_id      = aws_subnet.neediumtgw-pub-A.id
  route_table_id = aws_route_table.neediumtgw-rt-pub-A.id # Attach the route table
}

######################################################
# Associate the route table with the private subnet
######################################################
resource "aws_route_table_association" "neediumtgw_priv_assoc-A" {
  subnet_id      = aws_subnet.neediumtgw-priv-A.id         # Reference the second public subnet
  route_table_id = aws_route_table.neediumtgw-rt-priv-A.id # Attach the route table
}

####################################################
# Create the VPC attachment A
####################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "needium-tgw-attach-A" {
  transit_gateway_id = aws_ec2_transit_gateway.needium_tgw.id
  vpc_id             = aws_vpc.neediumtgw-vpc-A.id
  subnet_ids = [
    aws_subnet.neediumtgw-priv-A.id,
    aws_subnet.neediumtgw-pub-A.id
  ]
}

##############################################################
# Create the Transit Gateway Routes in each VPCs route table A
##############################################################
resource "aws_route" "needium_tgw_rt_A" {
  route_table_id         = aws_route_table.neediumtgw-rt-priv-A.id
  destination_cidr_block = var.destination_cidr_block_tgw
  gateway_id             = aws_ec2_transit_gateway.needium_tgw.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.needium-tgw-attach-A
  ]
}


#############################################################
# Create Networking Resources for the second Spoke (VPC B)
#############################################################

########################################
# Create a Virtual Private Cloud (VPC) B
########################################
resource "aws_vpc" "neediumtgw-vpc-B" {
  cidr_block           = var.neediumtgw_vpc_B # Define the IP address range for the VPC
  enable_dns_support   = true          # Enable DNS resolution within the VPC
  enable_dns_hostnames = true          # Allow instances to have public DNS hostnames

  tags = {
    Name = "neediumtgw-vpc-B"
  }
}

####################################################################
# Create an Internet Gateway (IGW) to allow outbound internet access
####################################################################
resource "aws_internet_gateway" "neediumtgw-igw-B" {
  vpc_id = aws_vpc.neediumtgw-vpc-B.id

  tags = {
    Name = "neediumtgw-igw-B"
  }
}

###################################################
# Create a route table for managing routing rules for pub
###################################################
resource "aws_route_table" "neediumtgw-rt-pub-B" {
  vpc_id = aws_vpc.neediumtgw-vpc-B.id

  tags = {
    Name = "neediumtgw-rt-pub-B"
  }
}

###################################################
# Create a route table for managing routing rules for priv
###################################################
resource "aws_route_table" "neediumtgw-rt-priv-B" {
  vpc_id = aws_vpc.neediumtgw-vpc-B.id

  tags = {
    Name = "neediumtgw-rt-priv-B"
  }
}

##############################################################################################
# Create a default route in the public route table to send all traffic to the Internet Gateway
##############################################################################################
resource "aws_route" "neediumtgw_default_route-B" {
  route_table_id         = aws_route_table.neediumtgw-rt-pub-B.id # Reference the public route table
  destination_cidr_block = "0.0.0.0/0"                            # Define the default route (all IPs allowed)
  gateway_id             = aws_internet_gateway.neediumtgw-igw-B.id
  # Use the Internet Gateway for outbound traffic
}

#####################################################
# Create the public subnet within the VPC
#####################################################
resource "aws_subnet" "neediumtgw-pub-B" {
  vpc_id = aws_vpc.neediumtgw-vpc.id
  cidr_block              = var.neediumtgw_pub_B
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2a"

  tags = {
    Name = "neediumtgw-pub"
  }
}

###########################################
# Create the private subnet within the VPC
###########################################
resource "aws_subnet" "neediumtgw-priv-B" {
  vpc_id = aws_vpc.neediumtgw-vpc-A.id
  cidr_block              = var.neediumtgw_priv_B
  map_public_ip_on_launch = true # automatically assign public IPs to instances
  availability_zone       = "us-east-2b"

  tags = {
    Name = "neediumtgw-priv-B"
  }
}

##################################################
# Associate the route table with the public subnet
##################################################
resource "aws_route_table_association" "neediumtgw_pub_assoc-B" {
  subnet_id      = aws_subnet.neediumtgw-pub-B.id
  route_table_id = aws_route_table.neediumtgw-rt-pub-B.id # Attach the route table
}

######################################################
# Associate the route table with the private subnet
######################################################
resource "aws_route_table_association" "neediumtgw_priv_assoc-B" {
  subnet_id      = aws_subnet.neediumtgw-priv-A.id         # Reference the second public subnet
  route_table_id = aws_route_table.neediumtgw-rt-priv-B.id # Attach the route table
}

####################################################
# Create the VPC attachment A
####################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "needium-tgw-attach-B" {
  transit_gateway_id = aws_ec2_transit_gateway.needium_tgw.id
  vpc_id             = aws_vpc.neediumtgw-vpc-B.id
  subnet_ids = [
    aws_subnet.neediumtgw-priv-B.id,
    aws_subnet.neediumtgw-pub-B.id
  ]
}

##############################################################
# Create the Transit Gateway Routes in each VPCs route table A
##############################################################
resource "aws_route" "needium_tgw_rt_B" {
  #count                  = length(var.route_table_ids)
  route_table_id         = aws_route_table.neediumtgw-rt-priv-B.id
  destination_cidr_block = var.destination_cidr_block_tgw
  gateway_id             = aws_ec2_transit_gateway.needium_tgw.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.needium-tgw-attach-B
  ]
}