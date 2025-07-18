########################################################################
#main file for the terraform configuration of resources
#########################################################################
# main.tf

provider "aws" {
  region = var.aws_region
}

# --- VPC, Subnets, and Security Groups ---

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "microservices-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true # For ALB internet-facing

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microservices-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for private subnets to access internet (e.g., for Lambda/ECS updates)
resource "aws_eip" "nat_a" {
  vpc = true
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-gateway-a"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Security Group for API Gateway to allow inbound traffic (not directly used for API GW)
# API Gateway is public by default, this SG is for resources it integrates with if they are in VPC.
resource "aws_security_group" "api_gateway_sg" {
  name_prefix = "api-gateway-access-"
  description = "Allow HTTP/HTTPS access from API Gateway"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # API Gateway is public, so allow from anywhere for simplicity
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "api-gateway-security-group"
  }
}

# Security Group for Lambdas (if they need VPC access for RDS/DynamoDB)
resource "aws_security_group" "lambda_sg" {
  name_prefix = "lambda-access-"
  description = "Allow outbound access for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound for simplicity
  }

  tags = {
    Name = "lambda-security-group"
  }
}

# Security Group for ALBs
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-access-"
  description = "Allow HTTP/HTTPS access to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "alb-security-group"
  }
}

# Security Group for ECS Tasks (Pharmacy)
resource "aws_security_group" "ecs_tasks_sg" {
  name_prefix = "ecs-tasks-"
  description = "Allow inbound from ALB and outbound to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80 # Or your application port
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound for simplicity, refine for production
  }

  tags = {
    Name = "ecs-tasks-security-group"
  }
}

# Security Group for EC2 Instances (Personal Health Management)
resource "aws_security_group" "ec2_instances_sg" {
  name_prefix = "ec2-instances-"
  description = "Allow inbound from ALB and outbound to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80 # Or your application port
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound for simplicity, refine for production
  }

  tags = {
    Name = "ec2-instances-security-group"
  }
}

# Security Group for RDS PostgreSQL
resource "aws_security_group" "rds_postgres_sg" {
  name_prefix = "rds-postgres-"
  description = "Allow inbound from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432 # PostgreSQL default port
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id] # Allow from ECS tasks
  }

  tags = {
    Name = "rds-postgres-security-group"
  }
}

# Security Group for RDS MSSQL
resource "aws_security_group" "rds_mssql_sg" {
  name_prefix = "rds-mssql-"
  description = "Allow inbound from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1433 # MSSQL default port
    to_port     = 1433
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_instances_sg.id] # Allow from EC2 instances
  }

  tags = {
    Name = "rds-mssql-security-group"
  }
}

# --- IAM Roles for Lambda Functions ---

resource "aws_iam_role" "lambda_exec_role" {
  name_prefix = "api-gateway-lambda-exec-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_read_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess" # For Lambda to read from SQS
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" # For Lambda to write to DynamoDB
}

# Policy for Lambda to access VPC resources (needed for RDS, if Lambda were to connect directly)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM Role for API Gateway to send messages to SQS
resource "aws_iam_role" "api_gateway_sqs_role" {
  name_prefix = "api-gateway-sqs-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_sqs_policy" {
  name = "api-gateway-sqs-publish-policy"
  role = aws_iam_role.api_gateway_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
        ]
        Effect   = "Allow"
        Resource = "*" # Will restrict to specific queue ARNs later
      },
    ]
  })
}

# --- Lambda Functions for Microservices ---

# Authentication Lambda (FusionAuth Custom Authorizer)
resource "aws_lambda_function" "auth_lambda" {
  function_name = "fusionauth-custom-authorizer"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.auth_lambda_zip.output_path
  source_code_hash = data.archive_file.auth_lambda_zip.output_base64sha256

  environment {
    variables = {
      FUSIONAUTH_DOMAIN  = var.fusionauth_domain
      FUSIONAUTH_API_KEY = var.fusionauth_api_key # Consider Secrets Manager for production
    }
  }
  # Lambdas that need to access VPC resources must be in a VPC
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

data "archive_file" "auth_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/auth_lambda"
  output_path = "lambdas/auth_lambda.zip"
}

