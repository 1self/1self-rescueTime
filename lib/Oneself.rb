require 'rest-client'
require 'time'

module Oneself

  module Stream
    extend self

    def register(username, reg_token, oneself_uniq_name)
      callback_url = Defaults::HOST_URL + Defaults::SYNC_ENDPOINT + "?oneself_user=#{oneself_uniq_name}&streamid={{streamid}}"
      app_id = Defaults::ONESELF_APP_ID
      app_secret = Defaults::ONESELF_APP_SECRET

      headers = {
        Authorization: "#{app_id}:#{app_secret}", 
        'registration-token' => reg_token,
        'content-type' => 'application/json'
      }

      stream_register_url = Defaults::ONESELF_API_HOST + 
        sprintf(Defaults::ONESELF_STREAM_REGISTER_ENDPOINT, username)

      resp = RestClient::Request.execute(
                                         method: :post,
                                         payload: {:callbackUrl => callback_url}.to_json,
                                         url: stream_register_url,
                                         headers: headers,
                                         accept: :json
                                         )

      puts "Successfully registered stream for #{username}"

      JSON.parse(resp)
    end
  end

  module Event
    extend self

    def transform_rescuetime_event(evt)
      dateTime = Date.parse(evt["date"]).to_time.utc.iso8601
      evt.delete("id")
      evt.delete("date")

      { 
        dateTime: dateTime,
        objectTags: ['self'],
        actionTags: ['productivity'],
        properties: evt
      }
    end

    def sync(type)
      [
       { dateTime: Time.now.utc.iso8601,
         objectTags: ['sync'],
         actionTags: [type],
         properties: {
           source: '1self-rescuetime'
         }
       }
      ]
    end

    def send_via_api(events, stream)
      puts "Sending events to 1self"

      url = Defaults::ONESELF_API_HOST + 
        sprintf(Defaults::ONESELF_SEND_EVENTS_ENDPOINT, stream["streamid"])

      puts stream
      puts url

      resp = RestClient.post(url, events.to_json, accept: :json, content_type: :json, Authorization: stream["writeToken"])
      
      parsed_resp = JSON.parse(resp)
      puts "Response after sending events: #{parsed_resp}"

      parsed_resp
    end

  end

end
