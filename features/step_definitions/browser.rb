def browser
  Dogtail::Application.new('Firefox')
end

def desktop_portal
  Dogtail::Application.new('xdg-desktop-portal-gtk')
end

def desktop_portal_save_as_dialog
  desktop_portal.child(roleName: 'file chooser')
end

def save_page_as
  browser.child(
    description: 'Open application menu',
    roleName:    'push button'
  ).press
  browser.child(
    name:     'Save page as\u2026',
    roleName: 'push button'
  ).press
  desktop_portal_save_as_dialog
end

def browser_url_entry
  # Unfortunately the Dogtail nodes' names are also translated, so for
  # non-English we have to use a less efficient and (potentially) less
  # future-proof way to find the URL entry.
  if $language.empty? # English
    browser.child('Navigation', roleName: 'tool bar')
           .child(roleName: 'entry')
  else
    browser.children(roleName: 'tool bar')
           .find { |n| n.child?(roleName: 'entry', retry: false) }
           .child(roleName: 'entry')
  end
end

def get_current_browser_url
  browser_url_entry.text
end

def set_browser_url(url)
  browser_url_entry.grabFocus
  try_for(10) do
    focused = browser.focused_child
    # Just matching against any entry could be racy if some other
    # entry had focus when calling this step, but address bar is
    # probably the only entry inside a tool bar.
    focused.roleName == 'entry' && focused.parent.parent.roleName == 'tool bar'
  end
  # We're retrying to workaround #19237.
  #
  # Dogtail's .text= would be a simpler and more robust workaround,
  # but we can't use it yet due to
  # https://bugzilla.mozilla.org/show_bug.cgi?id=1861026
  retry_action(10) do
    @screen.press('ctrl', 'a')
    _, selection_length = browser_url_entry.get_text_selection_range
    assert_equal(get_current_browser_url.length, selection_length)
    @screen.press('backspace')
    assert_true(get_current_browser_url.empty?)
    @screen.paste(url)
    assert_equal(get_current_browser_url, url)
  end
end

When /^I (try to )?start the Unsafe Browser$/ do |try_to|
  launch_unsafe_browser(check_started: !try_to)
end

When /^I successfully start the Unsafe Browser$/ do
  step 'I start the Unsafe Browser'
  step 'the Unsafe Browser has started'
end

# This step works reliably only when there's no more than one tab:
# otherwise, browser.tabs.warnOnClose will block this with a
# "Quit and close tabs?" dialog.
When /^I close the (?:Tor|Unsafe) Browser$/ do
  @screen.press('ctrl', 'q')
end

When(/^I kill the ((?:Tor|Unsafe) Browser)$/) do |browser|
  info = xul_application_info(browser)
  $vm.execute_successfully("pkill --full --exact '#{info[:cmd_regex]}'")
  try_for(10) do
    $vm.execute("pgrep --full --exact '#{info[:cmd_regex]}'").failure?
  end

  # Ugly fix to #18568; in my local testing, 3 seconds are always needed.
  # Let's add some more.
  # A better solution would be to wait until GNOME "received" the fact
  # that the browser has gone away.
  sleep 5
end

def tor_browser_application_info(defaults)
  user = LIVE_USER
  binary = $vm.execute_successfully(
    'echo ${TBB_INSTALL}/firefox.real', libs: 'tor-browser'
  ).stdout.chomp
  cmd_regex = "#{binary} .* -profile " \
              "/home/#{user}/\.tor-browser/profile\.default"
  defaults.merge(
    {
      user:,
      cmd_regex:,
      chroot:                          '',
      new_tab_button_image:            'TorBrowserNewTabButton.png',
      browser_reload_button_image:     'TorBrowserReloadButton.png',
      browser_reload_button_image_rtl: 'TorBrowserReloadButtonRTL.png',
      browser_stop_button_image:       'TorBrowserStopButton.png',
    }
  )
end

def unsafe_browser_application_info(defaults)
  user = LIVE_USER
  binary = $vm.execute_successfully(
    'echo ${TBB_INSTALL}/firefox.unsafe-browser', libs: 'tor-browser'
  ).stdout.chomp
  cmd_regex = "#{binary} .* " \
              "--profile /home/#{user}/\.unsafe-browser/profile\.default"
  defaults.merge(
    {
      user:,
      cmd_regex:,
      chroot:                      '/var/lib/unsafe-browser/chroot',
      new_tab_button_image:        'UnsafeBrowserNewTabButton.png',
      browser_reload_button_image: 'UnsafeBrowserReloadButton.png',
      browser_stop_button_image:   'UnsafeBrowserStopButton.png',
    }
  )
