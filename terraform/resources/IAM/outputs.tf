output "ssm_instance_role_name" {
  value = aws_iam_role.benevolate_ec2_ssm_role.name
}

output "ssm_instance_role_arn" {
  value = aws_iam_role.benevolate_ec2_ssm_role.arn
}