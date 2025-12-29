module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend

      before_action :authenticate_api_user

      private

      def authenticate_api_user
        token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")

        if token.blank?
          render json: { error: "Missing authorization header" }, status: :unauthorized
          return
        end

        @current_user = User.find_by(api_token: token)

        if @current_user.nil?
          render json: { error: "Invalid API token" }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def pagy_metadata(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.items
        }
      end
    end
  end
end
