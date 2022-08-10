#!/bin/bash
# your script here

ibmcloud login --apikey $1 -r kr-seo
clusterName=`ibmcloud ks clusters | grep $2 | grep $3 | awk '{ print $1 }'`
ibmcloud ks cluster config -c $clusterName
chmod +x create-jumpod.sh
./create-jumpod.sh
#kubectl get pods -A
