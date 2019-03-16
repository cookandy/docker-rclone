#!/usr/bin/with-contenv sh

(
  flock -n 200 || exit 1

  sync_command="rclone sync /data $SYNC_DESTINATION:/'$SYNC_DESTINATION_SUBPATH'"

  sendPushover() {
    if [[ "$PUSHOVER_ENABLED" == "true" ]]; then
      curl -s \
	    -F "token=$PUSHOVER_APP_TOKEN" \
	    -F "user=$PUSHOVER_USER_TOKEN" \
	    -F "sound=$PUSHOVER_SOUND" \
	    -F "priority=1" \
	    -F "title=$1" \
	    -F "message=$2" \
	    http://api.pushover.net/1/messages > /dev/null
    fi
  }

  
  if [ "$SYNC_COMMAND" ]; then
    sync_command="$SYNC_COMMAND"
  else
    if [ -z "$SYNC_DESTINATION" ]; then
      echo "Error: SYNC_DESTINATION environment variable was not passed to the container."
      exit 1
    fi
  fi
  
  sendPushover "Starting sync of $DOCKER_NAME" "Running $(eval echo $sync_command)..." 
  
  echo "Executing => $sync_command"
  eval "$sync_command"
  
  if [ $? -eq 0 ]; then
    echo "success"
    sendPushover "Successfully synced $DOCKER_NAME!" "Success!"
  else
    echo "fail"
    sendPushover "Could not sync $DOCKER_NAME!" "Failed. :("
  fi
) 200>/var/lock/rclone.lock
