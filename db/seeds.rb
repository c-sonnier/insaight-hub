# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user
admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.password = "admin"
  user.name = "Admin"
  user.admin = true
end

puts "Created admin user: #{admin.email_address} (API Token: #{admin.api_token})"

# To import demo reports, run:
#   rails demo:import_reports
#
# This will read HTML files from the monorepo-migration and parser-testable folders
# and create reports in the database without modifying the HTML content.
#
# Other demo tasks:
#   rails demo:remove_reports  - Remove the demo reports
#   rails demo:reset_reports   - Remove and re-import demo reports
