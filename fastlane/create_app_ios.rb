#!/usr/bin/env ruby
require 'json'
require 'fastlane'
require 'spaceship'
require 'dotenv'


# --------------------------------------------------
# Load ENV
# --------------------------------------------------
Dotenv.load(File.join(__dir__, ".env"))

# Note: FASTLANE_TEAM_ID and FASTLANE_ITC_TEAM_ID are optional.
# If not set in .env, you can manually select the team when running the script.

# --------------------------------------------------
# Load config data
# --------------------------------------------------

config_path = File.join(__dir__, "input/data.json")

unless File.exist?(config_path)
  puts "❌ ERROR: input/data.json not found!"
  exit 1
end

config = JSON.parse(File.read(config_path))
wl_name = config["name"]
bundle_id = config["bundleId"]
app_name = config["name"]
primary_language = "en-US"
sku = bundle_id
version = config["version"]

puts "🚀 Starting TECHNICAL SETUP for #{app_name} -  #{bundle_id}"

# --------------------------------------------------
# Authenticate
# --------------------------------------------------

puts "\n🔐 Logging in to Apple Developer & App Store Connect…"

Spaceship::Portal.login
Spaceship::ConnectAPI.login

# --------------------------------------------------
# 1. Create Bundle ID
# --------------------------------------------------

puts "\n📦 Creating Bundle ID…"

portal_apps = Spaceship::Portal.app.all.map(&:bundle_id)

if portal_apps.include?(bundle_id)
  puts "✔ Bundle ID already exists: #{bundle_id}"
  bundle = Spaceship::Portal.app.find(bundle_id)
else
  bundle = Spaceship::Portal.app.create!(
    bundle_id: bundle_id,
    name: "#{wl_name} whitelabel"
  )
  puts "✔ Created Bundle ID: #{bundle_id}"
end

# --------------------------------------------------
# 2. Enable Capabilities (Push + Autofill)
# --------------------------------------------------

puts "\n⚙️ Enabling capabilities…"

bundle.update_service(Spaceship::Portal::AppService.push_notification.on)
bundle.update_service(Spaceship::Portal::AppService.auto_fill_credential.on)

puts "✔ Capabilities enabled"

# --------------------------------------------------
# 3. Create the App Store Connect App
# --------------------------------------------------

puts "\n📱 Creating App Store Connect App…"

asc_apps = Spaceship::ConnectAPI::App.all.map(&:bundle_id)

if asc_apps.include?(bundle_id)
  puts "✔ App already exists in App Store Connect"
  app = Spaceship::ConnectAPI::App.find(bundle_id)
else
  Spaceship::ConnectAPI::App.create(
    name: app_name,
    version_string: version,
    primary_locale: primary_language,
    sku: sku,
    bundle_id: bundle_id,
    platforms: ["IOS"]
  )
  puts "✔ ASC App created"
  
  # Retry with delay to handle API eventual consistency
  3.times do |i|
    sleep(2)
    app = Spaceship::ConnectAPI::App.find(bundle_id)
    break if app
    puts "⏳ Waiting for app to be available... (attempt #{i + 1}/3)"
  end
end

raise "❌ ERROR: Could not find app: #{bundle_id}" unless app

apple_app_id = app.id
puts "→ Apple App ID: #{apple_app_id}"

# --------------------------------------------------
# 4. Create Internal TestFlight Group + Add Existing Testers (Raw API)
# --------------------------------------------------

puts "\n🧪 Setting up Internal TestFlight group…"

group_name = "Erin QA"
tester_emails = [
  "nicole.graham@erinliving.com",
  "nic.martin@erinliving.com",
  "jerome.soulas@erinliving.com",
]

# Fetch existing groups
existing_groups = app.get_beta_groups
group = existing_groups.find { |g| g.name == group_name }

if group
  puts "✔ Internal group '#{group_name}' already exists"
else
  puts "→ Creating INTERNAL group '#{group_name}'…"

  client = Spaceship::ConnectAPI
  body = {
    data: {
      attributes: {
        name: group_name,
        isInternalGroup: true,
        hasAccessToAllBuilds: true
      },
      relationships: {
        app: {
          data: {
            id: app.id,
            type: "apps"
          }
        }
      },
      type: "betaGroups"
    }
  }
  
  response = client.test_flight_request_client.post("v1/betaGroups", body)
  group = response.to_models.first
  
  if group.nil?
    puts "❌ ERROR: Failed to create TestFlight group - API returned empty response"
    exit 1
  end
  
  puts "✔ Created TestFlight internal group"
end

puts "\n👥 Adding existing testers to '#{group_name}' ..."


