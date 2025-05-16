#!/bin/bash
set -e

mkdir -p /mnt/efs/code /mnt/efs/logs

aws s3 cp s3://vj-test-benvolate/nodejs/nodejs-app.zip /mnt/efs/code/nodejs-app.zip

rm -rf /mnt/efs/code/nodejs-app-temp
mkdir -p /mnt/efs/code/nodejs-app-temp

unzip -o /mnt/efs/code/nodejs-app.zip -d /mnt/efs/code/nodejs-app-temp

cd /mnt/efs/code/nodejs-app-temp
npm install

if ! command -v pm2 > /dev/null; then
  npm install -g pm2
fi

ln -sfn /mnt/efs/code/nodejs-app-temp /mnt/efs/code/nodejs-app

cd /mnt/efs/code/nodejs-app
pm2 describe nodejs-app > /dev/null && pm2 reload nodejs-app --update-env || pm2 start index.js --name nodejs-app
pm2 save
