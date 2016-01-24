# Lights project

This project allows you to control the lights in your room. It consists primarily of a rails server, which provides a nice interface. There is also a listener that runs on a Raspberry Pi which does the physical job of turning lights on or off.

## How it works
When the lightbulb in the frontend is clicked, it sends a message through a websocket to the backend. The backend then sends that message out to all listeners, across all servers that are running the backend. The listener then uses a Raspberry Pi's GPIO pins to physically interface with the lights.

A few cool things worth noting:
- Because it uses websockets, it's super low latency
- It can scale to an arbitrary number of servers and still hold connections to all clients

## How to run server
Run `foreman start -f Procfile.dev`
Navigate to http://localhost:3000

To install the first time:
- Install Ruby on Rails
- Run `bundle install` to install dependencies
- It should now run, but depending on your computer you may need to install other dependencies if it tells you to

## How to run Raspberry Pi script
Run `ruby lib/lights_listener.rb` on the raspberry pi

To install the first time:
- `gem install pi_piper`
- `gem install websocket-client-simple`
- Edit `ws_url` on line 9 of `lib/lights_listener.rb` to point to your live server

Alternatively, if you don't have a Raspberry Pi, you can mock it by setting `mock` to true on line 8

## Files of note
While there are plenty of other files, the core logic lives in a just a few.
- `app/middleware/lights_middleware.rb`. This is the main serverside script that sends out messages to all listeners
- `app/assets/javascripts/lights.rb`. This is the frontend script that sends a message through the websocket to all listeners when the light is turned on or off.
- `lib/lights_listener.rb`. This is the client that runs on the RaspberryPi, listening for the messages and turning the light on or off as appropriate