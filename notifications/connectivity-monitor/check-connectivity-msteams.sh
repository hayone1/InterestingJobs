#!/bin/bash

# -----
# variables template.
# this will generally be set from kubernetes/docker environment variable
# but you can uncomment them if using pure bash

# HTTPS_PROXY=XXX
# HTTP_PROXY=XXX
# FTP_PROXY=XXX
# NO_PROXY=XXX
# PROXY_ON_NOTIFICATION=true
# PROXY_ON_STARTUP=false
# PROXY_DURING_TEST=false
# NOTIFY_ON_SUCCESS=false
# SUCCESS_STATUS="SUCCESS"
# FAILURE_STATUS="FAILURE"
# NOTIFY_ON_FAILURE=true
# RESULTS_FILE_NAME="connectivity-test.txt"
# WEBHOOK_URL="XXX"
# SCRIPT_URL=""
# HOSTS='
# [
#     {
#         "name" : "XXX",
#         "host" : "XXX",
#         "port" : "XXX"
#     },
#     {
#         "name" : "XXX",
#         "host" : "XXX",
#         "port" : "XXX"
#     }
# ]'
# TEAM='
# [
#   {
#     "type": "mention",
#     "text": "<at>name</at>",
#     "mentioned": {
#         "id": "name.name@domain.com",
#         "name": "name name"
#     }
#   },
#   {
#     "type": "mention",
#     "text": "<at>name</at>",
#     "mentioned": {
#         "id": "name.name@domain.com",
#         "name": "name name"
#     }
#   }
# ]
# '
# -----
#convert sleep interval to number
original_sleep_interval=$((SLEEP_INTERVAL))
sleep_interval=$((SLEEP_INTERVAL))
retry_exponent=$((RETRY_EXPONENT))
max_retry_interval=$((MAX_RETRY_INTERVAL))

function SendNotification(){
    local formattedStatuses=$1
    # emailFormat=$(echo "$formattedStatuses" | jq -c -r '.[][]' | sed ':a;N;$!ba;s/\n/%0D%0A/g')
    # emailFormat="${emailFormat//$'\n'/ }"
    # emailFormat=$(echo "$formattedStatuses" | jq -c -r '.[][]' | tr '\n' '')
    mentions=$(echo "$TEAM" | jq -r '.[].text' | paste -sd ',')
    echo "formattedStatuses: $formattedStatuses"
    # echo "EMAILformattedStatuses: $emailFormat"
    
    curl -X POST -H 'Content-Type: application/json' \
        -d '{
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": null,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.2",
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": "'"[Connection][Alert]: ${mentions}"'",
                            "wrap": "true"
                        },
                        {
                            "type": "FactSet",
                            "facts": '"$formattedStatuses"'
                        }
                    ],
                    "msteams": {
                        "entities": '"$TEAM"'
                    }
                }
            }
        ]
    }' "$WEBHOOK_URL"
}

function SendNotification(){
    local formattedStatuses=$1
    mentions=$(echo "$TEAM" | jq -r '.[].text' | paste -sd ',')
    echo "formattedStatuses: $formattedStatuses"
    curl -X POST -H 'Content-Type: application/json' \
        -d '{
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": null,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.2",
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": "'"[Connection][Alert]: ${mentions}"'",
                            "wrap": "true"
                        },
                        {
                            "type": "FactSet",
                            "facts": '"$formattedStatuses"'
                        }
                    ],
                    "msteams": {
                        "entities": '"$TEAM"'
                    }
                }
            }
        ]
    }' "$WEBHOOK_URL"
}

function SendNotification(){
    local formattedStatuses=$1
    mentions=$(echo "$TEAM" | jq -r '.[].text' | paste -sd ',')
    echo "formattedStatuses: $formattedStatuses"
    curl -X POST -H 'Content-Type: application/json' \
        -d '{
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": null,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.2",
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": "'"[Connection][Alert]: ${mentions}"'",
                            "wrap": "true"
                        },
                        {
                            "type": "FactSet",
                            "facts": '"$formattedStatuses"'
                        }
                    ],
                    "msteams": {
                        "entities": '"$TEAM"'
                    }
                }
            }
        ]
    }' "$WEBHOOK_URL"
}

