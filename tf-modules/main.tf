provider "aws" {
   region = var.aws_region
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
}

resource "random_id" "id" {
    byte_length = 4
}
 
data "template_file" "user_data" { 
  template = file("./preconf.yml")
  
  vars = {
    username = var.username
    public_key = file(var.public_key_path)
  }
}

module "aws-ec2" {
  source = "./modules/terraform-aws-ec2"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  random_id = random_id.id.hex
  prefix = "res-tim"
  public_key_path = var.public_key_path
  instances = var.instances
  user_data = data.template_file.user_data.rendered
}

