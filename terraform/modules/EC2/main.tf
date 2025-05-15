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

    echo "[1] Update and install dependencies"
    yum update -y
    yum install -y curl git amazon-efs-utils

    echo "[2] Install Node.js 18"
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs

    echo "[3] Install PM2 globally"
    npm install -g pm2

    echo "[4] Mount EFS volumes"
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    echo "[5] Persist mounts"
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    echo "[6] Clone repo and set permissions"
    rm -rf /mnt/efs/code/*
    git clone --single-branch --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code
    chown -R ec2-user:ec2-user /mnt/efs/code

    echo "[7] Install app dependencies"
    cd /mnt/efs/code/nodejs
    sudo -u ec2-user npm install

    echo "[8] Start Node app with PM2"
    sudo -i -u ec2-user pm2 start index.js --name nodejs-app
    sudo -i -u ec2-user pm2 save
    sudo -i -u ec2-user pm2 startup systemd -u ec2-user --hp /home/ec2-user

    echo "[9] Health check"
    sleep 5
    curl http://localhost:3000 || echo "App failed to respond"
  EOF



  tags = {
    Name = var.ec2_tag_name
  }
}

