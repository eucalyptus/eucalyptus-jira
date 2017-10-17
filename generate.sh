#!/bin/bash
########################################################################
# Generate pages / index for viewing issues exported from JIRA
########################################################################

for PROJECT_PATH in export/*; do
  PROJECT="${PROJECT_PATH##*/}"

  echo "Generating issue pages for ${PROJECT}"
  mkdir -pv "generated/${PROJECT}"

  for ISSUE_PATH in export/${PROJECT}/issues/*-*.json; do
    ISSUE="${ISSUE_PATH##*/}"
    cp -p template/issue-template.html "generated/${PROJECT}/${ISSUE%%.json}.html"
  done

  echo "Generating issue listing for ${PROJECT}"
  echo "{ \"issues\": [" > "generated/${PROJECT}/issues.json"
  ISSUE_FIRST="yes"
  for ISSUE_PATH in $(ls export/${PROJECT}/issues/*-*.json | sort -V); do
    ISSUE="${ISSUE_PATH##*/}"
    if [ "${ISSUE_FIRST}" == "no" ] ; then
      echo -n "," >> "generated/${PROJECT}/issues.json"
    fi
    echo "\"${ISSUE%%.json}\"" >> "generated/${PROJECT}/issues.json"
    ISSUE_FIRST="no"
  done  
  echo " ] }" >> "generated/${PROJECT}/issues.json"

  echo "Generating issue index for ${PROJECT}"
  INDEX_FILE="generated/${PROJECT}/index.json"
  echo "[{" > "${INDEX_FILE}"
  FIRST_ISSUE="yes"
  for ISSUE_PATH in $(ls export/${PROJECT}/issues/*-*.json | sort -Vr); do
    ISSUE="${ISSUE_PATH##*/}"
    if [ $FIRST_ISSUE != "yes" ]; then
      echo ",{" >> "${INDEX_FILE}"
    fi
    grep -oP '"components":\[.*?\]|"fixVersions":\[.*?\]|"issuetype":\{.*?}|"priority":\{.*?}|"resolution":\{.*?}|"status":\{.*?"statusCategory":{.*?}}|"summary":".*?(?<!\\)"|"versions":\[.*?\]|"issuelinks":\[.*?\]|"subtasks":\[.*?\]' $ISSUE_PATH | grep -v issuelinks | grep -v subtasks | awk '{print $0 ","}' >> "${INDEX_FILE}"
    echo -n '"key":"' >> "${INDEX_FILE}"
    echo -n "${ISSUE%%.json}" >> "${INDEX_FILE}"
    echo '"' >> "${INDEX_FILE}"
    echo -n "}" >> "${INDEX_FILE}"
    FIRST_ISSUE="no"
  done
  echo "]" >> "${INDEX_FILE}"

  echo "Copying templates for ${PROJECT}"
  cp -v template/issue.html "generated/${PROJECT}/"
  cp -v template/issue-side.html "generated/${PROJECT}/"

done

echo "Generating search facets"
FACETS_FILE="$(pwd)/generated/facets.json"
echo "{" > "${FACETS_FILE}"
echo '"components":[' >> "${FACETS_FILE}"
grep -hoP '{.*?"self":"https://eucalyptus.atlassian.net/rest/api/2/component/.*?".*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"versions":[' >> "${FACETS_FILE}"
grep -hoP '{.*?"self":"https://eucalyptus.atlassian.net/rest/api/2/version/.*?".*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"issuetypes":[' >> "${FACETS_FILE}"
grep -hoP '{.*?"self":"https://eucalyptus.atlassian.net/rest/api/2/issuetype/.*?".*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"priorities":[' >> "${FACETS_FILE}"
grep -hoP '{.*?"self":"https://eucalyptus.atlassian.net/rest/api/2/priority/.*?".*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"projects":[' >> "${FACETS_FILE}"
grep -hoP '{"self":"https://eucalyptus.atlassian.net/rest/api/2/project/.*?".*?"avatarUrls":{.*?}.*?}' export/*/issues/*-???.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"resolutions":[' >> "${FACETS_FILE}"
grep -hoP '{"self":"https://eucalyptus.atlassian.net/rest/api/2/resolution/.*?".*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo '],"statuses":[' >> "${FACETS_FILE}"
grep -hoP '{.*?"self":"https://eucalyptus.atlassian.net/rest/api/2/status/.*?".*?"statusCategory":{.*?}.*?}' generated/*/index.json | sort -uV | awk '{print $0 ","}' | head -c -2 >> "${FACETS_FILE}"
echo ']' >> "${FACETS_FILE}"
echo "}" >> "${FACETS_FILE}"


for PROJECT_PATH in export/*; do
  PROJECT="${PROJECT_PATH##*/}"

  echo "Shrinking index for ${PROJECT}"
  INDEX_FILE="generated/${PROJECT}/index.json"
  json_reformat < "${INDEX_FILE}" | grep -v '"self":' | grep -v '"iconUrl":' | grep -vP '"description": ".*?",$' | json_reformat -m > "${INDEX_FILE}.shrunk"
  mv -fv "${INDEX_FILE}.shrunk" "${INDEX_FILE}"
done
