module Oauth
  class TokensController < BaseController
    def create
      service = Oauth::TokenService.new(token_params)
      result = service.call

      if result[:error]
        oauth_error(result[:error], result[:error_description])
      else
        render json: result
      end
    end

    private

    def token_params
      params.permit(:grant_type, :code, :redirect_uri, :code_verifier, :refresh_token, :client_id, :client_secret, :resource)
    end
  end
end
