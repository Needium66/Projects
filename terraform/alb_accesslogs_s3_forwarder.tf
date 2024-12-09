###################################################
# alb access logs integration with s3
###################################################

---------------------------------------------------------------------------------------------------------------------------------------
#for security purposes, logging, troubleshooting and other reasons, you may need to track how traffic flows into your application
#in order to do that successfully, you will need to store it in a place. then you can use it for whatever you like
#this configurations describe the first part of 2 series that will involve the ingestion of alb access logs into an observability troubleshooting
#e.g grafana where it will be useful eventually.
#the focus of this deployment is to integrate alb accesslogs with an s3 bucket
----------------------------------------------------------------------------------------------------------------------------------------

#requests list of availability zones
data "aws_availability_zones" "available_zones" {
  state = "available"
}


# creates the vpc
resource "aws_vpc" "needaccess_vpc" {
  cidr_block           = var.needlinux_vpc_cidr_block
  enable_dns_hostnames = var.needlinux_enable_dns_hostnames

  tags = {
    Name = "needaccess-vpc"
  }
}

# creates the internet gateway
resource "aws_internet_gateway" "needaccess_igw" {
  vpc_id = aws_vpc.needaccess_vpc.id

  tags = {
    Name = "needaccess-igw"
  }
}

#creates eip
resource "aws_eip" "needaccess_eip_natgateway" {
  count = 1

  tags = {
    Name = "needaccess-eip"
  }
}

#creates nat gateways in public subnets
resource "aws_nat_gateway" "needaccess_natgateway" {
  count         = 1
  allocation_id = aws_eip.needaccess_eip_natgateway[count.index].id
  subnet_id     = aws_subnet.needaccess_public_subnet[count.index].id

  tags = {
    Name = "needaccess-nat-gateway"
  }
}

# creates the public subnet
resource "aws_subnet" "needaccess_public_subnet" {
  vpc_id                  = aws_vpc.needaccess_vpc.id
  count                   = length(var.needlinux_public_subnets_cidr)
  cidr_block              = element(var.needlinux_public_subnets_cidr, count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "needaccess-publicsubnet-${count.index + 1}"
  }
}

# creates the public route table
resource "aws_route_table" "needaccess_public_routetab" {
  vpc_id = aws_vpc.needaccess_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.needaccess_igw.id
  }

  tags = {
    Name = "needaccess-public-routetable"
  }
}

# attaches the public route table to the public subnet
resource "aws_route_table_association" "needaccess_public_route_ass" {
  count          = 2
  subnet_id      = element(aws_subnet.needaccess_public_subnet[*].id, count.index)
  route_table_id = aws_route_table.needaccess_public_routetab.id

}

# creates the security group for web instances
resource "aws_security_group" "needaccess_sg" {
  name        = "needaccess_security_group"
  description = "allows inbound traffic"
  vpc_id      = aws_vpc.needaccess_vpc.id

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
    Name = "needaccess-sg-web-server"
  }
}

# creates an iam role for ec2 to be accessible through ssm
resource "aws_iam_role" "needaccess_ssm_role" {
  name = "needaccess-ssm-role"
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
resource "aws_iam_role_policy_attachment" "needaccess_ssm_policy_attachment" {
  role       = aws_iam_role.needaccess_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#creates an ec2 instance profile that is attached to the created ssm role
resource "aws_iam_instance_profile" "needaccess_instance_profile_for_ssm" {
  name = "neediumaccess_ec2_instance_profile"
  role = aws_iam_role.needaccess_ssm_role.name
}

# creates the EC2 web servers
resource "aws_instance" "needaccess_web_server" {
  ami           = "ami-08be1e3e6c338b037"
  instance_type = var.instance_type
  #key_name               = var.needlinux_instance_key
  vpc_security_group_ids = [aws_security_group.needaccess_sg.id]
  count                  = 2
  subnet_id              = element(aws_subnet.needaccess_public_subnet[*].id, count.index)
  iam_instance_profile   = aws_iam_instance_profile.needaccess_instance_profile_for_ssm.name

  tags = {
    Name = "needaccess-web-${count.index + 1}"
  }
}

#creates certificate manager
resource "aws_acm_certificate" "needaccess_acm" {
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

resource "aws_route53_record" "needaccess_cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.needaccess_acm.domain_validation_options : dvo.domain_name => {
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
resource "aws_acm_certificate_validation" "needaccess_cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.needaccess_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.needaccess_cert_validation_record : record.fqdn]
}

#create s3 bucket with required permissions
resource "aws_s3_bucket" "needaccess_logs" {
  bucket = "needaccess-logs"
  acl    = "private"

  tags = {
    name = "needaccess"
  }
}

resource "aws_s3_bucket_policy" "needaccess_logs_policy" {
  bucket = aws_s3_bucket.needaccess_logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::033677994240:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::needaccess-logs/alb/needaccess_load_balancer/AWSLogs/058264335367/*"
    }
  ]
}
POLICY
}

#creates the loadbalancer security group
resource "aws_security_group" "needaccess-sg-load-balancer" {
  description = "allows incoming connections for load balancer"
  vpc_id      = aws_vpc.needaccess_vpc.id
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
    Name = "needaccess-sg-alb"
  }
}

#creates load balancer
resource "aws_lb" "needaccess_load_balancer" {
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.needaccess-sg-load-balancer.id]
  subnets                    = aws_subnet.needaccess_public_subnet.*.id
  enable_deletion_protection = false

  access_logs {
    enabled = true
    bucket  = "needaccess-logs"
    prefix  = "alb/needaccess_load_balancer"
  }

  tags = {
    Name = "needaccess-alb"
  }
}

#creates target group for alb
resource "aws_lb_target_group" "needaccess_alb_target_group" {
  target_type = "instance"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.needaccess_vpc.id

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
    Name = "needaccess-alb-tg"
  }
}

#creates listener on port 80 with redirect
resource "aws_lb_listener" "neediumaccess_alb_http_listener" {
  load_balancer_arn = aws_lb.needaccess_load_balancer.id
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.needaccess_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.needaccess_alb_target_group.id
  }
}

#attaches target group to the instance
resource "aws_alb_target_group_attachment" "needaccess_tgattachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.needaccess_alb_target_group.arn
  target_id        = aws_instance.needaccess_web_server.*.id[count.index]
}