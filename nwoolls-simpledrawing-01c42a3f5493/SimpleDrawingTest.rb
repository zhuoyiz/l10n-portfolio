require 'rubygems'
require 'appium_lib'

APP_PATH = '~/Desktop/Drawing.app'

capabilities = {
    platformName:  'iOS',
    versionNumber: '7.1',
    app:           APP_PATH,
    deviceName: 'IOS',
}

server_url = "http://0.0.0.0:4723/wd/hub"

Appium::Driver.new(caps: capabilities).start_driver
Appium.promote_appium_methods Object

sleep 1

find_element(:accessibility_id, "New").click

sleep 1

swipe :start_x => 76, :start_y => 96, :end_x => 76, :end_y => 300, :touchCount => 1, :duration => 500

swipe :start_x => 116, :start_y => 53, :end_x => 66, :end_y => 300, :touchCount => 1, :duration => 500


sleep 2

find_element(:accessibility_id, "Save").click

sleep 2

swipe :start_x => 315, :start_y => 278, :end_x => 316, :end_y => 279, :touchCount => 1, :duration => 500

sleep 2

swipe :start_x => 216, :start_y => 53, :end_x => 66, :end_y => 300, :touchCount => 1, :duration => 500

sleep 1

find_element(:accessibility_id, "Cancel").click

sleep 2

driver_quit
