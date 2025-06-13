resource "aws_s3_object" "cloudwatch_config" {
  bucket = "vj-test-benvolate"                          # S3 Bucket name
  key    = "Cloudwatch/cloudwatch-agent-config.json"     # Path inside the S3 bucket
  source = "C:/Users/vrjav/Downloads/Desktop folders/Benevolate/terraform/resources/Cloudwatch/cloudwatch-agent-config.json"  # Local file path
  acl    = "private"                                    # ACL for the file (private means only the owner can access)
}

resource "aws_ssm_document" "benevolate_cloudwatch_agent_document" {
  name          = "CloudWatchAgentConfig"
  document_type = "Command"
  content = <<JSON
{
  "schemaVersion": "2.2",
  "description": "CloudWatch Agent Installation and Configuration",
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "configure-cloudwatch-agent",
      "inputs": {
        "runCommand": [
          "mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
          "aws s3 cp s3://${var.cloudwatch_s3_bucket}/${var.cloudwatch_s3_path} /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
          "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop",
          "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start"
        ]
      }
    }
  ]
}
JSON
}


resource "aws_ssm_association" "cloudwatch_association" {
  for_each         = toset(var.ec2_instance_ids)  # Loop through EC2 instance IDs
  name             = aws_ssm_document.benevolate_cloudwatch_agent_document.name
  association_name = "CloudWatchAgentInstall"

  targets {
    key    = "InstanceIds"   # Specify that we are targeting by Instance IDs
    values = [each.value]    # The EC2 instance IDs are passed dynamically
  }
}