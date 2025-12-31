# frozen_string_literal: true

class McpController < ActionController::API
  before_action :authenticate_user

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
      server_context: { user: @current_user }
    )

    render json: server.handle_json(request.body.read)
  end

  private

  def authenticate_user
    token = request.headers["Authorization"]&.gsub(/^Bearer\s+/, "")

    if token.blank?
      render json: { error: "Missing authorization header" }, status: :unauthorized
      return
    end

    @current_user = User.find_by(api_token: token)

    if @current_user.nil?
      render json: { error: "Invalid API token" }, status: :unauthorized
      nil
    end
  end
end
