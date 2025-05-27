When /^I(?:| try to) open "([^"]+)" with Evince$/ do |filename|
  step "I run \"evince #{filename}\" in GNOME Terminal"
end

Then /^I can print the current document to "([^"]+)"$/ do |output_file|
  evince = Dogtail::Application.new('evince')
  @screen.press('ctrl', 'p')
  print_dialog = evince.dialog('Print')
  print_dialog.child('Print to File', roleName: 'table cell').grabFocus
  output_file_selection_button = nil
  try_for(10) do
    output_file_selection_button = print_dialog
                                   .children(roleName: 'push button')
                                   .find { |b| /[.]pdf$/.match(b.name) }
    !output_file_selection_button.nil?
  end
  output_file_selection_button.click
  select_path_in_file_chooser(
    evince.child(
      'Select a filename',
      roleName: 'file chooser'
    ),
    output_file,
    button_label: 'Select'
  )
  print_dialog.button('Print').click
  try_for(10, msg: "The document was not printed to #{output_file}") do
    $vm.file_exist?(output_file)
  end
end

When /^I close Evince$/ do
  @screen.press('ctrl', 'w')
  step 'process "evince" has stopped running after at most 20 seconds'
end

Then /^Evince tells me it cannot open "([^"]+)"$/ do |filename|
  assert(Dogtail::Application.new('evince')
                             .child?(
                               "Unable to open document “file://#{filename}”.",
                               roleName: 'label'
                             ))
end
