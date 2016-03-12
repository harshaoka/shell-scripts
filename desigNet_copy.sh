#!/bin/bash

##########################################################################
#
# This script make copy of DesigNet Servers
# This script is copyright of @Above-inc.com
# Contact E-mail ID: cloudops@above-inc.com
#
##########################################################################

# Enter the old hostname of the machine
echo "Enter the Old name"
read old

# Enter the new hostname of the machine
echo "Enter the new name"
read new

# Disabling the crons
sed -i '/\/u\/dbbackup-scripts\/synctos3.sh/s!^!#!' /var/spool/cron/root
sed -i '/\/u\/dbbackup-scripts\/db_s3sync.sh/s!^!#!' /var/spool/cron/root

#Updaing the hostname in different files
sed -i "s/$old/$new/g" /etc/hosts
sed -i "s/$old/$new/g" /etc/sysconfig/network
sed -i "s/$old/$new/g" /opt/smart/tomcat/webapps/DNAnalysis/DNAnalysis.html
sed -i "s/$old/$new/g" /opt/smart/tomcat/webapps/DNAnalysis/assets/properties.xml

# Updating the hostname of the machine
var=`cat /etc/hosts | grep $new | awk '{ print $2 }'`
hostname $var

# Starting database services and updating the database tables
service postgresql start

sleep 60

sudo su -c "psql -d DNAnalysis -c \"update application.qrtz_triggers set trigger_state ='PAUSED' where trigger_state='WAITING'\"" - postgres
sudo su -c "psql -d DNAnalysis -c \"update application.qrtz_triggers set trigger_state = 'PAUSED'  where job_group ='Reports'\"" - postgres


# Starting rest of the services on the server
service tomcat start > /dev/null 2>&1
service dirmonitor restart > /dev/null 2>&1
/etc/init.d/csvarchiver restart > /dev/null 2>&1



