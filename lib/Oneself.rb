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
      evt_type = evt["type"].downcase

      { 
        dateTime: evt["start_date"],
        objectTags: ['self'],
        actionTags: ['exercise', evt_type],
        properties: {
          distance: evt["distance"].to_i,
          name: evt["name"],
          moving_time: evt["moving_time"],
          elapsed_time: evt["elapsed_time"],
          total_elevation_gain: evt["total_elevation_gain"],
          city: evt["location_city"],
          state: evt["location_state"],
          country: evt["location_country"],
          average_speed: evt["average_speed"],
          max_speed: evt["max_speed"]
        }
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
