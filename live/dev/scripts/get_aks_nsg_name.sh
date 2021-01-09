#!/bin/bash
set -euo pipefail

function myFunction() {
	az network nsg list -g $1 -o json --query '[0].name' | grep -q "nsg"
	return $?
}

retry=0
maxRetries=30
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

OUTPUT=$(az network nsg list -g $1 -o json --query '[0].name')
OUTPUT=${OUTPUT//[$'\t\r\n\"']}
jq -n --arg output $OUTPUT '{output:$output}'