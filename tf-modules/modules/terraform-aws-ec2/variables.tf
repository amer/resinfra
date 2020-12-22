variable aws_access_key {}
variable aws_secret_key {}
variable random_id{}
variable prefix{}
variable public_key_path{}
variable instances{}
variable user_data{}

variable "aws_region" {
  type        = string
  description = "AWS region for resources to be created"
  default     = "eu-central-1"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the instance to be created"
  default     = "t2.micro" # 1 vCPU 1gb ram
}
