#!/usr/bin/env ruby

# Program:     test_webtrans_tutorial.rb
# Written by:  Jeremy Zehr
# Purpose:     Test the webtrans tutorial

=begin

usage: ./test_webtrans_tutorial [ full | N | --from N ]

Tries to run the webtrans tutorial's steps.
If no argument is passed, it will run the user's current step only.
If _full_ is passed, it will reset the tutorial and attempt a full runthrough.
If _N_ is passed, it will run the N-th step only.
If _--from N_ is passed, it will run from the N-th step through the last step.

Set the environment variables WEBTRANS_USERNAME and WEBTRANS_PASSWORD for login

=end

require 'capybara'
require 'capybara/dsl'
require 'selenium/webdriver'
require 'digest/sha1'

FILENAME = 'transcript.tsv'
DOWNLOADDIR = Dir.pwd.gsub(/\/[^\/]+$/,'/tmp')
FILEPATH = File.join(DOWNLOADDIR,FILENAME)
LOGPATH = File.join(DOWNLOADDIR,'test_checksums.csv')
puts "filepath #{FILEPATH}, logpath #{LOGPATH}"

# FIREFOX
if false
  Capybara.register_driver :firefox do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['browser.download.dir'] = DOWNLOADDIR
    profile['browser.download.folderList'] = 2 # 2 - save to user defined location
    profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/tab-separated-values'
    Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
  end
  Capybara.current_driver = :firefox
end

# CHROME / CHROMIUM
# Selenium::WebDriver::Chrome::Service.driver_path = "/usr/lib/chromium-browser/chromedriver" # Jeremy uses chromium
if true
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_option(:useAutomationExtension, false)
    options.add_preference(:download, directory_upgrade: true, prompt_for_download: false, default_directory: DOWNLOADDIR)
    options.add_preference('download.default_directory', DOWNLOADDIR)
    options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })  
    driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    driver
  end
  Capybara.current_driver = :chrome
end
  
