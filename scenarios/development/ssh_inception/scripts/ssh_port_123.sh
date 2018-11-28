#!/usr/bin/env bash

sed -i s/"Port 22"/"Port 123"/g /etc/ssh/sshd_config
sed -i s/"#Port 123"/"Port 123"/g /etc/ssh/sshd_config
if [ -f /etc/init.d/ssh ]
then
service ssh reload
fi
if [ ! -f /etc/init.d/ssh ]
then
service sshd reload
fi
