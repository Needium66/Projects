//needium app with more security
//launching a linux instance with userdata


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

# creates the internet gateway
resource "aws_internet_gateway" "needlinux_igw" {
  vpc_id = aws_vpc.needlinux_vpc.id

  tags = {
    Name = "needlinux-igw"
  }
}

#creates eip
resource "aws_eip" "needlinux_eip_natgateway" {
  count = 2

  tags = {
    Name = "needlinux-eip"
  }
}

#creates nat gateways in public subnets
resource "aws_nat_gateway" "needlinux_natgateway" {
  count         = 2
  allocation_id = aws_eip.needlinux_eip_natgateway[count.index].id
  subnet_id     = aws_subnet.needlinux_public_subnet[count.index].id

  tags = {
    Name = "needlinux-nat-gateway"
  }
}

# creates the security group for web instances
resource "aws_security_group" "needlinux_sg" {
  name        = "needlinux_security_group"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.needlinux_vpc.id

  ingress {
    description = "ssh from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https from vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "needlinux-sg-web-server"
  }
}


#creates the security group for app instances
resource "aws_security_group" "needlinux_app_sg" {
  name        = "needlinux-app-security-group"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.needlinux_vpc.id

  ingress {
    description     = "ssh from vpc"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = [aws_security_group.needlinux_sg.id]
  }

  ingress {
    description     = "https from vpc"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = [aws_security_group.needlinux_sg.id]
  }

  ingress {
    description     = "http from vpc"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = [aws_security_group.needlinux_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "needlinux-sg-app-server"
  }
}

# creates the public subnet
resource "aws_subnet" "needlinux_public_subnet" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  count                   = length(var.needlinux_public_subnets_cidr)
  cidr_block              = element(var.needlinux_public_subnets_cidr, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "needlinux-publicsubnet-${count.index + 1}"
  }
}

#creates the private subnet
resource "aws_subnet" "needlinux_private_subnet" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  count                   = length(var.needlinux_private_subnets_cidr)
  cidr_block              = element(var.needlinux_private_subnets_cidr, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "needlinux-privatesubnet-${count.index + 1}"
  }
}

# creates the public route table
resource "aws_route_table" "needlinux_public_routetab" {
  vpc_id = aws_vpc.needlinux_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.needlinux_igw.id
  }

  tags = {
    Name = "needlinux-public-routetable"
  }
}

# attaches the public route table to the public subnet
resource "aws_route_table_association" "needlinux_public_route_ass" {
  count          = 2
  subnet_id      = element(aws_subnet.needlinux_public_subnet[*].id, count.index)
  route_table_id = aws_route_table.needlinux_public_routetab.id

}

#creates the private route table
resource "aws_route_table" "needlinux_private_routetab" {
  vpc_id = aws_vpc.needlinux_vpc.id
  count  = 2
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.needlinux_natgateway[count.index].id
  }

  tags = {
    Name = "needlinux-private-routetable"
  }
}

# attaches the private route table to the private subnet
resource "aws_route_table_association" "needlinux_private_route_ass" {
  count          = 2
  subnet_id      = element(aws_subnet.needlinux_private_subnet[*].id, count.index)
  route_table_id = aws_route_table.needlinux_private_routetab[count.index].id

}

//creates database security group
resource "aws_security_group" "needlinuxdb_sg" {
  name        = "needlinuxdb-sg"
  description = "Allow https from app server"
  vpc_id      = aws_vpc.needlinux_vpc.id

  //ingress rule creation
  ingress {
    description     = "db access"
    from_port       = 1433
    protocol        = "tcp"
    to_port         = 1433
    security_groups = [aws_security_group.needlinux_app_sg.id]
  }

  //egress
  egress {
    description = "outbound access"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database_sg"
  }

}

//creates database subnets
resource "aws_subnet" "needlinux_private_db_subnets_1" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  cidr_block              = var.needlinux_private_db_subnet_cidr_1
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "needlinux-db-subnet-1"
  }
}

