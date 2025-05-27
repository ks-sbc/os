ASP_STATE_DIR = '/run/live-additional-software'.freeze
ASP_CONF = '/live/persistence/TailsData_unlocked/live-additional-software.conf'
           .freeze

Then /^the Additional Software (upgrade|installation) service has started$/ do |service|
  if $vm.file_exist?(ASP_CONF) && !$vm.file_empty?(ASP_CONF)
    case service
    when 'installation'
      service_name = 'tails-additional-software-install.service'
      seconds_to_wait = 600
    when 'upgrade'
      service_name = 'tails-additional-software-upgrade.service'
      seconds_to_wait = 900
    end
    try_for(seconds_to_wait, delay: 10) do
      $vm.execute("systemctl status #{service_name}").success?
    end
  end
end

Then /^I am notified I can not use Additional Software for "([^"]*)"$/ do |package|
  title = "You could install #{package} automatically when starting Tails"
  step "I see the \"#{title}\" notification after at most 300 seconds"
end

Then /^I am notified that the installation succeeded$/ do
  title = 'Additional software installed successfully'
  step "I see the \"#{title}\" notification after at most 300 seconds"
end

Then /^I am proposed to add the "([^"]*)" package to my Additional Software$/ do |package|
  title = "Add #{package} to your additional software?"
  step "I see the \"#{title}\" notification after at most 300 seconds"
end

def click_gnome_shell_notification_button(title)
  # The notification buttons do not expose any actions through AT-SPI,
  # so Dogtail is unable to click it directly. We let it grab focus
  # and activate it via the keyboard instead.
  Dogtail::Application.new('gnome-shell')
                      .child(title, roleName: 'push button')
                      .grabFocus
  @screen.press('Return')
end

Then /^I create a persistent storage and activate the Additional Software feature$/ do
  click_gnome_shell_notification_button('Create Persistent Storage')
  step 'I create a persistent partition for Additional Software'
  assert_additional_software_persistent_storage_feature_is_enabled
end

def assert_additional_software_persistent_storage_feature_is_enabled
  assert persistent_storage_main_frame.child('Personal Documents', roleName: 'label')
  additional_software_switch = persistent_storage_main_frame.child(
    'Activate Additional Software',
    roleName: 'toggle button'
  )
  assert additional_software_switch.checked?
end

Then /^Additional Software is correctly configured for package "([^"]*)"$/ do |package|
  try_for(30) do
    assert($vm.file_exist?(ASP_CONF), 'ASP configuration file not found')
    step 'all persistence configuration files have safe access rights'
    assert_not_empty(
      $vm.file_glob(
        "/live/persistence/TailsData_unlocked/apt/cache/#{package}_*.deb"
      )
    )
    assert_not_empty(
      $vm.file_glob('/live/persistence/TailsData_unlocked/apt/lists/*_Packages')
    )
    $vm.execute(
      "grep --line-regexp --fixed-strings #{package} #{ASP_CONF}"
    ).success?
  end
end

Then /^"([^"]*)" is not in the list of Additional Software$/ do |package|
  assert($vm.file_exist?(ASP_CONF), 'ASP configuration file not found')
  step 'all persistence configuration files have safe access rights'
  try_for(30) do
    $vm.execute("grep \"#{package}\" #{ASP_CONF}").stdout.empty?
  end
end

When /^I (refuse|accept) (adding|removing) "(?:[^"]*)" (?:to|from) Additional Software$/ do |decision, action|
  case action
  when 'adding'
    case decision
    when 'accept'
      button_title = 'Install Every Time'
    when 'refuse'
      button_title = 'Install Only Once'
    end
  when 'removing'
    case decision
    when 'accept'
      button_title = 'Remove'
    when 'refuse'
      button_title = 'Cancel'
    end
  end
  try_for(300) do
    click_gnome_shell_notification_button(button_title)
    true
  end
end

Given /^I remove "([^"]*)" from the list of Additional Software using Additional Software GUI$/ do |package|
  asp_gui = Dogtail::Application.new('tails-additional-software-config')
  installed_package = asp_gui.child(package, roleName: 'label')
  # We can't use the click action here because this button causes a
  # modal dialog to be run via gtk_dialog_run() which causes the
  # application to hang when triggered via a ATSPI action. See
  # https://gitlab.gnome.org/GNOME/gtk/-/issues/1281
  installed_package.parent.parent.child('Remove', roleName: 'push button').grabFocus
  @screen.press('Return')
  asp_gui.child('Question', roleName: 'alert').button('Remove').click
  deal_with_polkit_prompt(@sudo_password)
end

When /^I prepare the Additional Software upgrade process to fail$/ do
  # Remove the newest cowsay package from the APT cache with a DPKG hook
  # before it gets upgraded so that we simulate a failing upgrade.
  failing_dpkg_hook = <<~HOOK
    DPkg::Pre-Invoke {
      "ls -1 -v /var/cache/apt/archives/cowsay*.deb | tail -n 1 | xargs rm";
    };
  HOOK
  $vm.file_overwrite('/etc/apt/apt.conf.d/00failingDPKGhook', failing_dpkg_hook)
  # Tell the upgrade service check step not to run
  $vm.execute_successfully("touch #{ASP_STATE_DIR}/doomed_to_fail")
end

When /^I remove the "([^"]*)" deb files from the APT cache$/ do |package|
  $vm.execute_successfully(
    "rm /live/persistence/TailsData_unlocked/apt/cache/#{package}_*.deb"
  )
end

Then /^I can open the Additional Software documentation from the notification$/ do
  click_gnome_shell_notification_button('Documentation')
  try_for(60) { @torbrowser = Dogtail::Application.new('Firefox') }
  step '"Tails - Install by cloning" has loaded in the Tor Browser'
end

Then /^the Additional Software dpkg hook has been run for package "([^"]*)" and notices the persistence is locked$/ do |package|
  asp_logs = "#{ASP_STATE_DIR}/log"
  assert(!$vm.file_empty?(asp_logs))
  try_for(180, delay: 2) do
    $vm.execute(
      "grep -E '^.*New\spackages\smanually\sinstalled:\s.*#{package}.*$' " \
      "#{asp_logs}"
    ).success?
  end
  try_for(60) do
    $vm.file_content(asp_logs)
       .include?('Warning: persistence storage is locked')
  end
end

When /^I can open the Additional Software configuration window from the notification$/ do
  click_gnome_shell_notification_button('Configure')
  Dogtail::Application.new('tails-additional-software-config')
end

Then /^I can open the Additional Software log file from the notification$/ do
  click_gnome_shell_notification_button('Show Log')
  try_for(60) do
    Dogtail::Application.new('gnome-text-editor').child(
      "log (#{ASP_STATE_DIR}) - Text Editor", roleName: 'frame'
    )
  end
end
