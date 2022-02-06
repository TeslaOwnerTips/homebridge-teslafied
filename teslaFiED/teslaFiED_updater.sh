#!/bin/bash
#	self_name=$(basename $0)

 # count=$(pgrep -f -c $self_name)
  #[ $count -ne 1 ] \
   # && {
    #      exit 1
     # }
#--------------------------------------
<< _x_
# TeslaFiED _ Linux systemd service
 _ Updates all Homebridge Webhooks devcie states

# Requires
 _ Homebridge
 _ Homebridge HTTP Webhooks plugin
 _ jq, nc (Netcat)
 Note: These are usually present on Homebridge's RasPi image

# Location
_ /home/pi/teslaFiED/self_updater.sh

_x_
#--------------------------------------
[ "$1" = '--debug' ] && { [ "$2" != "" ] && [[ '1234567890' == **$2** ]] || { echo 'Error: Missing debug number'; exit 1; }; }
[ "$1" = '--debug' ] && { debug=$2 arg1="$3" arg2="$4"; } || { debug=0; arg1="$1"; arg2="$2"; }

# Variables
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

## TeslaFiED Updater (This script)
	RED='\033[0;31m'
	NO_COLOR='\033[0m'

	self_name=$(basename $0)
	self_output_directory='/home/pi/teslaFiED/updater_output'
    mkdir -p $self_output_directory

  update_loop_delay='2' # seconds
  declare -A update_interval
  update_interval[online]='120' # 120 = 2 minutes
  update_interval[asleep]='240' # 240 = 4 minutes
  minimum_idle_duration='30' # Wait for activity to stop before updating

## TeslaFiED Server
  server_port='11111'
	server_url="http://localhost:$server_port"
	server_success_reply='{"success":"true"}'
	server_header="HTTP/1.1 200 OK\nContent-Type: application/json\nContent-Length: ${#server_success_reply}"
	server_reply="$server_header\n\n$server_success_reply"

  server_exit_command='exit 0'
  server_shutdown_command='sudo shutdown now'
  server_reboot_command='sudo reboot'
  server_pause_command='pause'
  server_resume_command='resume'

	server_output_directory='/home/pi/teslaFiED/server_output'
    mkdir -p $server_output_directory
	activity_touch_file=$server_output_directory/activity_touch_file # for the activity window
  server_response_file_ext='.json'
	tesla_state_json_command='tesla_state'
	tesla_state_file=$server_output_directory/$tesla_state_json_command$server_response_file_ext
  tesla_asleep_state_file='asleep_state.json'

## TeslaFi
	teslafi_base_url='https://www.teslafi.com/feed.php'
	teslafi_request_limit_window='60'
	teslafi_request_limit_number='3'
  teslafi_online_value='online'

## Homebridge
	declare -A config
	homebridge_config_file='/var/lib/homebridge/config.json'
	homebridge_log_file='/var/lib/homebridge/homebridge.log'

## Webhook
	webhook_port_key='webhook_port'
	webhook_host_key='webhook_listen_host'
	webhook_user_key='http_auth_user'
	webhook_password_key='http_auth_pass'

	webhook_url_id_key='accessoryId'
	webhook_success_response_grep_value='"success":true'

	webhook_id_key='id'

