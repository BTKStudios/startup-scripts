#!/bin/bash

REPO_DIR="${GITHUB_REPO_DIR}"
JVM_RAM="${SERVER_RAM}"
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/home/container/.ssh/known_hosts"

exit_parent() {
	echo "Exiting script..."
	kill 0
	exit 0
}

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

if [ ! -d "/home/container/plugins/Skript/scripts/network/" ]; then
	echo -e "Network Skripts Git Directory does not exist. Cloning git repo..."
	mkdir -p "/home/container/plugins/Skript/scripts/network/"
	ssh-agent bash -c "ssh-add /home/container/ssh/id-rsa; git clone -b main --single-branch git@github.com:BTKStudios/network-skript.git /home/container/plugins/Skript/scripts/network/"
fi

# Start network skripts git-monitor execution.
sh /home/container/startup/network-skripts.sh &
NS_GIT_MONITOR_PID=$!

if [ -e pipe ]; then
	echo -e "Pipe already created. Deleting..."
	rm pipe
fi

mkfifo pipe

echo -e "Starting Minecraft Server..."
java -Xms$JVM_RAM -Xmx$JVM_RAM --add-modules=jdk.incubator.vector -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -Djdk.console=java.base -jar server.jar nogui < pipe &
SERVER_PID=$!

(
trap exit_parent EXIT
while [ -e /proc/$SERVER_PID ]; do sleep .6; done;
echo -e "Minecraft server exited."

if [ -n "${GITHUB_REPO_SSH}" ]; then
	echo -e "Killing git monitor.."
	# Kill git-monitor.sh when the Minecraft server exits
	kill $GIT_MONITOR_PID
	echo -e "Killing network skripts git monitor.."
	kill $NS_GIT_MONITOR_PID
	exit 0
else
	exit 0
fi
) &

while ps -p $SERVER_PID > /dev/null; do		
	cat > pipe
done