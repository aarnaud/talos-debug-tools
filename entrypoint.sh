#!/bin/sh

rm /etc/ssh/ssh_host_*
ssh-keygen -A
exec /usr/sbin/sshd -D -e