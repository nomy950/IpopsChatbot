#!/bin/bash
# your script here

ibmcloud login --apikey $0 -r kr-seo
ibmcloud ks cluster config -c rias-ng-us-south-dal12-preprod
kubectl get pods -A
