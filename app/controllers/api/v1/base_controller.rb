module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend

      before_action :set_current_account
      before_action :authenticate_api_user
      before_action :require_account_membership

      private

      # Account is set by middleware from URL path
      def set_current_account
        Current.account = request.env["insaight.account"]
      end

      def authenticate_api_user
        token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")

        if token.blank?
          render json: { error: "Missing authorization header" }, status: :unauthorized
          return
        end

        # Find the User (membership) that owns this token
        @token_user = User.find_by(api_token: token)

        if @token_user.nil?
          render json: { error: "Invalid API token" }, status: :unauthorized
          return
        end

        @current_identity = @token_user.identity
      end

      def require_account_membership
        return if Current.account.nil?

        # Super admins can access any account
        return if @current_identity&.admin?

        # Token grants cross-account access for the same identity
        @current_user = @current_identity&.users&.find_by(account: Current.account)

        unless @current_user
          render json: { error: "You don't have access to this organization" }, status: :forbidden
        end
      end

      def current_identity
        @current_identity
      end

      def current_user
        @current_user ||= @current_identity&.users&.find_by(account: Current.account)
      end

      def current_account
        Current.account
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
