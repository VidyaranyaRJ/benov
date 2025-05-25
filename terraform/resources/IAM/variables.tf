variable "iam_role_name" {
  type = string
}

variable "assume_role_policy_json" {
  type        = any
  description = "Full IAM trust policy JSON (assume_role_policy)"
}


variable "iam_managed_policy_arns" {
  type        = list(string)
  description = "List of managed IAM policy ARNs to attach to the role"
  default     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}