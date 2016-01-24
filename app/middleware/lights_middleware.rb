require 'faye/websocket'
require 'redis'
require 'thread'

#this middleware broadcasts websocket messages to all connections
class LightsMiddleware
  KEEPALIVE_TIME = 15 # keep the connection from dying
  CHANNEL        = "lights"

  def initialize(app)
    @app     = app
    @clients ||= []
    @synchronizer = Mutex.new

    uri      = URI.parse( ENV["REDISTOGO_URL"] || 'http://localhost:6379')
    @redis   = Redis.new(host: uri.host, port: uri.port, password: uri.password)
  end

  def call(env)
    #this middleware only deals with websocket requests
    if Faye::WebSocket.websocket?(env)

      #track the clients with a connection
      ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
      ws.on :open do |event|
        @synchronizer.synchronize {
          p [:open, ws.object_id]
          @clients.push ws
          subscribe_to_messages
        }
      end

      #when a client says something send it to everyone
      ws.on :message do |event|
        @synchronizer.synchronize {
          p [:message, event.data]
          @redis.publish(CHANNEL, event.data)
        }
      end

      #don't send message to nonexistent connections
      ws.on :close do |event|
        @synchronizer.synchronize {
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        }
      end

      # Return async Rack response
      ws.rack_response
    else #progress to the normal app
      @app.call(env)
    end
  end

  #each server needs to be listening to redis, as the message may have occurred on another instance
  def subscribe_to_messages
    if @initialized #it only needs to initialize once per worker
      return
    end
    @initialized = true

    #listen to REDIS for a message from some other server
    uri = URI.parse( ENV["REDISTOGO_URL"] || 'http://localhost:6379')
    Thread.new do
      redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      redis_sub.subscribe(CHANNEL) do |on|
        on.subscribe do |channel, subscriptions|
          puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.message do |channel, msg|
          @synchronizer.synchronize {
            puts "'#{msg}' received in #{channel}"
            #when you actually get the message, send it out
            @clients.each {|ws|
              ws.send(msg)
            }
          }
        end
      end
    end
  end
end