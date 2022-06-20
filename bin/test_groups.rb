#!/usr/bin/env ruby

# Program:     test_groups.rb
# Written by:  Jeremy Zehr
# Purpose:     Test the webtrans tutorial

=begin

usage: ./test_groups

Tests group creation, listing and destruction
Requires admin access:
set the environment variables WEBTRANS_USERNAME and WEBTRANS_PASSWORD for login

=end

require 'capybara'
require 'capybara/dsl'
require 'selenium/webdriver'
require 'securerandom'

# FIREFOX
if false
  Capybara.register_driver :firefox do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    # profile['browser.download.dir'] = DOWNLOADDIR
    # profile['browser.download.folderList'] = 2 # 2 - save to user defined location
    # profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/tab-separated-values'
    Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
  end
  Capybara.current_driver = :firefox
end

# CHROME / CHROMIUM
if true
  # Selenium::WebDriver::Chrome::Service.driver_path = "/usr/lib/chromium-browser/chromedriver" # Jeremy uses chromium
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_option(:useAutomationExtension, false)
    # options.add_preference(:download, directory_upgrade: true, prompt_for_download: false, default_directory: DOWNLOADDIR)
    # options.add_preference('download.default_directory', DOWNLOADDIR)
    # options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })  
    driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    driver
  end
  Capybara.current_driver = :chrome
end
  
class GroupTest
  include Capybara::DSL

  GroupName = SecureRandom.alphanumeric
  NewGroupName = SecureRandom.alphanumeric

  def start
    username = ENV['WEBTRANS_USERNAME']
    password = ENV['WEBTRANS_PASSWORD']
    visit 'http://localhost:3005/'
    fill_in('session_name', with: username)
    fill_in('session_password', with: password)
    click_on 'Sign in'
    if page.has_css?("input[value='Confirm']")
      fill_in('session_password', with: password)
      click_on 'Confirm'
    end
    find(".tabnav-tab",text:"Groups", exact_text: true).click
    puts "Found tab 'Groups' and clicked on it"
  end

  def test_create
    find(".btn div", text: "Create group", exact_text: true).click
    find(".form-group input").send_keys(GroupName)
    click_on "Save"
    flash = find('.flash-success', text: "created #{GroupName}", exact_text: true)
    flash.find('button').click
    puts "Group '#{GroupName}' created"
    puts "CREATE: Success"
  end

  def test_index
    find(".d-table .d-table-cell:first-child", text: GroupName, exact_text: true)
    puts "Found '#{GroupName}' in the list of groups "
    puts "INDEX: Success"
  end

  def test_show
    find(".d-table .d-table-cell:first-child", text: GroupName, exact_text: true).click
    click_on "Open", match: :first
    find(".tabnav-tab",text:"Group Info", exact_text: true)
    puts "Found and opened '#{GroupName}'"
    puts "SHOW: Success"
  end

  def test_update
    find(".tabnav-tab",text:"Group Info", exact_text: true).click
    input = find(".form-group-body input")
    input.value.length.times { input.send_keys [:backspace] }
    input.send_keys(NewGroupName)
    find("p.note.success", text: "updated name to #{NewGroupName}", exact_text: true)
    click_on "Return to Group list"
    puts "Renamed '#{GroupName}' into '#{NewGroupName}"
    puts "UPDATE: Success"
  end

  def test_delete
    find(".d-table .d-table-cell:first-child", text: NewGroupName, exact_text: true).click
    find(".btn div", text: "Delete", exact_text: true).click
    click_on "DELETE"
    flash = find('.flash-success', text: "Group #{NewGroupName} has been deleted.", exact_text: true)
    flash.find('button').click
    puts "Deleted '#{NewGroupName}'"
    puts "DELETE: Success"
  end

  def run
    start
    test_create
    test_index
    test_show
    test_update
    test_delete
  end
end


tst = GroupTest.new
tst.run
