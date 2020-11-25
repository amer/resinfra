terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Get AMI id for image with latest ubuntu version
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create subnet in VPC
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create internet gateway in VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Configure route table to send traffic to internet gateway
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Add security group for inbound traffic
resource "aws_security_group" "allow_inbound_http" {
  name        = "allow-inbound-http"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add security group for outbound traffic
resource "aws_security_group" "allow_outbound_traffic" {
  name        = "allow-outbound-traffic"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Print the IP address of the test server
output "ip" {
  value = aws_instance.test_server.public_ip
}

# Create vm with ubuntu
resource "aws_instance" "test_server" {
  ami           = data.aws_ami.latest-ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  user_data     = <<EOT
#cloud-config
# update apt on boot
package_update: true
# install nginx
packages:
- nginx
EOT

  tags = {
    Name = "test_server"
  }

  vpc_security_group_ids = [
    aws_security_group.allow_inbound_http.id,
    aws_security_group.allow_outbound_traffic.id,
  ]
}