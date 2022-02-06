# TeslaFiED
  * Control a Tesla vehicle form Apple Home (homekit)
  * This is an 'add on' for the awesome [TeslaFi](https://www.teslafi.com) service [[Coffee Link](https://www.teslafi.com/signup.php?referred=teslaowner.tips) + 2 wks to the trial period]
  * Proxy server for TeslaFi API commands
  * Responds to the client immediately with success which makes Tesla Homebridge (homekit) accessories quicker
  * Sends the client's command to TeslaFi
  * Prevents and takes care of errors caused by the vehicle being asleep
  * Updates the Tesla Homebridge (homekit) accessory states based on data from TeslaFi/Tesla
![Screen Shot 2022-02-06 at 3 06 33 PM](https://user-images.githubusercontent.com/78335749/152699340-76897c86-7cc8-4841-874d-49fd4b54ec1a.png)

## Development
This was developped for my own use. Due to my health I am unable to respond to any issues. 

Please take over this project if you are inclined to do so. If you do and let me know I will link to it.

## Audience
Me.

## User skills required to use this software
  - A working knowledge of linux
  - Willing to try and fail
  - Willing to problem solve
  - Being detail oriented may help

# Setup
## Prerequisite
  * Homebridge Rasberry Pi image
    - https://homebridge.io
  * Homebridge Webhooks plugin
    - https://github.com/benzman81/homebridge-http-webhooks
  * TeslaFi account with API access enabled & its access token
    - Sign up for the [TeslaFi](https://www.teslafi.com) service [[Coffee Link](https://www.teslafi.com/signup.php?referred=teslaowner.tips) + 2 wks to the trial period]
    - https://www.teslafi.com/api.php

## Open a terminal
![Screen Shot 2022-02-06 at 3 26 26 PM](https://user-images.githubusercontent.com/78335749/152700604-e7567678-0258-4f7e-ab9c-3765d73f4d23.png)

## Create the directory
```
mkdir /home/pi/teslaFiED
```
## Get the scripts
```
curl -o /home/pi/teslaFiED/teslaFiED_updater.sh https://raw.githubusercontent.com/TeslaOwnerTips/homebridge-teslafied/main/teslaFiED/teslaFiED_server.sh
```
```
curl -o /home/pi/teslaFiED/teslaFiED_server.sh https://raw.githubusercontent.com/TeslaOwnerTips/homebridge-teslafied/main/teslaFiED/teslaFiED_updater.sh
```
## Edit .bashrc
```
echo "/home/pi/teslaFiED/teslaFiED_server.sh" >> /home/pi/.bashrc
echo "sleep 2"
echo "/home/pi/teslaFiED/teslaFiED_updater.sh" >> /home/pi/.bashrc
```
## Auto Login
```
sudo raspi-config 
```
![Screen Shot 2022-02-06 at 3 53 38 PM](https://user-images.githubusercontent.com/78335749/152700913-cebc5839-870c-4d2a-b133-eace87163ce1.png)
![Screen Shot 2022-02-06 at 3 56 01 PM](https://user-images.githubusercontent.com/78335749/152700979-447d78d1-2f7c-4e6f-b7ad-23dbdd7f2576.png)

## Edit config.json
<details> 
  <summary>Using "Config" in the Web UI add the text below to the platforms section.
   
 ![Screen Shot 2022-02-06 at 4 27 30 PM](https://user-images.githubusercontent.com/78335749/152702324-878aab49-fe16-4223-9454-3025dd28f27e.png)
   
 </summary> 
 
 Place a comma after the preceeding closing brace "},". 

```json
        {
            "webhook_port": "51828",
            "webhook_listen_host": "localhost",
            "http_auth_user": "dgd",
            "http_auth_pass": "xfghfdhh",
            "update_loop_delay": "1",
            "update_interval[online]": "120",
            "update_interval[asleep]": "240",
            "minimum_idle_duration": "40",
            "tesla_state_values_to_be_converted_to_true": "online Home",
            "sensors": [
                {
                    "id": "inside_tempNN",
                    "name": "Inside",
                    "type": "temperature"
                },
                {
                    "id": "outside_tempNN",
                    "name": "Outside",
                    "type": "temperature"
                },
                {
                    "id": "battery_levelNN",
                    "name": "Bettery Level",
                    "type": "humidity"
                },
                {
                    "id": "charge_limit_socNN",
                    "name": "Charge Limit",
                    "type": "humidity"
                },
                {
                    "id": "locationLB",
                    "name": "At Home",
                    "type": "occupancy"
                },
                {
                    "id": "speedBB",
                    "name": "Moving",
                    "type": "motion"
                },
                {
                    "id": "f*r*p*d*_windowIB",
                    "name": "Windows",
                    "type": "contact"
                },
                {
                    "id": "p*d*f*r*IB",
                    "name": "Doors",
                    "type": "contact"
                },
                {
                    "id": "ftIB",
                    "name": "Frunk",
                    "type": "contact"
                },
                {
                    "id": "rtIB",
                    "name": "Trunk",
                    "type": "contact"
                },
                {
                    "id": "charge_port_cold_weather_modeIB",
                    "name": "Charge Port Cold Mode",
                    "type": "contact"
                },
                {
                    "id": "battery_heater_onIB",
                    "name": "Battery Heater",
                    "type": "contact"
                },
                {
                    "id": "is_auto_conditioning_onIB",
                    "name": "Auto Conditioning",
                    "type": "contact"
                },
                {
                    "id": "is_preconditioningIB",
                    "name": "Pre Conditioning",
                    "type": "contact"
                },
                {
                    "id": "is_rear_defroster_onIB",
                    "name": "Rear Defroster",
                    "type": "contact"
                },
                {
                    "id": "defrost_modeIB",
                    "name": "Defrost Mode",
                    "type": "contact"
                },
                {
                    "id": "side_mirror_heatersIB",
                    "name": "Side Mirror Heaters",
                    "type": "contact"
                },
                {
                    "id": "wiper_blade_heaterIB",
                    "name": "Wiper Heater",
                    "type": "contact"
                },
                {
                    "id": "error-IB-",
                    "name": "Plugin Error",
                    "type": "contact",
                    "autoRelease": false,
                    "autoReleaseTime": 0
                },
                {
                    "id": "cpu_temp",
                    "name": "Tesla Bridge CPU",
                    "type": "temperature"
                }
            ],
            "switches": [
                {
                    "id": "stateBB",
                    "name": "Awake",
                    "on_url": "http://localhost:11111/wake_up&wake=20"
                },
                {
                    "id": "lockedBB",
                    "name": "Tesla's Locks",
                    "on_url": "http://localhost:11111/door_lock&wake=20",
                    "off_url": "http://localhost:11111/door_unlock&wake=20"
                },
                {
                    "id": "is_climate_onBB",
                    "name": "Climate",
                    "on_url": "http://localhost:11111/auto_conditioning_start&wake=20",
                    "off_url": "http://localhost:11111/auto_conditioning_stop&wake=20"
                },
                {
                    "id": "sentry_modeBB",
                    "name": "Sentry Mode",
                    "on_url": "http://localhost:11111/set_sentry_mode&sentryMode=true&wake=20",
                    "off_url": "http://localhost:11111/set_sentry_mode&sentryMode=false&wake=20"
                },
                {
                    "id": "defrost_modeBB",
                    "name": "Defrosters",
                    "on_url": "http://localhost:11111/set_preconditioning_max&statement=true&wake=20",
                    "off_url": "http://localhost:11111/set_preconditioning_max&statement=false&wake=20"
                },
                {
                    "id": "seat_heater_leftBB",
                    "name": "Driver's Seat Heater",
                    "on_url": "http://localhost:11111/command=seat_heater&heater=0&level=2&wake=20",
                    "off_url": "http://localhost:11111/command=seat_heater&heater=0&level=0&wake=20"
                },
                {
                    "id": "seat_heater_rightBB",
                    "name": "Passenger's Seat Heater",
                    "on_url": "http://localhost:11111/command=seat_heater&heater=1&level=2&wake=20",
                    "off_url": "http://localhost:11111/command=seat_heater&heater=1&level=0&wake=20"
                },
                {
                    "id": "pause-BB-",
                    "name": "Pause Bridge",
                    "on_url": "http://localhost:11111/pause",
                    "off_url": "http://localhost:11111/resume"
                }
            ],
            "pushbuttons": [
                {
                    "id": "charge_limit_soc_100-",
                    "name": "Set Charge Limit to 100%",
                    "push_url": "http://localhost:11111/set_charge_limit&charge_limit_soc=100&wake=20"
                },
                {
                    "id": "charge_limit_soc_90-",
                    "name": "Set Charge Limit to 90%",
                    "push_url": "http://localhost:11111/set_charge_limit&charge_limit_soc=90&wake=20"
                },
                {
                    "id": "charge_limit_soc_80-",
                    "name": "Set Charge Limit to 80%",
                    "push_url": "http://localhost:11111/set_charge_limit&charge_limit_soc=80&wake=20"
                },
                {
                    "id": "honk-",
                    "name": "Honk Tesla's Horn",
                    "push_url": "http://localhost:11111/honk&wake=20"
                },
                {
                    "id": "flash_lights-",
                    "name": "Flash Tesla's Lights",
                    "push_url": "http://localhost:11111/flash_lights&wake=20"
                },
                {
                    "id": "reboot-",
                    "name": "Restart Bridge",
                    "push_url": "http://localhost:11111/sudo reboot"
                },
                {
                    "id": "halt-",
                    "name": "Power Off Bridge",
                    "push_url": "http://localhost:11111/halt"
                },
                {
                    "id": "exit-",
                    "name": "Exit Bridge Software",
                    "push_url": "http://localhost:11111/exit 0"
                }
            ],
            "lights": [
                {
                    "id": "cpu_percent",
                    "name": "Tesla Bridge CPU %"
                }
            ],
            "outlets": [
                {
                    "id": "charger_actual_currentOB",
                    "name": "Charging",
                    "on_url": "http://localhost:11111/charge_start&wake=20",
                    "off_url": "http://localhost:11111/charge_stop&wake=20"
                }
            ],
            "windowcoverings": [
                {
                    "id": "charge_port_door_openWN",
                    "name": "Tesla's Charge Port",
                    "open_url": "http://localhost:11111/charge_port_door_open&wake=20",
                    "close_url": "http://localhost:11111/charge_port_door_close&wake=20",
                    "auto_set_current_position": true
                }
            ],
            "_bridge": {
                "name": "TeslaFiED",
                "username": "0E:62:9B:04:20:69",
                "port": 48699
            },
            "platform": "HttpWebHooks"
        }
```
</details>

Replace the value for http_auth_pass with the TeslaFi API token.
```json
            "http_auth_user": "dgd",
            "http_auth_pass": "xfghfdhh",
```
![Screen Shot 2022-02-06 at 4 47 01 PM](https://user-images.githubusercontent.com/78335749/152702710-6aeb80a6-960a-47b9-b03f-ca03ac6a6b69.png)

![Screen Shot 2022-02-06 at 4 48 21 PM](https://user-images.githubusercontent.com/78335749/152702752-39ed7658-5776-4142-b73c-380950e9a981.png)

![Screen Shot 2022-02-06 at 4 51 26 PM](https://user-images.githubusercontent.com/78335749/152702858-a3da37b1-baef-4304-98c6-faac0baccc77.png)

## Wake
 Wake up the vehicle.

## Restart/Reboot the hombridge computer
![Screen Shot 2022-02-06 at 5 00 24 PM](https://user-images.githubusercontent.com/78335749/152703160-916f8c5f-c721-4bad-90a1-7e5e223d9dda.png)

## Add TeslaFiED as a accessory to Apple Home
The pin is the same pin as the one used to homebridge. Look for:
```json
        "pin": "420-69-420",
        "port": 12345,
        "username": "ef:56:9cd:34:ad:12",
        "name": "xyz"
```
