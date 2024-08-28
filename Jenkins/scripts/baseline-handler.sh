#!/usr/bin/env bash
set -e
set -x
cmd=$1
DOCKER=docker
case $cmd in
    prepare)
        echo "Start prepare command"
        ;;
    publish)
        echo "Start publish command"
        ;;
    dryrun)
        echo "Start dryrun"
        DOCKER="echo docker "
        ;;
    *)
        echo "Invalid parameter: '$cmd', must provide: prepare or publish"
        exit 1
        ;;
esac
   
if [ -z "$cmd" ]; then
    echo "Must provide command: prepare or publish"
    exit 1
fi
      
IMAGE=armdocker.rnd.ericsson.se/proj-adp-cicd-drop/adp-int-helm-chart-auto:latest
HELM_REPO_INT="https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-edca-ci-internal-helm/"
HELM_REPO_DRP="https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-edca-drop-helm/"
HELM_REPO_REL="https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-edca-released-helm/"
HELM_USERNAME=enmadm100

# This is an example how to add sub-chart update
#LOGGING_FA_GIT="https://gerrit.ericsson.se/adp-cicd/fa-charts/fa-logging"
#LOGGING_FA_CHART_PATH="charts/eric-adp-log-fa"
#LOGGING_FA_BRANCH="incatest"
DEMO_GIT="https://gerrit.ericsson.se/ADP-huboss/Microservices/edca-integration-charts"
DEMO_CHART_PATH="charts/eric-edca-integration-helm"
DEMO_BRANCH="master"
$DOCKER pull ${IMAGE} || true
$DOCKER inspect ${IMAGE} -f '{{range $key, $value := .Config.Labels}}{{printf "%s: %s\n" $key $value}}{{end}}' || true
# Set to true if want to handle sub-charts (a.k.a functional area helm charts)
#FA_ENABLED="false"
#if [ "${FA_ENABLED}" == "true" ] &&
# These are example chart name, first line is the sub-chart name
#   (([ "${CHART_NAME}" == "eric-adp-log-fa" ] && [ ! -z "${GERRIT_REFSPEC}" ]) ||
# The reset are dependencies in the sub-chart
#     [ "${CHART_NAME}" == "eric-data-search-engine" ] ||
#     [ "${CHART_NAME}" == "eric-log-transformer" ] ||
#     [ "${CHART_NAME}" == "eric-data-search-engine-curator" ] ||
#     [ "${CHART_NAME}" == "eric-log-shipper" ]);
#then
#   echo
#    echo "##########################"
#    echo "# LOGGING FA CHART       #"
#    echo "##########################"
#    echo
#    if [ ! -z "${GERRIT_REFSPEC}" ]; then
#        CHART_NAME=""
#    fi
#    VOL=$WORKSPACE/logging-fa
#    mkdir -p $VOL
#    $DOCKER run --init --rm --user $(id -u):$(id -g) \
#      --env CHART_NAME \
#      --env CHART_REPO \
#      --env CHART_VERSION \
#      --env GERRIT_REFSPEC \
#      --env GERRIT_USERNAME \
#      --env GERRIT_PASSWORD \
#      --env GIT_BRANCH=${LOGGING_FA_BRANCH} \
#      --env ARM_API_TOKEN \
#      --env HELM_REPO_CREDENTIALS=/tmp/helm-repositories-file \
#      --env GIT_REPO_URL=${LOGGING_FA_GIT} \
#      --env CHART_PATH=${LOGGING_FA_CHART_PATH} \
#      --env HELM_DROP_REPO=${HELM_REPO_REL} \
#      --env HELM_INTERNAL_REPO=${HELM_REPO_INT} \
#      --env HELM_RELEASED_REPO=${HELM_REPO_REL} \
#      --env ALLOW_DOWNGRADE="false" \
#      --env IGNORE_NON_RELEASED="false" \
#      --env AUTOMATIC_RELEASE="true" \
#      --env ALWAYS_RELEASE=false \
#      --env SOURCE=${JENKINS_URL}/job/${JOB_NAME}/${BUILD_NUMBER} \
      # --env GERRIT_TOPIC="inca" \
      # --env UPLOAD_INTERNAL \
      # --volume $VOL:$VOL \
      # --volume $HELM_REPO_CREDENTIALS:/tmp/helm-repositories-file:ro \
      # --workdir $VOL ${IMAGE} \
      # ihc-auto $cmd
   # unset GERRIT_REFSPEC
   # export CHART_NAME=$(grep -m 1 "INT_CHART_NAME=" $VOL/artifact.properties | awk -F= '{print $2}')
   # export CHART_REPO=$(grep -m 1 "INT_CHART_REPO=" $VOL/artifact.properties | awk -F= '{print $2}')
   # export CHART_VERSION=$(grep -m 1 "INT_CHART_VERSION=" $VOL/artifact.properties | awk -F= '{print $2}')
# fi
echo
echo "#######################"
echo "#  EDCA-APP BASELINE  #"
echo "#######################"
echo
echo $CHART_NAME
echo $CHART_REPO
echo $CHART_VERSION
$DOCKER run --init --rm --user $(id -u):$(id -g) \
  --env CHART_NAME \
  --env CHART_REPO \
  --env CHART_VERSION \
  --env GERRIT_REFSPEC \
  --env GERRIT_USERNAME \
  --env GERRIT_PASSWORD \
  --env GIT_BRANCH=${DEMO_BRANCH} \
  --env HELM_USER=${HELM_USERNAME} \
  --env ARM_API_TOKEN=${ARM_API_TOKEN} \
  --env HELM_REPO_CREDENTIALS=/tmp/helm-repositories-file \
  --env GIT_REPO_URL=${DEMO_GIT} \
  --env CHART_PATH=${DEMO_CHART_PATH} \
  --env HELM_INTERNAL_REPO=${HELM_REPO_INT} \
  --env HELM_DROP_REPO=${HELM_REPO_DRP} \
  --env HELM_RELEASED_REPO=${HELM_REPO_REL} \
  --env ALLOW_DOWNGRADE="false" \
  --env IGNORE_NON_RELEASED="false" \
  --env AUTOMATIC_RELEASE="true" \
  --env ALWAYS_RELEASE="false" \
  --env SKIP_COND \
  --env SOURCE=${JENKINS_URL}/job/${JOB_NAME}/${BUILD_NUMBER} \
  --env GERRIT_TOPIC="inca" \
  --env UPLOAD_INTERNAL \
  --volume $WORKSPACE:$WORKSPACE \
  --volume $HELM_REPO_CREDENTIALS:/tmp/helm-repositories-file:ro \
  --workdir $WORKSPACE ${IMAGE} \
  ihc-auto $cmd