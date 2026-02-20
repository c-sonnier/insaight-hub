module Oauth
  class ClientsController < BaseController
    before_action :authenticate_registration_token, only: :show

    def create
      result = Oauth::Client.register(client_params)

      if result[:errors]
        oauth_error(:invalid_client_metadata, result[:errors].full_messages.join(", "))
      else
        render json: {
          client_id: result[:client].client_id,
          client_name: result[:client].client_name,
          client_secret: result[:client_secret],
          redirect_uris: result[:client].redirect_uris,
          grant_types: result[:client].grant_types,
          token_endpoint_auth_method: result[:client].token_endpoint_auth_method,
          registration_access_token: result[:registration_access_token],
          registration_client_uri: "#{root_url}oauth/register/#{result[:client].client_id}"
        }, status: :created
      end
    end

    def show
      render json: {
        client_id: @client.client_id,
        client_name: @client.client_name,
        redirect_uris: @client.redirect_uris,
        grant_types: @client.grant_types,
        token_endpoint_auth_method: @client.token_endpoint_auth_method
      }
    end

    private

    def client_params
      params.permit(:client_name, :token_endpoint_auth_method, redirect_uris: [], grant_types: [])
    end

    def authenticate_registration_token
      @client = Oauth::Client.find_by(client_id: params[:client_id])
      return oauth_error(:invalid_client, "Client not found", status: :not_found) unless @client

      token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")
      return oauth_error(:invalid_token, "Missing registration access token", status: :unauthorized) if token.blank?

      expected_digest = Digest::SHA256.hexdigest(token)
      unless ActiveSupport::SecurityUtils.secure_compare(@client.registration_access_token_digest.to_s, expected_digest)
        oauth_error(:invalid_token, "Invalid registration access token", status: :unauthorized)
      end
    end
  end
end
