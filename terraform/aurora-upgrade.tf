###################################################
# rds aurora mysql
###################################################

#requests list of availability zones
data "aws_availability_zones" "available_zones" {
  state = "available"
}


# creates the vpc
resource "aws_vpc" "needlinux_vpc" {
  cidr_block           = var.needlinux_vpc_cidr_block
  enable_dns_hostnames = var.needlinux_enable_dns_hostnames

  tags = {
    Name = "needlinux-vpc"
  }
}



resource "aws_subnet" "needlinux_private_db_subnet" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  count                   = length(var.needlinux_private_db_subnets_cidr)
  cidr_block              = element(var.needlinux_private_db_subnets_cidr, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "needlinux-db-privatesubnet-${count.index + 1}"
  }
}

resource "aws_subnet" "needlinux_private_subnet" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  count                   = length(var.needlinux_private_subnets_cidr)
  cidr_block              = element(var.needlinux_private_subnets_cidr, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "needlinux-privatesubnet-${count.index + 1}"
  }
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.2.2"

  name              = "needlinux-db-aurora-mysql"
  engine            = "aurora-mysql"
  engine_mode       = "serverless"
  storage_encrypted = true
  tags = {
    Name = "needlinux-db"
  }


  vpc_id                = aws_vpc.needlinux_vpc.id
  subnets               = aws_subnet.needlinux_private_db_subnet.*.id
  create_security_group = true
  allowed_cidr_blocks   = aws_subnet.needlinux_private_subnet.*.id

  monitoring_interval  = 60
  enable_http_endpoint = true
  publicly_accessible  = true

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.needlinux_db_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.needlinux_db_cluster_parameter_group.id

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 1800
    timeout_action           = "ForceApplyCapacityChange"
  }
}

resource "aws_db_parameter_group" "needlinux_db_parameter_group" {
  name        = "needlinux-db"
  family      = "aurora-mysql5.7"
  description = "needlinux-db-aurora-db-parameter-group"

}

resource "aws_rds_cluster_parameter_group" "needlinux_db_cluster_parameter_group" {
  name        = "needlinux-db-aurora-57-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "needlinux-db-aurora-57-cluster-parameter-group"
  tags = {
    Name = "needlinux-database-cluster-parameter-group"
  }
}