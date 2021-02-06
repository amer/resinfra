#!/bin/bash

CURRENT_BRANCH=`git symbolic-ref --short HEAD 2>/dev/null || echo ''`
jq -n --arg current_branch $CURRENT_BRANCH '{"current_branch":$current_branch}'