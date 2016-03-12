#!/bin/bash

##########################################################################
#
# This script will install node.js, sails and mongodb on Ubuntu Server
# This script is copyright of @Above-inc.com
# Contact E-mail ID: cloudops@above-inc.com
#
##########################################################################

# Installing make, g++ and git
apt-get install -y make g++ git

# Adding repo for nodejs, npm and sails
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -

# Installing nodejs, npm and sails
apt-get install -y nodejs
npm install -y -g npm
npm -g install -y sails

# Adding repo for mongodb as well as ffmpeg
add-apt-repository ppa:kirillshkrogalev/ffmpeg-next -y
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list

# Updating the repo
apt-get update -y

# Installing ffmpeg and mongobd
apt-get install -y ffmpeg
apt-get install -y mongodb-org