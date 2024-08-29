#!/bin/bash

REPO_DIR="${GITHUB_REPO_DIR}"
JVM_RAM="${SERVER_RAM}"

cd /home/container

if [ ! -d "$REPO_DIR" ]; then
	echo -e "Git Directory does not exist. Cloning git repo..."
	mkdir -p "$REPO_DIR"
	ssh-agent bash -c "ssh-add /home/container/ssh/id-rsa; git clone -b ${GITHUB_REPO_BRANCH} --single-branch ${GITHUB_REPO_SSH} $REPO_DIR"
fi

# Start git-monitor execution
sh git-monitor.sh &
GIT_MONITOR_PID=$!

java -Xmx$JVM_RAM -Xms$JVM_RAM -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui

echo "Minecraft server exited. Killing git monitor.."
# Kill git-monitor.sh when the Minecraft server exits
kill $GIT_MONITOR_PID

# Wait for git-monitor.sh to clean up/terminate before terminating main script
wait $GIT_MONITOR_PID