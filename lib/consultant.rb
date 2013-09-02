require File.dirname(__FILE__) + '/timecard'
require 'date'

class Consultant
  def initialize id, last_name, first_name, grade, beeline_guid, project_name, first_billable_date, rolloff_date, timecards = {}
    @id = id
    @last_name = last_name
    @first_name = first_name
    @grade = grade
    @beeline_guid = beeline_guid
    @project = project_name
    @first_billable_date = first_billable_date
    @rolloff_date = rolloff_date
    @timecards = timecards
    @parse_object_id = nil
  end

  attr_reader :id, :beeline_guid, :first_name, :last_name, :project, :grade, :first_billable_date, :rolloff_date, :timecards
  attr_accessor :parse_object_id

  def timecard_end_dates
    end_dates = Set.new
    @timecards.each do |week_ending_date, timecard|
      end_dates << week_ending_date
    end

    end_dates
  end

  def add_timecard week_ending_date
    if timecard_end_dates.include? week_ending_date
      raise "Timecard already exists!"
    end
    @timecards[week_ending_date] = Timecard.new(week_ending_date, @rolloff_date, @first_billable_date)
  end

  def find_timecard week_ending_date
    @timecards[week_ending_date]
  end

  def time_submitted week_ending_date, hours_submitted
    @timecards[week_ending_date].hours_submitted = hours_submitted
  end

  def timecard_failed week_ending_date
    @timecards[week_ending_date].submit_failed
  end

  def timecard_state week_ending_date
    @timecards[week_ending_date].state
  end

  def total_hours_needed
    hours_worked = @timecards.inject(0) {|total, (week_ending, timecard)| total + timecard.hours_worked }
    hours_submitted = @timecards.inject(0) {|total, (week_ending, timecard)| total + timecard.hours_submitted }

    hours_worked - hours_submitted
  end

  def total_hours_worked
    @timecards.inject(0) {|total, (week_ending, timecard)| total + timecard.hours_worked }
  end

  def total_hours_submitted
    @timecards.inject(0) {|total, (week_ending, timecard)| total + timecard.hours_submitted }
  end

  def hours_to_enter week_ending_date
    return 0 if @timecards[week_ending_date].state == :SUBMITTED

    total_hours_needed <= 80 ? total_hours_needed : 80
  end

  def timecard_for_entry week_ending_date
    return nil if (week_ending_date > @rolloff_date) && (week_ending_date - @rolloff_date > 7)
    raise "Timecard does not exist" if @timecards[week_ending_date].nil?

    {"first_name" => @first_name,
     "last_name" => @last_name,
     "beeline_guid" => @beeline_guid,
     "project" => @project,
     "hours_to_enter" => hours_to_enter(week_ending_date),
     "hours_needed" => total_hours_needed,
     "hours_submitted" => @timecards[week_ending_date].hours_submitted,
     "state" => @timecards[week_ending_date].state
    }
  end

  def to_hash
    timecard_hashes = []
    @timecards.each do |week_ending_date, timecard|
      timecard_hashes << timecard.to_hash
    end

    {:id => @id,
     :last_name => @last_name,
     :first_name => @first_name,
     :grade => @grade,
     :beeline_guid => @beeline_guid,
     :project => @project,
     :first_billable_date => @first_billable_date.to_s,
     :rolloff_date => @rolloff_date.to_s,
     :timecards => timecard_hashes,
     :hours_needed => total_hours_needed,
     :total_hours_worked => total_hours_worked,
     :total_hours_submitted => total_hours_submitted
     }
  end

  def self.from_hash consultant_hash
    timecards = {}
    if consultant_hash["timecards"] then
      rolloff_date = Date.parse(consultant_hash["rolloff_date"])
      first_billable_date = Date.parse(consultant_hash["first_billable_date"])
      consultant_hash["timecards"].each do |timecard_hash|
        week_ending_date = Date.parse(timecard_hash["week_ending"])
        timecard = Timecard.new(week_ending_date, rolloff_date, first_billable_date)
        if timecard_hash["hours_submitted"].to_i > 0 then
          timecard.hours_submitted = timecard_hash["hours_submitted"]
        end
        timecards[week_ending_date] = timecard
      end
    end

    consultant = Consultant.new consultant_hash["id"],
                   consultant_hash["last_name"],
                   consultant_hash["first_name"],
                   consultant_hash["grade"],
                   consultant_hash["beeline_guid"],
                   consultant_hash["project"],
                   Date.parse(consultant_hash["first_billable_date"]),
                   Date.parse(consultant_hash["rolloff_date"]),
                   timecards
    consultant.parse_object_id = consultant_hash["objectId"]
    consultant
  end
end