#!/usr/bin/with-contenv sh

(
  flock -n 200 || exit 1

  sync_command="rclone sync /data $SYNC_DESTINATION:/'$SYNC_DESTINATION_SUBPATH'"

  sendPushover() {
    curl -s \
	  -F "token=$PUSHOVER_APP_TOKEN" \
	  -F "user=$PUSHOVER_USER_TOKEN" \
	  -F "sound=$PUSHOVER_SOUND" \
	  -F "priority=1" \
	  -F "title=$1" \
	  -F "message=$2" \
	  http://api.pushover.net/1/messages > /dev/null
  }

  
  if [ "$SYNC_COMMAND" ]; then
    sync_command="$SYNC_COMMAND"
  else
    if [ -z "$SYNC_DESTINATION" ]; then
      echo "Error: SYNC_DESTINATION environment variable was not passed to the container."
      exit 1
    fi
  fi
  
  # send pushover if enabled
  if [[ "$PUSHOVER_ENABLED" == "true" ]]; then
    sendPushover "Starting backup of $RCLONE_DOCKER_NAME" "running $sync_command..."
  fi  
  
  echo "Executing => $sync_command"
  eval "$sync_command"
  
  # send pushover if enabled
  if [[ "$PUSHOVER_ENABLED" == "true" ]]; then
    if [ $? -eq 0 ]; then
      sendPushover "Successfully backed up $RCLONE_DOCKER_NAME" "Successfully backed up $RCLONE_DOCKER_NAME."
    else
      sendPushover "Could not back up $RCLONE_DOCKER_NAME" "Could not back up $RCLONE_DOCKER_NAME."
    fi
  fi
) 200>/var/lock/rclone.lock
