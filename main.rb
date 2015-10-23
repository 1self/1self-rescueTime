require 'sinatra'
require "sinatra/reloader"
require 'pg'
require 'byebug'

require_relative 'defaults'
require_relative 'lib/Oneself'
require_relative 'lib/RescueTimeHelper'
require_relative 'logging'

logger = Logging::MultiLogger.new(ENV['LOGGINGDIR'] + '/rescuetime.log')
logger.fatal("fatal messages logged here")
logger.error("error messages logged here")
logger.warn("warn messages logged here")
logger.info("info messages logged here")
logger.debug("debug messages logged here")

logger.info('running on port ' + ENV['PORT'])

get '/' do
  "There's nothing here."
end

loginLogger = Logging::ScopedLogger.new("login", logger)

get '/login' do
  if params[:username].nil? || params[:token].nil?
    status 404
    loginLogger.error("request was made without required parameters")
    body 'Oneself parameters not found' and return
  end

  usernameLogger = Logging::ScopedLogger.new(params[:username], loginLogger);
  session['oneselfUsername'] = params[:username]
  session['registrationToken'] = params[:token]
  session['redirectUri'] = params[:redirect_uri]
  usernameLogger.info("Redirecting to login.")
  usernameLogger.debug("Redirect url is #{params[:redirect_uri]}, token is #{params[:token][0, 2]}")

  scopes = ["time_data","category_data","productivity_data","alert_data","highlight_data"]

  rt_helper = RescueTimeHelper.new
  auth_url = rt_helper.get_auth_url(scopes)

  usernameLogger.debug("Authing on #{auth_url}")
  redirect auth_url
end

syncLogger = Logging::ScopedLogger.new("sync", logger)

get '/sync' do
  user = params[:oneself_user]
  userLogger = Logging::ScopedLogger.new(user, syncLogger)
  userLogger.info('requested')
  streamid = params[:streamid]
  write_token = request.env['HTTP_AUTHORIZATION']

  userLogger.debug("streamid is #{streamid}, write token is #{write_token[0, 2]}")

  if user.nil? || streamid.nil? || write_token.nil?
    status 404
    userLogger.error("required parameters not found")
    body 'Oneself sync parameters not found' and return
  end

  stream = {
    "streamid" => streamid,
    "writeToken" => write_token
  }

  userLogger.debug("starting sync")
  start_sync(user, stream, userLogger)
  userLogger.info("finished sync")

  "Sync request complete"
end

oauthredirectLogger = Logging::ScopedLogger.new("oauthredirect", logger)

get '/oauthredirect' do
  begin
    oneself_username = session['oneselfUsername']
    userLogger = Logging::ScopedLogger.new(oneself_username, oauthredirectLogger)
    userLogger.info("request made")
    code = params[:code]

    userLogger.debug("received auth code #{code}")

    rt_helper = RescueTimeHelper.new
    token = rt_helper.get_auth_token(code)

    conn = PG::Connection.open(dbname: Defaults::RESCUE_TIME_DB_NAME,
                              host: Defaults::RESCUE_TIME_DB_HOST,
                              port: Defaults::RESCUE_TIME_DB_PORT.to_i,
                              user: Defaults::RESCUE_TIME_DB_USER,
                              password: Defaults::RESCUE_TIME_DB_PASSWORD)
    conn.exec_params('INSERT INTO USERS (oneself_username, access_token, last_sync_id) VALUES ($1, $2, $3)', [oneself_username, token.token, 0])
    userLogger.debug('user state stored in db')  
    userLogger.debug("registrationToken is #{session['registrationToken'][0, 2]}")
    stream = Oneself::Stream.register(oneself_username,
                                      session['registrationToken'],
                                      oneself_username #no uniq field from rescuetime available :(
                                      )
    userLogger.info('stream registered')
#    userLogger.info(stream)
    userLogger.debug('starting sync')
    start_sync(oneself_username, stream, userLogger)
    userLogger.info("sync complete, redirecting back to integrations using #{session['redirect_uri']}")
    redirect(session['redirectUri'] + '?success=true')
  rescue => e
    userLogger.error("Error while rescuetime callback #{e}")
    redirect(session['redirectUri'] + '?success=false&error=server_error')
  end
end


def start_sync(oneself_username, stream, logger)
  sync_start_event = Oneself::Event.sync("start")
  logger.debug("sending sync start event #{sync_start_event}")
  Oneself::Event.send_via_api(sync_start_event, stream)
  logger.info("Sent sync start event successfully")


  logger.debug("getting users details from the database")
  conn = PG::Connection.open(dbname: Defaults::RESCUE_TIME_DB_NAME,
                              host: Defaults::RESCUE_TIME_DB_HOST,
                              port: Defaults::RESCUE_TIME_DB_PORT.to_i,
                              user: Defaults::RESCUE_TIME_DB_USER,
                              password: Defaults::RESCUE_TIME_DB_PASSWORD)


  result = conn.exec("SELECT * FROM USERS WHERE oneself_username = '#{oneself_username}'")
  
  access_token = result[0]["access_token"]
  username = result[0]["oneself_username"]
  last_id = result[0]["last_sync_id"]

  logger.debug("access_token is #{access_token[0, 2]}, username is #{username[0, 2]}, last_id is #{last_id}")

  logger.debug("fectching events")
  rt_helper = RescueTimeHelper.new
  rt_helper.set_token(access_token)

  rescue_time_events, new_last_id = rt_helper.get_events(last_id)

  logger.debug("events retrieved, time of last event from api is #{new_last_id}")
  logger.debug("rescue_time_events is #{rescue_time_events}")

  if rescue_time_events == nil
    rescue_time_events = []
  end
    
  logger.debug("adding the complete event")
  all_events = rescue_time_events + Oneself::Event.sync("complete")
    
  logger.debug("sending the events to the api")
  Oneself::Event.send_via_api(all_events, stream)
  if new_last_id != nil
    result = conn.exec("UPDATE USERS SET LAST_SYNC_ID = #{new_last_id} WHERE oneself_username = '#{oneself_username}'")
  end
  logger.info("Sync complete")

rescue => e
  logger.info("Error occurred, #{e}")
  throw e
end
