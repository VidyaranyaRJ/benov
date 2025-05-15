data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
}

resource "aws_instance" "ecs_instance" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = true
  key_name                    = "vj-test"
  user_data = <<-EOF
  #!/bin/bash
  exec > /var/log/user-data.log 2>&1
  set -euxo pipefail

  echo "[1] Install essential packages (no curl)"
  yum install -y git amazon-efs-utils gcc-c++ make || echo "yum failed"

  echo "[2] Create EFS mount points"
  mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs

  echo "[3] Mount EFS volumes"
  mount -t nfs4 -o nfsvers=4.1 fs-0404721d2b7dfd02f.efs.us-east-2.amazonaws.com:/ /mnt/efs/code || echo "EFS code mount failed"
  mount -t nfs4 -o nfsvers=4.1 fs-0e2948fe805e62930.efs.us-east-2.amazonaws.com:/ /mnt/efs/data || echo "EFS data mount failed"
  mount -t nfs4 -o nfsvers=4.1 fs-0de94b91a36f18463.efs.us-east-2.amazonaws.com:/ /mnt/efs/logs || echo "EFS logs mount failed"
EOF



  tags = {
    Name = var.ec2_tag_name
  }
}

