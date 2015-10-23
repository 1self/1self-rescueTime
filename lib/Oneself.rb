require 'rest-client'
require 'time'
require_relative 'util'

module Oneself

  module Stream
    extend self

    def register(username, reg_token, oneself_uniq_name, logger)
      logger.debug('rgistering stream')
      callback_url = Defaults::HOST_URL + Defaults::SYNC_ENDPOINT + "?oneself_user=#{oneself_uniq_name}&streamid={{streamid}}"
      logger.debug('callback_url: ' + callback_url)
      app_id = Defaults::ONESELF_APP_ID
      app_secret = Defaults::ONESELF_APP_SECRET

      headers = {
        Authorization: "#{app_id}:#{app_secret}", 
        'registration-token' => reg_token,
        'content-type' => 'application/json'
      }

      stream_register_url = Defaults::ONESELF_API_HOST + 
        sprintf(Defaults::ONESELF_STREAM_REGISTER_ENDPOINT, username)

      logger.debug('stream_register_url: ' + stream_register_url)
      logger.debug('reg_token: ' + reg_token[0, 2])
      logger.debug('appid: ' + app_id)
      logger.debug('app_secret: ' + app_secret[0, 2])

      resp = RestClient::Request.execute(
                                         method: :post,
                                         payload: {:callbackUrl => callback_url}.to_json,
                                         url: stream_register_url,
                                         headers: headers,
                                         accept: :json
                                         )

      logger.info("Registered stream for #{username}")
      logger.debug(resp)
      JSON.parse(resp)
    end
  end

  module Event
    extend self

    def transform_rescuetime_event(evt)
      date = Date.parse(evt["date"]).to_s
      dateTime = Time.parse(date + " 23:59:59").utc.iso8601
      
      props = {}
      props["productivity-percent"] = evt["productivity_pulse"]
      props["very-productive-percent"] = evt["very_productive_percentage"]
      props["productive-percent"] = evt["productive_percentage"]
      props["neutral-percent"] = evt["neutral_percentage"]
      props["distracting-percent"] = evt["distracting_percentage"]
      props["very-distracting-percent"] = evt["very_distracting_percentage"]

      props["all-productive-percent"] = evt["all_productive_percentage"]
      props["all-distracting-percent"] = evt["all_distracting_percentage"]
      props["business-percent"] = evt["business_percentage"]

      props["communication-and-scheduling-percent"] = evt["communication_and_scheduling_percentage"]
      props["social-networking-percent"] = evt["social_networking_percentage"]
      props["design-and-composition-percent"] = evt["design_and_composition_percentage"]

      props["entertainment-percent"] = evt["entertainment_percentage"]
      props["news-percent"] = evt["news_percentage"]
      props["software-development-percent"] = evt["software_development_percentage"]

      props["reference-and-learning-percent"] = evt["reference_and_learning_percentage"]
      props["shopping-percent"] = evt["shopping_percentage"]
      props["utilities-percent"] = evt["utilities_percentage"]

      props["total-duration"] = Util.hours_to_seconds(evt["total_hours"])
      props["very-productivity-duration"] = Util.hours_to_seconds(evt["very_productivity_hours"])
      props["all-productivity-duration"] = Util.hours_to_seconds(evt["all_productivity_hours"])
      props["productive-duration"] = Util.hours_to_seconds(evt["productive_hours"])
      props["neutral-duration"] = Util.hours_to_seconds(evt["neutral_hours"])
      props["distracting-duration"] = Util.hours_to_seconds(evt["distracting_hours"])

      props["all-distracting-duration"] = Util.hours_to_seconds(evt["all_distracting_hours"])
      props["uncategorized-duration"] = Util.hours_to_seconds(evt["uncategorized_hours"])
      props["very-distracting-duration"] = Util.hours_to_seconds(evt["very_distracting_hours"])
      props["business-duration"] = Util.hours_to_seconds(evt["business_hours"])
      props["communication-and-scheduling-duration"] = Util.hours_to_seconds(evt["communication_and_scheduling_hours"])
      props["social-networking-duration"] = Util.hours_to_seconds(evt["social_networking_hours"])
      
      props["design-and-composition-duration"] = Util.hours_to_seconds(evt["design_and_composition_hours"])
      props["entertainment-duration"] = Util.hours_to_seconds(evt["entertainment_hours"])

      props["news-duration"] = Util.hours_to_seconds(evt["news_hours"])
      props["software-development-duration"] = Util.hours_to_seconds(evt["software_development_hours"])

      props["reference-and-learning-duration"] = Util.hours_to_seconds(evt["reference_and_learning_hours"])
      props["shopping-duration"] = Util.hours_to_seconds(evt["shopping_hours"])
      props["utilities-duration"] = Util.hours_to_seconds(evt["utilities_hours"])
      

      { 
        dateTime: dateTime,
        objectTags: ['desktop', 'computer'],
        actionTags: ['use'],
        source: "1self-rescuetime",
        properties: props
      }
    end

    def sync(type)
      [
       { dateTime: Time.now.utc.iso8601,
         objectTags: ['1self', 'integration', 'sync'],
         actionTags: [type],
         source: '1self-rescuetime',
         properties: {
         }
       }
      ]
    end

    def send_via_api(events, stream, logger)
      if events.length == 0
        logger.info("there are no events to send to 1self")
      end

      logger.debug("sending events to 1self")

      url = Defaults::ONESELF_API_HOST + 
        sprintf(Defaults::ONESELF_SEND_EVENTS_ENDPOINT, stream["streamid"])

      logger.debug("stream is #{stream}, url is #{url}")
      logger.debug("events are #{events.to_json}")

      resp = RestClient.post(url, events.to_json, accept: :json, content_type: :json, Authorization: stream["writeToken"])
      
      if resp != ''
        parsed_resp = JSON.parse(resp)
      end
      logger.debug("sent events response: #{parsed_resp}")
      logger.info("#{events.length} events sent to 1self (includes one sync complete)")

      parsed_resp
    end

  end

end
