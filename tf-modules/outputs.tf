output "aws_public_ips" {
  value = module.aws-ec2
}

output "hcloud_public_ips" {
  value = module.hcloud-server
}
