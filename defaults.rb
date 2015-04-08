
module Defaults
  extend self

  def from_file(fname)
    content = File.read(fname)
    content.strip
  end

  SESSION_SECRET = from_file("session_secret.txt")
  HOST_URL = "https://oneself-rescuetime.herokuapp.com"
  SYNC_ENDPOINT = "/sync"

  RESCUE_TIME_CLIENT_ID = from_file("rescuetime_client_id.txt")
  RESCUE_TIME_CLIENT_SECRET = from_file("rescuetime_client_secret.txt")
  RESCUE_TIME_CALLBACK_URL = 'https://rescuetime.1self.co/oauthredirect'

  ONESELF_API_HOST = "http://api.1self.co"
  ONESELF_STREAM_REGISTER_ENDPOINT = "/v1/users/%s/streams"
  ONESELF_SEND_EVENTS_ENDPOINT = "/v1/streams/%s/events/batch"
  ONESELF_APP_ID = from_file("oneself_app_id.txt")
  ONESELF_APP_SECRET = from_file("oneself_app_secret.txt")
end


$stdout.sync = true #enable realtime logs on heroku

configure do
  enable :sessions
  set :session_secret, Defaults::SESSION_SECRET
  set :logging, true
  set :server, 'webrick'
end

rescue_time_client = RescueTime::Client.new(RESCUE_TIME_CLIENT_ID, RESCUE_TIME_CLIENT_SECRET, RESCUE_TIME_CALLBACK_URL)