### Webhook devices are either boolean or numeric data types
  #   Some devices have two keys to update
  #   Device IDs have a two character suffix indication the category and type
  #     E.g. WN - Window Numeric

	webhook_update_suffix_list='NBI' # numeric, boolean, inverted boolean

  declare -A webhook_device_type_suffix
	declare -A webhook_device_key
	declare -A webhook_device_2nd_key
	declare -A webhook_value_true
  declare -A webhook_value_false

	### Boolean xB or xI
	tesla_state_values_to_be_converted_to_true='online Home'

	webhook_device_key[BB]='state' # Switch, Contact
	webhook_device_key[IB]='state' # Inverted Boolean Switch, Contact
	webhook_device_key[LB]='state' # Contact (Location)
	webhook_device_key[OB]='state' # Outlet not using stateOutletInUse

  webhook_value_true[BB]='true'
  webhook_value_true[IB]='false'
  webhook_value_true[OB]='true'
  webhook_value_true[LB]='true'

  webhook_value_false[BB]='false'
  webhook_value_false[IB]='true'
  webhook_value_false[OB]='false'
  webhook_value_false[LB]='false'

	### Numeric xN
	webhook_device_key[NN]='value' # Sensor
	webhook_device_key[SN]='currentstate' # Security (Stay=0 / Away=1 / Night=2 / Disarmed=3 / Triggered=4)
	webhook_device_2nd_key[SN]='targetstate' # (unsecured=0 / secured=1)
	webhook_device_key[LN]='lockcurrentstate' # Lock (unsecured=0 / secured=1 / jammed=2 / unknown=3)
	webhook_device_2nd_key[LN]='locktargetstate' # (unsecured=0 / secured=1)
	webhook_device_key[WN]='currentposition' # Window (Tesla charge port door)
	webhook_device_2nd_key[WN]='targetposition' # Percentage

  ### Thermostat
    # currenttemperature, targettemperature
    # currentstate (Off=0 / Heating=1 / Cooling=2)
    # targetstate  (Off=0 / Heat=1 / Cool=2 / Auto=3)

  ### Errors
	webhook_error_device_id='error-IB-'
	webhook_error_device_type='IB'
  errors=0

  ### Pause
  webhook_pause_device_id='pause-BB-'
  webhook_pause_device_type='BB'

  ### State
  webhook_state_device_id='stateBB'
  webhook_state_device_type='BB'
#--------------------------------------
# FUNCTIONS

## Check files exist
check_asleep_config_log_files_exist () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_asleep_config_log_files_exist \(\)

	log_error_text=''

  test -f $tesla_asleep_state_file \
	  || log_error_text+="Line ${LINENO}: Error: Missing tesla_asleep_state_file $tesla_asleep_state_file"
	test -f $homebridge_config_file \
	  || log_error_text+="\nLine ${LINENO}: Error: Missing homebridge_config_file $homebridge_config_file"
	test -f $homebridge_log_file \
	  && text='' \
		|| text="$log_error_text\nLine ${LINENO}: Error: Missing homebridge_log_file $homebridge_log_file"


  # Log file missing. Other errors may or may not exist but are included.
	[ "$text" != '' ] \
		&& {
 					echo -e "$0 ${LINENO}: $timestamp ${RED}Line ${LINENO}: - $text${NO_COLOR}"
 					return 1
 			}

  # There are errors and the log file is okay.
	[ "$log_error_text" != '' ] \
  	&& {
					log_errors
					return 1
			}

      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_asleep_config_log_files_exist \(DONE\)
	return 0
}

## Error Device State
set_error_device () {
  [ $errors -gt 0 ] \
    && value=${webhook_value_true[$webhook_error_device_type]} \
    || value=${webhook_value_false[$webhook_error_device_type]}

  [ $value != "$previous_error_state" ] \
    && {
          previous_error_state=$value

          id=$webhook_error_device_id
          device_type=$webhook_error_device_type
          curl_webhook
      }
  errors=0
}

## Homebridge Log Entry
log_message () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: log_message \(\)
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: $timestamp $log_message_text
	echo -e "$timestamp\n\t$log_message_text" >> $homebridge_log_file
	log_message_text=''
}

log_error () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: log_error \(\)
      [ $debug -gt 2 ] && echo -e $0 ${LINENO}: ~$log_error_text~ \
		    && exit 1

  let errors+=1
	log_message_text="${RED}$log_error_text${NO_COLOR}"
	log_message
	log_error_text=''
}

## Update Timestamp
update_timestamp () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: update_timestamp \(\)

	now=$(date +%s)
	timestamp=[$(date "+%d/%m/%Y, %T" --date="@$now")]${YELLOW}[$self_name]${NO_COLOR}
    [ $debug -gt 2 ] && echo -e "\t\t"$0 ${LINENO}: timestamp ~$timestamp~

      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: update_timestamp \(DONE\)
	return 0
}

