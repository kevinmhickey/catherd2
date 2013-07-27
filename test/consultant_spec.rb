$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + '../lib')

require 'rspec'
require File.dirname(__FILE__) + '/../lib/consultant'
require 'json'

describe 'Safe behavior' do
  it 'should not add a timecard if one exists for the given time period' do
    consultant = Consultant.new "Hickey", "Kevin", "12345678", Date.new(2012, 8, 1), Date.new(2014, 12, 31)
    ending_date = Date.new(2013, 06, 30)
    consultant.add_timecard ending_date
    expect { consultant.add_timecard(ending_date) }.to raise_error
  end

end

describe 'Listing timecard dates' do
  before :each do
    @consultant = Consultant.new "Hickey", "Kevin", "12345678", Date.new(2012, 8, 1), Date.new(2014, 12, 31)
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
    @consultant = Consultant.new "Hickey", "Kevin", "12345678", @first_billable_date, @rolloff_date
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

  it 'should include an empty array of timecards if none added' do
    @consultant.to_hash[:timecards].should == []
  end

  it 'should include the first billable date' do
    @consultant.to_hash[:first_billable_date].should == "2012-08-01"
  end

  it 'should include the rolloff date' do
    @consultant.to_hash[:rolloff_date].should == "2014-12-31"
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
    @hash = {"first_name" => "Kevin", "last_name" => "Hickey", "beeline_guid" => "12345678", "first_billable_date"=>"2012-08-01", "rolloff_date"=>"2014-12-31"}
  end

  it 'should initialize from hash with basic fields and no timecards' do
    consultant = Consultant.from_hash @hash
    consultant.first_name.should eq("Kevin")
    consultant.last_name.should eq("Hickey")
    consultant.beeline_guid.should eq("12345678")
    consultant.first_billable_date.should eq(Date.new(2012,8,1))
    consultant.rolloff_date.should eq(Date.new(2014,12,31))
  end

  it 'should add an empty array for timecards if none are present' do
    @consultant = Consultant.from_hash @hash
    @consultant.timecards.should eq([])
  end

end