# Adds the PrayerWidget WidgetKit extension to ios/Runner.xcodeproj (idempotent).
# Run with CocoaPods' bundled xcodeproj gem:
#   GEM_HOME=$(brew --prefix cocoapods)/libexec ruby tool/add_prayer_widget.rb
require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
project = Xcodeproj::Project.open(File.join(ROOT, 'ios/Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner
abort 'PrayerWidget already added' if project.targets.any? { |t| t.name == 'PrayerWidget' }

widget = project.new_target(:app_extension, 'PrayerWidget', :ios, '16.0', nil, :swift)

group = project.main_group.new_group('PrayerWidget', 'PrayerWidget')
swift = group.new_file('PrayerWidget.swift')
group.new_file('Info.plist')
group.new_file('PrayerWidget.entitlements')
xcconfig = group.new_file('PrayerWidget.xcconfig')
widget.add_file_references([swift])

frameworks = project.frameworks_group
%w[WidgetKit SwiftUI].each do |name|
  ref = frameworks.new_file("System/Library/Frameworks/#{name}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref, true)
end

# Every configuration Runner has (Debug / Release / Profile).
runner.build_configurations.each do |rc|
  cfg = widget.build_configurations.find { |c| c.name == rc.name } ||
        widget.add_build_configuration(rc.name, rc.name == 'Debug' ? :debug : :release)
  cfg.base_configuration_reference = xcconfig
  s = cfg.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.alray.azkarna.PrayerWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'PrayerWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'PrayerWidget/PrayerWidget.entitlements'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['ENABLE_BITCODE'] = 'NO'
  s['SWIFT_OPTIMIZATION_LEVEL'] = rc.name == 'Debug' ? '-Onone' : '-O'

  # The app shares data with the widget through the App Group.
  rc.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
widget.build_configurations.reject { |c| runner.build_configurations.map(&:name).include?(c.name) }
      .each { |c| widget.build_configuration_list.build_configurations.delete(c) }

# Runner: entitlements file in the navigator, WidgetKit weak-linked (app is iOS 13+).
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
runner_group.new_file('Runner.entitlements') unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
wk = frameworks.files.find { |f| f.path.end_with?('WidgetKit.framework') }
bf = runner.frameworks_build_phase.add_file_reference(wk, true)
bf.settings = { 'ATTRIBUTES' => ['Weak'] }

# Build and embed the extension in the app, before Flutter's "Thin Binary"
# script (otherwise Xcode reports a dependency cycle).
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference, true).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.build_phases.delete(embed)
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
runner.build_phases.insert(thin || runner.build_phases.size, embed)

project.save
puts 'PrayerWidget added'
