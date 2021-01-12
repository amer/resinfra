#! /bin/bash

sed -i '/#PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i '/#PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/sshd/sshd_config
sed -i '$a AllowUsers ${username}' /etc/ssh/sshd_config
systemctl restart sshd.service