#!/bin/bash
##user##
#set timezone
sudo dpkg-reconfigure tzdata
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
printf "Please enter public-ssh-key: "
read -r AUTHORIZED_KEY
#ssh
mkdir .ssh
chmod 700 .ssh
touch .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
echo $AUTHORIZED_KEY >> .ssh/authorized_keys
#install packages
sudo apt-get install fail2ban curl git zip php5-fpm php5-mysql php5-mcrypt mysql-server nginx htop p7zip-full php5-curl monit
#nginx
sudo sed -i -e 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/worker_connections 768;/worker_connections 1024;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/keepalive_timeout 65;/keepalive_timeout 15;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/# gzip_comp_level 6;/gzip_comp_level 2;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/# gzip_proxied any;/gzip_proxied expired no-cache no-store private auth;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/# gzip_types text\/plain text\/css application\/json application\/javascript text\/xml application\/xml application\/xml+rss text\/javascript;/gzip_types text\/plain application\/x-javascript text\/xml text\/css application\/xml;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/access_log \/var\/log\/nginx\/access.log;/access_log off;/g' /etc/nginx/nginx.conf
sudo sed -i -e 's/# multi_accept on;/multi_accept on;/g' /etc/nginx/nginx.conf
sudo sed -i '/server_tokens off;/a \
\tclient_body_buffer_size 10k; \
\tclient_header_buffer_size 1k; \
\tlarge_client_header_buffers 2 1k;\
\tsend_timeout 10;\
\tclient_body_timeout 10;\
\treset_timedout_connection on;\
\topen_file_cache max=1000 inactive=20s;\
\topen_file_cache_valid 30s;\
\topen_file_cache_min_uses 2;\
\topen_file_cache_errors on;\
\tclient_max_body_size 8m;' /etc/nginx/nginx.conf
sudo sed -i '/gzip_comp_level 2;/a \
\tgzip_min_length  1000;' /etc/nginx/nginx.conf
#mysql
sudo mysql_secure_installation
sudo sed -i '/# ssl-key=\/etc\/mysql\/server-key.pem/a \
innodb_log_file_size = 64M\
innodb_buffer_pool_size = 512M\
innodb_log_buffer_size = 4M\
slow_query_log=1\
\t' /etc/mysql/my.cnf
sudo sed -i -e 's/query_cache_size        = 16M/query_cache_size = 128M/g' /etc/mysql/my.cnf
sudo mysql -uroot -p -e"SET GLOBAL innodb_fast_shutdown = 0"
sudo service mysql stop
sudo bash -c "rm /var/lib/mysql/ib_logfile[01]"
sudo service mysql start
#php
sudo sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
sudo sed -i -e 's/ignore_repeated_errors = Off/ignore_repeated_errors = On/g' /etc/php5/fpm/php.ini
sudo sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 32M/g' /etc/php5/fpm/php.ini
sudo service php5-fpm restart
#fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo service fail2ban restart
#monit todo add monit configuration
# Empty all rules
sudo iptables -t filter -F
sudo iptables -t filter -X
# Authorize already established connexions
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t filter -A INPUT -i lo -j ACCEPT
sudo iptables -t filter -A OUTPUT -o lo -j ACCEPT
# ICMP (Ping)
sudo iptables -t filter -A INPUT -p icmp -j ACCEPT
sudo iptables -t filter -A OUTPUT -p icmp -j ACCEPT
# SSH
sudo iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --dport 22 -j ACCEPT
# DNS
sudo iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT
# HTTP
sudo iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
#HTTPS
sudo iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
# Git
sudo iptables -t filter -A OUTPUT -p tcp --dport 9418 -j ACCEPT
#sudo iptables -t filter -A INPUT -p tcp --dport 9418 -j ACCEPT
# Mail SMTP
sudo iptables -t filter -A OUTPUT -p tcp --dport 25 -j ACCEPT
# FTP
sudo iptables -t filter -A OUTPUT -p tcp --dport 21 -j ACCEPT
# Mail POP3
sudo iptables -t filter -A OUTPUT -p tcp --dport 110 -j ACCEPT
# Mail IMAP
sudo iptables -t filter -A OUTPUT -p tcp --dport 143 -j ACCEPT
# NTP (server time)
sudo iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT
#ddos attack blocker
sudo iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m limit --limit 50/minute --limit-burst 200 -j ACCEPT
# Bloc everything by default
sudo iptables -t filter -P INPUT DROP
sudo iptables -t filter -P FORWARD DROP
sudo iptables -t filter -P OUTPUT DROP
#save rules for reboot
sudo apt-get install iptables-persistent
#backup
sudo apt-get install automysqlbackup
sudo sed -i -e 's/BACKUPDIR="\/var\/lib\/automysqlbackup"/BACKUPDIR="\/var\/backups\/automysqlbackup"/g' /etc/default/automysqlbackup

#ssl
#///////////////////
##install-phalcon
#apt-get install git-core gcc autoconf make
#sudo apt-get install php5-dev
#git clone git://github.com/phalcon/cphalcon.git
#cd cphalcon/ext
#sudo ./install
#echo "extension=phalcon.so" >> /etc/php5/fpm/conf.d/30-phalcon.ini
#sudo service php5-fpm restart
#sudo bash -c "rm cphalcon -R"
#///////////////////

#mysql ssh tunnel config
#cache installation
#cache configuration
#email alert config
#locale configuration
