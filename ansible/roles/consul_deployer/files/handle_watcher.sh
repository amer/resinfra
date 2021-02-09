#!/bin/bash


# manuel trigger command on deployer console
# consul watch -type=checks -state=critical /resinfra/terraform/handle_watcher.sh

# change the execution dir
cd /resinfra/terraform/

# get the json object
consul_json="$(cat /dev/stdin)"

# exit when the called json object is empty. Yes this happens.
if [ "$consul_json" = "[]" ]; then
        exit
fi

echo "send slack with failing services"
/bin/bash /resinfra/terraform/sendslack.sh "$consul_json"

# get nodes with failing services
# only show unique nodes; select attribute Node
list_failing_nodes="$(jq '.. | unique_by(.Node)? | .[]? | .Node' <<< ${consul_json})"
echo "$list_failing_nodes"

# taint the failing nodes
## get the terraform ids
echo "get node information"
for node_name in $list_failing_nodes; do
        # remove the quotation marks
        node_name=$(echo "$node_name" | sed -e 's/^"//' -e 's/"$//')
        # Get the right element based on the node name
        var=$(jq '.. | .attributes? | select(.name == "'$node_name'") | .id' terraform.tfstate)
        # remove the quotation marks
        var=$(echo "$var" | sed -e 's/^"//' -e 's/"$//')
        # get the terraform path for this ressource so we can taint it
        terraform_ressource_uri=$(terraform state list -id="$var")
        # echo $(terraform state list -id="$var")
        list_failed_terraform_ressources+=( $terraform_ressource_uri )
done

# taint all failing nodes
for failed_terraform_ressources in ${list_failed_terraform_ressources[*]}; do
        echo $(terraform taint $failed_terraform_ressources)
done

# execute the terraform / plan
terraform_output=$(terraform plan -target=module.hetzner 2>&1)

terraform_output_successfull=$(echo "$terraform_output" | grep 'Plan' | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$terraform_output_successfull" ]
then
        text="["$HOSTNAME"] This Event should have been covered by the automatic re-deployment agent but there was an error:\n \n"

        # the sed is used the remove color escape sequences
        payload="${text}\`\`\`"$(echo "$terraform_output" |  sed 's/\x1b\[[0-9;]*m//g')"\`\`\`"
else
        # send a message to the slack
        text="["$HOSTNAME"] This Event was covered by the automatic re-deployment agent. This was done:\n \n"

        # the sed is used the remove color escape sequences
        payload="${text}\`\`\`"${terraform_output_successfull}"\`\`\`"
fi


echo "$payload"

escaped_payload=$(echo "$payload" | sed 's/"/\\"/g')

postdata="{\"text\":\"${escaped_payload}\"}"

echo $(echo "$postdata" | less)

curl -X POST -H 'Content-type: application/json' --data "$postdata" https://hooks.slack.com/services/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