## Curl With Error Handling
curl_webhook () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IYELLOW}curl_webhook \(\)${NO_COLOR}

	[ "$webhook_user_password" = '' ] \
 		&& {
 		      log_error_text="Line ${LINENO}: webhook_user_password missing"
          log_error

          return 1
      }

	[ "$value" = '' ] \
 		&& {
 		          [ $debug -gt 1 ] && echo -e $0 ${LINENO}: ${IYELLOW}No value. Skipping curl.${NO_COLOR}
 		          [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IYELLOW}curl_webhook \(DONE\)${NO_COLOR}
          return 1
      }

  value_key=${webhook_device_key[$device_type]}
 	curl_webhook_url="$webhook_url_with_id_key=$id&$value_key=$value"
    # Add the second key if available
		[ "${webhook_device_2nd_key[$device_type]}" != '' ] \
			&& curl_webhook_url+="&${webhook_device_2nd_key[$device_type]}=$value"
        [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: curl_webhook_url ${IYELLOW}$curl_webhook_url${NO_COLOR}

	response=$(curl --no-progress-meter -s --user "$webhook_user_password" "$curl_webhook_url" 2>>$homebridge_log_file)
      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${IYELLOW}curl --no-progress-meter -s --user \"$webhook_user_password\" \"$curl_webhook_url\"${NO_COLOR}

	[ "$response" = "" ] \
		&& {
					log_error_text="Line ${LINENO}: No response from Webhooks"
					log_error_text+="\n\tcurl -s --user \"$webhook_user_password\" \"$curl_webhook_url\""
					log_error
					return 1
			}

	[ $(grep -c $webhook_success_response_grep_value <<< $response) = '1' ] \
		&& return 0

	log_error_text="Line ${LINENO}: Error: curl -s --user usr:pswd "
	log_error_text+=$curl_webhook_url
	log_error_text+="Response: $response"
	log_error
	return 1
}

curl_server () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${YELLOW}curl_server \(\)${NO_COLOR}
 		  [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${YELLOW}curl --no-progress-meter "\"$server_url/$curl_server_url\""${NO_COLOR}

  curl_output=$(curl -s --no-progress-meter "$server_url/$curl_server_url" 2>&1)
      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${YELLOW}curl_output ~$curl_output~${NO_COLOR}

  # If there is an error it is probably because the local server is not running.
  [ $(grep -c $server_success_reply <<< $curl_output) -lt 1 ] \
    && {
          log_error_text="Line ${LINENO}: $curl_output"
          log_error_text+="\n\t$server_url/$curl_server_url"
          log_error_text+="\n\tThe local TeslaFiED server is probably not running."
          log_error
 		      return 1
      }

  return 0
}

