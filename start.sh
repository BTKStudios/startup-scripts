#!/bin/bash

REPO_DIR="${GITHUB_REPO_DIR}"
JVM_RAM="${SERVER_RAM}"

[ -d /home/container/tmpstartup/ ] && rm -r /home/container/tmpstartup/

if [ -e /home/container/startup/updater.sh ]; then	
	cd /home/container/startup

	# Get current commit hash
	CURRENT_COMMIT=$(git rev-parse HEAD)

	# Fetch and get latest commit hash
	git fetch origin prod > /dev/null 2>&1
	LATEST_COMMIT=$(git rev-parse origin/prod)

	if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then
		echo -e "New update available. Running updater..."
		mkdir -p /home/container/tmpstartup/ && cp /home/container/startup/updater.sh /home/container/tmpstartup/updater.sh
		bash /home/container/tmpstartup/updater.sh
		exit 0
	fi
fi
	
cd /home/container
	

if [ -n "${GITHUB_REPO_SSH}" ]; then
	if [ ! -d "$REPO_DIR" ]; then
		echo -e "Git Directory does not exist. Cloning git repo..."
		mkdir -p "$REPO_DIR"
		ssh-agent bash -c "ssh-add /home/container/ssh/id-rsa; git clone -b ${GITHUB_REPO_BRANCH} --single-branch ${GITHUB_REPO_SSH} $REPO_DIR"
	fi

	# Start git-monitor execution
	sh /home/container/startup/git-monitor.sh &
	GIT_MONITOR_PID=$!
else
	echo -e "No GitHub Repo was provided. Skipping git monitor..."
fi


(
	while true; do cat ; done
) | java -Xmx$JVM_RAM -Xms$JVM_RAM -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Djdk.console=java.base -jar server.jar nogui &
JAVA_PID=$!

wait $JAVA_PID
kill $!

echo -e "Minecraft server exited."

if [ -n "${GITHUB_REPO_SSH}" ]; then
	echo -e "Killing git monitor.."
	# Kill git-monitor.sh when the Minecraft server exits
	kill $GIT_MONITOR_PID

	# Wait for git-monitor.sh to clean up/terminate before terminating main script
	wait $GIT_MONITOR_PID
	exit 0
else
	exit 0
fi