#!/bin/bash
echo "Enter the domain to be deleted"
read domain

if [ -d /var/www/html/$domain.mantest.com ]; then
	echo "Going to delete $domain from the server"
	service node-$domain stop
	rm -rf /var/www/html/$domain.mantest.com
	rm -rf /etc/nginx/sites-enabled/$domain.mantest.com
	rm -rf /var/log/nginx/$domain.*
	rm -rf /etc/init/node-$domain.conf
	echo "All done"
  else
	echo "Domain does not exist on the server"
fi
