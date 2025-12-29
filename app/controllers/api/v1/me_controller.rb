module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email_address,
          admin: current_user.admin?,
          reports_count: current_user.reports.count,
          published_reports_count: current_user.reports.published.count,
          created_at: current_user.created_at
        }
      end
    end
  end
end