## Update Webhook Variables
read_config_json_file () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: read_config_json_file \(\)

	config_file_time=$(date -r $homebridge_config_file +%s 2>>$homebridge_log_file)
  # Don't read the config if it has not changed
	[ $config_file_time = "$config_previous_file_time" ] \
		&& return 0

	# Do the rest only if the file time has changed

	config_previous_file_time=$config_file_time

	# All homebridge key value pairs
	config_key_value_pairs=$(grep -o "\".*:.*\"" < $homebridge_config_file 2>>$homebridge_log_file)
	[ "$config_key_value_pairs" = "" ] \
	  && log_error_text="Line ${LINENO}: config_key_value_pairs is empty."

  # Update Script Variables
  for var in 'update_loop_delay' 'update_interval[online]' 'update_interval[asleep]' 'minimum_idle_duration'
  do
    update_var
  done
    log_message_text="${LINENO}: update_loop_delay ~$update_loop_delay~ minimum_idle_duration ~$minimum_idle_duration~"
    log_message_text+="\n\t${LINENO}: update_interval[online] ~${update_interval[online]}~ update_interval[asleep] ~${update_interval[asleep]}~"
    log_message
	# Webhooks
	## URL
	webhook_host_value=$(grep -o "\"$webhook_host_key.*:.*\"" <<< $config_key_value_pairs \
		| cut -d '"' -f4 2>>$homebridge_log_file)
	[ "$webhook_host_value" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_host_value is empty."
	webhook_port_value=$(grep -o "\"$webhook_port_key.*:.*\"" <<< $config_key_value_pairs \
		| cut -d '"' -f4 2>>$homebridge_log_file)
	[ "$webhook_port_value" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_port_value is empty."

	webhook_base_url="http://$webhook_host_value:$webhook_port_value"
	webhook_url_with_id_key="$webhook_base_url/?$webhook_url_id_key"

	## Authorization
	webhook_user_value=$(grep -o "\"$webhook_user_key.*:.*\"" <<< $config_key_value_pairs \
		| cut -d '"' -f4 2>>$homebridge_log_file)
	[ "$webhook_user_value" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_user_value is empty."
	webhook_password_value=$(grep -o "\"$webhook_password_key.*:.*\"" <<< $config_key_value_pairs \
 		| cut -d '"' -f4 2>>$homebridge_log_file)
	[ "$webhook_password_value" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_password_value is empty."
	webhook_user_password="$webhook_user_value:$webhook_password_value"
	[ "$webhook_user_password" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_user_password is empty."

  ## Device IDs to update
 	webhook_ids_to_update=$( grep -o \"$webhook_id_key\".*[$webhook_update_suffix_list]\" <<< $config_key_value_pairs \
 		| cut -d '"' -f 4 2>>$homebridge_log_file)
	[ "$webhook_ids_to_update" = "" ] \
	  && log_error_text+="\nLine ${LINENO}: webhook_ids_to_update is empty."

  ## Tokens
 	pushover_token=$webhook_user_value
	teslafi_token=$webhook_password_value

      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: read_config_json_file \(DONE\)
	[ "$log_error_text" = "" ]  \
	  && return 0
	log_error
	return 1
}

update_var () {
  pattern=$var
  escape=$(grep -o '\[' <<< $pattern)
  pattern=${pattern/$escape/\\$escape}
  escape=$(grep -o '\]' <<< $pattern)
  pattern=${pattern/$escape/\\$escape}
  new_value=$(grep -o "\"$pattern.*:.*\"" <<< $config_key_value_pairs \
    | cut -d '"' -f4 2>>$homebridge_log_file)
  [ "$new_value" != '' ] \
    || return 1
  #let var_old_value=var
  let $var=new_value
  #let var_value=var
  new_value=''
  return 0
}

## Update Tesla State JSON
update_tesla_state_json () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${CYAN}update_tesla_state_json \(\)${NO_COLOR}

	update_tesla_state_file \
		&& {
		      tesla_state_json=$(< $tesla_state_file)
		      tesla_is_online \
		        || tesla_state_json=$(< $tesla_asleep_state_file)
          tesla_state_json=${tesla_state_json//null/\"\"}
              [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${CYAN}tesla_state_json ${IGREEN}"\t\t"UPDATED${NO_COLOR}
              [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${CYAN}update_tesla_state_json \(DONE\)${NO_COLOR}
		      return 0
		  }

      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${CYAN}tesla_state_json ${IGREEN}"\t\t"NOT updated${NO_COLOR}
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${CYAN}update_tesla_state_json \(DONE\)${NO_COLOR}
  return 1
}

update_tesla_state_file () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${ICYAN}update_tesla_state_file \(\)${NO_COLOR}

  # Do not updated if conditions not met
 	update_state_files_conditions_met \
 		|| return 1

  # Update file/ Get a new file
 	    [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${ICYAN}Updating $tesla_state_file${NO_COLOR}

  # Requesting new state file from local server
  resume_commands_to_teslafi
sleep 1
  curl_server_url=$tesla_state_json_command
  curl_server

  # Wait for the file
      [ $debug -gt 1 ] && echo -e "\t\t"$0 ${LINENO} ${ICYAN}Waiting for the new status file ~$tesla_state_file~${NO_COLOR}
  for x in {1..120}
  do
        [ $debug -gt 1 ] && echo -n -e ${ICYAN}"\t\t~$x~\r"${NO_COLOR}
    sleep 1
    test -s $tesla_state_file \
      && {
            [ $debug -gt 1 ] && echo -n -e ${ICYAN}"\t\t~$x~\n"${NO_COLOR}
            touch $tesla_state_file $activity_touch_file # Sync both files times to detect activity later
                [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${ICYAN}update_tesla_state_file \(DONE\)${NO_COLOR}
            return 0 # file updated
        }
  done

  # No file
  log_error_text="Line ${LINENO}: State file needed updating but was not."
  log_error_text+="\n\tTimed out waiting for a response to the request."
  log_error
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: update_tesla_state_file \(DONE\)
  return 1
}

update_state_files_conditions_met () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IPURPLE}update_state_files_conditions_met \(\)${NO_COLOR}

  # Update if state unknown (just started)
  [ "$state" = '' ] \
    && return 0

  # Update if state or activity file has a problem
 	test -s $tesla_state_file \
 	  || return 0
        [ $debug -gt 0 ] && echo -e "\t"$0 ${LINENO}: ${IPURPLE}$tesla_state_file okay${NO_COLOR}
 	test -f $activity_touch_file \
 	  || return 0
        [ $debug -gt 0 ] && echo -e "\t"$0 ${LINENO}: ${IPURPLE}$activity_touch_file okay${NO_COLOR}

  # File times are used to check for activity, idle duration and update interval
	tesla_state_file_time=$(date -r $tesla_state_file +%s)
  activity_touch_file_time=$(date -r $activity_touch_file +%s)

  # Idle duration
  let idle_duration=now-activity_touch_file_time

  # Do not update files until idle long enough
  [ $idle_duration -lt $minimum_idle_duration ] \
    && return 1
        [ $debug -gt 0 ] && echo -e "\t"$0 ${LINENO}: ${IPURPLE}Idle ~$idle_duration~ longer than ~$minimum_idle_duration~${NO_COLOR}

  # Update files if they don't have the same time stamp
  [ $tesla_state_file_time -ne $activity_touch_file_time ] \
    && return 0
        [ $debug -gt 0 ] && echo -e "\t"$0 ${LINENO}: ${IPURPLE}Activity and state files times match${NO_COLOR}

  # Duration since last update
  let state_file_age=now-tesla_state_file_time

  # Update if state file older than update interval
	[ $state_file_age -gt ${update_interval[$state]} ] \
		&& return 0
        [ $debug -gt 0 ] \
          && echo -e "\t"$0 ${LINENO}: ${IPURPLE}State ~$state~ file age ~$state_file_age~ younger than ${update_interval[$state]} ${NO_COLOR}

  # Do not update
  # No file problems
  # Not idle long enough
  # No local server activity since last state file update
  # The last update was less than the update interval
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IPURPLE}update_state_files_conditions_met NOT met\(DONE\)${NO_COLOR}
	return 1
}

## Tesla online status
update_tesla_online_status () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${GREEN}update_tesla_online_status \(\)${NO_COLOR}
  id=$webhook_state_device_id

  parse_key_type_and_value
  state=$value
      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${GREEN}~$state~${NO_COLOR}
  [ "$state" = '' ] \
    && {
          log_error_text="echo ${LINENO} Could not update state ~$state~"
          log_error
      }

      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${GREEN}update_tesla_online_status \(DONE\)${NO_COLOR}
  return 0
}

tesla_is_online () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IGREEN}tesla_is_online \(\)${NO_COLOR}

  update_tesla_online_status \
  [ $state = $teslafi_online_value ] \
    && return 0

      [ $debug -gt 0 ] && echo -e "\t"$0 ${LINENO}: ${IGREEN}-----NOT ONLINE-----${NO_COLOR}
  return 1
}

## Update Webhook Devices
parse_key_type_and_value () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${ICYAN}parse_key_type_and_value \(\)${NO_COLOR}

  id_reversed=$(rev <<< $id)
  tesla_key=$(cut -c 3- <<< $id_reversed | rev)
  device_type=$(cut -c 1-2 <<< $id_reversed | rev)
  value=$(grep --ignore-case -o "\"$tesla_key\":[\"[:alnum:].-]*" <<< $tesla_state_json | cut -d ':' -f2 | grep  -o "[a-zA-Z0-9.-]*")
      [ $debug -gt 1 ] \
        && echo -e "\t" $0 ${LINENO}: ${ICYAN}id ~$id~ tesla_key ~$tesla_key~ device_type ~$device_type~ value ~$value~${NO_COLOR}
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${ICYAN}parse_key_type_and_value \(DONE\)${NO_COLOR}
  return 0
}

process_value () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${ICYAN}process_value \(\)${NO_COLOR}

  [ "$value" = '' ] \
    && {
          [ "$tesla_key" = 'speed' ] \
            && value=0
          return 0
       }

  # Window covering used as charge port door
  [ $device_type = 'WN' ] \
    && [ $value -gt 0 ] \
      && value=100

  # Non boolean (numeric) device types don't need the value changed
  [ ${webhook_device_key[$device_type]} != ${webhook_device_key[BB]}  ] \
    && return 0

        [ $debug -gt 1 ] && echo -e $0 ${LINENO}: ${ICYAN}ID ~$id~ Type ~$device_type~ Value ~$value~${NO_COLOR}

  # Change matching text values to numeric
  grep --ignore-case --quiet "$value" <<< $tesla_state_values_to_be_converted_to_true \
    && value=1

  # Only a value above 0 is true. Anything else is false.
  grep --quiet [1-9] <<< $value \
    && value=${webhook_value_true[$device_type]} \
    || value=${webhook_value_false[$device_type]} \
    && return 0
    log_error_text="Line ${LINENO}: Error processing value. ID ~$id~ Type ~$device_type~ Value ~$value~"
    log_error
    return 1
}

