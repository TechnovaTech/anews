#!/bin/bash

echo "🔵 Checking MongoDB status..."
sudo systemctl status mongod

echo ""
echo "🔵 If MongoDB is not running, run these commands:"
echo "sudo systemctl start mongod"
echo "sudo systemctl enable mongod"

echo ""
echo "🔵 If MongoDB is not installed, run:"
echo "# Ubuntu 20.04/22.04"
echo "wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -"
echo "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list"
echo "sudo apt update"
echo "sudo apt install -y mongodb-org"
echo "sudo systemctl start mongod"
echo "sudo systemctl enable mongod"

echo ""
echo "🔵 Test MongoDB connection:"
echo "mongosh --eval 'db.runCommand({ connectionStatus: 1 })'"

echo ""
echo "🔵 Check if port 27017 is listening:"
echo "sudo netstat -tulpn | grep 27017"

echo ""
echo "🔵 After MongoDB is running, restart your Next.js app:"
echo "pm2 restart all"
