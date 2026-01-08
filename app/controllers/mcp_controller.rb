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

    # Super admins can access any account
    return if @current_identity&.admin?

    # Regular users need membership in the account
    @current_user = @current_identity&.users&.find_by(account: @current_account)

    unless @current_user
      render json: { error: "You don't have access to this organization" }, status: :forbidden
    end
  end
end
