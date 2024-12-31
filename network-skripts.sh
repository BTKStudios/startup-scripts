#!/bin/bash

echo "NS Git monitor started. Monitoring every minute."

# Path to your local repository
REPO_DIR="/home/container/plugins/Skript/scripts/network/"

# Branch you want to monitor
BRANCH="main"

cd /home/container
# Change to the repository directory
cd "$REPO_DIR" || { echo "Repository not found!"; exit 1; }

# Store the latest commit hash from the last check
LAST_COMMIT_FILE="/tmp/last_commit_hash"

LOG_DIR="/home/container/git-monitor"
mkdir -p "$LOG_DIR"

eval "$(ssh-agent -s)" > "$LOG_DIR/log.txt"
ssh-add /home/container/ssh/id-rsa >> "$LOG_DIR/network-skripts-log.txt" 2>&1

# Get the last commit hash from the repository
get_current_commit() {
    git rev-parse HEAD
}

# Load the last commit hash
LAST_COMMIT=$(git rev-parse HEAD)

while true; do
    # Fetch the latest changes for the specific branch
   git fetch origin "$BRANCH" >> "$LOG_DIR/log.txt" 2>&1

    # Get the latest commit hash on the specified branch
    CURRENT_COMMIT=$(git rev-parse origin/"$BRANCH")

    # Compare with the last known commit
    if [ "$CURRENT_COMMIT" != "$LAST_COMMIT" ]; then
        echo "Changes detected on branch '$BRANCH'! Performing action..." >> "$LOG_DIR/log.txt" 2>&1
        
        # Update the last commit hash
        echo "$CURRENT_COMMIT" > "$LAST_COMMIT_FILE"
		LAST_COMMIT=$(git rev-parse HEAD)

        # Pull changes for the specific branch
        git pull origin "$BRANCH" >> "$LOG_DIR/log.txt" 2>&1
        
    else
        echo "No changes detected on branch '$BRANCH'." >> "$LOG_DIR/log.txt" 2>&1
    fi

    # Sleep for a specified interval (e.g., 60 seconds)
    sleep 60
done