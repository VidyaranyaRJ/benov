data "aws_iam_instance_profile" "ecs_profile" {
  name = "vj-ec2"
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
  set -euxo pipefail

  echo "[1] Update packages and install dependencies"
  apt-get update -y
  apt-get install -y curl git nfs-common

  echo "[2] Install Node.js 18"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs

  echo "[3] Install PM2 globally using correct prefix"
  npm install -g pm2

  echo "[4] Link PM2 to /usr/bin (fixes PATH issue)"
  ln -sf /usr/lib/node_modules/pm2/bin/pm2 /usr/bin/pm2

  echo "[5] Mount EFS volumes"
  mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
  mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
  mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
  mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

  echo "[6] Persist mounts"
  echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
  echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
  echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

  echo "[7] Clone Node.js repo"
  rm -rf /mnt/efs/code/*
  git clone --single-branch --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code
  chown -R ubuntu:ubuntu /mnt/efs/code

  echo "[8] Install app dependencies"
  cd /mnt/efs/code/nodejs
  sudo -u ubuntu npm install

  echo "[9] Start Node app with PM2"
  sudo -i -u ubuntu pm2 start index.js --name nodejs-app
  sudo -i -u ubuntu pm2 save
  sudo -i -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu

  echo "[10] Health check"
  sleep 5
  curl http://localhost:3000 || echo "App failed to respond"
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
}

