# Overview
This repository has a copy of public issues from the [Eucalyptus JIRA](https://eucalyptus.atlassian.net/)

You can browse these issues using the static [generated site](https:///eucalyptus.github.io/eucalyptus-jira/) or use the raw [json export](tree/master/export/euca) data.
  
# Repository
This section covers how this repository content was created.

## Exporting
To export JIRA issues use the export.sh script from [confluence-to-github](https://github.com/sjones4/confluence-to-github/tree/master/jira). This will create the raw export content that is found under [export](tree/master/export)

## Generation
To generate pages for each exported project, run generate.sh. Generation creates all the content under [generated](tree/master/generated)

## Templates
Static content used by the generated site is under [template](tree/master/template)


