$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + '../lib')

require 'rspec'
require '../lib/consultant'
require 'json'

describe 'Safe behavior' do
  it 'should not add a timecard if one exists for the given time period' do
    consultant = Consultant.new "khickey", "Hickey", "Kevin", "lead", "12345678", "FAR117", Date.new(2012, 8, 1), Date.new(2014, 12, 31)
    ending_date = Date.new(2013, 06, 30)
    consultant.add_timecard ending_date
    expect { consultant.add_timecard(ending_date) }.to raise_error
  end

end

describe 'Listing timecard dates' do
  before :each do
    @consultant = Consultant.new "khickey", "Hickey", "Kevin", "lead", "12345678", "FAR117", Date.new(2012, 8, 1), Date.new(2014, 12, 31)
  end

  it 'should return empty set if no timecards' do
    @consultant.timecard_end_dates.should == Set.new
  end

  it 'should include all timecards if any are present' do
    first_end_date = Date.new(2013, 6, 30)
    second_end_date = Date.new(2013, 7, 7)
    @consultant.add_timecard first_end_date
    @consultant.add_timecard second_end_date

    expected_set = Set.new
    expected_set.add first_end_date
    expected_set.add second_end_date

    @consultant.timecard_end_dates.should == expected_set
  end
end

describe 'Converting to Hash' do
  before :each do
    @first_billable_date = Date.new(2012, 8, 1)
    @rolloff_date = Date.new(2014, 12, 31)
    @consultant = Consultant.new "khickey", "Hickey", "Kevin", "lead", "12345678", "FAR117", @first_billable_date, @rolloff_date
  end

  it 'should include the id' do
    @consultant.to_hash[:id].should == "khickey"
  end

  it 'should include the last name' do
     @consultant.to_hash[:last_name].should == "Hickey"
  end

  it 'should include the first name' do
    @consultant.to_hash[:first_name].should == "Kevin"
  end

  it 'should include the beeline GUID' do
    @consultant.to_hash[:beeline_guid].should == "12345678"
  end

  it 'should include the project name' do
    @consultant.to_hash[:project].should == "FAR117"
  end

  it 'should include an empty array of timecards if none added' do
    @consultant.to_hash[:timecards].should == []
  end

  it 'should include the first billable date' do
    @consultant.to_hash[:first_billable_date].should == "2012-08-01"
  end

  it 'should include the rolloff date' do
    @consultant.to_hash[:rolloff_date].should == "2014-12-31"
  end

  it 'should include the consultants grade' do
    @consultant.to_hash[:grade].should == "lead"
  end

  it 'should include timecards if any are added' do
    first_end_date = Date.new(2013, 6, 30)
    second_end_date = Date.new(2013, 7, 7)
    @consultant.add_timecard first_end_date
    @consultant.add_timecard second_end_date
    first_timecard = Timecard.new first_end_date, @rolloff_date, @first_billable_date
    second_timecard = Timecard.new second_end_date, @rolloff_date, @first_billable_date

    @consultant.to_hash[:timecards].include?(first_timecard.to_hash).should == true
    @consultant.to_hash[:timecards].include?(second_timecard.to_hash).should == true
  end

  it 'should set hours needed to total hours worked when no time submitted' do
    first_end_date = Date.new(2013, 6, 30)
    second_end_date = Date.new(2013, 7, 7)
    @consultant.add_timecard first_end_date
    @consultant.add_timecard second_end_date

    @consultant.to_hash[:hours_needed].should == 80
  end

  it 'should set hours needed to total hours worked less total hours submitted' do
    first_end_date = Date.new(2013, 6, 30)
    second_end_date = Date.new(2013, 7, 7)
    @consultant.add_timecard first_end_date
    @consultant.add_timecard second_end_date

    @consultant.time_submitted first_end_date, 40
    @consultant.to_hash[:hours_needed].should == 40
  end
end

