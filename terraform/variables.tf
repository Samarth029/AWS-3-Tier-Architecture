variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "showcase"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_1" {
  description = "First Availability Zone"
  type        = string
  default     = "ap-south-1a"
}

variable "az_2" {
  description = "Second Availability Zone"
  type        = string
  default     = "ap-south-1b"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}


# ============================================================
# EC2 / WORDPRESS
# ============================================================

variable "ami_id" {
  description = "AMI ID used for WordPress EC2 instances"
  type        = string
  default     = "ami-02a1e27f0f36dceff"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Existing AWS EC2 key pair name. Leave empty if using SSM only."
  type        = string
  default     = "mykeypair"
}


# ============================================================
# RDS MYSQL
# ============================================================

variable "db_name" {
  description = "WordPress database name"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "RDS database username"
  type        = string
  default     = "wordpressadmin"
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}