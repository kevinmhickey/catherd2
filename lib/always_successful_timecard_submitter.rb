class AlwaysSuccessfulTimecardSubmitter
  def submit timecard, week_ending_date, beeline_guid, hours_to_enter, project
    timecard.hours_submitted = hours_to_enter
  end

  def close

  end
end