module Oauth
  class AuthorizationController < ApplicationController
    # Uses session auth from Authentication concern — redirects to login if unauthenticated.
    # After login, the user returns here via session[:return_to_after_authenticating].

    def new
      @service = Oauth::AuthorizationService.new(authorization_params)
      result = @service.validate

      if result[:error]
        flash.now[:alert] = result[:error_description]
        render :error, status: :bad_request
      end
    end

    def create
      @service = Oauth::AuthorizationService.new(authorization_params)
      result = @service.validate

      if result[:error]
        flash.now[:alert] = result[:error_description]
        render :error, status: :bad_request
        return
      end

      account = Account.find_by(external_id: params[:account_id])
      unless account
        flash.now[:alert] = "Account not found"
        render :error, status: :bad_request
        return
      end

      identity = Current.identity
      code_result = @service.authorize(identity: identity, account: account)

      redirect_uri = URI.parse(authorization_params[:redirect_uri])
      query = URI.decode_www_form(redirect_uri.query || "")
      query << ["code", code_result[:plaintext_code]]
      query << ["state", authorization_params[:state]] if authorization_params[:state].present?
      redirect_uri.query = URI.encode_www_form(query)

      redirect_to redirect_uri.to_s, allow_other_host: true
    end

    private

    def authorization_params
      params.permit(:client_id, :redirect_uri, :response_type, :scope, :code_challenge, :code_challenge_method, :resource, :state)
    end
  end
end
