require 'rescue_time_client'
require_relative 'Oneself'
logger = Logger.new(STDOUT)

class RescueTimeHelper
  @@logger = Logger.new(STDOUT)

  def initialize(client_id, client_secret, callback_url)
    @client = RescueTime::Client.new(client_id, client_secret, callback_url)
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
  
  def get_events(from_id, logger)
    logger.debug('getting events')
    rescuetime_events = @client.fetch_daily_summary_feed
    logger.info("events received from api")

    logger.debug("transforming events, ")
    logger.debug(rescuetime_events.inspect);
    events, latest_id = transform_to_oneself_events(rescuetime_events, from_id, logger)
    logger.info("transformed events")
    return events, latest_id
  end
  
  def transform_to_oneself_events(rescuetime_events, from_id, logger)
    if rescuetime_events == []
      return []
    end
    
    oneself_events = []
    latest_id = rescuetime_events.first["id"]

    logger.debug 'going through events, count' + rescuetime_events.length.to_s

    rescuetime_events.each do |evt|
      logger.debug("processing event")
      logger.debug("event to be transformed is #{evt}")
      if from_id.to_i == evt["id"] # the first event return will include the final event from the last sync
        logger.debug("skipped event")
        break
      elsif from_id.to_i > evt["id"]
        logger.warn("stopping transforming events because there is missing data in the rescue time source data")
        oneself_events = []
        latest_id = from_id.to_i
        break
      else
        logger.debug("added event")
        oneself_events.push(Oneself::Event.transform_rescuetime_event(evt))
      end
    end

    logger.debug("finished transforming #{oneself_events.count} events")
    return oneself_events, latest_id
  end
end
