#!/bin/bash

log=testlog.log

#Install httpd and configure for auto start 
sudo dnf -y update
sudo dnf install -y httpd httpd-tools
sudo systemctl enable httpd
sudo systemctl start httpd


#Configuring firewall for only port 80/443
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --reload

#Configure apache to set default error log location
sudo sed -i 's/ErrorLog \"logs\/error\_log\"/ErrorLog \/var\/log\/httpd\/error\_log/' /etc/httpd/conf/httpd.conf

#Possible way for logrotate to work??? Work on this as well possibly in logrotate.d/httpd
sudo echo /var/log/httpd/error_log '{' >> /etc/logrotate.d/httpd
sudo echo daily >> /etc/logrotate.d/httpd
sudo echo rotate 0 >> /etc/logrotate.d/httpd
sudo echo maxage 7 >> /etc/logrotate.d/httpd
sudo echo '}' >> /etc/logrotate.d/httpd

#Install wget
sudo dnf -y install wget

#Install rsync
sudo dnf -y install rsync
sudo dnf -y install rsync-daemon
sudo systemctl start rsyncd
sudo systemctl enable rsyncd

#Install NTP using chrony, as ntp is no longer supported
sudo dnf -y install chrony
sudo systemctl start chronyd
sudo systemctl enable chronyd


#Remaining LAMP stack install
sudo dnf install -y mariadb-server mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
#The following skips setting a password for ease of testing.
#Removes anonymous users, diallows root login remotely
#Removes test database and access to it, and reloads privilege tables.
mysql_secure_installation << EOF

n
Y
Y
Y
Y
EOF

#Install PHP from repository
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install dnf-utils -y http://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf module reset php
sudo dnf module enable -y php:remi-8.0
sudo dnf install -y php php-opcache php-gd php-curl php-mysqlnd
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo setsebool -P httpd_execmem 1
sudo systemctl restart httpd


#Create database for WordPress
sudo mysql -u root -p << EOF
CREATE DATABASE wordpress;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'admin'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
exit
EOF
sudo systemctl restart httpd

#Install WordPress, transfer files with rsync & make new directory for uploads
sudo wget http://wordpress.org/latest.tar.gz
sudo tar xzvf latest.tar.gz
#sudo chown -R test:test wordpress
sudo rsync -avP /~/wordpress/ /var/www/html/
sudo mkdir /var/www/html/wp-content/uploads
sudo chown -R apache:apache /var/www/html/*

#Connect WordPress to database/edit config file.
cd /var/www/html
sudo cp wp-config-sample.php wp-config.php
sudo sed -i 's/database\_name\_here/wordpress/' wp-config.php
sudo sed -i 's/username\_here/admin/' wp-config.php
sudo sed -i 's/password\_here/password/' wp-config.php








