#!/bin/bash

# Bash Script that will push a Custom Annotation event to Dynatrace via ${DT_URL}/api/v1/events
# The script also assumes the ${DT_TOKEN} contains your API-Token!
# Either set your Dynatrace Token and URL in this script or pass it as Env Variables to this Shell Script
# DT_TOKEN=YOURAPITOKEN
# DT_URL=https://YOURTENANT.live.dynatrace.com
# When used with Jenkins we suggest to define DT_TOKEN and DT_URL as Global Environment Variables - they will then get passed to your shell script automatically

# Usage:
# ./pushevent.sh ENTITYTYPE TAGCONTEXT TAGNAME TAGVALUE ANNOTATIONTYPE SOURCE ANNOTATIONDESCRIPTION CILINK JENKINSURL BUILDURL GITCOMMIT

# Example from command line:
# Pushing a Custom Deployment Event to a HOST with the tag [AWS]Environment:JenkinsTutorial
# ./pushevent.sh HOST AWS Environment JenkinsTutorial "Start Load Test" "Jenkins Job XYZ" "My description about this event" http://myjenkins http://myjenkins/job http://myjenins/build gitcommitid

# Example from Jenkins:
# Pushing same Custom Deployment event using Jenkins Propeties
# ./dynatrace-scripts/pushevent.sh SERVICE CONTEXTLESS DockerService SampleNodeJsStaging "Starting Load Test" ${JOB_NAME} "Starting a JMeter Load Testing as part of the Testing stage" ${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}

PAYLOAD=$(cat <<EOF
{
  "eventType": "CUSTOM_ANNOTATION",
  "attachRules" : {
    "tagRule" : [
      {
        "meTypes" : ["$1"],
        "tags" : [
          {
            "context" : "$2",
            "key" : "$3",
            "value" : "$4"
          }]
      }]
  },
  "annotationType" : "$5",
  "source" : "$6",
  "annotationDescription" : "$7",
  "customProperties" : {
    "JenkinsUrl" : "$8",
    "BuildUrl" : "$9",
    "GitCommit" : "${10}"
  }
}
EOF
)

echo $PAYLOAD
echo ${DT_URL}/api/v1/events
curl -H "Content-Type: application/json" -H "Authorization: Api-Token ${DT_TOKEN}" -X POST -d "${PAYLOAD}" ${DT_URL}/api/v1/events
