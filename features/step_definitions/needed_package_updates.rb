Given /^I have the build manifest for the image under test$/ do
  assert File.exist? TAILS_BUILD_MANIFEST
end

Then /^all packages listed in the build manifest are up-to-date$/ do
  command = "#{GIT_DIR}/bin/needed-package-updates"
  config = "#{GIT_DIR}/config/ci/needed-package-updates.yml"
  cmd_helper([command, "--config=#{config}", "--file=#{TAILS_BUILD_MANIFEST}"])
end
