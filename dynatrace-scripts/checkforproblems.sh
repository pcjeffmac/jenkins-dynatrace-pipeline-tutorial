#!/bin/bash
# Bash Script that will query problem details from Dynatrace. The script will return the number of open problems matching the supplied tags
# This can be called from Jenkins like this
# DYNATRACE_PROBLEM_COUNT = sh (script: './dynatrace-scripts/checkforproblems.sh', returnStatus)

# Either set your Dynatrace Token and URL in this script or pass it as Env Variables to this Shell Script
# DT_TOKEN=YOURAPITOKEN
# DT_URL=https://YOURTENANT.live.dynatrace.com

output=$(curl -H "Content-Type: application/json" -H "Authorization: Api-Token ${DT_TOKEN}" -X GET ${DT_URL}/api/v1/problem/status)
echo $output | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(obj["result"]["totalOpenProblemsCount"]);'