data "template_file" "user_data" { 
  template = file("./preconf.yml")
  
  vars = {
    username = var.username
    public_key = file(var.public_key_path)
  }
}

resource "random_id" "id" {
    byte_length = 4
}