tester_emails.each do |email|
  begin
    tester = Spaceship::ConnectAPI::BetaTester.all(filter: { email: email }).first
    if tester.nil?
      puts "⚠️ Tester not found in ASC (must be invited first): #{email}"
      next
    end
    
    # Check if tester is associated with this app
    app_testers = app.get_beta_testers
    tester_in_app = app_testers.any? { |t| t.id == tester.id }
    
    unless tester_in_app
      # Use post_beta_tester_assignment to add tester to app and group at once
      Spaceship::ConnectAPI.post_beta_tester_assignment(
        beta_group_ids: [group.id],
        attributes: {
          email: email
        }
      )
      puts "✔ Added tester to app and group: #{email}"
    else
      # Tester is already in the app; add them to the group via Spaceship API
      group.add_beta_testers(beta_tester_ids: [tester.id])
      puts "✔ Added existing tester to group: #{email}"
    end

  rescue => e
    # Show full error for debugging
    error_msg = e.message.to_s
    error_class = e.class.to_s
    # Check if it's the "cannot be assigned" error
    if error_msg.downcase.include?("cannot be assigned") || error_msg.downcase.include?("state of another resource")
      puts "⚠️ Cannot assign tester #{email}: #{error_msg}"
      puts "   This might mean the tester already in group, or there's a state conflict."
    else
      puts "⚠️ Error adding #{email}: #{error_msg} (#{error_class})"
    end
  end
end

puts "✔ Internal TestFlight group setup complete!"


# --------------------------------------------------
# 4. Age Ratings
# --------------------------------------------------

puts "\n📋 Setting Age Ratings…"

begin
  # Use fetch_edit_app_info to get the editable app info
  app_info = app.fetch_edit_app_info
  
  if app_info
    # Fetch the age rating declaration from AppInfo
    age_rating_declaration = app_info.fetch_age_rating_declaration
    
    if age_rating_declaration
      # Prepare attributes to set all fields to "No" (NONE or false)
      # Step 1-6: Set "No" to all questions
      # Capabilities: Set "No" to Unrestricted Web Access, User-Generated Content, Messaging and Chat, Advertising
      # In-App Controls: Set "No" to Parental Controls and Age Assurance
      attributes = {
        # Step 1: Features
        parentalControls: false, 
        ageAssurance: false,
        unrestrictedWebAccess: false,
        userGeneratedContent: false, 
        advertising: false,
        messagingAndChat: false,
        
        # Step 2: Mature Themes
        profanityOrCrudeHumor: "NONE",
        horrorOrFearThemes: "NONE",
        alcoholTobaccoOrDrugUseOrReferences: "NONE",

        # Step 3: Medical or Wellness
        medicalOrTreatmentInformation: "NONE",
        healthOrWellnessTopics: false, 
        
        # Step 4: Sexual Content or Nudity
        matureOrSuggestiveThemes: "NONE",
        sexualContentOrNudity: "NONE",
        sexualContentGraphicAndNudity: "NONE",

        # Step 5: Violence
        violenceCartoonOrFantasy: "NONE",
        violenceRealistic: "NONE",
        violenceRealisticProlongedGraphicOrSadistic: "NONE",
        gunsOrOtherWeapons: "NONE", # Note: Guns or Other Weapons field not successfully updated - must be set manually
        
        # Step 6: Chance-Based Activities
        gambling: false, 
        gamblingSimulated: "NONE", 
        contests: "NONE", 
        lootBox: false, 
      }
      
      # Step 7: Age Categories and Override - Set to "Not Applicable"
      # For "Not Applicable", we omit kidsAgeBand from the update (don't set it)
      # This effectively leaves it as "Not Applicable"
      # Age Suitability URL is typically not settable via API and should remain blank
      
      # Update the age rating declaration
      age_rating_declaration.update(attributes: attributes)
      puts "✔ Age rating declaration updated"
      puts "   - Expected result: 'Ages 4+' rating"
    else
      puts "⚠️  No age rating declaration found. Creating new declaration..."
    end
  else
    puts "⚠️  No AppInfo found. Cannot set age ratings."
  end
rescue => e
  puts "⚠️  Warning: Failed to update age rating declaration: #{e.message}"
end

# --------------------------------------------------
# 5. Save output data
# --------------------------------------------------

output_dir = File.join(__dir__, "output")
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

output_path = File.join(output_dir, "app_info.json")

File.write(output_path, JSON.pretty_generate({
  name: wl_name,
  bundleId: bundle_id,
  appleAppId: apple_app_id,
  groupName: group_name
}))

puts "\n💾 Output saved to: #{output_path}"
puts "\n🎉 Script A completed successfully!"
