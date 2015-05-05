module Util
  extend self

  def hours_to_milli_seconds(hours)
    hours * 60 * 60 * 1000 rescue 0
  end

  def hours_to_seconds(hours)
    hours * 60 * 60 rescue 0
  end
end
