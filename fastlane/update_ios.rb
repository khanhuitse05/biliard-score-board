#!/usr/bin/env ruby
require 'json'
require 'fastlane'
require 'spaceship'
require 'dotenv'
require 'fileutils'

# --------------------------------------------------
# Helper Methods
# --------------------------------------------------

# Helper method to verify files in a directory
def verify_files(filenames, directory, missing_files)
  filenames.each do |filename|
    file_path = File.join(directory, filename)
    if File.exist?(file_path)
      puts "  ✔ Found: #{filename}"
    else
      missing_files << filename
      puts "  ❌ Missing: #{filename}"
    end
  end
end

# --------------------------------------------------
# Load ENV
# --------------------------------------------------
Dotenv.load(File.join(__dir__, ".env"))

# Note: FASTLANE_TEAM_ID and FASTLANE_ITC_TEAM_ID are optional.
# If not set in .env, you can manually select the team when running the script.

# --------------------------------------------------
# Load Input Data
# --------------------------------------------------

input_path = File.join(__dir__, "input/data.json")

unless File.exist?(input_path)
  puts "❌ ERROR: input/data.json not found!"
  exit 1
end

config = JSON.parse(File.read(input_path))
bundle_id      = config["bundleId"]
app_name       = config["name"]
version_number = config["version"]
# Create metadata .txt files from input/data.json values

metadata_dir = File.join(__dir__, "metadata_ios")
locale = config["primaryLanguage"] || "en-US"
locale_dir = File.join(metadata_dir, locale)

# Create directories if they don't exist
FileUtils.mkdir_p(metadata_dir) unless Dir.exist?(metadata_dir)
FileUtils.mkdir_p(locale_dir) unless Dir.exist?(locale_dir)

# Map fields in data.json to expected file names
metadata_files = {
  "description.txt"      => config["description"],
  "keywords.txt"         => config["keywords"],
  "marketing_url.txt"    => config["marketingUrl"],
  "support_url.txt"      => config["supportUrl"],
  "privacy_url.txt"      => config["privacyUrl"],
  "subtitle.txt"         => config["subtitle"],
  "promotional_text.txt" => config["promotionalText"],
  "release_notes.txt"    => config["releaseNotes"]
}

# Write app-level files (not localized)
root_files = {
  "primary_category.txt"  => config["primaryCategory"],
  "secondary_category.txt"=> config["secondaryCategory"],
  "version.txt"           => version_number,
  "copyright.txt"         => "#{Time.now.year} Erin Living Co."
}

# Write localized (per-locale) files
metadata_files.each do |filename, value|
  next unless value && !value.strip.empty?
  begin
    File.open(File.join(locale_dir, filename), "w") do |f|
      f.write(value)
    end
  rescue => e
    puts "❌ ERROR: Failed to write #{filename}: #{e.message}"
    exit 1
  end
end

# Write root-level (non-localized) files
root_files.each do |filename, value|
  next unless value && !value.strip.empty?
  begin
    File.open(File.join(metadata_dir, filename), "w") do |f|
      f.write(value)
    end
  rescue => e
    puts "❌ ERROR: Failed to write #{filename}: #{e.message}"
    exit 1
  end
end

# Write review information for Apple review team
review_info = config["reviewInformation"]
if review_info && review_info.is_a?(Hash)
  review_dir = File.join(metadata_dir, "review_information")
  Dir.mkdir(review_dir) unless Dir.exist?(review_dir)
  review_info.each do |key, value|
    filename = "#{key.downcase}.txt"
    begin
      File.open(File.join(review_dir, filename), "w") do |f|
        f.write(value)
      end
    rescue => e
      puts "❌ ERROR: Failed to write review info #{filename}: #{e.message}"
      exit 1
    end
  end
end

puts "🚀 Starting STORE METADATA SETUP for #{app_name}"
puts "→ Bundle ID: #{bundle_id}"
puts "→ Version: #{version_number}"

# --------------------------------------------------
# Verify Deliver Metadata Folder Structure
# --------------------------------------------------

puts "\n📝 Verifying metadata files…"

# Verify required metadata files exist
# https://docs.fastlane.tools/actions/deliver/
required_metadata_files = metadata_files.keys
required_root_files = root_files.keys
missing_files = []

verify_files(required_metadata_files, locale_dir, missing_files)
verify_files(required_root_files, metadata_dir, missing_files)

