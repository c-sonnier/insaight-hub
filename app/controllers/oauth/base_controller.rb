module Oauth
  class BaseController < ActionController::API
    private

    def oauth_error(error, description, status: :bad_request)
      render json: { error: error, error_description: description }, status: status
    end
  end
end
