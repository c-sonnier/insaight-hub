module Oauth
  class TokenService
    def initialize(params)
      @grant_type = params[:grant_type]
      @code = params[:code]
      @redirect_uri = params[:redirect_uri]
      @code_verifier = params[:code_verifier]
      @refresh_token = params[:refresh_token]
      @client_id = params[:client_id]
      @client_secret = params[:client_secret]
      @resource = params[:resource]
    end

    def call
      case @grant_type
      when "authorization_code"
        exchange_code
      when "refresh_token"
        refresh
      else
        error(:unsupported_grant_type, "Unsupported grant_type")
      end
    end

    private

    def exchange_code
      auth_code = Oauth::AuthorizationCode.find_by_plaintext(@code)
      return error(:invalid_grant, "Invalid authorization code") unless auth_code
      return error(:invalid_grant, "Authorization code expired") if auth_code.expired?
      return error(:invalid_grant, "Authorization code already used") if auth_code.used?

      client = authenticate_client(auth_code.oauth_client)
      return error(:invalid_client, "Client authentication failed") unless client

      return error(:invalid_grant, "redirect_uri mismatch") unless auth_code.redirect_uri == @redirect_uri

      unless Oauth::PkceVerifier.verify(
        code_verifier: @code_verifier,
        code_challenge: auth_code.code_challenge,
        method: auth_code.code_challenge_method
      )
        return error(:invalid_grant, "PKCE verification failed")
      end

      auth_code.use!

      issue_tokens(
        client: client,
        identity: auth_code.identity,
        account: auth_code.account,
        scope: auth_code.scope,
        resource: auth_code.resource
      )
    end

    def refresh
      old_refresh = Oauth::RefreshToken.find_by_plaintext(@refresh_token)
      return error(:invalid_grant, "Invalid refresh token") unless old_refresh
      return error(:invalid_grant, "Refresh token expired") if old_refresh.expired?
      return error(:invalid_grant, "Refresh token revoked") if old_refresh.revoked?

      client = authenticate_client(old_refresh.oauth_client)
      return error(:invalid_client, "Client authentication failed") unless client

      old_refresh.revoke!

      issue_tokens(
        client: client,
        identity: old_refresh.identity,
        account: old_refresh.account,
        scope: old_refresh.scope,
        resource: old_refresh.resource,
        previous_refresh_token: old_refresh
      )
    end

    def issue_tokens(client:, identity:, account:, scope:, resource:, previous_refresh_token: nil)
      refresh_result = Oauth::RefreshToken.create_for(
        client: client,
        identity: identity,
        account: account,
        scope: scope,
        resource: resource,
        previous_token: previous_refresh_token
      )

      access_result = Oauth::AccessToken.create_for(
        client: client,
        identity: identity,
        account: account,
        scope: scope,
        resource: resource,
        refresh_token: refresh_result[:token]
      )

      {
        access_token: access_result[:plaintext_token],
        token_type: "Bearer",
        expires_in: 3600,
        refresh_token: refresh_result[:plaintext_token],
        scope: scope
      }
    end

    def authenticate_client(expected_client)
      if expected_client.confidential?
        Oauth::Client.authenticate(@client_id, @client_secret)
      else
        return expected_client if expected_client.client_id == @client_id
        nil
      end
    end

    def error(code, description)
      { error: code, error_description: description }
    end
  end
end
