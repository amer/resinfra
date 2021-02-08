#!/bin/sh

# get the json object
consul_json=$(cat /dev/stdin)

# parse the json and get the node name and service names of the critical services
parsed_json=$( echo "$consul_json" | tr '\r\n' ' ' |  jq '.[] |  {node: .Node, service: .ServiceName, service_state: .Status}' )

# some informational message for the mail body
message="This is a automatic alert message from a check handler triggered by a consul watcher\n"
message="${message}Below is a list of the services with critical health state:\n\n"

# TODO: replace exposed credentials
# this account is not used for anything and was only created for this use
#echo "${message}${parsed_json}" | s-nail -v \
# -r "alert@hanse-jobs.de" \
# -s "Consul Watcher detected services with critical health status!" \
# -S smtp="mail.your-server.de:587" \
# -S smtp-use-starttls \
# -S smtp-auth=login \
# -S smtp-auth-user="alert@hanse-jobs.de" \
# -S smtp-auth-password="52j8i24pPY45N3GJ" \
# -S ssl-verify=ignore \
# julian.legler@gmx.de
