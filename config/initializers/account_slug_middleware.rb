# Add AccountSlug::Extractor middleware for multi-tenancy
# This extracts the account UUID from URL paths and sets Current.account
require_relative "../../app/middleware/account_slug/extractor"

Rails.application.config.middleware.use AccountSlug::Extractor
