# Extracts the secrets for the XMPP account `account_name`.
def xmpp_account(account_name)
  begin
    account = $config['Pidgin']['Accounts']['XMPP'][account_name]
    check_keys = ['username', 'domain', 'password']
    check_keys.each do |key|
      assert(account.key?(key))
      assert_not_nil(account[key])
      assert(!account[key].empty?)
    end
  rescue NoMethodError, Test::Unit::AssertionFailedError
    raise(
      "Your Pidgin:Accounts:XMPP:#{account} is incorrect or missing " \
      "from your local configuration file (#{LOCAL_CONFIG_FILE}). " \
      'See wiki/src/contribute/release_process/test/usage.mdwn for the format.'
    )
  end
  account
end

# Only works for XWayland apps due to use of xdotool
def select_virtual_desktop(desktop_number, user: LIVE_USER)
  assert(desktop_number >= 0 && desktop_number <= 3,
         'Only values between 0 and 1 are valid virtual desktop numbers')
  $vm.execute_successfully(
    "xdotool set_desktop '#{desktop_number}'",
    user:
  )
end

# Only works for XWayland apps due to use of xdotool
def focus_window(window_title, user: LIVE_USER)
  do_focus = lambda do
    $vm.execute_successfully(
      "xdotool search --name '#{window_title}' windowactivate --sync",
      user:
    )
  end

  begin
    do_focus.call
  rescue ExecutionFailedInVM
    # Often when xdotool fails to focus a window it'll work when retried
    # after redrawing the screen.  Switching to a new virtual desktop then
    # back seems to be a reliable way to handle this.
    # Sadly we have to rely on a lot of sleep() here since there's
    # little on the screen etc that we truly can rely on.
    sleep 5
    select_virtual_desktop(1)
    sleep 5
    select_virtual_desktop(0)
    sleep 5
    do_focus.call
  end
rescue StandardError
  # noop
end

def wait_and_focus(img, window, time = 10)
  @screen.wait(img, time)
rescue FindFailed
  focus_window(window)
  @screen.wait(img, time)
end

# This method should always fail (except with the option
# `return_shellcommand: true`) since we block Pidgin's D-Bus interface
# (#14612) ...
def pidgin_dbus_call(method, *args, **opts)
  opts[:user] = LIVE_USER
  dbus_send(
    'im.pidgin.purple.PurpleService',
    '/im/pidgin/purple/PurpleObject',
    "im.pidgin.purple.PurpleInterface.#{method}",
    *args, **opts
  )
end

# ... unless we re-enable it!
def pidgin_force_allowed_dbus_call(method, *args, **opts)
  opts[:user] = LIVE_USER
  policy_file = '/etc/dbus-1/session.d/im.pidgin.purple.PurpleService.conf'
  $vm.execute_successfully("mv #{policy_file} #{policy_file}.disabled")
  # From dbus-daemon(1): "Policy changes should take effect with SIGHUP"
  # Note that HUP is asynchronous, so there is no guarantee whatsoever
  # that the HUP will take effect before we do the dbus call. In
  # practice, however, the delays imposed by using the remote shell is
  # (in general) much larger than the processing time needed for
  # handling signals, so they are in effect synchronous in our
  # context.
  $vm.execute_successfully("pkill -HUP -u #{opts[:user]} 'dbus-daemon'")
  pidgin_dbus_call(method, *args, **opts)
ensure
  $vm.execute_successfully("mv #{policy_file}.disabled #{policy_file}")
  $vm.execute_successfully("pkill -HUP -u #{opts[:user]} 'dbus-daemon'")
end

def pidgin_account_connected?(account, prpl_protocol)
  account_id = pidgin_force_allowed_dbus_call(
    'PurpleAccountsFind', account, prpl_protocol
  )
  pidgin_force_allowed_dbus_call('PurpleAccountIsConnected', account_id) == 1
end

def mid_right_edge(pattern, **opts)
  m = @screen.find(pattern, **opts)
  [m.x + m.w, m.y + m.h / 2]
