require 'sinatra'
require "sinatra/reloader"
require 'pg'
require 'byebug'
require 'rescue_time_client'

require_relative 'defaults'
require_relative 'lib/Oneself'
require_relative 'lib/RescueTimeHelper'

get '/' do
  "There's nothing here."
end

get '/login' do
  if params[:username].nil? || params[:token].nil?
    status 404
    body 'Oneself parameters not found' and return
  end

  session['oneselfUsername'] = params[:username]
  session['registrationToken'] = params[:token]
  puts "Redirecting #{params[:username]} to login."

  scopes = ["time_data","category_data","productivity_data","alert_data","highlight_data"]
  auth_url = rescue_time_client.get_auth_url(scopes)

  redirect auth_url
end

get '/sync' do
  user = params[:oneself_user]
  streamid = params[:streamid]
  write_token = request.env['HTTP_AUTHORIZATION']

  if user.nil? || streamid.nil? || write_token.nil?
    status 404
    body 'Oneself sync parameters not found' and return
  end

  stream = {
    "streamid" => streamid,
    "writeToken" => write_token
  }

  start_sync(user, stream)

  "Sync request complete"
end


get '/oauthredirect' do
  begin
    code = params[:code]

    token = rescue_time_client.get_token_from_code(code)
    oneself_username = session['oneselfUsername']

    last_sync_time = (DateTime.now << 1).to_time.to_i
    conn = PG::Connection.open(:dbname => 'dev')
    conn.exec_params('INSERT INTO USERS (oneself_username, access_token, last_sync_time) VALUES ($1, $2, $3)', [username, token.token, last_sync_time])
    
    stream = Oneself::Stream.register(oneself_username,
                                      session['registrationToken'],
                                      oneself_username #no uniq field from rescuetime available :(
                                      )

    start_sync(oneself_username, stream)

    redirect(Defaults::ONESELF_API_HOST + '/integrations')
  rescue => e
    puts "Error while rescuetime callback #{e}"
    redirect(Defaults::ONESELF_API_HOST + '/integrations')
  end
end


def start_sync(oneself_username, stream)
  sync_start_event = Oneself::Event.sync("start")
  Oneself::Event.send_via_api(sync_start_event, stream)
  puts "Sent sync start event successfully"

  conn = PG::Connection.open(:dbname => 'dev')
  result = conn.exec("SELECT * FROM USERS WHERE oneself_username = '#{oneself_username}'")
  
  auth_token = result[0]["access_token"]
  username = result[0]["oneself_username"]
  since_time = result[0]["last_sync_time"]

  puts "Fetching events for #{username}"
  rescuetime_helper = RescueTimeHelper.new(auth_token)

  all_events = rescuetime_helper.get_events(since_time) +
    Oneself::Event.sync("complete")

  Oneself::Event.send_via_api(all_events, stream)

  result = conn.exec("UPDATE USERS SET LAST_SYNC_TIME = #{Time.now.to_i} WHERE oneself_username = '#{oneself_username}'")
  puts "Sync complete for #{username}"

rescue => e
  puts "Some error for: #{oneself_username}. Error: #{e}"
end
