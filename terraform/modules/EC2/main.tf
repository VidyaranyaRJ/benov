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
    set -x  # Echo commands for debugging

    echo "[0] BEGIN EC2 BOOTSTRAP"

    echo "[1] Install base packages"
    apt-get update -y
    apt-get install -y nfs-common git curl > /tmp/apt-install.log 2>&1 || echo "[ERROR] apt-get install failed"

    echo "[2] Install Node.js 18 and npm"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - >> /tmp/node-setup.log 2>&1 || echo "[ERROR] NodeSource setup failed"
    apt-get install -y nodejs >> /tmp/node-install.log 2>&1 || echo "[ERROR] Node.js install failed"
    node -v || echo "[ERROR] node -v failed"
    npm -v || echo "[ERROR] npm -v failed"

    echo "[3] Mount EFS volumes"
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code || echo "[ERROR] EFS1 mount failed"
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data || echo "[ERROR] EFS2 mount failed"
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs || echo "[ERROR] EFS3 mount failed"

    echo "[4] Persist mounts"
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    echo "[5] Clone repo fresh"
    find /mnt/efs/code -mindepth 1 -delete || echo "[WARN] Cleanup failed"
    git clone --single-branch --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code || echo "[ERROR] Git clone failed"

    echo "[6] Set ownership"
    chown -R ubuntu:ubuntu /mnt/efs/code || echo "[ERROR] chown failed"

    echo "[7] Install project dependencies"
    cd /mnt/efs/code/nodejs || exit 1

    echo "[7.1] Running npm install"
    sudo -u ubuntu npm install >> /tmp/npm-install.log 2>&1 || echo "[ERROR] npm install failed"
    sudo -u ubuntu npm list --depth=0 || echo "[ERROR] npm list failed"

    echo "[7.2] Installing local pm2"
    sudo -u ubuntu npm install pm2 --save >> /tmp/pm2-install.log 2>&1 || echo "[ERROR] npm install pm2 --save failed"

    if [ ! -f ./node_modules/.bin/pm2 ]; then
      echo "[7.3] Local PM2 not found, trying global install"
      npm install -g pm2 >> /tmp/pm2-global-install.log 2>&1 || echo "[ERROR] Global pm2 install failed"
      ln -sf $(which pm2) /usr/bin/pm2
      which pm2 || echo "[ERROR] pm2 not found even after global install"
      pm2 -v || echo "[ERROR] pm2 -v failed"

      echo "[8] Start app with global PM2"
      pm2 start index.js --name nodejs-app || echo "[ERROR] pm2 start failed"
      pm2 save
      pm2 startup systemd -u ubuntu --hp /home/ubuntu || echo "[ERROR] pm2 startup failed"
    else
      echo "[8] Start app with local PM2"
      sudo -u ubuntu ./node_modules/.bin/pm2 start index.js --name nodejs-app || echo "[ERROR] local pm2 start failed"
      sudo -u ubuntu ./node_modules/.bin/pm2 save

      echo "[9] Configure local PM2 to run on boot"
      export PM2_HOME="/home/ubuntu/.pm2"
      su - ubuntu -c "export PATH=/mnt/efs/code/nodejs/node_modules/.bin:\$PATH && ./node_modules/.bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu" || echo "[ERROR] pm2 startup (local) failed"
      su - ubuntu -c "export PATH=/mnt/efs/code/nodejs/node_modules/.bin:\$PATH && ./node_modules/.bin/pm2 save"
    fi

    echo "[10] Health check"
    sleep 5
    curl http://localhost:3000 || echo "[ERROR] App not responding on port 3000"

    echo "[11] DONE — check /var/log/user-data.log and /tmp/*.log for details"
    EOF

  tags = {
    Name = var.ec2_tag_name
  }
}

