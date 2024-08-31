#!/bin/bash

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ $SCRIPT_PATH == /home/container/startup ]; then
	echo -e "Script Directory is inside Git repo. Unsafe to update. Aborting..."
	exit 1
fi
	
git config --global --add safe.directory /home/container/startup
cd /home/container/startup

# Get current commit hash
CURRENT_COMMIT=$(git rev-parse HEAD)

# Fetch and get latest commit hash
git fetch origin prod > /dev/null 2>&1
LATEST_COMMIT=$(git rev-parse origin/prod)

if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then
	echo -e "Merging new changes to startup scripts."
	git pull
fi

echo -e "Running startup script."
bash /home/container/startup/start.sh