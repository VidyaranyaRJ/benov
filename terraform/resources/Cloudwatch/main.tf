resource "aws_s3_object" "cloudwatch_config" {
  bucket  = "vj-test-benvolate"
  key     = "Cloudwatch/cloudwatch-agent-config.json"
  content = templatefile("${path.module}/cloudwatch-agent-config.json", {
    region = var.region
  })
  acl = "private"
}

resource "aws_ssm_document" "benevolate_cloudwatch_agent_document" {
  name          = "CloudWatchAgentConfig"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "CloudWatch Agent Installation and Configuration"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "configure-cloudwatch-agent"
        inputs = {
          runCommand = [
            "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
            "aws s3 cp s3://${var.cloudwatch_s3_bucket}/${var.cloudwatch_s3_path} /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start"
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_association" "cloudwatch_association" {
  for_each         = toset(var.ec2_instance_ids)
  name             = aws_ssm_document.benevolate_cloudwatch_agent_document.name
  association_name = "CloudWatchAgentInstall"

  targets {
    key    = "InstanceIds"
    values = [each.value]
  }
}