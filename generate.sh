#!/bin/bash
########################################################################
# Generate pages / index for viewing issues exported from JIRA
########################################################################

for PROJECT_PATH in export/*; do
  PROJECT="${PROJECT_PATH##*/}"

  echo "Generating issue pages for ${PROJECT}"
  mkdir -pv "generated/${PROJECT}"

  for ISSUE_PATH in export/${PROJECT}/issues/*.json; do
    ISSUE="${ISSUE_PATH##*/}"
    cp -p template/issue-template.html "generated/${PROJECT}/${ISSUE%%.json}.html"
  done

  echo "Generating issue listing for ${PROJECT}"
  echo "{ \"issues\": [" > "generated/${PROJECT}/issues.json"
  ISSUE_FIRST="yes"
  for ISSUE_PATH in $(ls export/${PROJECT}/issues/*.json | sort -V); do
    ISSUE="${ISSUE_PATH##*/}"
    if [ "${ISSUE_FIRST}" == "no" ] ; then
      echo -n "," >> "generated/${PROJECT}/issues.json"
    fi
    echo "\"${ISSUE%%.json}\"" >> "generated/${PROJECT}/issues.json"
    ISSUE_FIRST="no"
  done  
  echo " ] }" >> "generated/${PROJECT}/issues.json"

  echo "Copying templates for ${PROJECT}"
  cp -v template/issue.html "generated/${PROJECT}/"
  cp -v template/issue-side.html "generated/${PROJECT}/"

done

