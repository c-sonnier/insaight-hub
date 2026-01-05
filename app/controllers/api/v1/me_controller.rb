module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          # Identity info (global user)
          identity: {
            id: current_identity.id,
            name: current_identity.name,
            email: current_identity.email_address,
            super_admin: current_identity.admin?,
            created_at: current_identity.created_at
          },
          # Account membership info
          membership: current_user ? {
            id: current_user.id,
            role: current_user.role,
            account_id: current_account.external_id,
            account_name: current_account.name,
            insights_count: current_user.insight_items.count,
            published_insights_count: current_user.insight_items.published.count
          } : nil
        }
      end
    end
  end
end
