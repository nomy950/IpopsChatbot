    #! /bin/bash
    set -u
    sudo sh rias_scripts/dev_rias_79.sh ${d_api_key}
    export JOB_LOG="$PIPELINE_LOG_URL"
    echo ${JOB_LOG}
    