end

def click_mid_right_edge(pattern, **opts)
  target = mid_right_edge(pattern, **opts)
  @screen.click(target[0], target[1])
end

def triple_click_mid_right_edge(pattern, **opts)
  target = mid_right_edge(pattern, **opts)
  @screen.click(target[0], target[1], triple: true)
end

When /^I create my XMPP account$/ do
  account = xmpp_account('Tails_account')
  @screen.click('PidginAccountManagerAddButton.png')
  @screen.wait('PidginAddAccountWindow.png', 20)
  @screen.wait('PidginAddAccountProtocolLabel.png', 20)
  click_mid_right_edge('PidginAddAccountProtocolLabel.png')
  @screen.click('PidginAddAccountProtocolXMPP.png')
  # We first wait for some field that is shown for XMPP but not the
  # default (IRC) since we otherwise may decide where we click before
  # the GUI has updated after switching protocol.
  @screen.wait('PidginAddAccountXMPPDomain.png', 5)
  click_mid_right_edge('PidginAddAccountXMPPUsername.png')
  @screen.paste(account['username'])
  click_mid_right_edge('PidginAddAccountXMPPDomain.png')
  @screen.paste(account['domain'])
  click_mid_right_edge('PidginAddAccountXMPPPassword.png')
  @screen.paste(account['password'])
  @screen.click('PidginAddAccountXMPPRememberPassword.png')
  if account['connect_server']
    @screen.click('PidginAddAccountXMPPAdvancedTab.png')
    click_mid_right_edge('PidginAddAccountXMPPConnectServer.png')
    @screen.paste(account['connect_server'])
  end
  @screen.click('PidginAddAccountXMPPAddButton.png')
end

Then /^Pidgin automatically enables my XMPP account$/ do
  account = xmpp_account('Tails_account')
  jid = "#{account['username']}@#{account['domain']}"
  try_for(3 * 60) do
    pidgin_account_connected?(jid, 'prpl-jabber')
  end
  focus_window('Buddy List')
  @screen.wait('PidginAvailableStatus.png', 60 * 3)
end

Given /^my XMPP friend goes online( and joins the multi-user chat)?$/ do |join_chat|
  account = xmpp_account('Friend_account')
  bot_opts = account.select { |k, _| ['connect_server'].include?(k) }
  bot_opts['auto_join'] = [@chat_room_jid] if join_chat
  @friend_name = account['username']
  @chatbot = ChatBot.new(
    "#{account['username']}@#{account['domain']}",
    account['password'],
    **bot_opts.transform_keys(&:to_sym)
  )
  @chatbot.start
  add_after_scenario_hook { @chatbot.stop }
  focus_window('Buddy List')
  @screen.wait('PidginFriendOnline.png', 60)
end

When /^I start a conversation with my friend$/ do
  focus_window('Buddy List')
  # Clicking the middle, bottom of this image should query our
  # friend, given it's the only subscribed user that's online, which
  # we assume.
  r = @screen.find('PidginFriendOnline.png')
  x = r.x + r.w / 2
  y = r.y + r.h
  @screen.click(x, y, double: true)
  # Since Pidgin sets the window name to the contact, we have no good
  # way to identify the conversation window. Let's just look for the
  # expected menu bar.
  @screen.wait('PidginConversationWindowMenuBar.png', 10)
end

And /^I say (.*) to my friend( in the multi-user chat)?$/ do |msg, multi_chat|
  msg = 'ping' if msg == 'something'
  if multi_chat
    focus_window(@chat_room_jid.split('@').first)
    msg = "#{@friend_name}: #{msg}"
  else
    focus_window(@friend_name)
  end
  @screen.paste(msg)
  @screen.press('Return')
end

Then /^I receive a response from my friend( in the multi-user chat)?$/ do |multi_chat|
  if multi_chat
    focus_window(@chat_room_jid.split('@').first)
  else
    focus_window(@friend_name)
  end
  try_for(60) do
    if @screen.exists?('PidginServerMessage.png')
      @screen.click('PidginDialogCloseButton.png')
    end
    @screen.find('PidginFriendExpectedAnswer.png')
  end
