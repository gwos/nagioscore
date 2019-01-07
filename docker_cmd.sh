#!/bin/bash

# Reverse these if applicable:
goodhost=localhost
badhost=host.docker.internal


sed -i "s/${badhost}/${goodhost}/g" /usr/local/groundwork/config/*
#sed -i "s/${badhost}/${goodhost}/g" /src/config/*
#sed -i 's/ 80$/ 8091/' /etc/apache2/ports.conf

/usr/local/nagios/bin/nagios -d /usr/local/nagios/etc/nagios.cfg
sleep 999999
