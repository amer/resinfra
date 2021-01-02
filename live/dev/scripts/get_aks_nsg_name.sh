#!/bin/bash
OUTPUT=$(az network nsg list -g $1 -o json --query '[0].name')
jq -n --arg output $OUTPUT '{output:$output}'