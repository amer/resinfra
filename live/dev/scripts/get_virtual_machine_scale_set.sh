#!/bin/bash
OUTPUT=$(az vmss list -g $1 -o json --query '[].name | [?contains(@,`public`)] | [0] ')
OUTPUT=${OUTPUT//[$'\t\r\n\"']}
jq -n --arg output $OUTPUT '{output:$output}'