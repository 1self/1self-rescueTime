require 'rescue_time_client'

class RescueTimeHelper
  def initialize
    @client = RescueTime::Client.new(Defaults::RESCUE_TIME_CLIENT_ID, 
                                     Defaults::RESCUE_TIME_CLIENT_SECRET, 
                                     Defaults::RESCUE_TIME_CALLBACK_URL)
  end

  def get_auth_url(scopes)
    @client.get_auth_url(scopes)
  end

  def get_auth_token(code)
    @client.get_token_from_code(code)
  end

  def set_token(access_token)
    @client.set_token(access_token)
  end
  
  def get_events(from_id)
    rescuetime_events = @client.fetch_daily_summary_feed

    transform_to_oneself_events(rescuetime_events, from_id)
  end

  private
  
  def transform_to_oneself_events(rescuetime_events, from_id)
    oneself_events = []
    latest_id = rescuetime_events.first["id"]

    rescuetime_events.each do |evt|
      if from_id.to_i == evt["id"]
        break
      else
        oneself_events.push(Oneself::Event.transform_rescuetime_event(evt))
      end
    end

    puts "Finished transforming #{oneself_events.count} events, returning."
    return oneself_events, latest_id
  end
end
