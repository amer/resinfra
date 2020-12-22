output "aws_public_ips" {
  value = aws_instance.web.*.public_ip
}
