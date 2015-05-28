require('logger')

module Defaults
  extend self

  def from_file(fname)
    content = File.read(fname)
    content.strip
  end

  SESSION_SECRET = ENV['SESSION_SECRET'] # from_file("session_secret.txt")
  HOST_URL = ENV['RESCUE_TIME_HOST_URL'] # "https://rescuetime.1self.co"
  SYNC_ENDPOINT = "/sync"

  RESCUE_TIME_CLIENT_ID = ENV['RESCUE_TIME_CLIENT_ID']
  RESCUE_TIME_CLIENT_SECRET = ENV['RESCUE_TIME_CLIENT_SECRET'] #from_file("rescuetime_client_secret.txt")
  RESCUE_TIME_CALLBACK_URL = HOST_URL + '/oauthredirect'

  ONESELF_API_HOST = ENV['ONESELF_API_HOST'] #"http://api.1self.co"
  ONESELF_STREAM_REGISTER_ENDPOINT = "/v1/users/%s/streams"
  ONESELF_SEND_EVENTS_ENDPOINT = "/v1/streams/%s/events/batch"
  ONESELF_APP_ID = ENV['ONESELF_APP_ID'] #from_file("oneself_app_id.txt")
  ONESELF_APP_SECRET = ENV['ONESELF_APP_SECRET'] #from_file("oneself_app_secret.txt")


  RESCUE_TIME_DB_HOST = ENV['RESCUE_TIME_DB_HOST']
  RESCUE_TIME_DB_PORT = ENV['RESCUE_TIME_DB_PORT']
  RESCUE_TIME_DB_NAME = ENV['RESCUE_TIME_DB_NAME']
  RESCUE_TIME_DB_USER = ENV['RESCUE_TIME_DB_USER']
  RESCUE_TIME_DB_PASSWORD = ENV['RESCUE_TIME_DB_PASSWORD']

  logger = Logger.new(STDOUT)

  logger.info("SESSION_SECRET: " + SESSION_SECRET)
  logger.info("RESCUE_TIME_CLIENT_ID: " + RESCUE_TIME_CLIENT_ID)
  logger.info("RESCUE_TIME_CLIENT_SECRET: " + RESCUE_TIME_CLIENT_SECRET)
  logger.info("ONESELF_API_HOST: " + ONESELF_API_HOST)
  logger.info("ONESELF_APP_ID: " + ONESELF_APP_ID)
  logger.info("ONESELF_APP_SECRET: " + ONESELF_APP_SECRET)
  logger.info("RESCUE_TIME_DB_HOST: " + RESCUE_TIME_DB_HOST)
  logger.info("RESCUE_TIME_DB_PORT: " + RESCUE_TIME_DB_PORT)
  logger.info("RESCUE_TIME_DB_NAME: " + RESCUE_TIME_DB_NAME)
  logger.info("RESCUE_TIME_DB_USER: " + RESCUE_TIME_DB_USER)
  logger.info("RESCUE_TIME_DB_PASSWORD: " + RESCUE_TIME_DB_PASSWORD)
end



$stdout.sync = true #enable realtime logs on heroku

configure do
  enable :sessions
  set :session_secret, Defaults::SESSION_SECRET
  set :logging, true
  set :server, 'webrick'
end
