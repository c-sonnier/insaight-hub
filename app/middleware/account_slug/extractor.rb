module AccountSlug
  class Extractor
    # UUID regex pattern for matching account identifiers
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    # Routes that should not have account prefix (global routes)
    # These include authentication, public pages, and static assets
    GLOBAL_ROUTES = %w[
      /
      /up
      /health
      /waitlist
      /s
      /assets
      /rails
      /session
      /passwords
      /setup
      /register
      /how-to
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["PATH_INFO"]

      # Skip processing for global routes
      return @app.call(env) if global_route?(path)

      # Try to extract account UUID from path
      account_id, remaining_path = extract_account_from_path(path)

      if account_id
        # Find the account
        account = Account.find_by(external_id: account_id)

        if account
          # Set the account in Current (will be available throughout request)
          env["insaight.account"] = account
          env["insaight.account_id"] = account_id

          # Move the account slug from PATH_INFO to SCRIPT_NAME
          # This makes Rails think the app is "mounted" at /{account_id}
          env["SCRIPT_NAME"] = "#{env['SCRIPT_NAME']}/#{account_id}"
          env["PATH_INFO"] = remaining_path.presence || "/"
        end
      end

      @app.call(env)
    end

    private

    def global_route?(path)
      GLOBAL_ROUTES.any? { |route| path == route || path.start_with?("#{route}/") }
    end

    def extract_account_from_path(path)
      # Path format: /{account_uuid}/rest/of/path
      parts = path.split("/").reject(&:blank?)

      return [nil, path] if parts.empty?

      potential_account_id = parts.first

      if potential_account_id.match?(UUID_PATTERN)
        remaining_parts = parts.drop(1)
        remaining_path = remaining_parts.empty? ? "/" : "/#{remaining_parts.join('/')}"
        [potential_account_id, remaining_path]
      else
        [nil, path]
      end
    end
  end
end
