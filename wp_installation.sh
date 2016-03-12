#!/bin/bash

##########################################################################
#
# This script will install Wordpress on Ubuntu Server
# This script is copyright of @Above-inc.com
# Contact E-mail ID: cloudops@above-inc.com
#
##########################################################################

# Wordpress configuration on ubuntu14.04

# Entering the name of the Project
echo "Enter the name of the Project"
read project

# Enter the valid email ID to recieve .ssh key for sftp 
echo "Enter the E-mail ID"
read mailid

# Installing and updating the packages on server
apt-get update -y
apt-get install nginx php5-fpm -y

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default_`date +%y%m%d`

# Updating nginx file with necessary parameters
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /home/$project/wordpress;
    index index.php index.html index.htm;

    server_name localhost;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Adding project user for ftp access
addgroup sftpusers
useradd -d /home/$project -m $project -g sftpusers -s /bin/false
chown -R root.root /home/$project
cd /home/$project

# Downloading wordpress package 
wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
rm latest.tar.gz

# Coping and entring the values in config file of WP
cp wordpress/wp-config-sample.php wordpress/wp-config.php
chgrp -R www-data wordpress/
chmod -R g+s wordpress/


# Installing makepasswd for generating random password
apt-get install makepasswd -y

# If mysql-server installed, then it will not create a password for root 
if [ -f "/root/.mysql_password" ]
then
        continue
else
        makepasswd --chars 16 > /root/.mysql_password
fi

# Creating password for
makepasswd --chars 16 > /root/.password_"$project"

# Installing/Updating OS env for mysql root password
apt-get install debconf-utils -y
echo "mysql-server-5.5 mysql-server/root_password password `cat /root/.mysql_password`" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password `cat /root/.mysql_password`" | debconf-set-selections

# Installing mysql-server
apt-get install mysql-server php5-mysql -y

# Creating and grantion permission to project User
mysql -u root -p`cat /root/.mysql_password` -e "create database $project"
mysql -u root -p`cat /root/.mysql_password` -e "CREATE USER '$project'@'localhost' IDENTIFIED BY '`cat /root/.password_"$project"`'"
mysql -u root -p`cat /root/.mysql_password` -e "GRANT ALL PRIVILEGES ON $project.* TO '$project'@'localhost'"

# Updating values in wp-config file
sed -i "s/database_name_here/$project/g" /home/$project/wordpress/wp-config.php
sed -i "s/username_here/$project/g" /home/$project/wordpress/wp-config.php
sed -i "s/password_here/`cat /root/.password_$project`/g" /home/$project/wordpress/wp-config.php

cat >> /etc/ssh/ssh_config <<EOF
Match group sftpusers
  ChrootDirectory %h
  AuthorizedKeysFile /home/%u/.ssh/authorized_keys
  ForceCommand internal-sftp
  AllowTcpForwarding no
EOF

/etc/init.d/ssh restart
/etc/init.d/nginx restart
/etc/init.d/php5-fpm restart

echo "Almost Done"

# Installing mutt and postfix utility to send the ssh key to the sftp user
DEBIAN_FRONTEND=noninteractive apt-get -y install mutt postfix -y

# Creating .ssh key for passwordless authentication
if [ -d /home/$project ]; then
	cd /home/$project
	sleep 2
		if [ -d /home/$project/.ssh ]; then
				mv .ssh .ssh_old
				mkdir .ssh
		else
				mkdir .ssh
		fi	
	if [ -d /home/$project/.ssh ]; then
			cd /home/$project/.ssh
			ssh-keygen -b 2048 -t rsa -N "" -f /home/$project/.ssh/id_rsa > /dev/null
			chmod 700 /home/$project/.ssh/id_rsa
			cat /home/$project/.ssh/id_rsa.pub >> /home/$project/.ssh/authorized_keys
			chmod 700 /home/$project/.ssh
			chmod 600 /home/$project/.ssh/authorized_keys
			echo -e "Your username: $project" | mutt -a "/home/$project/.ssh/id_rsa" -s "Access for the `hostname`" -- $mailid
			
	else 
			echo ".ssh directiry does not exist at /home/$project/.ssh"
		fi
	else
		echo "$project home directory does not exist"
fi