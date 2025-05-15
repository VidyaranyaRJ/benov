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

    # Update system and install essential packages
    yum update -y
    yum install -y amazon-efs-utils unzip awscli \
        gcc-c++ make jq tar gzip \
        openssl-devel zlib-devel bzip2 bzip2-devel xz-devel libffi-devel

    # Install Node.js 18.20.2 and PM2
    cd /usr/local
    curl -O https://nodejs.org/dist/v18.20.2/node-v18.20.2-linux-x64.tar.xz
    tar -xf node-v18.20.2-linux-x64.tar.xz
    cp -r node-v18.20.2-linux-x64/{bin,include,lib,share} /usr/local/
    rm -rf node-v18.20.2-linux-x64*
    ln -sf /usr/local/bin/node /usr/bin/node
    ln -sf /usr/local/bin/npm /usr/bin/npm
    npm install -g pm2
    ln -sf /usr/local/bin/pm2 /usr/bin/pm2

    # Create mount points and mount EFS
    mkdir -p /mnt/efs/code /mnt/efs/data /mnt/efs/logs
    mount -t nfs4 -o nfsvers=4.1 ${var.efs1_dns_name}:/ /mnt/efs/code
    mount -t nfs4 -o nfsvers=4.1 ${var.efs2_dns_name}:/ /mnt/efs/data
    mount -t nfs4 -o nfsvers=4.1 ${var.efs3_dns_name}:/ /mnt/efs/logs

    # Persist mounts in fstab
    echo "${var.efs1_dns_name}:/ /mnt/efs/code nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs2_dns_name}:/ /mnt/efs/data nfs4 defaults,_netdev 0 0" >> /etc/fstab
    echo "${var.efs3_dns_name}:/ /mnt/efs/logs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    # Fix permissions for ec2-user
    chown -R ec2-user:ec2-user /mnt/efs/code /mnt/efs/data /mnt/efs/logs

    # Deploy app from S3 into EFS and start via PM2
    if aws s3 ls s3://vj-application/app.zip; then
      aws s3 cp s3://vj-application/app.zip /tmp/app.zip
      rm -rf /mnt/efs/code/nodejs && mkdir -p /mnt/efs/code/nodejs
      unzip /tmp/app.zip -d /mnt/efs/code/nodejs
      chown -R ec2-user:ec2-user /mnt/efs/code

      cd /mnt/efs/code/nodejs
      sudo -u ec2-user npm install
      sudo -u ec2-user pm2 start index.js --name node-app
      sudo -u ec2-user pm2 save
      sudo -u ec2-user pm2 startup systemd
    fi
  EOF


  tags = {
    Name = var.ec2_tag_name
  }
} 