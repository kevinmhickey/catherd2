require 'date'

class DateRange
  def initialize beginning, ending
    @beginning = beginning
    @ending = ending
  end

  def months_covered
    if @beginning.year != @ending.year then
      covered = (@ending.year - @beginning.year - 1) * 12
      covered += 12 - @beginning.month + 1
      covered += @ending.month
    else
      covered = @ending.month - @beginning.month + 1
    end

    covered
  end

  def complete_months_covered
    covered = months_covered
    covered -= 1 if @beginning.day > 1
    covered -= 1 if ((@ending + 1).month == @ending.month)

    covered
  end

  def weekdays_covered
    weekdays = [1,2,3,4,5]
    (@beginning..@ending).to_a.select {|day| weekdays.include?(day.wday())}.size
  end
end