function ProcessNofitication(){
    local statuses=$1
    #if use proxy when sending notification
    if [[ $PROXY_ON_NOTIFICATION == "true" ]]; then
        export https_proxy="$HTTPS_PROXY"
        export http_proxy="$HTTP_PROXY"
        export ftp_proxy="$FTP_PROXY"
        export no_proxy="$NO_PROXY"
    fi

    #convert multiline json to json string array
    formattedStatuses=$(echo "${statuses[@]}" | jq -n '. |= [inputs]')
    # Check if the statuses contains the any FAILURE_STATUS
    ContainsFailedTest=$(echo "$formattedStatuses" | grep -Fq "[$FAILURE_STATUS]" && echo true)
    echo "ContainsFailedTest: $ContainsFailedTest"

    #if one of more connectivity tests failed
    if [[ "$ContainsFailedTest" == true ]]; then
        echo "---Failure found in connectivity test---"

        sleep_interval=$((sleep_interval * retry_exponent))
        # clamp the value of sleep_interval to max_retry_interval
        if [ "$sleep_interval" -gt "$max_retry_interval" ]; then
                sleep_interval="$max_retry_interval"
        fi
        echo "---Set sleep-retry interval to: $sleep_interval"

        # if notify on failure is true
        if [[ $NOTIFY_ON_FAILURE == "true" ]]; then
            echo "---Sending Failure Notification---"
            SendNotification "$formattedStatuses"
        fi
    else # if all tests were successful
        # ensure sleep_interval equals original_sleep_interval
        echo "---All connectivity tests successful---"
        sleep_interval=$((original_sleep_interval))
        echo "---Set sleep-retry interval to: $sleep_interval"
        # if notify on success is true
        if [[ $NOTIFY_ON_SUCCESS == "true" ]]; then
        echo "---Sending Success Notification---"
            SendNotification "$formattedStatuses"
        fi
    fi
    # just to print out the false condition
    ContainsFailedTest=$(echo "$formattedStatuses" | grep -Fq "[$FAILURE_STATUS]" || echo false)
    echo "ContainsFailedTest: $ContainsFailedTest"
    
}

function GetMessage(){
    local name=$1
    local host=$2
    local port=$3
    local status=$4

    # TimeStamp=$(date)
    Message='{"title": "'"${name}"'", "value": "'"[[${status}](http://$host)]=>[host]: ${host}・[port]: $port"'"}'
    echo "$Message"
}

function CheckConnection() {
    #if proxy should be activated before test
    if [[ $PROXY_DURING_TEST == "true" ]]; then
        export https_proxy="$HTTPS_PROXY"
        export http_proxy="$HTTP_PROXY"
        export ftp_proxy="$FTP_PROXY"
        export no_proxy="$NO_PROXY"
    fi

    lineCreateSuffix="-connectivity-test"
    hostsArrayLength=$(echo "$HOSTS" | jq 'length')
    echo "hostsArrayLength: ${hostsArrayLength}"

    #create file that keeps result
    install -Dv /dev/null "$RESULTS_FILE_NAME"
    
    # create lines(numbers) in the file by using number placeholders starting from 0
    seq 0 $(("$hostsArrayLength" - 1)) | tee "$RESULTS_FILE_NAME"
    # append text to line numbers for placeholder replacement later on
    sed -i "s/$/${lineCreateSuffix}/" connectivity-test.txt
    for ((i = 0; i < "$hostsArrayLength"; i++))
    # while read host_data
    do
        host_data=$(echo "$HOSTS" | jq ".[$i]")
        name=$(echo "$host_data" | jq -r .name)
        host=$(echo "$host_data" | jq -r .host)
        port=$(echo "$host_data" | jq -r .port)

        Title="Test Connectivity to ${name}"
        statusMessage=""
        # will be the status to connection
        
        
        (
        echo "$Title"
        if nc -z -w 2 "$host" "$port"; then
            echo "success"
            statusMessage="$SUCCESS_STATUS"
        else
            echo "failure"
            statusMessage="$FAILURE_STATUS"
        fi
        #add result in file line
        currentLineContent="${i}${lineCreateSuffix}"
        echo "currentLineContent: ${currentLineContent}"

        # replace placeholder using sed -i 's/old-text/new-text/g' file.txt
        # -i.bak and \< ensure to replace exactly the text considering the length as well
        #eg. it differentiates between 1-connectivity-test and 11-connectivity-test
        # sed -i "s^${currentLineContent}^$(GetMessage "$name" "$host" "$port" "$statusMessage")^ig" "$RESULTS_FILE_NAME"
        sed -i.bak "s^\<${currentLineContent}\>^$(GetMessage "$name" "$host" "$port" "$statusMessage")^g" "connectivity-test.txt"
        # sed -i "${i}iokok" "$RESULTS_FILE_NAME"

        # echo "${name}=${host}:${port}"
    ) &
    done
    wait
    # load file content

    echo "Test Results: $(cat "$RESULTS_FILE_NAME")"

    ProcessNofitication "$(cat "$RESULTS_FILE_NAME")"
}

while true; do
    #check connection at least once
    CheckConnection

    if [ "$sleep_interval" -le 0 ]; then
        break
    fi
    sleep "$sleep_interval"
done
# echo "$sleep_interval"

