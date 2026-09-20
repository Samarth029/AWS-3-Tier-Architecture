# ============================================================
# AWS 3-Tier WordPress Architecture
# Terraform Recreation / Infrastructure as Code
# Region: ap-south-1
# ============================================================


# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "My-Enterprise-VPC"
    Environment = var.environment
  }
}


# ============================================================
# SUBNETS
# ============================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public-Subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.az_1

  tags = {
    Name        = "Private-Subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public-Subnet-2"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.az_2

  tags = {
    Name        = "Private-Subnet-2"
    Environment = var.environment
  }
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "My-Enterprise-VPC-igw"
    Environment = var.environment
  }
}


# ============================================================
# NAT GATEWAY
# ============================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "My-Enterprise-NAT-EIP"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name        = "My-Enterprise-NAT"
    Environment = var.environment
  }
}


# ============================================================
# ROUTE TABLES
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "Public-Route-Table"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "Private-Route-Table"
    Environment = var.environment
  }
}


# ============================================================
# PUBLIC ROUTE
# ============================================================

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


# ============================================================
# PRIVATE ROUTE
# ============================================================

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# ============================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}


# ============================================================
# SECURITY GROUP - APPLICATION LOAD BALANCER
# ============================================================

resource "aws_security_group" "alb" {
  name        = "ALB-SG"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ALB-SG"
    Environment = var.environment
  }
}


# ============================================================
# SECURITY GROUP - WEB TIER
# ============================================================

resource "aws_security_group" "web" {
  name        = "Web-Tier-SG"
  description = "Security group for WordPress EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP only from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Web-Tier-SG"
    Environment = var.environment
  }
}


# ============================================================
# SECURITY GROUP - DATABASE
# ============================================================

resource "aws_security_group" "db" {
  name        = "DB-SG"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL only from web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "DB-SG"
    Environment = var.environment
  }
}


# ============================================================
# DB SUBNET GROUP
# ============================================================

resource "aws_db_subnet_group" "wordpress" {
  name = "wordpress-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name        = "WordPress-DB-Subnet-Group"
    Environment = var.environment
  }
}


# ============================================================
# RDS MYSQL
# ============================================================

resource "aws_db_instance" "wordpress" {
  identifier = "wordpress-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 3306

  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  backup_retention_period = 7

  tags = {
    Name        = "wordpress-db"
    Environment = var.environment
  }
}


# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "wordpress" {
  name               = "My-Enterprise-ALB"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name        = "My-Enterprise-ALB"
    Environment = var.environment
  }
}


# ============================================================
# TARGET GROUP
# ============================================================

resource "aws_lb_target_group" "wordpress" {
  name     = "My-Enterprise-TG"
  port     = 80
  protocol = "HTTP"

  target_type = "instance"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled  = true
    protocol = "HTTP"
    port     = "80"
    path     = "/"
  }

  tags = {
    Name        = "My-Enterprise-TG"
    Environment = var.environment
  }
}


# ============================================================
# ALB LISTENER
# ============================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}


# ============================================================
# IAM ROLE FOR EC2 / SSM
# ============================================================

resource "aws_iam_role" "ec2_ssm" {
  name = "wordpress-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "wordpress-ec2-ssm-role"
    Environment = var.environment
  }
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "ec2" {
  name = "wordpress-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}


# ============================================================
# LAUNCH TEMPLATE
# ============================================================

resource "aws_launch_template" "wordpress" {
  name = "wordpress-LT"

  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash

    dnf update -y

    dnf install -y httpd php php-mysqlnd php-fpm php-json php-gd php-mbstring php-xml php-curl wget tar

    systemctl enable httpd
    systemctl start httpd

    cd /tmp

    wget https://wordpress.org/latest.tar.gz

    tar -xzf latest.tar.gz

    rm -rf /var/www/html/*

    cp -r wordpress/* /var/www/html/

    chown -R apache:apache /var/www/html

    chmod -R 755 /var/www/html

    cat > /var/www/html/wp-config.php <<'WP_CONFIG'
    <?php

    define('DB_NAME', '${var.db_name}');
    define('DB_USER', '${var.db_username}');
    define('DB_PASSWORD', '${var.db_password}');
    define('DB_HOST', '${aws_db_instance.wordpress.address}');

    define('DB_CHARSET', 'utf8');
    define('DB_COLLATE', '');

    \$table_prefix = 'wp_';

    define('WP_DEBUG', false);

    if ( !defined('ABSPATH') ) {
        define('ABSPATH', __DIR__ . '/');
    }

    require_once ABSPATH . 'wp-settings.php';
    WP_CONFIG

    systemctl restart httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "WordPress-EC2"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "wordpress-LT"
    Environment = var.environment
  }
}


# ============================================================
# AUTO SCALING GROUP
# ============================================================

resource "aws_autoscaling_group" "wordpress" {
  name = "wordpress-ASG"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  target_group_arns = [
    aws_lb_target_group.wordpress.arn
  ]

  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "WordPress-EC2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]
}