# Payment Microservice Lambda (triggered by SQS)
resource "aws_lambda_function" "payment_sqs_lambda" {
  function_name = "payment-sqs-processor"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.payment_sqs_lambda_zip.output_path
  source_code_hash = data.archive_file.payment_sqs_lambda_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

data "archive_file" "payment_sqs_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/payment_sqs_lambda"
  output_path = "lambdas/payment_sqs_lambda.zip"
}

# Telemedicine Microservice Lambda (triggered by SQS)
resource "aws_lambda_function" "telemedicine_sqs_lambda" {
  function_name = "telemedicine-sqs-processor"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.telemedicine_sqs_lambda_zip.output_path
  source_code_hash = data.archive_file.telemedicine_sqs_lambda_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

data "archive_file" "telemedicine_sqs_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/telemedicine_sqs_lambda"
  output_path = "lambdas/telemedicine_sqs_lambda.zip"
}

# Placeholder Lambdas for ECS/EC2 (not directly invoked by API GW, but needed for zip data source)
resource "aws_lambda_function" "pharmacy_ecs_lambda_placeholder" {
  function_name = "pharmacy-ecs-placeholder"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.pharmacy_ecs_lambda_zip.output_path
  source_code_hash = data.archive_file.pharmacy_ecs_lambda_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

data "archive_file" "pharmacy_ecs_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/pharmacy_ecs_lambda"
  output_path = "lambdas/pharmacy_ecs_lambda.zip"
}

resource "aws_lambda_function" "pfm_ec2_lambda_placeholder" {
  function_name = "pfm-ec2-placeholder"
  handler       = "main.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = data.archive_file.pfm_ec2_lambda_zip.output_path
  source_code_hash = data.archive_file.pfm_ec2_lambda_zip.output_base64sha256
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

data "archive_file" "pfm_ec2_lambda_zip" {
  type        = "zip"
  source_dir  = "lambdas/pfm_ec2_lambda"
  output_path = "lambdas/pfm_ec2_lambda.zip"
}

# --- SQS Queues ---

resource "aws_sqs_queue" "payment_queue" {
  name                      = "payment-microservice-queue"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30
}

resource "aws_sqs_queue" "telemedicine_queue" {
  name                      = "telemedicine-microservice-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30
}

# --- SQS Event Source Mappings for Lambdas ---

resource "aws_lambda_event_source_mapping" "payment_sqs_event_source" {
  event_source_arn = aws_sqs_queue.payment_queue.arn
  function_name    = aws_lambda_function.payment_sqs_lambda.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "telemedicine_sqs_event_source" {
  event_source_arn = aws_sqs_queue.telemedicine_queue.arn
  function_name    = aws_lambda_function.telemedicine_sqs_lambda.arn
  batch_size       = 10
  enabled          = true
}

# --- DynamoDB Tables ---

resource "aws_dynamodb_table" "payment_data" {
  name         = "PaymentData"
  billing_mode = "PAY_PER_REQUEST" # On-demand capacity

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  tags = {
    Name = "PaymentDataTable"
  }
}

resource "aws_dynamodb_table" "telemedicine_data" {
  name         = "TelemedicineData"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  tags = {
    Name = "TelemedicineDataTable"
  }
}

# --- RDS PostgreSQL for Pharmacy ---

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "postgres-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "PostgreSQL Subnet Group"
  }
}

resource "aws_db_instance" "pharmacy_postgres_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = "db.t3.micro"
  name                 = "pharmacydb"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_postgres_sg.id]
  skip_final_snapshot  = true # Set to false for production
  publicly_accessible  = false

  tags = {
    Name = "PharmacyPostgreSQLDB"
  }
}

# --- RDS MSSQL for Personal Health Management ---

