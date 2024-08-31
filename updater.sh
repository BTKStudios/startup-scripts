#!/bin/bash

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ $SCRIPT_PATH == /home/container/startup]; then
	echo -e "Script Directory is inside Git repo. Unsafe to update. Aborting..."
	exit 1
	
git config --global --add safe.directory /home/container/startup
cd /home/container/startup

# Get current commit hash
CURRENT_COMMIT=$(git rev-parse HEAD)

# Fetch and get latest commit hash
git fetch origin prod
LATEST_COMMIT=$(git rev-parse origin/"$BRANCH")

if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then
	echo -e "New version of startup scripts detected. Updating..."
	git merge origin/prod
fi