end

# The reason the chat must be empty is to guarantee that we don't mix
# up messages/events from other users with the ones we expect from the
# bot.
When /^I join some empty multi-user chat$/ do
  focus_window('Buddy List')
  @screen.click('PidginBuddiesMenu.png')
  @screen.wait('PidginBuddiesMenuJoinChat.png', 10).click
  @screen.wait('PidginJoinChatWindow.png', 10).click
  click_mid_right_edge('PidginJoinChatRoomLabel.png')
  account = xmpp_account('Tails_account')
  chat_room = if account.key?('chat_room') && \
                 !account['chat_room'].nil? && \
                 !account['chat_room'].empty?
                account['chat_room']
              else
                random_alnum_string(10, 15)
              end
  @screen.paste(chat_room)

  # We will need the conference server later, when starting the bot.
  click_mid_right_edge('PidginJoinChatServerLabel.png')
  @screen.press('ctrl', 'a')
  @screen.press('ctrl', 'c')
  conference_server =
    $vm.execute_successfully('xclip -o', user: LIVE_USER).stdout.chomp
  @chat_room_jid = "#{chat_room}@#{conference_server}"

  @screen.click('PidginJoinChatButton.png')
  # The following will both make sure that the we joined the chat, and
  # that it is empty. We'll also deal with the *potential* "Create New
  # Room" prompt that Pidgin shows for some server configurations.
  images = ['PidginCreateNewRoomPrompt.png',
            'PidginChat1UserInRoom.png',]
  image_found = @screen.wait_any(images, 30).image
  if image_found == 'PidginCreateNewRoomPrompt.png'
    @screen.wait('PidginCreateNewRoomAcceptDefaultsButton.png', 15).click
  end
  focus_window(@chat_room_jid)
  @screen.wait('PidginChat1UserInRoom.png', 10)
end

# Since some servers save the scrollback, and sends it when joining,
# it's safer to clear it so we do not get false positives from old
# messages when looking for a particular response, or similar.
When /^I clear the multi-user chat's scrollback$/ do
  focus_window(@chat_room_jid)
  @screen.click('PidginConversationMenu.png')
  @screen.wait('PidginConversationMenuClearScrollback.png', 10).click
end

Then /^I can see that my friend joined the multi-user chat$/ do
  focus_window(@chat_room_jid)
  @screen.wait('PidginChat2UsersInRoom.png', 60)
end

def configured_pidgin_accounts
  accounts = {}
  xml = REXML::Document.new(
    $vm.file_content("/home/#{LIVE_USER}/.purple/accounts.xml")
  )
  xml.elements.each('account/account') do |e|
    account = e.elements['name'].text
    account_name, network = account.split('@')
    protocol = e.elements['protocol'].text
    port = e.elements["settings/setting[@name='port']"].text
    username_element = e.elements["settings/setting[@name='username']"]
    realname_elemenet = e.elements["settings/setting[@name='realname']"]
    nickname = username_element ? username_element.text : nil
    real_name = realname_elemenet ? realname_elemenet.text : nil
    accounts[network] = {
      'name'      => account_name,
      'network'   => network,
      'protocol'  => protocol,
      'port'      => port,
      'nickname'  => nickname,
      'real_name' => real_name,
    }
  end

  accounts
end

def chan_image(account, channel, image)
  images = {
    'chat.disroot.org' => {
      'tails' => {
        'conversation_tab' => 'PidginTailsConversationTab',
        'welcome'          => 'PidginTailsChannelWelcome',
      },
    },
  }
  "#{images[account][channel][image]}.png"
end

def default_chan(account)
  chans = {
    'chat.disroot.org' => 'tails',
  }
  chans[account]
end

When /^I open Pidgin's account manager window$/ do
  @screen.wait('PidginMenuAccounts.png', 20).click
  @screen.wait('PidginMenuManageAccounts.png', 20).click
  step "I see Pidgin's account manager window"
