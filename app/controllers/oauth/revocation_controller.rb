module Oauth
  class RevocationController < BaseController
    def create
      token_value = params[:token]
      token_type = params[:token_type_hint]

      if token_value.blank?
        oauth_error(:invalid_request, "token parameter is required")
        return
      end

      # Try to find and revoke the token. Per RFC 7009, always return 200
      # even if the token is invalid or already revoked.
      case token_type
      when "refresh_token"
        revoke_refresh_token(token_value) || revoke_access_token(token_value)
      else
        revoke_access_token(token_value) || revoke_refresh_token(token_value)
      end

      head :ok
    end

    private

    def revoke_access_token(token_value)
      token = Oauth::AccessToken.find_by_plaintext(token_value)
      token&.revoke!
      token.present?
    end

    def revoke_refresh_token(token_value)
      token = Oauth::RefreshToken.find_by_plaintext(token_value)
      token&.revoke!
      token.present?
    end
  end
end