end

def xul_application_info(application)
  defaults = {
    address_bar_image: "BrowserAddressBar#{$language}.png",
    unused_tbb_libs:   [
      'libnssdbm3.so',
      'libmozavcodec.so',
      'libmozavutil.so',
      'libipcclientcerts.so',
    ],
  }
  case application
  when 'Tor Browser'
    tor_browser_application_info(defaults)
  when 'Unsafe Browser'
    unsafe_browser_application_info(defaults)
  else
    raise "Invalid browser or XUL application: #{application}"
  end
end

When /^I open a new tab in the (.*)$/ do |browser_name|
  info = xul_application_info(browser_name)
  retry_action(2) do
    @screen.click(info[:new_tab_button_image])
    @screen.wait(info[:address_bar_image], 15)
  end
end

When /^I open the address "([^"]*)" in the (.* Browser)( without waiting)?$/ do |address, browser_name, non_blocking|
  browser = Dogtail::Application.new('Firefox')
  info = xul_application_info(browser_name)
  open_address = proc do
    step "I open a new tab in the #{browser_name}"
    set_browser_url(address)
    @screen.press('Return')
  end
  recovery_on_failure = proc do
    @screen.press('Escape')
    @screen.wait_vanish(info[:browser_stop_button_image], 3)
  end
  retry_method = if browser_name == 'Tor Browser'
                   method(:retry_tor)
                 else
                   proc { |p, &b| retry_action(10, recovery_proc: p, &b) }
                 end
  retry_method.call(recovery_on_failure) do
    open_address.call
    unless non_blocking
      try_for(120, delay: 3) do
        !browser.child?('Stop', roleName: 'push button', retry: false) &&
          browser.child?('Reload', roleName: 'push button', retry: false)
      end
    end
  end
end

def page_has_loaded_in_the_tor_browser(page_titles)
  page_titles = [page_titles] if page_titles.instance_of?(String)
  assert_equal(Array, page_titles.class)
  browser_name = 'Tor Browser'
  if $language == 'German'
    reload_action = 'Neu laden'
    separator = '–'
  else
    reload_action = 'Reload'
    separator = '—'
  end
  try_for(180, delay: 3) do
    # The 'Reload' button (graphically shown as a looping arrow)
    # is only shown when a page has loaded, so once we see the
    # expected title *and* this button has appeared, then we can be sure
    # that the page has fully loaded.
    @torbrowser.children(roleName: 'frame').any? do |frame|
      page_titles
        .map  { |page_title| "#{page_title} #{separator} #{browser_name}" }
        .any? { |page_title| page_title == frame.name }
    end &&
      @torbrowser.child(reload_action, roleName: 'push button')
  end
end

Then /^"([^"]+)" has loaded in the Tor Browser$/ do |title|
  page_has_loaded_in_the_tor_browser(title)
end

def xul_app_shared_lib_check(pid, expected_absent_tbb_libs = [])
  absent_tbb_libs = []
  unwanted_native_libs = []
  tbb_libs = $vm.execute_successfully('ls -1 ${TBB_INSTALL}/*.so',
                                      libs: 'tor-browser').stdout.split
  firefox_pmap_info = $vm.execute("pmap --show-path #{pid}").stdout
  native_libs = $vm.execute_successfully(
    'find /usr/lib /lib -name "*.so"'
  ).stdout.split
  tbb_libs.each do |lib|
    lib_name = File.basename lib
    absent_tbb_libs << lib_name unless /\W#{lib}$/.match(firefox_pmap_info)
    native_libs.each do |native_lib|
      next unless native_lib.end_with?("/#{lib_name}")

      if /\W#{native_lib}$"/.match(firefox_pmap_info)
        unwanted_native_libs << lib_name
      end
    end
  end
  absent_tbb_libs -= expected_absent_tbb_libs
  assert(absent_tbb_libs.empty? && unwanted_native_libs.empty?,
         'The loaded shared libraries for the firefox process are not the ' \
         "way we expect them.\n" \
         "Expected TBB libs that are absent: #{absent_tbb_libs}\n" \
         "Native libs that we don't want: #{unwanted_native_libs}")
end

Then /^the (.*) uses all expected TBB shared libraries$/ do |application|
  info = xul_application_info(application)
  pid = $vm.execute_successfully(
    "pgrep --uid #{info[:user]} --full --exact '#{info[:cmd_regex]}'"
  ).stdout.chomp
  pid = pid.scan(/\d+/).first
  assert_match(/\A\d+\z/, pid, "It seems like #{application} is not running")
  xul_app_shared_lib_check(pid, info[:unused_tbb_libs])
