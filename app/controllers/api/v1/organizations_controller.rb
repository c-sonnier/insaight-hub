module Api
  module V1
    class OrganizationsController < BaseController
      skip_before_action :require_account_membership

      def index
        memberships = current_identity.users.includes(:account).order("accounts.name")

        render json: {
          organizations: memberships.map do |user|
            {
              id: user.account.external_id,
              name: user.account.name,
              role: user.role
            }
          end
        }
      end
    end
  end
end