resource "aws_db_subnet_group" "mssql_subnet_group" {
  name       = "mssql-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "MSSQL Subnet Group"
  }
}

resource "aws_db_instance" "pfm_mssql_db" {
  allocated_storage    = 20
  engine               = "sqlserver-express" # Or other SQL Server editions
  engine_version       = "15.00.4153.1" # Example version
  instance_class       = "db.t3.micro"
  name                 = "pfmdb"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.mssql_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_mssql_sg.id]
  skip_final_snapshot  = true # Set to false for production
  publicly_accessible  = false

  tags = {
    Name = "PFMMSSQLDB"
  }
}

# --- ECS Cluster for Pharmacy ---

resource "aws_ecs_cluster" "pharmacy_cluster" {
  name = "pharmacy-ecs-cluster"

  tags = {
    Name = "PharmacyECSCluster"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition (Fargate example for simplicity)
resource "aws_ecs_task_definition" "pharmacy_task_def" {
  family                   = "pharmacy-service"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name        = "pharmacy-app"
      image       = "nginx:latest" # Replace with your actual Pharmacy microservice image
      essential   = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.pharmacy_postgres_db.address
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.pharmacy_postgres_db.name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.pharmacy_postgres_db.username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password # Use Secrets Manager in production
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/pharmacy-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_pharmacy_logs" {
  name              = "/ecs/pharmacy-service"
  retention_in_days = 7
}

resource "aws_ecs_service" "pharmacy_service" {
  name            = "pharmacy-service"
  cluster         = aws_ecs_cluster.pharmacy_cluster.id
  task_definition = aws_ecs_task_definition.pharmacy_task_def.arn
  desired_count   = 1 # Start with 1 instance
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pharmacy_tg.arn
    container_name   = "pharmacy-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.pharmacy_listener] # Ensure listener is ready
}

# --- EC2 Instance for Personal Health Management ---

resource "aws_instance" "pfm_ec2_instance" {
  ami           = "ami-0abcdef1234567890" # Replace with a valid AMI ID for your region (e.g., Amazon Linux 2 or Windows Server for MSSQL)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_a.id
  security_groups = [aws_security_group.ec2_instances_sg.id]
  key_name      = var.ec2_key_pair_name # Optional: for SSH access, if needed
  associate_public_ip_address = false # Private instance behind ALB

  # User data to install a simple web server (e.g., Nginx) or your application
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from Personal Health Management EC2!" > /var/www/html/index.html
              # Add commands to install your MSSQL application and configure it
              # For a Windows instance, this would be PowerShell commands
              EOF

  tags = {
    Name = "PFM-EC2-Instance"
  }
}

# --- Application Load Balancers (ALB) ---

# ALB for Pharmacy
resource "aws_lb" "pharmacy_alb" {
  name               = "pharmacy-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "PharmacyALB"
  }
}

resource "aws_lb_target_group" "pharmacy_tg" {
  name     = "pharmacy-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip" # For Fargate tasks

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }

  tags = {
    Name = "PharmacyTargetGroup"
  }
}

resource "aws_lb_listener" "pharmacy_listener" {
  load_balancer_arn = aws_lb.pharmacy_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pharmacy_tg.arn
  }
}

# ALB for Personal Health Management
resource "aws_lb" "pfm_alb" {
  name               = "pfm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "PFMALB"
  }
}

resource "aws_lb_target_group" "pfm_tg" {
  name     = "pfm-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance" # For EC2 instances

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }

  tags = {
    Name = "PFMTargetGroup"
  }
}

resource "aws_lb_target_group_attachment" "pfm_tg_attachment" {
  target_group_arn = aws_lb_target_group.pfm_tg.arn
  target_id        = aws_instance.pfm_ec2_instance.id
  port             = 80
}

resource "aws_lb_listener" "pfm_listener" {
  load_balancer_arn = aws_lb.pfm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pfm_tg.arn
  }
}

# --- API Gateway REST API ---

resource "aws_api_gateway_rest_api" "microservices_api" {
  name        = "MicroservicesAPI"
  description = "API Gateway for fan-out microservices"
}