class TutorialClass
  include Capybara::DSL

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
    find("div[data-key='Tutorial'] a").click
  end

  def reset 
    click_on 'Reset'
    find("span.ui-button-text", text: "Reset").click
  end

  def jump_to(n)
    click_on 'Next' if page.has_css?("span.ui-button-text", text: "Next")
    sel = find(".guide select")
    on = n-1
    if sel.has_css?("option[value='#{on}']")
      sel.click
      sel.find("option[value='#{on}']").click
      sleep 0.5
      click_on 'Erase' if page.has_css?("span.ui-button-text", text: "Erase")
      puts "Jumped to step ##{n}"
    else
      puts "Could not find step ##{n}"
    end
  end

  def run_step(n)
    click_on 'Erase' if page.has_css?("span.ui-button-text", text: "Erase")
    sleep 0.5 # give more time for display refresh
    case n
    when 1
      step_welcome
    when 2
      step_intro_playback
    when 3
      step_navigation
    when 4
      step_create_segment
    when 5
      step_toggle
    when 6
      step_split_merge_1
    when 7
      step_split_merge_2
    when 8
      step_adjust_segments
    when 9  
      step_zoom
    when 10
      step_home_keys_1
    when 11
      step_home_keys_2
    when 12
      step_move_across_segments
    when 13
      step_help_general
    when 14
      step_help_sumbit
    when 15
      step_end
    else
      puts "Step #{n} not found, running full runthrough"
      full_runthrough
    end
  end

  def current_step
    option = find("select option:checked")
    return option.value
  end

  def stop_playback
    return unless evaluate_script("window.ldc_source.is_playing()")
    find(".node-waveform").click
    page.driver.browser.action.send_keys(' ').perform  # stop playback
  end

  def wait_playback
    loop do 
      sleep 0.25
      break unless evaluate_script("window.ldc_source.is_playing()")
    end
  end


  # STEPS
  #
  def step_welcome
    puts "Running step 1: welcome"
    click_on 'Next'
    find(".tooltip .submit").click # See bottom bar?
    puts "Step 1 (welcome) complete"
  end

  def step_intro_playback
    puts "Running step 2: intro and playback"
    click_on 'Next'
    find(".tooltip .submit").click # Represents audio file
    find(".tooltip .submit").click # Timeline
    find(".tooltip .submit").click # Filename
    find(".ChannelA").click # Click anywhere in waveform
    page.driver.browser.action.send_keys(' ').perform
    sleep 1 # 1s playback
    page.driver.browser.action.send_keys(' ').perform
    puts "Step 2 (intro & playback) complete"
  end

  def step_navigation
    puts "Running step 3: navigating the waveform"
    click_on 'Next'
    scrollbar = find(".waveform-scrollbar")
    sleep 0.5 # give time to properly display the scrollbar
    x = scrollbar.rect.x+2
    y = scrollbar.rect.y+2
    page.driver.browser.action.move_to_location(x,y)
                              .click_and_hold
                              .move_to_location(x+200, y)
                              .release
                              .perform
    sleep 0.5 # observe the effects of your action
    find(".tooltip .submit").click # feedback
    puts "Step 3 (navigating the waveform) complete"
  end

  def step_create_segment
    puts "Running step 4: create a segment"
    click_on 'Next'
    waveform = find(".node-waveform")
    waveform.click  # Make sure waveform
    sleep 0.5       # has focus
    x = waveform.rect.x+20
    y = waveform.rect.y+20
    page.driver.browser.action.move_to_location(x,y)
                              .click_and_hold
                              .move_to_location(x+50, y)
                              .release
                              .perform
    page.driver.browser.action.send_keys(' ').perform # listen to selection
    wait_playback
    sleep 1 # for some reason waiting 1s here seems to prevent a bug with chromium
    page.driver.browser.action.send_keys(:enter).perform # create segment
    wait_playback
    find(".transcript-input").send_keys("hello world",:enter) # transcribe
    wait_playback
    find(".underline_rect", match: :first).click # replay
    wait_playback
    click_on 'Next' # interim popup
    page.driver.browser.action.move_to_location(x+150, y)
                              .click_and_hold
                              .move_to_location(x+200, y)
                              .release
                              .perform  # create second segment
    page.driver.browser.action.send_keys(:enter).perform
    find(".transcript-input").send_keys("bye earth",:enter)
    sleep 0.5
    wait_playback
    click_on 'Next' # end-of-step popup
    puts "Step 4 (create a segment) complete"
  end

  def step_toggle
    puts "Running step 5: toggle"
    click_on 'Next'
    find('.segment', match: :first).click
    find('.transcript-input').click
    page.driver.browser.action.send_keys(:tab).perform # first toggle: input to waveform
    sleep 0.5
    page.driver.browser.action.send_keys(:tab).perform # second toggle: waveform to input
    sleep 0.5
    page.driver.browser.action.send_keys(:enter).perform # play next segment
    find '.tooltip', match: :first
    page.driver.browser.action.send_keys(:tab).perform # third toggle: input to waveform
    sleep 0.5
    page.driver.browser.action.send_keys(:enter).perform # duplicate segment
    sleep 0.5
    find(".tooltip .submit").click # comments
    input = find('.transcript-input')
    input.click # click the new segment's input box
    input.send_keys([:control, 'd']) # Ctrl+d to delete
    find(".tooltip .submit").click # last tooltip
    puts "Step 5 (toggle) complete"
  end

  def step_split_merge_1
    puts "Running step 6: split and merge I"
    click_on 'Next'
    sleep 0.5 # wait for segments to move down
    segment = find('.segment', match: :first) # make segment active
    page.driver.browser.action.move_to(segment.native, 100, 10).click.perform # avoid error: 'underline would receive click'
    sleep 0.25
    page.driver.browser.action.send_keys(:tab).perform # focus to waveform
    sleep 0.5
    rect = find('rect.selection')
    w = rect[:width].to_f
    page.driver.browser.action.move_to(rect.native, (w/2.0).to_i, 0).perform  # move to middle of selection
    page.driver.browser.action.send_keys(',').perform # split
    find(".tooltip .submit").click # feedback
    find(".keyboard").click # make sure this has focus
    page.driver.browser.action.send_keys('m').perform # merge back
    find(".tooltip .submit").click # last feedback
    puts "Step 6 (split and merge I) complete"
  end

  def step_split_merge_2
    puts "Running step 7: split and merge II"
    click_on 'Next'
    find('.segment', match: :first).click # open input box
    rect = find('rect.selection')
    w = rect[:width].to_f
    page.driver.browser.action.move_to(rect.native, (w/2.0).to_i, 0).perform  # move to middle of selection
    input = find('.transcript-input')
    input.send_keys([:control,',']) # split
    sleep 0.1
    input.send_keys([:control,'m']) # merge back
    find(".tooltip .submit").click # last feedback
    puts "Step 7 (split and merge II) complete"
  end

  def step_adjust_segments
    puts "Running step 8: adjust audio segments"
    click_on 'Next'
    find('.segment', match: :first).click # make segment active
    rect = find('rect.selection')
    w = rect[:width].to_i
    x = rect.rect.x + w
    y = rect.rect.y + 5
    page.driver.browser.action.move_to(rect.native, w, 5)
                              .click_and_hold
                              .move_to_location(x+50, y)
                              .release
                              .perform  # adjust end
    sleep 0.5
    find(".tooltip .submit").click # last feedback
    puts "Step 8 (adjust audio segments) complete"
  end

  def step_zoom
    puts "Running step 9: zoom in and out"
    click_on 'Next'
    find('.node-waveform').click # give focus to waveform
    page.driver.browser.action.send_keys('i').perform # zoom in
    find(".tooltip .submit").click # feedback
    page.driver.browser.action.send_keys('o').perform # zoom out
    find(".tooltip .submit").click # last feedback
    puts "Step 9 (zoom in & out) complete"
  end

  def step_home_keys_1
    puts "Running step 10: Home Keys I"
    click_on 'Next'
    segment = find('.segment', match: :first) # make segment active
    page.driver.browser.action.move_to(segment.native, 100, 20).click.perform # avoid error: 'underline would receive click'
    sleep 0.25
    page.driver.browser.action.send_keys(:tab).perform # give focus to waveform
    page.driver.browser.action.send_keys('b').perform # edit beginning of segment
    sleep 0.1
    page.driver.browser.action.send_keys('j').perform # shorten segment
    page.driver.browser.action.send_keys('f').perform # lengthen segment
    sleep 0.25
    find(".tooltip .submit").click # feedback
    sleep 0.1
    page.driver.browser.action.send_keys('k').perform # shorten segment
    page.driver.browser.action.send_keys('d').perform # lengthen segment
    page.driver.browser.action.send_keys('l').perform # shorten segment
    page.driver.browser.action.send_keys('s').perform # lengthen segment
    page.driver.browser.action.send_keys(';').perform # shorten segment
    page.driver.browser.action.send_keys('a').perform # lengthen segment
    page.driver.browser.action.send_keys('c').perform # done with editing beginning
    sleep 0.1
    page.driver.browser.action.send_keys('e').perform # edit end of segment
    sleep 0.1
    page.driver.browser.action.send_keys('f').perform # shorten segment
    page.driver.browser.action.send_keys('j').perform # lengthen segment
    page.driver.browser.action.send_keys('d').perform # shorten segment
    page.driver.browser.action.send_keys('k').perform # lengthen segment
    page.driver.browser.action.send_keys('s').perform # shorten segment
    page.driver.browser.action.send_keys('l').perform # lengthen segment
    page.driver.browser.action.send_keys('a').perform # shorten segment
    page.driver.browser.action.send_keys(';').perform # lengthen segment
    page.driver.browser.action.send_keys('c').perform # done with editing end
    puts "Step 10 (home keys I) complete"
  end

  def step_home_keys_2
    puts "Running step 11: Home Keys II"
    click_on 'Next'
    find('.node-waveform').click # give focus to waveform
    page.driver.browser.action.send_keys('w').perform # window mode
    sleep 0.1
    page.driver.browser.action.send_keys('j').perform # move window
    page.driver.browser.action.send_keys('f').perform # move window
    page.driver.browser.action.send_keys('k').perform # move window
    page.driver.browser.action.send_keys('d').perform # move window
    page.driver.browser.action.send_keys('l').perform # move window
    page.driver.browser.action.send_keys('s').perform # move window
    page.driver.browser.action.send_keys(';').perform # move window
    page.driver.browser.action.send_keys('a').perform # move window
    find(".tooltip .submit").click # done with window mode
    sleep 0.1
    page.driver.browser.action.send_keys('j').perform # move cursor
    page.driver.browser.action.send_keys('f').perform # move cursor
    page.driver.browser.action.send_keys('k').perform # move cursor
    page.driver.browser.action.send_keys('d').perform # move cursor
    page.driver.browser.action.send_keys('l').perform # move cursor
    page.driver.browser.action.send_keys('s').perform # move cursor
    page.driver.browser.action.send_keys(';').perform # move cursor
    page.driver.browser.action.send_keys('a').perform # move cursor
    find(".tooltip .submit").click # done with cusror mode
    puts "Step 11 (home keys II) complete"
  end

  def step_move_across_segments
    puts "Running step 12: Move across audio segments"
    click_on 'Next'
    find('.node-waveform').click # give focus to waveform
    page.driver.browser.action.send_keys(:down).perform # next segment
    sleep 0.1
    page.driver.browser.action.send_keys(:up).perform # previous segment (from input focus)
    find(".tooltip .submit").click # last feedback
    puts "Step 12 (move across segments) complete"
  end

   # 3/30/21: distant crashes here - waiting for latest commit merge
  def step_help_general
    puts "Running step 13: Help Menu - General"
    click_on 'Next'
    find('.node-waveform').click # give focus to waveform
    page.driver.browser.action.send_keys('h').perform # open help menu
    page.driver.browser.action.send_keys('1').perform # open help on waveform window
    sleep 0.5
    page.driver.browser.action.send_keys('h').perform # back to main help menu
    page.driver.browser.action.send_keys('2').perform # open help on text window
    sleep 0.5
    page.driver.browser.action.send_keys('h').perform # back to main help menu
    puts "Step 13 (help menu - general) complete"
  end

   # This step won't work locally (different confirmation modal), but it should work distantly
  def step_help_sumbit
    puts "Running step 14: Help Menu - Submit"
    click_on 'Next'

    # Download transcript
    find('.fa-download').click
    find('.Box-body input[type="text"]').click.send_keys(FILENAME)
    # Bypass tutorial overlay
    page.evaluate_script("document.querySelector('.Box-body button.btn-sm').click()")
    page.evaluate_script("document.querySelector('.Box-body button.btn-sm').click()")
    page.evaluate_script("document.querySelector('.Box-body a').click()")
    find('.Box-header .btn-octicon').click
    puts "filepath #{FILEPATH}"
    while File.exists?(FILEPATH) == false do
      sleep 0.5
    end
    text = File.read(FILEPATH)
    checksum = Digest::MD5.hexdigest(text)
    File.write(LOGPATH, "Time,Checksum") unless File.exists?(LOGPATH)
    File.write(LOGPATH, "\n#{Time.now},#{checksum}", File.size(LOGPATH), mode: 'a')
    File.delete(FILEPATH)

    find('.node-waveform').click # give focus to waveform
    page.driver.browser.action.send_keys('h').perform # open help menu
    # page.driver.browser.action.send_keys('6').perform # open 'close file'
    # click_on 'Next'
    puts "Step 14 (help menu - submit) complete"
  end

  def step_end
    puts "Running step 15: The End"
    click_on 'Next'
    puts "Step 15 (the end) complete"
  end

  def full_runthrough
    # RESET TUTO 
    reset
    for n in 1..14
      run_step n
    end
  end
end


run = TutorialClass.new
run.start

sleep 1 # give time for display

current_step = run.current_step.to_i+1
# With Chromium, the script won't go any further, because the waveform never shows up
if ARGV.length>0
  if ARGV[0].match(/(\d+)/)
    n = Regexp.last_match[1].to_i
    run.jump_to n unless current_step == n
    run.run_step n
  elsif ARGV[0].match(/(full|reset)/i)
    puts "Running full runthrough"
    run.full_runthrough
  elsif ARGV[0].match(/--from/i)
    if ARGV.length>1 and ARGV[1].match(/(\d+)/)
      n = Regexp.last_match[1].to_i
      run.jump_to n unless current_step == n
      for i in n..14
        run.run_step i
      end
    else
      puts "Invalid use of the --from paramater - running current step"
      run.run_step(current_step)
    end
  else
    puts "Argument unrecognized - running current step"
    run.run_step(current_step)
  end
else
  run.run_step(current_step)
end

sleep 1 # give time for updates