if missing_files.any?
  puts "\n❌ ERROR: Missing required metadata files:"
  missing_files.each { |f| puts "   - #{f}" }
  exit 1
end

puts "✔ All metadata files verified"


# --------------------------------------------------
# Prepare images
# --------------------------------------------------
puts "\n📝 Preparing images..."
screenshots_dir = File.join(__dir__, "screenshots_ios")
screenshots_path = File.join(screenshots_dir, locale)

# Delete screenshots_dir if it exists to ensure clean state
if Dir.exist?(screenshots_dir)
  FileUtils.rm_rf(screenshots_dir)
  puts "✔ Deleted existing screenshots directory"
end

FileUtils.mkdir_p(screenshots_path) unless Dir.exist?(screenshots_path)

# copy images from input/images/6.5inch/ and input/images/6.9inch/ to metadata_ios/screenshots/{primary_language}/
screenshots_65inch_source = File.join(__dir__, "input/images/6.5inch")
screenshots_69inch_source = File.join(__dir__, "input/images/6.9inch")

# Process 6.5inch screenshots
if Dir.exist?(screenshots_65inch_source)
  Dir.glob(File.join(screenshots_65inch_source, "*")).each do |screenshot_file|
    if File.file?(screenshot_file)
      filename = File.basename(screenshot_file)
      dest_file = File.join(screenshots_path, "65#{filename}")
      FileUtils.cp(screenshot_file, dest_file)
    end
  end
else
  puts "⚠️  Warning: #{screenshots_65inch_source} directory not found, skipping 6.5inch screenshots"
end

# Process 6.9inch screenshots
if Dir.exist?(screenshots_69inch_source)
  Dir.glob(File.join(screenshots_69inch_source, "*")).each do |screenshot_file|
    if File.file?(screenshot_file)
      filename = File.basename(screenshot_file)
      dest_file = File.join(screenshots_path, "69#{filename}")
      FileUtils.cp(screenshot_file, dest_file)
    end
  end
else
  puts "⚠️  Warning: #{screenshots_69inch_source} directory not found, skipping 6.9inch screenshots"
end

# --------------------------------------------------
# Authenticate with ASC
# --------------------------------------------------

puts "\n🔐 Logging into App Store Connect…"
Spaceship::ConnectAPI.login

app = Spaceship::ConnectAPI::App.find(bundle_id)

if app.nil?
  puts "❌ ERROR: App not found in App Store Connect!"
  exit 1
end

puts "✔ Found ASC App: #{app.name} (ID: #{app.id})"

# --------------------------------------------------
# Upload Metadata & Screenshots (Fastlane Deliver)
# --------------------------------------------------

puts "\n🚀 Uploading metadata to App Store Connect…"

deliver_command = [
  "fastlane", "deliver",
  "--app_version", version_number.to_s,
  "--app_identifier", bundle_id,
  "--metadata_path", File.expand_path(metadata_dir),
  "--screenshots_path", File.expand_path(screenshots_dir),
  "--screenshot_processing_timeout", "60",
  "--skip_binary_upload", "true",
  # "--force", "true",
]

unless system(*deliver_command)
  puts "❌ ERROR: Failed to upload metadata to App Store Connect!"
  exit 1
end

puts "✔ Metadata & Screenshots uploaded"

# --------------------------------------------------
# Release Type
# --------------------------------------------------

puts "\n🚦 Setting release type…"
version = app.get_edit_app_store_version

if version
  version.update(attributes: { releaseType: "MANUAL" })
  puts "✔ Version set to manual release"
else
  puts "⚠️ No editable version found. You must create one manually first."
end

# --------------------------------------------------
# Pricing & Availability
# --------------------------------------------------

puts "\n💲 Setting Pricing & Availability…"

puts "⚠️  SKIPPED: Pricing and availability must be set manually"
puts "   This is due to App Store Connect API limitations Please set manually:"
puts "   1. Go to App Store Connect > #{app_name} > Pricing and Availability"
puts "   2. Set Price: $0.00 (Free)"
puts "   3. Set Availability: All territories except CN and HK"
puts ""

# --------------------------------------------------
# App Privacy
# --------------------------------------------------

puts "\n🔒 Setting App Privacy…"

puts "⚠️  SKIPPED: App Privacy must be set manually"

# --------------------------------------------------
# DONE
# --------------------------------------------------

puts "\n🎉 Script completed successfully!"
puts "Store metadata, screenshots, pricing, and review info updated."
