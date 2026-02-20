# frozen_string_literal: true

class McpController < ActionController::API
  before_action :set_current_account
  before_action :authenticate_identity
  before_action :require_account_membership

  def handle
    server = MCP::Server.new(
      name: "digest-hub",
      version: "1.0.0",
      instructions: "Digest Hub MCP server for managing insights. Use these tools to create, read, update, and delete insights.",
      tools: [
        ListInsightsTool,
        GetInsightTool,
        CreateInsightTool,
        UpdateInsightTool,
        PublishInsightTool,
        UnpublishInsightTool,
        DeleteInsightTool,
        GetTagsTool
      ],
      server_context: {
        user: @current_user,
        identity: @current_identity,
        account: @current_account
      }
    )

    render json: server.handle_json(request.body.read)
  end

  private

  # Account is set by middleware from URL path
  def set_current_account
    @current_account = request.env["insaight.account"]
    Current.account = @current_account
  end

  def authenticate_identity
    token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")

    if token.blank?
      response.set_header("WWW-Authenticate", www_authenticate_header)
      render json: { error: "Missing authorization header" }, status: :unauthorized
      return
    end

    # Try OAuth token first, fall back to API token (temporary — remove once clients have migrated)
    @current_identity = authenticate_via_oauth(token) || Identity.find_by(api_token: token)

    if @current_identity.nil?
      response.set_header("WWW-Authenticate", www_authenticate_header)
      render json: { error: "Invalid token" }, status: :unauthorized
      nil
    end
  end

  def require_account_membership
    if @current_account.nil?
      render json: { error: "Account not found. Please check your MCP URL configuration." }, status: :not_found
      return
    end

    # Always try to find the user's membership in this account
    @current_user = @current_identity&.users&.find_by(account: @current_account)

    # Super admins can access any account but still need a user record to create content
    return if @current_user.present?

    # Non-members get forbidden
    unless @current_identity&.admin?
      render json: { error: "You don't have access to this organization" }, status: :forbidden
      return
    end

    # Admins without membership in this account cannot create content
    render json: { error: "Admin access granted but you need a user membership in this account to create content. Please join this organization first." }, status: :unprocessable_entity
  end

  def authenticate_via_oauth(token)
    access_token = Oauth::AccessToken.find_by_plaintext(token)
    return nil unless access_token&.active?

    # Validate resource parameter matches this account's MCP endpoint
    if access_token.resource.present? && @current_account.present?
      expected_resource = "#{request.base_url}/#{@current_account.external_id}/mcp"
      return nil unless access_token.resource == expected_resource
    end

    @oauth_scope = access_token.scope
    access_token.identity
  end

  def www_authenticate_header
    resource_uri = @current_account ? "#{request.base_url}/#{@current_account.external_id}/mcp" : request.original_url
    %(Bearer resource_metadata="#{request.base_url}/.well-known/oauth-protected-resource")
  end
end
