require 'rspec'
require '../lib/timecard'

describe 'Hours Calculation' do

  before :each do
    @first_billable_date = Date.new(2013, 1, 1)
    @week_ending_date = Date.new(2013, 6, 30)
    @rolloff_date = Date.new(2014, 1, 1)
  end

  it 'should have 40 hours worked if the consultant is on for the whole week' do
    timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
    timecard.hours_worked.should == 40
  end

  it 'should have 0 hours worked if the consultant rolled off before the week' do
    @rolloff_date = Date.new(2013, 2, 1)

    timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
    timecard.hours_worked.should == 0
  end

  it 'should have 24 hours worked if the consultant rolled off on Thursday' do
    @rolloff_date = Date.new(2013, 6, 27)

    timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
    timecard.hours_worked.should == 32
  end

  it 'should have 0 hours if the consultant rolled on after the week' do
    @first_billable_date = Date.new(2013, 8, 1)

    timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
    timecard.hours_worked.should == 0
  end

  it 'should have 16 hours if the consultant started on Tuesday' do
    @first_billable_date = Date.new(2013, 6, 25)
  end
end

describe 'Convert to Hash' do
  before :each do
    @first_billable_date = Date.new(2013, 1, 1)
    @week_ending_date = Date.new(2013, 6, 30)
    @rolloff_date = Date.new(2014, 1, 1)

    @timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
  end

  it 'should include week ending date' do
    @timecard.to_hash[:week_ending].should == "2013-06-30"
  end

  it 'should include hours worked' do
    @timecard.to_hash[:hours_worked].should == 40
  end

  it 'should include hours submitted as 0 if no hours submitted' do
    @timecard.to_hash[:hours_submitted].should == 0
  end

  it 'should include hours submitted if any hours submitted' do
    @timecard.hours_submitted = 40
    @timecard.to_hash[:hours_submitted].should == 40
  end

  it 'should include the state as UNSUBMITTED if no hours submitted' do
    @timecard.to_hash[:state].should eq "UNSUBMITTED"
  end
end

describe 'States' do
  before :each do
    @first_billable_date = Date.new(2013, 1, 1)
    @week_ending_date = Date.new(2013, 6, 30)
    @rolloff_date = Date.new(2014, 1, 1)

    @timecard = Timecard.new @week_ending_date, @rolloff_date, @first_billable_date
  end

  it 'should initialize to UNSUBMITTED' do
    @timecard.state.should eq :UNSUBMITTED
  end

  it 'should change to SUBMITTED if any hours submitted' do
    @timecard.hours_submitted = 40
    @timecard.state.should eq :SUBMITTED
  end

  it 'should change to FAILED if hour submission failed' do
    @timecard.submit_failed
    @timecard.state.should eq :FAILED
  end
end