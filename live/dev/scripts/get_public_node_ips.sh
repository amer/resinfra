#!/bin/bash
OUTPUT=$(az vmss list-instance-public-ips -g $1 -n $2 -o json --query '[].ipAddress')
OUTPUT=$(echo -e $OUTPUT | tr -d "[]\" \t\n\r") # Clean up the string split it into array later
jq -n --arg output "$OUTPUT" '{output:$output}'