end

Then /^the (.*) chroot is torn down$/ do |browser|
  info = xul_application_info(browser)
  try_for(30, msg: "The #{browser} chroot '#{info[:chroot]}' was " \
                      'not removed') do
    !$vm.execute("test -d '#{info[:chroot]}'").success?
  end
end

Then /^the (.*) runs as the expected user$/ do |browser|
  info = xul_application_info(browser)
  assert_vmcommand_success(
    $vm.execute("pgrep --full --exact '#{info[:cmd_regex]}'"),
    "The #{browser} is not running"
  )
  assert_vmcommand_success(
    $vm.execute(
      "pgrep --uid #{info[:user]} --full --exact '#{info[:cmd_regex]}'"
    ),
    "The #{browser} is not running as the #{info[:user]} user"
  )
end

When /^I download some file in the Tor Browser to the (.*) directory$/ do |target_dir|
  @some_file = 'tails-signing.key'
  some_url = "https://tails.net/#{@some_file}"
  step "I open the address \"#{some_url}\" in the Tor Browser without waiting"
  # Note that the "Opening ..." dialog sometimes appear with roleName
  # "frame" and sometimes with "dialog", so we deliberately do not
  # specify the roleName.
  button = @torbrowser
           .child("Opening #{@some_file}")
           .button('Save File')
  try_for(10) { button.sensitive? }
  button.press
  file_dialog = desktop_portal_save_as_dialog
  activate_places_sidebar_item(file_dialog, "/home/#{LIVE_USER}/#{target_dir}")
  file_dialog.child('Save', roleName: 'push button').click

  @torbrowser
    .button('Downloads')
    .press
  @torbrowser
    .child('Downloads', roleName: 'panel')
    .child("#{@some_file} Completed .*", roleName: 'list item')
end

Then /^the file is saved to the (.*) directory$/ do |target_dir|
  assert_not_nil(@some_file)
  try_for(10) { $vm.file_exist?("/home/#{LIVE_USER}/#{target_dir}/#{@some_file}") }
end

When /^I open the Tails homepage in the (.+)$/ do |browser|
  step "I open the address \"https://tails.net\" in the #{browser}"
end

Then /^the Tails homepage loads in the Unsafe Browser$/ do
  @screen.wait('TailsHomepage.png', 60)
end

def headings_in_page(browser, page_title)
  browser.child(page_title, roleName: 'document web').children(roleName: 'heading')
end

def page_has_heading(browser, page_title, heading)
  headings_in_page(browser, page_title).any? { |h| h.name == heading }
end

Then /^the (Tor|Unsafe) Browser shows the "([^"]+)" error$/ do |browser_name, error|
  browser = if browser_name == 'Tor'
              @torbrowser
            else
              @unsafe_browser
            end

  try_for(60, delay: 3) do
    page_has_heading(browser, 'Problem loading page', error)
  end
end

Then /^Tor Browser displays a "([^"]+)" heading on the "([^"]+)" page$/ do |heading, page_title|
  try_for(60, delay: 3) do
    page_has_heading(@torbrowser, page_title, heading)
  end
end

Then /^Tor Browser displays a '([^']+)' heading on the "([^"]+)" page$/ do |heading, page_title|
  try_for(60, delay: 3) do
    page_has_heading(@torbrowser, page_title, heading)
  end
end

Then /^I can listen to an Ogg audio track in Tor Browser$/ do
  test_url = 'https://upload.wikimedia.org/wikipedia/commons/1/1e/HTTP_cookie.ogg'
  info = xul_application_info('Tor Browser')
  open_test_url = proc do
    step "I open the address \"#{test_url}\" in the Tor Browser"
  end
  recovery_on_failure = proc do
    @screen.press('Escape')
    @screen.wait_vanish(info[:browser_stop_button_image], 3)
    open_test_url.call
  end
  try_for(20) { pipewire_input_ports.zero? }
  open_test_url.call
  retry_tor(recovery_on_failure) do
    sleep 30
    assert(pipewire_input_ports.positive?)
  end
end

Then /^I can watch a WebM video in Tor Browser$/ do
  test_url = WEBM_VIDEO_URL
  info = xul_application_info('Tor Browser')
  open_test_url = proc do
    step "I open the address \"#{test_url}\" in the Tor Browser"
  end
  recovery_on_failure = proc do
    @screen.press('Escape')
    @screen.wait_vanish(info[:browser_stop_button_image], 3)
    open_test_url.call
  end
  open_test_url.call
  retry_tor(recovery_on_failure) do
    @screen.wait('TorBrowserSampleRemoteWebMVideoFrame.png', 30)
  end
