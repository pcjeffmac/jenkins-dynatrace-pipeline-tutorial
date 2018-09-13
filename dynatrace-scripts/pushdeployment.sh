#!/bin/bash

# Bash Script that will push a Custom Deployment event to Dynatrace via ${DT_URL}/api/v1/events
# The script also assumes the ${DT_TOKEN} contains your API-Token!
# Either set your Dynatrace Token and URL in this script or pass it as Env Variables to this Shell Script
# DT_TOKEN=YOURAPITOKEN
# DT_URL=https://YOURTENANT.live.dynatrace.com
# When used with Jenkins we suggest to define DT_TOKEN and DT_URL as Global Environment Variables - they will then get passed to your shell script automatically

# Usage:
# ./pushtag.sh ENTITYTYPE TAGCONTEXT TAGNAME TAGVALUE DEPLOYMENTNAME DEPLOYMENTVERSION DEPLOYMENTPROJECT SOURCE CILINK JENKINSURL BUILDURL GITCOMMIT

# Example from command line:
# Pushing a Custom Deployment Event to a HOST with the tag [AWS]Environment:JenkinsTutorial
# ./pushtag.sh HOST AWS Environment JenkinsTutorial DemoDeploy 1.0 MyProject Jenkins http://myjenkins http://myjenkins/job http://myjenins/build gitcommitid

# Example from Jenkins:
# Pushing same Custom Deployment event using Jenkins Propeties
# ./dynatrace-scripts/pushtag.sh HOST AWS Environment JenkinsTutorial ${BUILD_TAG} ${BUILD_NUMBER} ${JOB_NAME} Jenkins ${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}

buildurl=$11

PAYLOAD=$(cat <<EOF
{
  "eventType": "CUSTOM_DEPLOYMENT",
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
  "deploymentName" : "$5",
  "deploymentVersion" : "$6",
  "deploymentProject" : "$7",
  "source" : "$8",
  "ciBackLink" : "$9",
  "customProperties" : {
    "JenkinsUrl" : "$10",
    "BuildUrl" : "$buildurl",
    "GitCommit" : "$12"
  }
}
EOF
)

echo $10
echo $11

echo $PAYLOAD
echo ${DT_URL}/api/v1/events
curl -H "Content-Type: application/json" -H "Authorization: Api-Token ${DT_TOKEN}" -X POST -d "${PAYLOAD}" ${DT_URL}/api/v1/events
