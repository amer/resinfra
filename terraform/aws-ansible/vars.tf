variable "region" {
  type = string
  description = "AWS region for resources to be created"
  default = "eu-central-1"
} 

variable "ami" {
  type = string
  description = "AMI for the instance to be created"
  default = "ami-0502e817a62226e03" 
  # ubuntu 20.04
}

variable "instance_type" {
  type = string
  description = "Instance type for the instance to be created"
  default = "t2.micro"
  # 1 vCPU 1gb ram
}

variable "public_key_path" {
  description = "path to public key that will be uploaded to aws"
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "path to private key, used to access instance"
  default = "~/.ssh/id_rsa"
}

variable "remote_user" {
  description = "user for ssh connection"
  default = "ubuntu"
}
