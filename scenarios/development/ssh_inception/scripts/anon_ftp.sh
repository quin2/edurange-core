#!/usr/bin/env bash

#apt-get update
#apt-get install vsftpd

service vsftpd stop
mkdir /var/ftp
chown -hR ftp:ftp /var/ftp
chmod 555 /var/ftp

echo -e "ip: 10.0.0.17
decryption_password: {{scenario.variables.fifth_stop_password_key}}" > /var/ftp/hint

chmod 444 /var/ftp/hint
echo -e "listen=YES
" > /etc/vsftpd.conf
echo -e "local_enable=YES
" >> /etc/vsftpd.conf
echo -e "anonymous_enable=YES
" >> /etc/vsftpd.conf
echo -e "write_enable=NO
" >> /etc/vsftpd.conf
echo -e "anon_root=/var/ftp
" >> /etc/vsftpd.conf
# also docker might not actually start the service here....
service vsftpd start

# double check that ssh is getting stopped, it might be in the init script and started
if [ -f /etc/init.d/ssh ]
then
service ssh stop
fi
if [ ! -f /etc/init.d/ssh ]
then
service sshd stop
fi