end

Then /^DuckDuckGo is the default search engine$/ do
  ddg_search_prompt = 'DuckDuckGoSearchPrompt.png'
  case $language
  when 'Arabic', 'Persian'
    ddg_search_prompt = 'DuckDuckGoSearchPromptRTL.png'
  when 'Hindi'
    ddg_search_prompt = "DuckDuckGoSearchPrompt#{$language}.png"
  end
  step 'I open a new tab in the Tor Browser'
  set_browser_url('a random search string')
  @screen.wait(ddg_search_prompt, 20)
end

Then(/^the screen keyboard works in Tor Browser$/) do
  osk_key_images = ['ScreenKeyboardKeyComma.png',
                    'ScreenKeyboardKeyComma_alt.png',]
  browser_bar_x = 'BrowserAddressBarComma.png'
  case $language
  when 'Arabic'
    browser_bar_x = 'BrowserAddressBarCommaRTL.png'
  when 'Persian'
    osk_key_images = ['ScreenKeyboardKeyCommaPersian.png',
                      'ScreenKeyboardKeyCommaPersian_alt.png',]
  end
  step 'I start the Tor Browser'
  step 'I open a new tab in the Tor Browser'
  # When opening a new tab the address bar's entry is focused which
  # should show the OSK, but it doesn't. Dogtail's .grabFocus doesn't
  # trigger it either.
  @screen.click(xul_application_info('Tor Browser')[:address_bar_image])
  @screen.wait('ScreenKeyboard.png', 20)
  @screen.wait_any(osk_key_images, 20).click
  @screen.wait(browser_bar_x, 20)
end

When /^I log-in to the Captive Portal$/ do
  step 'a web server is running on the LAN'
  captive_portal_page = "#{@web_server_url}/captive"
  step "I open the address \"#{captive_portal_page}\" in the Unsafe Browser"

  try_for(30) do
    File.exist?(@captive_portal_login_file)
  end

  step 'I close the Unsafe Browser'
end

Then /^Tor Browser's circuit view is working$/ do
  @torbrowser.child('Tor Circuit', roleName: 'push button').click
  nodes = @torbrowser.child('This browser', roleName: 'list item')
                     .parent.children(roleName: 'list item')
  domain = URI.parse(get_current_browser_url).host.split('.')[-2..].join('.')
  assert_equal('This browser', nodes.first.name)
  assert_equal(domain, nodes.last.name)
  assert_equal(5, nodes.size)
end

When /^I start the Tor Browser( in offline mode)?$/ do |offline|
  launch_tor_browser(check_started: !offline)
  if offline
    start_button = Dogtail::Application
                   .new('zenity')
                   .dialog('Tor is not ready')
                   .button('Start Tor Browser Offline')
    # Sometimes this click is lost. Maybe the dialog is not fully setup yet?
    sleep 2
    start_button.click
  end
  step 'the Tor Browser has started'
  if offline
    step 'the Tor Browser shows the ' \
         '"The proxy server is refusing connections" error'
  end
end

Given /^the Tor Browser (?:has started|starts)$/ do
  try_for(60) do
    @torbrowser = Dogtail::Application.new('Firefox')
    @torbrowser.child?(roleName: 'frame', recursive: false)
  end
  browser_info = xul_application_info('Tor Browser')
  @screen.wait(browser_info[:new_tab_button_image], 10)
  try_for(120, delay: 3) do
    # We can't use Dogtail here: this step must support many languages
    # and using Dogtail would require maintaining a list of translations
    # for the "Stop" and "Reload" buttons.
    @screen.wait_vanish(browser_info[:browser_stop_button_image], 120)
    if RTL_LANGUAGES.include?($language)
      @screen.wait(browser_info[:browser_reload_button_image_rtl], 120)
    else
      @screen.wait(browser_info[:browser_reload_button_image], 120)
    end
  end
end

Given /^the Tor Browser loads the (startup page|Tails homepage|Tails GitLab)$/ do |page|
  case page
  when 'startup page'
    titles = [
      'Tails',
      'Tails - Trying a testing version of Tails',
      'Tails - Welcome to Tails!',
      'Tails - Dear Tails user,',
    ]
  when 'Tails homepage'
    titles = ['Tails']
  when 'Tails GitLab'
    titles = ['tails · GitLab']
  else
    raise "Unsupported page: #{page}"
  end
  page_has_loaded_in_the_tor_browser(titles)
end

