#!/bin/bash
# your script here

ibmcloud login --apikey 9r216S5Gx09EnSoz3fhp1z18hY0_WNPALDLZ2siKR8f3 -r kr-seo
ibmcloud ks cluster config -c rias-ng-us-south-dal12-preprod
kubectl get pods -A