resource "aws_subnet" "needlinux_private_db_subnets_2" {
  vpc_id                  = aws_vpc.needlinux_vpc.id
  cidr_block              = var.needlinux_private_db_subnet_cidr_2
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "needlinux-db-subnet2"
  }
}

//creates database route table route association
resource "aws_route_table_association" "needlinux_database_route_asso_1" {
  subnet_id      = aws_subnet.needlinux_private_db_subnets_1.id
  count          = 1
  route_table_id = aws_route_table.needlinux_private_routetab[count.index].id
}

resource "aws_route_table_association" "needlinux_database_route_asso_2" {
  subnet_id      = aws_subnet.needlinux_private_db_subnets_2.id
  count          = 1
  route_table_id = aws_route_table.needlinux_private_routetab[count.index].id
}

//creates db subnet group creation
resource "aws_db_subnet_group" "needlinux_database_subnet_group" {
  name       = "needlinux-database-subnet-group"
  subnet_ids = [aws_subnet.needlinux_private_db_subnets_1.id, aws_subnet.needlinux_private_db_subnets_2.id]

  tags = {
    Name = "needlinux-database-subnet-group"
  }
}

# creates an iam role for ec2 to be accessible through ssm
resource "aws_iam_role" "needlinux_ssm_role" {
  name = "needlinux-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#attaches the required ssm policy to the role for ec2 to be able to call ssm
resource "aws_iam_role_policy_attachment" "needlinux_ssm_policy_attachment" {
  role       = aws_iam_role.needlinux_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#creates an ec2 instance profile that is attached to the created ssm role
resource "aws_iam_instance_profile" "needlinux_instance_profile_for_ssm" {
  name = "neediumlinux_ec2_instance_profile"
  role = aws_iam_role.needlinux_ssm_role.name
}

# creates the EC2 web servers
resource "aws_instance" "needlinux_web_server" {
  ami                    = "ami-09da212cf18033880"
  instance_type          = var.needlinux_instance_type
  key_name               = var.needlinux_instance_key
  vpc_security_group_ids = [aws_security_group.needlinux_sg.id]
  count                  = 2
  subnet_id              = element(aws_subnet.needlinux_public_subnet[*].id, count.index)
  iam_instance_profile   = aws_iam_instance_profile.needlinux_instance_profile_for_ssm.name


  user_data = <<-EOF
 #!/bin/bash
 yum update -y
 yum install -y httpd.x86_64
 systemctl start httpd.service
 systemctl enable httpd.service

 TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")

 instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id --header "X-aws-ec2-metadata-token: $TOKEN")
 instanceAZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone --header "X-aws-ec2-metadata-token: $TOKEN")
 pubHostName=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
 pubIPv4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
 privHostName=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname --header "X-aws-ec2-metadata-token: $TOKEN")
 privIPv4=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 --header "X-aws-ec2-metadata-token: $TOKEN")
 
 echo "<font face = "Verdana" size = "5">" > /var/www/html/index.html
 echo "<center><h1>Needium Consulting Incorporated LLC</h1></center>" >> /var/www/html/index.html
 echo "<center> <b>Boutique Reseller</b> </center>" >> /var/www/html/index.html
 echo "<center> <b>Consulting:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>AWS:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Hardware:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Software:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Cybersecurity:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>GRC & Auditing:</b> Services </center>" >> /var/www/html/index.html
 echo "</font>" >> /var/www/html/index.html
EOF

  tags = {
    Name = "needlinux-web-${count.index + 1}"
  }
}

#creates certificate manager
resource "aws_acm_certificate" "needlinux_acm" {
  domain_name               = "web.${var.domain_name}"
  subject_alternative_names = ["*.web.${var.domain_name}"]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  #  tags = {
  #    Name = "needlinux-web-certificate
  #  }
}

#route 53 entry to perform auto validation
data "aws_route53_zone" "selected_zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "needlinux_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.needlinux_acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected_zone.zone_id
}

