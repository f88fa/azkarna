# Adds PrivacyInfo.xcprivacy to the Runner and PrayerWidget targets' resources
# (idempotent). Run like tool/add_prayer_widget.rb.
require 'xcodeproj'

project = Xcodeproj::Project.open(File.expand_path('../ios/Runner.xcodeproj', __dir__))
{ 'Runner' => 'Runner', 'PrayerWidget' => 'PrayerWidget' }.each do |target_name, group_name|
  target = project.targets.find { |t| t.name == target_name }
  group = project.main_group.children.find { |g| g.display_name == group_name }
  next if group.files.any? { |f| f.path == 'PrivacyInfo.xcprivacy' }
  ref = group.new_file('PrivacyInfo.xcprivacy')
  target.resources_build_phase.add_file_reference(ref, true)
  puts "added to #{target_name}"
end
project.save