end

When /^I see Pidgin's account manager window$/ do
  @screen.wait('PidginAccountWindow.png', 40)
end

When /^I close Pidgin's account manager window$/ do
  @screen.wait('PidginDialogCloseButton.png', 10).click
end

When /^I close Pidgin$/ do
  focus_window('Buddy List')
  @screen.press('ctrl', 'q')
  @screen.wait_vanish('PidginAvailableStatus.png', 10)
end

When /^I (de)?activate the "([^"]+)" Pidgin account$/ do |deactivate, account|
  @screen.click("PidginAccount_#{account}.png")
  @screen.type(['Left'], ['space'])
  if deactivate
    @screen.wait_vanish('PidginAccountEnabledCheckbox.png', 5)
  else
    # wait for the Pidgin to be connecting, otherwise sometimes the step
    # that closes the account management dialog happens before the account
    # is actually enabled
    @screen.wait_any(['PidginConnecting.png', 'PidginAvailableStatus.png'], 5)
  end
end

def deactivate_and_activate_pidgin_account(account)
  debug_log("Deactivating and reactivating Pidgin account #{account}")
  step "I open Pidgin's account manager window"
  step "I deactivate the \"#{account}\" Pidgin account"
  step "I close Pidgin's account manager window"
  step "I open Pidgin's account manager window"
  step "I activate the \"#{account}\" Pidgin account"
  step "I close Pidgin's account manager window"
end

Then /^Pidgin successfully connects to the "([^"]+)" account$/ do |account|
  expected_channel_entry = chan_image(account, default_chan(account), 'roster')
  reconnect_button = 'PidginReconnect.png'
  recovery_on_failure = proc do
    if @screen.exists?('PidginReconnect.png')
      @screen.click('PidginReconnect.png')
    else
      deactivate_and_activate_pidgin_account(account)
    end
  end
  retry_tor(recovery_on_failure) do
    begin
      focus_window('Buddy List')
    rescue ExecutionFailedInVM
      # Sometimes focusing the window with xdotool will fail with the
      # conversation window right on top of it. We'll try to close the
      # conversation window. At worst, the test will still fail...
      close_pidgin_conversation_window(account)
    end
    on_screen = @screen.wait_any([expected_channel_entry, reconnect_button],
                                 60).image
    unless on_screen == expected_channel_entry
      raise "Connecting to account #{account} failed."
    end
  end
end

