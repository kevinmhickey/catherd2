require 'rspec'
require '../lib/herd'
require '../lib/consultant'
require '../lib/always_successful_timecard_submitter'
require '../lib/dummy_repository'

describe 'Enter Time' do
  before :each do
    @herd = Herd.new DummyRepository.new({})
    @sheldon_beeline_guid = "123456789"
    @amy_beeline_guid = "987654321"

    @sheldon_cooper = Consultant.new "scooper", "Cooper", "Sheldon", "lead", @sheldon_beeline_guid, "monopoles", Date.new(2013, 05, 11), Date.new(2014, 05, 11)
    @amy_fowler = Consultant.new "sfowler", "Fowler", "Amy", "lead", @amy_beeline_guid, "brains", Date.new(2013, 05, 11), Date.new(2014, 05, 11)

    @herd.add @sheldon_cooper
    @herd.add @amy_fowler

    @week_ending_date = Date.new(2013, 8, 25)
    @sheldon_cooper.add_timecard @week_ending_date
    @amy_fowler.add_timecard @week_ending_date

  end

  it 'should mark selected timecards as submitting' do
    @herd.mark_as_submitting @week_ending_date, [@sheldon_beeline_guid]

    @sheldon_cooper.timecards[@week_ending_date].state.should eq(:SUBMITTING)
    @amy_fowler.timecards[@week_ending_date].state.should_not eq(:SUBMITTING)
  end

  it 'should updated the consultant timecard with hours submitted and state :SUBMITTED if successful' do
    @herd.enter_timecards AlwaysSuccessfulTimecardSubmitter.new, @week_ending_date, {@sheldon_beeline_guid => 40}

    @sheldon_cooper.timecards[@week_ending_date].state.should eq(:SUBMITTED)
    @sheldon_cooper.timecards[@week_ending_date].hours_submitted.should eq(40)
    @amy_fowler.timecards[@week_ending_date].state.should_not eq(:SUBMITTING)
    @amy_fowler.timecards[@week_ending_date].hours_submitted.should eq(0)
  end
end

describe 'Get time to enter' do
  before :each do
    @herd = Herd.new DummyRepository.new({})
    @sheldon_beeline_guid = "123456789"
    @amy_beeline_guid = "987654321"

    @sheldon_cooper = Consultant.new "scooper", "Cooper", "Sheldon", "lead", @sheldon_beeline_guid, "monopoles", Date.new(2013, 05, 11), Date.new(2014, 05, 11)
    @amy_fowler = Consultant.new "sfowler", "Fowler", "Amy", "lead", @amy_beeline_guid, "brains", Date.new(2013, 05, 11), Date.new(2014, 01, 01)

    @herd.add @sheldon_cooper
    @herd.add @amy_fowler

    @week_ending_date = Date.new(2013, 8, 25)
    @another_week_ending_date = Date.new(2013, 9, 1)
    @sheldon_cooper.add_timecard @week_ending_date
    @sheldon_cooper.add_timecard @another_week_ending_date
    @amy_fowler.add_timecard @week_ending_date
    @amy_fowler.add_timecard @another_week_ending_date
  end

  it 'should get a list of all timecards for a given week ending date' do
    expected = [
        {"first_name" => "Sheldon", "last_name" => "Cooper", "beeline_guid" => @sheldon_beeline_guid, "project" => "monopoles", "hours_to_enter" => 80, "hours_needed" => 80, "hours_submitted" => 0, "state" => :UNSUBMITTED},
        {"first_name" => "Amy", "last_name" => "Fowler", "beeline_guid" => @amy_beeline_guid, "project" => "brains", "hours_to_enter" => 80, "hours_needed" => 80, "hours_submitted" => 0, "state" => :UNSUBMITTED}
    ]

    @herd.get_timecards_for_entry(@week_ending_date).should eq(expected)
  end

  it 'should not include timecards for consultants with no time to enter' do
    expected = [
        {"first_name" => "Sheldon", "last_name" => "Cooper", "beeline_guid" => @sheldon_beeline_guid, "project" => "monopoles", "hours_to_enter" => 80, "hours_needed" => 120, "hours_submitted" => 0, "state" => :UNSUBMITTED},
    ]

    week_ending_date_after_amys_rolloff = Date.new(2014, 01, 12)
    @sheldon_cooper.add_timecard week_ending_date_after_amys_rolloff
    @amy_fowler.add_timecard week_ending_date_after_amys_rolloff

    @herd.get_timecards_for_entry(week_ending_date_after_amys_rolloff).should eq(expected)

  end
end