#creates dns validating certificate
resource "aws_acm_certificate_validation" "needlinux_cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.needlinux_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.needlinux_cert_validation_record : record.fqdn]
}

#creates the loadbalancer security group
resource "aws_security_group" "needlinux-sg-load-balancer" {
  description = "allows incoming connections for load balancer"
  vpc_id      = aws_vpc.needlinux_vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow incoming https connections"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "needlinux-sg-alb"
  }
}

#creates load balancer
resource "aws_lb" "needlinux_load_balancer" {
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.needlinux-sg-load-balancer.id]
  subnets                    = aws_subnet.needlinux_public_subnet.*.id
  enable_deletion_protection = false

  tags = {
    Name = "needlinux-alb"
  }
}

#creates target group for alb
resource "aws_lb_target_group" "needlinux_alb_target_group" {
  target_type = "instance"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.needlinux_vpc.id

  health_check {
    enabled             = true
    interval            = 60
    path                = "/"
    timeout             = 30
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "needlinux-alb-tg"
  }
}

#creates listener on port 80 with redirect
resource "aws_lb_listener" "neediumlinux_alb_http_listener" {
  load_balancer_arn = aws_lb.needlinux_load_balancer.id
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.needlinux_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.needlinux_alb_target_group.id
  }
}

#attaches target group to the instance
resource "aws_alb_target_group_attachment" "needlinux_tgattachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.needlinux_alb_target_group.arn
  target_id        = aws_instance.needlinux_web_server.*.id[count.index]
}

#creates route 53 record
resource "aws_route53_record" "needlinux_route53_A_record" {
  zone_id = data.aws_route53_zone.selected_zone.zone_id
  name    = "web.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.needlinux_load_balancer.dns_name
    zone_id                = aws_lb.needlinux_load_balancer.zone_id
    evaluate_target_health = true
  }
}

# creates the app servers
resource "aws_instance" "needlinux_app_server" {
  ami                    = "ami-09da212cf18033880"
  instance_type          = var.needlinux_instance_type
  key_name               = var.needlinux_instance_key
  vpc_security_group_ids = [aws_security_group.needlinux_app_sg.id]
  count                  = 2
  subnet_id              = element(aws_subnet.needlinux_private_subnet[*].id, count.index)
  iam_instance_profile   = aws_iam_instance_profile.needlinux_instance_profile_for_ssm.name


  user_data = <<-EOF
 #!/bin/bash
 yum update -y
 yum install -y httpd.x86_64
 systemctl start httpd.service
 systemctl enable httpd.service

 TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")

 instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id --header "X-aws-ec2-metadata-token: $TOKEN")
 instanceAZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone --header "X-aws-ec2-metadata-token: $TOKEN")
 pubHostName=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
 pubIPv4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
 privHostName=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname --header "X-aws-ec2-metadata-token: $TOKEN")
 privIPv4=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 --header "X-aws-ec2-metadata-token: $TOKEN")
 
 echo "<font face = "Verdana" size = "5">" > /var/www/html/index.html
 echo "<center><h1>Needium Consulting Incorporated LLC</h1></center>" >> /var/www/html/index.html
 echo "<center> <b>Boutique Reseller</b> </center>" >> /var/www/html/index.html
 echo "<center> <b>Consulting:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>AWS:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Hardware:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Software:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>Cybersecurity:</b> Services </center>" >> /var/www/html/index.html
 echo "<center> <b>GRC & Auditing:</b> Services </center>" >> /var/www/html/index.html
 echo "</font>" >> /var/www/html/index.html
EOF

  tags = {
    Name = "needlinux-app-${count.index + 1}"
  }
}

