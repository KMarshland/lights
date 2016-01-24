#This runs on a raspberry pi with connections to my lights

require 'rubygems'
require 'websocket-client-simple'
require 'json'

#tell it whether or not it's actually running on a raspberry pi
mock = true
ws_url = ENV['WS_URL'] || 'ws://localhost:3000'

require 'pi_piper' unless mock
include PiPiper unless mock

#get a reference to the lights pin
pin = PiPiper::Pin.new(:pin => 14, :direction => :out) unless mock

#Connect to the websocket
ws = WebSocket::Client::Simple.connect ws_url

#this gets called whenever there's a websocket message
ws.on :message do |msg|

  mess = JSON.parse(msg.data)
  if mess['lights']
    puts 'Turning lights on'
    pin.on unless mock
  else
    puts 'Turning lights off'
    pin.off unless mock
  end
end

ws.on :open do
end

ws.on :close do |e|
  exit 1
end

ws.on :error do |e|
  puts e
end

#keep the script from exiting
loop do
  #additionally, you can send messages from here
  msg = STDIN.gets.strip
  ws.send msg if msg.present?
end
