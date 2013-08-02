class Timecard
  def initialize week_ending_date, rolloff_date, start_date
    @week_ending_date = week_ending_date
    @start_date = start_date
    @rolloff_date = rolloff_date
    @hours_submitted = 0
    @state = :UNSUBMITTED
  end

  attr_reader :week_ending_date, :state, :hours_submitted

  def working_on? day, rolloff_date, start_date
    return day <= rolloff_date && day >= start_date
  end

  def hours_worked
    hours_worked = 0
    week_start_date = @week_ending_date - 6

    5.times do |time|
      hours_worked += 8 if working_on?(week_start_date + time, @rolloff_date, @start_date)
    end

    hours_worked
  end

  def hours_submitted= hours
    @hours_submitted = hours
    @state = :SUBMITTED
  end

  def submit_failed
    @state = :FAILED
  end

  def to_hash
    {:week_ending => @week_ending_date.to_s,
     :hours_worked => self.hours_worked,
     :hours_submitted => @hours_submitted,
     :state => @state.to_s
    }
  end
end