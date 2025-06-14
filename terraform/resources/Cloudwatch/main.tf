resource "aws_s3_object" "cloudwatch_config" {
  bucket = "vj-test-benvolate"
  key    = "Cloudwatch/cloudwatch-agent-config.json"
  source = "${path.module}/cloudwatch-agent-config.json"
  acl    = "private"
  etag   = filemd5("${path.module}/cloudwatch-agent-config.json")
}


resource "random_id" "doc_suffix" {
  byte_length = 4
}

resource "aws_ssm_document" "benevolate_cloudwatch_agent_document" {
  name          = "CloudWatchAgentConfig-${random_id.doc_suffix.hex}"
  document_type = "Command"
  document_format = "JSON"
  
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "CloudWatch Agent Installation and Configuration"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "configure_cloudwatch_agent"
        inputs = {
          timeoutSeconds = "300"
          runCommand = [
            "#!/bin/bash",
            "set -e",
            "echo 'Starting CloudWatch Agent installation and configuration'",
            "",
            "# Download and install CloudWatch Agent if not already installed",
            "if [ ! -f /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then",
            "  echo 'Installing CloudWatch Agent'",
            "  wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",
            "  sudo rpm -U ./amazon-cloudwatch-agent.rpm",
            "  rm -f ./amazon-cloudwatch-agent.rpm",
            "fi",
            "",
            "# Create configuration directory",
            "sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
            "",
            "# Download configuration from S3",
            "echo 'Downloading CloudWatch Agent configuration from S3'",
            "aws s3 cp s3://vj-test-benvolate/Cloudwatch/cloudwatch-agent-config.json /tmp/amazon-cloudwatch-agent.json",
            "sudo mv /tmp/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
            "",
            "# Set proper permissions",
            "sudo chown cwagent:cwagent /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
            "sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
            "",
            "# Stop existing agent if running",
            "echo 'Stopping existing CloudWatch Agent if running'",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a stop || true",
            "",
            "# Start agent with new configuration",
            "echo 'Starting CloudWatch Agent with new configuration'",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
            "",
            "# Wait a moment for agent to start",
            "sleep 5",
            "",
            "# Verify agent is running",
            "echo 'Verifying CloudWatch Agent status'",
            "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status",
            "echo 'CloudWatch Agent installation and configuration completed successfully'"
          ]
        }
      }
    ]
  })
  
  depends_on = [aws_s3_object.cloudwatch_config]
}





resource "aws_ssm_association" "cloudwatch_association" {
  for_each         = toset(var.ec2_instance_ids)
  name             = aws_ssm_document.benevolate_cloudwatch_agent_document.name
  association_name = "CloudWatchAgentInstall-${each.value}"

  targets {
    key    = "InstanceIds"
    values = [each.value]
  }

  # Force re-run when config changes
  parameters = {
    "commands" = ["echo 'Config updated: ${aws_s3_object.cloudwatch_config.etag}'"]
  }
  
  # Run immediately
  schedule_expression = "rate(30 days)"
  
  depends_on = [
    aws_ssm_document.benevolate_cloudwatch_agent_document,
    aws_s3_object.cloudwatch_config
  ]
}