# Pause & Resume commands to teslaFi
pause_commands_to_teslafi (){
  curl_server_url=$server_pause_command
  curl_server

  id=$webhook_pause_device_id
  device_type=$webhook_pause_device_type
  value=${webhook_value_true[$device_type]}
  curl_webhook
}

resume_commands_to_teslafi (){
  curl_server_url=$server_resume_command
  curl_server

  id=$webhook_pause_device_id
  device_type=$webhook_pause_device_type
  value=${webhook_value_false[$device_type]}
  curl_webhook
}

update_webhook_devices () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IYELLOW}update_webhook_devices \(\)${NO_COLOR}

  # Webhook devices send commands when their state changes. The goal here is to
  # update the devices to match the vehicle and not cause changes to the vehicle.
  pause_commands_to_teslafi

	for id in $webhook_ids_to_update
	do
	  parse_key_type_and_value
	      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${IYELLOW}id ~$id~ value ~$value~${NO_COLOR}
    process_value
	      [ $debug -gt 1 ] && echo -e "\t"$0 ${LINENO}: ${IYELLOW}id ~$id~ value ~$value~${NO_COLOR}
    curl_webhook
	done

  resume_commands_to_teslafi

      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: ${IYELLOW}update_webhook_devices \(DONE\)${NO_COLOR}
	return 0
}

