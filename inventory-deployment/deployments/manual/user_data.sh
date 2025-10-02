#!/bin/bash
apt update
apt install -y nodejs npm git
cd /home/ubuntu
git clone https://github.com/tuusuario/inventory-deployment.git
cd inventory-deployment/application
npm install
node index.js
