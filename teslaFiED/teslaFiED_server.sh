#!/bin/bash
#self_name=$(basename $0)
 # count=$(pgrep -f -c $self_name)
  #[ $count -ne 1 ] \
   # && {
    #      exit 1
     # }
  pause_state=0 # 1 pause 0 resume
  debug=0
#--------------------------------------
<< _x_
# TeslaFiED - Linux systemd service
  ## Server
  - Receives commands and execute them using TeslaFi's API
  - Takes care of TeslaFi request rate limits
  - Saves responses to files
  ## Updater
  - Updates Homebridge devcie states
  - (Not Implemented) Checks for server errors

# Files
  - teslaFiED_server.sh
  - teslaFiED_updater.sh
  ## Run as a service (optional)
  - teslaFiED_server.service
  - teslaFiED_updater.service

# Location
  - Keep server and updater files in the same directory
  - To use as a service the default location is /home/pi/teslaFiED

# Requires
  - Raspberry Pi Homebridge SD card image
  - Homebridge HTTP Webhooks plugin

_x_
#--------------------------------------
# Regular Colors
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
PURPLE='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White
NO_COLOR='\033[0m'
# High Intensty
IBLACK='\033[0;90m'       # Black
IRED='\033[0;91m'         # Red
IGREEN='\033[0;92m'       # Green
IYELLOW='\033[0;93m'      # Yellow
IBLUE='\033[0;94m'        # Blue
IPURPLE='\033[0;95m'      # Purple
ICYAN='\033[0;96m'        # Cyan
IWHITE='\033[0;97m'       # White

# Variables
## TeslaFiED Updater
  teslafied_updater='/home/pi/teslaFiED/teslaFiED_updater.sh'

## TeslaFiED Server (this script)
  self=$(basename $0)
  command_reply=$($teslafied_updater --server-reply)
  output_directory=$($teslafied_updater --output-path)
  port=$($teslafied_updater --port)
  cmd_limit_window=$($teslafied_updater --request-limit-window)
  cmd_limit_num=$($teslafied_updater --request-limit-number)
  activity_touch_file=$($teslafied_updater --touch-file)
  log_error="$teslafied_updater --log-error"
  log_message="$teslafied_updater --log-message"
#      [ $debug -gt 0 ] && log_error='echo -e'
#      [ $debug -gt 0 ] && log_message='echo -e'
  teslafi_response_ext=$($teslafied_updater --response-extension)
  self_error_file=$($teslafied_updater --error-file)
  reboot_command=$($teslafied_updater --reboot-command)
  exit_command=$($teslafied_updater --exit-command)
  shutdown_command=$($teslafied_updater --shutdown-command)
  pause_command=$($teslafied_updater --pause-command)
  resume_command=$($teslafied_updater --resume-command)

## TeslaFi
        teslafi_url_with_key=$($teslafied_updater --teslafi-url-with-key)

# Receive command
wait_for_a_command () {
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: waiting"
        received=$( echo -e "$command_reply" | nc -l $port 2>>$self_error_file )
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: received ${GREEN}~$received~${NO_COLOR}"
}

parse_command () {
  command=$(echo -e "$received" | head -1 | cut -d ' ' -f2 | cut -c 2-)
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: parsed command ${IGREEN}~$command~${NO_COLOR}"
  [ "$command" = '' ] \
    && {
          $log_error "${YELLOW}[$self]${NO_COLOR} ${LINENO}: No command in ~$received~"
          return 1
    }
  return 0
}

