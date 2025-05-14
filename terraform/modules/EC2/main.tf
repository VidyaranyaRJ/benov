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
  key_name                    = "vj-test-1"
  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -e

    echo "[1/10] Ensuring base packages are installed"
    for pkg in nfs-common git curl; do
      if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Installing missing package: $pkg"
        apt-get update -y
        apt-get install -y "$pkg"
      else
        echo "Package $pkg is already installed"
      fi
    done

    echo "[2/10] Checking Node.js installation"
    if ! command -v node >/dev/null || ! node -v | grep -q '^v18'; then
      echo "Installing Node.js 18"
      curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
      apt-get install -y nodejs
    else
      echo "Node.js is already installed: $(node -v)"
    fi

    echo "[3/10] Creating EFS mount points"
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs

    echo "[4/10] Mounting EFS volumes"
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    echo "[5/10] Persisting EFS mounts"
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    echo "[6/10] Cleaning and cloning GitHub repository"
    if [ -d "/mnt/efs/code/.git" ]; then
      echo "Existing Git repo found in EFS, deleting contents..."
      rm -rf /mnt/efs/code/*
    fi
    git clone --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code

    echo "[7/10] Changing ownership to ubuntu"
    chown -R ubuntu:ubuntu /mnt/efs/code

    echo "[8/10] Installing app dependencies as ubuntu"
    sudo -u ubuntu bash -c "
      cd /mnt/efs/code/nodejs &&
      npm install
    "

    echo "[9/10] Installing PM2 globally if not present"
    if ! sudo -u ubuntu command -v pm2 >/dev/null 2>&1; then
      sudo -u ubuntu npm install -g pm2
    fi
    
    echo "[10/10] Starting the app using pm2"
    sudo -u ubuntu bash -c "
      pm2 start /mnt/efs/code/nodejs/index.js --name nodejs-app &&
      pm2 save &&
      pm2 startup systemd -u ubuntu --hp /home/ubuntu
    "

    echo ""
    echo "========== Installation Summary =========="
    echo "- Node.js version: $(node -v)"
    echo "- npm version: $(npm -v)"
    echo "- pm2 version: $(sudo -u ubuntu pm2 -v || echo 'Not installed')"
    echo "- App running status (pm2 list):"
    sudo -u ubuntu pm2 list || echo "PM2 failed to list processes"
    echo "=========================================="
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
}

