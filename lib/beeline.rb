$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))) 

require "selenium-webdriver"
require 'beeline_timecard'
require 'billable_person'

class Beeline
    @@PROJECT_CODE = "00623036001"

    def initialize
        @driver = Selenium::WebDriver.for :firefox
        @driver.manage.timeouts.implicit_wait = 15
        @driver.get "https://prod.beeline.com/pwc"
        @driver.find_element(:id, "beelineForm_userNameText").send_keys("khickey@thoughtworks.com")
        @driver.find_element(:id, "beelineForm_passwordText").send_keys("ThoughtWorks01")
        @driver.find_element(:id, "defaultActionLinks_loginAction").click
    end

    def impersonate guid
        billable_person = Billable_Person.new @driver, "last", "first", guid, 0
        billable_person.impersonate
    end

    def stop_impersonating
        billable_person = Billable_Person.new @driver, "last", "first", "guid", 0
        billable_person.stop_impersonating
    end

    def enter_time week_ending_date, hours_for_week
        t = BeelineTimecard.new @driver
        if (hours_for_week <= 40)
          hours_per_day = [8] * (hours_for_week / 8)
        else
          hours_per_day = [hours_for_week / 5] * 5
        end

        t.select week_ending_date
        t.enter_time @@PROJECT_CODE, hours_per_day
        #t.submit
    end

    def close
      @driver.quit
    end
end