#--------------------------------------
check_args_after_read_config_json_file () {
        [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_args_after_read_config_json_file \(\)

	# Process file arguments
	case $arg1 in
	 	'--webhook_url_with_id_key')
	  	echo $webhook_url_with_id_key # for the testing script
	  	exit 0
	  	;;
	 	'--webhook_user_password')
	  	echo $webhook_user_password # for the testing script
	  	exit 0
	  	;;
	 	'--webhook_ids_to_update')
      echo $webhook_ids_to_update # for the testing script
	  	exit 0
	  	;;
	 	'--teslafi-url-with-key')
	 		# --teslafi-url         \t The url used to send TeslaFi commands
	  	echo "$teslafi_base_url/?token=$teslafi_token&command"
	  	exit 0
	  	;;
	 	'--log-message')
	 		# --log-message str     \t Used by the server to log messages
	  	log_message_text=$arg2
			log_message
	  	exit 0
	  	;;
	 	'--log-error')
	 		# --log-error str       \t Used by the server to log errors
	  	log_error_text=$arg2
			log_error
	  	exit 0
	  	;;
	 	'')
	  	;;
	 	*)
			echo "$self_name: invalid option(s) $@"
			echo "Try $self_name --help"
			exit 1
	  	;;
	esac
        [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_args_after_read_config_json_file \(DONE\)
}

