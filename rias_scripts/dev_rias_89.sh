    #! /bin/bash
    ibmcloud login --apikey $1 -r kr-seo
    clusterName=`ibmcloud ks clusters | grep dal10 | grep preprod | awk '{ print $1 }'`
    ibmcloud ks cluster config -c $clusterName
    echo "<Logs_Start>"
    kubectl get pods -A
    echo "<Logs_End>"
    