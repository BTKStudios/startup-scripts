#!/bin/bash

echo "Git monitor started. Monitoring every minute."

# Path to your local repository
REPO_DIR="${GITHUB_REPO_DIR}"

# Branch you want to monitor
BRANCH="${GITHUB_REPO_BRANCH}"

# Change to the repository directory
cd "$REPO_DIR" || { echo "Repository not found!"; exit 1; }

# Store the latest commit hash from the last check
LAST_COMMIT_FILE="/tmp/last_commit_hash"

LOG_DIR="/home/container/git-monitor"
mkdir -p "$LOG_DIR"

exec 3>&1 1>>"$LOG_DIR/log.txt" 2>&1

eval "$(ssh-agent -s)"
ssh-add /home/container/ssh/id-rsa

# Get the last commit hash from the repository
get_current_commit() {
    git rev-parse HEAD
}

# Load the last commit hash
LAST_COMMIT=$(git rev-parse HEAD)

while true; do
    # Fetch the latest changes for the specific branch
   git fetch origin "$BRANCH"

    # Get the latest commit hash on the specified branch
    CURRENT_COMMIT=$(git rev-parse origin/"$BRANCH")

    # Compare with the last known commit
    if [ "$CURRENT_COMMIT" != "$LAST_COMMIT" ]; then
        echo "Changes detected on branch '$BRANCH'! Performing action..."
        
        # Update the last commit hash
        echo "$CURRENT_COMMIT" > "$LAST_COMMIT_FILE"
		LAST_COMMIT=$(git rev-parse HEAD)

        # Pull changes for the specific branch
        git pull origin "$BRANCH"
        
    else
        echo "No changes detected on branch '$BRANCH'."
    fi

    # Sleep for a specified interval (e.g., 60 seconds)
    sleep 60
done