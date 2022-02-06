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
 
## Get the scripts