check_args () {
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_args \(\)
	# Process file arguments
	case $arg1 in
		# Usage: $self_name [OPTION] \n The updater script to the keep the Tesla webhook devices in sync with the vehicle's state.\n It is used in conjunction with a server script that handles communication between homebridge and TeslaFi.\n To use it just run it without options. The options are for use by the server.#
		'--debug')
	 		# --debug n             \t Prints developer debugging information
	  	;;
		'--pause-command')
	 		# --pause-command  \t When the server receives this command it pauses sending commands to TeslaFi
	  	echo $server_pause_command
	  	exit 0
	  	;;
		'--resume-command')
	 		# --resume-command  \t When the server receives this command it resumes sending commands to TeslaFi
	  	echo $server_resume_command
	  	exit 0
	  	;;
		'--exit-command')
	 		# --exit-command  \t When the server receives this command it exits
	  	echo $server_exit_command
	  	exit 0
	  	;;
		'--shutdown-command')
	 		# --shutdown-command  \t When the server receives this command it shutdowns its own computer
	  	echo $server_shutdown_command
	  	exit 0
	  	;;
		'--reboot-command')
	 		# --halt-command  \t When the server receives this command it reboots its own computer
	  	echo $server_reboot_command
	  	exit 0
	  	;;
		'--response-extension')
	 		# --response-extension  \t The file extension for the server to save responses to commands it sends
	  	echo $server_response_file_ext
	  	exit 0
	  	;;
		'--error-file')
	 		# --error-extension     \t The file for the server to save errors
	  	echo $homebridge_log_file
	  	exit 0
	  	;;
		'--request-limit-window')
	 	  # --request-limit-window\t The length of time for the TeslaFi request limit
	  	echo $teslafi_request_limit_window
	  	exit 0
	  	;;
		'--request-limit-number')
	 	  # --request-limit-number\t The number of requests allowed withing the limit window
	  	echo $teslafi_request_limit_number
	  	exit 0
	  	;;
		'--touch-file')
	 		# --touch-file          \t A file used to track activity of the scripts
	  	echo $activity_touch_file
	  	exit 0
	  	;;
		'--output-path')
	 		# --output-path         \t The location for the scripts to save files
	  	echo $server_output_directory
	  	exit 0
	  	;;
		'--server-reply')
	 		# --server-reply        \t The string that the server sends back to the client when a request is made
	  	echo $server_reply
	  	exit 0
	  	;;
		'--port')
	 		# --port                \t The server port number
	  	echo $server_port
	  	exit 0
	  	;;
	 	'--help')
	 		# --help                \t Prints this help information
			echo -e "$(grep -o "# Usage:.*" < $0  | cut -d '#' -f2 | grep --invert-match ':\.')\n" 
	 		echo -e "$(grep -o '# --.*' < $0 | cut -d '#' -f2 | grep --invert-match '\-\.' )"
	  	exit 0
	 		;;
	 	'')
	  	;;
	esac
      [ $debug -gt 0 ] && echo -e $0 ${LINENO}: check_args \(DONE\)
}

#--------------------------------------
# MAIN

check_args
update_timestamp
check_asleep_config_log_files_exist
read_config_json_file
check_args_after_read_config_json_file

count=$(pgrep -c -f $self_name)
[ $count -gt 1 ] \
  && {
        log_error_text="Already running. Exiting."
        log_error_text+="\n\t$(pgrep -a -f $self_name)"
        log_error
        exit 1
    }

line='TeslaFiED Webhook device updater started.'
line="$line\n\t Webhook activity checks every $update_loop_delay seconds."
line="$line\n\t Vehicle state update every:"
line="$line\n\t\t\t ${update_interval[online]} secconds when it is online"
line="$line\n\t\t\t ${update_interval[asleep]} when it is asleep."
line="$line\n\t These checks do not wake up the vehicle."
log_message_text=$line
log_message

    [ $debug -gt 0 ] && echo -e $0 ${LINENO}: 'Starting main loop:'
while true;
do
	update_timestamp
	read_config_json_file # if changed
	update_tesla_state_json \
	  && update_webhook_devices
          [ $debug -gt 2 ] && { echo -e "\nAll environment variables BEGIN"; ( set -o posix ; set ) ; echo -e "END\n"; }
  set_error_device
          [ $debug -gt 0 ] && echo -e "$0 ${LINENO} Loop delay ~$update_loop_delay~\n\n\n"
  sleep $update_loop_delay
done

exit 0

###################################
Trace
###################################
update_timestamp
###################################
read_config_json_file
  ...
###################################
update_tesla_state_json
  update_tesla_state_file
    update_state_files_conditions_met
    resume_commands_to_teslafi
      ...
  tesla_is_online
###################################
update_webhook_devices
  pause_commands_to_teslafi
    ...
  parse_key_type_and_value
  process_value
    ...
  curl_webhook
    ...
  resume_commands_to_teslafi
    ...
###################################
set_error_device
  ...
###################################
... (represents log or curl functions)
curl_webhook
  log_error
    log_message
OR
log_error
  log_message
