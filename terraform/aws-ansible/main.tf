provider "aws" {
  region = var.region
} 

resource "aws_key_pair" "aws_key" {
  key_name = "aws"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "ssh_http" {
  name = "ssh_http"
  description = "Allows both ssh and http trafic"
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
   
resource "aws_instance" "web" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.aws_key.key_name
  security_groups = [aws_security_group.ssh_http.name]

  provisioner "remote-exec" { 
    inline = ["echo 'SSH is now ready!'"]
    
    connection {
      type = "ssh"
      user = var.remote_user
      private_key = file(var.private_key_path)
      host = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' -u '${var.remote_user}' --private-key '${var.private_key_path}' playbook.yaml"
  }
}

output "public_ip" {
  value = aws_instance.web.*.public_ip[0]
}
