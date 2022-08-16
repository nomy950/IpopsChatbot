    #! /bin/bash
    #set -u
    issue_number=68
    echo $issue_number
    sudo sh rias_scripts/dev_rias_68.sh ${d_api_key}
    export JOB_LOG="$PIPELINE_LOG_URL"
    echo ${JOB_LOG}
    