describe 'Initializing from hash' do
  before :each do
    @hash = {"id" => "khickey", "first_name" => "Kevin", "last_name" => "Hickey", "grade" => "lead", "beeline_guid" => "12345678", "project" => "FAR117", "first_billable_date"=>"2012-08-01", "rolloff_date"=>"2014-12-31"}
  end

  it 'should initialize from hash with basic fields and no timecards' do
    consultant = Consultant.from_hash @hash
    consultant.id.should eq("khickey")
    consultant.first_name.should eq("Kevin")
    consultant.last_name.should eq("Hickey")
    consultant.beeline_guid.should eq("12345678")
    consultant.project.should eq("FAR117")
    consultant.first_billable_date.should eq(Date.new(2012,8,1))
    consultant.rolloff_date.should eq(Date.new(2014,12,31))
    consultant.grade.should eq("lead")
  end

  it 'should add an empty array for timecards if none are present' do
    @consultant = Consultant.from_hash @hash
    @consultant.timecards.should eq({})
  end

end

describe 'Timecard for entry' do
  before :each do
    @first_billable_date = Date.new(2012, 8, 1)
    @rolloff_date = Date.new(2013, 12, 31)
    @beeline_guid = "12345678"
    @consultant = Consultant.new "khickey", "Hickey", "Kevin", "lead", @beeline_guid, "FAR117", @first_billable_date, @rolloff_date
  end

  it 'should generate a timecard hash for a week ending date for which a timecard exists' do
    week_ending_date = Date.new(2013, 8, 25)
    @consultant.add_timecard(week_ending_date)
    expected = {"first_name" => "Kevin", "last_name" => "Hickey", "beeline_guid" => @beeline_guid, "project" => "FAR117", "hours_to_enter" => 40, "hours_needed" => 40, "hours_submitted" => 0, "state" => :UNSUBMITTED}

    @consultant.timecard_for_entry(week_ending_date).should eq(expected)
  end

  it 'should raise an exception for a week ending date that does not exist' do
    week_ending_date = Date.new(2013, 8, 25)
    expect { @consultant.timecard_for_entry(week_ending_date) }.to raise_error("Timecard does not exist")
  end

  it 'should generate a nil response for a timecard after the week containing the rolloff date' do
    week_ending_date = Date.new(2014, 01, 12)
    @consultant.add_timecard(week_ending_date)

    @consultant.timecard_for_entry(week_ending_date).should eq(nil)
  end

  it 'should generate a timecard hash for the week ending containing the rolloff date' do
    week_ending_date = Date.new(2014, 01, 05)
    @consultant.add_timecard(week_ending_date)
    expected = {"first_name" => "Kevin", "last_name" => "Hickey", "beeline_guid" => @beeline_guid, "project" => "FAR117", "hours_to_enter" => 16, "hours_needed" => 16, "hours_submitted" => 0, "state" => :UNSUBMITTED}

    @consultant.timecard_for_entry(week_ending_date).should eq(expected)
  end

end

describe 'Hours to enter calculation' do
  before :each do
    @first_billable_date = Date.new(2012, 8, 1)
    @rolloff_date = Date.new(2013, 12, 31)
    @beeline_guid = "12345678"
    @consultant = Consultant.new "khickey", "Hickey", "Kevin", "lead", @beeline_guid, "FAR117", @first_billable_date, @rolloff_date
  end

  it 'should be 0 if the timecard state is SUBMITTED' do
    week_ending_date = Date.new(2013, 8, 25)
    @consultant.add_timecard week_ending_date
    @consultant.time_submitted week_ending_date, 40

    @consultant.timecard_for_entry(week_ending_date)["hours_to_enter"].should eq(0)
  end

  it 'should be the total hours needed for a normal week' do
    week_ending_date = Date.new(2013, 8, 25)
    @consultant.add_timecard week_ending_date

    @consultant.timecard_for_entry(week_ending_date)["hours_to_enter"].should eq(@consultant.total_hours_needed)
  end

  it 'should limit to 80 hours if more than 80 are needed' do
    week_ending_date = Date.new(2013, 9, 8)
    @consultant.add_timecard Date.new(2013, 8, 25)
    @consultant.add_timecard Date.new(2013, 9, 1)
    @consultant.add_timecard week_ending_date

    @consultant.timecard_for_entry(week_ending_date)["hours_to_enter"].should eq(80)
  end
