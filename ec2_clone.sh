#!/bin/bash

##########################################################################
#
# This script will create an image of the existing Ec2 and then launch the
# new Ec2 machine, and update the DNS in Route53 for DesigNet Servers
# This script is copyright of @Above-inc.com
# Contact E-mail ID: cloudops@above-inc.com
#
##########################################################################

# Enter the old hostname of the machine
echo "Enter the Instance ID of current Ec2 instance"
read InstanceID

# Enter the size of the machine that you want to launch with new AMI. Make sure you add valid size like: t2.micro, t2.small, t2.medium, c3.large
echo "Enter the instance-type for your new machine. Make sure you add valid size like: t2.micro, t2.small, t2.medium, c3.large"
read InstanceType

# Enter the full hostname of your machine for DNS
echo "Enter the full hostname of your machine: Like: abc.xyz.designet.com"
read DNSNAME

# Enter the name of the DesignNet Customer
echo "Enter the name of the customer"
read CustomerName

# This will create an image of the mentioned instance
aws ec2 create-image  --instance-id $InstanceID --name "$CustomerName-`date +%Y%m%d%H%M`" --description "$CustomerName-`date +%Y%m%d%H%M`" --region us-east-1 --no-reboot --output text > /tmp/clone

newami=`cat /tmp/clone`

aws ec2 describe-images  --image-id $newami --output text | grep -w available
while [ $? -ne 0 ]; do
        sleep 60
    aws ec2 describe-images  --image-id $newami --output text | grep -w available
done

aws ec2 create-tags --resources $newami --tags Key=Name,Value=$CustomerName

# This will launch the new EC2 machine using the newly created image
# NOTE: You need to fill your own details for the hardcoded value in the following command
aws ec2 run-instances --image-id $newami --count 1 --instance-type $InstanceType --key-name New-AMI-Designet --security-group-ids sg-66567403 --subnet-id subnet-29abb46f --output text > /tmp/amihost

# This will extract the instance ID of the new Ec2
amihost=`cat /tmp/amihost | awk '{print $7}' | grep i-`

sleep 60

# This will describe the status of the newly create Ec2 machine and will extract the IP
aws ec2 describe-instances --instance-ids $amihost  --output text > /tmp/ip

# Extract the Public IP of the machine
IP=`cat /tmp/ip | grep -m 1 ASSOCIATION | awk '{print $3}'`

# Update the tags on newly launch machine
aws ec2 create-tags  --resources $amihost --tags Key=Name,Value=$DNSNAME
aws ec2 create-tags  --resources $amihost --tags Key=Environment,Value=Copy
aws ec2 create-tags  --resources $amihost --tags Key=Customer,Value=$CustomerName

# It will create a template in json formate for A record
cat > /tmp/record.json <<EOF
{
  "Comment": "A new record set for the zone.",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DNSNAME.",
        "Type": "A",
        "TTL": 600,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF

# This will update the DNS record in Route 53
aws route53 change-resource-record-sets --hosted-zone-id  Z291C6B8Y236W4 --change-batch file:///tmp/record.json

# Clean up the files created for this script
rm /tmp/clone
rm /tmp/amihost
rm /tmp/record.json
rm /tmp/ip
echo "All Done"