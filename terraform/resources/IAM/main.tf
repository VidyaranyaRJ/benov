resource "aws_iam_role" "benevolate_ec2_ssm_role" {
  name               = var.iam_role_name
  assume_role_policy = jsonencode(var.assume_role_policy_json)
}

resource "aws_iam_role_policy_attachment" "managed_policy_attachments" {
  for_each   = toset(var.iam_managed_policy_arns)
  role       = aws_iam_role.benevolate_ec2_ssm_role.name
  policy_arn = each.key
}