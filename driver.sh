    #! /bin/bash
    #set -u
    issue_number = 71
    sudo sh rias_scripts/dev_rias_71.sh ${d_api_key}
    export JOB_LOG="$PIPELINE_LOG_URL"
    echo ${JOB_LOG}
    