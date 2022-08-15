    #! /bin/bash
    set -u
    sudo sh dev_rias_78.sh ${d_api_key}
    export JOB_LOG="$PIPELINE_LOG_URL"
    echo ${JOB_LOG}
    