# --- Custom Authorizer (FusionAuth Integration) ---

resource "aws_api_gateway_authorizer" "fusionauth_authorizer" {
  name                   = "FusionAuthAuthorizer"
  type                   = "TOKEN" # For JWT validation
  rest_api_id            = aws_api_gateway_rest_api.microservices_api.id
  authorizer_uri         = aws_lambda_function.auth_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.lambda_exec_role.arn # Role for API Gateway to invoke Lambda
  identity_source        = "method.request.header.Authorization" # Where to find the JWT
  identity_validation_expression = "^Bearer [a-zA-Z0-9\\-_\\.]+$" # Basic regex for Bearer token
  authorizer_result_ttl_in_seconds = 300 # Cache results for 5 minutes
}

# Grant API Gateway permission to invoke the authorizer Lambda
resource "aws_lambda_permission" "apigw_auth_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuthLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.microservices_api.execution_arn}/*"
}

# --- API Gateway Resources (Paths) and Methods ---

# Root path for all microservices
resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "{proxy+}" # Catch-all for sub-paths, though specific paths are defined below
}

# --- Payment Service (API Gateway -> SQS) ---
resource "aws_api_gateway_resource" "payment_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "payments"
}

resource "aws_api_gateway_resource" "payment_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.payment_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "payment_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.payment_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "payment_sqs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.payment_proxy_resource.id
  http_method             = aws_api_gateway_method.payment_method_any.http_method
  type                    = "AWS" # AWS service integration
  integration_http_method = "POST" # SQS SendMessage is a POST operation
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.payment_queue.name}"
  credentials             = aws_iam_role.api_gateway_sqs_role.arn # Role for API Gateway to send to SQS

  request_templates = {
    "application/json" = <<-EOT
      Action=SendMessage&MessageBody=$util.urlEncode("$input.body")&MessageDeduplicationId=$context.requestId&MessageGroupId=payment-group
    EOT
  }

  passthrough_behavior = "NEVER" # Ensure template is used
  content_handling     = "CONVERT_TO_TEXT" # Ensure body is text for SQS
}

# --- Telemedicine Service (API Gateway -> SQS) ---
resource "aws_api_gateway_resource" "telemedicine_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "telemedicine"
}

resource "aws_api_gateway_resource" "telemedicine_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.telemedicine_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "telemedicine_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.telemedicine_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "telemedicine_sqs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.telemedicine_proxy_resource.id
  http_method             = aws_api_gateway_method.telemedicine_method_any.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.telemedicine_queue.name}"
  credentials             = aws_iam_role.api_gateway_sqs_role.arn

  request_templates = {
    "application/json" = <<-EOT
      Action=SendMessage&MessageBody=$util.urlEncode("$input.body")&MessageDeduplicationId=$context.requestId&MessageGroupId=telemedicine-group
    EOT
  }

  passthrough_behavior = "NEVER"
  content_handling     = "CONVERT_TO_TEXT"
}

# --- Pharmacy Service (API Gateway -> ALB -> ECS) ---
resource "aws_api_gateway_resource" "pharmacy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "pharmacy"
}

resource "aws_api_gateway_resource" "pharmacy_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.pharmacy_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "pharmacy_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.pharmacy_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "pharmacy_alb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.pharmacy_proxy_resource.id
  http_method             = aws_api_gateway_method.pharmacy_method_any.http_method
  type                    = "HTTP_PROXY" # HTTP Proxy integration for ALB
  integration_http_method = "ANY"        # Pass through original HTTP method
  uri                     = "${aws_lb_listener.pharmacy_listener.arn}/" # Use listener ARN for ALB integration
  connection_type         = "VPC_LINK" # If ALB is in private VPC, use VPC Link
  # For simplicity, assuming ALB is public-facing and accessible directly.
  # If ALB is internal, you'd need aws_api_gateway_vpc_link and connection_id.
  # For this example, we'll use the ALB's DNS name directly as the URI.
  # Note: API Gateway HTTP_PROXY integration to ALB directly uses ALB's DNS name.
  # The URI should be the full URL to the ALB.
  uri = "http://${aws_lb.pharmacy_alb.dns_name}/{proxy}" # ALB DNS name with proxy path
}