Then /^I can join the "([^"]+)" channel on "([^"]+)"$/ do |channel, server|
  focus_window('Buddy List')
  @screen.wait('PidginBuddiesMenu.png', 20).click
  @screen.wait('PidginBuddiesMenuJoinChat.png', 10).click
  @screen.wait('PidginJoinChatWindow.png', 10).click
  click_mid_right_edge('PidginJoinChatRoomLabel.png')
  @screen.paste(channel)
  # Replace the default server (which is based on the XMPP account
  # being used by the client)
  triple_click_mid_right_edge('PidginJoinChatServerLabel.png')
  @screen.paste(server)
  @screen.click('PidginJoinChatButton.png')
  @chat_room_jid = "#{channel}@#{server}"
  focus_window(@chat_room_jid)
  @screen.hide_cursor
  try_for(60) do
    @screen.wait(chan_image(server, channel, 'conversation_tab'), 5).click
  rescue FindFailed => e
    # If the channel tab can't be found it could be because there were
    # multiple connection attempts and the channel tab we want is off the
    # screen. We'll try closing tabs until the one we want can be found.
    @screen.press('ctrl', 'w')
    raise e
  end
  @screen.hide_cursor
  @screen.wait(chan_image(server, channel, 'welcome'), 10)
end

Then /^I take note of the configured Pidgin accounts$/ do
  @persistent_pidgin_accounts = configured_pidgin_accounts
end

Then /^Pidgin has the expected persistent accounts configured$/ do
  current_accounts = configured_pidgin_accounts
  assert(
    current_accounts <=> @persistent_pidgin_accounts,
    "Currently configured Pidgin accounts do not match the persistent ones:\n" \
    "Current:\n#{current_accounts}\n" \
    "Persistent:\n#{@persistent_pidgin_accounts}"
  )
end

def pidgin_add_certificate_from(cert_file)
  src = '/usr/share/ca-certificates/mozilla/' \
        'Baltimore_CyberTrust_Root.crt'
  # Here, we need a certificate that is not already in the NSS database
  step "I copy \"#{src}\" to \"#{cert_file}\" as user \"amnesia\""

  focus_window('Buddy List')
  @screen.wait('PidginToolsMenu.png', 10).click
  @screen.wait('PidginCertificatesMenuItem.png', 10).click
  @screen.wait('PidginCertificateManagerDialog.png', 10)
  @screen.wait('PidginCertificateAddButton.png', 10).click
  begin
    @screen.wait('GtkFileChooserDesktopButton.png', 10).click
  rescue FindFailed
    # The first time we're run, the file chooser opens in the Recent
    # view, so we have to browse a directory before we can use the
    # "Type file name" button. But on subsequent runs, the file
    # chooser is already in the Desktop directory, so we don't need to
    # do anything. Hence, this noop exception handler.
  end
  @screen.wait('GtkFileTypeFileNameButton.png', 10).click
  @screen.press('alt', 'l') # "Location" field
  @screen.paste(cert_file)
  @screen.press('Return')
end

Then /^I can add a certificate from the "([^"]+)" directory to Pidgin$/ do |cert_dir|
  pidgin_add_certificate_from("#{cert_dir}/test.crt")
  wait_and_focus('PidginCertificateAddHostnameDialog.png',
                 'Certificate Import', 10)
  @screen.paste('XXX test XXX')
  @screen.press('Return')
  wait_and_focus('PidginCertificateTestItem.png', 'Certificate Manager', 10)
end

Then /^I cannot add a certificate from the "([^"]+)" directory to Pidgin$/ do |cert_dir|
  pidgin_add_certificate_from("#{cert_dir}/test.crt")
  wait_and_focus('PidginCertificateImportFailed.png', 'Import Error', 10)
end

When /^I close Pidgin's certificate manager$/ do
  wait_and_focus('PidginCertificateManagerDialog.png', 'Certificate Manager',
                 10)
  @screen.press('Escape')
  # @screen.wait('PidginCertificateManagerClose.png', 10).click
  @screen.wait_vanish('PidginCertificateManagerDialog.png', 10)
end

When /^I close Pidgin's certificate import failure dialog$/ do
  @screen.press('Escape')
  # @screen.wait('PidginCertificateManagerClose.png', 10).click
  @screen.wait_vanish('PidginCertificateImportFailed.png', 10)
end

When /^I see the Tails GitLab URL$/ do
  try_for(60) do
    if @screen.exists?('PidginServerMessage.png')
      @screen.click('PidginDialogCloseButton.png')
    end
    begin
      @screen.find('PidginTailsGitLabUrl.png')
    rescue FindFailed => e
      @screen.press('Page_Up')
      raise e
    end
  end
end

When /^I click on the Tails GitLab URL$/ do
  @screen.click('PidginTailsGitLabUrl.png')
  try_for(60) { @torbrowser = Dogtail::Application.new('Firefox') }
end

Then /^Pidgin's D-Bus interface is not available$/ do
  # Pidgin must be running to expose the interface
  assert($vm.process_running?('pidgin'))
  # Let's first ensure it would work if not explicitly blocked.
  # Note: that the method we pick here doesn't really matter
  # (`PurpleAccountsGetAll` felt like a convenient choice since it
  # doesn't require any arguments).
  assert_equal(
    Array, pidgin_force_allowed_dbus_call('PurpleAccountsGetAll').class
  )
  # Finally, let's make sure it is blocked
  c = pidgin_dbus_call('PurpleAccountsGetAll', return_shellcommand: true)
  assert(c.failure?)
  assert_not_nil(c.stderr['Rejected send message'])
end
