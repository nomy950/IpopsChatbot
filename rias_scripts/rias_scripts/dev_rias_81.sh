    #! /bin/bash
    ibmcloud login --apikey $1 -r kr-seo
    clusterName=`ibmcloud ks clusters | grep dal12 | grep preprod`
    ibmcloud ks cluster config -c $clusterName
    kubectl get pods -A
    