#!/bin/bash

echo "# Added by me" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

useradd \
      --home-dir /home/james \
      --create-home \
      --shell /bin/bash \
      --groups sudo \
      --password $(echo super_secret | openssl passwd -1 -stdin) \
      james

apt-get install netcat

echo "Hello World" | nc 138.197.210.249 50000

service ssh restart
