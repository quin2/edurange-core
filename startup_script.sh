#!/bin/bash

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service ssh restart

useradd \
      --home-dir /home/james \
      --create-home \
      --shell /bin/bash \
      --groups sudo \
      --password $(echo s00p3rs3cr37 | openssl passwd -1 -stdin) \
      james

echo "stuff" > /home/james/message
chown /home/james/message james

curl -X PUT -d "Hello, World." "{{status_object_url}}"

