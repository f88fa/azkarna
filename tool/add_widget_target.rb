#!/usr/bin/env ruby
# frozen_string_literal: true

# One-off helper that adds the "AwwabWidgets" WidgetKit extension to
# ios/Runner.xcodeproj (target, sources, embed phase, entitlements).
#
#   gem install xcodeproj --user-install
#   ruby tool/add_widget_target.rb
#
# Safe to re-run: it stops when the target already exists.

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'ios', 'Runner.xcodeproj')
EXT_NAME = 'AwwabWidgets'
EXT_BUNDLE_ID = 'com.alray.azkarna.AwwabWidgets'
APP_GROUP = 'group.com.alray.azkarna'
SOURCES = %w[
  AwwabWidgetBundle.swift
  WidgetData.swift
  WidgetTheme.swift
  PrayerWidgets.swift
  ReadingWidgets.swift
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
if project.targets.any? { |t| t.name == EXT_NAME }
  puts "#{EXT_NAME} already exists - nothing to do"
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'

# --- Files ----------------------------------------------------------------
group = project.main_group.new_group(EXT_NAME, EXT_NAME)
source_refs = SOURCES.map { |name| group.new_file(name) }
group.new_file('Info.plist')
group.new_file("#{EXT_NAME}.entitlements")

runner_group = project.main_group['Runner'] or abort 'Runner group not found'
runner_group.new_file('Runner.entitlements')

# --- Extension target -----------------------------------------------------
ext = project.new_target(:app_extension, EXT_NAME, :ios, '16.0', project.products_group, :swift, EXT_NAME)
ext.add_file_references(source_refs)

# `new_target` links a Foundation.framework reference with a hard-coded SDK
# path; autolinking (import SwiftUI / WidgetKit) makes it unnecessary.
ext.frameworks_build_phase.files.dup.each(&:remove_from_project)
project.files.select { |f| f.display_name == 'Foundation.framework' }.each(&:remove_from_project)
project.main_group['Frameworks']&.remove_from_project

ext.build_configurations.each do |config|
  runner_config = runner.build_configurations.find { |c| c.name == config.name }
  config.base_configuration_reference = runner_config.base_configuration_reference

  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => EXT_BUNDLE_ID,
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => "#{EXT_NAME}/Info.plist",
    'CODE_SIGN_ENTITLEMENTS' => "#{EXT_NAME}/#{EXT_NAME}.entitlements",
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.0',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks'
    ],
    'VERSIONING_SYSTEM' => 'apple-generic'
  )
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if config.name == 'Debug'

  # The app gets the shared App Group too.
  runner_config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# --- Embed in Runner (before "Thin Binary" to avoid a build cycle) ---------
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(ext.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

phases = runner.build_phases
phases.delete(embed)
thin = phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
phases.insert(thin || phases.length, embed)

runner.add_dependency(ext)

project.save
puts "Added #{EXT_NAME} (#{EXT_BUNDLE_ID}) with app group #{APP_GROUP}"
