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

    echo "[1] Update system and install base packages"
    yum update -y || { echo "System update failed"; exit 1; }
    yum install -y git amazon-efs-utils gcc-c++ make || { echo "Base package install failed"; exit 1; }

    echo "[2] Download and install Node.js 18"
    cd /usr/local
    curl -O https://nodejs.org/dist/v18.20.2/node-v18.20.2-linux-x64.tar.xz || { echo "Failed to download Node.js"; exit 1; }
    tar -xf node-v18.20.2-linux-x64.tar.xz || { echo "Failed to extract Node.js"; exit 1; }
    cp -r node-v18.20.2-linux-x64/{bin,include,lib,share} /usr/local/ || { echo "Failed to copy Node.js binaries"; exit 1; }
    rm -rf node-v18.20.2-linux-x64*
    ln -sf /usr/local/bin/node /usr/bin/node
    ln -sf /usr/local/bin/npm /usr/bin/npm

    echo "[3] Verify Node.js and npm installation"
    node -v || { echo "Node.js not found"; exit 1; }
    npm -v || { echo "npm not found"; exit 1; }

    echo "[4] Create and mount EFS directories"
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code || { echo "EFS code mount failed"; exit 1; }
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data || { echo "EFS data mount failed"; exit 1; }
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs || { echo "EFS logs mount failed"; exit 1; }

    echo "[5] Persist EFS mounts in /etc/fstab"
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    echo "[6] Clean and clone application repo into /mnt/efs/code"
    rm -rf /mnt/efs/code/* /mnt/efs/code/.* 2>/dev/null || true
    git clone --single-branch --branch nodejs https://github.com/VidyaranyaRJ/application.git /mnt/efs/code || { echo "Git clone failed"; exit 1; }

    echo "[7] Fix ownership for ec2-user"
    chown -R ec2-user:ec2-user /mnt/efs/code /mnt/efs/data /mnt/efs/logs

    echo "[8] Install Node.js dependencies"
    cd /mnt/efs/code/nodejs
    sudo -u ec2-user npm install > /mnt/efs/logs/npm-install.log 2>&1 || {
      echo "npm install failed. Check /mnt/efs/logs/npm-install.log"
      exit 1
    }

    echo "[9] Run the Node.js app in background"
    sudo -u ec2-user nohup node index.js > /mnt/efs/logs/app.log 2>&1 &
    sleep 3
    if ! pgrep -f "node index.js" > /dev/null; then
      echo "Node.js app failed to start"
      cat /mnt/efs/logs/app.log
      exit 1
    fi

    echo "[10] Health check"
    if ! curl --silent --fail http://localhost:3000; then
      echo "App failed to respond on port 3000"
      exit 2
    fi
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
} 