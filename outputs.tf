output "instance_id" {
  description = "EC2 instance ID of the pgweb host."
  value       = aws_instance.pgweb.id
}

output "public_ip" {
  description = "Public IP address of the pgweb host."
  value       = aws_instance.pgweb.public_ip
}

output "security_group_id" {
  description = "Security group ID attached to the pgweb host."
  value       = aws_security_group.pgweb.id
}

output "iam_role_arn" {
  description = "IAM role ARN used by the pgweb instance."
  value       = aws_iam_role.this.arn
}
