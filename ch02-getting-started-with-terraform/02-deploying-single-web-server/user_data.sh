#!/bin/bash
dd if=/dev/zero of=/swapfile1 bs=1024 count=2097152
chown root:root /swapfile1
chmod 600 /swapfile1
mkswap /swapfile1
swapon /swapfile1
dnf config-manager --enable ol8_developer_EPEL
dnf -y install busybox
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
systemctl stop firewalld
firewall-offline-cmd --zone=public --add-port=8080/tcp
systemctl start firewalld