//creates the db instance for mssql
resource "aws_db_instance" "needlinux_db_instance" {
  allocated_storage      = 20
  engine                 = "sqlserver-ex"
  engine_version         = "15.00"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  availability_zone      = "us-east-2a"
  identifier             = "needlinux-database-mssql"
  db_subnet_group_name   = aws_db_subnet_group.needlinux_database_subnet_group.name
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.needlinuxdb_sg.id]
  storage_encrypted      = false # encryption at rest is not available for DB instances running SQL Server Express Edition
  #  kms_key_id             = aws_kms_key.nincappnew_kms_key.arn # not needed for express edition
  license_model = "license-included"
}

#nessus scanner block
module "nessus_scanner" {
  source = "github.com/BuyerQuest/terraform-tenable-nessus-scanner-aws"

  scanner_name        = "neediumlinux Nessus Scanner"
  tenable_linking_key = "pvwk5qf5bwsuperfakekeypqv3zcovanqnuawebmv23rj9fofsdcul7aaa"
  vpc_id              = aws_vpc.needlinux_vpc.id
  count               = 1
  subnet_id           = element(aws_subnet.needlinux_private_subnet[*].id, count.index)
  instance_type       = var.needlinux_instance_type
  instance_name       = "needlinux-nessus-scanner"

  instance_tags = {
    name    = "security-scanner"
    purpose = "tenable"
  }

  extra_filters = [
    {
      name   = "image-id"
      values = ["ami-0e2e293e46c009d6f"] # Use a specific AMI instead of the latest available image
    }
  ]
}

# creates the nessus security groups
resource "aws_security_group" "needlinux-nessus-security-group" {
  name        = "needlinux-tenable-security"
  description = "security group for the Nessus VM Scanner Server instance (Deny all inbound)"
  vpc_id      = aws_vpc.needlinux_vpc.id

  # nessus port
  ingress {
    from_port   = 8834
    to_port     = 8834
    protocol    = "tcp"
    cidr_blocks = ["${var.ip_address}"]
  }
}

# the documentation for tenable on aws recommends a security group with
# no entries in it, but mine had a problem without the egress rule.

# outbound traffic
resource "aws_security_group_rule" "needlinux-nessus-allow-outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.needlinux-nessus-security-group.id
}

# nessus iam role
resource "aws_iam_role" "needlinux-nessus-server-role" {
  name               = "needlinux-nessus-role"
  assume_role_policy = data.aws_iam_policy_document.needlinux-nessus-instance-assume-role-policy.json
}

# role assumption policy
data "aws_iam_policy_document" "needlinux-nessus-instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# attaches ec2 read-only policy to the iam role
resource "aws_iam_role_policy_attachment" "needlinux-nessus-ec2-read-only" {
  role       = aws_iam_role.needlinux-nessus-server-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# assigns the role to the instance profile
resource "aws_iam_instance_profile" "needlinux-nessus-server-profile" {
  name = "needlinux-nessus-instance-profile"
  role = aws_iam_role.needlinux-nessus-server-role.name
}

# finds the latest AMI by product code
data "aws_ami" "nessus-image" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["8fn69npzmbzcs4blc4583jd0y"]
  }

  dynamic "filter" {
    for_each = var.extra_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}


####################################################
# AWS RDS Aurora MySQL
####################################################

#https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest

module "aurora" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "7.2.2"

  #name            = local.name
  name            = ${local.name}-aurora-mysql
  engine          = "aurora-mysql"
  engine_version  = "serverless"
  storage_encrypted = true
  database_name     = "Need-database"
  tags              = local.tags


  #vpc_id               = module.vpc.vpc_id
  vpc_id               = aws_vpc.needlinux_vpc.id
  #db_subnet_group_name = module.vpc.database_subnet_group_name
  db_subnet_group_name = aws_db_subnet_group.needlinux_database_subnet_group.name
  create_security_group = true
  allowed_cidr_blocks   =

  monitoring_interval = 60
  enable_http_endpoint = true
  publicly accessible = true

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name  = aws_db_parameter_group.serverless-mysql.
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.serverless-mysql.id

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 1800
    timeout_action           = "ForceApplyCapacityChange"
  }
}
  

################################