#!/bin/bash
############################################################################
# This script is used to create Multi tentant Neev Platform on Ubuntu
# Copyright above-inc.com
# Email: cloudops@above-inc.com
############################################################################

# Enter the domain name for your domain, it will be sub-domain of 'mantest.com'
echo "Please enter the domain Name, that will be sub domain on mantest.com"
read domain

# Code to check the domain name previously exist of the server
if [ -d /var/www/html/$domain.mantest.com ]; then
	echo "We are Sorry, this domain has already been taken, please try another domain name"
	exit
   else
        echo "Please standy, your domain is in progress"
	continue
fi

# Checking the Newport for sails lift
#port=`cat ./port`
#newport=`expr $port + 1`
#echo $newport > ./port
port=`netstat -tulpn | grep node | awk '{print $4}' | sed -r 's/^.{3}//' | tail -1`
if [ -z $port ]; then
        newport=1337
   else
       newport=`expr $port + 1`
fi

# Code to update nginx conf file
cat > /etc/nginx/sites-enabled/$domain.mantest.com <<EOF
upstream node_$domain {
  server localhost:$newport;
}

server {
  listen 80;
  
  server_name $domain.mantest.com;

  index index.html index.htm app/index.html;
  root /var/www/html/$domain.mantest.com;


## logging options ##
#-------------------
  access_log /var/log/nginx/$domain.access.log combined;
  error_log /var/log/nginx/$domain.error.log;


## Redirect to /app for the requests on / ##
#---------------------------------------------
  location = / { 
    rewrite ^(.*) http://$domain.mantest.com/app/ break;
  }

# Pass the PHP scripts to FastCGI server listening on the php-fpm socket
#----------------------------------------------------------------------
        location ~ /\.php$ {
                try_files \$uri =404;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME /$document_root$fastcgi_script_name;
                include fastcgi_params;
                
        }

# Pass Sails api calls
#---------------------------------------------------------------
  location /api {
    alias /var/www/html/$domain.mantest.com/sails-ayny/;
    try_files \$uri \$uri/ @node_$domain;
  }

  location @node_$domain {
    rewrite /api(.*) \$1 break;

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$proxy_host;
    proxy_set_header X-NginX-Proxy true;

#    proxy_pass http://127.0.0.1:1337;
    proxy_pass http://node_$domain;
    proxy_redirect http://node_$domain/ /api/;
#     proxy_redirect off;
#    client_max_body_size                            32M;
#    client_body_buffer_size                         512k;
#    proxy_connect_timeout                           90;
#    proxy_send_timeout                              90;
#    proxy_read_timeout                              4000;
#    proxy_buffers                                   32 4k;

  }

# Pass the odoo partner api 
#------------------------------------------------------------
#location /odooapi {
#    try_files \$uri \$uri/ @odoo;
#  }

#  location @odoo {
#    rewrite /odooapi(.*) \$1 break;
#    uwsgi_pass odoo;
#  }
 location /odooapi {
            uwsgi_pass unix:///tmp/uwsgi.sock;
        include uwsgi_params;
        # strip path before handing it to app
        uwsgi_param SCRIPT_NAME /odooapi;
        uwsgi_modifier1 30;
    }

## Deny all requests for git files ##
#-------------------------------------
        location ~ /(\.git).* {
                deny  all;
        }

## Browser Cache
# -----------------------
         location ~* \.(js|css|html|png)$ {
         add_header    Cache-Control "public";
         expires           1M;
         access_log        off;
         add_header Cache-Control "public";
   }
}
EOF

# This code will create document root of the domain
mkdir /var/www/html/$domain.mantest.com

# Code will copy the application code to the document root
cp -R /opt/ayny/brooklyn/* /var/www/html/$domain.mantest.com

# Code will create an upstart script 
cat > /etc/init/node-$domain.conf <<EOF
description "NodeJS Server"
author "admin"

env PORT=$newport
#env NODE_ENV=production

start on runlevel [2345]
stop on runlevel [016]
respawn

setuid root
chdir /var/www/html/$domain.mantest.com/sails-ayny/
exec node app.js
EOF

# This will change the code for the database and will create the same database in th mongodb
sed -i "s/brroklyn/$domain/g" /var/www/html/$domain.mantest.com/sails-ayny/config/connections.js

# Relodaing the nginx to reflect the changes
/etc/init.d/nginx reload

# Starting the neev node
service node-$domain start
