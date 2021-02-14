#----------------------------------------------------------
# EPAM aws homework outputs.tf file
#----------------------------------------------------------

output "aws_lb_dns_name" {
  value       = aws_lb.alb_wp.dns_name
  description = "DNS name of the load balancer"
}

output "aws_instance_wp1_public_ip" {
  value       = aws_instance.wp1.public_ip
  description = "Public IP address of the first wordpress instance"
}

output "aws_instance_wp2_public_ip" {
  value       = aws_instance.wp2.public_ip
  description = "Public IP address of the second wordpress instance"
}
