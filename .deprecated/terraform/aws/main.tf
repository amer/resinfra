provider "aws" {
  region = var.region
}

resource "aws_key_pair" "aws_key" {
  key_name   = "aws"
  public_key = file(var.public_key_path)
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
resource "aws_security_group" "allow_inbound_traffic" {
  name        = "allow-inbound-traffic"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.aws_key.key_name
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.allow_inbound_traffic.id,
    aws_security_group.allow_outbound_traffic.id,
  ]

  provisioner "remote-exec" {
    inline = ["echo 'SSH is now ready!'"]

    connection {
      type        = "ssh"
      user        = var.remote_user
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' -u '${var.remote_user}' --private-key '${var.private_key_path}' playbook.yaml"
  }
}

output "public_ip" {
  value = aws_instance.web.*.public_ip[0]
}