# --- Personal Health Management Service (API Gateway -> ALB -> EC2) ---
resource "aws_api_gateway_resource" "pfm_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = "personal-health-management"
}

resource "aws_api_gateway_resource" "pfm_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.pfm_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "pfm_method_any" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.pfm_proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.fusionauth_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "pfm_alb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.pfm_proxy_resource.id
  http_method             = aws_api_gateway_method.pfm_method_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.pfm_alb.dns_name}/{proxy}" # ALB DNS name with proxy path
}

# --- API Gateway Deployment and Stage ---

resource "aws_api_gateway_deployment" "microservices_deployment" {
  rest_api_id = aws_api_gateway_rest_api.microservices_api.id
  # Note: The `triggers` block forces a new deployment on API changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root_resource.id,
      aws_api_gateway_method.payment_method_any.id,
      aws_api_gateway_integration.payment_sqs_integration.id,
      aws_api_gateway_method.telemedicine_method_any.id,
      aws_api_gateway_integration.telemedicine_sqs_integration.id,
      aws_api_gateway_method.pharmacy_method_any.id,
      aws_api_gateway_integration.pharmacy_alb_integration.id,
      aws_api_gateway_method.pfm_method_any.id,
      aws_api_gateway_integration.pfm_alb_integration.id,
      aws_api_gateway_authorizer.fusionauth_authorizer.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.microservices_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  stage_name    = "prod"
  description   = "Production stage"

  # Enable CloudWatch logs
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      "requestId" : "$context.requestId",
      "ip" : "$context.identity.sourceIp",
      "caller" : "$context.identity.caller",
      "user" : "$context.identity.user",
      "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength"
    })
  }

  xray_tracing_enabled = true # Enable X-Ray tracing for better observability
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/microservices-api"
  retention_in_days = 7
}

# --- API Key and Usage Plan for Rate Limiting ---

resource "aws_api_gateway_api_key" "main_api_key" {
  name        = "MicroservicesAPIKey"
  description = "API Key for accessing Microservices API"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "high_throughput_plan" {
  name        = "HighThroughputPlan"
  description = "Usage plan for high throughput users"

  api_stages {
    api_id = aws_api_gateway_rest_api.microservices_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
    throttle {
      path        = "ANY /payments/{proxy+}"
      rate_limit  = 100
      burst_limit = 200
    }
    throttle {
      path        = "ANY /telemedicine/{proxy+}"
      rate_limit  = 50
      burst_limit = 100
    }
    throttle {
      path        = "ANY /pharmacy/{proxy+}"
      rate_limit  = 50
      burst_limit = 100
    }
    throttle {
      path        = "ANY /personal-health-management/{proxy+}"
      rate_limit  = 20
      burst_limit = 40
    }
  }

  quota_settings {
    limit  = 100000
    period = "MONTH"
  }
}

resource "aws_api_gateway_usage_plan_key" "main_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.main_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.high_throughput_plan.id
}

# --- Response Processing (Example for 4xx/5xx errors) ---

resource "aws_api_gateway_gateway_response" "unauthorized_response" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  response_type = "UNAUTHORIZED"
  status_code   = "401"
  response_templates = {
    "application/json" = jsonencode({
      "message" : "$context.error.messageString",
      "code" : "UNAUTHORIZED"
    })
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
  }
}

resource "aws_api_gateway_gateway_response" "bad_request_response" {
  rest_api_id   = aws_api_gateway_rest_api.microservices_api.id
  response_type = "BAD_REQUEST_BODY"
  status_code   = "400"
  response_templates = {
    "application/json" = jsonencode({
      "message" : "Invalid request body.",
      "details" : "$context.error.validationErrorString"
    })
  }
}