require File.dirname(__FILE__) + '/timecard'
require 'date'

class Consultant
  def initialize id, last_name, first_name, grade, beeline_guid, first_billable_date, rolloff_date
    @id = id
    @last_name = last_name
    @first_name = first_name
    @grade = grade
    @beeline_guid = beeline_guid
    @first_billable_date = first_billable_date
    @rolloff_date = rolloff_date
    @timecards = []
  end

  attr_reader :id, :beeline_guid, :first_name, :last_name, :grade, :first_billable_date, :rolloff_date, :timecards

  def timecard_end_dates
    end_dates = Set.new
    @timecards.each do |timecard|
      end_dates << timecard.week_ending_date
    end

    end_dates
  end

  def add_timecard week_ending_date
    if timecard_end_dates.include? week_ending_date
      raise "Timecard already exists!"
    end
    @timecards << Timecard.new(week_ending_date, @rolloff_date, @first_billable_date)
  end

  def time_submitted week_ending_date, hours_submitted
    @timecards.find {|timecard| timecard.week_ending_date == week_ending_date}.hours_submitted = hours_submitted
  end

  def total_hours_needed
    hours_worked = @timecards.inject(0) {|total, timecard| total + timecard.hours_worked }
    hours_submitted = @timecards.inject(0) {|total, timecard| total + timecard.hours_submitted }

    hours_worked - hours_submitted
  end

  def total_hours_worked
    @timecards.inject(0) {|total, timecard| total + timecard.hours_worked }
  end

  def total_hours_submitted
    @timecards.inject(0) {|total, timecard| total + timecard.hours_submitted }
  end

  def to_hash
    timecard_hashes = []
    @timecards.each do |timecard|
      timecard_hashes << timecard.to_hash
    end

    {:id => @id,
     :last_name => @last_name,
     :first_name => @first_name,
     :grade => @grade,
     :beeline_guid => @beeline_guid,
     :first_billable_date => @first_billable_date.to_s,
     :rolloff_date => @rolloff_date.to_s,
     :timecards => timecard_hashes,
     :hours_needed => total_hours_needed,
     :total_hours_worked => total_hours_worked,
     :total_hours_submitted => total_hours_submitted
     }
  end

  def self.from_hash consultant_hash
    Consultant.new consultant_hash["id"],
                   consultant_hash["last_name"],
                   consultant_hash["first_name"],
                   consultant_hash["grade"],
                   consultant_hash["beeline_guid"],
                   Date.parse(consultant_hash["first_billable_date"]),
                   Date.parse(consultant_hash["rolloff_date"])
  end

end