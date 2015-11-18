require 'test/unit'
require_relative 'RescueTimeHelper'
logger = Logger.new(STDOUT)


class RescueTimeHelperTests < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  @@logger = Logger.new(STDOUT)
  
  def create_event(id)
    evt = {}
    evt["id"] = id
    evt["date"] = "2015-01-01"
    
    evt["productivity_pulse"] = 0
    evt["very_productive_percentage"] = 0
    evt["productive_percentage"] = 0
    evt["neutral_percentage"] = 0
    evt["distracting_percentage"] = 0
    evt["very_distracting_percentage"] = 0

    evt["all_productive_percentage"] = 0
    evt["all_distracting_percentage"] = 0
    evt["business_percentage"] = 0

    evt["communication_and_scheduling_percentage"] = 0
    evt["social_networking_percentage"] = 0
    evt["design_and_composition_percentage"] = 0

    evt["entertainment_percentage"] = 0
    evt["news_percentage"] = 0
    evt["software_development_percentage"] = 0

    evt["reference_and_learning_percentage"] = 0
    evt["shopping_percentage"] = 0
    evt["utilities_percentage"] = 0

    evt["total_hours"] = 0
    evt["very_productivity_hours"] = 0
    evt["all_productivity_hours"] = 0
    evt["productive_hours"] = 0
    evt["neutral_hours"] = 0
    evt["distracting_hours"] = 0

    evt["all_distracting_hours"] = 0
    evt["uncategorized_hours"] = 0
    evt["very_distracting_hours"] = 0
    evt["business_hours"] = 0
    evt["communication_and_scheduling_hours"] = 0
    evt["social_networking_hours"] = 0
    
    evt["design_and_composition_hours"] = 0
    evt["entertainment_hours"] = 0

    evt["news_hours"] = 0
    evt["software_development_hours"] = 0

    evt["reference_and_learning_hours"] = 0
    evt["shopping_hours"] = 0
    evt["utilities_hours"] = 0
     
    evt
  end

  def test_first_sync
    events = [create_event(3), create_event(2), create_event(1)]

    rt_helper = RescueTimeHelper.new('','','')
    eventsToSend, latest = rt_helper.transform_to_oneself_events(events, "0", @@logger);
    assert_equal(3, eventsToSend.length, 'all events should be sent')
  end

  def test_sync_on_same_day
    events = [create_event(3), create_event(2), create_event(1)]

    rt_helper = RescueTimeHelper.new('','','')
    eventsToSend, latest = rt_helper.transform_to_oneself_events(events, "3", @@logger);
    assert_equal(0, eventsToSend.length, 'all events should be sent')
  end

  def test_missing_rescue_time_data
    events = [create_event(3), create_event(1)]

    rt_helper = RescueTimeHelper.new('','','')
    eventsToSend, latest = rt_helper.transform_to_oneself_events(events, "2", @@logger);
    assert_equal(0, eventsToSend.length, 'all events should be sent')
  end

 
end