end

describe 'Hours worked calculation' do
  before :each do
    Consultant.first_day_of_project = Date.new(2011, 1, 1)
  end

  it 'should limit to 160 hours for a complete month worked in the past' do
    first_billable_date = Date.new(2013, 7, 1)
    rolloff_date = Date.new(2013, 7, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    consultant.hours_worked_as_of(Date.new(2013, 7, 31)).should eq(160)
  end

  it 'should total 8 times the number of weekdays on for a month where the first billable date is after the first' do
    first_billable_date = Date.new(2013, 7, 8)
    rolloff_date = Date.new(2013, 7, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    consultant.hours_worked_as_of(Date.new(2013, 7, 31)).should eq(18 * 8)
  end

  it 'should total 8 times the number of weekdays on for a month where the rolloff date is before the end of the month' do
    first_billable_date = Date.new(2013, 7, 1)
    rolloff_date = Date.new(2013, 7, 19)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    consultant.hours_worked_as_of(Date.new(2013, 7, 31)).should eq(15 * 8)
  end

  it 'should only count time up to the requested date if the requested date falls before the rolloff date' do
    first_billable_date = Date.new(2013, 7, 1)
    rolloff_date = Date.new(2013, 7, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    consultant.hours_worked_as_of(Date.new(2013, 7, 19)).should eq(15 * 8)
  end

  it 'should calculate correctly spanning months with all complete months' do
    first_billable_date = Date.new(2012, 11, 1)
    rolloff_date = Date.new(2014, 12, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    consultant.hours_worked_as_of(Date.new(2013, 7, 31)).should eq(160 * 9)
  end

  it 'should calculate correctly spanning months with and incomplete beginning month' do
    first_billable_date = Date.new(2012, 11, 18)
    rolloff_date = Date.new(2014, 12, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    hours_worked_for_complete_months = 160 * 8
    hours_worked_in_first_month = 10 * 8
    expected_hours_worked = hours_worked_for_complete_months + hours_worked_in_first_month
    consultant.hours_worked_as_of(Date.new(2013, 7, 31)).should eq(expected_hours_worked)
  end

  it 'should calculate correctly spanning months with and incomplete ending month' do
    first_billable_date = Date.new(2012, 11, 1)
    rolloff_date = Date.new(2014, 12, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    hours_worked_for_complete_months = 160 * 8
    hours_worked_in_last_month = 15 * 8
    expected_hours_worked = hours_worked_for_complete_months + hours_worked_in_last_month
    consultant.hours_worked_as_of(Date.new(2013, 7, 19)).should eq(expected_hours_worked)
  end

  it 'should calculate correctly spanning months with and incomplete first and last month' do
    first_billable_date = Date.new(2012, 11, 18)
    rolloff_date = Date.new(2014, 12, 31)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    hours_worked_for_complete_months = 160 * 7
    hours_worked_in_first_month = 10 * 8
    hours_worked_in_last_month = 15 * 8
    expected_hours_worked = hours_worked_for_complete_months + hours_worked_in_first_month + hours_worked_in_last_month
    consultant.hours_worked_as_of(Date.new(2013, 7, 19)).should eq(expected_hours_worked)
  end

  it 'should use the first date of project as the beginning if it is after the first billable date' do
    first_billable_date = Date.new(2012, 11, 18)
    rolloff_date = Date.new(2014, 12, 31)
    Consultant.first_day_of_project = Date.new(2013, 7, 1)

    consultant = Consultant.new "", "", "", "", "", "", first_billable_date, rolloff_date

    expected_hours_worked = 160 + 160 + 80
    consultant.hours_worked_as_of(Date.new(2013, 9, 15)).should eq(expected_hours_worked)
  end
end