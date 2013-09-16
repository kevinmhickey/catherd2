$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)) + '../lib')

require 'rspec'
require '../lib/date_range'

describe 'Months covered by' do

  it 'should calculate the number of months covered by a date range within the same year' do
    range = DateRange.new Date.new(2012, 1, 1), Date.new(2012, 7, 31)
    range.months_covered.should eq(7)
  end

  it 'should calculate the number of months covered by a date range spanning two years' do
    range = DateRange.new Date.new(2012, 11, 1), Date.new(2013, 3, 31)
    range.months_covered.should eq(5)
  end

  it 'should calculate the number of months covered by a date range spanning more than 2 years' do
    range = DateRange.new Date.new(2011, 11, 1), Date.new(2014, 3, 31)
    range.months_covered.should eq(29)
  end

  it 'should calculate the number of complete months covered for a range starting after the first of a month' do
    range = DateRange.new Date.new(2012, 1, 15), Date.new(2012, 7, 31)
    range.complete_months_covered.should eq(6)
  end

  it 'should calculate the number of complete months covered for a range ending before the last of a month' do
    range = DateRange.new Date.new(2012, 1, 1), Date.new(2012, 7, 28)
    range.complete_months_covered.should eq(6)
  end

end

describe 'Weekdays covered by' do
  it 'should count the number of weekdays [M-F] covered by a range' do
    range = DateRange.new Date.new(2013, 7, 1), Date.new(2013, 7, 31)
    range.weekdays_covered.should eq(23)
  end
end