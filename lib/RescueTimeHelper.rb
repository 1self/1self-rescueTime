class RescueTimeHelper
  def initialize(access_token)
    rescue_time_client.set_token(access_token)
  end
  
  def get_events(since_time)
    rescuetime_events = rescue_time_client.fetch_daily_summary_feed
    transform_to_oneself_events(rescuetime_events)
  end

  private
  
  def transform_to_oneself_events(rescuetime_events)
    oneself_events = []
    rescuetime_events.each do |evt|
      oneself_events.push(Oneself::Event.transform_rescuetime_event(evt))
    end

    puts "Finished transforming events, returning."
    oneself_events
  end
end
