#!/bin/bash

for ID in $(/home/manpreet/aws/delete)
do
        #aws ec2 terminate-instances --instance-ids $ID
        echo $ID
done