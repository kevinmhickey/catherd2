class Herd

  def initialize repository
    @repository = repository
    @consultants = repository.get_all_consultants
    @submitting = false
  end

  attr_reader :consultants, :submitting

  def add consultant
    @consultants[consultant.beeline_guid] = consultant
  end

  def mark_as_submitting week_ending_date, beeline_guids
    beeline_guids.each do |beeline_guid|
      @consultants[beeline_guid].timecards[week_ending_date].state = :SUBMITTING
    end
  end

  def enter_timecards timecard_submitter, week_ending_date, times_to_enter
    @submitting = true
    mark_as_submitting week_ending_date, times_to_enter.keys

    times_to_enter.each do |beeline_guid, hours_to_enter|
      timecard = @consultants[beeline_guid].timecards[week_ending_date]
      timecard_submitter.submit timecard, week_ending_date, beeline_guid, hours_to_enter.to_i, @consultants[beeline_guid].project
      @repository.update_consultant @consultants[beeline_guid]
    end
    @submitting = false
  end

  def get_timecards_for_entry week_ending_date
    timecards = []
    @consultants.values.each do |consultant|
      timecard = consultant.timecard_for_entry(week_ending_date)
      timecards << timecard unless timecard.nil?
    end

    timecards
  end

end