
class Billable_Person
  def initialize driver, last, first, guid, hours
    @driver = driver
    @name = "#{first} #{last}"
    @guid = guid
    @hours = hours
  end

  attr_reader :guid, :name, :hours

  def open_search_page
    @driver.get "https://prod.beeline.com/pwc/Admin/Security/Admin/MyOrganizationUserListScreen.ascx?IncludeSupplierResources=1&bc="
  end

  def search_for_guid
    @driver.find_element(:id, "Master_PageContentPlaceHolder_screen_userList_beelineForm_userNameText").clear
    @driver.find_element(:id, "Master_PageContentPlaceHolder_screen_userList_beelineForm_userNameText").send_keys @guid
    @driver.find_element(:css, "a.BeelineFormFilter").click
  end

  def select_impersonate
    @driver.find_element(:xpath, "(//input[@id='Master_PageContentPlaceHolder_screen_userList_selectionList_Check'])[2]").click
    @driver.find_element(:id, "Master_topDefaultActionLinks_action2").click
  end

  def impersonate
    open_search_page
    search_for_guid
    select_impersonate
  end

  def stop_impersonating
    @driver.find_element(:id, "HeaderCurrentImpersonatorNameLink").click
    @driver.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError
  end

  def to_s
    "#{@name}: #{@guid}"
  end
end
  

