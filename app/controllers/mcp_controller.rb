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
      render json: { error: "Missing authorization header" }, status: :unauthorized
      return
    end

    # API token is now on Identity
    @current_identity = Identity.find_by(api_token: token)

    if @current_identity.nil?
      render json: { error: "Invalid API token" }, status: :unauthorized
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
end
