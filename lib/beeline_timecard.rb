require 'date'
require 'selenium-webdriver'

class BeelineTimecard
  def self.find_next_sunday start_date
    until start_date.sunday? do
        start_date = start_date.next_day
    end
    start_date
  end

  def initialize driver
    @wait = Selenium::WebDriver::Wait.new(:timeout => 15) # seconds
    @driver = driver
    @current_week_ending = BeelineTimecard.find_next_sunday Date.today
    @sequence = 0
  end

  def next_sequence
    xpath = ".//*[contains(@id, 'Assignment_0_AssignmentDetail_0_TimesheetRowGroup') and contains(@id, 'EntryTextBox_0') and not(contains(@id, 'Group_0'))]"
    @wait.until { @driver.find_element(:xpath, xpath).displayed? }
    /Group_(?'sequence'\d)/.match(@driver.find_element(:xpath, xpath).attribute(:id))[:sequence]
  end

  def select week_ending
    current_week_ending_string = @current_week_ending.strftime "%-m_%-d_%Y"
    week_ending_string = week_ending.strftime "%-m_%-d_%Y"
    @wait.until { @driver.find_element(:id, "Assignment_0_AssignmentDetail_0_TimesheetRowGroup_#{@sequence}_Task_0_ProjectComboSelector_Input").displayed? }
    @driver.find_element(:id, "timesheetSelectorItem_#{current_week_ending_string}_Detail").click
    @driver.find_element(:id, "timesheetSelectorItem_#{week_ending_string}_Detail").click
    sleep 10
    @current_week_ending = week_ending
    @sequence = next_sequence
  end

  def enter_time project, hours_per_day
    clear_and_type "Assignment_0_AssignmentDetail_0_TimesheetRowGroup_#{@sequence}_Task_0_ProjectComboSelector_Input", project
    clear_and_type "Assignment_0_AssignmentDetail_0_TimesheetRowGroup_#{@sequence}_Task_0_ProjectTypeComboSelector_Input", "Time and Materials"

    5.times do |day|
        @driver.find_element(:id, "Assignment_0_AssignmentDetail_0_TimesheetRowGroup_#{@sequence}_Task_0_EntryTextBox_#{day}").click
        @driver.find_element(:id, "timesheetEntryControl_EntryTextBox").send_keys hours_per_day[day]
    end
  end

  def submit
    @driver.find_element(:id, "submitTimesheetButton").click
    @driver.find_element(:xpath, "(//button[@type='button'])[2]").click
    @wait.until { @driver.find_element(:id => "editTimesheetButton").displayed? }
  end

  def clear_and_type id, input
    @driver.find_element(:id, id).clear
    @driver.find_element(:id, id).send_keys input
  end
  
end


