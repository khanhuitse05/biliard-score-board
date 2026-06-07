#!/usr/bin/env ruby
require "json"
require "dotenv"
require "fastlane"
require "google/apis/androidpublisher_v3"
require "fileutils"


# --------------------------------------------------
# Helper: Check if app exists
# --------------------------------------------------
# Note: Google Play Console API does NOT provide an endpoint to create apps.
# Apps must be created manually via the Play Console web interface first.
# This function checks if an app exists by attempting to create an edit.

def check_app_exists(android_publisher, package_name)
  begin
    edit = android_publisher.insert_edit(package_name)
    edit_id = edit.id
    android_publisher.delete_edit(package_name, edit_id)
    return true
  rescue Google::Apis::ClientError => e
    if e.status_code == 404  # 404 means app doesn't exist
      return false
    else
      raise
    end
  end
end


# --------------------------------------------------
# Load ENV
# --------------------------------------------------
Dotenv.load(File.join(__dir__, ".env"))

# Service account path: relative to fastlane/ so it works when run via fastlane from project root
SERVICE_ACCOUNT_JSON = File.join(__dir__, "service_account.json")

unless File.exist?(SERVICE_ACCOUNT_JSON)
  puts "❌ Missing service account file: #{SERVICE_ACCOUNT_JSON}"
  exit 1
end

# --------------------------------------------------
# Load config data
# --------------------------------------------------

config_path = File.join(__dir__, "input/data.json")

unless File.exist?(config_path)
  puts "❌ ERROR: input/data.json not found!"
  exit 1
end

config = JSON.parse(File.read(config_path))
app_name            = config["name"]
package_name        = config["bundleId"]
version_name        = config["version"]
primary_language    = config["primaryLanguage"] || "en-US"

short_description   = config["shortDescription"]
full_description    = config["description"]
promotional_text    = config["promotionalText"]

marketing_url       = config["marketingUrl"]
privacy_url         = config["privacyUrl"]
support_url         = config["supportUrl"]
contact_url         = config["contactUrl"]
release_notes       = config["releaseNotes"]
review_email        = config.dig("reviewInformation", "email_address")
review_phone        = config.dig("reviewInformation", "phone_number") 

puts "🚀 Starting ANDROID SETUP for #{app_name} - #{package_name}"

metadata_path = File.join(__dir__, "metadata_android")


# --------------------------------------------------
# Init Google API client
# --------------------------------------------------

android_publisher = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
android_publisher.authorization = File.open(SERVICE_ACCOUNT_JSON) do |file|
  Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: file,
    scope: "https://www.googleapis.com/auth/androidpublisher"
  )
end

# --------------------------------------------------
# 1. Check if app already exists on Play Console
# --------------------------------------------------

puts "\n🔍 Checking if app exists on Google Play…"
app_exists = check_app_exists(android_publisher, package_name)
unless app_exists
  puts "❌ App '#{package_name}' does not exist in Google Play Console."
  puts "📝 Please create the app manually first:"
  puts "   1. Go to https://play.google.com/console"
  puts "   2. Click 'Create app'"
  puts "   3. Fill in the app details:"
  puts "      - App name: #{app_name}"
  puts "      - Default language: #{primary_language}"
  puts "   4. Upload first abb file with package name: #{package_name}"
  puts "   5. Complete the initial setup"
  puts "   6. Then run this script again"
  exit 1
end
puts "✔ App exists. Proceeding with edit creation…"

# --------------------------------------------------
# 2.1 Prepare metadata files for supply
# --------------------------------------------------
puts "\n📝 Preparing metadata files..."
metadata_lang_path = File.join(metadata_path, primary_language)
Dir.mkdir(metadata_path) unless Dir.exist?(File.join(metadata_path))
Dir.mkdir(metadata_lang_path) unless Dir.exist?(metadata_lang_path)

# Helper: only write file if value is present and not blank (consistent with update_ios.rb)
def write_metadata_if_present(path, value)
  return unless value && !value.to_s.strip.empty?
  File.write(path, value.to_s)
end

# Write metadata files (skip nil/empty to avoid invalid uploads and supply failures)
write_metadata_if_present(File.join(metadata_lang_path, "title.txt"), app_name)
write_metadata_if_present(File.join(metadata_lang_path, "short_description.txt"), short_description)
write_metadata_if_present(File.join(metadata_lang_path, "full_description.txt"), full_description)
write_metadata_if_present(File.join(metadata_lang_path, "video.txt"), nil)  # optional; skip when no URL
write_metadata_if_present(File.join(metadata_lang_path, "contact_website.txt"), marketing_url)
write_metadata_if_present(File.join(metadata_lang_path, "privacy_policy.txt"), privacy_url)
write_metadata_if_present(File.join(metadata_lang_path, "contact_email.txt"), review_email)
# Write release notes to changelogs/default.txt for supply changelogs
changelogs_dir = File.join(metadata_lang_path, "changelogs")
Dir.mkdir(changelogs_dir) unless Dir.exist?(changelogs_dir)
write_metadata_if_present(File.join(changelogs_dir, "default.txt"), release_notes)