# Handle command
## Don't send command to TeslaFi
server_command () {

  case ${command//%20/ } in
    $exit_command)
      $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: Received ${YELLOW}${command//%20/ }${NO_COLOR}. Exiting the server."
      ${command//%20/ }
      exit 0
      ;;
    $reboot_command)
      $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: Received ${YELLOW}${command//%20/ }${NO_COLOR}. Rebooting the server."
      ${command//%20/ }
      exit 0
      ;;
    $shutdown_command)
      $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: Received ${YELLOW}${command//%20/ }${NO_COLOR}. Shutting down the server."
      ${command//%20/ }
      exit 0
      ;;
    $pause_command)
      $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: Received ${YELLOW}${command//%20/ }${NO_COLOR}. Paused sending TeslaFi commands."
      pause_state=1
      return 0
      ;;
    $resume_command)
      $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: Received ${YELLOW}${command//%20/ }${NO_COLOR}. Resumed sending TeslaFi commands."
      pause_state=0
      return 0
      ;;
  esac
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: ${YELLOW}NOT a server command${NO_COLOR} ~$command~"
  return 1

}

not_paused () {
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: ${CYAN}pause_state ~$pause_state~${NO_COLOR}"
  return $pause_state
}

## Send command to TeslaFi
teslafi_command () {
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: ${IPURPLE}teslafi command${NO_COLOR} ~$command~"
  calulate_delay
  send_after_delay & # Prevents blocking the script from continuing
}

send_after_delay () {
  teslafi_response_file=$output_directory/$(cut -d '&' -f1 <<< $command)$teslafi_response_ext
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}:$(date) ${ICYAN}teslafi_response_file ~$teslafi_response_file~${NO_COLOR}"

  $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: ${YELLOW}Sending: \"$command\" Delay: $delay seconds${NO_COLOR}"
  sleep $delay
  time1=$(date +%s)
  curl --no-progress-meter --output $teslafi_response_file --url "$teslafi_url_with_key=$command" 2>>$self_error_file
  touch $activity_touch_file $teslafi_response_file # Activity tracker
  let time2=$(date +%s)-time1
  $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: ${YELLOW}Completed: \"$command\" Response: $time seconds${NO_COLOR}"

      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}:${ICYAN}$(ls -l $teslafi_response_file)${NO_COLOR}"
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}:$(date) ${ICYAN}~$delay~ seconds${NO_COLOR}"
      [ $debug -gt 0 ] && $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}:\"$teslafi_url_with_key=$command\"${NO_COLOR}"
}

calulate_delay () {
  # This could be rewritten with a for loop to support different limit heuristics
        [ "$first_request_time" = "" ] && { first_request_time=$SECONDS; delay=0; return 0; }
        [ "$second_request_time" = "" ] && { second_request_time=$SECONDS; return 0; }
        [ "$third_request_time" = "" ] && { third_request_time=$SECONDS; return 0; }
        fourth_request_time=$SECONDS

        let interval=fourth_request_time-first_request_time
        [ $interval -lt $cmd_limit_window ] \
                && let delay=cmd_limit_window-interval \
                || delay=0

        let new_fourth_request_time=fourth_request_time+delay

        first_request_time=$second_request_time
        second_request_time=$third_request_time
        third_request_time=$new_fourth_request_time

        return 0
}

# -------------------------------------

########
# Main #
########

$log_message "${YELLOW}[$self] Checking if port $port is available.${NO_COLOR}"
count=$(pgrep -c -f $port)
[ "$count" -gt 0 ] \
        && {
                        $log_error "${IYELLOW}$self: $port already in use. Quitting.\n\tIf teslaFiED is not working please restart the computer.${NO_COLOR}"
                        exit 1
                }

line="${YELLOW}[$self]${NO_COLOR}: ${IYELLOW}Starting server on port $port.${NO_COLOR}"
line="$line\n\tWebhook urls http://localhost:$port/<teslaFi API command>"
line="$line\n\thttp://localhost:$port/$exit_command - Close the bridge app."
line="$line\n\thttp://localhost:$port/$shutdown_command - Power off the bridge's computer."
line="$line\n\thttp://localhost:$port/$reboot_command - Restart the bridge's computer."
line="$line\n\thttp://localhost:$port/$pause_command - Pause the bridge sending commands to TeslaFi."
line="$line\n\thttp://localhost:$port/$resume_command - Resume the bridge sending commands to TeslaFi"
$log_message "$line"

while true;
do
        wait_for_a_command
  parse_command \
    && { # if parsed okay
          # Server or TeslaFi command
          server_command \
          || { # not a server command so a TeslaFi command
                # if not paused send TeslaFi command
                not_paused \
                && teslafi_command
            }
      }
      [ $debug -gt 1 ] && { $log_message "${YELLOW}[$self]${NO_COLOR} ${LINENO}: All variables"; ( set -o posix ; set ) ; }
done

exit 1
