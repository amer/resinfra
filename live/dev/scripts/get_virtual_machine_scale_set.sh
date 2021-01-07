#!/bin/bash
set -euo pipefail

function myFunction() {
	az vmss list -g $1 -o json --query '[].name | [?contains(@,`public`)] | [0] ' | grep -q "public"
	return $?
}

retry=0
maxRetries=15
retryInterval=15
until [ ${retry} -ge ${maxRetries} ]
do
	myFunction $1 && break
	retry=$[${retry}+1]
	echo "Retrying [${retry}/${maxRetries}] in ${retryInterval}(s) "
	sleep ${retryInterval}
done

if [ ${retry} -ge ${maxRetries} ]; then
  echo "Failed after ${maxRetries} attempts!"
  exit 1
fi



OUTPUT=$(az vmss list -g $1 -o json --query '[].name | [?contains(@,`public`)] | [0] ')
OUTPUT=${OUTPUT//[$'\t\r\n\"']}
jq -n --arg output $OUTPUT '{output:$output}'