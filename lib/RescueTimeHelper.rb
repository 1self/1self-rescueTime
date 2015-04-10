class RescueTimeHelper
  def initialize(access_token)
    Defaults::RescueTimeClient.set_token(access_token)
  end
  
  def get_events(from_id)
    rescuetime_events = Defaults::RescueTimeClient.fetch_daily_summary_feed

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
