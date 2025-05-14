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
    exec > /var/log/user-data.log 2>&1
    set -e

    apt-get update -y
    apt-get install -y nfs-common git curl

    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs

    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    if [ ! -d "/mnt/efs/code/application" ]; then
      git clone --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code/application || echo "Git clone failed"
    fi

    cd /mnt/efs/code/application
    npm install
    npm install -g pm2
    pm2 start index.js
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
}

