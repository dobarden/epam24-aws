output "ALB-dns-name" {
  value = aws_lb.my-alb.dns_name
}

output "WebServer1-public-IP" {
  value = aws_instance.webserver1.public_ip
}

output "WebServer1-private-IP" {
  value = aws_instance.webserver1.private_ip
}

output "WebServer2-public-IP" {
  value = aws_instance.webserver2.public_ip
}

output "WebServer2-private-IP" {
  value = aws_instance.webserver2.private_ip
}