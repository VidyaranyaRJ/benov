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
    set -e

    echo "[1] Install base packages"
    apt-get update -y
    apt-get install -y nfs-common git curl

    echo "[2] Install Node.js 18 and npm"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    echo "[3] Mount EFS volumes"
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    echo "[4] Persist mounts"
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    echo "[5] Clone repo fresh"
    find /mnt/efs/code -mindepth 1 -delete
    git clone --single-branch --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code

    echo "[6] Set correct ownership"
    chown -R ubuntu:ubuntu /mnt/efs/code

    echo "[7] Install project dependencies + local PM2"
    cd /mnt/efs/code/nodejs
    sudo -u ubuntu npm install
    sudo -u ubuntu npm install pm2 --save

    echo "[8] Start app with local PM2"
    sudo -u ubuntu ./node_modules/.bin/pm2 start index.js --name nodejs-app
    sudo -u ubuntu ./node_modules/.bin/pm2 save

    echo "[9] Configure PM2 to run on boot"
    export PM2_HOME="/home/ubuntu/.pm2"
    su - ubuntu -c "export PATH=/mnt/efs/code/nodejs/node_modules/.bin:\$PATH && ./node_modules/.bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu"
    su - ubuntu -c "export PATH=/mnt/efs/code/nodejs/node_modules/.bin:\$PATH && ./node_modules/.bin/pm2 save"

    echo "[10] Health check"
    sleep 5
    curl http://localhost:3000 || echo "App failed to respond"
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
}

