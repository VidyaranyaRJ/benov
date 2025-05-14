data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ecs-ec2-1"
}

resource "aws_instance" "ecs_instance" {
  ami                         = "ami-0c3b809fcf2445b6a"
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = data.aws_iam_instance_profile.ecs_profile.name
  associate_public_ip_address = true
  key_name                    = "vj-test"
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nfs-common git nodejs npm

    # Mount paths
    mkdir -p /mnt/efs/code
    mkdir -p /mnt/efs/data
    mkdir -p /mnt/efs/logs

    # Mount each EFS
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    # Persist mounts in fstab
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    # Git clone only in /mnt/efs/code
    if [ ! -d "/mnt/efs/code/application" ]; then
      git clone --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code/application
    fi

    cd /mnt/efs/code/your-repo
    npm install -y
    npm install -g pm2
    pm2 start index.js
    EOF

  tags = {
    Name = var.ec2_tag_name
  }
}

