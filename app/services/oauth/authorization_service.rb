module Oauth
  class AuthorizationService
    VALID_RESPONSE_TYPES = %w[code].freeze
    VALID_SCOPES = %w[mcp:read mcp:write mcp:admin].freeze
    DEFAULT_SCOPE = "mcp:read"

    def initialize(params)
      @client_id = params[:client_id]
      @redirect_uri = params[:redirect_uri]
      @response_type = params[:response_type]
      @scope = params[:scope]
      @code_challenge = params[:code_challenge]
      @code_challenge_method = params[:code_challenge_method]
      @resource = params[:resource]
      @state = params[:state]
    end

    def validate
      @client = Oauth::Client.find_by(client_id: @client_id)
      return error(:invalid_client, "Unknown client") unless @client
      return error(:invalid_redirect_uri, "Invalid redirect URI") unless @client.valid_redirect_uri?(@redirect_uri)
      return error(:unsupported_response_type, "Only 'code' is supported") unless VALID_RESPONSE_TYPES.include?(@response_type)
      return error(:invalid_request, "PKCE code_challenge is required") if @code_challenge.blank?
      return error(:invalid_request, "Only S256 code_challenge_method is supported") if @code_challenge_method.present? && @code_challenge_method != "S256"
      return error(:invalid_scope, "Invalid scope") unless valid_scopes?

      success
    end

    def authorize(identity:, account:)
      Oauth::AuthorizationCode.create_for(
        client: @client,
        identity: identity,
        account: account,
        redirect_uri: @redirect_uri,
        scope: resolved_scope,
        code_challenge: @code_challenge,
        code_challenge_method: @code_challenge_method || "S256",
        resource: @resource,
        state: @state
      )
    end

    def client
      @client
    end

    def resolved_scope
      @scope.presence || DEFAULT_SCOPE
    end

    private

    def valid_scopes?
      return true if @scope.blank?
      @scope.split(" ").all? { |s| VALID_SCOPES.include?(s) }
    end

    def error(code, description)
      { error: code, error_description: description }
    end

    def success
      { success: true }
    end
  end
end
