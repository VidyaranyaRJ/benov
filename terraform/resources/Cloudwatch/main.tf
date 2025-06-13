resource "aws_s3_object" "cloudwatch_config" {
  bucket = var.cloudwatch_s3_bucket
  key    = var.cloudwatch_s3_path
  source = "./cloudwatch/cloudwatch-agent-config.json"  
  acl    = "private"
}


resource "aws_ssm_document" "benevolate_cloudwatch_agent_document" {
  name          = "CloudWatchAgentConfig"
  document_type = "Command"
  content = templatefile("cloudwatch-agent-config.json", {
    region               = var.region
    cloudwatch_s3_bucket = var.cloudwatch_s3_bucket
    cloudwatch_s3_path   = var.cloudwatch_s3_path
  })
}


resource "aws_ssm_association" "cloudwatch_association" {
  for_each         = toset(var.ec2_instance_ids)  # Loop through EC2 instance IDs
  name             = aws_ssm_document.cloudwatch_agent_document.name
  association_name = "CloudWatchAgentInstall"

  targets {
    key    = "InstanceIds"   # Specify that we are targeting by Instance IDs
    values = [each.value]    # The EC2 instance IDs are passed dynamically
  }
}