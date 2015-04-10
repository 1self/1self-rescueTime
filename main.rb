require 'sinatra'
require "sinatra/reloader"
require 'pg'
require 'byebug'

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

  rt_helper = RescueTimeHelper.new
  auth_url = rt_helper.get_auth_url(scopes)

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

    rt_helper = RescueTimeHelper.new
    token = rt_helper.get_auth_token(code)
    oneself_username = session['oneselfUsername']

    conn = PG::Connection.open(:dbname => 'rescue_time')
    conn.exec_params('INSERT INTO USERS (oneself_username, access_token, last_sync_id) VALUES ($1, $2, $3)', [oneself_username, token.token, 0])
    
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

  conn = PG::Connection.open(:dbname => 'rescue_time')
  result = conn.exec("SELECT * FROM USERS WHERE oneself_username = '#{oneself_username}'")
  
  auth_token = result[0]["access_token"]
  username = result[0]["oneself_username"]
  last_id = result[0]["last_sync_id"]

  puts "Fetching events for #{username}"
  rt_helper = RescueTimeHelper.new
  rt_helper.set_token(auth_token)

  rescue_time_events, last_id = rt_helper.get_events(last_id)

  all_events = rescue_time_events + Oneself::Event.sync("complete")

  Oneself::Event.send_via_api(all_events, stream)

  result = conn.exec("UPDATE USERS SET LAST_SYNC_ID = #{last_id} WHERE oneself_username = '#{oneself_username}'")
  puts "Sync complete for #{username}"

rescue => e
  puts "Some error for: #{oneself_username}. Error: #{e}"
end