puts "✔ Metadata files prepared"

# --------------------------------------------------
# 2.2 Prepare images
# --------------------------------------------------
puts "\n📝 Preparing images..."
# Create images directory
images_dir = File.join(metadata_lang_path, "images")
Dir.mkdir(images_dir) unless Dir.exist?(images_dir)
# Create phoneScreenshots directory
phone_screenshots_dir = File.join(metadata_lang_path, "images", "phoneScreenshots")
Dir.mkdir(phone_screenshots_dir) unless Dir.exist?(phone_screenshots_dir)

# copy images from input/images/ to metadata_android/{primary_language}/images/
icon_source = File.join(__dir__, "input/images/icon.png")
feature_graphic_source = File.join(__dir__, "input/images/featureGraphic.png")

if File.exist?(icon_source)
  FileUtils.cp(icon_source, File.join(images_dir, "icon.png"))
else
  puts "⚠️  Warning: #{icon_source} not found, skipping icon.png"
end

if File.exist?(feature_graphic_source)
  FileUtils.cp(feature_graphic_source, File.join(images_dir, "featureGraphic.png"))
else
  puts "⚠️  Warning: #{feature_graphic_source} not found, skipping featureGraphic.png"
end

# copy images from input/images/screenshots/ to metadata_android/{primary_language}/phoneScreenshots/
screenshots_source = File.join(__dir__, "input/images/6.5inch")
if Dir.exist?(screenshots_source)
  Dir.glob(File.join(screenshots_source, "*")).each do |screenshot_file|
    FileUtils.cp(screenshot_file, phone_screenshots_dir) if File.file?(screenshot_file)
  end
else
  puts "⚠️  Warning: #{screenshots_source} directory not found, skipping screenshots"
end

# --------------------------------------------------
# 3. Upload metadata, images and screenshots using supply
# --------------------------------------------------
puts "\n📸 Uploading images and screenshots..."

# Use supply to upload metadata, images and screenshots (paths expanded for cwd when run from project root)
supply_command = [
  "fastlane", "supply",
  "--package_name", package_name,
  "--json_key", File.expand_path(SERVICE_ACCOUNT_JSON),
  "--metadata_path", File.expand_path(metadata_path),
  "--skip_upload_apk", "true",
  "--skip_upload_aab", "true",
  "--skip-upload-aab", "true",
  "--skip_upload_changelogs", "true",  # Skip changelogs to avoid version_code requirement
  "--skip_upload_metadata", "false",    # Upload metadata (title, descriptions, etc.)
  "--skip_upload_images", "false",
  "--skip_upload_screenshots", "false"
]

unless system(*supply_command)
  puts "❌ ERROR: Failed to upload metadata to Google Play!"
  exit 1
end

# --------------------------------------------------
# 4. Update Store Listing Contact Details
# https://googleapis.dev/ruby/google-apis-androidpublisher_v3/v0.2.0/Google/Apis/AndroidpublisherV3/AppDetails.html
# --------------------------------------------------
puts "\n📧 Updating store listing contact details..."

unless review_email.is_a?(String) && !review_email.strip.empty?
  puts "⚠️  Warning: No contact email specified (reviewInformation.email_address). Skipping contact details update."
else
  edit_id = nil
  begin
    edit = android_publisher.insert_edit(package_name)
    edit_id = edit.id
    puts "✔ Edit created: #{edit_id}"

    # Build the AppDetails object
    app_details = Google::Apis::AndroidpublisherV3::AppDetails.new(
      contact_email: review_email,
      contact_phone:   review_phone,
      contact_website: contact_url,
      default_language: primary_language  # good practice to include
    )

    # Update the details
    android_publisher.update_edit_detail(package_name, edit_id, app_details)

    puts "✔ Contact details updated: { Email: #{review_email}, Phone: #{review_phone}, Website: #{contact_url} }"

    # Commit the edit
    android_publisher.commit_edit(package_name, edit_id)
    puts "✔ Edit committed successfully"

  rescue => e
    puts "❌ ERROR: Failed to update contact details: #{e.message}"
    puts "   #{e.backtrace.first}"
    begin
      android_publisher.delete_edit(package_name, edit_id) if edit_id
    rescue => cleanup_error
      puts "   ⚠️  Warning: Failed to cleanup edit: #{cleanup_error.message}"
    end
  end
end

# NOTE: Data Safety declarations cannot be updated via API.
# They must be configured manually in Google Play Console:
# https://play.google.com/console → App content → Data safety

puts "\n✅ Google Play metadata updated successfully!"