Given /^I add a bookmark to eff.org in the Tor Browser$/ do
  url = 'https://www.eff.org'
  step "I open the address \"#{url}\" in the Tor Browser"
  step 'the Tor Browser shows the ' \
       '"The proxy server is refusing connections" error'
  @torbrowser.child('Bookmark this page (Ctrl+D)', roleName: 'push button').click
  prompt = @torbrowser.child('Add bookmark', roleName: 'panel')
  prompt.child('Location', roleName: 'combo box').open
  prompt.child('Bookmarks Menu', roleName: 'menu item').click
  prompt.button('Save').press
end

Given /^the Tor Browser has a bookmark to eff.org$/ do
  @screen.press('alt', 'b')
  @screen.wait('TorBrowserEFFBookmark.png', 10)
end

When /^I can print the current page as "([^"]+[.]pdf)" to the (.*) directory$/ do |output_file, target_dir|
  output_dir = "/home/#{LIVE_USER}/#{target_dir}"
  @screen.press('ctrl', 'p')
  @torbrowser.child('Save', roleName: 'push button').press
  file_dialog = desktop_portal_save_as_dialog
  # Enter the output filename in the text entry
  text_entry = file_dialog.child('Name', roleName: 'label').labelee
  filename = "#{output_dir}/#{output_file}"
  text_entry.text = filename
  file_dialog.child('Save', roleName: 'push button').click

  try_for(30,
          msg: "The page was not printed to #{output_dir}/#{output_file}") do
    $vm.file_exist?("#{output_dir}/#{output_file}")
  end
end

def activate_places_sidebar_item(parent, path)
  list_item = parent.child(description: path, roleName: 'list item')
  # We have had problems with the Space press not causing the
  # bookmark to be selected despite it being focused (tails#20356,
  # tails#20159)
  try_for(20) do
    # Unlike the native file picker, the XDG Desktop Portal file
    # picker use here has this issue: grabbing focus of the list item
    # and then pressing Space to activate it does nothing, which for
    # the native file picker selects the list item in its list box and
    # changes the directory. So we also manually making the list item
    # selected and then it works as expected.
    # Furthermore, our Dogtail::Node#select is implemented with
    # .doActionNamed('select'), but for some reason that action is not
    # available for this list item like it usually is. So we instead
    # call .select() which Dogtail implements differently and is
    # available for this list item node.
    list_item.call_tree_api_method('select')
    list_item.grabFocus
    @screen.press('Space')
    # If we successfully selected the bookmark then the path will be
    # updated accordingly, and each path component is a 'toggle
    # button' labelled with the name of the folder.
    parent.child?(path.split('/').last, roleName: 'toggle button', retry: false)
  end
end

When /^I (can|cannot) save the current page as "([^"]+[.]html)" to the (.*) (directory|GNOME bookmark)$/ do |should_work, output_file, target_dir, bookmark|
  should_work = should_work == 'can'
  is_gnome_bookmark = bookmark == 'GNOME bookmark'
  file_dialog = save_page_as
  output_dir = "/home/#{LIVE_USER}/#{target_dir}"

  if is_gnome_bookmark
    activate_places_sidebar_item(file_dialog, output_dir)
  else
    # Enter the output directory in the text entry
    text_entry = file_dialog.child('Name', roleName: 'label').labelee
    text_entry.text = output_dir
    # Do the "activate" action of the text entry (same effect as
    # pressing Enter) to open the directory.
    text_entry.activate
  end

  # Enter the output filename in the text entry
  text_entry = file_dialog.child('Name', roleName: 'label').labelee
  text_entry.text = output_file
  save_button = file_dialog.child('Save', roleName: 'push button')
  # When changing output directory the Save button turns insensitive
  # for a few moments
  try_for(10) { save_button.sensitive? }
  save_button.click

  if should_work
    try_for(20,
            msg: "The page was not saved to #{output_dir}/#{output_file}") do
      $vm.file_exist?("#{output_dir}/#{output_file}")
    end
  else
    @screen.wait('TorBrowserCannotSavePage.png', 10)
  end
end

When /^I request a new identity in Tor Browser$/ do
  @torbrowser.child('Tor Browser', roleName: 'push button').press
  @torbrowser.child('New identity', roleName: 'push button').press
  @torbrowser.child('Restart Tor Browser', roleName: 'push button').press
end

Then /^the Tor Browser has (\d+) tabs? open$/ do |expected_tab_count|
  tabs = @torbrowser.child('Browser tabs', roleName: 'tool bar')
                    .child(roleName: 'page tab list')
                    .children(roleName: 'page tab', showingOnly: false)
  assert_equal(expected_tab_count.to_i, tabs.size)
end
