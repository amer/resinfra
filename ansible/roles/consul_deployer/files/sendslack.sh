#!/bin/bash

# get the json object
consul_json="$1"

#echo $consul_json

# parse the json and get the node name and service names of the critical services
table_formatted_nodes=$(echo "$consul_json" | mlr --ijson --opprint --barred cut -f Node,ServiceName,Status then group-by Node)

# some informational message for the mail body
message="This is a automatic alert message from a check handler triggered by a consul watcher\n"
message="${message}Below is a list of the services with critical health state:\n\n"

payload="${message}\`\`\`${table_formatted_nodes}\`\`\`"

escaped_payload=$(echo "$payload" | sed 's/"/\\"/g')
postdata="{\"text\":\"$escaped_payload\"}"

#echo "$postdata"

curl -X POST -H 'Content-type: application/json' --data "$postdata" https://hooks.slack.com/services/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